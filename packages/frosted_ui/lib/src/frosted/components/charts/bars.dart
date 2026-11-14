import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../chrome_metrics.dart';
import '../../format.dart';
import '../../internal/chart_parts.dart';
import '../../theme.dart';

/// The width a chart draws at when nothing bounds it: the pilot's phone
/// tile interior.
const double _unboundedWidth = 326;

enum _BarsFace { days, months, stacked }

/// Where a [FrostedAxisMark] hangs: under its slot's centre, flush with the
/// chart's start or end (the month's first and last day), or starting at
/// its slot's centre ([slotStart]: the month's first day under a chart whose
/// days are columns).
enum FrostedAxisEdge {
  /// Under its slot's centre.
  none,

  /// Flush with the chart's start.
  start,

  /// Flush with the chart's end.
  end,

  /// Starting at its slot's centre.
  slotStart,
}

/// One word under a chart of slots: a day's, a month's, today's.
///
/// ```dart
/// FrostedAxisMark(27, 'Today', current: true)
/// ```
@immutable
class FrostedAxisMark {
  /// Under [slot]'s centre (slots from 0: the 8th is slot 7).
  const FrostedAxisMark(this.slot, this.label, {this.current = false})
    : edge = FrostedAxisEdge.none;

  /// Flush with the chart's start (the 1st, named: "Oct 1").
  const FrostedAxisMark.first(this.label, {this.current = false})
    : slot = 0,
      edge = FrostedAxisEdge.start;

  /// Flush with the chart's end (the last day).
  const FrostedAxisMark.last(this.label, {this.current = false})
    : slot = -1,
      edge = FrostedAxisEdge.end;

  /// Starting at [slot]'s centre rather than centred under it: the first
  /// day's word under a chart whose days are columns, as category.py's
  /// day_axis sets "Oct 1" (`left: (d - .5) / n`, no `.c`).
  const FrostedAxisMark.startingAt(
    this.slot,
    this.label, {
    this.current = false,
  }) : edge = FrostedAxisEdge.slotStart;

  /// The slot it names, from 0.
  final int slot;

  /// The words under the slot.
  final String label;

  /// Now (today, the month shown), in the page ink.
  final bool current;

  /// Where the words hang.
  final FrostedAxisEdge edge;

  /// The axis words of [marks] over [days] slots: a mark at its slot's
  /// centre, the first flush with the start, the last with the end; with
  /// [point], at its slot's end (a spend chart's days end where their
  /// spending stands). Plumbing of the charts.
  static List<FrostedAxisWord> words(
    List<FrostedAxisMark> marks,
    int days, {
    bool point = false,
  }) => [
    for (final m in marks)
      switch (m.edge) {
        FrostedAxisEdge.start => FrostedAxisWord(
          0,
          m.label,
          current: m.current,
          anchor: FrostedLabelAnchor.start,
        ),
        FrostedAxisEdge.end => FrostedAxisWord(
          1,
          m.label,
          current: m.current,
          anchor: FrostedLabelAnchor.end,
        ),
        FrostedAxisEdge.none => FrostedAxisWord(
          point ? (m.slot + 1) / days : (m.slot + 0.5) / days,
          m.label,
          current: m.current,
        ),
        FrostedAxisEdge.slotStart => FrostedAxisWord(
          point ? (m.slot + 1) / days : (m.slot + 0.5) / days,
          m.label,
          current: m.current,
          anchor: FrostedLabelAnchor.start,
        ),
      },
  ];
}

/// One band of a stacked chart ([FrostedDayBars.stacked]): its [hue] and a
/// value per month, in the months' order.
///
/// ```dart
/// FrostedBarSeries(theme.hues.azure, emergencyByMonth)
/// ```
@immutable
class FrostedBarSeries {
  /// Creates a [FrostedBarSeries].
  const FrostedBarSeries(this.hue, this.values);

  /// The bars' hue.
  final FrostedHue hue;

  /// One value a slot, in order.
  final List<num> values;
}

/// Pill bars of a hue's light from $0 on hairline gridlines, their values
/// at the end. The default is a month day by day: a bar for each day's
/// spending, a faint dot on the floor of a day without any, nothing for
/// the days to come, the [marks] under it. [FrostedDayBars.months] is a year
/// by month: the latest month in the hue's full light and the earlier ones
/// at .45, its [value] over the latest bar, the [months]' initials under
/// the columns (their short names from 1024 wide). [FrostedDayBars.stacked]
/// builds each month's bar of one band per [series], parted by a
/// hairline, the earlier months at half strength. Sized by its width;
/// [height] is the plot's.
///
/// ```dart
/// FrostedDayBars(values: diningByDay, daysInMonth: 31, hue: theme.hues.coral, marks: octoberAxis, label: 'Dining out, each day in October')
/// ```
class FrostedDayBars extends StatelessWidget {
  /// Creates a [FrostedDayBars].
  const FrostedDayBars({
    required this.values,
    required int this.daysInMonth,
    required FrostedHue this.hue,
    required this.label,
    this.marks = const <FrostedAxisMark>[],
    this.lines = 3,
    this.height,
    super.key,
  }) : months = const <String>[],
       current = null,
       series = const <FrostedBarSeries>[],
       value = false,
       cents = true,
       _face = _BarsFace.days;

  /// A year by month: one value per month, the latest last and lit, its
  /// [value] set over it ("+$73.42"; whole dollars with [cents] false).
  ///
  /// ```dart
  /// FrostedDayBars.months(values: interestByMonth, months: shortMonths, hue: theme.hues.seafoam, label: 'Interest earned each month')
  /// ```
  const FrostedDayBars.months({
    required this.values,
    required this.months,
    required FrostedHue this.hue,
    required this.label,
    this.current,
    this.value = true,
    this.cents = true,
    this.lines = 3,
    this.height,
    super.key,
  }) : daysInMonth = null,
       marks = const <FrostedAxisMark>[],
       series = const <FrostedBarSeries>[],
       _face = _BarsFace.months;

  /// A year by month, each bar built of the [series]' bands from the
  /// bottom, the month's total set over the latest bar.
  ///
  /// ```dart
  /// FrostedDayBars.stacked(series: [FrostedBarSeries(theme.hues.azure, emergencyByMonth), FrostedBarSeries(theme.hues.sunset, lisbonByMonth)], months: shortMonths, lines: 4, label: 'Put away each month')
  /// ```
  const FrostedDayBars.stacked({
    required this.series,
    required this.months,
    required this.label,
    this.current,
    this.value = true,
    this.cents = false,
    this.lines = 3,
    this.height,
    super.key,
  }) : values = const <num>[],
       daysInMonth = null,
       hue = null,
       marks = const <FrostedAxisMark>[],
       _face = _BarsFace.stacked;

  /// One value per day so far, or per month; dollars.
  final List<num> values;

  /// The bands of a stacked chart, the bottom one first.
  final List<FrostedBarSeries> series;

  /// The days in the month of a day face.
  final int? daysInMonth;

  /// The months' short names under a year's columns.
  final List<String> months;

  /// The month set in the page ink; the last by default.
  final int? current;

  /// The bars' hue; each band's own on a stacked chart.
  final FrostedHue? hue;

  /// What a screen reader calls the chart.
  final String label;

  /// The words under a day face's plot.
  final List<FrostedAxisMark> marks;

  /// Whether the latest bar's value is set over it.
  final bool value;

  /// Whether that value keeps its cents.
  final bool cents;

  /// How many gridlines the chart aims for.
  final int lines;

  /// The plot's height; the source's for the width when null.
  final double? height;
  final _BarsFace _face;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    final wide = FrostedBreakpoints.isWide(context);
    final gutter = FrostedChartGutter.bars.of(wide);
    final h =
        height ??
        switch (_face) {
          _BarsFace.days => wide ? 150.0 : 120.0,
          _BarsFace.months => wide ? 180.0 : 140.0,
          _BarsFace.stacked => wide ? 200.0 : 150.0,
        };
    final axis = switch (_face) {
      _BarsFace.days when marks.isNotEmpty => FrostedDaysAxis(
        words: FrostedAxisMark.words(marks, daysInMonth!),
        endInset: wide ? FrostedChromeMetrics.chartLabelsEndGapWide : gutter,
      ),
      _BarsFace.months || _BarsFace.stacked when months.isNotEmpty =>
        FrostedMonthsAxis(months: months, current: current, endInset: gutter),
      _ => null,
    };
    final latest = switch (_face) {
      _BarsFace.stacked =>
        series.isEmpty || series.first.values.isEmpty
            ? null
            : series.fold<num>(0, (sum, s) => sum + s.values.last),
      _ => values.isEmpty ? null : values.last,
    };
    return Semantics(
      label: label,
      value: latest == null ? null : FrostedFormat.money(latest, cents: cents),
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
                final g = _bars(w, h, gutter);
                return SizedBox(
                  height: h,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned.fill(
                        child: CustomPaint(painter: _BarsPainter(g, t.charts)),
                      ),
                      for (final (text, y) in g.grid)
                        FrostedChartLabel(
                          span: TextSpan(text: text),
                          at: Offset(w, y),
                          anchor: FrostedLabelAnchor.gridEnd,
                          // .y-lbl { font: 500 12px/1; color: var(--ink-3) }
                          style: t.textTheme.labelSmall.c(
                            t.colorScheme.textTertiary,
                          ),
                        ),
                      if (value && latest != null && g.valueAt != null)
                        FrostedChartLabel(
                          span: TextSpan(
                            text: FrostedFormat.money(
                              latest,
                              cents: cents,
                              sign: true,
                            ),
                          ),
                          at: g.valueAt!,
                          anchor: FrostedLabelAnchor.barValueEnd,
                          // .bar-v { font: 600 12px/1 var(--font-d);
                          // color: var(--k) }: the hue's ink, or the page's
                          // where the bars are many hues.
                          style: t.textTheme.labelSmall.semibold.display.c(
                            hue?.ink ?? t.colorScheme.textPrimary,
                          ),
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

  _Bars _bars(double w, double h, double gutter) {
    final plot = w - gutter;
    final floor = h - 1;
    switch (_face) {
      case _BarsFace.days:
        // day_bars(): a bar 56% of its day's slot, 3 to 10 wide, a full
        // pill at least; the grid on a nice step from $0.
        const padTop = 10.0;
        final n = daysInMonth!;
        final nonzero = [
          for (final v in values)
            if (v > 0) v,
        ];
        final range = frostedValueRange(
          nonzero.isEmpty ? const <num>[1] : nonzero,
          lines: lines,
          zero: true,
        );
        final hi = range.hi;
        final slot = plot / n;
        final bw = math.max(3.0, math.min(10.0, slot * 0.56));
        double y(num v) => padTop + (hi - v) / hi * (floor - padTop);
        final bars = <_Bar>[];
        final dots = <Offset>[];
        for (final (i, v) in values.indexed) {
          final cx = (i + 0.5) * slot;
          if (v <= 0) {
            dots.add(Offset(cx, floor - 1.5));
            continue;
          }
          final top = math.min(y(v), floor - bw);
          bars.add(
            _Bar(
              RRect.fromRectAndRadius(
                Rect.fromLTRB(cx - bw / 2, top, cx + bw / 2, floor),
                Radius.circular(bw / 2),
              ),
              hue!,
              1,
            ),
          );
        }
        return _Bars(
          bars: bars,
          dots: dots,
          padTop: padTop,
          floor: floor,
          floorLine: true,
          plot: plot,
          gridYs: [for (final g in range.grid) y(g)],
          grid: [
            for (final g in range.grid.reversed) (frostedDollarsShort(g), y(g)),
          ],
          valueAt: null,
        );
      case _BarsFace.months:
        // month_bars(): bars half their slot, 22 at most, the earlier
        // months at .45; the latest bar's top right corner for its value.
        const padTop = 22.0;
        final n = values.length;
        final range = frostedValueRange(
          values.isEmpty ? const <num>[1] : values,
          lines: lines,
          zero: true,
        );
        final hi = range.hi;
        final slot = plot / math.max(n, 1);
        final bw = math.min(22.0, slot * 0.5);
        double y(num v) => padTop + (hi - v) / hi * (floor - padTop);
        return _Bars(
          bars: [
            for (final (i, v) in values.indexed)
              _Bar(
                RRect.fromRectAndRadius(
                  Rect.fromLTRB(
                    (i + 0.5) * slot - bw / 2,
                    y(v),
                    (i + 0.5) * slot + bw / 2,
                    floor,
                  ),
                  Radius.circular(math.min(bw / 2, 6)),
                ),
                hue!,
                i == n - 1 ? 1 : 0.45,
              ),
          ],
          dots: const [],
          padTop: padTop,
          floor: floor,
          floorLine: false,
          plot: plot,
          gridYs: [for (final g in range.grid) y(g)],
          grid: [
            for (final g in range.grid.reversed) (frostedDollarsShort(g), y(g)),
          ],
          valueAt: n == 0
              ? null
              : Offset((n - 0.5) * slot + bw / 2, y(values.last)),
        );
      case _BarsFace.stacked:
        // stacked_months(): bars 46% of their slot, 26 at most, each band
        // parted from the next by a 2 hairline and at least 1.5 tall, the
        // earlier months at half strength.
        const padTop = 22.0;
        const gap = 2.0;
        final n = series.isEmpty ? 0 : series.first.values.length;
        final totals = [
          for (var i = 0; i < n; i++)
            series.fold<num>(0, (sum, s) => sum + s.values[i]),
        ];
        final range = frostedValueRange(
          totals.isEmpty ? const <num>[1] : totals,
          lines: lines,
          zero: true,
        );
        final hi = range.hi;
        final slot = plot / math.max(n, 1);
        final bw = math.min(26.0, slot * 0.46);
        final k = (floor - padTop) / hi;
        double y(num v) => padTop + (hi - v) / hi * (floor - padTop);
        final bars = <_Bar>[];
        for (var i = 0; i < n; i++) {
          final cx = (i + 0.5) * slot;
          final opacity = i == n - 1 ? 1.0 : 0.5;
          final segs = [
            for (final s in series)
              if (s.values[i] > 0) (s.hue, s.values[i]),
          ];
          var base = floor;
          for (final (m, (hue, v)) in segs.indexed) {
            final hh = v * k;
            final y0 = base - hh + (m < segs.length - 1 ? gap / 2 : 0);
            final y1 = base - (m > 0 ? gap / 2 : 0);
            final tall = math.max(y1 - y0, 1.5);
            bars.add(
              _Bar(
                RRect.fromRectAndRadius(
                  Rect.fromLTWH(cx - bw / 2, y0, bw, tall),
                  Radius.circular(math.min(5, math.min(tall / 2, bw / 2))),
                ),
                hue,
                opacity,
              ),
            );
            base -= hh;
          }
        }
        return _Bars(
          bars: bars,
          dots: const [],
          padTop: padTop,
          floor: floor,
          floorLine: false,
          plot: plot,
          gridYs: [for (final g in range.grid) y(g)],
          grid: [
            for (final g in range.grid.reversed) (frostedDollarsShort(g), y(g)),
          ],
          valueAt: n == 0
              ? null
              : Offset((n - 0.5) * slot + bw / 2, y(totals.last)),
        );
    }
  }
}

class _Bar {
  const _Bar(this.box, this.hue, this.opacity);

  final RRect box;
  final FrostedHue hue;
  final double opacity;
}

class _Bars {
  const _Bars({
    required this.bars,
    required this.dots,
    required this.padTop,
    required this.floor,
    required this.floorLine,
    required this.plot,
    required this.gridYs,
    required this.grid,
    required this.valueAt,
  });

  final List<_Bar> bars;
  final List<Offset> dots;
  final double padTop;
  final double floor;
  final bool floorLine;
  final double plot;
  final List<double> gridYs;
  final List<(String, double)> grid;
  final Offset? valueAt;
}

class _BarsPainter extends CustomPainter {
  const _BarsPainter(this.g, this.inks);

  final _Bars g;
  final FrostedChartInks inks;

  @override
  void paint(Canvas canvas, Size size) {
    frostedPaintGrid(canvas, g.gridYs, g.plot, inks.grid);
    if (g.floorLine) {
      // The floor, half a pixel under the bars' feet, the grid ink at .1.
      canvas.drawLine(
        Offset(0, g.floor + 0.5),
        Offset(g.plot, g.floor + 0.5),
        Paint()
          ..color = inks.grid.withValues(alpha: 0.1)
          ..strokeWidth = 1,
      );
    }
    for (final dot in g.dots) {
      // A day without spending: a dot 3 across on the floor, the grid ink
      // at .14.
      canvas.drawCircle(
        dot,
        1.5,
        Paint()..color = inks.grid.withValues(alpha: 0.14),
      );
    }
    for (final bar in g.bars) {
      canvas.drawRRect(
        bar.box,
        frostedBarPaint(bar.hue, g.padTop, g.floor, opacity: bar.opacity),
      );
    }
  }

  @override
  bool shouldRepaint(_BarsPainter old) => true;
}
