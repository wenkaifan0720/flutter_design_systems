/// Brutal's charts, drawn flat: ink axes at the theme's rule width, thin
/// muted grid lines, heavy lines on square markers, bars and wedges in
/// solid block colours edged with ink, and a legend of squares. Each reads
/// its numbers to a screen reader.
///
/// Every chart reads its `style`'s `edge` (the axes and the rules round
/// bars, wedges and legend squares), `foreground` (the axis labels, and a
/// sparkline's line) and `textStyle` (the labels and the legend), then
/// [BrutalThemeData.chartStyle]'s.
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import 'surface.dart';
import 'theme.dart';

/// One named run of values on a chart.
@immutable
class BrutalSeries {
  /// [label]'s [values], one for each of the chart's labels.
  const BrutalSeries(this.label, this.values, {this.color});

  /// Its name, in the legend.
  final String label;

  /// Its values, left to right.
  final List<double> values;

  /// Its colour; null takes the next of ink, blue, pink, lime and violet.
  final Color? color;
}

List<Color> _palette(BrutalColors c) => [
  c.ink,
  c.blue,
  c.pink,
  c.lime,
  c.violet,
];

Color _colorOf(BrutalColors c, List<BrutalSeries> series, int i) =>
    series[i].color ?? _palette(c)[i % 5];

String _number(double v) =>
    v == v.roundToDouble() ? v.round().toString() : v.toStringAsFixed(1);

/// A round top for the axis: 1, 2, 2.5 or 5 times a power of ten.
double _niceTop(double max) {
  if (max <= 0) return 1;
  final power = math.pow(10, (math.log(max) / math.ln10).floor()).toDouble();
  for (final step in const [1.0, 2.0, 2.5, 5.0, 10.0]) {
    if (step * power >= max) return step * power;
  }
  return 10 * power;
}

String _readOut(List<String> labels, List<BrutalSeries> series) => [
  for (final s in series)
    '${s.label}: ${[for (final (i, v) in s.values.indexed) '${i < labels.length ? labels[i] : i + 1} ${_number(v)}'].join(', ')}',
].join('; ');

/// The chart and its legend under it.
class _Framed extends StatelessWidget {
  const _Framed({
    required this.semanticLabel,
    required this.readOut,
    required this.legend,
    required this.chart,
    required this.layered,
  });

  final String semanticLabel;
  final String readOut;
  final List<(String, Color)> legend;
  final Widget chart;
  final DesignStyleOf layered;

  @override
  Widget build(BuildContext context) => Semantics(
    label: semanticLabel,
    value: readOut,
    excludeSemantics: true,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        chart,
        if (legend.length > 1) ...[
          const SizedBox(height: BrutalSpacing.medium),
          _Legend(entries: legend, layered: layered),
        ],
      ],
    ),
  );
}

class _Legend extends StatelessWidget {
  const _Legend({required this.entries, required this.layered});

  final List<(String, Color)> entries;
  final DesignStyleOf layered;

  @override
  Widget build(BuildContext context) {
    final theme = BrutalTheme.of(context);
    final c = theme.colors;
    final rule = layered.side?.color ?? layered.edge ?? c.ink;
    return Wrap(
      spacing: BrutalSpacing.regular,
      runSpacing: BrutalSpacing.small,
      children: [
        for (final (label, color) in entries)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox.square(
                dimension: 12,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: color,
                    border: Border.all(color: rule, width: theme.borderWidth),
                  ),
                ),
              ),
              const SizedBox(width: BrutalSpacing.small),
              Flexible(
                child: Text(
                  label,
                  style: layered.text(theme.textTheme.secondary),
                ),
              ),
            ],
          ),
      ],
    );
  }
}

/// What the axes painter shares between the line, area and bar charts.
abstract class _AxesPainter extends CustomPainter {
  _AxesPainter({
    required this.colors,
    required this.text,
    required this.labels,
    required this.series,
    required this.direction,
    required this.edge,
    required this.width,
    required this.words,
  });

  final BrutalColors colors;
  final TextStyle text;
  final List<String> labels;
  final List<BrutalSeries> series;
  final TextDirection direction;

  /// The axes' and the rules' colour.
  final Color edge;

  /// The axes' and the rules' width.
  final double width;

  /// The labels' colour.
  final Color words;

  late final double top = _niceTop(
    series.expand((s) => s.values).fold<double>(0, math.max),
  );

  TextPainter _label(String s) => TextPainter(
    text: TextSpan(
      text: s,
      style: text.copyWith(
        color: words,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    ),
    textDirection: direction,
  )..layout();

  /// Paints the grid and the axes and returns the plot's rectangle.
  Rect paintAxes(Canvas canvas, Size size) {
    final ticks = [for (var i = 0; i <= 4; i++) top * i / 4];
    final tickLabels = [for (final t in ticks) _label(_number(t))];
    final gutter = tickLabels.map((p) => p.width).fold<double>(0, math.max) + 8;
    final zero = _label('0');
    final xHeight = labels.isEmpty ? 0.0 : zero.height + 8;
    zero.dispose();
    final plot = Rect.fromLTRB(
      gutter,
      tickLabels.last.height / 2,
      size.width - 4,
      size.height - xHeight,
    );
    final grid = Paint()
      ..color = colors.inkMuted.withValues(alpha: 0.35)
      ..strokeWidth = 1;
    for (final (i, t) in ticks.indexed) {
      final y = plot.bottom - plot.height * t / top;
      if (i > 0) {
        canvas.drawLine(Offset(plot.left, y), Offset(plot.right, y), grid);
      }
      final p = tickLabels[i];
      p.paint(canvas, Offset(gutter - 8 - p.width, y - p.height / 2));
    }
    for (final p in tickLabels) {
      p.dispose();
    }
    final axis = Paint()
      ..color = edge
      ..strokeWidth = width;
    canvas
      ..drawLine(plot.bottomLeft, plot.bottomRight, axis)
      ..drawLine(plot.topLeft, plot.bottomLeft, axis);
    return plot;
  }

  void paintXLabel(Canvas canvas, Rect plot, String s, double x) {
    final p = _label(s);
    p.paint(canvas, Offset(x - p.width / 2, plot.bottom + 6));
    p.dispose();
  }

  @override
  bool shouldRepaint(_AxesPainter old) =>
      old.series != series ||
      old.labels != labels ||
      old.colors != colors ||
      old.edge != edge ||
      old.width != width ||
      old.words != words ||
      old.text != text;
}

class _LinePainter extends _AxesPainter {
  _LinePainter({
    required super.colors,
    required super.text,
    required super.labels,
    required super.series,
    required super.direction,
    required super.edge,
    required super.width,
    required super.words,
    required this.area,
  });

  final bool area;

  @override
  void paint(Canvas canvas, Size size) {
    final plot = paintAxes(canvas, size);
    final n = series.fold<int>(0, (a, s) => math.max(a, s.values.length));
    if (n == 0) return;
    double x(int i) => n == 1
        ? plot.center.dx
        : plot.left + 8 + (plot.width - 16) * i / (n - 1);
    double y(double v) => plot.bottom - plot.height * v / top;
    for (final (i, label) in labels.indexed) {
      if (i < n) paintXLabel(canvas, plot, label, x(i));
    }
    for (final (si, s) in series.indexed) {
      final color = _colorOf(colors, series, si);
      final line = Path();
      for (final (i, v) in s.values.indexed) {
        i == 0 ? line.moveTo(x(i), y(v)) : line.lineTo(x(i), y(v));
      }
      if (area && s.values.isNotEmpty) {
        final fill = Path.from(line)
          ..lineTo(x(s.values.length - 1), plot.bottom)
          ..lineTo(x(0), plot.bottom)
          ..close();
        canvas.drawPath(
          fill,
          Paint()
            ..color = color.withValues(alpha: series.length > 1 ? 0.45 : 0.8),
        );
      }
      canvas.drawPath(
        line,
        Paint()
          ..color = area ? edge : color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeJoin = StrokeJoin.miter,
      );
      if (!area) {
        for (final (i, v) in s.values.indexed) {
          final r = Rect.fromCenter(
            center: Offset(x(i), y(v)),
            width: 9,
            height: 9,
          );
          canvas
            ..drawRect(r, Paint()..color = colors.surface)
            ..drawRect(
              r,
              Paint()
                ..color = color
                ..style = PaintingStyle.stroke
                ..strokeWidth = width,
            );
        }
      }
    }
  }
}

class _BarPainter extends _AxesPainter {
  _BarPainter({
    required super.colors,
    required super.text,
    required super.labels,
    required super.series,
    required super.direction,
    required super.edge,
    required super.width,
    required super.words,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final plot = paintAxes(canvas, size);
    final n = series.fold<int>(0, (a, s) => math.max(a, s.values.length));
    if (n == 0) return;
    final slot = plot.width / n;
    final group = slot * 0.7;
    final bar = group / series.length;
    final rule = Paint()
      ..color = edge
      ..style = PaintingStyle.stroke
      ..strokeWidth = width;
    for (var i = 0; i < n; i++) {
      final start = plot.left + slot * i + (slot - group) / 2;
      for (final (si, s) in series.indexed) {
        if (i >= s.values.length) continue;
        final h = plot.height * s.values[i] / top;
        final r = Rect.fromLTWH(start + bar * si, plot.bottom - h, bar, h);
        canvas
          ..drawRect(r, Paint()..color = _colorOf(colors, series, si))
          ..drawRect(r.deflate(width / 2), rule);
      }
      if (i < labels.length) {
        paintXLabel(canvas, plot, labels[i], plot.left + slot * (i + 0.5));
      }
    }
  }
}

/// A chart of [series] over [labels]: the shared parts of the line, area
/// and bar charts.
abstract class _AxesChart extends StatelessWidget {
  const _AxesChart({
    super.key,
    required this.labels,
    required this.series,
    required this.semanticLabel,
    required this.height,
    this.style,
  });

  final List<String> labels;
  final List<BrutalSeries> series;
  final String semanticLabel;
  final double height;

  /// Its style, over [BrutalThemeData.chartStyle].
  final BrutalStyle? style;

  CustomPainter painter(
    BrutalThemeData theme,
    DesignStyleOf layered,
    TextDirection direction,
  );

  @override
  Widget build(BuildContext context) {
    final theme = BrutalTheme.of(context);
    final layered = DesignStyleOf([style, theme.chartStyle], const {});
    return _Framed(
      layered: layered,
      semanticLabel: semanticLabel,
      readOut: _readOut(labels, series),
      legend: [
        for (final (i, s) in series.indexed)
          (s.label, _colorOf(theme.colors, series, i)),
      ],
      chart: SizedBox(
        height: height,
        child: CustomPaint(
          painter: painter(theme, layered, Directionality.of(context)),
          size: Size.infinite,
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IntProperty('series', series.length))
      ..add(IntProperty('labels', labels.length));
  }
}

/// [series] as heavy lines over [labels], each value on a square marker.
///
/// ```dart
/// BrutalLineChart(semanticLabel: 'Tickets sold by night', labels: ['Mon', 'Tue', 'Wed'], series: [BrutalSeries('Sold', [120, 180, 150])])
/// ```
class BrutalLineChart extends _AxesChart {
  /// A line chart.
  const BrutalLineChart({
    super.key,
    required super.labels,
    required super.series,
    required super.semanticLabel,
    super.height = 220,
    super.style,
  });

  @override
  CustomPainter painter(
    BrutalThemeData theme,
    DesignStyleOf layered,
    TextDirection direction,
  ) => _LinePainter(
    colors: theme.colors,
    text: layered.text(theme.textTheme.caption),
    labels: labels,
    series: series,
    direction: direction,
    edge: layered.side?.color ?? layered.edge ?? theme.colors.ink,
    width: theme.borderWidth,
    words: layered.foreground ?? theme.colors.inkMuted,
    area: false,
  );
}

/// [series] as flat filled areas over [labels], each under an ink line.
///
/// ```dart
/// BrutalAreaChart(semanticLabel: 'Visits', labels: days, series: [BrutalSeries('Visits', visits)])
/// ```
class BrutalAreaChart extends _AxesChart {
  /// An area chart.
  const BrutalAreaChart({
    super.key,
    required super.labels,
    required super.series,
    required super.semanticLabel,
    super.height = 220,
    super.style,
  });

  @override
  CustomPainter painter(
    BrutalThemeData theme,
    DesignStyleOf layered,
    TextDirection direction,
  ) => _LinePainter(
    colors: theme.colors,
    text: layered.text(theme.textTheme.caption),
    labels: labels,
    series: series,
    direction: direction,
    edge: layered.side?.color ?? layered.edge ?? theme.colors.ink,
    width: theme.borderWidth,
    words: layered.foreground ?? theme.colors.inkMuted,
    area: true,
  );
}

/// [series] as solid ink-edged bars, side by side for each of [labels].
///
/// ```dart
/// BrutalBarChart(semanticLabel: 'Sold by night', labels: days, series: [BrutalSeries('Sold', sold)])
/// ```
class BrutalBarChart extends _AxesChart {
  /// A bar chart.
  const BrutalBarChart({
    super.key,
    required super.labels,
    required super.series,
    required super.semanticLabel,
    super.height = 220,
    super.style,
  });

  @override
  CustomPainter painter(
    BrutalThemeData theme,
    DesignStyleOf layered,
    TextDirection direction,
  ) => _BarPainter(
    colors: theme.colors,
    text: layered.text(theme.textTheme.caption),
    labels: labels,
    series: series,
    direction: direction,
    edge: layered.side?.color ?? layered.edge ?? theme.colors.ink,
    width: theme.borderWidth,
    words: layered.foreground ?? theme.colors.inkMuted,
  );
}

/// One wedge of a [BrutalPieChart].
@immutable
class BrutalSlice {
  /// [label]'s share, [value] of the whole.
  const BrutalSlice(this.label, this.value, {this.color});

  /// Its name, in the legend.
  final String label;

  /// Its amount; the chart sums them.
  final double value;

  /// Its colour; null takes the next of the block colours.
  final Color? color;
}

/// [slices] as flat wedges divided by ink rules, with a legend of squares
/// that also gives each share; [donut] cuts the middle out.
///
/// ```dart
/// BrutalPieChart(semanticLabel: 'Tickets by type', slices: [BrutalSlice('Standing', 340), BrutalSlice('Seated', 120)])
/// ```
class BrutalPieChart extends StatelessWidget {
  /// A pie of [slices].
  const BrutalPieChart({
    super.key,
    required this.slices,
    required this.semanticLabel,
    this.donut = false,
    this.size = 180,
    this.style,
  });

  /// The wedges, clockwise from the top.
  final List<BrutalSlice> slices;

  /// What the chart shows, for a screen reader.
  final String semanticLabel;

  /// Whether the middle is cut out.
  final bool donut;

  /// The pie's diameter.
  final double size;

  /// Its style, over [BrutalThemeData.chartStyle].
  final BrutalStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = BrutalTheme.of(context);
    final c = theme.colors;
    final layered = DesignStyleOf([style, theme.chartStyle], const {});
    final rule = layered.side?.color ?? layered.edge ?? c.ink;
    final blocks = [c.blue, c.pink, c.lime, c.violet, c.signal, c.ink];
    final total = slices.fold<double>(0, (a, s) => a + s.value);
    String share(BrutalSlice s) =>
        total == 0 ? '0%' : '${(s.value / total * 100).round()}%';
    final colors = [
      for (final (i, s) in slices.indexed) s.color ?? blocks[i % blocks.length],
    ];
    final pie = SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _PiePainter(
          values: [for (final s in slices) s.value],
          colors: colors,
          ink: rule,
          width: theme.borderWidth,
          hole: donut ? c.surface : null,
        ),
      ),
    );
    final legend = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final (i, s) in slices.indexed)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: BrutalSpacing.tight),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox.square(
                  dimension: 14,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: colors[i],
                      border: Border.all(color: rule, width: theme.borderWidth),
                    ),
                  ),
                ),
                const SizedBox(width: BrutalSpacing.small),
                Flexible(
                  child: Text(
                    s.label,
                    style: layered.text(theme.textTheme.body),
                  ),
                ),
                const SizedBox(width: BrutalSpacing.small),
                Text(
                  share(s),
                  style: layered
                      .text(theme.textTheme.secondary)
                      .copyWith(
                        color: layered.foreground,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                ),
              ],
            ),
          ),
      ],
    );
    return Semantics(
      label: semanticLabel,
      value: [for (final s in slices) '${s.label} ${share(s)}'].join(', '),
      excludeSemantics: true,
      child: Wrap(
        spacing: BrutalSpacing.large,
        runSpacing: BrutalSpacing.regular,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [pie, legend],
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<BrutalSlice>('slices', slices))
      ..add(StringProperty('semanticLabel', semanticLabel))
      ..add(FlagProperty('donut', value: donut, ifTrue: 'donut'))
      ..add(DoubleProperty('size', size))
      ..add(
        DiagnosticsProperty<BrutalStyle>('style', style, defaultValue: null),
      );
  }
}

class _PiePainter extends CustomPainter {
  const _PiePainter({
    required this.values,
    required this.colors,
    required this.ink,
    required this.width,
    required this.hole,
  });

  final List<double> values;
  final List<Color> colors;
  final Color ink;
  final double width;
  final Color? hole;

  @override
  void paint(Canvas canvas, Size size) {
    final total = values.fold<double>(0, (a, v) => a + v);
    final rect = (Offset.zero & size).deflate(width / 2);
    final rule = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeJoin = StrokeJoin.miter;
    if (total <= 0) {
      canvas.drawOval(rect, rule);
      return;
    }
    var start = -math.pi / 2;
    for (final (i, v) in values.indexed) {
      final sweep = 2 * math.pi * v / total;
      canvas.drawArc(rect, start, sweep, true, Paint()..color = colors[i]);
      canvas.drawArc(rect, start, sweep, true, rule);
      start += sweep;
    }
    if (hole != null) {
      final inner = Rect.fromCenter(
        center: rect.center,
        width: rect.width * 0.5,
        height: rect.height * 0.5,
      );
      canvas
        ..drawOval(inner, Paint()..color = hole!)
        ..drawOval(inner, rule);
    }
  }

  @override
  bool shouldRepaint(_PiePainter old) =>
      !listEquals(old.values, values) ||
      !listEquals(old.colors, colors) ||
      old.ink != ink ||
      old.width != width ||
      old.hole != hole;
}

/// A trend in a line of text: [values] as a line at the theme's rule
/// width, the last on a square; no axes. A screen reader hears [semanticLabel] and the first
/// and last values.
///
/// ```dart
/// BrutalSparkline(values: [3, 5, 4, 8, 7], semanticLabel: 'Sales this week')
/// ```
class BrutalSparkline extends StatelessWidget {
  /// A sparkline of [values].
  const BrutalSparkline({
    super.key,
    required this.values,
    required this.semanticLabel,
    this.color,
    this.width = 96,
    this.height = 28,
    this.style,
  });

  /// The values, left to right.
  final List<double> values;

  /// What it shows, for a screen reader.
  final String semanticLabel;

  /// The line's colour; null is the style's `foreground`, or ink.
  final Color? color;

  /// Its width.
  final double width;

  /// Its height.
  final double height;

  /// Its style, over [BrutalThemeData.chartStyle].
  final BrutalStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = BrutalTheme.of(context);
    final c = theme.colors;
    final layered = DesignStyleOf([style, theme.chartStyle], const {});
    return Semantics(
      label: semanticLabel,
      value: values.isEmpty
          ? null
          : 'from ${_number(values.first)} to ${_number(values.last)}',
      excludeSemantics: true,
      child: SizedBox(
        width: width,
        height: height,
        child: CustomPaint(
          painter: _SparkPainter(
            values: values,
            color: color ?? layered.foreground ?? c.ink,
            width: theme.borderWidth,
          ),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<double>('values', values))
      ..add(StringProperty('semanticLabel', semanticLabel))
      ..add(ColorProperty('color', color, defaultValue: null))
      ..add(DoubleProperty('width', width))
      ..add(DoubleProperty('height', height))
      ..add(
        DiagnosticsProperty<BrutalStyle>('style', style, defaultValue: null),
      );
  }
}

class _SparkPainter extends CustomPainter {
  const _SparkPainter({
    required this.values,
    required this.color,
    required this.width,
  });

  final List<double> values;
  final Color color;
  final double width;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final lo = values.reduce(math.min);
    final hi = values.reduce(math.max);
    final span = hi == lo ? 1 : hi - lo;
    final box = (Offset.zero & size).deflate(4);
    Offset at(int i) => Offset(
      values.length == 1
          ? box.center.dx
          : box.left + box.width * i / (values.length - 1),
      box.bottom - box.height * (values[i] - lo) / span,
    );
    final line = Path()..moveTo(at(0).dx, at(0).dy);
    for (var i = 1; i < values.length; i++) {
      line.lineTo(at(i).dx, at(i).dy);
    }
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeJoin = StrokeJoin.miter;
    canvas
      ..drawPath(line, paint)
      ..drawRect(
        Rect.fromCenter(center: at(values.length - 1), width: 7, height: 7),
        Paint()..color = color,
      );
  }

  @override
  bool shouldRepaint(_SparkPainter old) =>
      !listEquals(old.values, values) ||
      old.color != color ||
      old.width != width;
}
