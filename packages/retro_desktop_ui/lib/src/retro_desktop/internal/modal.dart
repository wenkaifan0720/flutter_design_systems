// The look's modal windows (an alert, a dialog, a sheet) and what stands under them: only the front window is active
// (law 3), so a window under one draws its title bar inactive and its default button goes quiet, as the period's did.
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

// A value its listeners hear change, shared by the whole app for as long as it runs. Not a ChangeNotifier: nothing
// disposes it, and leak tracking counts an undisposed notifier as a leak.
class _Shared<T> implements ValueListenable<T> {
  _Shared(this._value);

  T _value;
  final _listeners = <VoidCallback>[];
  bool _due = false;

  @override
  T get value => _value;

  // Read at once; heard at once, or after the frame where it changed in one (a route disposed as the tree it stood
  // in unmounts): a listener told mid-frame would mark a widget to build while the tree is locked.
  set value(T value) {
    if (value == _value) return;
    _value = value;
    final binding = SchedulerBinding.instance;
    if (binding.schedulerPhase != SchedulerPhase.persistentCallbacks) {
      _notify();
    } else if (!_due) {
      _due = true;
      binding.addPostFrameCallback((_) {
        _due = false;
        _notify();
      });
    }
  }

  void _notify() {
    for (final listener in List.of(_listeners)) {
      if (_listeners.contains(listener)) listener();
    }
  }

  @override
  void addListener(VoidCallback listener) => _listeners.add(listener);

  @override
  void removeListener(VoidCallback listener) => _listeners.remove(listener);
}

final _barFoot = _Shared<double>(0);

/// How far down the screen the menu bar across its top reaches (the bar's bottom edge, in global coordinates); 0 with
/// none. An alert stands below it: nothing the look raises covers the menu bar, as on the period's desktop.
ValueListenable<double> get retroDesktopBarFoot => _barFoot;

/// Publishes [child]'s bottom edge, a menu bar's, to [retroDesktopBarFoot] while it runs across the top of the screen
/// (a bar inside a window, Chisel's, or further down a page doesn't count).
class RetroDesktopBarFoot extends SingleChildRenderObjectWidget {
  /// Marks [child] as a menu bar.
  const RetroDesktopBarFoot({super.key, super.child});

  // The top of the screen's room: below the system's own bar, where there is one.
  static double _screenTop(BuildContext context) {
    final view = View.maybeOf(context);
    return view == null ? 0 : view.viewPadding.top / view.devicePixelRatio;
  }

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderBarFoot(_screenTop(context));

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    (renderObject as _RenderBarFoot).screenTop = _screenTop(context);
  }
}

class _RenderBarFoot extends RenderProxyBox {
  _RenderBarFoot(this.screenTop);

  double screenTop;

  static final _feet = <_RenderBarFoot, double>{};
  static bool _due = false;

  // After the frame: a notifier changed while painting would rebuild a listener in the middle of the frame.
  static void _publish() {
    if (_due) return;
    _due = true;
    SchedulerBinding.instance
      ..addPostFrameCallback((_) {
        _due = false;
        _barFoot.value = _feet.values.fold(0.0, math.max);
      })
      ..ensureVisualUpdate();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    super.paint(context, offset);
    final top = localToGlobal(Offset.zero).dy;
    if (top > screenTop + 1) {
      if (_feet.remove(this) != null) _publish();
      return;
    }
    final foot = localToGlobal(Offset(0, size.height)).dy;
    if (_feet[this] != foot) {
      _feet[this] = foot;
      _publish();
    }
  }

  @override
  void detach() {
    if (_feet.remove(this) != null) _publish();
    super.detach();
  }
}

final _modals = _Shared<List<Route<Object?>>>(const []);

/// The routes of the look's modal windows open now, oldest first.
ValueListenable<List<Route<Object?>>> get retroDesktopModals => _modals;

// The look's menus open now: the routes that don't list as modal.
final _openMenus = <RetroDesktopModalRoute<Object?>>{};

/// Lists a route among [retroDesktopModals] from its push until it pops. [listsAsModal] false leaves it out (a menu or
/// a popover leaves the window under it active), and a modal window that opens closes it.
mixin RetroDesktopModalRoute<T> on Route<T> {
  /// Whether this route is a modal window.
  bool get listsAsModal => true;

  /// Whether a modal window that opened over this menu closed it: the place it was opened from doesn't take the
  /// focus back from that window.
  bool get closedByModal => _closedByModal;
  bool _closedByModal = false;

  @override
  void install() {
    super.install();
    if (!listsAsModal) {
      _openMenus.add(this);
      return;
    }
    _modals.value = [..._modals.value, this];
    // Only windows stack: a menu open when an alert opens closes, as the period's did, rather than stand under it with
    // its row still lit. After this push, which takes no other change to the navigator.
    final menus = _openMenus.toList();
    if (menus.isEmpty) return;
    for (final m in menus) {
      m._closedByModal = true;
    }
    scheduleMicrotask(() {
      for (final m in menus) {
        if (m.isActive) m.navigator?.removeRoute(m);
      }
    });
  }

  @override
  bool didPop(T? result) {
    _leave();
    return super.didPop(result);
  }

  @override
  void dispose() {
    _leave();
    super.dispose();
  }

  void _leave() {
    _openMenus.remove(this);
    if (_modals.value.contains(this)) {
      _modals.value = [
        for (final r in _modals.value)
          if (r != this) r,
      ];
    }
  }
}

/// Whether one of the look's modal windows stands over the place [context] is built in: a window there isn't the
/// front one. A modal stands over a route of its own navigator that isn't the current one, and over every route of a
/// navigator nested under the root when it stands in the root. Depends on the context's route, so a part that asks
/// is built again when a route is pushed over it or popped; listen to [retroDesktopModals] as well.
bool retroDesktopUnderModal(BuildContext context) {
  final open = retroDesktopModals.value;
  if (open.isEmpty) return false;
  final own = ModalRoute.of(context);
  if (own == null) return false;
  final root = Navigator.maybeOf(context, rootNavigator: true);
  for (final m in open) {
    if (identical(m, own) || !m.isActive) continue;
    if (m.navigator == own.navigator) {
      if (!own.isCurrent) return true;
    } else if (m.navigator == root && own.navigator != root) {
      return true;
    }
  }
  return false;
}

/// Closes the menus and popovers in [child] (ui_core's anchored overlays, a menu bar's among them) when one of the
/// look's modal windows opens: the alert stands over the desk alone, as the period's did, not over a menu still
/// dropped with its row lit.
class RetroDesktopClosesUnderModal extends StatefulWidget {
  /// Closes [child]'s menus when a modal window opens.
  const RetroDesktopClosesUnderModal({super.key, required this.child});

  /// The menu bar or the popover.
  final Widget child;

  @override
  State<RetroDesktopClosesUnderModal> createState() => _ClosesUnderModalState();
}

class _ClosesUnderModalState extends State<RetroDesktopClosesUnderModal> {
  final _menus = MenuController();
  var _open = retroDesktopModals.value.length;

  @override
  void initState() {
    super.initState();
    retroDesktopModals.addListener(_changed);
  }

  // Heard as the modal window's route installs, before it takes the focus: the menu gives the focus back to its
  // title, and the window that opens takes it from there.
  void _changed() {
    final open = retroDesktopModals.value.length;
    if (open > _open && _menus.isOpen) _menus.close();
    _open = open;
  }

  @override
  void dispose() {
    retroDesktopModals.removeListener(_changed);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      RawMenuAnchorGroup(controller: _menus, child: widget.child);
}

/// Builds [builder] again whenever a modal window of the look opens or closes.
class RetroDesktopModalWatch extends StatelessWidget {
  /// Watches [retroDesktopModals] for [builder].
  const RetroDesktopModalWatch({super.key, required this.builder});

  /// Builds the part; ask [retroDesktopUnderModal] in it.
  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder(
    valueListenable: retroDesktopModals,
    builder: (context, _, _) => builder(context),
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IntProperty('open', retroDesktopModals.value.length));
  }
}
