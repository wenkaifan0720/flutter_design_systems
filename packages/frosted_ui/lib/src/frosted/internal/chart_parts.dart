import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import '../chrome_metrics.dart';
import '../theme.dart';

/// The gutter a chart keeps at its end for its grid's values (the source's
/// `G`): 40 (48 from 1024) on the trails and the goal, 36 (40) on the
/// spend chart, the bars and the steps. Plumbing of the charts.
enum FrostedChartGutter {
  /// The trails' and the goal's gutter.
  trail,

  /// The spend chart's, the bars' and the steps' gutter.
  bars;

  /// The gutter's width on a phone or ([wide]) the desktop.
  double of(bool wide) => switch (this) {
    trail =>
      wide
          ? FrostedChromeMetrics.chartLabelsEndWide
          : FrostedChromeMetrics.chartLabelsEnd,
    bars =>
      wide
          ? FrostedChromeMetrics.chartLabelsEndGapWide
          : FrostedChromeMetrics.chartLabelsEndGap,
  };
}

/// A Fritsch-Carlson monotone cubic through [pts] (the source's
/// `monotone`): a C segment between each pair, the tangents damped so the
/// curve never overshoots a point. Plumbing of the charts.
Path frostedMonotonePath(List<Offset> pts) {
  final n = pts.length;
  final path = Path();
  if (n == 0) return path;
  path.moveTo(pts.first.dx, pts.first.dy);
  if (n < 2) return path;
  final d = List<double>.generate(
    n - 1,
    (i) => (pts[i + 1].dy - pts[i].dy) / (pts[i + 1].dx - pts[i].dx),
  );
  final m = List<double>.filled(n, 0);
  m[0] = d[0];
  m[n - 1] = d[n - 2];
  for (var i = 1; i < n - 1; i++) {
    m[i] = d[i - 1] * d[i] <= 0 ? 0 : (d[i - 1] + d[i]) / 2;
  }
  for (var i = 0; i < n - 1; i++) {
    if (d[i] == 0) {
      m[i] = 0;
      m[i + 1] = 0;
      continue;
    }
    final a = m[i] / d[i];
    final b = m[i + 1] / d[i];
    final h = a * a + b * b;
    if (h > 9) {
      final t = 3 / math.sqrt(h);
      m[i] = t * a * d[i];
      m[i + 1] = t * b * d[i];
    }
  }
  for (var i = 0; i < n - 1; i++) {
    final dx = (pts[i + 1].dx - pts[i].dx) / 3;
    path.cubicTo(
      pts[i].dx + dx,
      pts[i].dy + m[i] * dx,
      pts[i + 1].dx - dx,
      pts[i + 1].dy - m[i + 1] * dx,
      pts[i + 1].dx,
      pts[i + 1].dy,
    );
  }
  return path;
}

/// A polyline through [pts]. Plumbing of the charts.
Path frostedPolyline(List<Offset> pts) {
  final path = Path();
  if (pts.isEmpty) return path;
  path.moveTo(pts.first.dx, pts.first.dy);
  for (final p in pts.skip(1)) {
    path.lineTo(p.dx, p.dy);
  }
  return path;
}

/// [path] cut into dashes (SVG's `stroke-dasharray`): [pattern] is the
/// lengths on and off in turn; each dash is its own subpath, so a round
/// cap ends every dash. Plumbing of the charts.
Path frostedDashes(Path path, List<double> pattern) {
  assert(pattern.isNotEmpty && pattern.every((p) => p > 0), 'dashes');
  final out = Path();
  for (final metric in path.computeMetrics()) {
    var at = 0.0;
    var i = 0;
    while (at < metric.length) {
      final len = pattern[i % pattern.length];
      if (i.isEven) {
        out.addPath(
          metric.extractPath(at, math.min(at + len, metric.length)),
          Offset.zero,
        );
      }
      at += len;
      i++;
    }
  }
  return out;
}

/// Paints a hairline across [width] at each of [ys] (the source's
/// `_hgrid`: 1 wide in the grid ink). Plumbing of the charts.
void frostedPaintGrid(Canvas canvas, List<double> ys, double width, Color ink) {
  final paint = Paint()
    ..color = ink
    ..strokeWidth = 1
    ..style = PaintingStyle.stroke;
  for (final y in ys) {
    canvas.drawLine(Offset(0, y), Offset(width, y), paint);
  }
}

/// The dot that ends a line (the source's `_end`): a halo 20 across in the
/// end ink at 14%, then a ring 9 across in the page ground stroked 2.5 in
/// the end ink. [halo] false draws the ring alone (a projection's end, in
/// its goal's [ink]). Plumbing of the charts.
void frostedPaintEndDot(
  Canvas canvas,
  Offset at,
  FrostedChartInks inks, {
  Color? ink,
  bool halo = true,
}) {
  final dot = ink ?? inks.endDot;
  if (halo) {
    canvas.drawCircle(at, 10, Paint()..color = dot.withValues(alpha: 0.14));
  }
  canvas.drawCircle(at, 4.5, Paint()..color = inks.endRing);
  canvas.drawCircle(
    at,
    4.5,
    Paint()
      ..color = dot
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5,
  );
}

/// The line's spectrum from [from] to [to] (the source's three stops at 0,
/// .55 and 1 in user space). Plumbing of the charts.
ui.Shader frostedSpectrum(Offset from, Offset to, List<Color> line) =>
    ui.Gradient.linear(
      from,
      to,
      line,
      line.length == 3 ? const <double>[0, 0.55, 1] : null,
    );

/// The line's stroke: 2.5 wide, round capped and joined. Plumbing of the
/// charts.
Paint frostedLinePaint(ui.Shader shader) => Paint()
  ..shader = shader
  ..style = PaintingStyle.stroke
  ..strokeWidth = 2.5
  ..strokeCap = StrokeCap.round
  ..strokeJoin = StrokeJoin.round;

/// A dashed rule's stroke [width] wide in [ink], round capped. Plumbing of
/// the charts.
Paint frostedRulePaint(Color ink, double width) => Paint()
  ..color = ink
  ..style = PaintingStyle.stroke
  ..strokeWidth = width
  ..strokeCap = StrokeCap.round;

/// The light under a line (the source's `_area_fill`): the area ink from
/// [top] fading to [to] (nothing, by default) at [foot]. Plumbing of the
/// charts.
Paint frostedAreaPaint(
  double top,
  double foot,
  FrostedChartInks inks, {
  Color? to,
}) => Paint()
  ..shader = ui.Gradient.linear(Offset(0, top), Offset(0, foot), [
    inks.areaFrom,
    to ?? inks.areaTo,
  ]);

/// A bar's light (the source's vertical `_grad`): [top] in the hue's
/// second stop down to [foot] in its first, at [opacity]. Plumbing of the
/// charts.
Paint frostedBarPaint(
  FrostedHue hue,
  double top,
  double foot, {
  double opacity = 1,
}) => Paint()
  ..shader = ui.Gradient.linear(Offset(0, top), Offset(0, foot), [
    hue.b.withValues(alpha: hue.b.a * opacity),
    hue.a.withValues(alpha: hue.a.a * opacity),
  ]);

/// The grid for [vals] (the source's `value_range`): lines on the nice
/// step (1, 2, 2.5 or 5 times a power of ten) that wastes the least of the
/// plot, two to [lines] + 1 of them; the floor a fifth of the span under
/// the lowest line, or zero when [zero] (then the zero line is left out of
/// [grid]); a top within 8% of a step of the highest value gets half a step
/// of headroom for its end dot. Plumbing of the charts.
({double lo, double hi, List<double> grid, double step}) frostedValueRange(
  List<num> vals, {
  int lines = 4,
  bool zero = false,
}) {
  var hiV = double.negativeInfinity;
  var loV = double.infinity;
  for (final v in vals) {
    hiV = math.max(hiV, v.toDouble());
    loV = math.min(loV, v.toDouble());
  }
  if (vals.isEmpty) {
    hiV = 1;
    loV = 0;
  }
  if (zero) loV = 0;
  double? best;
  var step = 1.0;
  var hi = 0.0;
  var g0 = 0.0;
  for (var e = -1; e <= 5; e++) {
    for (final m in const <double>[1, 2, 2.5, 5]) {
      final st = m * math.pow(10, e).toDouble();
      final top = (hiV / st - 1e-9).ceil() * st;
      final floor = zero ? 0.0 : (loV / st + 1e-9).floor() * st;
      final n = ((top - floor) / st).round();
      if (n < 2 || n > lines + 1) continue;
      final score = ((top - hiV) + (loV - floor)) / (top - floor);
      if (best == null || score < best - 1e-9) {
        best = score;
        step = st;
        hi = top;
        g0 = floor;
      }
    }
  }
  if (best == null) {
    // Nothing spans two lines (every value the same): a step of the
    // value's own order, two lines up from its floor.
    final size = math.max(hiV.abs(), 1.0);
    step = math.pow(10, (math.log(size) / math.ln10).floor()).toDouble();
    g0 = zero ? 0 : (loV / step).floor() * step;
    hi = g0 + 2 * step;
  }
  final count = ((hi - g0) / step).round();
  final grid = <double>[for (var i = 0; i <= count; i++) g0 + i * step];
  if (hi - hiV < step * 0.08) hi += step * 0.5;
  if (zero) {
    return (
      lo: 0,
      hi: hi,
      grid: [
        for (final g in grid)
          if (g > 0) g,
      ],
      step: step,
    );
  }
  return (lo: g0 - (grid.last - g0) * 0.2, hi: hi, grid: grid, step: step);
}

/// A grid value as the source's `dollars_short` prints it: "$7.5k",
/// "$50k", "$75", "$0". Plumbing of the charts.
String frostedDollarsShort(double g) {
  String plain(double v) {
    final r = v.roundToDouble();
    if ((v - r).abs() < 1e-9) return r.toInt().toString();
    var s = v.toStringAsFixed(2);
    while (s.endsWith('0')) {
      s = s.substring(0, s.length - 1);
    }
    return s;
  }

  return g >= 1000 ? '\$${plain(g / 1000)}k' : '\$${plain(g)}';
}

/// The centre of slot [i] of [n] across [width] (a day's bar, a month's
/// column). Plumbing of the charts.
double frostedSlot(int i, int n, double width) => (i + 0.5) / n * width;

/// Where a chart's word stands against its point, as the source's CSS
/// places each one. Plumbing of the charts.
enum FrostedLabelAnchor {
  /// A gridline's value (`.y-lbl`): its right edge at the point, centred
  /// on the line.
  gridEnd,

  /// A rule's name (`.b-lbl`): its left edge at the point, its foot 4 over
  /// the rule.
  ruleStart,

  /// A note at its point (`.a-lbl`): its top left corner there.
  at,

  /// A note over a cliff (`.mk.mk-up`): 6 in from the point, its foot 5
  /// over it.
  noteUp,

  /// A note under a cliff (`.mk.mk-dn`): 6 in from the point, its head 5
  /// under it.
  noteDown,

  /// A step's name (`.mk-step`): 8 in from the point, centred on it.
  noteStep,

  /// The end of a projection, over it (`.mk-end.mk-up`): its right edge at
  /// the point, its foot 10 over.
  endUp,

  /// The end of a projection, under it (`.mk-end.mk-dn`): its right edge at
  /// the point, its head 10 under, dropped by the dashes' rise over its own
  /// width so it clears them.
  endDown,

  /// A bar's value (`.bar-v`): centred on the point, its foot 6 over.
  barValue,

  /// The latest bar's value (`.bar-v--end`): its right edge at the point,
  /// its foot 6 over.
  barValueEnd,

  /// An axis word centred under its point (`.x-days .c`).
  centre,

  /// An axis word starting at its point (the first).
  start,

  /// An axis word ending at its point (`.x-days .r`).
  end,
}

/// A word on a chart at a point of its plot: a gridline's value, a note,
/// an axis word. Goes in the plot's [Stack]. [slope] is the rise per unit
/// of width of the dashes under an [FrostedLabelAnchor.endDown] label.
/// Plumbing of the charts.
class FrostedChartLabel extends StatelessWidget {
  /// Creates a [FrostedChartLabel].
  const FrostedChartLabel({
    required this.span,
    required this.at,
    required this.anchor,
    required this.style,
    this.slope = 0,
    this.fixed = false,
    super.key,
  });

  /// The words.
  final InlineSpan span;

  /// Where they stand.
  final Offset at;

  /// Which point of the words stands at [at].
  final FrostedLabelAnchor anchor;

  /// The words' style.
  final TextStyle style;

  /// The line's slope where the words stand, so they lift clear of it.
  final double slope;

  /// In a box of a fixed height (an axis row): the word keeps its size.
  final bool fixed;

  @override
  Widget build(BuildContext context) => Positioned.fill(
    child: CustomSingleChildLayout(
      delegate: _AnchorLayout(at, anchor, slope),
      // Placed by the plot's left-to-right geometry, and a figure's sign
      // stays before it ("+$73.42", not "$73.42+" in a right-to-left page).
      child: Text.rich(
        span,
        maxLines: 1,
        softWrap: false,
        style: style,
        textDirection: TextDirection.ltr,
        textScaler: fixed ? TextScaler.noScaling : null,
      ),
    ),
  );
}

class _AnchorLayout extends SingleChildLayoutDelegate {
  const _AnchorLayout(this.at, this.anchor, this.slope);

  final Offset at;
  final FrostedLabelAnchor anchor;
  final double slope;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      const BoxConstraints();

  @override
  Offset getPositionForChild(Size size, Size child) {
    final w = child.width;
    final h = child.height;
    const inset = FrostedChromeMetrics.chartNoteInset;
    const gap = FrostedChromeMetrics.chartNoteGap;
    const endGap = FrostedChromeMetrics.chartNoteEndGap;
    const value = FrostedChromeMetrics.chartBarValueGap;
    return switch (anchor) {
      FrostedLabelAnchor.gridEnd => Offset(at.dx - w, at.dy - h / 2),
      FrostedLabelAnchor.ruleStart => Offset(at.dx, at.dy - h - 4),
      FrostedLabelAnchor.at => at,
      FrostedLabelAnchor.noteUp => Offset(at.dx + inset, at.dy - h - gap),
      FrostedLabelAnchor.noteDown => Offset(at.dx + inset, at.dy + gap),
      FrostedLabelAnchor.noteStep => Offset(
        at.dx + FrostedChromeMetrics.chartNoteStepInset,
        at.dy - h / 2,
      ),
      FrostedLabelAnchor.endUp => Offset(at.dx - w, at.dy - h - endGap),
      FrostedLabelAnchor.endDown => Offset(
        at.dx - w,
        at.dy + endGap + math.max(0, slope * w),
      ),
      FrostedLabelAnchor.barValue => Offset(at.dx - w / 2, at.dy - h - value),
      FrostedLabelAnchor.barValueEnd => Offset(at.dx - w, at.dy - h - value),
      FrostedLabelAnchor.centre => Offset(at.dx - w / 2, at.dy),
      FrostedLabelAnchor.start => at,
      FrostedLabelAnchor.end => Offset(at.dx - w, at.dy),
    };
  }

  @override
  bool shouldRelayout(_AnchorLayout old) =>
      old.at != at || old.anchor != anchor || old.slope != slope;
}

/// One word of a chart's day axis: where it stands as a fraction of the
/// plot's width, what it says, whether it is now (in the page ink), and how
/// it hangs on its point. Plumbing of the charts.
@immutable
class FrostedAxisWord {
  /// Creates a [FrostedAxisWord].
  const FrostedAxisWord(
    this.x,
    this.label, {
    this.current = false,
    this.anchor = FrostedLabelAnchor.centre,
  });

  /// Where across the chart it stands.
  final double x;

  /// The word.
  final String label;

  /// Whether it names now (the page ink).
  final bool current;

  /// Which point of the word stands at [x].
  final FrostedLabelAnchor anchor;
}

/// The room a chart's axis words take under its plot past their own 8
/// ([FrostedChromeMetrics.chartLabelsGap]): [extra] more where the axis is
/// one item of a column with a gap, as in a record's chart (`.rec-chart`,
/// `.cat-chart`: the gap of 10 over the axis's own margin), none where the
/// chart stands alone. Plumbing of the charts.
class FrostedChartAxisRoom extends InheritedWidget {
  /// Creates a [FrostedChartAxisRoom].
  const FrostedChartAxisRoom({
    required this.extra,
    required super.child,
    super.key,
  });

  /// Room past the axis's own.
  final double extra;

  /// The [extra] the nearest room gives, 0 outside one.
  static double of(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<FrostedChartAxisRoom>()
          ?.extra ??
      0;

  @override
  bool updateShouldNotify(FrostedChartAxisRoom oldWidget) =>
      oldWidget.extra != extra;
}

/// A chart's row of day words (`.x-days`): 16 tall, 8 under the plot (and
/// a [FrostedChartAxisRoom]'s extra), its
/// end inset by [endInset] (the plot's gutter), each word in 12/1 in the
/// third ink at its fraction of the row, centred (`.c`), flush at the
/// start (the first) or the end (`.r`); the current one in the page ink,
/// semibold (`.now`). Plumbing of the charts.
class FrostedDaysAxis extends StatelessWidget {
  /// Creates a [FrostedDaysAxis].
  const FrostedDaysAxis({
    required this.words,
    required this.endInset,
    super.key,
  });

  /// The days named, in order.
  final List<FrostedAxisWord> words;

  /// The room kept at the axis's end (the gutter).
  final double endInset;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    // .x-days span { font: 500 12px/1; color: var(--ink-3) }
    final style = t.textTheme.labelSmall.c(t.colorScheme.textTertiary);
    final now = t.textTheme.labelSmall.semibold.c(t.colorScheme.textPrimary);
    // Left to right in any language: the plot it names is painted so, and
    // a mirrored axis would put each day under another day's figure.
    return frostedChartAxisDirection(
      Padding(
        padding: EdgeInsetsDirectional.only(
          top:
              FrostedChromeMetrics.chartLabelsGap +
              FrostedChartAxisRoom.of(context),
          end: endInset,
        ),
        child: SizedBox(
          height: FrostedChromeMetrics.chartLabels,
          child: LayoutBuilder(
            builder: (context, box) => Stack(
              clipBehavior: Clip.none,
              children: [
                for (final w in words)
                  FrostedChartLabel(
                    span: TextSpan(text: w.label),
                    at: Offset(w.x * box.maxWidth, 0),
                    anchor: w.anchor,
                    style: w.current ? now : style,
                    fixed: true,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// [axis] laid out left to right whatever the page's direction: a chart's
/// plot is painted left to right, so its axes are too, and each word stays
/// under its own figure. Plumbing of the charts.
Widget frostedChartAxisDirection(Widget axis) =>
    Directionality(textDirection: TextDirection.ltr, child: axis);

/// A chart's row of month words (`.x12`): a grid of one column per month,
/// 8 under the plot (and a [FrostedChartAxisRoom]'s extra), its end inset by
/// [endInset] (the plot's gutter), each word centred in 12/1 in the third ink; on a phone each month's initial,
/// from 1024 its short name (`<b class="desk">`); the [current] month in
/// the page ink, semibold (`.now`). Plumbing of the charts.
class FrostedMonthsAxis extends StatelessWidget {
  /// Creates a [FrostedMonthsAxis].
  const FrostedMonthsAxis({
    required this.months,
    required this.endInset,
    this.current,
    super.key,
  });

  /// The months' names, in order.
  final List<String> months;

  /// The room kept at the axis's end (the gutter).
  final double endInset;

  /// The month that is now, from 0.
  final int? current;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    final wide = FrostedBreakpoints.isWide(context);
    final style = t.textTheme.labelSmall.c(t.colorScheme.textTertiary);
    final now = t.textTheme.labelSmall.semibold.c(t.colorScheme.textPrimary);
    final lit = current ?? months.length - 1;
    // Left to right, as the plot above it is painted.
    return frostedChartAxisDirection(
      Padding(
        padding: EdgeInsetsDirectional.only(
          top:
              FrostedChromeMetrics.chartLabelsGap +
              FrostedChartAxisRoom.of(context),
          end: endInset,
        ),
        child: Row(
          children: [
            for (final (i, m) in months.indexed)
              Expanded(
                child: Text(
                  wide || m.isEmpty ? m : m.characters.first,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.clip,
                  style: i == lit ? now : style,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
