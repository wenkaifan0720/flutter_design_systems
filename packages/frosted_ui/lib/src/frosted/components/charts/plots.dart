import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/widgets.dart';

import '../../internal/chart_parts.dart';
import '../../localizations.dart';
import '../../theme.dart';

/// One named run of values for a [FrostedLineChart], [FrostedAreaChart] or
/// [FrostedBarChart]: its [label] (the legend and what a screen reader
/// names), its [values] in point order (a null is a gap, breaking a line),
/// and its [color] (null takes the chart's own: the look's spectrum for a
/// lone line, the category hues round the wheel for several).
@immutable
class FrostedChartSeries {
  /// A series named [label].
  const FrostedChartSeries(this.label, this.values, {this.color});

  /// Its name.
  final String label;

  /// Its values, first to last; null is a gap.
  final List<double?> values;

  /// Its ink; null for the chart's own.
  final Color? color;

  @override
  bool operator ==(Object other) =>
      other is FrostedChartSeries &&
      other.label == label &&
      other.color == color &&
      listEquals(other.values, values);

  @override
  int get hashCode => Object.hash(label, color, Object.hashAll(values));
}

/// A value as a chart's axis prints it: 950, 1.2k, 3.4M.
String _short(double v) {
  String trim(double x) {
    var s = x.toStringAsFixed(x.abs() >= 100 ? 0 : 1);
    if (s.contains('.')) s = s.replaceFirst(RegExp(r'\.?0+$'), '');
    return s;
  }

  final a = v.abs();
  if (a >= 1e9) return '${trim(v / 1e9)}B';
  if (a >= 1e6) return '${trim(v / 1e6)}M';
  if (a >= 1e3) return '${trim(v / 1e3)}k';
  return trim(v);
}

String _describe(
  FrostedLocalizations words,
  List<FrostedChartSeries> series,
  String Function(double) format,
) {
  final parts = <String>[];
  for (final s in series) {
    final vs = s.values.whereType<double>().toList();
    if (vs.isEmpty) {
      parts.add('${s.label}: ${words.noData}');
      continue;
    }
    parts.add(
      words.seriesSummary(
        name: s.label,
        first: format(vs.first),
        last: format(vs.last),
        high: format(vs.reduce(math.max)),
        low: format(vs.reduce(math.min)),
      ),
    );
  }
  return parts.join('; ');
}

enum _Kind { line, area, bar }

/// A run of values over time or order as a line (Material's place has no
/// chart; this is the shape every charting library draws): gridlines in
/// the grid ink on a nice step, their values in the quiet note at the end,
/// the [labels] along the foot (as many as fit), each series a smooth line
/// 2.5 wide that never overshoots its points. A lone series runs in the
/// look's spectrum with the light under it fading to nothing and the end
/// dot's halo; several take the category hues, with a legend under the
/// plot. [current] marks a point with a dashed rule and a dot on each line.
/// Read aloud as [label] with each series' first, last, high and low.
///
/// ```dart
/// FrostedLineChart(label: 'Visitors', labels: const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'], series: const [FrostedChartSeries('This week', [120, 180, 150, 210, 240])])
/// ```
class FrostedLineChart extends StatelessWidget {
  /// A line chart of [series].
  const FrostedLineChart({
    required this.label,
    required this.series,
    this.labels = const <String>[],
    this.format,
    this.current,
    this.curved = true,
    this.height = 200,
    super.key,
  });

  /// What a screen reader calls the chart.
  final String label;

  /// The lines, in legend order.
  final List<FrostedChartSeries> series;

  /// The words along the foot, one per point.
  final List<String> labels;

  /// How a value is printed on the axis and read aloud; null prints 1.2k.
  final String Function(double value)? format;

  /// The index of the point that is now; null marks none.
  final int? current;

  /// Whether the lines bend smoothly through their points (else straight).
  final bool curved;

  /// The plot's height, the legend aside.
  final double height;

  @override
  Widget build(BuildContext context) => _XYChart(
    kind: _Kind.line,
    label: label,
    series: series,
    labels: labels,
    format: format,
    current: current,
    curved: curved,
    height: height,
  );
}

/// A [FrostedLineChart] with the light under each line filled to the floor:
/// a share of a whole that grows or shrinks. The floor is zero; a lone
/// series' area is the look's spectrum fading to nothing, several series'
/// each their hue at a fifth fading out, drawn in legend order.
///
/// ```dart
/// FrostedAreaChart(label: 'Storage used', labels: months, series: const [FrostedChartSeries('Photos', [2, 3, 3.5, 5, 6.2])], format: (v) => '${v.toStringAsFixed(1)} GB')
/// ```
class FrostedAreaChart extends StatelessWidget {
  /// An area chart of [series].
  const FrostedAreaChart({
    required this.label,
    required this.series,
    this.labels = const <String>[],
    this.format,
    this.current,
    this.curved = true,
    this.height = 200,
    super.key,
  });

  /// What a screen reader calls the chart.
  final String label;

  /// The areas, in legend order.
  final List<FrostedChartSeries> series;

  /// The words along the foot, one per point.
  final List<String> labels;

  /// How a value is printed on the axis and read aloud; null prints 1.2k.
  final String Function(double value)? format;

  /// The index of the point that is now; null marks none.
  final int? current;

  /// Whether the edges bend smoothly through their points.
  final bool curved;

  /// The plot's height, the legend aside.
  final double height;

  @override
  Widget build(BuildContext context) => _XYChart(
    kind: _Kind.area,
    label: label,
    series: series,
    labels: labels,
    format: format,
    current: current,
    curved: curved,
    height: height,
  );
}

/// Values side by side as bars from zero: one slot per point, each
/// series' bar in its hue's light (the top's stop falling to the foot's),
/// its top corners round, the bars of a slot touching with a hairline's
/// gap. A [current] slot stands in full light and the others dim to under
/// half, as the look's own spend bars do. Gridlines, the foot's [labels]
/// and the legend as [FrostedLineChart] sets them.
///
/// ```dart
/// FrostedBarChart(label: 'Steps', labels: const ['M', 'T', 'W', 'T', 'F'], current: 4, series: const [FrostedChartSeries('Steps', [6200, 8400, 7100, 9900, 4300])])
/// ```
class FrostedBarChart extends StatelessWidget {
  /// A bar chart of [series].
  const FrostedBarChart({
    required this.label,
    required this.series,
    this.labels = const <String>[],
    this.format,
    this.current,
    this.height = 200,
    super.key,
  });

  /// What a screen reader calls the chart.
  final String label;

  /// The bars of each slot, in legend order.
  final List<FrostedChartSeries> series;

  /// The words along the foot, one per slot.
  final List<String> labels;

  /// How a value is printed on the axis and read aloud; null prints 1.2k.
  final String Function(double value)? format;

  /// The slot that is now, standing in full light; null lights them all.
  final int? current;

  /// The plot's height, the legend aside.
  final double height;

  @override
  Widget build(BuildContext context) => _XYChart(
    kind: _Kind.bar,
    label: label,
    series: series,
    labels: labels,
    format: format,
    current: current,
    curved: false,
    height: height,
  );
}

class _XYChart extends StatelessWidget {
  const _XYChart({
    required this.kind,
    required this.label,
    required this.series,
    required this.labels,
    required this.format,
    required this.current,
    required this.curved,
    required this.height,
  });

  final _Kind kind;
  final String label;
  final List<FrostedChartSeries> series;
  final List<String> labels;
  final String Function(double value)? format;
  final int? current;
  final bool curved;
  final double height;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    final words = FrostedLocalizations.of(context);
    final fmt = format ?? _short;
    final lone = series.length == 1;
    final hues = <FrostedHue>[
      for (var i = 0; i < series.length; i++)
        lone && kind == _Kind.bar ? t.hues.iris : t.hue(i),
    ];
    // A series in its hue's ink by day; by night in its pastel mark, as the
    // ink is lifted toward white for words there and every series read the
    // same near-white (self-review round 1).
    Color seriesInk(FrostedHue hue) => t.isDark ? hue.a : hue.ink;
    final inks = <Color?>[
      for (final (i, s) in series.indexed)
        s.color ?? (lone && kind != _Kind.bar ? null : seriesInk(hues[i])),
    ];
    final plot = LayoutBuilder(
      builder: (context, box) => CustomPaint(
        size: Size(box.maxWidth, height),
        painter: _XYPainter(
          kind: kind,
          series: series,
          labels: labels,
          inks: inks,
          hues: hues,
          current: current,
          curved: curved,
          format: fmt,
          chart: t.charts,
          note: t.textTheme.bodySmall,
          now: t.colorScheme.textPrimary,
        ),
      ),
    );
    return Semantics(
      container: true,
      label: label,
      value: series.isEmpty ? words.noData : _describe(words, series, fmt),
      child: ExcludeSemantics(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: FrostedSpacing.s12,
          children: [
            plot,
            if (!lone && series.isNotEmpty)
              _Legend(
                entries: [
                  for (final (i, s) in series.indexed)
                    (s.label, inks[i] ?? seriesInk(hues[i]), null),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// The chart's key: a dot of each series' ink before its name; a name
/// wider than the key wraps.
class _Legend extends StatelessWidget {
  const _Legend({required this.entries});

  final List<(String, Color, String?)> entries;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    return Wrap(
      spacing: FrostedSpacing.s16,
      runSpacing: FrostedSpacing.s6,
      children: [
        for (final (name, ink, end) in entries)
          Row(
            mainAxisSize: MainAxisSize.min,
            spacing: FrostedSpacing.s6,
            children: [
              SizedBox.square(
                dimension: 8,
                child: DecoratedBox(
                  decoration: BoxDecoration(color: ink, shape: BoxShape.circle),
                ),
              ),
              // A name wider than the key's room wraps under itself (at
              // large text under a pie); its figure stays whole beside it.
              Flexible(
                child: Text(
                  name,
                  style: t.textTheme.labelMedium.c(t.colorScheme.textSecondary),
                ),
              ),
              if (end != null)
                Text(end, style: t.textTheme.labelMedium.tabular),
            ],
          ),
      ],
    );
  }
}

class _XYPainter extends CustomPainter {
  _XYPainter({
    required this.kind,
    required this.series,
    required this.labels,
    required this.inks,
    required this.hues,
    required this.current,
    required this.curved,
    required this.format,
    required this.chart,
    required this.note,
    required this.now,
  });

  final _Kind kind;
  final List<FrostedChartSeries> series;
  final List<String> labels;
  final List<Color?> inks;
  final List<FrostedHue> hues;
  final int? current;
  final bool curved;
  final String Function(double) format;
  final FrostedChartInks chart;
  final TextStyle note;
  final Color now;

  static const double _gutter = 44;

  // Room past the plot's end for the end dot's ring (4.5 round, stroked
  // 2.5), so it stands clear of the values beside it; it sat on them.
  static const double _endRoom = 6;
  static const double _foot = 22;
  static const double _top = 10;

  TextPainter _text(String s, TextStyle style) => TextPainter(
    text: TextSpan(text: s, style: style),
    textDirection: TextDirection.ltr,
    maxLines: 1,
  )..layout();

  @override
  void paint(Canvas canvas, Size size) {
    final n = series.fold<int>(
      labels.length,
      (m, s) => math.max(m, s.values.length),
    );
    final values = [for (final s in series) ...s.values.whereType<double>()];
    final plot = Rect.fromLTRB(
      0,
      _top,
      math.max(0, size.width - _gutter - _endRoom),
      size.height - (labels.isEmpty ? 0 : _foot),
    );
    final negative = values.any((v) => v < 0);
    final range = frostedValueRange(
      values,
      zero: kind != _Kind.line && !negative,
    );
    final lo = range.lo;
    final hi = range.hi == lo ? lo + 1 : range.hi;
    double y(double v) => plot.bottom - (v - lo) / (hi - lo) * plot.height;
    double x(int i) {
      if (kind == _Kind.bar) return plot.left + frostedSlot(i, n, plot.width);
      if (n <= 1) return plot.center.dx;
      return plot.left + i / (n - 1) * plot.width;
    }

    // Grid, its values at the end, the floor.
    final gridYs = [for (final g in range.grid) y(g)];
    frostedPaintGrid(canvas, gridYs, plot.width, chart.grid);
    if (kind != _Kind.line) {
      frostedPaintGrid(canvas, [y(math.max(lo, 0))], plot.width, chart.grid);
    }
    for (final g in range.grid) {
      final tp = _text(format(g), note);
      tp.paint(canvas, Offset(plot.right + _endRoom + 6, y(g) - tp.height / 2));
    }

    // The foot's words, as many as fit.
    if (labels.isNotEmpty && n > 0) {
      var widest = 0.0;
      final painters = [for (final l in labels) _text(l, note)];
      for (final p in painters) {
        widest = math.max(widest, p.width);
      }
      final fit = math.max(1, (plot.width / (widest + 8)).floor());
      final every = (labels.length / fit).ceil();
      for (var i = 0; i < labels.length && i < n; i += every) {
        final tp = i == current
            ? _text(labels[i], note.copyWith(color: now))
            : painters[i];
        final cx = (x(i) - tp.width / 2).clamp(0.0, size.width - tp.width);
        tp.paint(canvas, Offset(cx, plot.bottom + 6));
      }
    }

    if (n == 0 || values.isEmpty) return;

    if (kind == _Kind.bar) {
      _bars(canvas, plot, n, y, x, lo);
      return;
    }

    // A current point's dashed rule.
    final at = current;
    if (at != null && at >= 0 && at < n) {
      final rule = Path()
        ..moveTo(x(at), plot.top)
        ..lineTo(x(at), plot.bottom);
      canvas.drawPath(
        frostedDashes(rule, const [3, 4]),
        frostedRulePaint(chart.pace, 1.5),
      );
    }

    final floor = y(math.max(lo, 0));
    for (final (si, s) in series.indexed) {
      final segments = <List<Offset>>[[]];
      for (final (i, v) in s.values.indexed) {
        if (v == null) {
          if (segments.last.isNotEmpty) segments.add([]);
        } else {
          segments.last.add(Offset(x(i), y(v)));
        }
      }
      final ink = inks[si];
      final stroke = ink == null
          ? frostedLinePaint(
              frostedSpectrum(
                Offset(plot.left, 0),
                Offset(plot.right, 0),
                chart.line,
              ),
            )
          : (Paint()
              ..color = ink
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.5
              ..strokeCap = StrokeCap.round
              ..strokeJoin = StrokeJoin.round);
      for (final pts in segments) {
        if (pts.isEmpty) continue;
        if (pts.length == 1) {
          canvas.drawCircle(
            pts.first,
            2.5,
            Paint()..color = ink ?? chart.endDot,
          );
          continue;
        }
        final line = curved ? frostedMonotonePath(pts) : frostedPolyline(pts);
        if (kind == _Kind.area || (ink == null && series.length == 1)) {
          final area = Path.from(line)
            ..lineTo(pts.last.dx, floor)
            ..lineTo(pts.first.dx, floor)
            ..close();
          canvas.drawPath(
            area,
            ink == null
                ? frostedAreaPaint(plot.top, floor, chart)
                : (Paint()
                    ..shader = ui.Gradient.linear(
                      Offset(0, plot.top),
                      Offset(0, floor),
                      [
                        ink.withValues(alpha: kind == _Kind.area ? .22 : .14),
                        ink.withValues(alpha: 0),
                      ],
                    )),
          );
        }
        canvas.drawPath(line, stroke);
      }
      // The end, or the current point.
      final mark = at != null && at < s.values.length ? at : null;
      final index = mark ?? s.values.lastIndexWhere((v) => v != null);
      final v = index < 0 ? null : s.values[index];
      if (v != null) {
        frostedPaintEndDot(
          canvas,
          Offset(x(index), y(v)),
          chart,
          ink: ink,
          halo: series.length == 1,
        );
      }
    }
  }

  void _bars(
    Canvas canvas,
    Rect plot,
    int n,
    double Function(double) y,
    double Function(int) x,
    double lo,
  ) {
    final k = series.length;
    final slot = plot.width / n;
    final group = math.min(slot * .7, 20.0 * k + 6);
    const gap = 2.0;
    final bar = math.max(1.0, (group - gap * (k - 1)) / k);
    final zero = y(math.max(lo, 0));
    for (var i = 0; i < n; i++) {
      final lit = current == null || current == i;
      for (final (si, s) in series.indexed) {
        if (i >= s.values.length) continue;
        final v = s.values[i];
        if (v == null) continue;
        final left = x(i) - group / 2 + si * (bar + gap);
        final top = math.min(y(v), zero);
        final foot = math.max(y(v), zero);
        if (foot - top < .5) continue;
        final r = Radius.circular(math.min(4, bar / 2));
        final rect = v >= 0
            ? RRect.fromLTRBAndCorners(
                left,
                top,
                left + bar,
                foot,
                topLeft: r,
                topRight: r,
              )
            : RRect.fromLTRBAndCorners(
                left,
                top,
                left + bar,
                foot,
                bottomLeft: r,
                bottomRight: r,
              );
        final ink = inks[si];
        final paint = ink == null
            ? frostedBarPaint(hues[si], top, foot, opacity: lit ? 1 : .45)
            : (Paint()..color = ink.withValues(alpha: ink.a * (lit ? 1 : .45)));
        canvas.drawRRect(rect, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_XYPainter old) =>
      old.kind != kind ||
      !listEquals(old.series, series) ||
      !listEquals(old.labels, labels) ||
      !listEquals(old.inks, inks) ||
      !listEquals(old.hues, hues) ||
      old.current != current ||
      old.curved != curved ||
      old.chart != chart ||
      old.note != note ||
      old.now != now;
}

// ---------------------------------------------------------------------------
// Pie
// ---------------------------------------------------------------------------

/// One share of a [FrostedPieChart]: its [label], its [value] (any unit;
/// the slices make the whole) and its [color] (null for the category hue
/// of its place).
@immutable
class FrostedPieSlice {
  /// A slice named [label] worth [value].
  const FrostedPieSlice(this.label, this.value, {this.color})
    : assert(value >= 0);

  /// Its name.
  final String label;

  /// Its worth.
  final double value;

  /// Its ink; null for its place's hue.
  final Color? color;

  @override
  bool operator ==(Object other) =>
      other is FrostedPieSlice &&
      other.label == label &&
      other.value == value &&
      other.color == color;

  @override
  int get hashCode => Object.hash(label, value, color);
}

/// Shares of a whole round a ring (a donut, or a full pie when [donut] is
/// false): each slice in its category hue, a hairline of the page between
/// each two, starting at the top and running clockwise; [center] stands in
/// the ring's hole (the total, a word). A legend under it names each slice
/// with its share. Read aloud as [label] with each slice's share.
///
/// ```dart
/// FrostedPieChart(label: 'Time spent', center: Text('38 h'), slices: const [FrostedPieSlice('Focus', 18), FrostedPieSlice('Meetings', 12), FrostedPieSlice('Email', 8)])
/// ```
class FrostedPieChart extends StatelessWidget {
  /// A ring of [slices].
  const FrostedPieChart({
    required this.label,
    required this.slices,
    this.center,
    this.donut = true,
    this.size = 180,
    this.showLegend = true,
    super.key,
  });

  /// What a screen reader calls the chart.
  final String label;

  /// The shares, clockwise from the top.
  final List<FrostedPieSlice> slices;

  /// What stands in the hole.
  final Widget? center;

  /// Whether the middle is open (a donut) or full (a pie).
  final bool donut;

  /// The ring's width and height.
  final double size;

  /// Whether the names and shares stand under the ring.
  final bool showLegend;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    final words = FrostedLocalizations.of(context);
    final total = slices.fold<double>(0, (a, s) => a + s.value);
    final inks = [for (final (i, s) in slices.indexed) s.color ?? t.hue(i).a];
    int pct(double v) => total == 0 ? 0 : (v / total * 100).round();
    final summary = total == 0
        ? words.noData
        : [for (final s in slices) words.sliceShare(s.label, pct(s.value))]
              .join('; ');
    final ring = SizedBox.square(
      dimension: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size.square(size),
            painter: _PiePainter(
              values: [for (final s in slices) s.value],
              inks: inks,
              donut: donut,
              empty: t.charts.grid,
            ),
          ),
          if (center case final center? when donut)
            DefaultTextStyle.merge(
              style: t.textTheme.titleLarge.tabular,
              textAlign: TextAlign.center,
              child: center,
            ),
        ],
      ),
    );
    return Semantics(
      container: true,
      label: label,
      value: summary,
      child: ExcludeSemantics(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: FrostedSpacing.s16,
          children: [
            ring,
            if (showLegend && slices.isNotEmpty)
              // Under the ring and no wider: in a row beside another chart
              // an unbounded key ran on into the next one's.
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: size),
                child: _Legend(
                  entries: [
                    for (final (i, s) in slices.indexed)
                      (s.label, inks[i], '${pct(s.value)}%'),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PiePainter extends CustomPainter {
  _PiePainter({
    required this.values,
    required this.inks,
    required this.donut,
    required this.empty,
  });

  final List<double> values;
  final List<Color> inks;
  final bool donut;
  final Color empty;

  @override
  void paint(Canvas canvas, Size size) {
    final r = math.min(size.width, size.height) / 2;
    final c = size.center(Offset.zero);
    final thick = donut ? r * .28 : r;
    final mid = r - thick / 2;
    final rect = Rect.fromCircle(center: c, radius: mid);
    final total = values.fold<double>(0, (a, v) => a + v);
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = thick;
    if (total <= 0) {
      canvas.drawCircle(c, mid, arc..color = empty);
      return;
    }
    // The slices in a layer of their own, so the gaps between them can be
    // cut through to whatever lies under (law 5: a gap is never painted in
    // the ground's colour; by night the painted surface read as black
    // strokes, self-review round 3).
    canvas.saveLayer(Rect.fromCircle(center: c, radius: r + 1), Paint());
    var start = -math.pi / 2;
    final starts = <double>[];
    for (final (i, v) in values.indexed) {
      final sweep = v / total * 2 * math.pi;
      if (sweep <= 0) continue;
      starts.add(start);
      canvas.drawArc(rect, start, sweep, false, arc..color = inks[i]);
      start += sweep;
    }
    // A 2 px cut between each two slices.
    if (starts.length > 1) {
      final cut = Paint()
        ..blendMode = BlendMode.clear
        ..strokeWidth = 2;
      final inner = r - thick;
      for (final a in starts) {
        final dir = Offset(math.cos(a), math.sin(a));
        canvas.drawLine(c + dir * inner, c + dir * (r + 1), cut);
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_PiePainter old) =>
      !listEquals(old.values, values) ||
      !listEquals(old.inks, inks) ||
      old.donut != donut ||
      old.empty != empty;
}

// ---------------------------------------------------------------------------
// Sparkline
// ---------------------------------------------------------------------------

/// A word-sized line of [values] with no axis (a trend in a row or a tile):
/// the look's spectrum (or [color]) 2 wide, the light under it fading out
/// when [area], and a small dot at its end. Read aloud as [label] with its
/// first, last, high and low.
///
/// ```dart
/// FrostedSparkline(const [3, 5, 4, 7, 6, 9], label: 'Sign-ups this week')
/// ```
class FrostedSparkline extends StatelessWidget {
  /// A sparkline of [values].
  const FrostedSparkline(
    this.values, {
    required this.label,
    this.color,
    this.area = true,
    this.height = 32,
    this.width,
    this.format,
    super.key,
  });

  /// The values, first to last; null is a gap.
  final List<double?> values;

  /// What a screen reader calls it.
  final String label;

  /// Its ink; null for the look's spectrum.
  final Color? color;

  /// Whether the light under it shows.
  final bool area;

  /// Its height.
  final double height;

  /// Its width; null fills what it is given.
  final double? width;

  /// How a value is read aloud; null reads 1.2k.
  final String Function(double value)? format;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    final words = FrostedLocalizations.of(context);
    return Semantics(
      container: true,
      label: label,
      value: _describe(words, [
        FrostedChartSeries(label, values),
      ], format ?? _short).replaceFirst('$label: ', ''),
      child: ExcludeSemantics(
        child: SizedBox(
          width: width,
          height: height,
          child: CustomPaint(
            painter: _SparkPainter(
              values: values,
              ink: color,
              area: area,
              chart: t.charts,
            ),
          ),
        ),
      ),
    );
  }
}

class _SparkPainter extends CustomPainter {
  _SparkPainter({
    required this.values,
    required this.ink,
    required this.area,
    required this.chart,
  });

  final List<double?> values;
  final Color? ink;
  final bool area;
  final FrostedChartInks chart;

  @override
  void paint(Canvas canvas, Size size) {
    final vs = values.whereType<double>();
    if (vs.isEmpty) return;
    var lo = vs.reduce(math.min);
    var hi = vs.reduce(math.max);
    if (hi == lo) {
      lo -= 1;
      hi += 1;
    }
    const pad = 4.0;
    final n = values.length;
    double x(int i) =>
        n <= 1 ? size.width / 2 : pad + i / (n - 1) * (size.width - pad * 2);
    double y(double v) =>
        size.height - pad - (v - lo) / (hi - lo) * (size.height - pad * 2);
    final segments = <List<Offset>>[[]];
    for (final (i, v) in values.indexed) {
      if (v == null) {
        if (segments.last.isNotEmpty) segments.add([]);
      } else {
        segments.last.add(Offset(x(i), y(v)));
      }
    }
    final c = ink;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    if (c == null) {
      stroke.shader = frostedSpectrum(
        Offset.zero,
        Offset(size.width, 0),
        chart.line,
      );
    } else {
      stroke.color = c;
    }
    for (final pts in segments) {
      if (pts.length < 2) continue;
      final line = frostedMonotonePath(pts);
      if (area) {
        final fill = Path.from(line)
          ..lineTo(pts.last.dx, size.height)
          ..lineTo(pts.first.dx, size.height)
          ..close();
        canvas.drawPath(
          fill,
          c == null
              ? frostedAreaPaint(0, size.height, chart)
              : (Paint()
                  ..shader = ui.Gradient.linear(
                    Offset.zero,
                    Offset(0, size.height),
                    [c.withValues(alpha: .18), c.withValues(alpha: 0)],
                  )),
        );
      }
      canvas.drawPath(line, stroke);
    }
    final last = values.lastIndexWhere((v) => v != null);
    if (last >= 0) {
      final at = Offset(x(last), y(values[last]!));
      canvas.drawCircle(at, 3.5, Paint()..color = chart.endRing);
      canvas.drawCircle(at, 2.5, Paint()..color = c ?? chart.endDot);
    }
  }

  @override
  bool shouldRepaint(_SparkPainter old) =>
      !listEquals(old.values, values) ||
      old.ink != ink ||
      old.area != area ||
      old.chart != chart;
}
