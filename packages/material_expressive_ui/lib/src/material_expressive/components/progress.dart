/// Progress — linear and circular indicators, determinate and
/// indeterminate, with the wavy variants as an opt-in hero — and the step
/// indicator (CONTRACT §4.1 `progress`, `step-indicator`). Owner:
/// w3-feedback.
///
/// A port of Compose material3 1.5.0-alpha29's `ProgressIndicator.kt`
/// (`LinearProgressIndicator` and `CircularProgressIndicator` with their
/// track gap and stop indicator) and `WavyProgressIndicator.kt` with its
/// drawing in `internal/LinearWavyProgressModifiers.kt` and
/// `internal/CircularWavyProgressModifiers.kt`. Geometry and colours come
/// from the generated `ProgressIndicatorTokens`,
/// `LinearProgressIndicatorTokens` and `CircularProgressIndicatorTokens`;
/// what Compose sets in code (the 240dp default width, the indeterminate
/// keyframe timelines, the wave's star) from `ProgressIndicatorBehavior`,
/// `ProgressEasingBehavior` and `WavyProgressIndicatorBehavior`
/// (`tools/expressive_tokens/behavior/progress.yaml`).
///
/// The drawing is Compose's line for line: the flat linear bar's round
/// caps clamped inside the track and the gap widened by the stroke; the
/// circular arcs from 12 o'clock with the gap as a sweep; the wavy line a
/// chain of quadratics measured and cut per frame, flattened by the
/// amplitude; the circular wave a star morphed from a circle, drawn twice
/// round so the wave can travel.
///
/// Deviations (recorded for the oracle):
/// - Compose runs the indeterminate timelines as keyframes on an infinite
///   transition. Expressive evaluates the same keyframes (same delays,
///   durations and cubic-bezier easings, and Compose's interval rule: an
///   easing applies to the interval that starts at its keyframe) as a
///   function of the frame clock's elapsed time, so no
///   `AnimationController` with a duration and no `Curve` exist here.
/// - Compose tweens a wavy indicator's amplitude over 500ms when progress
///   crosses 10 % or 95 %; Expressive runs the change on the default
///   effects spring (springs only).
library;

import 'dart:math' as math;
import 'dart:ui' show PathMetric;

import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../icons.dart';
import '../component_themes.dart';
import '../elevation.dart';
import '../internal/shape/graphics/graphics.dart';
import '../internal/tokens/behavior.g.dart';
import '../internal/tokens/circular_progress_indicator_tokens.g.dart';
import '../internal/tokens/linear_progress_indicator_tokens.g.dart';
import '../internal/tokens/progress_indicator_tokens.g.dart';
import '../motion.dart';
import '../spacing.dart';
import '../strings.dart';
import '../theme.dart';
import 'hero.dart';

// ---------------------------------------------------------------------------
// The indeterminate timelines (ProgressIndicator.kt's keyframes)
// ---------------------------------------------------------------------------

/// Compose's `CubicBezierEasing(x1, y1, x2, y2).transform(x)`: the curve's
/// y where its x is [x].
double _bezier(double x1, double y1, double x2, double y2, double x) {
  if (x <= 0) return 0;
  if (x >= 1) return 1;
  double at(double t, double a, double b) =>
      3 * (1 - t) * (1 - t) * t * a + 3 * (1 - t) * t * t * b + t * t * t;
  var lo = 0.0;
  var hi = 1.0;
  var t = x;
  for (var i = 0; i < 32; i++) {
    t = (lo + hi) / 2;
    if (at(t, x1, x2) < x) {
      lo = t;
    } else {
      hi = t;
    }
  }
  return at(t, y1, y2);
}

double _emphasizedAccelerate(double x) => _bezier(
  ProgressEasingBehavior.emphasizedAccelerateX1,
  ProgressEasingBehavior.emphasizedAccelerateY1,
  ProgressEasingBehavior.emphasizedAccelerateX2,
  ProgressEasingBehavior.emphasizedAccelerateY2,
  x,
);

double _standard(double x) => _bezier(
  ProgressEasingBehavior.standardX1,
  ProgressEasingBehavior.standardY1,
  ProgressEasingBehavior.standardX2,
  ProgressEasingBehavior.standardY2,
  x,
);

double _ms(Duration elapsed) =>
    elapsed.inMicroseconds / Duration.microsecondsPerMillisecond;

/// One of the linear indeterminate lines' ends: 0 until [delay], then
/// emphasized-accelerate to 1 over [duration], then 1 (`keyframes { 0f at
/// delay using LinearIndeterminateProgressEasing; 1f at duration + delay }`).
double _lineEnd(double ms, int delay, int duration) {
  if (ms <= delay) return 0;
  if (ms >= delay + duration) return 1;
  return _emphasizedAccelerate((ms - delay) / duration);
}

/// The four line ends of the linear indeterminate indicator at [elapsed]:
/// first head, first tail, second head, second tail.
List<double> _linearIndeterminateEnds(Duration elapsed) {
  final ms = _ms(elapsed) % ProgressIndicatorBehavior.linearDuration;
  return <double>[
    _lineEnd(
      ms,
      ProgressIndicatorBehavior.firstLineHeadDelay,
      ProgressIndicatorBehavior.firstLineHeadDuration,
    ),
    _lineEnd(
      ms,
      ProgressIndicatorBehavior.firstLineTailDelay,
      ProgressIndicatorBehavior.firstLineTailDuration,
    ),
    _lineEnd(
      ms,
      ProgressIndicatorBehavior.secondLineHeadDelay,
      ProgressIndicatorBehavior.secondLineHeadDuration,
    ),
    _lineEnd(
      ms,
      ProgressIndicatorBehavior.secondLineTailDelay,
      ProgressIndicatorBehavior.secondLineTailDuration,
    ),
  ];
}

/// The circular indeterminate indicator at [elapsed]: its rotation in
/// degrees (the linear global turn plus the four quarter steps) and its
/// sweep as a fraction of the circle (min → max linearly over the first
/// half, back with the standard easing over the second).
({double rotation, double sweep}) _circularIndeterminateState(
  Duration elapsed,
) {
  const duration = ProgressIndicatorBehavior.circularDuration;
  const delay = ProgressIndicatorBehavior.circularRotationDelay;
  const step = ProgressIndicatorBehavior.circularRotationDuration;
  final ms = _ms(elapsed) % duration;
  final global =
      ms / duration * ProgressIndicatorBehavior.circularGlobalRotationTarget;
  final quarter =
      ProgressIndicatorBehavior.circularRotationTarget / (duration ~/ delay);
  final k = ms ~/ delay;
  final within = ms - k * delay;
  final additional = k * quarter + math.min(1.0, within / step) * quarter;
  const min = ProgressIndicatorBehavior.circularMinProgress;
  const max = ProgressIndicatorBehavior.circularMaxProgress;
  final half = duration / 2;
  final sweep = ms < half
      ? min + (max - min) * (ms / half)
      : max + (min - max) * _standard((ms - half) / half);
  return (rotation: global + additional, sweep: sweep);
}

// ---------------------------------------------------------------------------
// The shared state: a frame clock for motion, a spring for the amplitude
// ---------------------------------------------------------------------------

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

/// The frame clock and the wave's amplitude an indicator paints from.
class _Clock extends ChangeNotifier {
  Duration elapsed = Duration.zero;
  double amplitude = 0;

  final _TimelineOrigin _origin = _TimelineOrigin();

  void tick(Duration value) {
    elapsed = _origin.elapsed(value);
    notifyListeners();
  }

  void restart() {
    _origin.reset();
    elapsed = Duration.zero;
    notifyListeners();
  }

  /// Stops the timeline at [frame].
  void hold(Duration frame) {
    if (elapsed == frame) return;
    elapsed = frame;
    notifyListeners();
  }

  void setAmplitude(double value) {
    if (value == amplitude) return;
    amplitude = value;
    notifyListeners();
  }
}

abstract class _ProgressState<T extends StatefulWidget> extends State<T>
    with TickerProviderStateMixin {
  final _Clock clock = _Clock();
  Ticker? _ticker;
  late final AnimationController _amplitude = AnimationController(vsync: this)
    ..addListener(() => clock.setAmplitude(_amplitude.value));

  /// The drawn value, or null when indeterminate.
  double? get value;

  /// Whether the indicator draws a wave.
  bool get wavy;

  /// The amplitude the wave rests at for [value] (Compose's
  /// `WavyProgressIndicatorDefaults.indicatorAmplitude`; 1 when
  /// indeterminate).
  double get targetAmplitude {
    if (!wavy) return 0;
    final v = value;
    if (v == null) return 1;
    return v <= WavyProgressIndicatorBehavior.amplitudeLowProgress ||
            v >= WavyProgressIndicatorBehavior.amplitudeHighProgress
        ? 0
        : 1;
  }

  /// Under Reduce Motion (`MediaQuery.disableAnimationsOf`) nothing loops:
  /// the wave stands still and an indeterminate indicator holds one frame
  /// of its cycle, its first line part way out.
  bool _still = false;

  bool get _moves => (value == null || wavy) && !_still;

  @override
  void initState() {
    super.initState();
    _amplitude.value = targetAmplitude;
    clock.amplitude = targetAmplitude;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _still = ExpressiveMotion.of(context).reduceMotion;
    _syncTicker();
  }

  void _syncTicker() {
    if (_moves && _ticker == null) {
      clock.restart();
      _ticker = createTicker(clock.tick)..start();
    } else if (!_moves && _ticker != null) {
      _ticker!.dispose();
      _ticker = null;
      clock.restart();
    }
    if (!_moves && _still && value == null) clock.hold(_stillFrame);
  }

  /// The frame a still indeterminate indicator holds.
  static const Duration _stillFrame = Duration(
    milliseconds: ProgressIndicatorBehavior.firstLineTailDelay,
  );

  @override
  void didUpdateWidget(covariant T oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncTicker();
    final target = targetAmplitude;
    if (_amplitude.value != target || _amplitude.isAnimating) {
      _amplitude.springTo(
        target,
        ExpressiveMotion.of(context).spring(ExpressiveMotionKey.defaultEffects),
      );
    }
  }

  @override
  void dispose() {
    _ticker?.dispose();
    _amplitude.dispose();
    clock.dispose();
    super.dispose();
  }
}

/// The progress semantics Compose sets: the value as a percentage, or none
/// while indeterminate.
Widget _semantics({
  required double? value,
  required String? label,
  required Widget child,
}) => Semantics(
  label: label,
  value: value == null ? null : '${(value.clamp(0.0, 1.0) * 100).round()}%',
  child: child,
);

/// Compose's `IncreaseVerticalSemanticsBounds` for the linear indicators: a
/// negative padding that keeps the track's layout height but grows the
/// merged semantics node `VerticalSemanticsBoundsPadding` above and below it,
/// so a screen reader gets a minimum-size box.
class _VerticalSemanticsBounds extends SingleChildRenderObjectWidget {
  const _VerticalSemanticsBounds({required super.child});

  /// The padding in whole device pixels, as Compose's `roundToPx` takes it.
  static double _padding(BuildContext context) {
    final ratio = MediaQuery.maybeDevicePixelRatioOf(context) ?? 1;
    return (ProgressIndicatorBehavior.verticalSemanticsBoundsPadding * ratio)
            .roundToDouble() /
        ratio;
  }

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderVerticalSemanticsBounds(_padding(context));

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderVerticalSemanticsBounds renderObject,
  ) => renderObject.padding = _padding(context);
}

class _RenderVerticalSemanticsBounds extends RenderProxyBox {
  _RenderVerticalSemanticsBounds(this._padding);

  double _padding;
  set padding(double value) {
    if (value == _padding) return;
    _padding = value;
    markNeedsSemanticsUpdate();
  }

  @override
  Rect get semanticBounds =>
      Rect.fromLTRB(0, -_padding, size.width, size.height + _padding);

  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);
    config
      ..isSemanticBoundary = true
      ..isMergingSemanticsOfDescendants = true;
  }
}

Paint _stroke(Color color, double width) => Paint()
  ..color = color
  ..style = PaintingStyle.stroke
  ..strokeWidth = width
  ..strokeCap = StrokeCap.round
  ..isAntiAlias = true;

// ---------------------------------------------------------------------------
// Linear
// ---------------------------------------------------------------------------

/// A linear progress indicator (Compose `LinearProgressIndicator`, or with
/// [wavy] `LinearWavyProgressIndicator`, a hero).
///
/// [value] 0–1 is determinate (the stop indicator marks the track's end);
/// null is indeterminate (two lines chase across the track). 240dp wide
/// unless [expand] fills the width available.
///
/// ```dart
/// ExpressiveLinearProgressIndicator(value: 0.4, semanticLabel: 'Upload')
/// ```
class ExpressiveLinearProgressIndicator extends StatefulWidget {
  /// A linear progress indicator at [value], indeterminate when null.
  const ExpressiveLinearProgressIndicator({
    this.value,
    this.wavy = false,
    this.expand = false,
    this.color,
    this.trackColor,
    this.semanticLabel,
    this.style,
    super.key,
  });

  /// Stateful slots for the frame; foreground colours its data ink.
  final ExpressiveComponentThemeData? style;

  /// The progress 0–1, or null while indeterminate.
  final double? value;

  /// Whether the active indicator is a travelling wave (a hero: it needs an
  /// [ExpressiveHeroMoment] above it, CONTRACT §3).
  final bool wavy;

  /// Whether the indicator fills the width available instead of its 240dp.
  final bool expand;

  /// The active indicator's colour
  /// (`ProgressIndicatorTokens.activeIndicatorColor`).
  final Color? color;

  /// The track's colour (`ProgressIndicatorTokens.trackColor`).
  final Color? trackColor;

  /// What a screen reader calls the indicator.
  final String? semanticLabel;

  @override
  State<ExpressiveLinearProgressIndicator> createState() =>
      _ExpressiveLinearProgressState();
}

/// An amount against its limit: the [label] at the start and the figure at
/// the end over a determinate [ExpressiveLinearProgressIndicator] that fills
/// the width, and a [note] under it. Past [limit] the indicator stays full
/// and the figure and the indicator turn `error`. Announced as one node:
/// the label, the figure of the limit, the note.
///
/// ```dart
/// ExpressiveMeter(label: 'Storage', value: 148, limit: 200, note: '52 GB left')
/// ```
class ExpressiveMeter extends StatelessWidget {
  /// A meter of [value] against [limit].
  const ExpressiveMeter({
    required this.label,
    required this.value,
    required this.limit,
    this.note,
    this.format,
    this.wavy = false,
    this.style,
    super.key,
  }) : assert(limit > 0, 'a meter measures against a positive limit');

  /// Stateful slots for the frame; foreground colours its data ink.
  final ExpressiveComponentThemeData? style;

  /// What is measured.
  final String label;

  /// How much there is.
  final double value;

  /// How much there may be.
  final double limit;

  /// A line under the indicator (what is left, when it resets); none when
  /// null.
  final String? note;

  /// Writes a figure; whole numbers when null.
  final String Function(double value)? format;

  /// The wavy indicator (Material 3 Expressive's).
  final bool wavy;

  String _figure(double v) => format?.call(v) ?? v.round().toString();

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    final over = value > limit;
    final visual = t.meterTheme.merge(style);
    final states = <WidgetState>{if (over) WidgetState.error};
    final ink = visual.foregroundColor?.resolve(states);
    final typography = visual.textStyle?.resolve(states);
    final figure = '${_figure(value)} / ${_figure(limit)}';
    final note = this.note;
    return ExpressiveSurface(
      componentStyle: visual,
      states: states,
      shape: t.shapes.none,
      color: expressiveTransparent,
      padding: EdgeInsets.zero,
      child: Semantics(
        container: true,
        label: label,
        value: <String>[figure, ?note].join(', '),
        child: ExcludeSemantics(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              LayoutBuilder(
                builder: (context, constraints) {
                  final titleStyle = t.type.bodyLarge
                      .merge(typography)
                      .copyWith(color: ink ?? t.colors.onSurface);
                  final valueStyle = t.type.labelLarge
                      .merge(typography)
                      .copyWith(
                        color:
                            ink ??
                            (over ? t.colors.error : t.colors.onSurfaceVariant),
                        fontFeatures: const <FontFeature>[
                          FontFeature.tabularFigures(),
                        ],
                      );
                  final title = Text(label, style: titleStyle);
                  final amount = Text(figure, style: valueStyle);
                  TextPainter measure(String text, TextStyle style) =>
                      TextPainter(
                        text: TextSpan(text: text, style: style),
                        textDirection: Directionality.of(context),
                        textScaler: MediaQuery.textScalerOf(context),
                      )..layout();
                  final titleSize = measure(label, titleStyle);
                  final valueSize = measure(figure, valueStyle);
                  final required =
                      titleSize.minIntrinsicWidth +
                      valueSize.width +
                      ExpressiveSpacing.s12;
                  titleSize.dispose();
                  valueSize.dispose();
                  if (constraints.maxWidth < required) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [title, amount],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Expanded(child: title),
                      const SizedBox(width: ExpressiveSpacing.s12),
                      amount,
                    ],
                  );
                },
              ),
              const SizedBox(height: ExpressiveSpacing.s8),
              ExpressiveLinearProgressIndicator(
                value: (value / limit).clamp(0, 1).toDouble(),
                wavy: wavy,
                expand: true,
                color: ink ?? (over ? t.colors.error : null),
              ),
              if (note != null) ...<Widget>[
                const SizedBox(height: ExpressiveSpacing.s4),
                Text(
                  note,
                  style: t.type.bodySmall
                      .merge(typography)
                      .copyWith(color: ink ?? t.colors.onSurfaceVariant),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ExpressiveLinearProgressState
    extends _ProgressState<ExpressiveLinearProgressIndicator> {
  final _LinearWavyCache _cache = _LinearWavyCache();

  @override
  double? get value => widget.value;

  @override
  bool get wavy => widget.wavy;

  @override
  Widget build(BuildContext context) {
    if (widget.wavy) {
      assert(
        ExpressiveHeroMoment.debugCheck(
          context,
          'ExpressiveLinearProgressIndicator (wavy)',
        ),
      );
    }
    final t = context.expressiveTheme;
    final visual = t.progressIndicatorTheme.merge(widget.style);
    const states = <WidgetState>{};
    final color =
        visual.foregroundColor?.resolve(states) ??
        widget.color ??
        t.colors.role(ProgressIndicatorTokens.activeIndicatorColor);
    final track =
        widget.trackColor ?? t.colors.role(ProgressIndicatorTokens.trackColor);
    final height = widget.wavy
        ? LinearProgressIndicatorTokens.waveHeight
        : LinearProgressIndicatorTokens.height;
    final direction = Directionality.of(context);
    return ExpressiveSurface(
      componentStyle: visual,
      clipBehavior: Clip.none,
      shape: t.shapes.none,
      color: expressiveTransparent,
      padding: EdgeInsets.zero,
      child: _VerticalSemanticsBounds(
        child: _semantics(
          value: widget.value,
          label: widget.semanticLabel,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = widget.expand && constraints.hasBoundedWidth
                  ? constraints.maxWidth
                  : math.min(
                      ProgressIndicatorBehavior.linearWidth,
                      constraints.maxWidth,
                    );
              // Its own layer: an indeterminate or wavy bar repaints every
              // frame for as long as it shows, and nothing around it should.
              return RepaintBoundary(
                child: ClipRect(
                  child: CustomPaint(
                    size: Size(width, height),
                    painter: widget.wavy
                        ? _LinearWavyPainter(
                            clock: clock,
                            cache: _cache,
                            value: widget.value,
                            color: color,
                            trackColor: track,
                            direction: direction,
                          )
                        : _LinearPainter(
                            clock: clock,
                            value: widget.value,
                            color: color,
                            trackColor: track,
                            direction: direction,
                          ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// `LinearProgressIndicator`'s drawing (ProgressIndicator.kt).
class _LinearPainter extends CustomPainter {
  _LinearPainter({
    required this.clock,
    required this.value,
    required this.color,
    required this.trackColor,
    required this.direction,
  }) : super(repaint: clock);

  final _Clock clock;
  final double? value;
  final Color color;
  final Color trackColor;
  final TextDirection direction;

  void _line(Canvas canvas, Size size, double from, double to, Paint paint) {
    final width = size.width;
    final y = size.height / 2;
    final ltr = direction == TextDirection.ltr;
    final start = (ltr ? from : 1 - to) * width;
    final end = (ltr ? to : 1 - from) * width;
    final cap = paint.strokeWidth / 2;
    if ((to - from).abs() > 0) {
      canvas.drawLine(
        Offset(start.clamp(cap, width - cap), y),
        Offset(end.clamp(cap, width - cap), y),
        paint,
      );
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.height;
    final active = _stroke(color, stroke)..strokeCap = StrokeCap.round;
    final track = _stroke(trackColor, stroke)..strokeCap = StrokeCap.round;
    // Round caps: the gap grows by the stroke (Compose's adjustedGapSize).
    final gap =
        (LinearProgressIndicatorTokens.trackActiveSpace + stroke) / size.width;
    final v = value;
    if (v != null) {
      final p = v.clamp(0.0, 1.0);
      final trackStart = p + math.min(p, gap);
      if (trackStart <= 1) _line(canvas, size, trackStart, 1, track);
      _line(canvas, size, 0, p, active);
      _stop(canvas, size);
      return;
    }
    final ends = _linearIndeterminateEnds(clock.elapsed);
    final firstHead = ends[0];
    final firstTail = ends[1];
    final secondHead = ends[2];
    final secondTail = ends[3];
    if (firstHead < 1 - gap) {
      _line(canvas, size, firstHead > 0 ? firstHead + gap : 0, 1, track);
    }
    if (firstHead - firstTail > 0) {
      _line(canvas, size, firstTail, firstHead, active);
    }
    if (firstTail > gap) {
      final start = secondHead > 0 ? secondHead + gap : 0.0;
      final end = firstTail < 1 ? firstTail - gap : 1.0;
      _line(canvas, size, start, end, track);
    }
    if (secondHead - secondTail > 0) {
      _line(canvas, size, secondTail, secondHead, active);
    }
    if (secondTail > gap) {
      _line(canvas, size, 0, secondTail < 1 ? secondTail - gap : 1, track);
    }
  }

  /// `ProgressIndicatorDefaults.drawStopIndicator`: a round dot at the
  /// track's end.
  void _stop(Canvas canvas, Size size) {
    final stop = math.min(LinearProgressIndicatorTokens.stopSize, size.height);
    final offset = math.min(
      (size.height - stop) / 2,
      ProgressIndicatorBehavior.stopTrailingSpace,
    );
    final radius = stop / 2;
    final x = size.width - radius - offset;
    final y = size.height / 2;
    canvas.drawCircle(
      Offset(direction == TextDirection.ltr ? x : size.width - x, y),
      radius,
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(_LinearPainter old) =>
      old.value != value ||
      old.color != color ||
      old.trackColor != trackColor ||
      old.direction != direction;
}

/// `LinearProgressDrawingCache`: the full wave, rebuilt only when the size
/// or the wave's presence changes.
class _LinearWavyCache {
  Size? _size;
  bool? _waved;
  double? _wavelength;
  PathMetric? _metric;
  double _scale = 1;

  void update(Size size, double amplitude, double stroke, double wavelength) {
    final waved = amplitude != 0;
    if (_size == size && _waved == waved && _wavelength == wavelength) return;
    _size = size;
    _waved = waved;
    _wavelength = wavelength;
    final path = Path()..moveTo(0, 0);
    if (!waved) {
      path.lineTo(size.width, 0);
    } else {
      final half = wavelength / 2;
      var anchorX = half;
      var controlX = half / 2;
      var controlY = size.height - stroke;
      final end = size.width + wavelength * 2;
      while (anchorX <= end) {
        path.quadraticBezierTo(controlX, controlY, anchorX, 0);
        anchorX += half;
        controlX += half;
        controlY = -controlY;
      }
    }
    final baseline = size.height / 2;
    final full = path.shift(Offset(0, baseline));
    _metric = full.computeMetrics().first;
    _scale = _metric!.length / (full.getBounds().width + 0.00000001);
  }

  Path segment(double from, double to) =>
      _metric!.extractPath(from * _scale, to * _scale);
}

/// `LinearWavyProgressIndicator`'s drawing (LinearWavyProgressModifiers.kt).
class _LinearWavyPainter extends CustomPainter {
  _LinearWavyPainter({
    required this.clock,
    required this.cache,
    required this.value,
    required this.color,
    required this.trackColor,
    required this.direction,
  }) : super(repaint: clock);

  final _Clock clock;
  final _LinearWavyCache cache;
  final double? value;
  final Color color;
  final Color trackColor;
  final TextDirection direction;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = LinearProgressIndicatorTokens.activeThickness;
    const trackStroke = LinearProgressIndicatorTokens.trackThickness;
    final amplitude = clock.amplitude.clamp(0.0, 1.0);
    final v = value;
    final wavelength = v == null
        ? LinearProgressIndicatorTokens.indeterminateActiveWaveWavelength
        : LinearProgressIndicatorTokens.activeWaveWavelength;
    cache.update(size, amplitude, stroke, wavelength);
    // One wavelength per second (waveSpeed = wavelength).
    final offset = amplitude > 0
        ? (clock.elapsed.inMicroseconds % Duration.microsecondsPerSecond) /
              Duration.microsecondsPerSecond
        : 0.0;
    final List<double> fractions;
    if (v == null) {
      final e = _linearIndeterminateEnds(clock.elapsed);
      // (start, end) pairs: each line's tail, then its head.
      fractions = <double>[e[1], e[0], e[3], e[2]];
    } else {
      fractions = <double>[0, v.clamp(0.0, 1.0)];
    }
    final width = size.width;
    final half = size.height / 2;
    final cap = math.max(stroke / 2, trackStroke / 2);
    double gap = LinearProgressIndicatorTokens.trackActiveSpace;
    var visible = false;
    var nextEnd = width - cap;
    final trackPath = Path()..moveTo(nextEnd, half);
    final active = <Path>[];
    for (var i = 0; i < fractions.length ~/ 2; i++) {
      final tail = fractions[i * 2] * width;
      final head = fractions[i * 2 + 1] * width;
      if (i == 0) {
        gap = head < cap
            ? 0
            : math.min(
                head - cap,
                LinearProgressIndicatorTokens.trackActiveSpace,
              );
        visible = head >= cap;
      }
      final adjustedHead = head.clamp(cap, width - cap);
      final adjustedTail = tail.clamp(cap, width - cap);
      if ((fractions[i * 2 + 1] - fractions[i * 2]).abs() > 0) {
        final shift = amplitude != 0 ? offset * wavelength : 0.0;
        final matrix = Matrix4.identity()
          ..translateByDouble(-shift, (1 - amplitude) * half, 0, 1)
          ..scaleByDouble(1, amplitude == 0 ? 1 : amplitude, 1, 1);
        active.add(
          cache
              .segment(adjustedTail + shift, adjustedHead + shift)
              .transform(matrix.storage),
        );
      }
      final spacing = visible ? gap + cap * 2 : gap;
      if (nextEnd > adjustedHead + spacing) {
        trackPath.lineTo(math.max(cap, adjustedHead + spacing), half);
      }
      if (head > tail) {
        nextEnd = math.max(cap, adjustedTail - spacing);
        trackPath.moveTo(nextEnd, half);
      }
    }
    if (nextEnd > cap) trackPath.lineTo(cap, half);

    canvas.save();
    if (direction == TextDirection.rtl) {
      canvas
        ..translate(size.width, size.height)
        ..rotate(math.pi);
    }
    canvas.drawPath(
      trackPath,
      _stroke(trackColor, trackStroke)..strokeCap = StrokeCap.round,
    );
    final paint = _stroke(color, stroke)..strokeCap = StrokeCap.round;
    for (final path in active) {
      canvas.drawPath(path, paint);
    }
    if (v != null) _stop(canvas, size, fractions[1], cap, trackStroke);
    canvas.restore();
  }

  /// The wavy indicator's `drawStopIndicator`: it shrinks as the progress
  /// reaches it.
  void _stop(
    Canvas canvas,
    Size size,
    double end,
    double insets,
    double trackStroke,
  ) {
    double stop = math.min(trackStroke, LinearProgressIndicatorTokens.stopSize);
    final inset = stop == trackStroke ? 0.0 : trackStroke / 4;
    var x = size.width - stop - inset;
    final progressX = size.width * end + insets;
    if (x <= progressX) {
      stop = math.max(0, stop - (progressX - x));
      x = progressX;
    }
    if (stop > 0) {
      final radius = stop / 2;
      final y = size.height / 2;
      canvas.drawCircle(Offset(x + radius, y), radius, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(_LinearWavyPainter old) =>
      old.value != value ||
      old.color != color ||
      old.trackColor != trackColor ||
      old.direction != direction;
}

// ---------------------------------------------------------------------------
// Circular
// ---------------------------------------------------------------------------

/// A circular progress indicator (Compose `CircularProgressIndicator`, 40dp;
/// or with [wavy] `CircularWavyProgressIndicator`, 48dp, a hero).
///
/// [value] 0–1 is determinate, from 12 o'clock clockwise with the track
/// after a gap; null is indeterminate (a growing and shrinking arc that
/// turns; the flat one has no track).
///
/// ```dart
/// ExpressiveCircularProgressIndicator(semanticLabel: 'Syncing')
/// ```
class ExpressiveCircularProgressIndicator extends StatefulWidget {
  /// A circular progress indicator at [value], indeterminate when null.
  const ExpressiveCircularProgressIndicator({
    this.value,
    this.wavy = false,
    this.color,
    this.trackColor,
    this.semanticLabel,
    this.style,
    super.key,
  });

  /// Stateful slots for the frame; foreground colours its data ink.
  final ExpressiveComponentThemeData? style;

  /// The progress 0–1, or null while indeterminate.
  final double? value;

  /// Whether the active indicator is a travelling wave (a hero).
  final bool wavy;

  /// The active indicator's colour.
  final Color? color;

  /// The track's colour; a flat indeterminate indicator has none unless
  /// given one (`circularIndeterminateTrackColor` is transparent).
  final Color? trackColor;

  /// What a screen reader calls the indicator.
  final String? semanticLabel;

  @override
  State<ExpressiveCircularProgressIndicator> createState() =>
      _ExpressiveCircularProgressState();
}

class _ExpressiveCircularProgressState
    extends _ProgressState<ExpressiveCircularProgressIndicator> {
  final _CircularWavyCache _cache = _CircularWavyCache();

  @override
  double? get value => widget.value;

  @override
  bool get wavy => widget.wavy;

  @override
  Widget build(BuildContext context) {
    if (widget.wavy) {
      assert(
        ExpressiveHeroMoment.debugCheck(
          context,
          'ExpressiveCircularProgressIndicator (wavy)',
        ),
      );
    }
    final t = context.expressiveTheme;
    final visual = t.progressIndicatorTheme.merge(widget.style);
    const states = <WidgetState>{};
    final color =
        visual.foregroundColor?.resolve(states) ??
        widget.color ??
        t.colors.role(ProgressIndicatorTokens.activeIndicatorColor);
    final track =
        widget.trackColor ??
        (widget.value == null && !widget.wavy
            ? null
            : t.colors.role(ProgressIndicatorTokens.trackColor));
    final side =
        visual.iconSize?.resolve(states) ??
        (widget.wavy
            ? CircularProgressIndicatorTokens.waveSize
            : CircularProgressIndicatorTokens.size);
    return ExpressiveSurface(
      componentStyle: visual,
      clipBehavior: visual.shape?.resolve(states) == null
          ? Clip.none
          : Clip.antiAlias,
      shape: t.shapes.none,
      color: expressiveTransparent,
      padding: EdgeInsets.zero,
      child: _semantics(
        value: widget.value,
        label: widget.semanticLabel,
        // Its own layer: a spinning or wavy ring repaints every frame.
        child: RepaintBoundary(
          child: CustomPaint(
            size: Size.square(side),
            painter: widget.wavy
                ? _CircularWavyPainter(
                    clock: clock,
                    cache: _cache,
                    value: widget.value,
                    color: color,
                    trackColor: track,
                  )
                : _CircularPainter(
                    clock: clock,
                    value: widget.value,
                    color: color,
                    trackColor: track,
                  ),
          ),
        ),
      ),
    );
  }
}

double _radians(double degrees) => degrees * math.pi / 180;

/// `CircularProgressIndicator`'s drawing (ProgressIndicator.kt).
class _CircularPainter extends CustomPainter {
  _CircularPainter({
    required this.clock,
    required this.value,
    required this.color,
    required this.trackColor,
  }) : super(repaint: clock);

  final _Clock clock;
  final double? value;
  final Color color;
  final Color? trackColor;

  Paint _arcStroke(Color color, double width) =>
      _stroke(color, width)..strokeCap = StrokeCap.round;

  void _arc(Canvas canvas, Size size, double start, double sweep, Paint p) {
    final inset = p.strokeWidth / 2;
    final side = size.width - p.strokeWidth;
    canvas.drawArc(
      Offset(inset, inset) & Size.square(side),
      _radians(start),
      _radians(sweep),
      false,
      p,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = CircularProgressIndicatorTokens.trackThickness;
    final active = _arcStroke(color, stroke);
    final track = trackColor;
    // Round caps: the gap grows by the stroke, as a sweep of the circle.
    final gapSweep =
        (CircularProgressIndicatorTokens.trackActiveSpace + stroke) /
        (math.pi * size.width) *
        360;
    final v = value;
    if (v != null) {
      final sweep = v.clamp(0.0, 1.0) * 360;
      const start = 270.0;
      final gap = math.min(sweep, gapSweep);
      if (track != null) {
        _arc(
          canvas,
          size,
          start + sweep + gap,
          360 - sweep - gap * 2,
          _arcStroke(track, stroke),
        );
      }
      if (sweep > 0) _arc(canvas, size, start, sweep, active);
      return;
    }
    final state = _circularIndeterminateState(clock.elapsed);
    final sweep = state.sweep * 360;
    final gap = math.min(sweep, gapSweep);
    canvas
      ..save()
      ..translate(size.width / 2, size.height / 2)
      ..rotate(_radians(state.rotation))
      ..translate(-size.width / 2, -size.height / 2);
    if (track != null) {
      _arc(
        canvas,
        size,
        sweep + gap,
        360 - sweep - gap * 2,
        _arcStroke(track, stroke),
      );
    }
    _arc(canvas, size, 0, sweep, active);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_CircularPainter old) =>
      old.value != value || old.color != color || old.trackColor != trackColor;
}

/// `CircularShapes` + `CircularProgressDrawingCache`: the circle the track
/// follows and the star the wave is drawn from, morphed by the amplitude,
/// scaled into the stroke's inset box and centred.
class _CircularWavyCache {
  Size? _size;
  int _vertices = 0;
  ExpressiveRoundedPolygon? _circle;
  ExpressivePolygonMorph? _morph;
  double? _amplitude;
  PathMetric? _progress;
  PathMetric? _track;
  Rect _bounds = Rect.zero;

  int get vertices => _vertices;

  void update(Size size, double amplitude, double stroke) {
    if (_size != size) {
      final r = size.shortestSide / 2 - stroke / 2;
      final count = math.max(
        WavyProgressIndicatorBehavior.circularMinVertexCount.toInt(),
        (2 * math.pi * r / CircularProgressIndicatorTokens.activeWaveWavelength)
            .round(),
      );
      if (count != _vertices) {
        _vertices = count;
        _circle = ExpressiveRoundedPolygon.circle(numVertices: count)
            .normalized();
        final star = ExpressiveRoundedPolygon.star(
          numVerticesPerRadius: count,
          innerRadius: WavyProgressIndicatorBehavior.starInnerRadius,
          rounding: const ExpressiveCornerRounding(
            radius: WavyProgressIndicatorBehavior.starRounding,
            smoothing: WavyProgressIndicatorBehavior.starSmoothing,
          ),
          innerRounding: const ExpressiveCornerRounding(
            radius: WavyProgressIndicatorBehavior.starInnerRounding,
          ),
        ).normalized();
        _morph = ExpressivePolygonMorph(_circle!, star);
      }
      _size = size;
      _amplitude = null;
    }
    if (_amplitude == amplitude) return;
    _amplitude = amplitude;
    final scale = Matrix4.diagonal3Values(
      size.width - stroke,
      size.height - stroke,
      1,
    );
    Path place(Path p) {
      final scaled = p.transform(scale.storage);
      return scaled.shift(size.center(Offset.zero) - scaled.getBounds().center);
    }

    final progress = place(
      _pathFrom(_morph!.asCubics(amplitude), repeat: true),
    );
    _bounds = progress.getBounds();
    _progress = progress.computeMetrics(forceClosed: true).first;
    _track = place(_pathFrom(_circle!.cubics, repeat: false))
        .computeMetrics(forceClosed: true)
        .first;
  }

  /// The internal `pathFromCubics`: the cubics (twice round when
  /// [repeat]), closed, turned about the origin so the first anchor sits
  /// at 12 o'clock (start angle 270), as Compose turns it.
  static Path _pathFrom(
    List<ExpressiveShapeCubic> cubics, {
    required bool repeat,
  }) {
    final path = Path();
    for (var pass = 0; pass < (repeat ? 2 : 1); pass++) {
      for (var i = 0; i < cubics.length; i++) {
        final c = cubics[i];
        if (i == 0) {
          if (pass == 0) {
            path.moveTo(c.anchor0X, c.anchor0Y);
          } else {
            path.lineTo(c.anchor0X, c.anchor0Y);
          }
        }
        path.cubicTo(
          c.control0X,
          c.control0Y,
          c.control1X,
          c.control1Y,
          c.anchor1X,
          c.anchor1Y,
        );
      }
    }
    path.close();
    final first = cubics.first;
    const pivot = 0.5;
    final angle =
        math.atan2(first.anchor0Y - pivot, first.anchor0X - pivot) *
        180 /
        math.pi;
    return path.transform(Matrix4.rotationZ(_radians(270 - angle)).storage);
  }

  /// The active arc from [start] to [end] (fractions of one lap), the
  /// wave travelled by [offset] laps and turned back so the arc stays put.
  Path progress(double start, double end, double offset) {
    final lap = _progress!.length / 2;
    final shift = offset.clamp(0.0, 1.0) * lap;
    var path = _progress!.extractPath(start * lap + shift, end * lap + shift);
    final angle = offset * 360 % 360;
    if (angle != 0) {
      final c = _bounds.center;
      path = path
          .shift(-c)
          .transform(Matrix4.rotationZ(_radians(-angle)).storage)
          .shift(c);
    }
    return path;
  }

  /// The track, from after the arc's end (and its gap) to before its start.
  Path track(double end, double gap, double cap) {
    final length = _track!.length;
    final stop = end * (_progress!.length / 2);
    final spacing = math.min(stop, cap) * 2 + math.min(stop, gap);
    return _track!.extractPath(end * length + spacing, length - spacing);
  }
}

/// `CircularWavyProgressIndicator`'s drawing
/// (CircularWavyProgressModifiers.kt).
class _CircularWavyPainter extends CustomPainter {
  _CircularWavyPainter({
    required this.clock,
    required this.cache,
    required this.value,
    required this.color,
    required this.trackColor,
  }) : super(repaint: clock);

  final _Clock clock;
  final _CircularWavyCache cache;
  final double? value;
  final Color color;
  final Color? trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = CircularProgressIndicatorTokens.activeThickness;
    const trackStroke = CircularProgressIndicatorTokens.trackThickness;
    final amplitude = clock.amplitude.clamp(0.0, 1.0);
    cache.update(size, amplitude, stroke);
    // One wavelength per second: a lap of the wave takes a second a vertex.
    final lap = Duration.microsecondsPerSecond * cache.vertices;
    final offset = amplitude > 0
        ? (clock.elapsed.inMicroseconds % lap) / lap
        : 0.0;
    final cap = math.max(stroke / 2, trackStroke / 2);
    final butt = StrokeCap.round;
    final v = value;
    final double end;
    var rotation = 0.0;
    if (v == null) {
      final state = _circularIndeterminateState(clock.elapsed);
      end = state.sweep;
      rotation =
          state.rotation +
          WavyProgressIndicatorBehavior.indeterminateRotationOffset;
    } else {
      end = v.clamp(0.0, 1.0);
    }
    canvas.save();
    if (rotation != 0) {
      canvas
        ..translate(size.width / 2, size.height / 2)
        ..rotate(_radians(rotation))
        ..translate(-size.width / 2, -size.height / 2);
    }
    final track = trackColor;
    if (track != null) {
      canvas.drawPath(
        cache.track(end, CircularProgressIndicatorTokens.trackActiveSpace, cap),
        _stroke(track, trackStroke)..strokeCap = butt,
      );
    }
    if (end > 0) {
      canvas.drawPath(
        cache.progress(0, end, offset),
        _stroke(color, stroke)..strokeCap = butt,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_CircularWavyPainter old) =>
      old.value != value || old.color != color || old.trackColor != trackColor;
}

// ---------------------------------------------------------------------------
// Step indicator
// ---------------------------------------------------------------------------

/// How an [ExpressiveStepProgress] draws its steps.
enum ExpressiveStepProgressKind {
  /// Numbered markers joined by the progress track, labels beneath.
  numbered,

  /// One flat progress segment per step, gapped: a compact stepper.
  segmented,
}

/// A step indicator: where a flow is among [count] steps. Material 3 has
/// none; it is built from the progress tokens — the active and track
/// colours, the track's thickness, shape and gap.
///
/// Steps before [current] are done (a check), [current] is active, the rest
/// are to come; [current] == [count] is every step done.
///
/// ```dart
/// ExpressiveStepProgress(count: 3, currentStep: 1, labels: ['Cart', 'Address', 'Pay'])
/// ```
class ExpressiveStepProgress extends StatelessWidget {
  /// A step indicator at [currentStep] of [count] steps.
  const ExpressiveStepProgress({
    required this.count,
    required this.currentStep,
    this.labels,
    this.kind = ExpressiveStepProgressKind.numbered,
    this.style,
    super.key,
  }) : assert(count > 0),
       assert(currentStep >= 0 && currentStep <= count);

  /// How many steps there are.
  final int count;

  /// The active step, from 0 (`count` when every step is done).
  final int currentStep;

  /// A label per step, or none.
  final List<String>? labels;

  /// Numbered markers or flat segments.
  final ExpressiveStepProgressKind kind;

  /// Stateful visual slots for step markers and their labels.
  final ExpressiveComponentThemeData? style;

  @override
  Widget build(BuildContext context) {
    assert(labels == null || labels!.length == count, 'a label per step');
    final t = context.expressiveTheme;
    final visual = t.stepProgressTheme.merge(style);
    Set<WidgetState> states(int i) => <WidgetState>{
      if (i <= currentStep) WidgetState.selected,
    };
    final active = t.colors.role(ProgressIndicatorTokens.activeIndicatorColor);
    final track = t.colors.role(ProgressIndicatorTokens.trackColor);
    final shape = t.shapes.of(ProgressIndicatorTokens.trackShape);
    final strings = ExpressiveLocalizations.of(context);
    final label = currentStep < count
        ? strings.stepOf(currentStep + 1, count) +
              (labels == null ? '' : ': ${labels![currentStep]}')
        : strings.allStepsDone(count);
    Widget bar(bool reached) => ExpressiveSpringColor(
      value:
          visual.backgroundColor?.resolve(<WidgetState>{
            if (reached) WidgetState.selected,
          }) ??
          (reached ? active : track),
      motion: ExpressiveMotionKey.defaultEffects,
      builder: (context, color, _) => ExpressiveSurface(
        componentStyle: visual,
        states: <WidgetState>{if (reached) WidgetState.selected},
        shape: shape,
        color: color,
        child: SizedBox(height: LinearProgressIndicatorTokens.trackThickness),
      ),
    );
    Widget name(int i, TextAlign align) => Text(
      labels![i],
      textAlign: align,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style:
          (i == currentStep ? t.type.labelMediumEmphasized : t.type.labelMedium)
              .merge(visual.textStyle?.resolve(states(i)))
              .copyWith(
                color:
                    visual.foregroundColor?.resolve(states(i)) ??
                    (i <= currentStep
                        ? t.colors.onSurface
                        : t.colors.onSurfaceVariant),
              ),
    );
    if (kind == ExpressiveStepProgressKind.segmented) {
      // Each label starts under its own segment, as the segment it names.
      return Semantics(
        label: label,
        container: true,
        child: ExcludeSemantics(
          child: Row(
            spacing: LinearProgressIndicatorTokens.trackActiveSpace,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              for (var i = 0; i < count; i++)
                Expanded(
                  child: labels == null
                      ? bar(i <= currentStep)
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            bar(i <= currentStep),
                            const SizedBox(height: ExpressiveSpacing.s8),
                            name(i, TextAlign.start),
                          ],
                        ),
                ),
            ],
          ),
        ),
      );
    }
    final markers = <Widget>[];
    for (var i = 0; i < count; i++) {
      if (i > 0) {
        markers.add(
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: LinearProgressIndicatorTokens.trackActiveSpace,
              ),
              child: bar(i <= currentStep),
            ),
          ),
        );
      }
      markers.add(_StepMarker(index: i, current: currentStep, style: visual));
    }
    final names = labels;
    var minimumWidth =
        (count - 1) * LinearProgressIndicatorTokens.trackActiveSpace * 2;
    for (var i = 0; i < count; i++) {
      final state = states(i);
      final border = visual.shape?.resolve(state);
      final inset =
          border
              ?.copyWith(
                side:
                    visual.side?.resolve(state) ??
                    BorderSide.none.copyWith(
                      color: visual.outline?.resolve(state),
                      style: visual.outline?.resolve(state) == null
                          ? null
                          : BorderStyle.solid,
                    ),
              )
              .dimensions
              .resolve(Directionality.of(context)) ??
          EdgeInsets.zero;
      final space =
          visual.padding?.resolve(state)?.resolve(Directionality.of(context)) ??
          EdgeInsets.zero;
      minimumWidth += math.max(
        visual.minimumSize?.resolve(state)?.width ?? 0,
        _stepExtent(t, visual, state) + inset.horizontal + space.horizontal,
      );
    }
    // One marker's width (the markers' share of the row's minimum).
    final markerExtent =
        (minimumWidth -
            (count - 1) * LinearProgressIndicatorTokens.trackActiveSpace * 2) /
        count;
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: math.max(constraints.maxWidth, minimumWidth),
          child: Semantics(
            label: label,
            container: true,
            child: ExcludeSemantics(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Row(children: markers),
                  if (names != null) ...<Widget>[
                    const SizedBox(height: ExpressiveSpacing.s8),
                    // Each label centred under its marker, the first and
                    // last kept to the ends; never cut.
                    _StepLabels(
                      markerExtent: markerExtent,
                      textDirection: Directionality.of(context),
                      children: <Widget>[
                        for (var i = 0; i < count; i++)
                          name(i, TextAlign.center),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The numbered steps' names: each centred under its marker (the markers
/// spread evenly, the first and last at the row's ends), kept within the
/// row. When two names would meet (long names, large text), every name
/// prints smaller by one scale until they stand apart, rather than any
/// being cut.
class _StepLabels extends MultiChildRenderObjectWidget {
  const _StepLabels({
    required this.markerExtent,
    required this.textDirection,
    required super.children,
  });

  final double markerExtent;
  final TextDirection textDirection;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderStepLabels(markerExtent, textDirection);

  @override
  void updateRenderObject(
    BuildContext context,
    covariant _RenderStepLabels renderObject,
  ) => renderObject
    ..markerExtent = markerExtent
    ..textDirection = textDirection;
}

class _StepLabelsParentData extends ContainerBoxParentData<RenderBox> {}

class _RenderStepLabels extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _StepLabelsParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _StepLabelsParentData> {
  _RenderStepLabels(this._markerExtent, this._textDirection);

  /// The least room between two names.
  static const double _gap = ExpressiveSpacing.s8;

  double _markerExtent;
  set markerExtent(double value) {
    if (value == _markerExtent) return;
    _markerExtent = value;
    markNeedsLayout();
  }

  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    if (value == _textDirection) return;
    _textDirection = value;
    markNeedsLayout();
  }

  double _scale = 1;

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _StepLabelsParentData) {
      child.parentData = _StepLabelsParentData();
    }
  }

  /// The names' starts from the start edge at [scale], or null when two
  /// would meet.
  List<double>? _starts(List<double> widths, double width, double scale) {
    final n = widths.length;
    final starts = <double>[];
    for (var i = 0; i < n; i++) {
      final centre = n == 1
          ? width / 2
          : _markerExtent / 2 + i * (width - _markerExtent) / (n - 1);
      final w = widths[i] * scale;
      final x = (centre - w / 2)
          .clamp(0.0, math.max(0.0, width - w))
          .toDouble();
      if (i > 0 && x < starts.last + widths[i - 1] * scale + _gap - 0.01) {
        return null;
      }
      starts.add(x);
    }
    return starts;
  }

  /// The largest scale at most 1 at which the names stand apart.
  double _fit(List<double> widths, double width) {
    if (_starts(widths, width, 1) != null) return 1;
    var low = 0.0;
    var high = 1.0;
    for (var k = 0; k < 16; k++) {
      final mid = (low + high) / 2;
      if (_starts(widths, width, mid) != null) {
        low = mid;
      } else {
        high = mid;
      }
    }
    return low;
  }

  Size _measure(
    BoxConstraints constraints,
    Size Function(RenderBox child) sizeOf,
    void Function(List<double> starts, List<double> widths, double scale)?
    place,
  ) {
    final sizes = [for (final child in getChildrenAsList()) sizeOf(child)];
    final width = constraints.maxWidth.isFinite
        ? constraints.maxWidth
        : sizes.fold<double>(0, (a, s) => a + s.width + _gap);
    final widths = [for (final s in sizes) s.width];
    final scale = _fit(widths, width);
    final starts =
        _starts(widths, width, scale) ??
        [for (var i = 0; i < widths.length; i++) 0.0];
    place?.call(starts, widths, scale);
    final height = sizes.fold<double>(0, (h, s) => math.max(h, s.height));
    return constraints.constrain(Size(width, height * scale));
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) => _measure(
    constraints,
    (child) => child.getDryLayout(const BoxConstraints()),
    null,
  );

  @override
  void performLayout() {
    size = _measure(
      constraints,
      (child) {
        child.layout(const BoxConstraints(), parentUsesSize: true);
        return child.size;
      },
      (starts, widths, scale) {
        _scale = scale;
        final children = getChildrenAsList();
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : widths.fold<double>(0, (a, w) => a + w + _gap);
        for (var i = 0; i < children.length; i++) {
          final w = widths[i] * scale;
          final x = _textDirection == TextDirection.rtl
              ? width - starts[i] - w
              : starts[i];
          (children[i].parentData! as _StepLabelsParentData).offset = Offset(
            x,
            0,
          );
        }
      },
    );
  }

  @override
  double computeMinIntrinsicWidth(double height) => 0;

  @override
  double computeMaxIntrinsicWidth(double height) => getChildrenAsList()
      .fold<double>(0, (a, c) => a + c.getMaxIntrinsicWidth(height) + _gap);

  @override
  double computeMinIntrinsicHeight(double width) => getChildrenAsList()
      .fold<double>(0, (h, c) => math.max(h, c.getMinIntrinsicHeight(width)));

  @override
  double computeMaxIntrinsicHeight(double width) =>
      computeMinIntrinsicHeight(width);

  @override
  void paint(PaintingContext context, Offset offset) {
    var child = firstChild;
    while (child != null) {
      final data = child.parentData! as _StepLabelsParentData;
      if (_scale == 1) {
        context.paintChild(child, offset + data.offset);
      } else {
        final at = offset + data.offset;
        final painted = child;
        context.pushTransform(
          needsCompositing,
          at,
          Matrix4.diagonal3Values(_scale, _scale, 1),
          (context, offset) => context.paintChild(painted, offset),
        );
      }
      child = data.nextSibling;
    }
  }

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) {
    final data = child.parentData! as _StepLabelsParentData;
    transform.multiply(
      Matrix4.translationValues(data.offset.dx, data.offset.dy, 0)
        ..scaleByDouble(_scale, _scale, 1, 1),
    );
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      false;
}

/// One numbered marker: done (active, a check), current (active, its
/// number) or to come (the track's colour, its number).
class _StepMarker extends StatelessWidget {
  const _StepMarker({
    required this.index,
    required this.current,
    required this.style,
  });

  final int index;
  final int current;
  final ExpressiveComponentThemeData style;

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    final reached = index <= current;
    final states = <WidgetState>{if (reached) WidgetState.selected};
    final fill =
        style.backgroundColor?.resolve(states) ??
        (reached
            ? t.colors.role(ProgressIndicatorTokens.activeIndicatorColor)
            : t.colors.role(ProgressIndicatorTokens.trackColor));
    final ink =
        style.foregroundColor?.resolve(states) ??
        (reached ? t.colors.onPrimary : t.colors.onSecondaryContainer);
    return ExpressiveSpringColor(
      value: fill,
      motion: ExpressiveMotionKey.defaultEffects,
      builder: (context, color, _) => ExpressiveSurface(
        componentStyle: style,
        states: states,
        shape: const CircleBorder(),
        color: color,
        child: SizedBox.square(
          dimension: _stepExtent(t, style, states),
          child: Center(
            child: index < current
                ? ExpressiveIcon(
                    ExpressiveSymbols.check,
                    size:
                        style.iconSize?.resolve(states) ??
                        ExpressiveSpacing.s16,
                    color: ink,
                  )
                : Text(
                    '${index + 1}',
                    textScaler: TextScaler.noScaling,
                    style: t.type.labelMedium
                        .merge(style.textStyle?.resolve(states))
                        .copyWith(color: ink),
                  ),
          ),
        ),
      ),
    );
  }
}

// The numbered mark grows with density and an explicitly sized glyph.
double _stepExtent(
  ExpressiveThemeData theme,
  ExpressiveComponentThemeData style,
  Set<WidgetState> states,
) => math.max(
  theme.density.width(ExpressiveSpacing.s24, floor: ExpressiveSpacing.s24),
  style.iconSize?.resolve(states) ?? 0,
);
