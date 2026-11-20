/// Clay's charts: lines and areas laid on a well, bars and slices moulded in
/// pastel clay, and sparklines beside a figure.
library;

import 'package:material_ui/material_ui.dart';
import 'package:clay_ui/clay_ui.dart';

import '../kit.dart';

const _week = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

List<ClayChartPoint> _points(List<double> values) => [
  for (final (i, v) in values.indexed) ClayChartPoint(i.toDouble(), v),
];

/// The charts page.
Widget kitChartsDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Charts',
  sections: const [
    KitSection(
      title: 'Lines',
      note:
          'Each series a line of rolled clay; a pointer or the arrow keys '
          'pick a day and its readings rise beside it.',
      children: [_Lines()],
    ),
    KitSection(
      title: 'Areas',
      note: 'The same line with the clay under it filled to the floor.',
      children: [_Area()],
    ),
    KitSection(
      title: 'Bars',
      note:
          'Each bar a raised slab of clay; the picked day lifts and its band '
          'dents the well.',
      children: [_Bars()],
    ),
    KitSection(
      title: 'Slices',
      note: 'A ring of clay, a slice to each share, the total in its hole.',
      children: [_Slices()],
    ),
    KitSection(
      title: 'Sparklines',
      note: 'A week at a glance beside its figure.',
      children: [_Sparks()],
    ),
  ],
);

class _Lines extends StatelessWidget {
  const _Lines();

  @override
  Widget build(BuildContext context) => ClayCard(
    child: ClayLineChart(
      semanticLabel: 'Glasses of water a day, this week and last',
      xAxis: ClayChartXAxis.band,
      categories: _week,
      yIncludesZero: true,
      series: [
        ClayChartSeries(
          label: 'This week',
          points: _points(const [5, 7, 6, 8, 7, 8, 6]),
        ),
        ClayChartSeries(
          label: 'Last week',
          points: _points(const [4, 5, 5, 6, 4, 7, 5]),
        ),
      ],
    ),
  );
}

class _Area extends StatelessWidget {
  const _Area();

  @override
  Widget build(BuildContext context) => ClayCard(
    child: ClayAreaChart(
      semanticLabel: 'Minutes read a day',
      xAxis: ClayChartXAxis.band,
      categories: _week,
      formatY: (v) => '${v.round()} min',
      series: [
        ClayChartSeries(
          label: 'Minutes',
          points: _points(const [12, 20, 15, 25, 18, 30, 22]),
        ),
      ],
    ),
  );
}

class _Bars extends StatelessWidget {
  const _Bars();

  @override
  Widget build(BuildContext context) => ClayCard(
    child: ClayBarChart(
      semanticLabel: 'Glasses of water a day, morning and evening',
      categories: _week,
      series: [
        ClayChartSeries(
          label: 'Morning',
          points: _points(const [4, 3, 5, 4, 3, 2, 4]),
        ),
        ClayChartSeries(
          label: 'Evening',
          points: _points(const [3, 4, 3, 4, 4, 3, 3]),
        ),
      ],
    ),
  );
}

class _Slices extends StatelessWidget {
  const _Slices();

  @override
  Widget build(BuildContext context) => const ClayCard(
    child: ClayPieChart(
      semanticLabel: 'Minutes by habit this week',
      centerLabel: '5 h',
      centerCaption: 'this week',
      formatValue: _minutes,
      slices: [
        ClayPieSlice(label: 'Walk', value: 140),
        ClayPieSlice(label: 'Read', value: 95),
        ClayPieSlice(label: 'Stretch', value: 65),
        ClayPieSlice(label: 'Breathe', value: 30),
      ],
    ),
  );
}

String _minutes(double v) => '${v.round()} min';

class _Sparks extends StatelessWidget {
  const _Sparks();

  @override
  Widget build(BuildContext context) {
    final theme = ClayTheme.of(context);
    Widget row(String label, String figure, List<double> values) => Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: theme.textTheme.secondary),
              Text(
                figure,
                style: theme.textTheme.headline.copyWith(
                  color: theme.colors.ink,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: ClaySpacing.regular),
        ClaySparkline(
          semanticLabel: '$label this week',
          width: 140,
          values: values,
        ),
      ],
    );
    return ClayCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          row('Water', '6.7 a day', const [5, 7, 6, 8, 7, 8, 6]),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: ClaySpacing.regular),
            child: ClayGroove(),
          ),
          row('Sleep', '7 h 10', const [6.5, 7, 7.5, 6.8, 7.2, 8, 7.1]),
        ],
      ),
    );
  }
}
