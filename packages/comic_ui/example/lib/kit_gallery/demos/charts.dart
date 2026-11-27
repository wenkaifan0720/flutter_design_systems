/// Figures inked true to their amounts, on plain numbers. A figure means whatever the page says it means, so none of them assumes money, distance or time.
library;

import 'package:material_ui/material_ui.dart';
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

Widget kitSpecimenBar() => Builder(
  builder: (context) => ComicColumn(
    gap: 14,
    children: [
      ComicBar(
        value: 2,
        of: 6,
        label: kitSay(context, 'Pages pencilled'),
        figure: kitSay(context, '2 of 6'),
      ),
      ComicBar(
        value: 5,
        of: 6,
        ink: ComicBarFill.leading,
        height: 28,
        stamp: kitSay(context, 'Leads'),
        label: kitSay(context, 'Pages inked'),
        figure: kitSay(context, '5 of 6'),
      ),
      ComicBar(
        value: 3,
        of: 6,
        ink: ComicBarFill.currentUser,
        height: 18,
        label: kitSay(context, 'Your pages'),
        figure: kitSay(context, '3 of 6'),
      ),
    ],
  ),
);

Widget kitSpecimenTally() => Builder(
  builder: (context) => ComicTally(
    question: kitSay(context, 'Which of them?'),
    subtitle: kitSay(context, 'One pick each · 5 of 6 in'),
    of: 6,
    options: [
      ComicVote(
        kitSay(context, 'The first'),
        count: 3,
        isLeading: true,
        stamp: kitSay(context, 'Leads'),
        people: [
          ComicPerson(initials: 'AB', size: 24),
          ComicPerson(initials: 'CD', size: 24),
          ComicPerson(initials: 'EF', size: 24),
        ],
      ),
      ComicVote(
        kitSay(context, 'The second'),
        note: kitSay(context, 'with a note'),
        count: 1,
        people: [ComicPerson(initials: 'GH', size: 24)],
      ),
      ComicVote(
        kitSay(context, 'The third'),
        count: 1,
        people: [ComicPerson(initials: 'IJ', size: 24)],
      ),
    ],
    waiting: kitSay(context, 'Waiting on one'),
    yours: kitSay(context, 'You picked 1'),
  ),
);

Widget kitSpecimenBarList() => Builder(
  builder: (context) => ComicBarList(
    of: 27,
    entries: [
      ComicBarEntry(kitSay(context, 'Sam'), 25, isLeading: true),
      ComicBarEntry(kitSay(context, 'You'), 24, isCurrentUser: true),
      ComicBarEntry(kitSay(context, 'Alex'), 19),
      ComicBarEntry(kitSay(context, 'Robin'), 17),
    ],
  ),
);

Widget kitSpecimenFlow() => Builder(
  builder: (context) => ComicFlow(
    into: kitSay(context, 'Sam'),
    intoFigure: '237',
    intoPerson: ComicPerson(initials: 'SD', size: 56),
    from: [
      ComicFlowFrom(
        kitSay(context, 'You'),
        19,
        isCurrentUser: true,
        person: ComicPerson(initials: 'ME', size: 30),
      ),
      ComicFlowFrom(
        kitSay(context, 'Alex'),
        85,
        person: ComicPerson(initials: 'AB', size: 30, fillIndex: 1),
      ),
      ComicFlowFrom(
        kitSay(context, 'Robin'),
        133,
        person: ComicPerson(initials: 'RC', size: 30),
      ),
    ],
  ),
);

Widget kitSpecimenShares() => Builder(
  builder: (context) => ComicShares(
    stamp: kitSay(context, 'Done'),
    scaleStart: kitSay(context, '540 done'),
    scaleEnd: kitSay(context, '330 to go'),
    parts: [
      ComicShare(
        kitSay(context, 'The first'),
        540,
        note: kitSay(context, 'Done on the 10th'),
        ink: ComicShareFill.lamp,
      ),
      ComicShare(
        kitSay(context, 'The second'),
        156,
        note: kitSay(context, 'An estimate'),
      ),
      ComicShare(
        kitSay(context, 'The third'),
        90,
        ink: ComicShareFill.dramaDots,
      ),
      ComicShare(
        kitSay(context, 'The fourth'),
        84,
        ink: ComicShareFill.denseDots,
      ),
    ],
  ),
);

Widget kitSpecimenUnits() => Builder(
  builder: (context) => ComicUnits([
    ComicUnitColumn(kitSay(context, 'Jul'), 4),
    ComicUnitColumn(kitSay(context, 'Aug'), 3),
    ComicUnitColumn(kitSay(context, 'Sep'), 2),
    ComicUnitColumn(kitSay(context, 'Oct'), 2),
    ComicUnitColumn(kitSay(context, 'Nov'), 3, now: true),
  ]),
);

Widget kitSpecimenPie() => Builder(
  builder: (context) => ComicPieChart(
    centre: '417',
    unit: kitSay(context, 'in all'),
    slices: [
      ComicSlice(kitSay(context, 'The most'), 200, share: '48%'),
      ComicSlice(kitSay(context, 'Next'), 99, share: '24%'),
      ComicSlice(kitSay(context, 'Then'), 76, share: '18%'),
      ComicSlice(kitSay(context, 'The rest'), 42, share: '10%'),
    ],
  ),
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
Widget kitLineChart() => Builder(
  builder: (context) => ComicLineChart(
    semanticLabel: kitSay(context, 'Pages read each week'),
    labels: [for (final week in _weeks) kitSay(context, week)],
    series: [
      ComicChartSeries(kitSay(context, 'You'), [12, 18, 16, 24, 21, 27]),
      ComicChartSeries(kitSay(context, 'The group'), [10, 14, 15, 17, 18, 20]),
    ],
    band: ComicChartBand(15, 22, label: kitSay(context, 'Target 15 to 22')),
  ),
);

/// Gaps, shown where they are the point: a reading that never came breaks the line rather than guessing.
Widget kitGapChart() => Builder(
  builder: (context) => ComicColumn(
    gap: 8,
    children: [
      Text(
        kitSay(
          context,
          'The tracker was off on Wednesday and Thursday: the line breaks there instead of guessing.',
        ),
        style: ComicTheme.of(context).type.body,
      ),
      ComicChart(
        semanticLabel: kitSay(context, 'Hours slept each night'),
        labels: [
          kitSay(context, 'Mon'),
          kitSay(context, 'Tue'),
          kitSay(context, 'Wed'),
          kitSay(context, 'Thu'),
          kitSay(context, 'Fri'),
          kitSay(context, 'Sat'),
          kitSay(context, 'Sun'),
        ],
        series: [
          ComicChartSeries(kitSay(context, 'Hours slept'), [
            7,
            6,
            null,
            null,
            8,
            7,
            9,
          ]),
        ],
      ),
    ],
  ),
);

Widget kitAreaChart() => Builder(
  builder: (context) => ComicAreaChart(
    semanticLabel: kitSay(context, 'Visitors each week'),
    labels: [for (final week in _weeks) kitSay(context, week)],
    series: [
      ComicChartSeries(kitSay(context, 'Visitors'), [
        320,
        410,
        380,
        520,
        610,
        580,
      ]),
    ],
  ),
);

Widget kitBarChart() => Builder(
  builder: (context) => ComicBarChart(
    semanticLabel: kitSay(context, 'Orders each week'),
    labels: [for (final week in _weeks) kitSay(context, week)],
    series: [
      ComicChartSeries(kitSay(context, 'Online'), [42, 51, 38, 60, 55, 64]),
      ComicChartSeries(kitSay(context, 'In store'), [30, 28, 35, 32, 40, 37]),
    ],
  ),
);

Widget kitEmptyChart() => Builder(
  builder: (context) => ComicChart(
    semanticLabel: kitSay(context, 'Pages read each week'),
    series: [ComicChartSeries(kitSay(context, 'You'), [])],
    height: 120,
  ),
);

Widget kitLoadingChart() => Builder(
  builder: (context) => ComicChart(
    semanticLabel: kitSay(context, 'Pages read each week'),
    series: [ComicChartSeries(kitSay(context, 'You'), [])],
    height: 120,
    loading: true,
  ),
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
        ComicSparkline(
          semanticLabel: label,
          values: values,
          width: 120,
          height: 32,
        ),
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
        row(kitSay(context, 'Sales this week'), [3, 5, 4, 8, 7, 9, 12], '12'),
        row(kitSay(context, 'Returns this week'), [6, 4, 5, 5, 3, 2, 2], '2'),
      ],
    );
  },
);
