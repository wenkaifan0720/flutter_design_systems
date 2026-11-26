/// Whether a part with the focus paints it, as a browser's `:focus-visible`
/// decides: shown after a key, hidden after a press of a pointer (a mouse, a
/// finger, a pen) or a tap or a focus that reaches the app as a semantics
/// action with no key held (a click on the web with semantics on, which
/// focuses the pressed control's node before the press reaches the app; a
/// screen reader's), until the next key. Focus that ui_core or the app moves
/// (a dialog's safe action, a popover's first control, a closed surface
/// giving it back) shows as the last input decides, so a surface a pointer
/// opened shows no focus until a key is pressed, and one the keys opened
/// shows it at once. An app that sets
/// [FocusHighlightStrategy.alwaysTraditional] shows focus whatever the
/// input, as Flutter's own widgets do.
///
/// And how the focus arrived ([RawFocusArrival]): from the keys, from a
/// pointer, or given back as what held it closed or went (a dialog's route,
/// Flutter's or ui_core's, a popover, a removed control). A tip shows for
/// the keys' arrival alone, and a field's list opens for no focus given
/// back. Inside ui_core, but for [RawFocusShown], which a look's own
/// pressable takes.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'quiet_focus.dart';

/// How the primary focus arrived.
enum RawFocusArrival {
  /// The keys moved it, or moved last: a Tab, an arrow, a key that opened a
  /// surface that took it.
  keyboard,

  /// A pointer moved it, or moved last: a press, a tap, a click on the web
  /// (its semantics focus).
  pointer,

  /// It was given back: what held it closed or went (a route popped, a
  /// popover closed, the control was removed), whatever moved last.
  restore,
}

/// The last input's word on whether focus is shown.
abstract final class RawFocusVisible {
  // What hears the input now: started by the first part to hold it, gone
  // with the last to let go.
  static RawFocusHearing? _hearing;
  static FocusManager? _manager;
  static bool _shown = true;
  static final ObserverList<VoidCallback> _listeners =
      ObserverList<VoidCallback>();

  /// Whether focus is shown now: in Flutter's traditional highlight mode
  /// (no touch since the last key), and no pointer pressed since the last
  /// key. Before any input it is shown, as Flutter's highlight mode is.
  /// Always, when the app keeps the traditional mode for good
  /// ([FocusHighlightStrategy.alwaysTraditional]).
  static bool get shown {
    final manager = FocusManager.instance;
    _meet(manager);
    if (manager.highlightStrategy == FocusHighlightStrategy.alwaysTraditional) {
      return true;
    }
    return _shown && manager.highlightMode == FocusHighlightMode.traditional;
  }

  // A new focus manager (each test has its own): the input starts again.
  static void _meet(FocusManager manager) {
    if (identical(manager, _manager)) return;
    _manager = manager;
    _shown = true;
    _primary = manager.primaryFocus;
    _arrival = RawFocusArrival.keyboard;
  }

  static FocusNode? _primary;
  static RawFocusArrival _arrival = RawFocusArrival.keyboard;

  /// How the primary focus arrived. Read as soon as a focus change is told
  /// (a node's `onFocusChange`), it is already the new focus's.
  static RawFocusArrival get arrival {
    _meet(FocusManager.instance);
    _classify();
    return _arrival;
  }

  /// Whether the primary focus came from the keys, as a tip or a hover card
  /// shows for focus: shown now, and not given back. An app that keeps the
  /// traditional highlight mode for good shows it for a pointer's too.
  static bool get keyboardArrival {
    if (!shown) return false;
    final arrival = RawFocusVisible.arrival;
    if (arrival == RawFocusArrival.restore) return false;
    return arrival == RawFocusArrival.keyboard ||
        FocusManager.instance.highlightStrategy ==
            FocusHighlightStrategy.alwaysTraditional;
  }

  static void _classify() {
    final manager = FocusManager.instance;
    final now = manager.primaryFocus;
    if (identical(now, _primary)) return;
    final old = _primary;
    _primary = now;
    if (now == null) return;
    // Given back: what held it closed or went. Focus that rests on a scope
    // (no control) and then moves on was moved by the input, as any other.
    if (RawQuietFocus.isRestoring ||
        (old != null && old is! FocusScopeNode && _lost(old))) {
      _arrival = RawFocusArrival.restore;
    } else {
      _arrival =
          _shown && manager.highlightMode == FocusHighlightMode.traditional
          ? RawFocusArrival.keyboard
          : RawFocusArrival.pointer;
    }
  }

  // Whether [node] can no longer hold the focus: removed, in a scope that
  // turned it away, or in a route on its way out (popped, or removed).
  static bool _lost(FocusNode node) {
    if (identical(node, FocusManager.instance.rootScope)) return false;
    final context = node.context;
    if (context == null ||
        !context.mounted ||
        node.parent == null ||
        !node.canRequestFocus) {
      return true;
    }
    final route = ModalRoute.of(context);
    return route != null && !route.isActive;
  }

  /// Hears the input until the returned hearing is released. Every part
  /// that paints its focus, or shows something on it, holds one from its
  /// mounting to its disposal, so the press that opens a surface is heard
  /// before the surface takes the focus.
  ///
  /// What it hears by (a global pointer route, a key handler, a semantics
  /// action listener, a focus manager listener and a highlight mode
  /// listener) is its own each time the first part holds it, and is
  /// taken away when the last lets go: nothing is kept for the life of the
  /// bindings. A page drawn with ui_core instantiated afresh over a binding
  /// that lives on (App Preview's) neither meets the last page's
  /// registration nor leaves its own.
  static RawFocusHearing hold() {
    _meet(FocusManager.instance);
    final hearing = _hearing ??= RawFocusHearing._().._start();
    hearing._holds++;
    return hearing;
  }

  /// Forgets what it hears with, as ui_core instantiated afresh over the
  /// same bindings does (App Preview drawing a page), leaving what the
  /// mounted parts hold in place: they let go of it as they go.
  @visibleForTesting
  static void debugForget() {
    _hearing = null;
    _manager = null;
    _shown = true;
    _primary = null;
    _arrival = RawFocusArrival.keyboard;
  }

  /// Calls [listener] when [shown] may have changed.
  static void addListener(VoidCallback listener) => _listeners.add(listener);

  /// Stops calling [listener].
  static void removeListener(VoidCallback listener) =>
      _listeners.remove(listener);

  // A key shows the focus, but not one pressed with Control, Alt or Meta (a
  // shortcut, or a modifier held for a click), as browsers decide.
  static bool _key(KeyEvent event) {
    if (event is KeyUpEvent) return false;
    final keys = HardwareKeyboard.instance;
    if (keys.isControlPressed || keys.isAltPressed || keys.isMetaPressed) {
      return false;
    }
    _set(true);
    return false;
  }

  static void _pointer(PointerEvent event) {
    if (event is PointerDownEvent) _set(false);
  }

  // A tap or a focus with no key held is a pointer's or a screen reader's:
  // on the web with semantics on, a click focuses the pressed control's node
  // and reaches the app as a tap, before the press (if ever). A Tab that
  // moves the browser's focus holds its key.
  static void _semantics(SemanticsActionEvent event) {
    if (event.type != SemanticsAction.tap &&
        event.type != SemanticsAction.longPress &&
        event.type != SemanticsAction.focus) {
      return;
    }
    if (HardwareKeyboard.instance.logicalKeysPressed.isEmpty) _set(false);
  }

  static void _set(bool shown) {
    if (shown == _shown) return;
    _shown = shown;
    _notify();
  }

  // Flutter's highlight mode switches after the key handlers have run (a
  // key after a touch): [shown] reads it, so its listeners hear the switch.
  static void _modeSwitched() => _notify();

  static void _notify() {
    for (final listener in List<VoidCallback>.of(_listeners)) {
      if (_listeners.contains(listener)) listener();
    }
  }
}

/// What [RawFocusVisible] hears the input by while parts hold it: its
/// own pointer route, key handler, semantics action listener, focus manager
/// listener and highlight mode listener (each this object's, so equal to no
/// other's), registered as the first part holds it and removed as the last
/// [release]s it.
final class RawFocusHearing {
  RawFocusHearing._();

  int _holds = 0;
  late final PointerRouter _router;
  late final HardwareKeyboard _keys;
  late final SemanticsBinding _semantics;
  late final FocusManager _focus;

  void _start() {
    _router = GestureBinding.instance.pointerRouter;
    _keys = HardwareKeyboard.instance;
    _semantics = SemanticsBinding.instance;
    _focus = FocusManager.instance;
    _focus.addListener(_focusChanged);
    _focus.addHighlightModeListener(_modeChanged);
    _keys.addHandler(_key);
    _router.addGlobalRoute(_pointer);
    _semantics.addSemanticsActionListener(_action);
  }

  /// Lets go of it: the last part to let go takes its registrations away.
  void release() {
    assert(_holds > 0, 'a hearing released more often than held');
    if (_holds == 0 || --_holds > 0) return;
    _keys.removeHandler(_key);
    _router.removeGlobalRoute(_pointer);
    _semantics.removeSemanticsActionListener(_action);
    _focus.removeListener(_focusChanged);
    _focus.removeHighlightModeListener(_modeChanged);
    if (identical(RawFocusVisible._hearing, this)) {
      RawFocusVisible._hearing = null;
    }
  }

  bool _key(KeyEvent event) => RawFocusVisible._key(event);

  void _pointer(PointerEvent event) => RawFocusVisible._pointer(event);

  void _action(SemanticsActionEvent event) => RawFocusVisible._semantics(event);

  void _modeChanged(FocusHighlightMode mode) {
    if (identical(_focus, FocusManager.instance)) {
      RawFocusVisible._modeSwitched();
    }
  }

  void _focusChanged() {
    // A focus manager that is not the one in use (one a test swapped out)
    // classifies nothing.
    if (identical(_focus, FocusManager.instance)) {
      RawFocusVisible._classify();
    }
  }
}

/// Whether a part shows its focus, as ui_core's own parts decide it and a
/// browser's `:focus-visible` does: shown after a key, hidden after a
/// pointer's press (a mouse, a finger, a pen) and after a click that reaches
/// the app as a semantics action (on the web with semantics on), until the
/// next key.
///
/// `RawButton` and the other ui_core parts show their focus by it, and a
/// look's own pressable on a [FocusableActionDetector] takes it too. The
/// detector's [FocusableActionDetector.onShowFocusHighlight] follows
/// Flutter's focus highlight mode, which a mouse leaves traditional, so a
/// row a click focused, or one a click-opened menu gives the focus back to,
/// keeps its ring after use. Give that callback to [focused], paint the
/// focus by what [onChanged] hears, and [dispose] it with the part:
///
/// ```dart
/// late final RawFocusShown _focus = RawFocusShown(
///   (shown) => setState(() => _ring = shown),
/// );
///
/// @override
/// void dispose() {
///   _focus.dispose();
///   super.dispose();
/// }
///
/// @override
/// Widget build(BuildContext context) => FocusableActionDetector(
///   onShowFocusHighlight: _focus.focused,
///   child: DecoratedBox(
///     decoration: BoxDecoration(border: _ring ? Border.all(width: 2) : null),
///     child: widget.child,
///   ),
/// );
/// ```
class RawFocusShown {
  /// Tells [onChanged] whether the part shows its focus, hearing the input
  /// until [dispose].
  RawFocusShown(this.onChanged) : _hearing = RawFocusVisible.hold();

  /// Hears whether the part shows its focus, as it changes.
  final ValueChanged<bool> onChanged;

  RawFocusHearing? _hearing;

  bool _focused = false;
  bool _value = false;

  /// Whether the part shows its focus.
  bool get value => _value;

  /// Whether the part has the focus Flutter would highlight: what a
  /// [FocusableActionDetector.onShowFocusHighlight] says, or a focus in the
  /// traditional highlight mode. [onChanged] hears whether it shows.
  void focused(bool on) {
    if (on != _focused) {
      _focused = on;
      on
          ? RawFocusVisible.addListener(_update)
          : RawFocusVisible.removeListener(_update);
    }
    _value = on && RawFocusVisible.shown;
    onChanged(_value);
  }

  void _update() {
    final value = _focused && RawFocusVisible.shown;
    if (value == _value) return;
    _value = value;
    onChanged(value);
  }

  /// Stops hearing the input.
  void dispose() {
    RawFocusVisible.removeListener(_update);
    _hearing?.release();
    _hearing = null;
  }
}
