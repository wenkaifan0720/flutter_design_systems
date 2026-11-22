/// Numbers drawn in the grid: a sparkline of eighth-blocks, bars of
/// blocks, and line and area charts plotted in braille dots, two across
/// and four down a cell, as a terminal's monitors plot them.
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../grid.dart';
import '../primitives/box.dart';
import '../primitives/control.dart';
import '../style.dart';
import '../theme.dart';
import '../localizations.dart';

/// [v] as a chart writes it, in the reader's digits and separators as the
/// number field writes its value: whole where it is whole or ten and over,
/// else to a tenth ("2.5", "1,482"; Arabic's "٢٫٥", German's "2,5").
String _num(RawWidgetsLocalizations l, double v) => l.formatDecimal(
  v,
  fractionDigits: v == v.roundToDouble() || v.abs() >= 10 ? 0 : 1,
);

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
    final words = TermLocalizations.of(context);
    final l = RawWidgetsLocalizations.of(context);
    final said = values.isEmpty
        ? words.noValuesLabel
        : words.sparklineLabel(
            _num(l, values.first),
            _num(l, values.last),
            _num(l, values.reduce(math.min)),
            _num(l, values.reduce(math.max)),
          );
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
          rtl: Directionality.of(context) == TextDirection.rtl,
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
    required this.rtl,
  });

  final TermGrid grid;
  final List<double> values;
  final int cells;
  final double min;
  final double max;
  final Color color;
  final Color last;

  // Whether the trend runs from the right, the last value at the left.
  final bool rtl;

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
      final x = (rtl ? cells - 1 - i : i) * cw;
      canvas.drawRect(
        Rect.fromLTWH(x + cw * 0.08, bottom - h, cw * 0.84, h),
        Paint()..color = i == cells - 1 ? last : color,
      );
    }
  }

  @override
  bool shouldRepaint(_SparkPainter old) =>
      !listEquals(old.values, values) ||
      old.cells != cells ||
      old.color != color ||
      old.rtl != rtl ||
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

  // The names and the values grow with the reader's text to 1.3 times its
  // size, as Material's slider's value label does, so a phone's width
  // keeps both and the bars between them.
  @override
  Widget build(BuildContext context) => MediaQuery.withClampedTextScaling(
    maxScaleFactor: 1.3,
    child: Builder(builder: _bars),
  );

  Widget _bars(BuildContext context) {
    final theme = TermTheme.of(context);
    final grid = context.termGrid;
    final own = TermStyleOf([style, theme.chartStyle], const {});
    final top = max ?? _range(bars.map((b) => b.$2), min: 0).max;
    final l = RawWidgetsLocalizations.of(context);
    String figure(double v) =>
        unit == null ? _num(l, v) : '${_num(l, v)} $unit';
    var labelCols = 0;
    var valueCols = 0;
    for (final (label, v) in bars) {
      labelCols = math.max(labelCols, label.characters.length);
      valueCols = math.max(valueCols, grid.colsIn(grid.widthOf(figure(v))));
    }
    return Semantics(
      container: true,
      label: semanticLabel,
      explicitChildNodes: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (label, v) in bars)
            Semantics(
              label: '$label, ${figure(v)}',
              excludeSemantics: true,
              child: SizedBox(
                height: grid.lineHeight,
                child: Row(
                  children: [
                    SizedBox(
                      width: grid.cols(labelCols + 2),
                      child: Text(label, style: theme.dimStyle),
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
                        figure(v),
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
/// The behaviour is ui_core's [DesignChart]: a pointer over the plot picks
/// the point nearest it along the foot (a finger scrubs, a tap holds), and
/// the keys pick too (one tab stop: Left and Right along a series, Up and
/// Down between series, Home and End, Escape), the point's column shaded
/// and its value written over the plot; while the keys are on it the
/// cursor stands on the column of its scale, the most and least values cut
/// out of it, as a terminal's gutter lights the current line. A screen reader hears [semanticLabel] and the data in a
/// sentence, or the point picked, and steps through the points. A change of
/// data springs from the old line to the new.
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

  /// What it shows; a screen reader hears it, then the data in a sentence.
  /// Null: the series' names.
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
    final cw = grid.cellWidth;
    final stroke = termStroke(theme, grid);
    final inks = _inks(theme, series);
    // The axis column is as wide as the widest label the data could give;
    // the plot takes whole cells after it.
    final r0 = _range(
      series.expand((s) => s.values),
      min: min ?? (fill ? 0 : null),
      max: max,
    );
    final l = RawWidgetsLocalizations.of(context);
    int cells(double v) => grid.colsIn(grid.widthOf(_num(l, v)));
    final axisCols = math.max(cells(r0.max), cells(r0.min)) + 1;
    final axisWidth = grid.cols(axisCols);
    // The chart reads in the page's direction: right to left, its points
    // run from the right and its scale stands at the right.
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final plot = SizedBox(
      height: grid.lines(lines),
      child: LayoutBuilder(
        builder: (context, c) {
          final cols = grid.colsIn(c.maxWidth - axisWidth);
          final plotWidth = grid.cols(cols);
          return Align(
            alignment: AlignmentDirectional.centerStart,
            child: SizedBox(
              width: axisWidth + plotWidth,
              child: DesignChart(
                series: [
                  for (final s in series)
                    DesignChartSeries(
                      label: s.label,
                      points: [
                        for (final (i, v) in s.values.indexed)
                          DesignChartPoint(i.toDouble(), v),
                      ],
                    ),
                ],
                semanticLabel:
                    semanticLabel ?? series.map((s) => s.label).join(', '),
                yIncludesZero: fill,
                // The points by their place, from 1.
                formatX: (x) => l.formatDecimal(x.round() + 1),
                formatY: (y) => _num(l, y),
                // ui_core's x runs between the first and last dot columns'
                // middles, a quarter cell in from the plot's sides.
                padding: EdgeInsetsDirectional.only(
                  start: axisWidth + cw / 4,
                  end: cw / 4,
                ),
                builder: (context, chart) {
                  final drawn = [
                    for (final s in chart.series)
                      [for (final p in s.points) p.y ?? 0],
                  ];
                  final r = _range(
                    drawn.expand((v) => v),
                    min: min ?? (fill ? 0 : null),
                    max: max,
                  );
                  final focused = chart.states.contains(WidgetState.focused);
                  final rule = own.edge ?? theme.rule;
                  final active = chart.active;
                  int? cell;
                  String? readout;
                  if (active != null) {
                    final at =
                        chart.positionOf(active).dx - (rtl ? 0 : axisWidth);
                    cell = (at / cw).floor().clamp(0, math.max(0, cols - 1));
                    final v = drawn[active.series][active.index];
                    readout =
                        '${series.length > 1 ? '${series[active.series].label} ' : ''}${_num(l, v)}';
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TermStateSprings(
                        pressed: false,
                        focused: focused,
                        builder: (context, _, f) {
                          final scale = theme.dimStyle.copyWith(
                            color: termCursorInk(theme, theme.dim, f),
                          );
                          return ColoredBox(
                            color: theme.accent.withValues(
                              alpha: theme.accent.a * f,
                            ),
                            child: SizedBox(
                              width: axisWidth,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Padding(
                                    padding: EdgeInsetsDirectional.only(
                                      end: cw,
                                    ),
                                    child: Text(_num(l, r.max), style: scale),
                                  ),
                                  Padding(
                                    padding: EdgeInsetsDirectional.only(
                                      end: cw,
                                    ),
                                    child: Text(_num(l, r.min), style: scale),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      SizedBox(
                        width: plotWidth,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            border: BorderDirectional(
                              start: BorderSide(color: rule, width: stroke),
                              bottom: BorderSide(color: rule, width: stroke),
                            ),
                          ),
                          child: Stack(
                            children: [
                              // The picked point's column, shaded.
                              if (cell != null)
                                Positioned(
                                  left: grid.cols(cell),
                                  top: 0,
                                  bottom: 0,
                                  width: cw,
                                  child: ColoredBox(
                                    color: theme.rule.withValues(alpha: 0.35),
                                  ),
                                ),
                              CustomPaint(
                                size: Size(plotWidth, grid.lines(lines)),
                                painter: _PlotPainter(
                                  grid: grid,
                                  series: drawn,
                                  inks: inks,
                                  min: r.min,
                                  max: r.max,
                                  fill: fill,
                                  rtl: rtl,
                                ),
                              ),
                              // Its value, on the top line, beside the
                              // column on the side with room.
                              if (cell != null && readout != null)
                                Positioned(
                                  top: 0,
                                  left: cell < cols / 2
                                      ? grid.cols(cell + 1)
                                      : null,
                                  right: cell < cols / 2
                                      ? null
                                      : plotWidth - grid.cols(cell),
                                  child: ColoredBox(
                                    color: theme.background,
                                    child: Text(
                                      readout,
                                      maxLines: 1,
                                      softWrap: false,
                                      style: theme.textStyle.copyWith(
                                        color: inks[active!.series],
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          );
        },
      ),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        plot,
        ExcludeSemantics(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (xLabels != null)
                Padding(
                  padding: EdgeInsetsDirectional.only(start: axisWidth),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(xLabels!.$1, style: theme.dimStyle),
                      Text(xLabels!.$2, style: theme.dimStyle),
                    ],
                  ),
                ),
              if (series.length > 1 ||
                  series.isNotEmpty && semanticLabel == null)
                Padding(
                  padding: EdgeInsetsDirectional.only(start: axisWidth),
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
      ],
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
    required this.rtl,
  });

  final TermGrid grid;
  final List<List<double>> series;
  final List<Color> inks;
  final double min;
  final double max;
  final bool fill;

  // Whether the points run from the right.
  final bool rtl;

  @override
  void paint(Canvas canvas, Size size) {
    final cw = grid.cellWidth;
    final lh = grid.lineHeight;
    final across = (size.width / cw).round() * 2;
    final down = (size.height / lh).round() * 4;
    if (across < 2 || down < 2) return;
    final r = math.max(1.0, cw * 0.11);
    Offset dot(int x, int y) =>
        Offset(((rtl ? across - 1 - x : x) + 0.5) * cw / 2, (y + 0.5) * lh / 4);
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
      old.rtl != rtl ||
      !listEquals(old.inks, inks) ||
      old.series.length != series.length ||
      [
        for (var i = 0; i < series.length; i++)
          listEquals(old.series[i], series[i]),
      ].contains(false);
}
