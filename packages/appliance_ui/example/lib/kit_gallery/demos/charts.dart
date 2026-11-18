import 'package:material_ui/material_ui.dart';
import 'package:appliance_ui/appliance_ui.dart';

import '../kit.dart';

/// Traces lit on a display's glass: lines, areas, bars, a donut, a
/// sparkline; and the windows while loading and empty.
Widget kitChartsDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Charts',
  sections: const [_Charts()],
);

String _pounds(double v) => '£${v.round()}';

class _Charts extends StatelessWidget {
  const _Charts();

  @override
  Widget build(BuildContext context) => const Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      KitSection(
        title: 'Lines and areas',
        note: 'Point or arrow along a trace for its readout.',
        children: [
          ApplianceLineChart(
            semanticLabel: 'Spending by month',
            labels: ['Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov'],
            valueText: _pounds,
            series: [
              ApplianceChartSeries('This year', [42, 58, 51, 66, 61, 74]),
              ApplianceChartSeries('Last year', [38, 44, 49, 47, 55, 60]),
            ],
          ),
          ApplianceAreaChart(
            semanticLabel: 'Orders by week',
            labels: ['W1', 'W2', 'W3', 'W4', 'W5', 'W6'],
            series: [
              ApplianceChartSeries('Orders', [12, 18, 15, 22, 19, 26]),
            ],
          ),
        ],
      ),
      SizedBox(height: ApplianceSpacing.extraLarge),
      KitSection(
        title: 'Bars and a donut',
        note: 'The readout\'s group stays bright; a slice\'s share lit inside.',
        children: [
          ApplianceBarChart(
            semanticLabel: 'Items by room',
            labels: ['Kitchen', 'Hall', 'Garden', 'Larder'],
            series: [
              ApplianceChartSeries('Bought', [14, 6, 9, 11]),
              ApplianceChartSeries('Returned', [2, 1, 3, 0]),
            ],
          ),
          ApplianceDonutChart(
            semanticLabel: 'Spending by room',
            valueText: _pounds,
            slices: [
              ('Kitchen', 120),
              ('Hall', 40),
              ('Garden', 64),
              ('Larder', 28),
            ],
          ),
        ],
      ),
      SizedBox(height: ApplianceSpacing.extraLarge),
      KitSection(
        title: 'Small, loading and empty',
        note:
            'A trend in a row; the ring while readings come; dashes when none.',
        children: [
          ApplianceListTile(
            title: 'Orders this week',
            trailing: ApplianceSparkline(
              values: [3, 5, 4, 7, 6, 9],
              semanticLabel: 'Orders this week, rising',
            ),
          ),
          ApplianceLineChart(
            semanticLabel: 'Spending',
            height: 140,
            loading: true,
            labels: [],
            series: [],
          ),
          ApplianceBarChart(
            semanticLabel: 'Returns',
            height: 140,
            labels: [],
            series: [],
            emptyLabel: 'No returns yet',
          ),
        ],
      ),
    ],
  );
}
