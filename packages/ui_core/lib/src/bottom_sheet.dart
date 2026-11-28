/// A bottom sheet, headless: a modal route whose panel rises from the
/// bottom edge on a spring and rests at one of its sizes, or at its
/// content's own height. A drag moves it with the finger, the scroll view
/// inside handing the drag over at its top; let go, it settles on a size or
/// slides away. Focus moves into it and back as it closes; Escape, Android's
/// back and a barrier tap close it.
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart' show DragStartBehavior;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'barrier.dart';
import 'haptics.dart';
import 'internal/barrier_clip.dart';
import 'internal/gesture_focus.dart';
import 'internal/kept_clear.dart';
import 'internal/painted_barrier.dart';
import 'internal/route_spring.dart';
import 'internal/sheet_scroll.dart';
import 'localizations.dart';
import 'motion.dart';
import 'pressable.dart';

/// Builds a bottom sheet's panel from [details].
typedef RawBottomSheetBuilder = Widget Function(
  BuildContext context,
  RawBottomSheetDetails details,
);

/// What a [RawBottomSheetRoute]'s panel paints from.
@immutable
class RawBottomSheetDetails {
  /// The panel's details; the route makes them.
  const RawBottomSheetDetails({
    required this.animation,
    required this.size,
    required this.snapSizes,
    required this.dragging,
    required this.scrollController,
    required this.close,
  });

  /// The sheet's presence on the route's spring: 0 gone, 1 open, for the
  /// look's own fades. An underdamped token passes 1 before it rests; clamp
  /// it before an `Opacity`. Under Reduce Motion it stays at 1.
  final Animation<double> animation;

  /// The panel's height as a share of the room it has (the screen less the
  /// on-screen keyboard, and the top inset with `useSafeArea`), live through
  /// drags and settles: a look's corner that squares as it reaches the top.
  final Animation<double> size;

  /// The sizes it rests at ([RawBottomSheetRoute.snapSizes]); empty for
  /// a sheet at its content's own height.
  final List<double> snapSizes;

  /// Whether a finger is moving it (its own drag, or its content's handed
  /// over).
  final bool dragging;

  /// Give it to the panel's scroll view: a drag up grows the sheet to its
  /// largest size before the content scrolls, and a drag down with the
  /// content at its top shrinks the sheet or slides it away.
  final ScrollController scrollController;

  /// Closes it through `Navigator.maybePop`, so a `PopScope` may refuse: a
  /// close button.
  final VoidCallback close;
}

/// Drives an open [RawBottomSheetRoute]'s size from outside it, as
/// `DraggableScrollableController` drives a sheet, on the route's spring.
/// The caller makes it, gives it to one route at a time, and disposes it.
class RawBottomSheetController extends ChangeNotifier {
  _SheetHost? _host;

  /// Whether a pushed route is using it.
  bool get isAttached => _host != null;

  /// The panel's height as a share of the room it has
  /// ([RawBottomSheetDetails.size]). Only while [isAttached].
  double get size {
    assert(isAttached, 'the controller is not attached to a sheet');
    return _host!.share;
  }

  /// Moves the sheet on its spring to the snap size nearest [size].
  Future<void> animateTo(double size) {
    assert(isAttached, 'the controller is not attached to a sheet');
    return _host!.animateToSize(size);
  }

  /// Puts the sheet at the snap size nearest [size] at once.
  void jumpTo(double size) {
    assert(isAttached, 'the controller is not attached to a sheet');
    _host!.jumpToSize(size);
  }

  void _attach(_SheetHost host) {
    assert(_host == null, 'a controller drives one sheet at a time');
    _host = host;
  }

  void _detach(_SheetHost host) {
    if (_host == host) _host = null;
  }

  void _changed() => notifyListeners();
}

// What the controller and the drag handle reach of a route, whatever its T.
abstract interface class _SheetHost {
  double get share;
  List<double> get stops;
  double get stop;
  Future<void> animateToSize(double size);
  void jumpToSize(double size);
  void close();
  Listenable get changes;
  ValueListenable<bool> get dragging;
}

/// A modal bottom sheet. Push it with `Navigator.push`; its panel is
/// [builder]'s, the screen's width, rising from the bottom edge.
///
/// It stands on `RawAdaptiveShell`'s navigation bar where the app's
/// [RawToaster] keeps it clear, so a floating panel never leaves a strip of
/// it showing under it: its room ends at the bar's top, the bar stays whole
/// under the barrier (a tap there closes it, as on any of the barrier), and
/// the bottom inset its content sees is what the screen's has left past the
/// bar. A page's foot (a Save key kept clear with [RawToasterKeepClear],
/// on the bar or at the screen's foot) belongs to the page under the
/// barrier, and the panel covers it; so does a key floating over the bar.
/// The keyboard, where taller, lifts it. Pushed where the bar is not under
/// it (a place's own navigator, a pushed page with the bar gone, an app
/// with no toaster) it stands on the screen's foot.
///
/// With [snapSizes] it rests at one of them, each a share of the room it has
/// (the screen less the on-screen keyboard or the bars it stands on, and the
/// top inset with [useSafeArea]), opening at [initialSize], and is laid out
/// at its size, so
/// a footer at its bottom shows at every size. With none it rests at its
/// content's own height, at most the room.
///
/// It opens, settles and closes on a spring ([dampingRatio],
/// [stiffness]), or closes on its own ([closeDampingRatio],
/// [closeStiffness]); under Reduce Motion it fades instead of rising. A drag
/// ([enableDrag]) moves it with the finger, from where it is drawn: past its
/// largest size it gives a little and resists; below its smallest it slides
/// away. Let go, it settles on the size nearest, or, flung, on the next one
/// the fling points to; below half its smallest size, or flung down from
/// there, it closes. Its content's scroll view hands drags over
/// ([RawBottomSheetDetails.scrollController]).
///
/// It closes through `Navigator.maybePop` on Escape, Android's back, a
/// barrier tap ([barrierDismissible]), a drag and
/// [RawBottomSheetDetails.close], so a `PopScope` may refuse any of them;
/// refused, a dragged sheet springs back. Focus moves into it and stays
/// there, and goes back to what held it as it closes. When opened from a
/// focused control, keyboard focus starts at the first stop unless the
/// content supplies its own autofocus. A screen reader hears
/// it named by [semanticLabel], and can dismiss it.
///
/// The haptics table ([RawHaptics]) plays `thresholdCrossed` as a drag
/// passes the point where letting go closes it, and `selectionChanged` as a
/// drag settles it on another size.
///
/// ```dart
/// RawBottomSheetRoute<void>(
///   snapSizes: const [0.5, 1],
///   builder: (context, details) => ListView(
///     controller: details.scrollController,
///     children: [for (var i = 0; i < 30; i++) Text('Row $i')],
///   ),
/// )
/// ```
class RawBottomSheetRoute<T> extends PopupRoute<T> {
  /// A sheet whose panel [builder] paints.
  RawBottomSheetRoute({
    required this.builder,
    List<double>? snapSizes,
    double? initialSize,
    this.sheetController,
    this.enableDrag = true,
    this.useSafeArea = false,
    this.dampingRatio = 1,
    this.stiffness = 700,
    this.closeDampingRatio,
    this.closeStiffness,
    Color barrierColor = const Color(0x66000000),
    this.barrierBuilder,
    String? barrierLabel,
    bool barrierDismissible = true,
    this.semanticLabel,
    super.settings,
  }) : assert(
         snapSizes == null ||
             (snapSizes.isNotEmpty &&
                 snapSizes.first > 0 &&
                 snapSizes.last <= 1 &&
                 _ascending(snapSizes)),
         'snapSizes ascend, each in (0, 1]',
       ),
       assert(
         initialSize == null ||
             (snapSizes != null && snapSizes.contains(initialSize)),
         'initialSize is one of snapSizes',
       ),
       assert(dampingRatio > 0 && stiffness > 0),
       assert((closeDampingRatio ?? 1) > 0 && (closeStiffness ?? 1) > 0),
       snapSizes = snapSizes == null
           ? const []
           : List<double>.unmodifiable(snapSizes),
       initialSize = initialSize ?? snapSizes?.first,
       _scrim = barrierColor,
       _givenBarrierLabel = barrierLabel,
       _dismissOnBarrier = barrierDismissible,
       _spring = RouteSpring(
         dampingRatio: dampingRatio,
         stiffness: stiffness,
         closeDampingRatio: closeDampingRatio,
         closeStiffness: closeStiffness,
       );

  static bool _ascending(List<double> sizes) {
    for (var i = 1; i < sizes.length; i++) {
      if (sizes[i] <= sizes[i - 1]) return false;
    }
    return true;
  }

  /// Paints the panel.
  final RawBottomSheetBuilder builder;

  /// The sizes it rests at, ascending, each a share of the room in (0, 1];
  /// empty: one rest at its content's own height.
  final List<double> snapSizes;

  /// The size it opens at, one of [snapSizes]; null: the smallest (or its
  /// content's height).
  final double? initialSize;

  /// Moves it from outside; the caller's, never disposed by the route.
  /// (Not `controller`: a route's `controller` is its own animation's.)
  final RawBottomSheetController? sheetController;

  /// Whether a drag moves it. Defaults to true.
  final bool enableDrag;

  /// Whether its room stops under the screen's top inset (a status bar, a
  /// notch). Defaults to false.
  final bool useSafeArea;

  /// The spring's damping ratio (ζ): it opens and settles on it, and
  /// closes on it unless [closeDampingRatio] is given. Defaults to 1.
  final double dampingRatio;

  /// The spring's stiffness (k), and the close spring's unless
  /// [closeStiffness] is given. Defaults to 700.
  final double stiffness;

  /// The close spring's damping ratio (ζ); null: [dampingRatio]. A look
  /// whose sheet falls away on a spring of its own sets it with
  /// [closeStiffness].
  final double? closeDampingRatio;

  /// The close spring's stiffness (k); null: [stiffness].
  final double? closeStiffness;

  /// Paints the barrier in place of the barrier colour (a look's own
  /// screen); null: the colour.
  final RawBarrierBuilder? barrierBuilder;

  /// What a screen reader calls it; null:
  /// [RawWidgetsLocalizations.bottomSheetLabel].
  final String? semanticLabel;

  final Color _scrim;
  final String? _givenBarrierLabel;
  final bool _dismissOnBarrier;
  final RouteSpring _spring;
  final RouteFocusReturn _focus = RouteFocusReturn();
  final GestureFocus _gestureFocus = GestureFocus();
  final ValueNotifier<bool> _dragging = ValueNotifier(false);
  late final _SheetDrag _drag = _SheetDrag(this);
  late final _SheetHost _host = _RouteHost(this);
  late final ScrollController _scroll = enableDrag
      ? SheetScrollController(_drag)
      : ScrollController();

  // The size, in the sheet's own units: a share of the room with snap
  // sizes, else a multiple of its content's height (1 at rest).
  AnimationController? _size;
  late final _SizeShare _share = _SizeShare(this);

  // The room's height, and the content's own, as last laid out.
  double _room = 0;
  double _content = 0;
  // What stands under the panel from the screen's foot, as the page was last
  // built: the keyboard, or the bars it stands on where they are taller.
  double _under = 0;

  // A drag moved it since it last rested: under Reduce Motion it moves with
  // the finger, and slides on from there.
  bool _dragged = false;
  // Past the point where letting go closes it.
  bool _armed = false;
  // The size the drag began at.
  double _from = 1;
  bool _popped = false;
  bool _disposed = false;

  bool get _snaps => snapSizes.isNotEmpty;

  List<double> get _stops => _snaps ? snapSizes : const [1];

  double get _min => _stops.first;
  double get _max => _stops.last;

  // The pixels one size unit is.
  double get _unit => _snaps ? _room : _content;

  double get _stop => _nearest(_size?.value ?? _min);

  double _nearest(double size) {
    var best = _stops.first;
    for (final s in _stops) {
      if ((s - size).abs() < (best - size).abs()) best = s;
    }
    return best;
  }

  /// What a screen reader calls the barrier; null:
  /// [RawWidgetsLocalizations.modalBarrierDismissLabel].
  @override
  String? get barrierLabel {
    final context = navigator?.context;
    return _givenBarrierLabel ??
        (context == null
            ? null
            : RawWidgetsLocalizations.of(context).modalBarrierDismissLabel);
  }

  /// The barrier's colour; null while [barrierBuilder] paints it.
  @override
  Color? get barrierColor => barrierBuilder == null ? _scrim : null;

  /// Whether a barrier tap closes it. Defaults to true.
  @override
  bool get barrierDismissible => _dismissOnBarrier;

  /// Focus stays inside it: Tab from its last stop goes to its first.
  @override
  TraversalEdgeBehavior get traversalEdgeBehavior =>
      TraversalEdgeBehavior.closedLoop;

  /// Nominal: the spring decides how long it takes ([createSimulation]).
  @override
  Duration get transitionDuration => const Duration(milliseconds: 300);

  // What the panel covers of the barrier, from the screen's foot: a screen
  // reader outlines the barrier above it, where a tap reaches it.
  final ValueNotifier<EdgeInsets> _barrierClip = ValueNotifier(EdgeInsets.zero);

  @override
  Widget buildModalBarrier() {
    final barrier = clippedModalBarrier(this, _barrierClip);
    final paint = barrierBuilder;
    return paint == null ? barrier : paintedBarrier(paint, animation!, barrier);
  }

  @override
  void install() {
    final opener = FocusManager.instance.primaryFocus;
    final fromFocusedControl =
        opener != null &&
        opener is! FocusScopeNode &&
        FocusManager.instance.highlightMode == FocusHighlightMode.traditional;
    _focus.capture();
    super.install();
    if (fromFocusedControl) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Let the navigator and an explicit autofocus in the panel settle.
        scheduleMicrotask(() {
          final page = subtreeContext;
          if (_disposed || !isCurrent || page == null) return;
          final scope = FocusScope.of(page);
          if (scope.hasPrimaryFocus) scope.nextFocus();
        });
      });
    }
    _spring.attach(controller!);
    controller!.addStatusListener(_rested);
    _size = AnimationController.unbounded(
      vsync: navigator!,
      value: initialSize ?? 1,
    );
    final sheetController = this.sheetController;
    if (sheetController != null) {
      sheetController._attach(_host);
      _size!.addListener(sheetController._changed);
    }
  }

  /// The spring from where the sheet is to open or gone, carrying a drag's
  /// speed.
  @override
  Simulation createSimulation({required bool forward}) =>
      _spring.simulation(navigator!.context, to: forward ? 1 : 0);

  @override
  bool didPop(T? result) {
    _popped = true;
    final popped = super.didPop(result);
    _focus.giveBack();
    return popped;
  }

  @override
  void dispose() {
    _disposed = true;
    final sheetController = this.sheetController;
    if (sheetController != null) {
      _size?.removeListener(sheetController._changed);
      sheetController._detach(_host);
    }
    _size?.dispose();
    _scroll.dispose();
    _dragging.dispose();
    _barrierClip.dispose();
    super.dispose();
  }

  void _rested(AnimationStatus status) {
    if (!_dragging.value && !status.isAnimating) _dragged = false;
  }

  BuildContext get _here => subtreeContext ?? navigator!.context;

  void _close() => navigator?.maybePop();

  Future<void> _animateToSize(double size) {
    final to = _nearest(size);
    final s = _size!;
    if (s.value == to) return Future<void>.value();
    return s.animateWith(
      rawSpringSimulation(
        _spring.springAt(_here),
        from: s.value,
        to: to,
        velocity: s.velocity,
      ),
    );
  }

  void _jumpToSize(double size) {
    _size!
      ..stop()
      ..value = _nearest(size);
  }

  // -- The drag --------------------------------------------------------

  void _dragStart() {
    if (_dragging.value || !isCurrent) return;
    controller!.stop();
    _size!.stop();
    _dragged = true;
    _from = _stop;
    _armed = controller!.value < 0.5;
    _dragging.value = true;
    // A user gesture takes the focus out of the route; let go open, the
    // route has it back.
    _gestureFocus.hold(this);
    navigator?.didStartUserGesture();
  }

  // [dy]: logical pixels, down positive. Returns what it did not take.
  double _dragUpdate(double dy, {required bool stretch}) {
    if (!_dragging.value) return dy;
    final c = controller!;
    final s = _size!;
    final unit = _unit;
    if (unit <= 0) return dy;
    final smallest = _min * unit;
    if (dy > 0) {
      // Down: to the smallest size, then away.
      var down = dy;
      if (s.value > _min) {
        final take = math.min(down, (s.value - _min) * unit);
        s.value -= take / unit;
        down -= take;
      }
      if (down > 0) c.value = (c.value - down / smallest).clamp(0.0, 1.0);
    } else {
      // Up: back in, then to the largest size, then (stretching) it gives.
      var up = -dy;
      if (c.value < 1) {
        final take = math.min(up, (1 - c.value) * smallest);
        c.value += take / smallest;
        up -= take;
      }
      if (up > 0 && s.value < _max) {
        final take = math.min(up, (_max - s.value) * unit);
        s.value += take / unit;
        up -= take;
      }
      if (up > 0 && stretch) {
        if (_snaps && _max < 1) {
          final over = ((s.value - _max) / (1 - _max)).clamp(0.0, 1.0);
          final give = up * 0.5 * math.pow(1 - over, 2);
          s.value = math.min(1.0, s.value + give / unit);
        }
        up = 0;
      }
      if (up > 0) return -up;
    }
    final armed = c.value < 0.5;
    if (armed && !_armed) {
      RawHaptics.of(_here).thresholdCrossed?.call();
    }
    _armed = armed;
    return 0;
  }

  // The content's scroll view went while a drag moved the sheet. It goes as
  // the tree is torn down, when nothing may rebuild, so the drag ends after
  // the frame: let go where it is, or just over with the route closing or
  // gone.
  void _dragAbandon() {
    if (_disposed || !_dragging.value) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_disposed || !_dragging.value) return;
      if (_popped || !isActive) {
        _dragging.value = false;
        navigator?.didStopUserGesture();
      } else {
        _dragEnd(0);
      }
    }, debugLabel: 'RawBottomSheetRoute.dragAbandon');
  }

  // A drag past this speed, in logical pixels a second, is a fling: it
  // settles on the next size it points to. Material's.
  static const double _fling = 700;

  // [velocity]: logical pixels a second, down positive.
  void _dragEnd(double velocity) {
    if (!_dragging.value) return;
    _dragging.value = false;
    navigator?.didStopUserGesture();
    final c = controller!;
    final s = _size!.value;
    final unit = _unit;
    final smallest = _min * unit;
    final slid = c.value < 1;
    double? to;
    if (velocity >= _fling) {
      for (final stop in _stops.reversed) {
        if (stop < s - 1e-6) {
          to = stop;
          break;
        }
      }
      if (slid) to = null;
    } else if (velocity <= -_fling) {
      to = slid ? _min : _max;
      for (final stop in _stops) {
        if (!slid && stop > s + 1e-6) {
          to = stop;
          break;
        }
      }
    } else {
      to = c.value < 0.5 ? null : _nearest(s);
    }
    if (to == null) {
      _dismiss(velocity, smallest);
      return;
    }
    _settle(to, velocity, smallest, unit);
  }

  void _settle(double to, double velocity, double smallest, double unit) {
    final c = controller!;
    final s = _size!;
    final here = _here;
    if (to != _from) RawHaptics.of(here).selectionChanged?.call();
    if (c.value < 1) {
      _spring.settle(
        here,
        1,
        velocity: smallest > 0 ? -velocity / smallest : 0,
      );
    }
    if (s.value != to) {
      s.animateWith(
        rawSpringSimulation(
          _spring.springAt(here),
          from: s.value,
          to: to,
          velocity: c.value < 1 || unit <= 0 ? 0 : -velocity / unit,
        ),
      );
    }
  }

  void _dismiss(double velocity, double smallest) {
    _spring.carry = smallest > 0 ? -velocity / smallest : null;
    final navigator = this.navigator;
    if (navigator == null) return;
    navigator.maybePop().then((_) {
      _spring.carry = null;
      // Refused (a PopScope): back open.
      if (!_popped && isActive) _settle(_min, 0, smallest, _unit);
    });
  }

  // -- The page --------------------------------------------------------

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    final words = RawWidgetsLocalizations.of(context);
    final media = MediaQuery.of(context);
    final top = useSafeArea ? media.padding.top : 0.0;
    Widget panel = ValueListenableBuilder<bool>(
      valueListenable: _dragging,
      builder: (context, dragging, _) => builder(
        context,
        RawBottomSheetDetails(
          animation: _spring.reduced
              ? kAlwaysCompleteAnimation
              : _spring.presence,
          size: _share,
          snapSizes: snapSizes,
          dragging: dragging,
          scrollController: _scroll,
          close: _close,
        ),
      ),
    );
    if (enableDrag) {
      panel = GestureDetector(
        behavior: HitTestBehavior.opaque,
        dragStartBehavior: DragStartBehavior.down,
        onVerticalDragStart: (_) => _dragStart(),
        onVerticalDragUpdate: (d) =>
            _dragUpdate(d.primaryDelta ?? 0, stretch: true),
        onVerticalDragEnd: (d) => _dragEnd(d.primaryVelocity ?? 0),
        onVerticalDragCancel: () => _dragEnd(0),
        child: panel,
      );
    }
    final sheet = _SheetScope(host: _host, child: panel);
    // It stands on the shell's navigation bar the nearest toaster keeps
    // clear (not on a page's foot, which it covers), or on the keyboard
    // where that is taller; the bar under it takes the bottom inset.
    return escapeCloses(
      context,
      KeptFloorBuilder(
        route: this,
        builder: (context, floor) {
          _under = math.max(media.viewInsets.bottom, floor);
          return Padding(
            padding: EdgeInsets.only(top: top, bottom: _under),
            child: _SheetLayout(
              route: this,
              child: Semantics(
                container: true,
                scopesRoute: true,
                namesRoute: true,
                explicitChildNodes: true,
                label: semanticLabel ?? words.bottomSheetLabel,
                onDismiss: _close,
                child: MediaQuery(
                  data: KeptFloorBuilder.standingOn(media, floor)
                      .removeViewInsets(removeBottom: true)
                      .removePadding(removeTop: useSafeArea),
                  child: sheet,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => _spring.reduced && !_dragged
      ? FadeTransition(opacity: animation, child: child)
      : child;
}

/// A [RawBottomSheetRoute] as a page of a [Navigator]'s page list, so a
/// sheet joins a router's pages: each parameter is the route's, and the
/// route reads the page it holds now for [builder], [semanticLabel] and
/// [barrierDismissible] (a router that gives the same key a new page
/// rebuilds the panel in place). The sizes, the springs, the drag and the
/// barrier's paint are the route's from when it was made.
///
/// A sheet over a page, its pop leaving the page list as the navigator's
/// `onDidRemovePage` says:
///
/// ```dart
/// Navigator(
///   pages: [
///     const RawPage<void>(
///       transitionsBuilder: FadeUpwardsPageTransitionsBuilder(),
///       child: Text('Recipe'),
///     ),
///     RawBottomSheetPage<void>(
///       builder: (context, details) => const Text('Share'),
///     ),
///   ],
///   onDidRemovePage: (page) {},
/// )
/// ```
class RawBottomSheetPage<T> extends Page<T> {
  /// A sheet page whose panel [builder] paints.
  const RawBottomSheetPage({
    required this.builder,
    this.snapSizes,
    this.initialSize,
    this.sheetController,
    this.enableDrag = true,
    this.useSafeArea = false,
    this.dampingRatio = 1,
    this.stiffness = 700,
    this.closeDampingRatio,
    this.closeStiffness,
    this.barrierColor = const Color(0x66000000),
    this.barrierBuilder,
    this.barrierLabel,
    this.barrierDismissible = true,
    this.semanticLabel,
    super.key,
    super.canPop,
    super.onPopInvoked,
    super.name,
    super.arguments,
    super.restorationId,
  });

  /// Paints the panel ([RawBottomSheetRoute.builder]).
  final RawBottomSheetBuilder builder;

  /// The sizes it rests at ([RawBottomSheetRoute.snapSizes]); null: one
  /// rest at its content's own height.
  final List<double>? snapSizes;

  /// The size it opens at ([RawBottomSheetRoute.initialSize]).
  final double? initialSize;

  /// Moves it from outside ([RawBottomSheetRoute.sheetController]).
  final RawBottomSheetController? sheetController;

  /// Whether a drag moves it. Defaults to true.
  final bool enableDrag;

  /// Whether its room stops under the screen's top inset. Defaults to
  /// false.
  final bool useSafeArea;

  /// The spring's damping ratio (ζ). Defaults to 1.
  final double dampingRatio;

  /// The spring's stiffness (k). Defaults to 700.
  final double stiffness;

  /// The close spring's damping ratio (ζ); null: [dampingRatio].
  final double? closeDampingRatio;

  /// The close spring's stiffness (k); null: [stiffness].
  final double? closeStiffness;

  /// The barrier's colour.
  final Color barrierColor;

  /// Paints the barrier in place of [barrierColor].
  final RawBarrierBuilder? barrierBuilder;

  /// What a screen reader calls the barrier; null:
  /// [RawWidgetsLocalizations.modalBarrierDismissLabel].
  final String? barrierLabel;

  /// Whether a barrier tap closes it. Defaults to true.
  final bool barrierDismissible;

  /// What a screen reader calls it; null:
  /// [RawWidgetsLocalizations.bottomSheetLabel].
  final String? semanticLabel;

  @override
  Route<T> createRoute(BuildContext context) =>
      _PageBasedRawBottomSheetRoute<T>(this);
}

// RawBottomSheetPage's route: it reads the page it holds now.
class _PageBasedRawBottomSheetRoute<T> extends RawBottomSheetRoute<T> {
  _PageBasedRawBottomSheetRoute(RawBottomSheetPage<T> page)
    : super(
        builder: page.builder,
        snapSizes: page.snapSizes,
        initialSize: page.initialSize,
        sheetController: page.sheetController,
        enableDrag: page.enableDrag,
        useSafeArea: page.useSafeArea,
        dampingRatio: page.dampingRatio,
        stiffness: page.stiffness,
        closeDampingRatio: page.closeDampingRatio,
        closeStiffness: page.closeStiffness,
        barrierColor: page.barrierColor,
        barrierBuilder: page.barrierBuilder,
        barrierLabel: page.barrierLabel,
        barrierDismissible: page.barrierDismissible,
        semanticLabel: page.semanticLabel,
        settings: page,
      );

  RawBottomSheetPage<T> get _page => settings as RawBottomSheetPage<T>;

  @override
  RawBottomSheetBuilder get builder => _page.builder;

  @override
  String? get semanticLabel => _page.semanticLabel;

  @override
  bool get barrierDismissible => _page.barrierDismissible;
}

/// A full-screen sheet presented as an opaque page of the navigator. The
/// whole page rises on a spring and returns along the same path. With
/// Reduce Motion it fades. Escape and Back respect the page's [PopScope].
///
/// ```dart
/// RawSheetRoute<void>(builder: (context) => const Text('Edit recording'))
/// ```
class RawSheetRoute<T> extends PageRoute<T> {
  /// A full-screen page drawn by [builder]. The spring defaults match a
  /// [RawBottomSheetRoute]; a separate closing spring is optional.
  RawSheetRoute({
    required this.builder,
    this.semanticLabel,
    double dampingRatio = 1,
    double stiffness = 700,
    double? closeDampingRatio,
    double? closeStiffness,
    super.settings,
  }) : assert(dampingRatio > 0 && stiffness > 0),
       assert((closeDampingRatio ?? 1) > 0 && (closeStiffness ?? 1) > 0),
       _spring = RouteSpring(
         dampingRatio: dampingRatio,
         stiffness: stiffness,
         closeDampingRatio: closeDampingRatio,
         closeStiffness: closeStiffness,
       ),
       super(fullscreenDialog: true);

  /// Paints the full page, including its surface.
  final WidgetBuilder builder;

  /// The name announced when the page opens. Defaults to the localized
  /// bottom sheet label.
  final String? semanticLabel;

  final RouteSpring _spring;
  final RouteFocusReturn _focus = RouteFocusReturn();

  @override
  bool get maintainState => true;
  @override
  Color? get barrierColor => null;
  @override
  String? get barrierLabel => null;
  @override
  Duration get transitionDuration => const Duration(milliseconds: 300);

  @override
  void install() {
    _focus.capture();
    super.install();
    _spring.attach(controller!);
  }

  @override
  Simulation createSimulation({required bool forward}) =>
      _spring.simulation(navigator!.context, to: forward ? 1 : 0);

  @override
  bool didPop(T? result) {
    final popped = super.didPop(result);
    if (popped) _focus.giveBack();
    return popped;
  }

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) => escapeCloses(
    context,
    Semantics(
      scopesRoute: true,
      namesRoute: true,
      explicitChildNodes: true,
      label:
          semanticLabel ?? RawWidgetsLocalizations.of(context).bottomSheetLabel,
      child: SizedBox.expand(child: Builder(builder: builder)),
    ),
  );

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => _spring.reduced
      ? FadeTransition(opacity: animation, child: child)
      : SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(_spring.presence),
          child: child,
        );
}

// The panel's height as a share of the room.
class _SizeShare extends Animation<double>
    with AnimationWithParentMixin<double> {
  _SizeShare(this.route);

  final RawBottomSheetRoute<Object?> route;

  @override
  Animation<double> get parent => route._size ?? kAlwaysCompleteAnimation;

  @override
  double get value {
    final size = route._size?.value ?? route._min;
    if (route._snaps) return size.clamp(0.0, 1.0);
    final room = route._room;
    if (room <= 0) return 1;
    return (math.min(route._content * size, room) / room).clamp(0.0, 1.0);
  }
}

class _RouteHost implements _SheetHost {
  _RouteHost(this.route);

  final RawBottomSheetRoute<Object?> route;

  @override
  double get share => route._share.value;

  @override
  List<double> get stops => route._stops;

  @override
  double get stop => route._stop;

  @override
  Future<void> animateToSize(double size) => route._animateToSize(size);

  @override
  void jumpToSize(double size) => route._jumpToSize(size);

  @override
  void close() => route._close();

  @override
  Listenable get changes => route._size!;

  @override
  ValueListenable<bool> get dragging => route._dragging;
}

// The sheet's own drag, for the content's scroll view to hand over.
class _SheetDrag implements SheetDragTarget {
  _SheetDrag(this.route);

  final RawBottomSheetRoute<Object?> route;

  @override
  bool get canGrow =>
      route.animation!.value < 1 || (route._size?.value ?? 1) < route._max;

  @override
  bool get atLargest => !canGrow;

  @override
  void dragStart() => route._dragStart();

  @override
  double dragUpdate(double dy, {bool stretch = true}) =>
      route._dragUpdate(dy, stretch: stretch);

  @override
  void dragEnd(double velocity) => route._dragEnd(velocity);

  @override
  void dragAbandon() => route._dragAbandon();
}

// Lays the panel out at its size, at the room's foot, slid down by how far
// it is from open.
class _SheetLayout extends SingleChildRenderObjectWidget {
  const _SheetLayout({required this.route, required super.child});

  final RawBottomSheetRoute<Object?> route;

  // One route, one layout: the route is the same in every build.
  @override
  _RenderSheetLayout createRenderObject(BuildContext context) =>
      _RenderSheetLayout(route);
}

class _RenderSheetLayout extends RenderShiftedBox {
  _RenderSheetLayout(this._route) : super(null);

  final RawBottomSheetRoute<Object?> _route;

  Listenable? _listening;

  void _listen() {
    final size = _route._size;
    _listening = Listenable.merge([?size, _route.animation]);
    _listening!.addListener(markNeedsLayout);
  }

  void _unlisten() {
    _listening?.removeListener(markNeedsLayout);
    _listening = null;
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _listen();
  }

  @override
  void detach() {
    _unlisten();
    super.detach();
  }

  @override
  void performLayout() {
    size = constraints.biggest;
    final child = this.child;
    if (child == null) return;
    final route = _route;
    final room = size.height;
    route._room = room;
    final units = route._size?.value ?? route._min;
    double height;
    if (route._snaps) {
      height = (units.clamp(0.0, 1.0)) * room;
      child.layout(
        BoxConstraints.tightFor(width: size.width, height: height),
        parentUsesSize: true,
      );
    } else {
      child.layout(
        BoxConstraints(
          minWidth: size.width,
          maxWidth: size.width,
          maxHeight: room,
        ),
        parentUsesSize: true,
      );
      height = child.size.height;
      route._content = height;
    }
    // The barrier's node stops at the sheet's top (and the keyboard under
    // it), as Material's modal bottom sheet's does.
    route._barrierClip.value = EdgeInsets.only(
      bottom: math.min(height + route._under, room + route._under),
    );
    final c = route.animation!.value;
    final shown = route._spring.reduced && !route._dragged
        ? 1.0
        : c.clamp(0.0, 1.0);
    final data = child.parentData! as BoxParentData;
    data.offset = Offset(0, room - height * shown);
  }

  @override
  bool hitTestSelf(Offset position) => false;
}

// The open sheet, for its drag handle.
class _SheetScope extends InheritedWidget {
  const _SheetScope({required this.host, required super.child});

  final _SheetHost host;

  @override
  bool updateShouldNotify(_SheetScope oldWidget) => host != oldWidget.host;
}

class _GrowIntent extends Intent {
  const _GrowIntent();
}

class _ShrinkIntent extends Intent {
  const _ShrinkIntent();
}

/// A bottom sheet's drag handle, painted by [builder]: a button that moves
/// the sheet to its next size (from the largest back to the smallest; a
/// sheet of one size closes), Up and Down to a larger or smaller size when
/// focused, and a screen reader's increase and decrease. Put it in a
/// [RawBottomSheetRoute]'s panel. Its states take
/// [WidgetState.dragged] while a finger drags the sheet, as Material's
/// sheet's drag handle does.
///
/// ```dart
/// RawBottomSheetDragHandle(builder: (context, states) => const SizedBox(width: 32, height: 4))
/// ```
class RawBottomSheetDragHandle extends StatelessWidget {
  /// A drag handle [builder] paints.
  const RawBottomSheetDragHandle({
    super.key,
    required this.builder,
    this.semanticLabel,
  });

  /// Paints the handle in its pressable states, and dragged while the
  /// sheet is dragged.
  final Widget Function(BuildContext context, Set<WidgetState> states) builder;

  /// What a screen reader calls it; null:
  /// [RawWidgetsLocalizations.dragHandleLabel].
  final String? semanticLabel;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(
        ObjectFlagProperty<Widget Function(BuildContext, Set<WidgetState>)>.has(
          'builder',
          builder,
        ),
      )
      ..add(StringProperty('semanticLabel', semanticLabel, defaultValue: null));
  }

  @override
  Widget build(BuildContext context) {
    final host = context
        .dependOnInheritedWidgetOfExactType<_SheetScope>()
        ?.host;
    final words = RawWidgetsLocalizations.of(context);
    final label = semanticLabel ?? words.dragHandleLabel;
    if (host == null) {
      // Outside a sheet: painted, but it moves nothing.
      return RawButton(
        semanticLabel: label,
        excludeSemantics: true,
        minimumSize: const Size(40, 40),
        builder: (context, states, _) => builder(context, states),
      );
    }
    return ListenableBuilder(
      listenable: Listenable.merge([host.changes, host.dragging]),
      builder: (context, _) {
        final dragged = host.dragging.value;
        final stops = host.stops;
        final at = stops.indexOf(host.stop);
        final larger = at + 1 < stops.length ? stops[at + 1] : null;
        final smaller = at > 0 ? stops[at - 1] : null;
        void grow() => host.animateToSize(larger!);
        void shrink() => host.animateToSize(smaller!);
        return MergeSemantics(
          child: Semantics(
            onIncrease: larger == null ? null : grow,
            onDecrease: smaller == null ? null : shrink,
            child: RawButton(
              onPressed: stops.length == 1
                  ? host.close
                  : () => host.animateToSize(larger ?? stops.first),
              semanticLabel: label,
              excludeSemantics: true,
              minimumSize: const Size(40, 40),
              shortcuts: const {
                SingleActivator(LogicalKeyboardKey.arrowUp): _GrowIntent(),
                SingleActivator(LogicalKeyboardKey.arrowDown): _ShrinkIntent(),
              },
              actions: {
                _GrowIntent: CallbackAction<_GrowIntent>(
                  onInvoke: (_) => larger == null ? null : grow(),
                ),
                _ShrinkIntent: CallbackAction<_ShrinkIntent>(
                  onInvoke: (_) => smaller == null ? null : shrink(),
                ),
              },
              builder: (context, states, _) => builder(
                context,
                dragged
                    ? Set.unmodifiable({...states, WidgetState.dragged})
                    : states,
              ),
            ),
          ),
        );
      },
    );
  }
}
