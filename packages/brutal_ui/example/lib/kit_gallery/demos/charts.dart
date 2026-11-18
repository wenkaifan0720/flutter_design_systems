import 'package:material_ui/material_ui.dart';
import 'package:brutal_ui/brutal_ui.dart';

import '../kit.dart';

/// Charts drawn flat: lines on square markers, areas under an ink line,
/// ink-edged bars, wedges divided by rules, and a sparkline in a row.
Widget kitChartsDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Charts',
  sections: const [_Charts()],
);

const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

class _Charts extends StatelessWidget {
  const _Charts();

  @override
  Widget build(BuildContext context) => const Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      KitSection(
        title: 'Line',
        note: 'Heavy lines, each value on a square; thin grid, ink axes.',
        children: [
          BrutalLineChart(
            semanticLabel: 'Tickets sold by night',
            labels: _days,
            series: [
              BrutalSeries('This week', [120, 180, 150, 210, 340, 390, 160]),
              BrutalSeries('Last week', [100, 140, 170, 160, 300, 350, 120]),
            ],
          ),
        ],
      ),
      SizedBox(height: BrutalSpacing.extraLarge),
      KitSection(
        title: 'Bar',
        children: [
          BrutalBarChart(
            semanticLabel: 'Sold by venue',
            labels: ['Shed', 'Dock 4', 'Cellar', 'Glass'],
            series: [
              BrutalSeries('Standing', [340, 275, 64, 150]),
              BrutalSeries('Seated', [120, 80, 40, 96]),
            ],
          ),
        ],
      ),
      SizedBox(height: BrutalSpacing.extraLarge),
      KitSection(
        title: 'Area',
        children: [
          BrutalAreaChart(
            semanticLabel: 'Visits by day',
            labels: _days,
            series: [
              BrutalSeries('Visits', [820, 940, 760, 1100, 1650, 1900, 1200]),
            ],
          ),
        ],
      ),
      SizedBox(height: BrutalSpacing.extraLarge),
      KitSection(
        title: 'Pie and donut',
        note: 'Flat wedges divided by rules; the legend gives each share.',
        children: [
          BrutalPieChart(
            semanticLabel: 'Tickets by type',
            slices: [
              BrutalSlice('Standing', 340),
              BrutalSlice('Seated', 120),
              BrutalSlice('Guest list', 40),
            ],
          ),
          BrutalPieChart(
            semanticLabel: 'Where buyers came from',
            donut: true,
            slices: [
              BrutalSlice('Search', 48),
              BrutalSlice('Friends', 30),
              BrutalSlice('Listings', 22),
            ],
          ),
        ],
      ),
      SizedBox(height: BrutalSpacing.extraLarge),
      KitSection(
        title: 'Sparkline',
        note: 'A trend in a row: no axes, the last value on a square.',
        children: [
          Row(
            children: [
              Expanded(child: Text('Sales this week')),
              BrutalSparkline(
                semanticLabel: 'Sales this week',
                values: [3, 5, 4, 8, 7, 11, 9],
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

// Catalog specimens (metadata.yaml): one still per part, drawn the same in
// every preset; the stage chooses the preset.

Widget kitSpecimenLineChart() => const BrutalLineChart(
  semanticLabel: 'Tickets sold this week',
  labels: _days,
  series: [
    BrutalSeries('This week', [120, 180, 150, 210, 260, 340, 190]),
    BrutalSeries('Last week', [100, 140, 160, 170, 230, 300, 210]),
  ],
);

Widget kitSpecimenAreaChart() => const BrutalAreaChart(
  semanticLabel: 'Visits this week',
  labels: _days,
  series: [
    BrutalSeries('Visits', [820, 940, 760, 1010, 1240, 1500, 980]),
  ],
);

Widget kitSpecimenBarChart() => const BrutalBarChart(
  semanticLabel: 'Tickets sold by night',
  labels: _days,
  series: [
    BrutalSeries('Sold', [120, 180, 150, 210, 260, 340, 190]),
  ],
);

Widget kitSpecimenPieChart() => const Center(
  child: BrutalPieChart(
    semanticLabel: 'Tickets by kind',
    slices: [
      BrutalSlice('Standing', 340),
      BrutalSlice('Seated', 120),
      BrutalSlice('Boxes', 40),
    ],
  ),
);

Widget kitSpecimenSparkline() => const Row(
  children: [
    Expanded(child: Text('Sold this week')),
    BrutalSparkline(
      semanticLabel: 'Sold this week, rising',
      values: [3, 5, 4, 8, 7, 11, 12],
    ),
  ],
);
