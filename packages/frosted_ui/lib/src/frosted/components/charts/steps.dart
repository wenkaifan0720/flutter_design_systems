import 'package:flutter/widgets.dart';

import '../../chrome_metrics.dart';
import '../../format.dart';
import '../../internal/chart_parts.dart';
import '../../theme.dart';
import 'bars.dart' show FrostedAxisMark;

/// The width a chart draws at when nothing bounds it: the pilot's phone
/// tile interior.
const double _unboundedWidth = 326;

/// One step of a [FrostedStepsChart]: the [day] it falls due, its [amount]
/// and its [name], set beside its step when it is among the largest.
///
/// ```dart
/// FrostedStep(12, 1326.44, 'Credit card')
/// ```
@immutable
class FrostedStep {
  /// Creates a [FrostedStep].
  const FrostedStep(this.day, this.amount, this.name);

  /// The day of the month, from 1.
  final int day;

  /// The step's sum.
  final num amount;

  /// What the step is.
  final String name;
}

/// A month's bills added up: $0 on the 1st, a step up at the centre of
/// each bill's day, flat to the month's end, the spectrum line over its
/// light ringed at the total; the [named] largest steps carry their names
/// and whole-dollar amounts beside them; hairline gridlines on a nice step
/// from $0 with their values at the end, and [marks] under the plot. Sized
/// by its width; [height] is the plot's.
///
/// ```dart
/// FrostedStepsChart(steps: const [FrostedStep(1, 1150, 'Rent'), FrostedStep(12, 1326.44, 'Credit card')], daysInMonth: 30, marks: novemberAxis, label: 'November bills, added up through the month')
/// ```
class FrostedStepsChart extends StatelessWidget {
  /// Creates a [FrostedStepsChart].
  const FrostedStepsChart({
    required this.steps,
    required this.daysInMonth,
    required this.label,
    this.named = 2,
    this.marks = const <FrostedAxisMark>[],
    this.lines = 3,
    this.height,
    super.key,
  });

  /// The bills in date order.
  final List<FrostedStep> steps;

  /// How many days the month has.
  final int daysInMonth;

  /// What a screen reader calls the chart.
  final String label;

  /// How many of the largest steps are named.
  final int named;

  /// The words under the plot.
  final List<FrostedAxisMark> marks;

  /// How many gridlines the chart aims for.
  final int lines;

  /// The plot's height; the source's for the width when null.
  final double? height;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    final wide = FrostedBreakpoints.isWide(context);
    final gutter = FrostedChartGutter.bars.of(wide);
    final h = height ?? (wide ? 170.0 : 150.0);
    final total = steps.fold<num>(0, (sum, s) => sum + s.amount);
    return Semantics(
      label: label,
      value: FrostedFormat.money(total),
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
                final g = _steps(w, h, gutter, total);
                return SizedBox(
                  height: h,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned.fill(
                        child: CustomPaint(painter: _StepsPainter(g, t.charts)),
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
                      for (final (step, at) in g.named)
                        FrostedChartLabel(
                          span: TextSpan(
                            text: '${step.name} ',
                            children: [
                              // .mk-step b { font-weight: 600; color: ink }
                              // on .num: the display face, tabular.
                              TextSpan(
                                text: FrostedFormat.money(
                                  step.amount,
                                  cents: false,
                                ),
                                style: t
                                    .textTheme
                                    .labelSmall
                                    .semibold
                                    .display
                                    .tabular
                                    .c(t.colorScheme.textPrimary),
                              ),
                            ],
                          ),
                          at: at,
                          anchor: FrostedLabelAnchor.noteStep,
                          // .mk { font: 500 12px/1; color: var(--ink-2) }
                          style: t.textTheme.labelSmall,
                        ),
                    ],
                  ),
                );
              },
            ),
            if (marks.isNotEmpty)
              FrostedDaysAxis(
                words: FrostedAxisMark.words(marks, daysInMonth),
                endInset: wide
                    ? FrostedChromeMetrics.chartLabelsEndGapWide
                    : gutter,
              ),
          ],
        ),
      ),
    );
  }

  _Steps _steps(double w, double h, double gutter, num total) {
    // cum_steps(): the grid on a nice step from $0 to the total.
    const padTop = 12.0;
    final plot = w - gutter;
    final floor = h - 1;
    final range = frostedValueRange([0, total], lines: lines, zero: true);
    final hi = range.hi;
    double y(num v) => padTop + (hi - v) / hi * (floor - padTop);
    double xc(int d) => (d - 0.5) / daysInMonth * plot;
    num run = 0;
    final line = Path()..moveTo(0, y(0));
    final risers = <(FrostedStep, Offset)>[];
    for (final step in steps) {
      final x = xc(step.day);
      final y0 = y(run);
      run += step.amount;
      final y1 = y(run);
      line
        ..lineTo(x, y0)
        ..lineTo(x, y1);
      risers.add((step, Offset(x, (y0 + y1) / 2)));
    }
    line.lineTo(plot, y(run));
    final area = Path.from(line)
      ..lineTo(plot, h)
      ..lineTo(0, h)
      ..close();
    final largest = [...risers]
      ..sort((a, b) => b.$1.amount.compareTo(a.$1.amount));
    return _Steps(
      line: line,
      area: area,
      areaTop: y(total),
      end: Offset(plot, y(total)),
      plot: plot,
      gridYs: [for (final g in range.grid) y(g)],
      grid: [
        for (final g in range.grid.reversed) (frostedDollarsShort(g), y(g)),
      ],
      named: largest.take(named).toList(),
    );
  }
}

class _Steps {
  const _Steps({
    required this.line,
    required this.area,
    required this.areaTop,
    required this.end,
    required this.plot,
    required this.gridYs,
    required this.grid,
    required this.named,
  });

  final Path line;
  final Path area;
  final double areaTop;
  final Offset end;
  final double plot;
  final List<double> gridYs;
  final List<(String, double)> grid;
  final List<(FrostedStep, Offset)> named;
}

class _StepsPainter extends CustomPainter {
  const _StepsPainter(this.g, this.inks);

  final _Steps g;
  final FrostedChartInks inks;

  @override
  void paint(Canvas canvas, Size size) {
    frostedPaintGrid(canvas, g.gridYs, g.plot, inks.grid);
    canvas.drawPath(g.area, frostedAreaPaint(g.areaTop, size.height, inks));
    canvas.drawPath(
      g.line,
      frostedLinePaint(
        frostedSpectrum(Offset.zero, Offset(g.plot, 0), inks.line),
      ),
    );
    frostedPaintEndDot(canvas, g.end, inks);
  }

  @override
  bool shouldRepaint(_StepsPainter old) => true;
}
