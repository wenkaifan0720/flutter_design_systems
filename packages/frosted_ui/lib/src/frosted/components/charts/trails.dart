import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import '../../chrome_metrics.dart';
import '../../format.dart';
import '../../internal/chart_parts.dart';
import '../../theme.dart';
import 'bars.dart' show FrostedAxisMark;

/// The width a chart draws at when nothing bounds it: the pilot's phone
/// tile interior.
const double _unboundedWidth = 326;

enum _TrailFace { months, days, steps }

/// A note on a cliff of a balance's trail ([FrostedTrailChart.steps]): the
/// [day] it moved and what moved it ("Paycheck"), set over a rise or under
/// a fall.
///
/// ```dart
/// FrostedChartNote(9, 'Paycheck')
/// ```
@immutable
class FrostedChartNote {
  /// Creates a [FrostedChartNote].
  const FrostedChartNote(this.day, this.text);

  /// The day of the month, from 1.
  final int day;

  /// The note's words.
  final String text;
}

/// A run of values as a line of the spectrum (violet through mauve to
/// rose, 2.5 wide), the light under it fading to the floor, hairline
/// gridlines with their values at the end and the last value ringed as
/// today. The default is a year by month (the net worth): one column per
/// value, the grid every $10k, the [months]' initials under it (their short
/// names from 1024 wide), the [current] one in the page ink.
/// [FrostedTrailChart.days] draws a month by day through the days' centres
/// (an account's value); [FrostedTrailChart.steps] a balance: flat runs with
/// a cliff on each day it moved, from its [start] at the month's first
/// moment, the cliffs named by [notes]; both set [marks] under the plot.
/// [bare] keeps the line alone, a sparkline in a row. Sized by its width;
/// the plot stands [height] tall (the source's phone and desktop heights
/// by default).
///
/// ```dart
/// FrostedTrailChart(values: netWorthByMonth, months: const ['Nov', 'Dec', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct'], label: 'Net worth over the last 12 months')
/// ```
class FrostedTrailChart extends StatelessWidget {
  /// Creates a [FrostedTrailChart].
  const FrostedTrailChart({
    required this.values,
    required this.label,
    this.months = const <String>[],
    this.current,
    this.bare = false,
    this.height,
    super.key,
  }) : daysInMonth = null,
       start = null,
       notes = const <FrostedChartNote>[],
       marks = const <FrostedAxisMark>[],
       lines = 4,
       _face = _TrailFace.months;

  /// A month by day: one value per day so far (the last is today) of
  /// [daysInMonth], a monotone line through the days' centres, the grid on
  /// a nice step of [lines] lines, the [marks] under it.
  ///
  /// ```dart
  /// FrostedTrailChart.days(values: valueByDay, daysInMonth: 31, marks: octoberAxis, label: 'Investing value through October')
  /// ```
  const FrostedTrailChart.days({
    required this.values,
    required int this.daysInMonth,
    required this.label,
    this.marks = const <FrostedAxisMark>[],
    this.lines = 3,
    this.height,
    super.key,
  }) : months = const <String>[],
       current = null,
       start = null,
       bare = false,
       notes = const <FrostedChartNote>[],
       _face = _TrailFace.days;

  /// A balance by day: its closing [values] each day so far, drawn as flat
  /// runs from [start] (the balance before the month) with a cliff at the
  /// centre of each day it moved; each of [notes] names its day's cliff.
  ///
  /// ```dart
  /// FrostedTrailChart.steps(values: closingByDay, start: 2479.82, daysInMonth: 31, notes: const [FrostedChartNote(9, 'Paycheck')], marks: octoberAxis, label: 'Everyday balance through October')
  /// ```
  const FrostedTrailChart.steps({
    required this.values,
    required num this.start,
    required int this.daysInMonth,
    required this.label,
    this.notes = const <FrostedChartNote>[],
    this.marks = const <FrostedAxisMark>[],
    this.lines = 3,
    this.height,
    super.key,
  }) : months = const <String>[],
       current = null,
       bare = false,
       _face = _TrailFace.steps;

  /// The values in order, the latest last; dollars.
  final List<num> values;

  /// What a screen reader calls the chart.
  final String label;

  /// The months' short names under a year's columns; none for a bare
  /// trail.
  final List<String> months;

  /// The month set in the page ink; the last by default.
  final int? current;

  /// A sparkline: the line, its light and the end dot alone, no grid and
  /// no words (DERIVED: the pilot's trails all carry their grid).
  final bool bare;

  /// The days in the month of a day face.
  final int? daysInMonth;

  /// The balance before the month, on the steps face.
  final num? start;

  /// Notes pinned to days.
  final List<FrostedChartNote> notes;

  /// The words under a day face's plot.
  final List<FrostedAxisMark> marks;

  /// How many gridlines a day face aims for.
  final int lines;

  /// The plot's height; the source's for the width when null.
  final double? height;
  final _TrailFace _face;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    final wide = FrostedBreakpoints.isWide(context);
    final gutter = FrostedChartGutter.trail.of(wide);
    final h =
        height ??
        switch (_face) {
          _TrailFace.months => wide ? 210.0 : 140.0,
          _TrailFace.days => wide ? 210.0 : 150.0,
          _TrailFace.steps => wide ? 200.0 : 150.0,
        };
    final axis = switch (_face) {
      _ when bare => null,
      _TrailFace.months when months.isNotEmpty => FrostedMonthsAxis(
        months: months,
        current: current,
        endInset: gutter,
      ),
      _TrailFace.days ||
      _TrailFace.steps when marks.isNotEmpty => FrostedDaysAxis(
        words: FrostedAxisMark.words(marks, daysInMonth!),
        // .x-days--w { margin-right: 40px } (48 from 1024): the trail's
        // own gutter.
        endInset: gutter,
      ),
      _ => null,
    };
    return Semantics(
      label: label,
      value: values.isEmpty
          ? null
          : '${values.length} '
                '${_face == _TrailFace.months ? 'months' : 'days'}, '
                '${FrostedFormat.money(values.first)} to '
                '${FrostedFormat.money(values.last)}',
      child: ExcludeSemantics(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LayoutBuilder(
              builder: (context, box) {
                final w = box.maxWidth.isFinite
                    ? box.maxWidth
                    : _unboundedWidth;
                final g = _trail(w, h, gutter);
                return SizedBox(
                  height: h,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _TrailPainter(g, t.charts, grid: !bare),
                        ),
                      ),
                      if (!bare)
                        for (final (value, y) in g.grid)
                          FrostedChartLabel(
                            span: TextSpan(text: value),
                            at: Offset(w, y),
                            anchor: FrostedLabelAnchor.gridEnd,
                            // .y-lbl { font: 500 12px/1; color: var(--ink-3) }
                            style: t.textTheme.labelSmall.c(
                              t.colorScheme.textTertiary,
                            ),
                          ),
                      for (final (text, at, up) in g.notes)
                        FrostedChartLabel(
                          span: TextSpan(text: text),
                          at: at,
                          anchor: up
                              ? FrostedLabelAnchor.noteUp
                              : FrostedLabelAnchor.noteDown,
                          // .mk { font: 500 12px/1; color: var(--ink-2) }
                          style: t.textTheme.labelSmall,
                        ),
                    ],
                  ),
                );
              },
            ),
            ?axis,
          ],
        ),
      ),
    );
  }

  _Trail _trail(double w, double h, double gutter) {
    final plot = w - gutter;
    switch (_face) {
      case _TrailFace.months:
        // networth(): the grid every $10k, the floor a fifth of the span
        // under the lowest line so the line never touches it.
        const padTop = 12.0;
        const padBot = 8.0;
        final ks = [for (final v in values) v / 1000];
        var hi = (ks.reduce(math.max) / 10).ceil() * 10.0;
        final g0 = (ks.reduce(math.min) / 10).floor() * 10.0;
        if (hi <= g0) hi = g0 + 10;
        final lo = g0 - (hi - g0) * 0.2;
        double y(double v) =>
            padTop + (hi - v) / (hi - lo) * (h - padTop - padBot);
        final n = ks.length;
        final pts = [
          for (final (i, v) in ks.indexed)
            Offset(frostedSlot(i, n, plot), y(v)),
        ];
        final line = frostedMonotonePath(pts);
        final area = Path.from(line)
          ..lineTo(pts.last.dx, h)
          ..lineTo(pts.first.dx, h)
          ..close();
        return _Trail(
          line: line,
          area: area,
          areaTop: y(hi - 2),
          from: pts.first,
          to: pts.last,
          end: pts.last,
          plot: plot,
          gridYs: [for (var g = g0; g <= hi + 1e-9; g += 10) y(g)],
          grid: [
            for (var g = hi; g >= g0 - 1e-9; g -= 10) ('\$${g.round()}k', y(g)),
          ],
          notes: const [],
        );
      case _TrailFace.days:
      case _TrailFace.steps:
        // day_line(): the grid on the nice step of the values (the start
        // included on a balance), a monotone line through the days'
        // centres or flat runs with a cliff on each day the balance moved.
        const padTop = 14.0;
        const padBot = 6.0;
        final n = values.length;
        final days = daysInMonth!;
        final vals = [...values, ?start];
        final range = frostedValueRange(vals, lines: lines);
        final hi = range.hi;
        final lo = range.lo;
        double y(num v) =>
            padTop + (hi - v) / (hi - lo) * (h - padTop - padBot);
        double xc(int d) => (d - 0.5) / days * plot;
        final top = y(vals.reduce(math.max));
        final grid = [
          for (final g in range.grid.reversed) (frostedDollarsShort(g), y(g)),
        ];
        final gridYs = [for (final g in range.grid) y(g)];
        if (_face == _TrailFace.days) {
          final pts = [
            for (var d = 1; d <= n; d++) Offset(xc(d), y(values[d - 1])),
          ];
          final line = frostedMonotonePath(pts);
          final area = Path.from(line)
            ..lineTo(pts.last.dx, h)
            ..lineTo(pts.first.dx, h)
            ..close();
          return _Trail(
            line: line,
            area: area,
            areaTop: top,
            from: pts.first,
            to: pts.last,
            end: pts.last,
            plot: plot,
            gridYs: gridYs,
            grid: grid,
            notes: const [],
          );
        }
        var prev = start!;
        final line = Path()..moveTo(0, y(prev));
        final cliffs = <int, (double, double, double)>{};
        for (var d = 1; d <= n; d++) {
          final v = values[d - 1];
          if ((v - prev).abs() > 1e-9) {
            final x = xc(d);
            line
              ..lineTo(x, y(prev))
              ..lineTo(x, y(v));
            cliffs[d] = (x, y(prev), y(v));
          }
          prev = v;
        }
        final ex = n / days * plot;
        final ey = y(prev);
        line.lineTo(ex, ey);
        final area = Path.from(line)
          ..lineTo(ex, h)
          ..lineTo(0, h)
          ..close();
        return _Trail(
          line: line,
          area: area,
          areaTop: top,
          from: Offset(0, ey),
          to: Offset(ex, ey),
          end: Offset(ex, ey),
          plot: plot,
          gridYs: gridYs,
          grid: grid,
          notes: [
            for (final note in notes)
              if (cliffs[note.day] case (final x, final y0, final y1)?)
                (
                  note.text,
                  Offset(x, y1 < y0 ? math.min(y0, y1) : math.max(y0, y1)),
                  y1 < y0,
                ),
          ],
        );
    }
  }
}

class _Trail {
  const _Trail({
    required this.line,
    required this.area,
    required this.areaTop,
    required this.from,
    required this.to,
    required this.end,
    required this.plot,
    required this.gridYs,
    required this.grid,
    required this.notes,
  });

  final Path line;
  final Path area;
  final double areaTop;
  final Offset from;
  final Offset to;
  final Offset end;
  final double plot;
  final List<double> gridYs;
  final List<(String, double)> grid;
  final List<(String, Offset, bool)> notes;
}

class _TrailPainter extends CustomPainter {
  const _TrailPainter(this.g, this.inks, {required this.grid});

  final _Trail g;
  final FrostedChartInks inks;
  final bool grid;

  @override
  void paint(Canvas canvas, Size size) {
    if (grid) frostedPaintGrid(canvas, g.gridYs, g.plot, inks.grid);
    canvas.drawPath(g.area, frostedAreaPaint(g.areaTop, size.height, inks));
    canvas.drawPath(
      g.line,
      frostedLinePaint(frostedSpectrum(g.from, g.to, inks.line)),
    );
    frostedPaintEndDot(canvas, g.end, inks);
  }

  @override
  bool shouldRepaint(_TrailPainter old) => true;
}

/// A month's spending day by day against its budget: the spent line (the
/// spectrum, from $0 at the month's start to today) over its light, the
/// budget a dotted rule named at its start, the pace a dashed line from $0
/// to the budget on the last day, today a faint drop line to the floor,
/// gridlines every $1,000 with their values at the end, [firstNote] beside
/// the first day's point (the rent) and [marks] under the plot, each at its
/// day's point. Sized by its width; [height] is the plot's.
///
/// ```dart
/// FrostedSpendChart(spent: spentByDay, budget: 2700, daysInMonth: 31, firstNote: 'Rent', marks: octoberAxis, label: 'October spending against the budget pace')
/// ```
class FrostedSpendChart extends StatelessWidget {
  /// Creates a [FrostedSpendChart].
  const FrostedSpendChart({
    required this.spent,
    required this.budget,
    required this.daysInMonth,
    required this.label,
    this.firstNote,
    this.marks = const <FrostedAxisMark>[],
    this.height,
    super.key,
  });

  /// What the month had spent by the end of each day so far.
  final List<num> spent;

  /// The month's budget, drawn as the pace line's end.
  final num budget;

  /// How many days the month has.
  final int daysInMonth;

  /// What a screen reader calls the chart.
  final String label;

  /// A note beside the first day's point ("Rent").
  final String? firstNote;

  /// The words under the plot: a mark's slot is its day (from 0), set at
  /// the day's point.
  final List<FrostedAxisMark> marks;

  /// The chart's height; null takes the look's.
  final double? height;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    final wide = FrostedBreakpoints.isWide(context);
    final gutter = FrostedChartGutter.bars.of(wide);
    final h = height ?? (wide ? 216.0 : 176.0);
    return Semantics(
      label: label,
      value: spent.isEmpty
          ? null
          : '${FrostedFormat.money(spent.last)} of '
                '${FrostedFormat.money(budget, cents: false)}',
      child: ExcludeSemantics(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LayoutBuilder(
              builder: (context, box) {
                final w = box.maxWidth.isFinite
                    ? box.maxWidth
                    : _unboundedWidth;
                final g = _spend(w, h, gutter);
                return SizedBox(
                  height: h,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned.fill(
                        child: CustomPaint(painter: _SpendPainter(g, t.charts)),
                      ),
                      FrostedChartLabel(
                        span: TextSpan(
                          text:
                              'Budget ${FrostedFormat.money(budget, cents: false)}',
                        ),
                        at: Offset(0, g.budgetY),
                        anchor: FrostedLabelAnchor.ruleStart,
                        // .b-lbl { font: 500 12px/1; color: var(--ink-2) }
                        style: t.textTheme.labelSmall,
                      ),
                      for (final (value, y) in g.grid)
                        FrostedChartLabel(
                          span: TextSpan(text: value),
                          at: Offset(w, y),
                          anchor: FrostedLabelAnchor.gridEnd,
                          style: t.textTheme.labelSmall.c(
                            t.colorScheme.textTertiary,
                          ),
                        ),
                      if (firstNote case final note? when spent.isNotEmpty)
                        FrostedChartLabel(
                          span: TextSpan(text: note),
                          // The page sets it 8 right and 15 under the
                          // first day's point.
                          at: g.first + const Offset(8, 15),
                          anchor: FrostedLabelAnchor.at,
                          // .a-lbl { font: 500 12px/1; color: #5E5BB8 }
                          style: t.textTheme.labelSmall.c(t.charts.label),
                        ),
                    ],
                  ),
                );
              },
            ),
            if (marks.isNotEmpty)
              FrostedDaysAxis(
                words: FrostedAxisMark.words(marks, daysInMonth, point: true),
                endInset: wide
                    ? FrostedChromeMetrics.chartLabelsEndGapWide
                    : gutter,
              ),
          ],
        ),
      ),
    );
  }

  _Spend _spend(double w, double h, double gutter) {
    // cumulative(): the top the next $1,000 over the budget, lifted another
    // $1,000 when the budget is within $200 of it.
    const padTop = 10.0;
    const padBot = 0.0;
    var hi = (budget / 1000).ceil() * 1000.0;
    if (hi - budget < 200) hi += 1000;
    final plot = w - gutter;
    double y(num v) => padTop + (hi - v) / hi * (h - padTop - padBot);
    double x(int day) => day / daysInMonth * plot;
    final pts = [
      Offset(0, y(0)),
      for (final (i, v) in spent.indexed) Offset(x(i + 1), y(v)),
    ];
    final line = frostedPolyline(pts);
    final area = Path.from(line)
      ..lineTo(pts.last.dx, h)
      ..close();
    final grid = <double>[for (var g = 1000.0; g < hi; g += 1000) g];
    return _Spend(
      line: line,
      area: area,
      budgetY: y(budget),
      zeroY: y(0),
      today: pts.last,
      first: pts.length > 1 ? pts[1] : pts.first,
      plot: plot,
      gridYs: [for (final g in grid) y(g)],
      grid: [for (final g in grid.reversed) ('\$${g ~/ 1000}k', y(g))],
    );
  }
}

class _Spend {
  const _Spend({
    required this.line,
    required this.area,
    required this.budgetY,
    required this.zeroY,
    required this.today,
    required this.first,
    required this.plot,
    required this.gridYs,
    required this.grid,
  });

  final Path line;
  final Path area;
  final double budgetY;
  final double zeroY;
  final Offset today;
  final Offset first;
  final double plot;
  final List<double> gridYs;
  final List<(String, double)> grid;
}

class _SpendPainter extends CustomPainter {
  const _SpendPainter(this.g, this.inks);

  final _Spend g;
  final FrostedChartInks inks;

  @override
  void paint(Canvas canvas, Size size) {
    final h = size.height;
    frostedPaintGrid(canvas, g.gridYs, g.plot, inks.grid);
    // The budget: dots 1.5 wide, 1.5 on and 5 off, in the pace ink (.4).
    final budget = Path()
      ..moveTo(0, g.budgetY)
      ..lineTo(g.plot, g.budgetY);
    canvas.drawPath(
      frostedDashes(budget, const [1.5, 5]),
      frostedRulePaint(inks.pace, 1.5),
    );
    // Under the line the light runs from the budget's height down to a
    // last trace (.02) at the floor.
    canvas.drawPath(
      g.area,
      frostedAreaPaint(
        g.budgetY,
        h,
        inks,
        to: inks.areaFrom.withValues(alpha: 0.02),
      ),
    );
    // The pace: dashes 5 on and 6 off at .28 of the ink.
    final pace = Path()
      ..moveTo(0, g.zeroY)
      ..lineTo(g.plot, g.budgetY);
    canvas.drawPath(
      frostedDashes(pace, const [5, 6]),
      frostedRulePaint(inks.pace.withValues(alpha: 0.28), 1.5),
    );
    // Today's drop line, the end ink at .4, 1 wide.
    canvas.drawLine(
      g.today,
      Offset(g.today.dx, h),
      Paint()
        ..color = inks.endDot.withValues(alpha: 0.4)
        ..strokeWidth = 1,
    );
    canvas.drawPath(
      g.line,
      frostedLinePaint(
        frostedSpectrum(Offset(0, g.today.dy), g.today, inks.line),
      ),
    );
    frostedPaintEndDot(canvas, g.today, inks);
  }

  @override
  bool shouldRepaint(_SpendPainter old) => true;
}

/// A goal's saving over time: what was [saved] by each month (the
/// spectrum over its light), the [projection] on from the last month in
/// the goal's [hue], dashed, ringed at its end and named with where it
/// lands by [endDate] ("$3,890 by May 2027"), the [target] a dotted rule
/// named at its start, gridlines on a nice step with their values at the
/// end, today ringed, and [marks] under the columns (the first month,
/// today, the last). Sized by its width; [height] is the plot's.
///
/// ```dart
/// FrostedGoalChart(saved: savedByMonth, projection: ahead, target: 4000, endDate: DateTime(2027, 5), hue: theme.hues.sunset, marks: goalAxis, label: 'Lisbon in May: saved, and where it is headed')
/// ```
class FrostedGoalChart extends StatelessWidget {
  /// Creates a [FrostedGoalChart].
  const FrostedGoalChart({
    required this.saved,
    required this.target,
    required this.hue,
    required this.label,
    this.projection = const <num>[],
    this.endDate,
    this.marks = const <FrostedAxisMark>[],
    this.lines = 3,
    this.height,
    super.key,
  }) : assert(saved.length > 0, 'a goal chart needs a saved value');

  /// What the goal held at the end of each month, the latest last.
  final List<num> saved;

  /// Where the auto-save leads it, month by month after the latest.
  final List<num> projection;

  /// The goal's sum, drawn as a line.
  final num target;

  /// The month the projection reaches, for its end's label.
  final DateTime? endDate;

  /// The goal's hue, for the projection.
  final FrostedHue hue;

  /// What a screen reader calls the chart.
  final String label;

  /// The words under the columns (saved months, then projected).
  final List<FrostedAxisMark> marks;

  /// How many gridlines the chart aims for.
  final int lines;

  /// The chart's height; null takes the look's.
  final double? height;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    final wide = FrostedBreakpoints.isWide(context);
    final gutter = FrostedChartGutter.trail.of(wide);
    final h = height ?? (wide ? 280.0 : 170.0);
    final columns = saved.length + projection.length;
    return Semantics(
      label: label,
      value:
          '${FrostedFormat.money(saved.last)} of '
          '${FrostedFormat.money(target, cents: false)}',
      child: ExcludeSemantics(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LayoutBuilder(
              builder: (context, box) {
                final w = box.maxWidth.isFinite
                    ? box.maxWidth
                    : _unboundedWidth;
                final g = _goal(w, h, gutter);
                final end = g.projectionEnd;
                final below = end != null && end.dy > g.targetY;
                return SizedBox(
                  height: h,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _GoalPainter(g, t.charts, hue),
                        ),
                      ),
                      for (final (value, y) in g.grid)
                        FrostedChartLabel(
                          span: TextSpan(text: value),
                          at: Offset(w, y),
                          anchor: FrostedLabelAnchor.gridEnd,
                          style: t.textTheme.labelSmall.c(
                            t.colorScheme.textTertiary,
                          ),
                        ),
                      FrostedChartLabel(
                        span: TextSpan(
                          text:
                              'Target ${FrostedFormat.money(target, cents: false)}',
                        ),
                        at: Offset(0, g.targetY),
                        anchor: FrostedLabelAnchor.ruleStart,
                        style: t.textTheme.labelSmall,
                      ),
                      if (end != null)
                        FrostedChartLabel(
                          span: TextSpan(text: _endLabel),
                          at: end,
                          anchor: below
                              ? FrostedLabelAnchor.endDown
                              : FrostedLabelAnchor.endUp,
                          // Under the end of a rising projection the dashes
                          // run back down under the label: it drops by the
                          // rise over its own width.
                          slope: end.dx > g.today.dx
                              ? (g.today.dy - end.dy) / (end.dx - g.today.dx)
                              : 0,
                          style: t.textTheme.labelSmall,
                        ),
                    ],
                  ),
                );
              },
            ),
            if (marks.isNotEmpty)
              FrostedDaysAxis(
                words: FrostedAxisMark.words(marks, columns),
                // .x-days--w { margin-right: 40px } (48 from 1024): the
                // trail's own gutter.
                endInset: gutter,
              ),
          ],
        ),
      ),
    );
  }

  String get _endLabel {
    final money = FrostedFormat.money(projection.last, cents: false);
    final by = endDate;
    if (by == null) return money;
    return '$money by ${FrostedFormat.month(by, short: true, year: true)}';
  }

  _Goal _goal(double w, double h, double gutter) {
    // goal_line(): months are columns as on the net worth chart; the grid
    // spans the saved values, the projection and the target.
    const padTop = 16.0;
    const padBot = 6.0;
    final plot = w - gutter;
    final n = saved.length + projection.length;
    // Saved money stands on $0, as bars do: with the floor a fifth of a
    // span under the lowest line, the plot ran on below $0 and its dates
    // hung under an empty band (self-review rounds 4 and 5).
    final range = frostedValueRange(
      [...saved, ...projection, target],
      lines: lines,
      zero: true,
    );
    final hi = range.hi;
    final lo = range.lo;
    double y(num v) => padTop + (hi - v) / (hi - lo) * (h - padTop - padBot);
    final pts = [
      for (final (i, v) in saved.indexed) Offset(frostedSlot(i, n, plot), y(v)),
    ];
    final ahead = [
      pts.last,
      for (final (i, v) in projection.indexed)
        Offset(frostedSlot(saved.length + i, n, plot), y(v)),
    ];
    final line = pts.length > 2
        ? frostedMonotonePath(pts)
        : frostedPolyline(pts);
    // The light under the saved line stands on $0, the floor.
    final gridYs = [for (final g in range.grid) y(g)];
    final floor = y(0);
    final area = Path.from(line)
      ..lineTo(pts.last.dx, floor)
      ..lineTo(pts.first.dx, floor)
      ..close();
    return _Goal(
      line: line,
      area: area,
      areaTop: y(saved.reduce(math.max)),
      first: pts.first,
      today: pts.last,
      ahead: projection.isEmpty ? null : frostedPolyline(ahead),
      projectionEnd: projection.isEmpty ? null : ahead.last,
      targetY: y(target),
      plot: plot,
      gridYs: gridYs,
      grid: [
        for (final g in range.grid.reversed) (frostedDollarsShort(g), y(g)),
      ],
    );
  }
}

class _Goal {
  const _Goal({
    required this.line,
    required this.area,
    required this.areaTop,
    required this.first,
    required this.today,
    required this.ahead,
    required this.projectionEnd,
    required this.targetY,
    required this.plot,
    required this.gridYs,
    required this.grid,
  });

  final Path line;
  final Path area;
  final double areaTop;
  final Offset first;
  final Offset today;
  final Path? ahead;
  final Offset? projectionEnd;
  final double targetY;
  final double plot;
  final List<double> gridYs;
  final List<(String, double)> grid;
}

class _GoalPainter extends CustomPainter {
  const _GoalPainter(this.g, this.inks, this.hue);

  final _Goal g;
  final FrostedChartInks inks;
  final FrostedHue hue;

  @override
  void paint(Canvas canvas, Size size) {
    frostedPaintGrid(canvas, g.gridYs, g.plot, inks.grid);
    // The target: dots 1.5 wide, 1.5 on and 5 off, in the pace ink.
    final target = Path()
      ..moveTo(0, g.targetY)
      ..lineTo(g.plot, g.targetY);
    canvas.drawPath(
      frostedDashes(target, const [1.5, 5]),
      frostedRulePaint(inks.pace, 1.5),
    );
    canvas.drawPath(g.area, frostedAreaPaint(g.areaTop, size.height, inks));
    final ahead = g.ahead;
    final end = g.projectionEnd;
    if (ahead != null && end != null) {
      // The projection: 2.5 wide, 2 on and 6 off, round capped, the goal's
      // first stop at today turning to its second at the end.
      canvas.drawPath(
        frostedDashes(ahead, const [2, 6]),
        frostedLinePaint(ui.Gradient.linear(g.today, end, [hue.a, hue.b])),
      );
      frostedPaintEndDot(canvas, end, inks, ink: hue.b, halo: false);
    }
    canvas.drawPath(
      g.line,
      frostedLinePaint(frostedSpectrum(g.first, g.today, inks.line)),
    );
    frostedPaintEndDot(canvas, g.today, inks);
  }

  @override
  bool shouldRepaint(_GoalPainter old) => true;
}

/// What a key's line stands for: the spectrum line, the pace's dots, or a
/// goal's projection dashes.
enum FrostedKeySwatch {
  /// The spent or saved line: the spectrum, violet to rose (`.k-line`).
  line,

  /// The budget pace: dots 4 on and 3 off in the pace ink (`.k-pace`).
  pace,

  /// A projection: dashes 2 on and 4 off, 2.5 tall, in the goal's hue
  /// (`.k-proj`).
  projection,
}

/// One entry of a chart's key: a line 16 by 2 in its [swatch], then its
/// word 8 on in 12/1 in the second ink; a [figure] follows the word's dot
/// 8 on, in the page ink in the display face ("Spent · $2,486.12"). A
/// projection swatch takes the goal's [hue].
///
/// ```dart
/// FrostedKey(FrostedKeySwatch.pace, 'Budget pace')
/// ```
class FrostedKey extends StatelessWidget {
  /// Creates a [FrostedKey].
  const FrostedKey(this.swatch, this.label, {this.figure, this.hue, super.key})
    : assert(
        swatch != FrostedKeySwatch.projection || hue != null,
        'a projection key takes its goal\'s hue',
      );

  /// How the key's swatch is drawn.
  final FrostedKeySwatch swatch;

  /// What the key names.
  final String label;

  /// A figure after the word, in the page ink.
  final String? figure;

  /// The goal's hue, for a projection.
  final FrostedHue? hue;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    final figure = this.figure;
    final key = Row(
      mainAxisSize: MainAxisSize.min,
      spacing: FrostedChromeMetrics.keyGap,
      children: [
        CustomPaint(
          size: Size(16, swatch == FrostedKeySwatch.projection ? 2.5 : 2),
          painter: _SwatchPainter(swatch, t.charts, hue?.a),
        ),
        // The words may wrap in a narrow line, as an inline-flex key's do.
        // .key { font: 500 12px/1; color: var(--ink-2) }
        Flexible(
          child: Text(
            figure == null ? label : '$label ·',
            style: t.textTheme.labelSmall,
          ),
        ),
        // `.key` is a flex box and its `b.num` an item of its own: the
        // figure stands the key's 8 after the dot (the words' last space
        // collapses), in the page ink on the display face.
        if (figure != null)
          Text(
            figure,
            style: t.textTheme.labelSmall.display.tabular.c(
              t.colorScheme.textPrimary,
            ),
          ),
      ],
    );
    if (figure == null) return key;
    return Semantics(
      label: '$label · $figure',
      excludeSemantics: true,
      child: key,
    );
  }
}

class _SwatchPainter extends CustomPainter {
  const _SwatchPainter(this.swatch, this.inks, this.hue);

  final FrostedKeySwatch swatch;
  final FrostedChartInks inks;
  final Color? hue;

  @override
  void paint(Canvas canvas, Size size) {
    final box = Offset.zero & size;
    canvas.clipRRect(
      RRect.fromRectAndRadius(box, Radius.circular(size.height / 2)),
    );
    switch (swatch) {
      case FrostedKeySwatch.line:
        // .k-line { background: linear-gradient(90deg, #747BD9, #D76A88) }
        canvas.drawRect(
          box,
          Paint()
            ..shader = ui.Gradient.linear(Offset.zero, Offset(size.width, 0), [
              inks.line.first,
              inks.line.last,
            ]),
        );
      case FrostedKeySwatch.pace:
        _dashes(canvas, size, 4, 7, inks.pace);
      case FrostedKeySwatch.projection:
        _dashes(canvas, size, 2, 6, hue ?? inks.line.first);
    }
  }

  /// `repeating-linear-gradient(90deg, ink 0 on, transparent on period)`.
  void _dashes(Canvas canvas, Size size, double on, double period, Color ink) {
    final path = Path();
    for (var x = 0.0; x < size.width; x += period) {
      path.addRect(
        Rect.fromLTWH(x, 0, math.min(on, size.width - x), size.height),
      );
    }
    canvas.drawPath(path, Paint()..color = ink);
  }

  @override
  bool shouldRepaint(_SwatchPainter old) =>
      old.swatch != swatch || old.inks != inks || old.hue != hue;
}

/// A chart's key: its [keys] in a line 16 apart, wrapping (`.cum-legend`),
/// or 12 apart in a chart's head ([inHead], `.keys`).
///
/// ```dart
/// FrostedChartKey(keys: const [FrostedKey(FrostedKeySwatch.line, 'Spent', figure: '\$2,486.12'), FrostedKey(FrostedKeySwatch.pace, 'Budget pace')])
/// ```
class FrostedChartKey extends StatelessWidget {
  /// Creates a [FrostedChartKey].
  const FrostedChartKey({required this.keys, this.inHead = false, super.key});

  /// The keys, in order.
  final List<FrostedKey> keys;

  /// In a chart's head row, beside its caption: the keys 12 apart.
  final bool inHead;

  @override
  Widget build(BuildContext context) {
    final gap = inHead
        ? FrostedChromeMetrics.keysGapHead
        : FrostedChromeMetrics.keysGap;
    return Wrap(
      spacing: gap,
      runSpacing: FrostedSpacing.s8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: keys,
    );
  }
}
