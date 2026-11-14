/// The chart group's demo: charts of a measure rather than a count — a
/// blood pressure's two numbers paired on one axis over a week (with a
/// target band) and over a month that starts after the range does, a pulse
/// and a weight on axes scaled to their data, and a sparkline in a list
/// row, a donut, a bar chart's tooltip, and a chart loading and empty. The
/// count charts (bars and an area from zero) are the content group's demo;
/// their specimens are here, with the group that claims the chart file.
library;

import 'package:flutter/widgets.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';

import '../kit.dart';

/// The chart group's demo, in [brightness].
Widget kitChartDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Chart',
  sections: const <Widget>[
    _PairedWeek(),
    SizedBox(height: kitGap * 3),
    _PairedMonth(),
    SizedBox(height: kitGap * 3),
    _Measures(),
    SizedBox(height: kitGap * 3),
    _Sparkline(),
    SizedBox(height: kitGap * 3),
    _Donut(),
    SizedBox(height: kitGap * 3),
    _Pointed(),
    SizedBox(height: kitGap * 3),
    _States(),
  ],
);

const List<String> _weekdays = <String>[
  'Mon',
  'Tue',
  'Wed',
  'Thu',
  'Fri',
  'Sat',
  'Sun',
];

/// Morning and evening readings, systolic over diastolic, one pair a day.
const List<(double, double, double, double)> _week =
    <(double, double, double, double)>[
      (131, 84, 126, 80),
      (128, 82, 133, 86),
      (124, 79, 129, 83),
      (136, 88, 127, 81),
      (129, 83, 122, 78),
      (126, 80, 131, 85),
      (128, 82, 125, 79),
    ];

/// A day's two readings at 7 AM and 8 PM, as points at their time.
(ExpressiveChartSeries, ExpressiveChartSeries) _series(
  List<(double, double, double, double)> days, {
  required String Function(int day) label,
  int from = 0,
}) {
  final systolic = <ExpressiveChartPoint>[];
  final diastolic = <ExpressiveChartPoint>[];
  for (var i = 0; i < days.length; i++) {
    final (amSys, amDia, pmSys, pmDia) = days[i];
    final day = from + i;
    systolic
      ..add(ExpressiveChartPoint(label(day), amSys, at: day + 7 / 24))
      ..add(ExpressiveChartPoint(label(day), pmSys, at: day + 20 / 24));
    diastolic
      ..add(ExpressiveChartPoint(label(day), amDia, at: day + 7 / 24))
      ..add(ExpressiveChartPoint(label(day), pmDia, at: day + 20 / 24));
  }
  return (
    ExpressiveChartSeries('Systolic', systolic),
    ExpressiveChartSeries('Diastolic', diastolic),
  );
}

class _PairedWeek extends StatelessWidget {
  const _PairedWeek();

  @override
  Widget build(BuildContext context) {
    final (systolic, diastolic) = _series(_week, label: (d) => _weekdays[d]);
    return kitSection(
      'Paired · a week, with a target band',
      children: <Widget>[
        ExpressiveChart.paired(
          first: systolic,
          second: diastolic,
          span: 7,
          ticks: <ExpressiveChartTick>[
            for (var d = 0; d < 7; d++)
              ExpressiveChartTick(d + 0.5, _weekdays[d]),
          ],
          band: const ExpressiveChartBand(80, 120, label: 'Your target'),
        ),
      ],
    );
  }
}

class _PairedMonth extends StatelessWidget {
  const _PairedMonth();

  @override
  Widget build(BuildContext context) {
    // Sep 1 – Sep 30, readings from Sep 8 on.
    final days = <(double, double, double, double)>[
      for (var i = 0; i < 23; i++) _week[i % _week.length],
    ];
    final (systolic, diastolic) = _series(
      days,
      from: 7,
      label: (d) => 'Sep ${d + 1}',
    );
    return kitSection(
      'Paired · a month, readings from the 8th',
      children: <Widget>[
        ExpressiveChart.paired(
          first: systolic,
          second: diastolic,
          span: 30,
          ticks: <ExpressiveChartTick>[
            for (var d = 0; d < 30; d++)
              ExpressiveChartTick(d + 0.5, 'Sep ${d + 1}'),
          ],
          // A no-break space: the date never splits from its month.
          emptyLabel: 'No readings before Sep\u00A08',
        ),
      ],
    );
  }
}

class _Measures extends StatelessWidget {
  const _Measures();

  static const List<double> _pulse = <double>[68, 72, 64, 70, 78, 66, 69];
  static const List<double> _weight = <double>[
    173.8,
    173.4,
    173.6,
    173.1,
    172.8,
    173.0,
    172.6,
  ];

  @override
  Widget build(BuildContext context) => kitSection(
    'Line chart · on the data: pulse 60–80, weight 172–174',
    children: <Widget>[
      kitSpecimenLineChartPulse(),
      const SizedBox(height: kitGap * 2),
      ExpressiveLineChart(
        points: <ExpressiveChartPoint>[
          for (var w = 0; w < 7; w++)
            ExpressiveChartPoint('W${w + 1}', _weight[w]),
        ],
        aspectRatio: 1.8,
        semanticLabel: 'Weight over seven weeks, 173.8 to 172.6 pounds',
      ),
    ],
  );
}

class _Sparkline extends StatelessWidget {
  const _Sparkline();

  @override
  Widget build(BuildContext context) => kitSection(
    'Sparkline · in a list row',
    children: <Widget>[
      ExpressiveListSection(
        children: <Widget>[
          ExpressiveListTile(
            overline: const Text('Pulse'),
            title: const Text('69 bpm'),
            subtitle: const Text('Average this week'),
            trailing: kitSpecimenSparklinePulse(),
          ),
        ],
      ),
    ],
  );
}

// Catalog specimens (docs/architecture/component-catalog.md).

/// Minutes read each day of a week, today highlighted.
Widget kitSpecimenChartWeek() => const ExpressiveChart.bar(
  points: <ExpressiveChartPoint>[
    ExpressiveChartPoint('Mon', 24),
    ExpressiveChartPoint('Tue', 38),
    ExpressiveChartPoint('Wed', 12),
    ExpressiveChartPoint('Thu', 45),
    ExpressiveChartPoint('Fri', 30),
    ExpressiveChartPoint('Sat', 52),
    ExpressiveChartPoint('Sun', 18),
  ],
  highlight: 5,
  semanticLabel: 'Minutes read this week, most on Saturday',
);

const List<ExpressiveChartPoint> _spend = <ExpressiveChartPoint>[
  ExpressiveChartPoint('Rent', 1400),
  ExpressiveChartPoint('Food', 520),
  ExpressiveChartPoint('Travel', 310),
  ExpressiveChartPoint('Other', 190),
];

/// A month's spending as parts of a whole.
class _Donut extends StatelessWidget {
  const _Donut();

  @override
  Widget build(BuildContext context) => kitSection(
    'Pie chart · a donut of parts of a whole, a legend of each',
    children: const <Widget>[
      Center(
        child: SizedBox(
          width: 280,
          child: ExpressivePieChart(
            points: _spend,
            centerValue: '2,420',
            centerLabel: 'Spent in March',
          ),
        ),
      ),
    ],
  );
}

/// A count chart that shows the point under a pointer.
class _Pointed extends StatelessWidget {
  const _Pointed();

  @override
  Widget build(BuildContext context) => kitSection(
    'Bar chart · hover or press a bar for its tooltip',
    children: const <Widget>[
      ExpressiveBarChart(
        points: <ExpressiveChartPoint>[
          ExpressiveChartPoint('Mon', 32),
          ExpressiveChartPoint('Tue', 45),
          ExpressiveChartPoint('Wed', 28),
          ExpressiveChartPoint('Thu', 51),
          ExpressiveChartPoint('Fri', 38),
          ExpressiveChartPoint('Sat', 60),
          ExpressiveChartPoint('Sun', 22),
        ],
        highlight: 5,
        tooltip: true,
        semanticLabel: 'Minutes read, last 7 days',
      ),
    ],
  );
}

/// A chart still loading, and one with nothing to show.
class _States extends StatelessWidget {
  const _States();

  @override
  Widget build(BuildContext context) => kitSection(
    'Loading and empty',
    children: const <Widget>[
      ExpressiveChart.line(
        points: <ExpressiveChartPoint>[],
        loading: true,
        semanticLabel: 'Steps this week',
      ),
      SizedBox(height: kitGap * 2),
      ExpressiveChart.bar(
        points: <ExpressiveChartPoint>[],
        semanticLabel: 'Workouts this week',
      ),
    ],
  );
}

/// A month's spending as a donut.
Widget kitSpecimenChartDonut() => const SizedBox(
  width: 240,
  child: ExpressiveChart.donut(
    points: _spend,
    centerValue: '2,420',
    centerLabel: 'Spent in March',
  ),
);

/// Pulse over a week on an axis scaled to it.
Widget kitSpecimenLineChartPulse() => ExpressiveLineChart(
  points: <ExpressiveChartPoint>[
    for (var d = 0; d < 7; d++)
      ExpressiveChartPoint(_weekdays[d], _Measures._pulse[d]),
  ],
  aspectRatio: 1.8,
  semanticLabel: 'Pulse this week, 64 to 78 beats a minute',
);

/// Pulse over a week as a sparkline, a list row's trailing trend.
Widget kitSpecimenSparklinePulse() => SizedBox(
  width: ExpressiveSpacing.s72 + ExpressiveSpacing.s16,
  height: ExpressiveSpacing.s36,
  child: ExpressiveSparkline(
    points: <ExpressiveChartPoint>[
      for (var d = 0; d < 7; d++)
        ExpressiveChartPoint(_weekdays[d], _Measures._pulse[d]),
    ],
  ),
);

/// A spend's four parts as a pie chart.
Widget kitSpecimenPieChartSpend() => const SizedBox(
  width: 240,
  child: ExpressivePieChart(
    points: _spend,
    centerValue: '2,420',
    centerLabel: 'Spent in March',
  ),
);

/// Minutes read each day as bars, Saturday in primary.
Widget kitSpecimenBarChartWeek() => const ExpressiveBarChart(
  points: <ExpressiveChartPoint>[
    ExpressiveChartPoint('M', 22),
    ExpressiveChartPoint('T', 35),
    ExpressiveChartPoint('W', 18),
    ExpressiveChartPoint('T', 41),
    ExpressiveChartPoint('F', 30),
    ExpressiveChartPoint('S', 64),
    ExpressiveChartPoint('S', 48),
  ],
  highlight: 5,
  semanticLabel: 'Minutes read each day, most on Saturday',
);

/// Mood over two weeks as an area from zero.
Widget kitSpecimenAreaChartMood() => const ExpressiveAreaChart(
  points: <ExpressiveChartPoint>[
    ExpressiveChartPoint('1', 3),
    ExpressiveChartPoint('2', 4),
    ExpressiveChartPoint('3', 3.5),
    ExpressiveChartPoint('4', 2.5),
    ExpressiveChartPoint('5', 3),
    ExpressiveChartPoint('6', 4),
    ExpressiveChartPoint('7', 4.5),
    ExpressiveChartPoint('8', 4),
    ExpressiveChartPoint('9', 3.5),
    ExpressiveChartPoint('10', 4),
    ExpressiveChartPoint('11', 4.5),
    ExpressiveChartPoint('12', 5),
    ExpressiveChartPoint('13', 4.5),
    ExpressiveChartPoint('14', 4),
  ],
  highlight: 11,
  aspectRatio: 3,
  semanticLabel: 'Mood over two weeks',
);
