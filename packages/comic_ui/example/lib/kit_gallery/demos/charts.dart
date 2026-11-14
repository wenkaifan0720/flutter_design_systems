/// Figures inked true to their amounts, on plain numbers. A figure means whatever the page says it means, so none of them assumes money, distance or time.
library;

import 'package:flutter/material.dart';
import 'package:comic_ui/comic_ui.dart';

import '../kit.dart';

Widget kitChartsDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Numbers in print',
  sections: [
    kitSection('A line chart', children: [kitLineChart()]),
    kitSection('An area chart', children: [kitAreaChart()]),
    kitSection('A bar chart', children: [kitBarChart()]),
    kitSection('A donut', children: [kitSpecimenPie()]),
    kitSection('Sparklines', children: [_sparklines()]),
    kitSection('A gap in the data', children: [kitGapChart()]),
    kitSection(
      'Empty and loading',
      children: [kitEmptyChart(), kitLoadingChart()],
    ),
    kitSection('A bar of dots', children: [kitSpecimenBar()]),
    kitSection('A vote', children: [kitSpecimenTally()]),
    kitSection('A ranked list', children: [kitSpecimenBarList()]),
    kitSection('A flow', children: [kitSpecimenFlow()]),
    kitSection('Shares of a whole', children: [kitSpecimenShares()]),
    kitSection('Counts as units', children: [kitSpecimenUnits()]),
    kitSection('A run of steps', children: [kitSpecimenSegments()]),
    kitSection('Cells', children: [kitSpecimenCells()]),
  ],
);

Widget kitSpecimenBar() => const ComicColumn(
  gap: 14,
  children: [
    ComicBar(value: 2, of: 6, label: 'Pages pencilled', figure: '2 of 6'),
    ComicBar(
      value: 5,
      of: 6,
      ink: ComicBarFill.leading,
      height: 28,
      stamp: 'Leads',
      label: 'Pages inked',
      figure: '5 of 6',
    ),
    ComicBar(
      value: 3,
      of: 6,
      ink: ComicBarFill.currentUser,
      height: 18,
      label: 'Your pages',
      figure: '3 of 6',
    ),
  ],
);

Widget kitSpecimenTally() => const ComicTally(
  question: 'Which of them?',
  subtitle: 'One pick each · 5 of 6 in',
  of: 6,
  options: [
    ComicVote(
      'The first',
      count: 3,
      isLeading: true,
      stamp: 'Leads',
      people: [
        ComicPerson(initials: 'AB', size: 24),
        ComicPerson(initials: 'CD', size: 24),
        ComicPerson(initials: 'EF', size: 24),
      ],
    ),
    ComicVote(
      'The second',
      note: 'with a note',
      count: 1,
      people: [ComicPerson(initials: 'GH', size: 24)],
    ),
    ComicVote(
      'The third',
      count: 1,
      people: [ComicPerson(initials: 'IJ', size: 24)],
    ),
  ],
  waiting: 'Waiting on one',
  yours: 'You picked 1',
);

Widget kitSpecimenBarList() => const ComicBarList(
  of: 27,
  entries: [
    ComicBarEntry('Sam', 25, isLeading: true),
    ComicBarEntry('You', 24, isCurrentUser: true),
    ComicBarEntry('Alex', 19),
    ComicBarEntry('Robin', 17),
  ],
);

Widget kitSpecimenFlow() => const ComicFlow(
  into: 'Sam',
  intoFigure: '237',
  intoPerson: ComicPerson(initials: 'SD', size: 56),
  from: [
    ComicFlowFrom(
      'You',
      19,
      isCurrentUser: true,
      person: ComicPerson(initials: 'ME', size: 30),
    ),
    ComicFlowFrom(
      'Alex',
      85,
      person: ComicPerson(initials: 'AB', size: 30, fillIndex: 1),
    ),
    ComicFlowFrom('Robin', 133, person: ComicPerson(initials: 'RC', size: 30)),
  ],
);

Widget kitSpecimenShares() => const ComicShares(
  stamp: 'Done',
  scaleStart: '540 done',
  scaleEnd: '330 to go',
  parts: [
    ComicShare(
      'The first',
      540,
      note: 'Done on the 10th',
      ink: ComicShareFill.lamp,
    ),
    ComicShare('The second', 156, note: 'An estimate'),
    ComicShare('The third', 90, ink: ComicShareFill.dramaDots),
    ComicShare('The fourth', 84, ink: ComicShareFill.denseDots),
  ],
);

Widget kitSpecimenUnits() => const ComicUnits([
  ComicUnitColumn('Jul', 4),
  ComicUnitColumn('Aug', 3),
  ComicUnitColumn('Sep', 2),
  ComicUnitColumn('Oct', 2),
  ComicUnitColumn('Nov', 3, now: true),
]);

Widget kitSpecimenPie() => const ComicPieChart(
  centre: '417',
  unit: 'in all',
  slices: [
    ComicSlice('The most', 200, share: '48%'),
    ComicSlice('Next', 99, share: '24%'),
    ComicSlice('Then', 76, share: '18%'),
    ComicSlice('The rest', 42, share: '10%'),
  ],
);

Widget kitSpecimenSegments() => const ComicSegments(
  [8, 5, 2, 5, 45, 5],
  long: 4,
  scaleStart: '0',
  scaleEnd: '70',
);

Widget kitSpecimenCells() =>
    const ComicProgressCells(total: 8, completed: 4, started: 2);

const _weeks = ['Wk 1', 'Wk 2', 'Wk 3', 'Wk 4', 'Wk 5', 'Wk 6'];

// The three chart forms by their shared names (each a ComicChart of that form).
Widget kitLineChart() => const ComicLineChart(
  label: 'Pages read each week',
  labels: _weeks,
  series: [
    ComicChartSeries('You', [12, 18, 16, 24, 21, 27]),
    ComicChartSeries('The group', [10, 14, 15, 17, 18, 20]),
  ],
  band: ComicChartBand(15, 22, label: 'Target 15 to 22'),
);

/// Gaps, shown where they are the point: a reading that never came breaks the line rather than guessing.
Widget kitGapChart() => Builder(
  builder: (context) => ComicColumn(
    gap: 8,
    children: [
      Text(
        'The tracker was off on Wednesday and Thursday: the line breaks there instead of guessing.',
        style: ComicTheme.of(context).type.body,
      ),
      const ComicChart(
        label: 'Hours slept each night',
        labels: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
        series: [
          ComicChartSeries('Hours slept', [7, 6, null, null, 8, 7, 9]),
        ],
      ),
    ],
  ),
);

Widget kitAreaChart() => const ComicAreaChart(
  label: 'Visitors each week',
  labels: _weeks,
  series: [
    ComicChartSeries('Visitors', [320, 410, 380, 520, 610, 580]),
  ],
);

Widget kitBarChart() => const ComicBarChart(
  label: 'Orders each week',
  labels: _weeks,
  series: [
    ComicChartSeries('Online', [42, 51, 38, 60, 55, 64]),
    ComicChartSeries('In store', [30, 28, 35, 32, 40, 37]),
  ],
);

Widget kitEmptyChart() => const ComicChart(
  label: 'Pages read each week',
  series: [ComicChartSeries('You', [])],
  height: 120,
);

Widget kitLoadingChart() => const ComicChart(
  label: 'Pages read each week',
  series: [ComicChartSeries('You', [])],
  height: 120,
  loading: true,
);

// The complete demo's sparkline specimen, drawn here too: a demo imports only
// the public surface, never another demo.
Widget _sparklines() => Builder(
  builder: (context) {
    final t = ComicTheme.of(context);
    Widget row(String label, List<double> values, String figure) => Row(
      children: [
        Expanded(child: Text(label, style: t.type.body)),
        const SizedBox(width: 12),
        ComicSparkline(label: label, values: values, width: 120, height: 32),
        const SizedBox(width: 12),
        SizedBox(
          width: MediaQuery.textScalerOf(context).scale(36),
          child: Text(
            figure,
            textAlign: TextAlign.end,
            style: t.type.number(22, color: t.colors.text),
          ),
        ),
      ],
    );
    return ComicColumn(
      gap: 12,
      children: [
        row('Sales this week', [3, 5, 4, 8, 7, 9, 12], '12'),
        row('Returns this week', [6, 4, 5, 5, 3, 2, 2], '2'),
      ],
    );
  },
);
