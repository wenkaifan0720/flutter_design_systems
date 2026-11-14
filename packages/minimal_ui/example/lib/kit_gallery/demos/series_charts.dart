/// Series over time and parts of a whole: line, area and donut charts,
/// with their legend, readout, loading and empty states.
library;

import 'package:flutter/material.dart';
import 'package:minimal_ui/minimal_ui.dart';

import '../kit.dart';

const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug'];

Widget kitSeriesChartsDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Line, area, donut',
  sections: [
    kitSection(
      'Line chart',
      children: [
        kitSpecimenLineChartTwo(),
        kitNote(
          'Point at it, drag a finger across, or tab to it and use the arrows.',
        ),
      ],
    ),
    kitSection('Area chart', children: [kitSpecimenAreaChartRevenue()]),
    kitSection('Donut', children: [kitSpecimenPieChartHours()]),
    // Each state named under it, so a held place never reads as a gap; each
    // at the loaded chart's own height, the place it holds.
    kitSection(
      'Loading and empty',
      children: [
        const MinimalLineChart(series: [], loading: true),
        kitNote('Loading: a skeleton holds the plot\'s place.'),
        // Each caption keeps to its own plot: more air under it than over.
        const MinimalGap(MinimalSpacing.s16),
        const MinimalLineChart(series: [], emptyLabel: 'No signups this week'),
        kitNote('Empty: the plot keeps its place and says why.'),
        const MinimalGap(MinimalSpacing.s16),
        const _EmptyDonut(),
        kitNote(
          'An empty donut: its ring at the full size, and why in the middle.',
        ),
      ],
    ),
  ],
);

/// A donut with nothing logged, standing where the full donut above stands:
/// at the start of a column wide enough for that one's legend beside it,
/// centred in a narrower one. With no parts there is no legend, so the
/// chart alone would centre its ring.
class _EmptyDonut extends StatelessWidget {
  const _EmptyDonut();

  /// The donut's own size, as the full one above takes it.
  static const double _size = 168;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      const ring = MinimalPieChart(slices: [], emptyLabel: 'No hours yet');
      // The width at which the full donut sets its legend beside it.
      if (box.maxWidth < _size + 200) return ring;
      return const Align(
        alignment: AlignmentDirectional.centerStart,
        child: SizedBox(width: _size, child: ring),
      );
    },
  );
}

// --- catalog specimens -------------------------------------------------------

/// Two plans' signups over a week.
Widget kitSpecimenLineChartTwo() => const MinimalLineChart(
  semanticLabel: 'Signups this week',
  labels: _days,
  series: [
    MinimalChartSeries('Pro', [12, 18, 15, 22, 28, 19, 24]),
    MinimalChartSeries('Free', [30, 26, 34, 31, 38, 42, 40]),
  ],
);

/// Dollars in thousands, a whole thousand without its ".0" (`$5k`, `$7.5k`).
String _thousands(double v) {
  if (v < 1000) return '\$${v.round()}';
  final k = v / 1000;
  return k == k.roundToDouble()
      ? '\$${k.round()}k'
      : '\$${k.toStringAsFixed(1)}k';
}

/// Revenue by month.
Widget kitSpecimenAreaChartRevenue() => MinimalAreaChart(
  semanticLabel: 'Revenue by month',
  labels: _months,
  format: _thousands,
  series: const [
    MinimalChartSeries('Revenue', [
      4200,
      4800,
      4600,
      5900,
      6400,
      7100,
      6900,
      8200,
    ]),
  ],
);

/// A week's hours by kind of work.
Widget kitSpecimenPieChartHours() => const MinimalPieChart(
  semanticLabel: 'Hours this week',
  centerLabel: 'Hours',
  slices: [
    MinimalChartSlice('Design', 14),
    MinimalChartSlice('Build', 18),
    MinimalChartSlice('Review', 6),
    MinimalChartSlice('Meetings', 4),
  ],
);
