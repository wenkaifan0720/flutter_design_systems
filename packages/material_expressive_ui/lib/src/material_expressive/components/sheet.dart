/// Sheets (CONTRACT §4.1 roles `sheet`, `action-sheet` and
/// `full-screen-cover`; §4.2 `ExpressiveSheetPage`). Owner: w2-sheet.
///
/// A port of Compose material3 1.5.0-alpha29's `ModalBottomSheet`
/// (`ModalBottomSheet.kt`), the `BottomSheet` it lays out (`BottomSheet.kt`)
/// and `SheetState` with its defaults (`SheetDefaults.kt`):
///
/// - [ExpressiveBottomSheet] is `BottomSheet`: the container
///   (`SheetBottomTokens`: surface container low, the extra-large top
///   corners), the drag handle (32×4dp in on-surface-variant, 22dp above
///   and below), at most 640dp wide, standing on anchors — hidden at the
///   bottom edge, partially expanded at half the height (or at the sheet's
///   own height when it is shorter: Compose's deterministic partial anchor,
///   the pinned default) and expanded at its content's height. It follows
///   a drag, and a scrollable inside it through the primary scroll
///   controller (Compose's nested scroll connection: the sheet rises before
///   the content scrolls, and falls once the content is at its top); a
///   release settles by the anchored-draggable rule (56dp positional and
///   125dp/s velocity thresholds) on the default spatial spring. `show`
///   runs the default spatial spring, `hide` and `partialExpand` the fast
///   effects spring, as `BottomSheet` sets them. A spring that carries the
///   sheet above its highest anchor stretches the container down to the
///   edge rather than open a gap (`verticalScaleUp`), and a predictive back
///   gesture scales it (48dp narrower and 24dp shorter at full progress,
///   about the point Compose's `sheetPredictiveBackScaling` names) while
///   the content keeps its aspect.
/// - [ExpressiveSheetPage] is `ModalBottomSheet` as a go_router page on the
///   root navigator: the scrim (the scrim role at 32 %, fading on the
///   default effects spring, closing the sheet on a tap), the sheet rising
///   from the bottom edge, and the platform's back: Android's predictive
///   back, and a system back that settles an expanded sheet to its partial
///   anchor before it dismisses (`settleToDismiss`); on iOS the sheet is
///   swiped down. With `drawer` it is a full-screen dialog instead
///   ([ExpressiveFullScreenDialogPage]). [showExpressiveBottomSheet] raises
///   the same sheet from code; a short list of actions is list rows in it.
///
/// The route controllers run on springs (decision F11): each route drives
/// its controller with `animateWith(SpringSimulation)` and states a
/// transition duration derived from the spring's settle time.
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show ValueListenable, mapEquals;
import 'package:material_ui/material_ui.dart' show MaterialLocalizations, Theme;
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart' show SchedulerBinding, SchedulerPhase;
import 'package:flutter/services.dart'
    show PredictiveBackEvent, SystemMouseCursors;
import 'package:flutter/widgets.dart';
import 'package:ui_core/host.dart';

import '../elevation.dart';
import '../component_themes.dart';
import '../internal/tokens/tokens.g.dart';
import '../motion.dart';
import '../states.dart';
import '../strings.dart';
import '../theme.dart';
import 'overlays.dart' show ExpressiveBackHandleRoute;
import 'sheet_page.dart';
import 'page.dart'
    show
        ExpressivePage,
        ExpressivePredictiveBackRoute,
        ExpressivePredictiveBackTransition;

// --- The sheet ---------------------------------------------------------------

/// Where a bottom sheet rests (Compose's `SheetValue`).
enum ExpressiveSheetValue {
  /// Below the bottom edge, out of sight.
  hidden,

  /// At half the height, or at its own height when it is shorter.
  partiallyExpanded,

  /// At its content's height, up to the whole screen.
  expanded,
}

/// Drives an [ExpressiveBottomSheet] (Compose's `SheetState`): where it
/// rests, where it is going, and the springs that take it there. One
/// controller serves one sheet at a time.
class ExpressiveSheetController extends ChangeNotifier {
  _ExpressiveBottomSheetState? _sheet;

  /// A [show] asked for before the sheet was built.
  bool _showOnAttach = false;

  /// Where the sheet rests, or rested before the move now under way.
  ExpressiveSheetValue get currentValue =>
      _sheet?._current ?? ExpressiveSheetValue.hidden;

  /// Where the sheet is going: [currentValue] at rest.
  ExpressiveSheetValue get targetValue =>
      _sheet?._target ?? ExpressiveSheetValue.hidden;

  /// Whether the sheet shows or is on its way to showing.
  bool get isVisible => targetValue != ExpressiveSheetValue.hidden;

  /// Whether the sheet has a partially expanded anchor.
  bool get hasPartiallyExpandedState =>
      _sheet?._anchors?.containsKey(ExpressiveSheetValue.partiallyExpanded) ??
      false;

  /// Whether the sheet has an expanded anchor.
  bool get hasExpandedState =>
      _sheet?._anchors?.containsKey(ExpressiveSheetValue.expanded) ?? false;

  /// The sheet's top, from the top of the space it stands in; null before
  /// it is laid out.
  double? get offset => _sheet?._anchors == null ? null : _sheet!._position;

  /// Raises the sheet to its partial anchor, or its expanded one when it
  /// has none, on the default spatial spring. Before the sheet is laid out
  /// the move waits for its first layout.
  Future<void> show() {
    final sheet = _sheet;
    if (sheet == null) {
      _showOnAttach = true;
      return Future<void>.value();
    }
    return sheet._show();
  }

  /// Lowers the sheet out of sight on the fast effects spring.
  Future<void> hide() =>
      _sheet?._animateTo(ExpressiveSheetValue.hidden, _hideMotion) ??
      Future<void>.value();

  /// Raises the sheet to its expanded anchor on the default spatial spring.
  Future<void> expand() =>
      _sheet?._animateTo(ExpressiveSheetValue.expanded, _showMotion) ??
      Future<void>.value();

  /// Settles the sheet on its partial anchor on the fast effects spring.
  Future<void> partialExpand() =>
      _sheet?._animateTo(ExpressiveSheetValue.partiallyExpanded, _hideMotion) ??
      Future<void>.value();

  void _changed() => notifyListeners();
}

/// `BottomSheet.kt`: `showMotionSpec = defaultSpatialSpec`; a fling settles
/// on `anchoredDraggableMotionSpec`, also `defaultSpatialSpec`.
const ExpressiveMotionKey _showMotion = ExpressiveMotionKey.defaultSpatial;

/// `BottomSheet.kt`: `hideMotionSpec = fastEffectsSpec` (which
/// `SheetState.partialExpand` runs too).
const ExpressiveMotionKey _hideMotion = ExpressiveMotionKey.fastEffects;

/// The spring a cancelled predictive back gesture returns on. Compose
/// animates the progress back with `Animatable.animateTo`'s default
/// `spring()` (damping 1, stiffness 1500), which no motion key states; the
/// default effects spring (damping 1, stiffness 1600) is the nearest.
const ExpressiveMotionKey _backMotion = ExpressiveMotionKey.defaultEffects;

/// Compose's `BottomSheet`: a sheet on anchors over the space it is given
/// (see the library doc). Give it the whole screen: it stands at the
/// bottom, centred, at most 640dp wide.
///
/// It starts at [initialValue] (hidden by default, as Compose's state does;
/// [ExpressiveSheetController.show] raises it). [child] is laid out in the
/// space under the drag handle and above the bottom inset; a vertical
/// scrollable in it that uses the primary scroll controller hands its drag
/// to the sheet as Compose's nested scroll does. The sheet pads its own
/// insets (the top one only as it reaches the status bar) and removes them
/// from [child]'s media query.
///
/// Compose has no action sheet: its list items in this sheet are one, so the
/// bottom sheet stands for the `action-sheet` role (the `sheet` role's
/// primary is [ExpressiveSheetPage]).
class ExpressiveBottomSheet extends StatefulWidget {
  /// A bottom sheet showing [child].
  const ExpressiveBottomSheet({
    required this.child,
    this.controller,
    this.initialValue = ExpressiveSheetValue.hidden,
    this.skipPartiallyExpanded = false,
    this.gesturesEnabled = true,
    this.dragHandle = const ExpressiveSheetDragHandle(),
    this.onDismissRequest,
    this.confirmHide,
    this.predictiveBackProgress,
    this.style,
    super.key,
  });

  /// Stateful visual overrides before the bottom-sheet theme.
  final ExpressiveComponentThemeData? style;

  /// The sheet's content.
  final Widget child;

  /// Drives the sheet; one is made when null.
  final ExpressiveSheetController? controller;

  /// Where the sheet stands at its first layout. A partial anchor the sheet
  /// does not have falls to the expanded one.
  final ExpressiveSheetValue initialValue;

  /// Whether the sheet has no partial anchor.
  final bool skipPartiallyExpanded;

  /// Whether a drag moves the sheet.
  final bool gesturesEnabled;

  /// The drag handle over the content (Compose's `dragHandle` slot,
  /// `BottomSheetDefaults.DragHandle` by default); null draws none. The
  /// sheet makes it tappable and gives it the sheet's accessibility
  /// actions.
  final Widget? dragHandle;

  /// Told when the sheet has settled out of sight by the user's hand (a
  /// fling down, the handle): its owner removes it.
  final VoidCallback? onDismissRequest;

  /// Asked before the user's hand (a drag or fling, the handle) hides the
  /// sheet (Compose's `confirmValueChange` for `Hidden`); false keeps it
  /// up, and a released sheet springs back to its anchor. Null allows it.
  final bool Function()? confirmHide;

  /// A predictive back gesture's eased progress (0 to 1), which scales the
  /// sheet; null when nothing drives one.
  final ValueListenable<double>? predictiveBackProgress;

  /// The sheet's container.
  static const Key containerKey = ValueKey<String>(
    'expressive-sheet:container',
  );

  @override
  State<ExpressiveBottomSheet> createState() => _ExpressiveBottomSheetState();
}

class _ExpressiveBottomSheetState extends State<ExpressiveBottomSheet>
    with SingleTickerProviderStateMixin {
  /// The sheet's top while it moves (a spring or a drag), in logical px
  /// from the top of its space. At rest the sheet stands on its anchor.
  late final AnimationController _offset = AnimationController.unbounded(
    vsync: this,
  )..addListener(_onOffset);

  ExpressiveSheetController? _ownController;
  ExpressiveSheetController get _controller =>
      widget.controller ?? (_ownController ??= ExpressiveSheetController());

  late ExpressiveSheetValue _current = widget.initialValue;
  late ExpressiveSheetValue _target = widget.initialValue;

  /// The anchor a running spring is taking the sheet to.
  ExpressiveSheetValue? _animatingTo;
  Completer<void>? _arrival;

  bool _dragging = false;
  bool _showPending = false;

  /// The anchors of the last layout, and the sizes they came from.
  Map<ExpressiveSheetValue, double>? _anchors;
  double _fullHeight = 0;
  double _sheetHeight = 0;
  double _sheetWidth = 0;

  /// The status bar's inset, and the part of it the sheet pads as it
  /// reaches it (Compose's `SheetWindowInsets` consumes the rest).
  double _topInset = 0;
  final ValueNotifier<double> _topPadding = ValueNotifier<double>(0);

  late final _SheetScrollController _scroll = _SheetScrollController(this);

  @override
  void initState() {
    super.initState();
    _attach(_controller);
  }

  void _attach(ExpressiveSheetController controller) {
    controller._sheet = this;
    if (controller._showOnAttach) {
      controller._showOnAttach = false;
      _showPending = true;
    }
  }

  @override
  void didUpdateWidget(ExpressiveBottomSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      final previous = oldWidget.controller ?? _ownController;
      if (previous?._sheet == this) previous!._sheet = null;
      _attach(_controller);
    }
  }

  @override
  void dispose() {
    if (_controller._sheet == this) _controller._sheet = null;
    _ownController?.dispose();
    _arrive();
    _offset.dispose();
    _topPadding.dispose();
    _scroll.dispose();
    super.dispose();
  }

  bool get _moving => _dragging || _offset.isAnimating;

  bool get _gesturesActive =>
      widget.gesturesEnabled && _current != ExpressiveSheetValue.hidden;

  double get _minAnchor => _anchors!.values.reduce(math.min);

  double get _maxAnchor => _anchors!.values.reduce(math.max);

  /// Where the sheet's top stands now.
  double get _position {
    if (_moving) return _offset.value;
    return _anchors?[_current] ?? _fullHeight;
  }

  void _onOffset() {
    final arrived = _animatingTo;
    if (arrived != null && !_offset.isAnimating) {
      _animatingTo = null;
      _current = arrived;
      _changed();
      _arrive();
    }
  }

  /// Tells the controller, and rebuilds: the gestures and the handle
  /// follow where the sheet rests. During a layout or a build the rebuild
  /// waits for the frame's end.
  void _changed() {
    _controller._changed();
    if (!mounted) return;
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      _afterLayout(() => setState(() {}));
    } else {
      setState(() {});
    }
  }

  void _arrive() {
    final arrival = _arrival;
    _arrival = null;
    if (arrival != null && !arrival.isCompleted) arrival.complete();
  }

  /// Lays the anchors out for a sheet [sheetHeight] tall in a space
  /// [fullHeight] tall (`BottomSheetImpl`'s `draggableAnchors`), and
  /// returns where the sheet's top stands.
  double _place(double fullHeight, double sheetHeight) {
    final previous = _anchors;
    _fullHeight = fullHeight;
    _sheetHeight = sheetHeight;
    final anchors = <ExpressiveSheetValue, double>{
      ExpressiveSheetValue.hidden: fullHeight,
      if (!widget.skipPartiallyExpanded)
        ExpressiveSheetValue.partiallyExpanded:
            fullHeight -
            math.min(
              fullHeight * BottomSheetBehavior.partialHeightFraction,
              sheetHeight,
            ),
      if (sheetHeight != 0)
        ExpressiveSheetValue.expanded: math.max(0, fullHeight - sheetHeight),
    };
    _anchors = anchors;
    // `AnchoredDraggableState.updateAnchors`: new anchors retarget the
    // sheet; the same anchors leave it be.
    final changed = !mapEquals(previous, anchors);
    final partial = previous?[ExpressiveSheetValue.partiallyExpanded];
    final converged =
        partial != null && partial == previous?[ExpressiveSheetValue.expanded];
    final target = changed
        ? _retarget(_target, anchors, promote: converged)
        : _target;
    if (!_moving && (target != _current || target != _target)) {
      _current = target;
      _target = target;
      _afterLayout(_changed);
    }
    if (_showPending) {
      _showPending = false;
      _afterLayout(_show);
    }
    final position = _position;
    final padding = (_topInset - position).clamp(0.0, _topInset);
    if (padding != _topPadding.value) {
      _afterLayout(() => _topPadding.value = padding);
    }
    return position;
  }

  void _afterLayout(VoidCallback callback) =>
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) callback();
      });

  /// The value a sheet headed for [value] settles on under new [anchors]
  /// (`BottomSheetImpl`'s `newTarget`).
  ExpressiveSheetValue _retarget(
    ExpressiveSheetValue value,
    Map<ExpressiveSheetValue, double> anchors, {
    required bool promote,
  }) {
    final expanded = anchors.containsKey(ExpressiveSheetValue.expanded);
    switch (value) {
      case ExpressiveSheetValue.hidden:
        return ExpressiveSheetValue.hidden;
      case ExpressiveSheetValue.partiallyExpanded:
        if (promote && expanded) return ExpressiveSheetValue.expanded;
        if (anchors.containsKey(ExpressiveSheetValue.partiallyExpanded)) {
          return ExpressiveSheetValue.partiallyExpanded;
        }
        return expanded
            ? ExpressiveSheetValue.expanded
            : ExpressiveSheetValue.hidden;
      case ExpressiveSheetValue.expanded:
        return expanded
            ? ExpressiveSheetValue.expanded
            : ExpressiveSheetValue.hidden;
    }
  }

  Future<void> _show() {
    final anchors = _anchors;
    if (anchors == null) {
      _showPending = true;
      return Future<void>.value();
    }
    return _animateTo(
      anchors.containsKey(ExpressiveSheetValue.partiallyExpanded)
          ? ExpressiveSheetValue.partiallyExpanded
          : ExpressiveSheetValue.expanded,
      _showMotion,
    );
  }

  /// Springs the sheet to [value]'s anchor on [motion]'s spring, starting
  /// at [velocity] (logical px per second, down positive).
  Future<void> _animateTo(
    ExpressiveSheetValue value,
    ExpressiveMotionKey motion, {
    double velocity = 0,
  }) {
    final anchors = _anchors;
    if (anchors == null) {
      _current = _target = value;
      _changed();
      return Future<void>.value();
    }
    final resolved = anchors.containsKey(value)
        ? value
        : _retarget(value, anchors, promote: false);
    final from = _position;
    final to = anchors[resolved]!;
    _animatingTo = null;
    _arrive();
    _dragging = false;
    _offset
      ..stop()
      ..value = from;
    _target = resolved;
    _changed();
    _animatingTo = resolved;
    final arrival = _arrival = Completer<void>();
    if (from == to && velocity == 0) {
      _onOffset();
    } else {
      _offset.animateWith(
        designSpringSimulation(
          ExpressiveMotion.of(context).spring(motion),
          from: from,
          to: to,
          velocity: velocity,
        ),
      );
    }
    return arrival.future;
  }

  /// Moves the sheet by [delta] (down positive) within its anchors, and
  /// returns how far it moved (`dispatchRawDelta`).
  double _dragBy(double delta) {
    if (_anchors == null) return 0;
    if (!_dragging) {
      final from = _position;
      _animatingTo = null;
      _arrive();
      _offset
        ..stop()
        ..value = from;
      _dragging = true;
    }
    final from = _offset.value;
    final to = (from + delta).clamp(_minAnchor, _maxAnchor);
    _offset.value = to;
    final target = _computeTarget(to, 0);
    if (target != _target) {
      _target = target;
      _changed();
    }
    return to - from;
  }

  /// Ends a drag at [velocity] (logical px per second, down positive): the
  /// sheet settles on the anchor the anchored-draggable rule picks, on the
  /// default spatial spring, and a sheet settled out of sight asks to be
  /// dismissed.
  void _settle(double velocity) {
    if (!_dragging) return;
    var target = _computeTarget(_offset.value, velocity);
    if (target == ExpressiveSheetValue.hidden && !_mayHide()) {
      target = _restingAnchor;
    }
    _animateTo(target, _showMotion, velocity: velocity).then((_) {
      if (mounted && _current == ExpressiveSheetValue.hidden) {
        widget.onDismissRequest?.call();
      }
    });
  }

  /// The anchor a sheet released at [offset] with [velocity] settles on
  /// (foundation's `AnchoredDraggableState` target rule, with the sheet's
  /// 56dp positional and 125dp/s velocity thresholds).
  ExpressiveSheetValue _computeTarget(double offset, double velocity) {
    final settled = _anchors![_current];
    if (settled == null || settled == offset) return _current;
    if (velocity.abs() >= SheetDefaultsBehavior.velocityThreshold) {
      return _closest(offset, downwards: velocity > 0);
    }
    final neighbour = _closest(offset, downwards: offset > settled);
    return (settled - offset).abs() <= SheetDefaultsBehavior.positionalThreshold
        ? _current
        : neighbour;
  }

  /// The anchor nearest [offset] at or beyond it, down or up the screen.
  ExpressiveSheetValue _closest(double offset, {required bool downwards}) {
    ExpressiveSheetValue? best;
    var distance = double.infinity;
    for (final MapEntry(key: value, value: position) in _anchors!.entries) {
      final d = downwards ? position - offset : offset - position;
      if (d >= 0 && d < distance) {
        distance = d;
        best = value;
      }
    }
    return best ?? _current;
  }

  /// A nested scroll fling on its way down, damped inside the boundary
  /// zone above the hidden anchor (`BottomSheetImpl`'s fling behaviour).
  double _dampedFling(double velocity) {
    if (velocity <= 0) return velocity;
    const zone = SheetDefaultsBehavior.boundaryDampeningZone;
    final floor = math.max(0.0, _maxAnchor - _position);
    if (floor >= zone) return velocity;
    final factor = floor / zone;
    var damped = velocity * factor * factor;
    if (velocity >= SheetDefaultsBehavior.velocityThreshold) {
      damped = math.max(damped, SheetDefaultsBehavior.velocityThreshold);
    }
    return damped;
  }

  /// The drag handle's tap (`BottomSheetImpl`): an expanded sheet hides, a
  /// partial one expands.
  void _handleTap() {
    switch (_current) {
      case ExpressiveSheetValue.expanded:
        _dismiss();
      case ExpressiveSheetValue.partiallyExpanded:
        _animateTo(ExpressiveSheetValue.expanded, _showMotion);
      case ExpressiveSheetValue.hidden:
        _show();
    }
  }

  /// Whether the owner lets the user's hand hide the sheet.
  bool _mayHide() => widget.confirmHide?.call() ?? true;

  /// The visible anchor a sheet kept up springs back to.
  ExpressiveSheetValue get _restingAnchor {
    if (_current != ExpressiveSheetValue.hidden &&
        _anchors!.containsKey(_current)) {
      return _current;
    }
    return _anchors!.containsKey(ExpressiveSheetValue.partiallyExpanded)
        ? ExpressiveSheetValue.partiallyExpanded
        : ExpressiveSheetValue.expanded;
  }

  /// `animateToDismiss`: hide, then ask to be dismissed.
  void _dismiss() {
    if (!_mayHide()) return;
    _animateTo(ExpressiveSheetValue.hidden, _hideMotion).then((_) {
      if (mounted && _current == ExpressiveSheetValue.hidden) {
        widget.onDismissRequest?.call();
      }
    });
  }

  double get _backProgress => widget.predictiveBackProgress?.value ?? 0;

  /// `verticalScaleUp`: how much taller the container draws while a spring
  /// carries it above its highest anchor.
  double _stretch() {
    if (_anchors == null || _sheetHeight <= 0) return 1;
    final overflow = _minAnchor - _position;
    return overflow > 0 ? (_sheetHeight + overflow) / _sheetHeight : 1;
  }

  /// `calculateSheetPredictiveBackScaleX` and `…ScaleY`.
  ({double x, double y}) _backScale() {
    final progress = _backProgress;
    double scale(double extent, double distance) =>
        extent <= 0 ? 1 : 1 - math.min(distance, extent) * progress / extent;
    return (
      x: scale(
        _sheetWidth,
        BottomSheetBehavior.predictiveBackMaxScaleXDistance,
      ),
      y: scale(
        _sheetHeight,
        BottomSheetBehavior.predictiveBackMaxScaleYDistance,
      ),
    );
  }

  /// The container's transform about its top centre:
  /// `sheetPredictiveBackScaling` (about `TransformOrigin(0.5, (offset +
  /// height) / height)`, as Compose states it) over `verticalScaleUp`
  /// (about the top).
  Matrix4 _containerTransform() {
    final back = _backScale();
    final pivot = _position + _sheetHeight;
    return Matrix4.translationValues(0, pivot, 0)
      ..multiply(Matrix4.diagonal3Values(back.x, back.y, 1))
      ..multiply(Matrix4.translationValues(0, -pivot, 0))
      ..multiply(Matrix4.diagonal3Values(1, _stretch(), 1));
  }

  /// The content's counter-scale about its top: `contentPredictiveBack
  /// Scaling` over `verticalScaleDown`.
  double _contentScaleY() {
    final back = _backScale();
    final keep = back.y != 0 ? back.x / back.y : 1.0;
    return keep / _stretch();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    final media = MediaQuery.of(context);
    _topInset = media.padding.top;
    // Compose's modal window insets: the safe drawing area's bottom, the
    // keyboard included.
    final bottomInset = math.max(media.padding.bottom, media.viewInsets.bottom);
    final color = t.colors.role(SheetBottomTokens.dockedContainerColor);
    final contentColor = t.colors.contentColorFor(color) ?? t.colors.onSurface;
    final localizations = Localizations.of<MaterialLocalizations>(
      context,
      MaterialLocalizations,
    );
    final motion = Listenable.merge(<Listenable?>[
      _offset,
      widget.predictiveBackProgress,
    ]);

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        ValueListenableBuilder<double>(
          valueListenable: _topPadding,
          builder: (context, padding, _) => SizedBox(height: padding),
        ),
        if (widget.dragHandle case final handle?)
          Center(
            child: ListenableBuilder(
              listenable: _controller,
              builder: (context, _) => _DragHandle(
                color: color,
                contentColor: contentColor,
                current: _current,
                hasPartial:
                    _anchors?.containsKey(
                      ExpressiveSheetValue.partiallyExpanded,
                    ) ??
                    false,
                enabled: widget.gesturesEnabled,
                onTap: _gesturesActive ? _handleTap : null,
                onExpand: () =>
                    _animateTo(ExpressiveSheetValue.expanded, _showMotion),
                onCollapse: () => _animateTo(
                  ExpressiveSheetValue.partiallyExpanded,
                  _hideMotion,
                ),
                onDismiss: _dismiss,
                child: handle,
              ),
            ),
          ),
        Flexible(
          child: MediaQuery.removeViewInsets(
            context: context,
            removeBottom: true,
            child: MediaQuery.removePadding(
              context: context,
              removeTop: true,
              removeBottom: true,
              child: PrimaryScrollController(
                controller: _scroll,
                child: widget.child,
              ),
            ),
          ),
        ),
        SizedBox(height: bottomInset),
      ],
    );

    final surface = AnimatedBuilder(
      animation: motion,
      builder: (context, _) => ExpressiveSurface(
        key: ExpressiveBottomSheet.containerKey,
        style: widget.style,
        componentStyle: t.bottomSheetTheme,
        states: {if (_dragging) WidgetState.dragged},
        shape: t.shapes.of(SheetBottomTokens.dockedContainerShape),
        color: color,
        contentColor: contentColor,
        child: Semantics(
          container: true,
          explicitChildNodes: true,
          namesRoute: true,
          label: localizations?.bottomSheetLabel,
          child: AnimatedBuilder(
            animation: motion,
            builder: (context, child) => Transform(
              alignment: Alignment.topCenter,
              transform: Matrix4.diagonal3Values(1, _contentScaleY(), 1),
              child: child,
            ),
            child: content,
          ),
        ),
      ),
    );

    final active = _gesturesActive;
    return _SheetLayout(
      state: this,
      devicePixelRatio: MediaQuery.devicePixelRatioOf(context),
      child: GestureDetector(
        onVerticalDragUpdate: active
            ? (details) => _dragBy(details.primaryDelta ?? 0)
            : null,
        onVerticalDragEnd: active
            ? (details) => _settle(details.primaryVelocity ?? 0)
            : null,
        onVerticalDragCancel: active ? () => _settle(0) : null,
        child: AnimatedBuilder(
          animation: motion,
          builder: (context, child) => Transform(
            alignment: Alignment.topCenter,
            transform: _containerTransform(),
            child: child,
          ),
          child: surface,
        ),
      ),
    );
  }
}

/// Lays the sheet out in its whole space: at most
/// `BottomSheetDefaults.SheetMaxWidth` wide and centred, as tall as its
/// content up to the space's height, its top where the sheet's state puts
/// it, rounded to a whole physical pixel as `Modifier.draggableAnchors`
/// places it (`yOffset.roundToInt()`).
class _SheetLayout extends SingleChildRenderObjectWidget {
  const _SheetLayout({
    required this.state,
    required this.devicePixelRatio,
    required super.child,
  });

  final _ExpressiveBottomSheetState state;

  final double devicePixelRatio;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderSheetLayout(state, devicePixelRatio);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderSheetLayout renderObject,
  ) => renderObject
    ..state = state
    ..devicePixelRatio = devicePixelRatio;
}

class _RenderSheetLayout extends RenderShiftedBox {
  _RenderSheetLayout(this._state, this._devicePixelRatio) : super(null);

  double _devicePixelRatio;
  set devicePixelRatio(double value) {
    if (value == _devicePixelRatio) return;
    _devicePixelRatio = value;
    markNeedsLayout();
  }

  _ExpressiveBottomSheetState _state;
  set state(_ExpressiveBottomSheetState value) {
    if (value == _state) return;
    if (attached) _state._offset.removeListener(markNeedsLayout);
    _state = value;
    if (attached) _state._offset.addListener(markNeedsLayout);
    markNeedsLayout();
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _state._offset.addListener(markNeedsLayout);
  }

  @override
  void detach() {
    _state._offset.removeListener(markNeedsLayout);
    super.detach();
  }

  @override
  void performLayout() {
    size = constraints.biggest;
    final child = this.child;
    if (child == null) return;
    final width = math.min(size.width, SheetDefaultsBehavior.maxWidth);
    child.layout(
      BoxConstraints(minWidth: width, maxWidth: width, maxHeight: size.height),
      parentUsesSize: true,
    );
    _state._sheetWidth = child.size.width;
    final top = _state._place(size.height, child.size.height);
    (child.parentData! as BoxParentData).offset = Offset(
      (size.width - child.size.width) / 2,
      (top * _devicePixelRatio).roundToDouble() / _devicePixelRatio,
    );
  }

  @override
  bool hitTestSelf(Offset position) => false;
}

/// The primary scroll controller a sheet hands its content: its positions
/// move the sheet before (rising) or after (falling at the top) they
/// scroll, as Compose's
/// `ConsumeSwipeWithinBottomSheetBoundsNestedScrollConnection` does.
class _SheetScrollController extends ScrollController {
  _SheetScrollController(this.sheet);

  final _ExpressiveBottomSheetState sheet;

  @override
  ScrollPosition createScrollPosition(
    ScrollPhysics physics,
    ScrollContext context,
    ScrollPosition? oldPosition,
  ) => _SheetScrollPosition(
    sheet: sheet,
    physics: physics,
    context: context,
    oldPosition: oldPosition,
  );
}

class _SheetScrollPosition extends ScrollPositionWithSingleContext {
  _SheetScrollPosition({
    required this.sheet,
    required super.physics,
    required super.context,
    super.oldPosition,
  });

  final _ExpressiveBottomSheetState sheet;

  /// Whether this gesture has moved the sheet.
  bool _movedSheet = false;

  @override
  void applyUserOffset(double delta) {
    if (!sheet._gesturesActive || sheet._anchors == null) {
      return super.applyUserOffset(delta);
    }
    if (delta < 0) {
      // onPreScroll: rising, the sheet goes first.
      final moved = sheet._dragBy(delta);
      if (moved != 0) _movedSheet = true;
      final rest = delta - moved;
      if (rest != 0) super.applyUserOffset(rest);
      return;
    }
    // onPostScroll: falling, the content scrolls to its top first.
    final room = math.max(0.0, pixels - minScrollExtent);
    final scroll = math.min(delta, room);
    if (scroll > 0) super.applyUserOffset(scroll);
    final rest = delta - scroll;
    if (rest > 0 && sheet._dragBy(rest) != 0) _movedSheet = true;
  }

  @override
  void goBallistic(double velocity) {
    // A scroll's velocity is the content's (up positive); the sheet's is
    // the finger's (down positive). onPreFling takes a rising fling while
    // the sheet is below its top anchor; onPostFling settles a sheet this
    // gesture moved.
    final sheetVelocity = -velocity;
    final moved = _movedSheet;
    _movedSheet = false;
    if (sheet._dragging && (moved || sheetVelocity < 0)) {
      sheet._settle(sheet._dampedFling(sheetVelocity));
      super.goBallistic(0);
      return;
    }
    super.goBallistic(velocity);
  }
}

/// `BottomSheetDefaults.DragHandle`: the 32×4dp bar
/// (`SheetBottomTokens.DockedDragHandle*`, on-surface-variant, the
/// extra-large shape) with 22dp above and below it. A sheet makes it
/// tappable.
class ExpressiveSheetDragHandle extends StatelessWidget {
  /// A drag handle for a sheet.
  const ExpressiveSheetDragHandle({super.key});

  /// The handle's box: the bar with the space above and below it.
  static const Key boxKey = ValueKey<String>('expressive-sheet:drag-handle');

  /// The bar inside a handle's box of [size]: what a focus ring goes round.
  static Rect barIn(Size size) => Rect.fromCenter(
    center: size.center(Offset.zero),
    width: SheetBottomTokens.dockedDragHandleWidth,
    height: SheetBottomTokens.dockedDragHandleHeight,
  );

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    return Semantics(
      label: ExpressiveLocalizations.of(context).sheetDragHandle,
      child: Padding(
        key: boxKey,
        padding: const EdgeInsets.symmetric(
          vertical: SheetDefaultsBehavior.dragHandleVerticalPadding,
        ),
        child: SizedBox(
          width: SheetBottomTokens.dockedDragHandleWidth,
          height: SheetBottomTokens.dockedDragHandleHeight,
          child: DecoratedBox(
            decoration: ShapeDecoration(
              color: t.colors.role(SheetBottomTokens.dockedDragHandleColor),
              shape: t.shapes.extraLarge,
            ),
          ),
        ),
      ),
    );
  }
}

/// `DragHandleWithTooltip` around the sheet's handle: tappable (hide when
/// expanded, expand when partial) and carrying the sheet's accessibility
/// actions.
///
/// It draws no state layer and no ripple. Compose's `clickable` paints its
/// ripple over the handle's whole 32×48dp box; here that box is invisible,
/// so a layer filling it is a grey square round a 32×4dp bar, with edges
/// nothing on screen explains (the user's 11-09 capture). A deliberate
/// departure: the pointer turns to the grab hand instead, and keyboard focus
/// draws the focus ring round the bar itself.
class _DragHandle extends StatelessWidget {
  const _DragHandle({
    required this.child,
    required this.color,
    required this.contentColor,
    required this.current,
    required this.hasPartial,
    required this.enabled,
    required this.onTap,
    required this.onExpand,
    required this.onCollapse,
    required this.onDismiss,
  });

  final Widget child;
  final Color color;
  final Color contentColor;
  final ExpressiveSheetValue current;
  final bool hasPartial;
  final bool enabled;
  final VoidCallback? onTap;
  final VoidCallback onExpand;
  final VoidCallback onCollapse;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    final strings = ExpressiveLocalizations.of(context);
    final actions = <CustomSemanticsAction, VoidCallback>{
      if (enabled)
        CustomSemanticsAction(label: strings.sheetDismiss): onDismiss,
      if (enabled && current == ExpressiveSheetValue.partiallyExpanded)
        CustomSemanticsAction(label: strings.sheetExpand): onExpand
      else if (enabled && hasPartial)
        CustomSemanticsAction(label: strings.sheetCollapse): onCollapse,
    };
    return Semantics(
      customSemanticsActions: actions,
      child: ExpressivePressable(
        shapes: ExpressivePressShapes.all(
          t.shapes.of(ExpressiveShapeKey.cornerNone),
        ),
        motion: ExpressiveMotionKey.defaultEffects,
        color: color,
        contentColor: contentColor,
        stateLayers: false,
        mouseCursor: enabled
            ? SystemMouseCursors.grab
            : SystemMouseCursors.basic,
        // The ring follows the bar (the default handle's), or the whole of
        // a handle the app drew itself.
        focusRect: child is ExpressiveSheetDragHandle
            ? ExpressiveSheetDragHandle.barIn
            : null,
        focusShape: t.shapes.extraLarge,
        // Tappable, so it keeps the 48dp touch target round its 32dp bar
        // (the bar itself drawn as before): a control a finger must find.
        onPressed: onTap,
        child: child,
      ),
    );
  }
}

// --- The routes --------------------------------------------------------------

/// How long [spring] takes to settle from 0 to 1 at the kit's tolerance:
/// a route's transition duration (decision F11).
Duration _settleTime(SpringDescription spring) {
  final simulation = designSpringSimulation(spring, from: 0, to: 1);
  var ms = 0;
  while (!simulation.isDone(ms / Duration.millisecondsPerSecond) &&
      ms < Duration.millisecondsPerMinute) {
    ms += 1;
  }
  return Duration(milliseconds: ms);
}

/// Whether [platform] takes the iOS behaviour (no predictive back).
bool _isApple(TargetPlatform platform) =>
    platform == TargetPlatform.iOS || platform == TargetPlatform.macOS;

/// `ModalBottomSheet` as a route: the scrim, the sheet, and the platform's
/// back (see the library doc).
class _ModalSheetRoute<T> extends PopupRoute<T> {
  _ModalSheetRoute({
    required this.content,
    required this.skipPartiallyExpanded,
    required this.dismissLabel,
    required ExpressiveMotion motion,
    this.capturedThemes,
    this.style,
    super.settings,
  }) : _showDuration = _settleTime(motion.spring(_showMotion)),
       _hideDuration = _settleTime(motion.spring(_hideMotion));

  /// The sheet's content, built each time the route builds.
  final WidgetBuilder content;

  final bool skipPartiallyExpanded;
  final String? dismissLabel;

  /// The themes where the sheet was raised from code; null for a page,
  /// whose navigator stands inside the host.
  final CapturedThemes? capturedThemes;
  final ExpressiveComponentThemeData? style;

  final Duration _showDuration;
  final Duration _hideDuration;

  final ExpressiveSheetController sheet = ExpressiveSheetController();

  /// Whether the route was pushed (the sheet rises) rather than added (it
  /// stands at its anchor from the first frame).
  bool _pushed = false;

  late final AnimationController _scrim;
  late final AnimationController _back;
  late final _SheetBackObserver _observer = _SheetBackObserver(this);
  bool _scrimShown = false;

  ExpressiveMotion get _springs => ExpressiveMotion.of(navigator!.context);

  @override
  Duration get transitionDuration => _showDuration;

  @override
  Duration get reverseTransitionDuration => _hideDuration;

  @override
  bool get barrierDismissible => true;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => dismissLabel;

  @override
  void install() {
    _scrim = AnimationController.unbounded(vsync: navigator!);
    _back = AnimationController.unbounded(vsync: navigator!);
    super.install();
    sheet.addListener(_onSheet);
    WidgetsBinding.instance.addObserver(_observer);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(_observer);
    sheet.removeListener(_onSheet);
    _scrim.dispose();
    _back.dispose();
    super.dispose();
  }

  /// The scrim follows the sheet's target (`ModalBottomSheet`'s
  /// `isScrimVisible`), on the default effects spring.
  void _onSheet() {
    final shown = sheet.targetValue != ExpressiveSheetValue.hidden;
    if (shown == _scrimShown) return;
    _scrimShown = shown;
    _scrim.springTo(
      shown ? 1 : 0,
      _springs.spring(ModalBottomSheetBehavior.scrimMotion),
    );
  }

  @override
  void didAdd() {
    super.didAdd();
    _scrimShown = true;
    _scrim.value = 1;
  }

  @override
  TickerFuture didPush() {
    _pushed = true;
    super.didPush();
    sheet.show();
    return controller!.animateWith(
      designSpringSimulation(_springs.spring(_showMotion), from: 0, to: 1),
    );
  }

  @override
  bool didPop(T? result) {
    // False when an overlay held open in the sheet took the pop
    // ([ExpressiveBackHandle]): the sheet stays where it is.
    if (!super.didPop(result)) return false;
    sheet.hide();
    if (_scrimShown) {
      _scrimShown = false;
      _scrim.springTo(0, _springs.spring(ModalBottomSheetBehavior.scrimMotion));
    }
    controller!.animateBackWith(
      designSpringSimulation(
        _springs.spring(_hideMotion),
        from: controller!.value,
        to: 0,
      ),
    );
    return true;
  }

  /// `settleToDismiss`: the system back settles an expanded sheet that has
  /// a partial anchor there instead of dismissing it.
  bool get _collapsesOnBack =>
      sheet.currentValue == ExpressiveSheetValue.expanded &&
      sheet.hasPartiallyExpandedState;

  @override
  RoutePopDisposition get popDisposition {
    // An overlay held open in the sheet takes the back first, before the
    // settle and any PopScope ([ExpressiveBackHandleRoute]'s rule, written
    // out: [_popVetoed] reads the PopScopes past it).
    if (willHandlePopInternally) return RoutePopDisposition.pop;
    return _collapsesOnBack
        ? RoutePopDisposition.doNotPop
        : super.popDisposition;
  }

  @override
  void onPopInvokedWithResult(bool didPop, T? result) {
    if (!didPop && _collapsesOnBack) sheet.partialExpand();
    super.onPopInvokedWithResult(didPop, result);
  }

  /// Whether a [PopScope] (or another pop entry) in the sheet vetoes a
  /// dismissal. The sheet's own collapse-on-back is not a veto: the scrim
  /// and the hand dismiss whatever the anchor.
  bool get _popVetoed => super.popDisposition == RoutePopDisposition.doNotPop;

  /// Asked before the scrim or the user's hand dismisses the sheet: a
  /// vetoed pop keeps it up and tells the pop entries, as a refused
  /// `maybePop` does.
  bool _confirmHide() {
    if (!_popVetoed) return true;
    super.onPopInvokedWithResult(false, null);
    return false;
  }

  /// Removes the route once the sheet is out of sight by the user's hand.
  void _dismiss() {
    final navigator = this.navigator;
    if (navigator == null || !isActive) return;
    if (_popVetoed) {
      // Vetoed after the sheet hid (a pop entry that arrived meanwhile):
      // bring it back rather than leave an invisible route.
      sheet.show();
      return;
    }
    if (isCurrent) {
      // An overlay held open in the sheet goes with it: each of its pops
      // closes one before the route's own.
      while (willHandlePopInternally) {
        navigator.pop();
      }
      navigator.pop();
    } else {
      navigator.removeRoute(this);
    }
  }

  // Predictive back (Android): the sheet scales with the gesture, and a
  // commit settles it as the system back does.

  bool _claim(PredictiveBackEvent event) {
    final navigator = this.navigator;
    if (navigator == null ||
        event.isButtonEvent ||
        !isCurrent ||
        !sheet.isVisible ||
        // An overlay held open in the sheet takes the back: the gesture
        // falls through to the navigator, whose pop closes it.
        willHandlePopInternally ||
        // A vetoed dismissal is not previewed: the gesture falls through
        // to the navigator, whose refused pop tells the pop entries.
        (_popVetoed && !_collapsesOnBack) ||
        _isApple(Theme.of(navigator.context).platform)) {
      return false;
    }
    _back
      ..stop()
      ..value = ExpressivePage.predictiveBackEasing.transform(event.progress);
    return true;
  }

  void _follow(PredictiveBackEvent event) => _back.value = ExpressivePage
      .predictiveBackEasing
      .transform(event.progress);

  void _commit() {
    if (_collapsesOnBack) {
      sheet.partialExpand();
      _back.springTo(0, _springs.spring(_backMotion));
    } else if (isCurrent && _confirmHide()) {
      // The sheet hides still scaled, as Compose's does.
      navigator?.pop();
    } else {
      // A pop entry arrived mid-gesture and refused: the sheet stays.
      _back.springTo(0, _springs.spring(_backMotion));
    }
  }

  void _cancel() => _back.springTo(0, _springs.spring(_backMotion));

  @override
  Widget buildModalBarrier() {
    final Widget barrier = Stack(
      fit: StackFit.expand,
      children: <Widget>[
        IgnorePointer(
          child: Builder(
            builder: (context) {
              final scrim = context.expressiveTheme.colors.role(
                ScrimTokens.containerColor,
              );
              return AnimatedBuilder(
                animation: _scrim,
                builder: (context, _) => ColoredBox(
                  color: scrim.withValues(
                    alpha:
                        ScrimTokens.containerOpacity *
                        _scrim.value.clamp(0.0, 1.0),
                  ),
                ),
              );
            },
          ),
        ),
        ModalBarrier(
          semanticsLabel: dismissLabel,
          // The scrim hides the sheet and dismisses it
          // (`animateToDismiss`), whatever its anchor.
          // A PopScope in the sheet vetoes it, as with `maybePop`.
          onDismiss: () {
            if (isCurrent && _confirmHide()) navigator?.pop();
          },
        ),
      ],
    );
    return capturedThemes?.wrap(barrier) ?? barrier;
  }

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    Widget page = ExpressiveBottomSheet(
      style: switch (settings) {
        ExpressiveSheetPage<Object?>(style: final value) => value,
        _ => style,
      },
      controller: sheet,
      initialValue: _pushed
          ? ExpressiveSheetValue.hidden
          : ExpressiveSheetValue.partiallyExpanded,
      skipPartiallyExpanded: skipPartiallyExpanded,
      predictiveBackProgress: _back,
      onDismissRequest: _dismiss,
      confirmHide: _confirmHide,
      child: RoutePresentationScope(
        presentation: RoutePresentation.sheet,
        child: Builder(builder: content),
      ),
    );
    // Inside the captured themes, so the page's own theme wins.
    if (settings case ExpressiveSheetPage<Object?>(theme: _?)) {
      page = _SheetPageTheme(sheet: page);
    }
    return capturedThemes?.wrap(page) ?? page;
  }
}

/// A sheet page's [ExpressiveSheetPage.theme] around the whole sheet,
/// rebuilt with the page and on its [ExpressiveSheetPage.themeListenable].
class _SheetPageTheme extends StatelessWidget {
  const _SheetPageTheme({required this.sheet});

  final Widget sheet;

  @override
  Widget build(BuildContext context) {
    final page =
        ModalRoute.of(context)!.settings as ExpressiveSheetPage<Object?>;
    final theme = page.theme;
    if (theme == null) return sheet;
    return ListenableBuilder(
      listenable: page.themeListenable ?? const _Unchanging(),
      builder: (context, _) =>
          ExpressiveTheme(data: theme(context), child: sheet),
    );
  }
}

/// A listenable that never notifies.
class _Unchanging implements Listenable {
  const _Unchanging();

  @override
  void addListener(VoidCallback listener) {}

  @override
  void removeListener(VoidCallback listener) {}
}

/// Hands the system's predictive back events to a sheet route (a route
/// cannot be the observer itself: [TransitionRoute]'s own back-gesture
/// methods share the observer's names).
class _SheetBackObserver with WidgetsBindingObserver {
  _SheetBackObserver(this.route);

  final _ModalSheetRoute<dynamic> route;

  @override
  bool handleStartBackGesture(PredictiveBackEvent backEvent) =>
      route._claim(backEvent);

  @override
  void handleUpdateBackGestureProgress(PredictiveBackEvent backEvent) =>
      route._follow(backEvent);

  @override
  void handleCommitBackGesture() => route._commit();

  @override
  void handleCancelBackGesture() => route._cancel();
}

/// The full-screen dialog as a route: the page on the surface, rising from
/// the bottom edge on the default spatial spring and leaving on the fast
/// effects spring (the bottom sheet's show and hide springs). Compose has
/// no full-screen dialog component; the motion is the sheet's.
///
/// Its back is the platform's (CONTRACT §5): on Android the predictive back
/// `ExpressivePage`'s route runs (the same claim, frame and springs, shared
/// through [ExpressivePredictiveBackRoute]); on iOS a swipe down, as a
/// presented page is dismissed there. Flutter's Cupertino full-screen
/// dialog carries no back gesture at all (`CupertinoRouteTransitionMixin`
/// gives a `fullscreenDialog` neither the edge swipe nor its parallax), so
/// the swipe follows the modal sheet's: the page follows the finger down,
/// and a release past the sheet's positional threshold or faster than its
/// velocity threshold (`SheetDefaultsBehavior`) dismisses it, otherwise it
/// springs home.
class _FullScreenDialogRoute<T> extends PageRoute<T>
    with ExpressivePredictiveBackRoute<T>, ExpressiveBackHandleRoute<T> {
  _FullScreenDialogRoute({
    required this.content,
    required ExpressiveMotion motion,
    super.settings,
  }) : _showDuration = _settleTime(motion.spring(_showMotion)),
       _hideDuration = _settleTime(motion.spring(_hideMotion)),
       super(fullscreenDialog: true);

  final WidgetBuilder content;
  final Duration _showDuration;
  final Duration _hideDuration;

  ExpressiveMotion get _springs => ExpressiveMotion.of(navigator!.context);

  @override
  Duration get transitionDuration => _showDuration;

  @override
  Duration get reverseTransitionDuration => _hideDuration;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;

  /// [ModalRoute]'s rule, which [PageRoute] withholds from every
  /// `fullscreenDialog`: the platform's back gesture (Android's predictive
  /// back, the iOS swipe down) closes the dialog unless it is the first
  /// route, handles the pop itself, is vetoed (a `PopScope`), or is still
  /// moving.
  @override
  bool get popGestureEnabled =>
      !isFirst &&
      !willHandlePopInternally &&
      popDisposition != RoutePopDisposition.doNotPop &&
      animation!.isCompleted;

  @override
  TickerFuture didPush() {
    super.didPush();
    return controller!.animateWith(
      designSpringSimulation(_springs.spring(_showMotion), from: 0, to: 1),
    );
  }

  @override
  bool didPop(T? result) {
    // False when an overlay held open in the dialog took the pop.
    if (!super.didPop(result)) return false;
    controller!.animateBackWith(
      designSpringSimulation(
        _springs.spring(_hideMotion),
        from: controller!.value,
        to: 0,
      ),
    );
    return true;
  }

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) => Semantics(
    scopesRoute: true,
    explicitChildNodes: true,
    child: ColoredBox(
      color: context.expressiveTheme.colors.surface,
      child: SizedBox.expand(
        child: RoutePresentationScope(
          presentation: RoutePresentation.sheet,
          child: Builder(builder: content),
        ),
      ),
    ),
  );

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final swipes = _isApple(Theme.of(context).platform);
    return ExpressivePredictiveBackTransition(
      route: this,
      animation: animation,
      rise: true,
      // One tree on every platform; only iOS listens.
      child: GestureDetector(
        onVerticalDragStart: swipes ? _dragStart : null,
        onVerticalDragUpdate: swipes ? _dragUpdate : null,
        onVerticalDragEnd: swipes ? _dragEnd : null,
        onVerticalDragCancel: swipes ? _dragCancel : null,
        child: child,
      ),
    );
  }

  // The iOS swipe down.

  /// Whether a swipe down is following the finger.
  bool _dragging = false;

  void _dragStart(DragStartDetails details) {
    final navigator = this.navigator;
    if (navigator == null ||
        !isCurrent ||
        !popGestureEnabled ||
        navigator.userGestureInProgress) {
      return;
    }
    _dragging = true;
    controller!.stop();
    navigator.didStartUserGesture();
  }

  /// The page's height: the distance the swipe moves it off screen.
  double get _travel => subtreeContext?.size?.height ?? 0;

  void _dragUpdate(DragUpdateDetails details) {
    final travel = _travel;
    if (!_dragging || travel <= 0) return;
    controller!.value = (controller!.value - details.primaryDelta! / travel)
        .clamp(0.0, 1.0);
  }

  void _dragEnd(DragEndDetails details) {
    if (!_dragging) return;
    final velocity = details.velocity.pixelsPerSecond.dy;
    final dragged = (1 - controller!.value) * _travel;
    final dismiss = velocity.abs() >= SheetDefaultsBehavior.velocityThreshold
        ? velocity > 0
        : dragged > SheetDefaultsBehavior.positionalThreshold;
    _endDrag(dismiss: dismiss);
  }

  void _dragCancel() {
    if (_dragging) _endDrag(dismiss: false);
  }

  /// Ends the swipe: off the screen (the navigator pops, and [didPop]'s
  /// hide spring carries the page away), or home on the show spring.
  void _endDrag({required bool dismiss}) {
    _dragging = false;
    final navigator = this.navigator!;
    if (dismiss && isCurrent) {
      navigator.pop();
    } else {
      controller!.animateWith(
        designSpringSimulation(
          _springs.spring(_showMotion),
          from: controller!.value,
          to: 1,
        ),
      );
    }
    navigator.didStopUserGesture();
  }
}

// --- The pages ---------------------------------------------------------------

/// The page a sheet route stands for now: go_router hands the route a new
/// page (same key, new child) when its state changes.
Widget _pageChild(BuildContext context) =>
    (ModalRoute.of(context)!.settings as ExpressiveSheetPage<Object?>).child;

/// The route an `ExpressiveSheetPage` (`sheet_page.dart`) raises: the
/// modal sheet's, or with [drawer] the full-screen dialog's.
Route<T> expressiveSheetPageRoute<T>(
  BuildContext context,
  Page<T> page, {
  required bool drawer,
  required bool skipPartiallyExpanded,
}) {
  final motion = ExpressiveMotion.of(context);
  if (drawer) {
    return _FullScreenDialogRoute<T>(
      settings: page,
      motion: motion,
      content: _pageChild,
    );
  }
  return _ModalSheetRoute<T>(
    settings: page,
    motion: motion,
    skipPartiallyExpanded: skipPartiallyExpanded,
    dismissLabel: Localizations.of<MaterialLocalizations>(
      context,
      MaterialLocalizations,
    )?.modalBarrierDismissLabel,
    content: _pageChild,
  );
}

/// Shows [builder]'s content in a modal bottom sheet (Material's
/// `showModalBottomSheet`, Compose's `ModalBottomSheet`), raised from code
/// without a route of the app's router: the same scrim, sheet and back as
/// [ExpressiveSheetPage], on the root navigator by default. The route keeps
/// the themes where it was raised ([InheritedTheme.capture]), so a
/// subtree's theme reaches a sheet raised above it. Completes with the value
/// the sheet is popped with.
///
/// ```dart
/// showExpressiveBottomSheet<void>(context, builder: (context) => const ExpressiveListTile(title: Text('Share')))
/// ```
Future<T?> showExpressiveBottomSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool skipPartiallyExpanded = false,
  bool useRootNavigator = true,
  ExpressiveComponentThemeData? style,
}) {
  final navigator = Navigator.of(context, rootNavigator: useRootNavigator);
  return navigator.push<T>(
    _ModalSheetRoute<T>(
      style: style,
      content: builder,
      skipPartiallyExpanded: skipPartiallyExpanded,
      motion: ExpressiveMotion.of(context),
      dismissLabel: Localizations.of<MaterialLocalizations>(
        context,
        MaterialLocalizations,
      )?.modalBarrierDismissLabel,
      capturedThemes: InheritedTheme.capture(
        from: context,
        to: navigator.context,
      ),
    ),
  );
}
