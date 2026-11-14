/// The loading indicator — plain and contained, indeterminate and
/// determinate — and pull-to-refresh (CONTRACT §4.1 `loading-indicator`).
/// Owner: w3-feedback.
///
/// A port of Compose material3 1.5.0-alpha29's `LoadingIndicator.kt`
/// (`LoadingIndicator`, `ContainedLoadingIndicator`, `LoadingIndicatorImpl`)
/// and `pulltorefresh/PullToRefresh.kt` (`PullToRefreshBox` with
/// `PullToRefreshDefaults.LoadingIndicator`). Sizes and colours come from
/// the generated `LoadingIndicatorTokens`; the cycle's timing, spring and
/// shapes from `LoadingIndicatorBehavior`; the pull's threshold, drag
/// multiplier and overshoot turn from `PullToRefreshBehavior`
/// (`tools/expressive_tokens/behavior/loading.yaml`).
///
/// The indeterminate cycle is Compose's `LaunchedEffect` loop as a function
/// of the frame clock: every `morphInterval` a morph to the next of the
/// seven shapes starts on the (0.6, 200) spring; once that spring finishes
/// (Compose's settle estimate at the 0.1 visibility threshold) the shape
/// index advances, the morph snaps to 0 and the resting angle gains a
/// quarter turn; the drawn angle is morph × 90 + that angle + a linear
/// global turn every `globalRotation`. The shapes are the library's
/// (`internal/shape`, held to Compose's cubics), morphed into one reused
/// [Path], scaled by Compose's `calculateScaleFactor` × 38/48 and centred.
///
/// Deviations (recorded for the oracle):
/// - Under Reduce Motion the morph spring is critically damped (the kit's
///   policy for a spatial spring); Compose keeps it.
/// - The pull's settle to the threshold and back runs on the fast spatial
///   spring; Compose's `PullToRefreshState` uses `Animatable`'s default
///   spring (no bounce, medium stiffness), which is no motion token.
/// - The pull is read from Flutter's scroll notifications (overscroll on
///   Android, the bounce on iOS) instead of nested scrolling, as Flutter's
///   own refresh indicator does; the thresholds and the tension are
///   Compose's.
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/physics.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../internal/shape/graphics/graphics.dart';
import '../internal/shape/library.dart';
import '../internal/shape/library_shapes.g.dart';
import '../internal/tokens/behavior.g.dart';
import '../internal/tokens/loading_indicator_tokens.g.dart';
import '../motion.dart';
import '../component_themes.dart';
import '../elevation.dart';
import '../strings.dart';
import '../theme.dart';

// ---------------------------------------------------------------------------
// Geometry, built once
// ---------------------------------------------------------------------------

/// A morph sequence and its scale factor (`morphSequence` and
/// `calculateScaleFactor(polygons) * ActiveIndicatorScale`).
class _Sequence {
  _Sequence(List<ExpressiveRoundedPolygon> polygons, {required bool circular})
    : morphs = <ExpressivePolygonMorph>[
        for (var i = 0; i < polygons.length; i++)
          if (i + 1 < polygons.length)
            ExpressivePolygonMorph(
              polygons[i].normalized(),
              polygons[i + 1].normalized(),
            )
          else if (circular)
            ExpressivePolygonMorph(
              polygons[i].normalized(),
              polygons[0].normalized(),
            ),
      ],
      scale = _scaleFactor(polygons) * _activeScale;

  final List<ExpressivePolygonMorph> morphs;
  final double scale;

  static double get _activeScale =>
      LoadingIndicatorTokens.activeSize /
      math.min(
        LoadingIndicatorTokens.containerWidth,
        LoadingIndicatorTokens.containerHeight,
      );

  static double _scaleFactor(List<ExpressiveRoundedPolygon> polygons) {
    var factor = 1.0;
    for (final polygon in polygons) {
      final b = polygon.calculateBounds();
      final m = polygon.calculateMaxBounds();
      final x = (b[2] - b[0]) / (m[2] - m[0]);
      final y = (b[3] - b[1]) / (m[3] - m[1]);
      factor = math.min(factor, math.max(x, y));
    }
    return factor;
  }

  /// `LoadingIndicatorDefaults.IndeterminateIndicatorPolygons`, as a
  /// circular sequence.
  static final _Sequence indeterminate = _Sequence(<ExpressiveRoundedPolygon>[
    for (final name in LoadingIndicatorBehavior.indeterminateShapes)
      expressiveLibraryPolygon(
        ExpressiveMaterialShape.values.byName(
          name[0].toLowerCase() + name.substring(1),
        ),
      ),
  ], circular: true);

  /// `LoadingIndicatorDefaults.DeterminateIndicatorPolygons`: the circle
  /// turned a twentieth, then the soft burst.
  static final _Sequence determinate = _Sequence(<ExpressiveRoundedPolygon>[
    expressiveRotated(
      expressiveLibraryPolygon(ExpressiveMaterialShape.circle),
      _FullTurn.degrees / LoadingIndicatorBehavior.determinateStartDivisor,
    ),
    expressiveLibraryPolygon(ExpressiveMaterialShape.softBurst),
  ], circular: false);
}

/// A full turn, in degrees and radians.
abstract final class _FullTurn {
  static const degrees = 360.0;
  static const radians = 2 * math.pi;
}

/// When Compose's morph `Animatable` finishes, released at rest one unit
/// from its target: an underdamped spring when its envelope drops under
/// the visibility threshold (`estimateAnimationDurationMillis`), otherwise
/// when it comes within the threshold.
double _settleSeconds(SpringDescription spring) {
  const threshold = LoadingIndicatorBehavior.morphVisibilityThreshold;
  final w0 = math.sqrt(spring.stiffness / spring.mass);
  final zeta = spring.damping / (2 * math.sqrt(spring.stiffness * spring.mass));
  if (zeta < 1) {
    final wd = w0 * math.sqrt(1 - zeta * zeta);
    final r = -zeta * w0;
    const c1 = -1 / threshold;
    final c2 = -r * c1 / wd;
    final c = math.sqrt(c1 * c1 + c2 * c2);
    return math.log(1 / c) / r;
  }
  final simulation = SpringSimulation(spring, 0, 1, 0);
  var lo = 0.0;
  var hi = 1.0;
  while ((1 - simulation.x(hi)).abs() > threshold) {
    hi *= 2;
  }
  for (var i = 0; i < 32; i++) {
    final mid = (lo + hi) / 2;
    if ((1 - simulation.x(mid)).abs() > threshold) {
      lo = mid;
    } else {
      hi = mid;
    }
  }
  return hi;
}

/// The indeterminate cycle at [elapsed] under [spring]: which morph, how
/// far along it, and the angle to draw at (degrees).
({int index, double progress, double degrees}) _loadingCycle(
  Duration elapsed,
  SpringDescription spring,
  int shapes,
) {
  final ms = elapsed.inMicroseconds / Duration.microsecondsPerMillisecond;
  const interval = LoadingIndicatorBehavior.morphInterval;
  final k = ms ~/ interval;
  final into = (ms - k * interval) / Duration.millisecondsPerSecond;
  final finished = into >= _settleSeconds(spring);
  final completed = finished ? k + 1 : k;
  final progress = finished ? 0.0 : SpringSimulation(spring, 0, 1, 0).x(into);
  final quarter = LoadingIndicatorBehavior.morphRotationDegrees;
  final resting = (quarter * (1 + completed)) % _FullTurn.degrees;
  final global =
      (ms % LoadingIndicatorBehavior.globalRotation) /
      LoadingIndicatorBehavior.globalRotation *
      _FullTurn.degrees;
  return (
    index: completed % shapes,
    progress: progress,
    degrees: progress * quarter + resting + global,
  );
}

/// Where an infinite timeline's zero is. Compose's infinite animations
/// start their clock on the first frame their coroutine awaits, the frame
/// after the one they are composed in; a Flutter ticker started while a
/// frame is being built counts from that frame instead. So the timeline's
/// zero is the ticker's first tick (the oracle's frame images agree only
/// so).
class _TimelineOrigin {
  Duration? _origin;

  Duration elapsed(Duration ticker) => ticker - (_origin ??= ticker);

  void reset() => _origin = null;
}

// ---------------------------------------------------------------------------
// The indicator
// ---------------------------------------------------------------------------

/// The Expressive loading indicator (Compose `LoadingIndicator`, or with
/// [contained] `ContainedLoadingIndicator`): a shape that morphs through
/// seven library shapes as it turns — the wait for anything under about
/// five seconds.
///
/// With [progress] 0–1 it is determinate: a circle growing into the soft
/// burst as it turns back half a turn (what pull-to-refresh draws while
/// pulling).
///
/// ```dart
/// ExpressiveLoadingIndicator(contained: true, semanticLabel: 'Loading recipes')
/// ```
class ExpressiveLoadingIndicator extends StatefulWidget {
  /// A loading indicator, indeterminate unless [progress] is given.
  const ExpressiveLoadingIndicator({
    this.progress,
    this.contained = false,
    this.color,
    this.containerColor,
    this.style,
    this.semanticLabel,
    super.key,
  });

  /// Stateful visual overrides for the indicator and its container.
  final ExpressiveComponentThemeData? style;

  /// The progress 0–1, or null for the indeterminate cycle.
  final double? progress;

  /// Whether the shape sits on its container
  /// (`LoadingIndicatorTokens.containedContainerColor`, fully round).
  final bool contained;

  /// The shape's colour: `activeIndicatorColor`, or
  /// `containedActiveColor` when contained.
  final Color? color;

  /// The container's colour when [contained].
  final Color? containerColor;

  /// What a screen reader says the indicator is waiting for.
  final String? semanticLabel;

  @override
  State<ExpressiveLoadingIndicator> createState() =>
      _ExpressiveLoadingIndicatorState();
}

class _ExpressiveLoadingIndicatorState extends State<ExpressiveLoadingIndicator>
    with SingleTickerProviderStateMixin {
  final ValueNotifier<Duration> _elapsed = ValueNotifier<Duration>(
    Duration.zero,
  );
  final _TimelineOrigin _origin = _TimelineOrigin();
  Ticker? _ticker;

  /// Under Reduce Motion (`MediaQuery.disableAnimationsOf`) the
  /// indeterminate indicator holds its first shape instead of morphing.
  bool _still = false;

  void _sync() {
    final moving = widget.progress == null && !_still;
    if (moving && _ticker == null) {
      _origin.reset();
      _ticker = createTicker(
        (elapsed) => _elapsed.value = _origin.elapsed(elapsed),
      )..start();
    } else if (!moving && _ticker != null) {
      _ticker!.dispose();
      _ticker = null;
      _elapsed.value = Duration.zero;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _still = ExpressiveMotion.of(context).reduceMotion;
    _sync();
  }

  @override
  void didUpdateWidget(ExpressiveLoadingIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  @override
  void dispose() {
    _ticker?.dispose();
    _elapsed.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    final visual = t.loadingIndicatorTheme.merge(widget.style);
    const states = <WidgetState>{};
    final color =
        visual.foregroundColor?.resolve(states) ??
        widget.color ??
        t.colors.role(
          widget.contained
              ? LoadingIndicatorTokens.containedActiveColor
              : LoadingIndicatorTokens.activeIndicatorColor,
        );
    final spring = ExpressiveMotion.of(context).policy.spatial(
      dampingRatio: LoadingIndicatorBehavior.morphDampingRatio,
      stiffness: LoadingIndicatorBehavior.morphStiffness,
    );
    final progress = widget.progress;
    // Its own layer: the morphing shape repaints every frame, its container
    // never.
    Widget indicator = RepaintBoundary(
      child: CustomPaint(
        size: Size(
          visual.iconSize?.resolve(states) ??
              t.density.width(LoadingIndicatorTokens.containerWidth),
          visual.iconSize?.resolve(states) ??
              t.density.height(LoadingIndicatorTokens.containerHeight),
        ),
        painter: _LoadingPainter(
          elapsed: _elapsed,
          progress: progress?.clamp(0.0, 1.0),
          color: color,
          spring: spring,
        ),
      ),
    );
    // Native loading has no content clip: the morph is the painted shape.
    // Keep ShapeDecoration's original circle rasterization at the defaults.
    if (visual.isEmpty) {
      if (widget.contained) {
        indicator = DecoratedBox(
          decoration: ShapeDecoration(
            color:
                widget.containerColor ??
                t.colors.role(LoadingIndicatorTokens.containedContainerColor),
            shape: t.shapes.of(LoadingIndicatorTokens.containerShape),
          ),
          child: indicator,
        );
      }
    } else {
      indicator = ExpressiveSurface(
        componentStyle: visual,
        shape: widget.contained
            ? t.shapes.of(LoadingIndicatorTokens.containerShape)
            : t.shapes.none,
        color: widget.contained
            ? widget.containerColor ??
                  t.colors.role(LoadingIndicatorTokens.containedContainerColor)
            : expressiveTransparent,
        child: indicator,
      );
    }
    return Semantics(
      label: widget.semanticLabel,
      value: progress == null
          ? null
          : '${(progress.clamp(0.0, 1.0) * 100).round()}%',
      child: indicator,
    );
  }
}

class _LoadingPainter extends CustomPainter {
  _LoadingPainter({
    required this.elapsed,
    required this.progress,
    required this.color,
    required this.spring,
  }) : super(repaint: elapsed);

  final ValueListenable<Duration> elapsed;
  final double? progress;
  final Color color;
  final SpringDescription spring;

  // The painter's own path, rewritten every frame (never allocated per
  // frame).
  final Path _path = Path();

  @override
  void paint(Canvas canvas, Size size) {
    final p = progress;
    final _Sequence sequence;
    final ExpressivePolygonMorph morph;
    final double at;
    final double degrees;
    if (p == null) {
      sequence = _Sequence.indeterminate;
      final cycle = _loadingCycle(
        elapsed.value,
        spring,
        sequence.morphs.length,
      );
      morph = sequence.morphs[cycle.index];
      at = cycle.progress;
      degrees = cycle.degrees;
    } else {
      // One morph: its index is 0, its progress the value.
      sequence = _Sequence.determinate;
      morph = sequence.morphs.first;
      at = p;
      degrees = -p * LoadingIndicatorBehavior.determinateRotation;
    }
    // The Spacer: a square as tall as the container.
    final side = math.min(size.width, size.height);
    final scale = side * sequence.scale;
    morph.writePath(_path, at, scaleX: scale, scaleY: scale);
    final centre = _path.getBounds().center;
    canvas
      ..save()
      ..translate(size.width / 2, size.height / 2)
      ..rotate(degrees / _FullTurn.degrees * _FullTurn.radians)
      ..translate(-centre.dx, -centre.dy)
      ..drawPath(
        _path,
        Paint()
          ..color = color
          ..isAntiAlias = true,
      )
      ..restore();
  }

  @override
  bool shouldRepaint(_LoadingPainter old) =>
      old.progress != progress ||
      old.color != color ||
      old.spring != spring ||
      old.elapsed != elapsed;
}

// ---------------------------------------------------------------------------
// Pull to refresh
// ---------------------------------------------------------------------------

/// Pull-to-refresh with the Expressive loading indicator (Compose
/// `PullToRefreshBox` with `PullToRefreshDefaults.LoadingIndicator`).
///
/// Pull [child]'s scrollable down from its top: the contained indicator
/// slides in from the top edge, its shape growing with the pull (and
/// turning back once past the threshold); release past the threshold and
/// [onRefresh] runs while the indicator cycles at the threshold; it
/// slides away when the future completes.
///
/// ```dart
/// ExpressiveRefreshIndicator(onRefresh: reload, child: ListView(children: tasks))
/// ```
class ExpressiveRefreshIndicator extends StatefulWidget {
  /// A pull-to-refresh around [child] that awaits [onRefresh].
  const ExpressiveRefreshIndicator({
    required this.onRefresh,
    required this.child,
    this.semanticLabel,
    this.style,
    super.key,
  });

  /// Visual overrides for both phases of the loading indicator.
  final ExpressiveComponentThemeData? style;

  /// What a completed pull runs; the indicator cycles until it completes.
  /// Null turns the pull off.
  final Future<void> Function()? onRefresh;

  /// The scrollable content.
  final Widget child;

  /// Whether a pull refreshes: [onRefresh] is set.
  bool get enabled => onRefresh != null;

  /// What a screen reader announces while refreshing (the strings'
  /// `refreshing` when null).
  final String? semanticLabel;

  @override
  State<ExpressiveRefreshIndicator> createState() =>
      ExpressivePullToRefreshState();
}

/// The state of an [ExpressiveRefreshIndicator]: [show] refreshes as if pulled.
class ExpressivePullToRefreshState extends State<ExpressiveRefreshIndicator>
    with SingleTickerProviderStateMixin {
  // distanceFraction: the indicator's travel as a fraction of the threshold.
  late final AnimationController _fraction = AnimationController.unbounded(
    vsync: this,
  );
  double _pulled = 0;
  bool _dragging = false;
  bool _refreshing = false;

  double get _threshold => PullToRefreshBehavior.positionalThreshold;

  /// Whether a refresh is running.
  bool get refreshing => _refreshing;

  @override
  void dispose() {
    _fraction.dispose();
    super.dispose();
  }

  SpringDescription get _spring =>
      ExpressiveMotion.of(context).spring(ExpressiveMotionKey.fastSpatial);

  /// `calculateVerticalOffset`: the pull, with tension past the threshold.
  double _offset() {
    final adjusted = _pulled * PullToRefreshBehavior.dragMultiplier;
    if (adjusted <= _threshold) return adjusted;
    final overshoot = adjusted / _threshold - 1;
    final linear = overshoot.clamp(0.0, 2.0);
    final tension = linear - linear * linear / 4;
    return _threshold + _threshold * tension;
  }

  void _pull(double delta) {
    if (_refreshing || !widget.enabled) return;
    _pulled = math.max(0, _pulled + delta);
    _fraction.value = _offset() / _threshold;
  }

  void _release() {
    if (!_dragging) return;
    _dragging = false;
    if (_refreshing) return;
    final adjusted = _pulled * PullToRefreshBehavior.dragMultiplier;
    _pulled = 0;
    if (adjusted > _threshold) {
      show();
    } else {
      _fraction.springTo(0, _spring);
    }
  }

  /// Runs [ExpressiveRefreshIndicator.onRefresh] with the indicator at the
  /// threshold, as a completed pull does.
  Future<void> show() async {
    if (_refreshing) return;
    setState(() => _refreshing = true);
    unawaited(_fraction.springTo(1, _spring));
    try {
      await widget.onRefresh?.call();
    } finally {
      if (mounted) {
        setState(() => _refreshing = false);
        unawaited(_fraction.springTo(0, _spring));
      }
    }
  }

  bool _onScroll(ScrollNotification n) {
    if (n.depth != 0 || n.metrics.axis != Axis.vertical) return false;
    final atTop = n.metrics.pixels <= n.metrics.minScrollExtent;
    switch (n) {
      case ScrollStartNotification(:final dragDetails):
        if (dragDetails != null && atTop) _dragging = true;
      case OverscrollNotification(:final overscroll, :final dragDetails):
        if (dragDetails != null && overscroll < 0) {
          _dragging = true;
          _pull(-overscroll);
        }
      case ScrollUpdateNotification(:final scrollDelta, :final dragDetails):
        if (dragDetails == null) {
          if (_dragging) _release();
        } else if (scrollDelta != null && (_pulled > 0 || atTop)) {
          // The iOS bounce reports the pull as scrolling past the top; a
          // push back up takes the pull back first (Compose's pre-scroll).
          if (atTop || scrollDelta > 0) {
            _dragging = true;
            _pull(-scrollDelta);
          }
        }
      case ScrollEndNotification():
        _release();
      default:
        break;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    final containerColor = t.colors.role(
      LoadingIndicatorTokens.containedContainerColor,
    );
    final indicatorColor = t.colors.role(
      LoadingIndicatorTokens.containedActiveColor,
    );
    return NotificationListener<OverscrollIndicatorNotification>(
      onNotification: (n) {
        if (_pulled > 0 || _refreshing) n.disallowIndicator();
        return false;
      },
      child: NotificationListener<ScrollNotification>(
        onNotification: _onScroll,
        child: Stack(
          children: <Widget>[
            widget.child,
            Positioned.fill(
              child: IgnorePointer(
                child: ClipRect(
                  child: AnimatedBuilder(
                    animation: _fraction,
                    builder: (context, _) {
                      final fraction = math.max(0.0, _fraction.value);
                      if (fraction == 0 && !_refreshing) {
                        return const SizedBox.shrink();
                      }
                      return Align(
                        alignment: Alignment.topCenter,
                        child: Transform.translate(
                          offset: Offset(
                            0,
                            fraction * _threshold -
                                LoadingIndicatorTokens.containerHeight,
                          ),
                          child: Semantics(
                            liveRegion: _refreshing,
                            label: _refreshing
                                ? widget.semanticLabel ??
                                      ExpressiveLocalizations.of(context)
                                          .refreshing
                                : null,
                            child: ExpressiveSpringValue(
                              value: _refreshing ? 1 : 0,
                              motion: PullToRefreshBehavior.crossfadeMotion,
                              builder: (context, crossfade, _) => Stack(
                                children: <Widget>[
                                  if (crossfade < 1)
                                    Opacity(
                                      opacity: (1 - crossfade).clamp(0.0, 1.0),
                                      child: Transform.rotate(
                                        angle: fraction > 1
                                            ? -(fraction - 1) *
                                                  PullToRefreshBehavior
                                                      .overshootRotation /
                                                  _FullTurn.degrees *
                                                  _FullTurn.radians
                                            : 0,
                                        child: ExpressiveLoadingIndicator(
                                          style: widget.style,
                                          progress: fraction,
                                          contained: true,
                                          color: indicatorColor,
                                          containerColor: containerColor,
                                        ),
                                      ),
                                    ),
                                  if (crossfade > 0)
                                    Opacity(
                                      opacity: crossfade.clamp(0.0, 1.0),
                                      child: ExpressiveLoadingIndicator(
                                        style: widget.style,
                                        contained: true,
                                        color: indicatorColor,
                                        containerColor: containerColor,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
