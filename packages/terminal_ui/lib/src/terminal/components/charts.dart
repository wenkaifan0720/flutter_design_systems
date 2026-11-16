/// Numbers drawn in the grid: a sparkline of eighth-blocks, bars of
/// blocks, and line and area charts plotted in braille dots, two across
/// and four down a cell, as a terminal's monitors plot them.
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../grid.dart';
import '../primitives/box.dart';
import '../primitives/control.dart';
import '../style.dart';
import '../theme.dart';

String _num(double v) {
  if (v == v.roundToDouble()) return v.toInt().toString();
  return v.abs() >= 10 ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
}

({double min, double max}) _range(
  Iterable<double> values, {
  double? min,
  double? max,
}) {
  var lo = double.infinity;
  var hi = double.negativeInfinity;
  for (final v in values) {
    lo = math.min(lo, v);
    hi = math.max(hi, v);
  }
  if (lo == double.infinity) return (min: 0, max: 1);
  lo = min ?? lo;
  hi = max ?? hi;
  if (hi <= lo) hi = lo + 1;
  return (min: lo, max: hi);
}

double _at(List<double> values, double t) {
  if (values.length == 1) return values.first;
  final x = t * (values.length - 1);
  final i = x.floor().clamp(0, values.length - 2);
  final f = x - i;
  return values[i] + (values[i + 1] - values[i]) * f;
}

/// A trend in one line: a block per cell, its height in eighths of the
/// line (`▁▂▃▅▇`), the last value's cell in the accent.
///
/// ```dart
/// TermSparkline(values: const [3, 5, 4, 8, 6, 9], semanticLabel: 'build time, last 6 runs')
/// ```
class TermSparkline extends StatelessWidget {
  /// A sparkline of [values].
  const TermSparkline({
    super.key,
    required this.values,
    this.cols,
    this.semanticLabel,
    this.style,
  });

  /// The values, oldest first.
  final List<double> values;

  /// Its width in cells; null: a cell per value.
  final int? cols;

  /// What it shows; a screen reader hears it with the first, last, least
  /// and most values.
  final String? semanticLabel;

  /// Overrides, over the theme's [TermThemeData.chartStyle]: `foreground`
  /// (the blocks).
  final TermStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = TermTheme.of(context);
    final grid = context.termGrid;
    final own = TermStyleOf([style, theme.chartStyle], const {});
    final n = cols ?? values.length;
    final r = _range(values, min: 0);
    final said = values.isEmpty
        ? 'no values'
        : 'from ${_num(values.first)} to ${_num(values.last)}, '
              'least ${_num(values.reduce(math.min))}, '
              'most ${_num(values.reduce(math.max))}';
    return Semantics(
      label: [?semanticLabel, said].join(', '),
      excludeSemantics: true,
      child: CustomPaint(
        size: Size(grid.cols(n), grid.lineHeight),
        painter: _SparkPainter(
          grid: grid,
          values: values,
          cells: n,
          min: r.min,
          max: r.max,
          color: own.foreground ?? theme.dim,
          last: theme.accent,
        ),
      ),
    );
  }
}

class _SparkPainter extends CustomPainter {
  _SparkPainter({
    required this.grid,
    required this.values,
    required this.cells,
    required this.min,
    required this.max,
    required this.color,
    required this.last,
  });

  final TermGrid grid;
  final List<double> values;
  final int cells;
  final double min;
  final double max;
  final Color color;
  final Color last;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final cw = grid.cellWidth;
    final band = grid.fontSize;
    final bottom = (size.height + band) / 2;
    for (var i = 0; i < cells; i++) {
      final t = cells == 1 ? 1.0 : i / (cells - 1);
      final v = (_at(values, t) - min) / (max - min);
      final eighths = math.max(1, (v * 8).round());
      final h = band * eighths / 8;
      canvas.drawRect(
        Rect.fromLTWH(i * cw + cw * 0.08, bottom - h, cw * 0.84, h),
        Paint()..color = i == cells - 1 ? last : color,
      );
    }
  }

  @override
  bool shouldRepaint(_SparkPainter old) =>
      !listEquals(old.values, values) ||
      old.cells != cells ||
      old.color != color ||
      old.grid != grid;
}

/// Bars across the screen, one a line, as a terminal charts disk use: the
/// label, a bar of blocks to the eighth of a cell with dots for the cells
/// left, the value at the end.
///
/// ```dart
/// TermBarChart(bars: const [('api', 42), ('web', 18), ('worker', 7)], unit: 'min')
/// ```
class TermBarChart extends StatelessWidget {
  /// A bar per entry of [bars].
  const TermBarChart({
    super.key,
    required this.bars,
    this.max,
    this.unit,
    this.semanticLabel,
    this.style,
  });

  /// Each bar's label and value.
  final List<(String, double)> bars;

  /// The value a full bar stands for; null: the largest.
  final double? max;

  /// The values' unit, after each.
  final String? unit;

  /// What the chart shows.
  final String? semanticLabel;

  /// Overrides, over the theme's [TermThemeData.chartStyle]: `foreground`
  /// (the blocks) and `edge` (the dots left).
  final TermStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = TermTheme.of(context);
    final grid = context.termGrid;
    final own = TermStyleOf([style, theme.chartStyle], const {});
    final top = max ?? _range(bars.map((b) => b.$2), min: 0).max;
    var labelCols = 0;
    var valueCols = 0;
    for (final (l, v) in bars) {
      labelCols = math.max(labelCols, l.characters.length);
      valueCols = math.max(
        valueCols,
        _num(v).length + (unit == null ? 0 : unit!.length + 1),
      );
    }
    return Semantics(
      container: true,
      label: semanticLabel,
      explicitChildNodes: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (l, v) in bars)
            Semantics(
              label: '$l, ${_num(v)}${unit == null ? '' : ' $unit'}',
              excludeSemantics: true,
              child: SizedBox(
                height: grid.lineHeight,
                child: Row(
                  children: [
                    SizedBox(
                      width: grid.cols(labelCols + 2),
                      child: Text(l, style: theme.dimStyle),
                    ),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, c) => CustomPaint(
                          size: Size(
                            grid.cols(grid.colsIn(c.maxWidth)),
                            grid.lineHeight,
                          ),
                          painter: TermBlocksPainter(
                            grid: grid,
                            value: top == 0 ? 0 : v / top,
                            color: own.foreground ?? theme.accent,
                            track: own.edge ?? theme.rule,
                            textDirection: Directionality.of(context),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: grid.cols(valueCols + 1),
                      child: Text(
                        '${_num(v)}${unit == null ? '' : ' $unit'}',
                        textAlign: TextAlign.end,
                        style: theme.textStyle,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// One line of a [TermLineChart] or [TermAreaChart].
@immutable
class TermSeries {
  /// A series called [label] through [values].
  const TermSeries({required this.label, required this.values, this.color});

  /// Its name, in the key.
  final String label;

  /// Its values, evenly spaced, oldest first.
  final List<double> values;

  /// Its ink; null: the next of the palette's colours, the accent first.
  final Color? color;
}

List<Color> _inks(TermThemeData theme, List<TermSeries> series) {
  final slots = [
    theme.accent,
    TermAnsi.magenta.of(theme.palette),
    TermAnsi.yellow.of(theme.palette),
    TermAnsi.green.of(theme.palette),
    TermAnsi.blue.of(theme.palette),
    TermAnsi.red.of(theme.palette),
  ];
  return [
    for (final (i, s) in series.indexed) s.color ?? slots[i % slots.length],
  ];
}

/// A line chart plotted in braille dots, two across and four down each
/// cell: the most and least values dim at the start, a rule along the
/// foot, [xLabels] under it, and a key of each series' `●` and name.
///
/// ```dart
/// TermLineChart(
///   series: const [TermSeries(label: 'p95 ms', values: [120, 135, 128, 160, 142])],
///   xLabels: ('mon', 'fri'),
/// )
/// ```
class TermLineChart extends StatelessWidget {
  /// A chart of [series].
  const TermLineChart({
    super.key,
    required this.series,
    this.lines = 8,
    this.min,
    this.max,
    this.xLabels,
    this.semanticLabel,
    this.style,
  }) : fill = false;

  const TermLineChart._area({
    required this.series,
    this.lines = 8,
    this.min,
    this.max,
    this.xLabels,
    this.semanticLabel,
    this.style,
  }) : fill = true;

  /// The series.
  final List<TermSeries> series;

  /// The plot's height in lines.
  final int lines;

  /// The value at the foot; null: the least (an area's: 0).
  final double? min;

  /// The value at the top; null: the most.
  final double? max;

  /// The words under the foot's start and end.
  final (String, String)? xLabels;

  /// What it shows; a screen reader hears it with each series' first and
  /// last values.
  final String? semanticLabel;

  /// Overrides, over the theme's [TermThemeData.chartStyle]: `edge` (the
  /// axes); each series keeps its ink.
  final TermStyle? style;

  /// Whether the dots under each line are filled.
  final bool fill;

  @override
  Widget build(BuildContext context) {
    final theme = TermTheme.of(context);
    final grid = context.termGrid;
    final own = TermStyleOf([style, theme.chartStyle], const {});
    final r = _range(
      series.expand((s) => s.values),
      min: min ?? (fill ? 0 : null),
      max: max,
    );
    final top = _num(r.max);
    final foot = _num(r.min);
    final axisCols = math.max(top.length, foot.length) + 1;
    final inks = _inks(theme, series);
    final rule = own.edge ?? theme.rule;
    final said = [
      ?semanticLabel,
      for (final s in series)
        if (s.values.isNotEmpty)
          '${s.label}: from ${_num(s.values.first)} to ${_num(s.values.last)}',
    ].join('; ');
    return Semantics(
      label: said,
      excludeSemantics: true,
      child: Directionality(
        // A time axis runs left to right in any app, as a terminal's does.
        textDirection: TextDirection.ltr,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: grid.lines(lines),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: grid.cols(axisCols),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(right: grid.cellWidth),
                          child: Text(top, style: theme.dimStyle),
                        ),
                        Padding(
                          padding: EdgeInsets.only(right: grid.cellWidth),
                          child: Text(foot, style: theme.dimStyle),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, c) {
                        final cols = grid.colsIn(c.maxWidth);
                        return Align(
                          alignment: Alignment.centerLeft,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              border: Border(
                                left: BorderSide(
                                  color: rule,
                                  width: termStroke(theme, grid),
                                ),
                                bottom: BorderSide(
                                  color: rule,
                                  width: termStroke(theme, grid),
                                ),
                              ),
                            ),
                            child: CustomPaint(
                              size: Size(grid.cols(cols), grid.lines(lines)),
                              painter: _PlotPainter(
                                grid: grid,
                                series: [for (final s in series) s.values],
                                inks: inks,
                                min: r.min,
                                max: r.max,
                                fill: fill,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            if (xLabels != null)
              Padding(
                padding: EdgeInsets.only(left: grid.cols(axisCols)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(xLabels!.$1, style: theme.dimStyle),
                    Text(xLabels!.$2, style: theme.dimStyle),
                  ],
                ),
              ),
            if (series.length > 1 || series.isNotEmpty && semanticLabel == null)
              Padding(
                padding: EdgeInsets.only(left: grid.cols(axisCols)),
                child: Wrap(
                  spacing: grid.cols(2),
                  children: [
                    for (final (i, s) in series.indexed)
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: '● ',
                              style: theme.textStyle.copyWith(color: inks[i]),
                            ),
                            TextSpan(text: s.label, style: theme.dimStyle),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// An area chart: a [TermLineChart] with the dots under each line filled
/// in its ink, faint, the line itself solid; the foot is 0 unless [min]
/// says otherwise.
///
/// ```dart
/// TermAreaChart(series: const [TermSeries(label: 'requests', values: [4, 9, 7, 12, 10])])
/// ```
class TermAreaChart extends StatelessWidget {
  /// A chart of [series].
  const TermAreaChart({
    super.key,
    required this.series,
    this.lines = 8,
    this.min,
    this.max,
    this.xLabels,
    this.semanticLabel,
    this.style,
  });

  /// The series.
  final List<TermSeries> series;

  /// The plot's height in lines.
  final int lines;

  /// The value at the foot; null: 0.
  final double? min;

  /// The value at the top; null: the most.
  final double? max;

  /// The words under the foot's start and end.
  final (String, String)? xLabels;

  /// What it shows.
  final String? semanticLabel;

  /// Overrides, over the theme's [TermThemeData.chartStyle]: `edge` (the
  /// axes).
  final TermStyle? style;

  @override
  Widget build(BuildContext context) => TermLineChart._area(
    series: series,
    lines: lines,
    min: min,
    max: max,
    xLabels: xLabels,
    semanticLabel: semanticLabel,
    style: style,
  );
}

class _PlotPainter extends CustomPainter {
  _PlotPainter({
    required this.grid,
    required this.series,
    required this.inks,
    required this.min,
    required this.max,
    required this.fill,
  });

  final TermGrid grid;
  final List<List<double>> series;
  final List<Color> inks;
  final double min;
  final double max;
  final bool fill;

  @override
  void paint(Canvas canvas, Size size) {
    final cw = grid.cellWidth;
    final lh = grid.lineHeight;
    final across = (size.width / cw).round() * 2;
    final down = (size.height / lh).round() * 4;
    if (across < 2 || down < 2) return;
    final r = math.max(1.0, cw * 0.11);
    Offset dot(int x, int y) => Offset((x + 0.5) * cw / 2, (y + 0.5) * lh / 4);
    for (final (k, values) in series.indexed) {
      if (values.isEmpty) continue;
      final line = Paint()..color = inks[k];
      final under = Paint()..color = inks[k].withValues(alpha: 0.35);
      int? was;
      for (var x = 0; x < across; x++) {
        final v = (_at(values, x / (across - 1)) - min) / (max - min);
        final y = ((1 - v.clamp(0.0, 1.0)) * (down - 1)).round();
        if (fill) {
          for (var below = y + 1; below < down; below++) {
            canvas.drawCircle(dot(x, below), r, under);
          }
        }
        final from = was == null ? y : math.min(was + 1, y);
        final to = was == null ? y : math.max(was - 1, y);
        for (var yy = math.min(from, to); yy <= math.max(from, to); yy++) {
          canvas.drawCircle(dot(x, yy), r, line);
        }
        was = y;
      }
    }
  }

  @override
  bool shouldRepaint(_PlotPainter old) =>
      old.grid != grid ||
      old.min != min ||
      old.max != max ||
      old.fill != fill ||
      !listEquals(old.inks, inks) ||
      old.series.length != series.length ||
      [
        for (var i = 0; i < series.length; i++)
          listEquals(old.series[i], series[i]),
      ].contains(false);
}
