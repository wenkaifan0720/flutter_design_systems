/// Pressed wells with raised marks, on plain numbers. Marks are ink; the pigment is for now, by now: and only for that, so none of them takes a colour. A figure means what the page says it means.
library;

import 'package:flutter/material.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

import '../kit.dart';

Widget kitChartsDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Charts in wells',
  sections: [
    kitSection('Several series and a target', children: [kitSpecimenChart()]),
    kitSection('A line over time', children: [kitSpecimenLineChart()]),
    kitSection('Values side by side', children: [kitSpecimenBarChart()]),
    kitSection('An amount over time', children: [kitSpecimenAreaChart()]),
    kitSection('Parts of a whole', children: [kitSpecimenDonut()]),
    kitSection('A trend in a row', children: [kitSpecimenSparkline()]),
    kitSection('Still loading', children: [kitSpecimenChartLoading()]),
    kitSection('Two ways over an axis', children: [kitSpecimenTwoWayBars()]),
    kitSection('Columns', children: [kitSpecimenColumnBars()]),
    kitSection(
      'A reading against a set line',
      children: [kitSpecimenStepLine()],
    ),
    kitSection('Shares of a whole', children: [kitSpecimenShareBars()]),
    kitSection('A chart key', children: [kitSpecimenChartKey()]),
  ],
);

Widget kitSpecimenTwoWayBars() => const NeumorphicTwoWayBars(
  above: [
    .6,
    .5,
    .5,
    .6,
    1.1,
    1.6,
    1.4,
    .7,
    .5,
    .4,
    .4,
    .5,
    .9,
    1.3,
    1.8,
    1.9,
    1.5,
    .3,
  ],
  below: {8: .3, 9: .5, 10: .6, 11: .5, 12: .3},
  now: 17.5,
  peak: '1.9',
  labels: {0: '00', 6: '06', 12: '12'},
  nowLabel: '17:30',
  keys: [
    NeumorphicLegendItem('Out, per hour'),
    NeumorphicLegendItem('Back, per hour', kind: NeumorphicLegendSwatch.live),
  ],
);

Widget kitSpecimenColumnBars() => const NeumorphicColumnBars(
  values: [23.9, 22.1, 25.3, 24.7, 21.8, 22.4, 17.8],
  labels: ['Thu', 'Fri', 'Sat', 'Sun', 'Mon', 'Tue', 'Wed'],
  now: 6,
  forecast: 20.6,
  nowLabel: 'Today',
  forecastLabel: 'Forecast for tonight',
);

Widget kitSpecimenStepLine() => const NeumorphicStepLine(
  readings: [
    (0, 50),
    (3, 48),
    (6, 49),
    (8, 62),
    (10, 52),
    (12, 46),
    (14, 44),
    (16, 58),
    (18, 64),
    (20, 68),
  ],
  steps: [
    (0, 45),
    (6.5, 62),
    (8.2, 45),
    (15.5, 62),
    (17, 66),
    (19.75, 72),
    (22.5, 45),
    (24, 45),
  ],
  now: 20.17,
  xMax: 24,
  yMin: 40,
  yMax: 80,
  yTicks: [50, 60, 70],
  xLabels: [(0, '00'), (6, '06'), (12, '12'), (18, '18'), (24, '24')],
  keys: [
    NeumorphicLegendItem('Reading'),
    NeumorphicLegendItem('Set', kind: NeumorphicLegendSwatch.line),
  ],
  note: 'From 22:30: 40',
);

Widget kitSpecimenShareBars() => const NeumorphicShareBars(
  title: 'By kind',
  rows: [
    NeumorphicShare('The largest kind', '9.4', .53),
    NeumorphicShare('A second kind', '3.1', .17),
    NeumorphicShare('Everything else', '2.7', .15),
  ],
);

Widget kitSpecimenChartKey() => const NeumorphicLegend([
  NeumorphicLegendItem('Used'),
  NeumorphicLegendItem('Made', kind: NeumorphicLegendSwatch.live),
  NeumorphicLegendItem('Set', kind: NeumorphicLegendSwatch.line),
], note: 'A note on the same line');

Widget kitSpecimenChart() => const NeumorphicLineChart(
  label: 'Hours slept',
  labels: ['M', 'T', 'W', 'T', 'F'],
  band: NeumorphicChartBand(7, 9, label: 'Goal'),
  series: [
    NeumorphicChartSeries('This week', [7.5, 6, null, 8, 7]),
    NeumorphicChartSeries('Last week', [6, 7, 8, 7, 6.5]),
  ],
);

Widget kitSpecimenLineChart() => const NeumorphicLineChart(
  label: 'Hours slept',
  labels: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'],
  series: [
    NeumorphicChartSeries('Hours', [7, 8, 6, 7.5, 8]),
  ],
);

Widget kitSpecimenBarChart() => const NeumorphicBarChart(
  label: 'Lamp hours',
  labels: ['June', 'July', 'August'],
  series: [
    NeumorphicChartSeries('Bedroom', [4, 6, 5]),
    NeumorphicChartSeries('Study', [3, 5, 7]),
  ],
);

Widget kitSpecimenAreaChart() => const NeumorphicAreaChart(
  label: 'Warmth',
  labels: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'],
  series: [
    NeumorphicChartSeries('Warmth', [18, 20, 19, 21, 20]),
  ],
);

/// The week's rain as an area: the specimen the catalog's chart card has shown since before the area chart.
Widget kitSpecimenChartArea() => const NeumorphicAreaChart(
  label: 'Rain this week',
  labels: ['M', 'T', 'W', 'T', 'F', 'S', 'S'],
  series: [
    NeumorphicChartSeries('Rain, mm', [2, 5, 9, 4, 1, 0, 3]),
  ],
);

Widget kitSpecimenDonut() => const NeumorphicPieChart(
  label: 'Where the energy went',
  caption: 'kWh today',
  slices: [
    NeumorphicPieSlice('Heating', 9.2),
    NeumorphicPieSlice('Water', 3.1),
    NeumorphicPieSlice('Kitchen', 2.4),
    NeumorphicPieSlice('Other', 1.3),
  ],
);

Widget kitSpecimenSparkline() => Builder(
  builder: (context) {
    final t = NeumorphicTheme.of(context);
    // In a well as wide as the charts beside it, the line by its figure: across the whole column it stood 500 px from
    // its words and past the cards' edge.
    return Align(
      alignment: AlignmentDirectional.topStart,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: NeumorphicWell(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Steps this week', style: t.textTheme.caption),
                    Text('7,300 a day', style: t.textTheme.value),
                  ],
                ),
              ),
              const NeumorphicSparkline(
                label: 'Steps this week',
                values: [4.2, 6.1, 5.0, 7.3, 6.8, 8.1, 7.3],
              ),
            ],
          ),
        ),
      ),
    );
  },
);

Widget kitSpecimenChartLoading() =>
    const NeumorphicLineChart(label: 'Hours slept', series: [], loading: true);
