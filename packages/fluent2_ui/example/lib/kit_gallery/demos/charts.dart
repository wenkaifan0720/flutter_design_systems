/// The charts' marks: sparklines in the brand and the categorical hues
/// (with and without the area wash), the bar chart of a week's meeting
/// hours with one day picked, and the hues in their fixed order.
library;

import 'package:flutter/material.dart';
import 'package:fluent2_ui/fluent2_ui.dart';

import '../kit.dart';

const List<Fluent2Bar> _hours = [
  Fluent2Bar('Mon', 3, valueText: '3 h'),
  Fluent2Bar('Tue', 5, valueText: '5 h'),
  Fluent2Bar('Wed', 6.5, valueText: '6.5 h'),
  Fluent2Bar('Thu', 2, valueText: '2 h'),
  Fluent2Bar('Fri', 4, valueText: '4 h'),
];

Widget kitChartsDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Charts',
  sections: [
    kitSection('Sparklines', children: [kitSpecimenSparklines()]),
    kitSection('Bar chart', children: [kitSpecimenBarChart()]),
    kitSection('Pick a bar', children: [const _PickBar()]),
    kitSection('Every bar full', children: [kitSpecimenBarChartPlain()]),
    kitSection('Line chart', children: [kitSpecimenLineChart()]),
    kitSection('Area chart', children: [kitSpecimenAreaChart()]),
    kitSection('Pie chart', children: [kitSpecimenPieChart()]),
    kitSection(
      'Hues, in order',
      children: [
        Builder(
          builder: (context) {
            final t = context.fluent2Theme;
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: Fluent2Spacing.s,
              children: [
                for (final hue in [
                  Fluent2ChartHue.brand,
                  ...Fluent2ChartHue.categorical,
                  Fluent2ChartHue.neutral,
                ])
                  Row(
                    spacing: Fluent2Spacing.s,
                    children: [
                      Container(
                        width: 24,
                        height: 12,
                        decoration: BoxDecoration(
                          color: hue.of(t),
                          borderRadius: BorderRadius.circular(
                            Fluent2Radius.small,
                          ),
                        ),
                      ),
                      Text(kitSay(hue), style: t.caption1.c(t.textSecondary)),
                    ],
                  ),
              ],
            );
          },
        ),
      ],
    ),
  ],
);

/// Files shared, messages and storage this week.
Widget kitSpecimenSparklines() => Builder(
  builder: (context) {
    final t = context.fluent2Theme;
    // The figure keeps its whole width; the name and the line share the
    // rest, the name running on to a second line at a large text size.
    Widget line(String name, String figure, Fluent2Sparkline spark) => Row(
      spacing: Fluent2Spacing.m,
      children: [
        Expanded(
          flex: 3,
          child: Text(
            name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: t.body1.c(t.textPrimary),
          ),
        ),
        Flexible(
          flex: 2,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 120),
            child: spark,
          ),
        ),
        Text(
          figure,
          softWrap: false,
          style: t.body1Strong.tabular.c(t.textPrimary),
        ),
      ],
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      spacing: Fluent2Spacing.m,
      children: [
        line(
          'Files shared',
          '1,284',
          const Fluent2Sparkline(
            values: [820, 940, 910, 1080, 1010, 1190, 1284],
            area: true,
            label: 'Files shared this week',
          ),
        ),
        line(
          'Messages',
          '642',
          const Fluent2Sparkline(
            values: [510, 580, 720, 690, 600, 655, 642],
            hue: Fluent2ChartHue.pumpkin,
            label: 'Messages this week',
          ),
        ),
        line(
          'Storage',
          '9.4 GB',
          const Fluent2Sparkline(
            values: [7.9, 8.1, 8.4, 8.6, 8.9, 9.1, 9.4],
            hue: Fluent2ChartHue.forest,
            area: true,
            label: 'Storage this week',
          ),
        ),
      ],
    );
  },
);

/// The week's meeting hours, Wednesday highlighted.
Widget kitSpecimenBarChart() => const Fluent2BarChart(
  label: 'Meeting hours this week',
  highlight: 2,
  bars: _hours,
);

/// The same week with no day picked.
Widget kitSpecimenBarChartPlain() => const Fluent2BarChart(
  label: 'Meeting hours this week',
  hue: Fluent2ChartHue.cornflower,
  height: 140,
  bars: _hours,
);

const _week = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];

/// Files shared by you, your team and the company over a week: three
/// series, each named at its line's end and in the legend.
Widget kitSpecimenLineChart() => const Fluent2LineChart(
  label: 'Files shared this week',
  labels: _week,
  series: [
    Fluent2ChartSeries('You', [3, 5, 4, 7, 6]),
    Fluent2ChartSeries('Team', [8, 11, 9, 14, 12]),
    Fluent2ChartSeries('Company', [18, 16, 21, 19, 24]),
  ],
);

/// Storage used over six months, one washed series.
Widget kitSpecimenAreaChart() => Fluent2AreaChart(
  label: 'Storage used',
  labels: const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'],
  series: const [
    Fluent2ChartSeries('Used', [212, 260, 318, 351, 402, 455]),
  ],
  valueLabel: (v) => '${v.round()} GB',
);

/// Where the storage goes: the donut with the space used in the hole.
Widget kitSpecimenPieChart() => Builder(
  builder: (context) {
    final t = context.fluent2Theme;
    return Fluent2PieChart(
      label: 'Storage by kind',
      slices: const [
        Fluent2PieSlice('Documents', 410, valueText: '410 GB'),
        Fluent2PieSlice('Photos', 260, valueText: '260 GB'),
        Fluent2PieSlice('Video', 180, valueText: '180 GB'),
        Fluent2PieSlice('Other', 70, valueText: '70 GB'),
      ],
      center: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('920 GB', style: t.subtitle1.c(t.textPrimary)),
          Text('used', style: t.caption1.c(t.textSecondary)),
        ],
      ),
    );
  },
);

class _PickBar extends StatefulWidget {
  const _PickBar();

  @override
  State<_PickBar> createState() => _PickBarState();
}

class _PickBarState extends State<_PickBar> {
  int _day = 4;

  @override
  Widget build(BuildContext context) => Fluent2BarChart(
    label: 'Meeting hours this week',
    highlight: _day,
    onHighlight: (i) => setState(() => _day = i),
    bars: _hours,
  );
}
