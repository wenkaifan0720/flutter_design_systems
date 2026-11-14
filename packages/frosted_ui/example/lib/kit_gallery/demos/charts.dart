/// Frosted's charts, drawn from sample figures: the [FrostedTrailChart] of the
/// net worth by month, of Everyday's balance by its steps and of
/// Investing's value by day (and a bare trail with no axis), October's
/// [FrostedSpendChart] against its pace under its [FrostedChartKey] of
/// [FrostedKey]s, Lisbon's [FrostedGoalChart] with the keys in its head, the
/// [FrostedDayBars] of Dining out's month, of Savings' interest by month and
/// of what went into the goals stacked, November's bills as a
/// [FrostedStepsChart], and the [FrostedFan] of what leaves Everyday on its own,
/// each flow a [FrostedFanEnd].
library;

import 'package:flutter/material.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:frosted_ui/frosted_host.dart';

import '../kit.dart';

Widget kitChartsDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Charts',
  sections: [
    kitSection(
      'Line',
      children: const [
        FrostedLineChart(
          label: 'Visitors',
          labels: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
          current: 4,
          series: [
            // The week stands at Friday: nothing after it yet.
            FrostedChartSeries('Visitors', [
              120,
              180,
              150,
              210,
              240,
              null,
              null,
            ]),
          ],
        ),
        FrostedLineChart(
          label: 'Sign-ups by channel',
          labels: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'],
          series: [
            FrostedChartSeries('Search', [40, 52, 61, 58, 72, 80]),
            FrostedChartSeries('Social', [22, 30, 28, 41, 39, 50]),
            FrostedChartSeries('Referral', [10, 12, 18, 16, 21, 27]),
          ],
        ),
      ],
    ),
    kitSection(
      'Area',
      children: const [
        FrostedAreaChart(
          label: 'Storage used',
          labels: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'],
          series: [
            FrostedChartSeries('Photos', [2, 3, 3.5, 5, 6.2, 7]),
          ],
        ),
      ],
    ),
    kitSection(
      'Bar',
      children: const [
        FrostedBarChart(
          label: 'Steps',
          labels: ['M', 'T', 'W', 'T', 'F', 'S', 'S'],
          current: 4,
          series: [
            FrostedChartSeries('Steps', [6200, 8400, 7100, 9900, 4300, 0, 0]),
          ],
        ),
        FrostedBarChart(
          label: 'Tickets opened and closed',
          labels: ['W1', 'W2', 'W3', 'W4'],
          series: [
            FrostedChartSeries('Opened', [14, 22, 18, 9]),
            FrostedChartSeries('Closed', [11, 19, 21, 15]),
          ],
        ),
      ],
    ),
    kitSection(
      'Pie and donut',
      children: [
        kitRow(const [
          FrostedPieChart(
            label: 'Time spent',
            center: Text('38 h'),
            size: 160,
            slices: [
              FrostedPieSlice('Focus', 18),
              FrostedPieSlice('Meetings', 12),
              FrostedPieSlice('Email', 8),
            ],
          ),
          FrostedPieChart(
            label: 'Browsers',
            donut: false,
            size: 160,
            slices: [
              FrostedPieSlice('Safari', 46),
              FrostedPieSlice('Chrome', 38),
              FrostedPieSlice('Other', 16),
            ],
          ),
        ]),
      ],
    ),
    kitSection(
      'Sparkline',
      children: [
        kitRow(const [
          FrostedSparkline([3, 5, 4, 7, 6, 9], label: 'Sign-ups', width: 120),
          FrostedSparkline(
            [9, 8, 8.5, 6, 6.5, 4],
            label: 'Errors',
            width: 120,
            area: false,
          ),
        ]),
      ],
    ),
    kitSection(
      'Net worth, a year by month',
      children: [kitSpecimenTrailNetWorth()],
    ),
    kitSection(
      'Everyday, its balance through October',
      children: [kitSpecimenTrailEveryday()],
    ),
    kitSection(
      'Investing, its value through October',
      children: [kitSpecimenTrailInvesting()],
    ),
    // At a row's size: filling the column it read as a chart that had lost
    // its axes (self-review round 3).
    kitSection(
      'A bare trail, for a row',
      children: [
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: SizedBox(width: 120, child: kitSpecimenTrailBare()),
        ),
      ],
    ),
    kitSection(
      'October day by day, against its pace',
      children: [kitSpecimenSpendChart()],
    ),
    kitSection(
      'Lisbon in May, saved and where it is headed',
      children: [kitSpecimenGoalChart()],
    ),
    kitSection(
      'Dining out, each day in October',
      children: [kitSpecimenDayBars()],
    ),
    kitSection(
      'Interest earned each month',
      children: [kitSpecimenMonthBars()],
    ),
    kitSection('Put away each month', children: [kitSpecimenStackedMonths()]),
    kitSection(
      'November’s bills, added up',
      children: [kitSpecimenStepsChart()],
    ),
    kitSection('Scheduled, from Everyday', children: [kitSpecimenFan()]),
    kitSection(
      'Keys',
      children: [
        Builder(
          builder: (context) => FrostedChartKey(
            keys: [
              const FrostedKey(
                FrostedKeySwatch.line,
                'Spent',
                figure: '\$2,486.12',
              ),
              const FrostedKey(FrostedKeySwatch.pace, 'Budget pace'),
              FrostedKey(
                FrostedKeySwatch.projection,
                'Projected',
                hue: context.frostedTheme.hues.sunset,
              ),
            ],
          ),
        ),
      ],
    ),
  ],
);

// --- Sample figures ---------------------------------------------------------

/// Net worth at each month's end, November to October.
const List<num> _netWorth = [
  61400, 62900, 64100, 63200, 65600, 67000, //
  68300, 69900, 71600, 73400, 75278.38, 78182.56,
];

const List<String> _months = [
  'Nov', 'Dec', 'Jan', 'Feb', 'Mar', 'Apr', //
  'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct',
];

/// Everyday's closing balance each day of October so far, walked back
/// from today's through the ledger; its balance before the month began
/// was $2,479.82.
const List<num> _everyday = [
  673.12, 667.32, 667.32, 667.32, 661.52, 655.72, 649.92, 644.12, //
  4050.82, 4050.82, 4050.82, 2864.80, 2861.90, 2859.00, 2856.10, 2853.20,
  2853.20, 2853.20, 2850.30, 2847.40, 2844.50, 2841.60, 6251.20, 6251.20,
  6251.20, 6251.20, 6251.20, 6248.30,
];

/// The days Everyday moved by $500 or more, and what moved it.
const List<FrostedChartNote> _everydayNotes = [
  FrostedChartNote(1, 'Rent and goals'),
  FrostedChartNote(9, 'Paycheck'),
  FrostedChartNote(12, 'Card autopay'),
  FrostedChartNote(23, 'Paycheck'),
];

/// Investing's value at each day's close in October so far.
const List<num> _investing = [
  50612.40, 50388.15, 50388.15, 50388.15, 50701.92, 50455.30, 50120.84, //
  49876.25, 50034.61, 50034.61, 50034.61, 49702.18, 49388.47, 49165.02,
  49420.66, 49610.35, 49610.35, 49610.35, 49283.90, 48902.14, 48655.37,
  48874.05, 48712.68, 48712.68, 48712.68, 48601.20, 48529.33, 48920.70,
];

/// What October had spent by the end of each day so far.
const List<num> _spentByDay = [
  1172.40, 1210.55, 1274.75, 1371.55, 1390.15, 1402.55, 1447.65, //
  1470.40, 1541.70, 1596.60, 1717.05, 1732.25, 1742.05, 1800.65,
  1833.90, 1852.80, 1945.20, 2021.35, 2035.65, 2063.25, 2105.10,
  2124.80, 2188.20, 2209.35, 2354.90, 2401.30, 2476.47, 2486.12,
];

/// Dining out on each day of October so far.
const List<num> _dining = [
  15.70, 32.35, 29.20, 38.50, 5.25, 0, 4.75, 6.25, 20.05, 0, 13.45, 9.40, //
  0, 23.95, 0, 16.00, 0, 0, 8.41, 7.50, 26.35, 5.75, 6.50, 10.29, 0, 0, 0,
  6.75,
];

/// Interest paid into Savings by month, November to October.
const List<num> _interest = [
  58.12, 60.40, 61.95, 57.30, 64.18, 64.90, //
  67.42, 66.85, 69.77, 71.04, 70.92, 73.42,
];

/// The Lisbon fund at each month's end, and where $150 a month leads it.
const List<num> _lisbonSaved = [
  790,
  940,
  1090,
  1240,
  1390,
  1540,
  1690,
  1840,
  1990,
  2540,
  2690,
  2840,
];
const List<num> _lisbonAhead = [2990, 3140, 3290, 3440, 3590, 3740, 3890];

/// What went into each goal each month over the last twelve: the
/// Emergency fund's auto-saves and the Savings interest, Lisbon's with its
/// August catch-up, the bike pot from May.
const List<num> _emergencyByMonth = [
  458.12, 460.40, 461.95, 457.30, 464.18, 464.90, //
  467.42, 466.85, 469.77, 471.04, 470.92, 473.42,
];
const List<num> _lisbonByMonth = [
  150,
  150,
  150,
  150,
  150,
  150,
  150,
  150,
  150,
  550,
  150,
  150,
];
const List<num> _bikeByMonth = [0, 0, 0, 0, 0, 0, 140, 100, 100, 100, 100, 100];

/// November's bills by due day.
const List<FrostedStep> _bills = [
  FrostedStep(1, 1150, 'Rent'),
  FrostedStep(3, 35, 'Kite Mobile'),
  FrostedStep(12, 1326.44, 'Harbor Card'),
  FrostedStep(15, 15.98, 'Newsline'),
  FrostedStep(19, 2.99, 'Cloudbox'),
  FrostedStep(27, 10.99, 'Streamline Music'),
];

/// Oct 1, the weeks and today (the 28th) under a chart of October's days.
const List<FrostedAxisMark> _octoberAxis = [
  FrostedAxisMark.first('Oct 1'),
  FrostedAxisMark(7, '8'),
  FrostedAxisMark(14, '15'),
  FrostedAxisMark(21, '22'),
  FrostedAxisMark(27, 'Today', current: true),
];

/// Nov 1, the weeks and the 30th under November's bills.
const List<FrostedAxisMark> _novemberAxis = [
  FrostedAxisMark.first('Nov 1'),
  FrostedAxisMark(7, '8'),
  FrostedAxisMark(14, '15'),
  FrostedAxisMark(21, '22'),
  FrostedAxisMark.last('30'),
];

/// The goal's first month, today's column and the projection's last.
const List<FrostedAxisMark> _goalAxis = [
  FrostedAxisMark.first('Nov 2025'),
  FrostedAxisMark(11, 'Today', current: true),
  FrostedAxisMark.last('May 2027'),
];

/// Where a fan's row would open; the gallery stays put.
void _open() {}

// --- Specimens --------------------------------------------------------------
// One builder per specimen in metadata.yaml. The stage (kitSpecimenStage)
// styles them; a builder never names a style.

/// Home's net worth over the last twelve months, October in the page ink.
Widget kitSpecimenTrailNetWorth() => const FrostedTrailChart(
  values: _netWorth,
  months: _months,
  label: 'Net worth over the last 12 months',
);

/// Everyday's balance through October as its steps: the rent and the
/// goals on the 1st, the paychecks, the card's autopay.
Widget kitSpecimenTrailEveryday() => const FrostedTrailChart.steps(
  values: _everyday,
  start: 2479.82,
  daysInMonth: 31,
  notes: _everydayNotes,
  marks: _octoberAxis,
  label: 'Everyday balance through October',
);

/// Investing's value through October, a line through the days.
Widget kitSpecimenTrailInvesting() => const FrostedTrailChart.days(
  values: _investing,
  daysInMonth: 31,
  marks: _octoberAxis,
  label: 'Investing value through October',
);

/// A year's trail alone, a sparkline for a row: the line, its light and
/// its end, no grid and no words.
// A row's height: the plot's own height (a box round it does not set it;
// boxed at 40 the 140 plot ran into the next heading, self-review round 4).
Widget kitSpecimenTrailBare() => const FrostedTrailChart(
  values: _netWorth,
  bare: true,
  height: 40,
  label: 'Net worth over the last 12 months',
);

/// Spending's day by day: the keys over the chart, as the page sets them
/// (16 over the plot), the rent named on the 1st, today the 28th.
Widget kitSpecimenSpendChart() => const Column(
  crossAxisAlignment: CrossAxisAlignment.stretch,
  children: [
    FrostedChartKey(
      keys: [
        FrostedKey(FrostedKeySwatch.line, 'Spent', figure: '\$2,486.12'),
        FrostedKey(FrostedKeySwatch.pace, 'Budget pace'),
      ],
    ),
    FrostedGap(FrostedChromeMetrics.chartTop),
    FrostedSpendChart(
      spent: _spentByDay,
      budget: 2700,
      daysInMonth: 31,
      firstNote: 'Rent',
      marks: _octoberAxis,
      label: 'October spending against the budget pace',
    ),
  ],
);

/// Lisbon in May: its caption and keys in a head row, then what was saved
/// by month, where $150 a month leads it, and the target.
Widget kitSpecimenGoalChart() => Builder(
  builder: (context) {
    final t = context.frostedTheme;
    final trip = t.hues.sunset;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: FrostedSpacing.s10,
      children: [
        // .rec-chart-h { display: flex; justify-content: space-between;
        // gap: 8px; flex-wrap: wrap }
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: FrostedSpacing.s8,
          runSpacing: FrostedSpacing.s8,
          children: [
            // What is saved today (the line's end), not the projection's.
            Text(r'$2,840 saved of $4,000', style: t.textTheme.labelMedium),
            FrostedChartKey(
              inHead: true,
              keys: [
                const FrostedKey(FrostedKeySwatch.line, 'Saved'),
                FrostedKey(FrostedKeySwatch.projection, 'Projected', hue: trip),
              ],
            ),
          ],
        ),
        FrostedGoalChart(
          saved: _lisbonSaved,
          projection: _lisbonAhead,
          target: 4000,
          endDate: DateTime(2027, 5),
          hue: trip,
          marks: _goalAxis,
          label: 'Lisbon in May: saved, and where it is headed',
        ),
      ],
    );
  },
);

/// Dining out's October day by day, a dot on each day without a meal out.
Widget kitSpecimenDayBars() => Builder(
  builder: (context) => FrostedDayBars(
    values: _dining,
    daysInMonth: 31,
    hue: context.frostedTheme.hues.coral,
    marks: _octoberAxis,
    label: 'Dining out, each day in October',
  ),
);

/// Savings' interest by month in its hue, October lit and valued.
Widget kitSpecimenMonthBars() => Builder(
  builder: (context) => FrostedDayBars.months(
    values: _interest,
    months: _months,
    hue: context.frostedTheme.hues.seafoam,
    label: 'Interest earned each month',
  ),
);

/// What went into the three goals each month, a band per goal, October's
/// total over its bar.
Widget kitSpecimenStackedMonths() => Builder(
  builder: (context) {
    final hues = context.frostedTheme.hues;
    return FrostedDayBars.stacked(
      series: [
        FrostedBarSeries(hues.azure, _emergencyByMonth),
        FrostedBarSeries(hues.sunset, _lisbonByMonth),
        FrostedBarSeries(hues.lime, _bikeByMonth),
      ],
      months: _months,
      lines: 4,
      label: 'Put away each month',
    );
  },
);

/// November's bills added up through the month, the rent and the card
/// named on their steps.
Widget kitSpecimenStepsChart() => const FrostedStepsChart(
  steps: _bills,
  daysInMonth: 30,
  marks: _novemberAxis,
  label: 'November bills, added up through the month',
);

/// What leaves Everyday on its own: the goals' auto-saves on the 1st,
/// then the card's autopay on the 12th (its ribbon in the card's own
/// light, the prism's first two stops, as the page draws it), each row a
/// link.
Widget kitSpecimenFan() => Builder(
  builder: (context) {
    final hues = context.frostedTheme.hues;
    return FrostedFan(
      flows: [
        FrostedFanEnd(
          amount: 400,
          hue: hues.azure,
          title: 'Emergency fund',
          subtitle: 'Auto-save · Sun, Nov 1',
          onPressed: _open,
        ),
        FrostedFanEnd(
          amount: 150,
          hue: hues.sunset,
          title: 'Lisbon in May',
          subtitle: 'Auto-save · Sun, Nov 1',
          onPressed: _open,
        ),
        FrostedFanEnd(
          amount: 100,
          hue: hues.lime,
          title: 'New bike',
          subtitle: 'Auto-save · Sun, Nov 1',
          onPressed: _open,
        ),
        FrostedFanEnd(
          amount: 1326.44,
          hue: hues.iris,
          title: 'Harbor Card autopay',
          subtitle: 'Autopay · Thu, Nov 12',
          onPressed: _open,
        ),
      ],
      source: hues.cyan,
      label: 'What leaves Everyday on its own in November',
    );
  },
);

/// Savings over five months, filled under its line.
Widget kitSpecimenAreaChart() => const FrostedAreaChart(
  label: 'Saved this year',
  labels: ['Jun', 'Jul', 'Aug', 'Sep', 'Oct'],
  series: [
    FrostedChartSeries('Savings', [820, 1140, 1390, 1720, 2050]),
  ],
);

/// Spending by week, this week lit.
Widget kitSpecimenBarChart() => const FrostedBarChart(
  label: 'Spent each week',
  labels: ['W1', 'W2', 'W3', 'W4'],
  current: 3,
  series: [
    FrostedChartSeries('Spent', [412, 380, 466, 298]),
  ],
);

/// The balance across a week.
Widget kitSpecimenLineChart() => const FrostedLineChart(
  label: 'Balance',
  labels: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'],
  series: [
    FrostedChartSeries('This week', [4210, 4185, 4320, 4290, 4480]),
  ],
);

/// October by category, the total in its middle.
Widget kitSpecimenPieChart() => const FrostedPieChart(
  label: 'October by category',
  center: Text(r'$1,260'),
  slices: [
    FrostedPieSlice('Groceries', 420),
    FrostedPieSlice('Dining out', 310),
    FrostedPieSlice('Transport', 180),
    FrostedPieSlice('Other', 350),
  ],
);

/// Six weeks of saving in a line.
Widget kitSpecimenSparkline() => const Center(
  heightFactor: 1,
  child: SizedBox(
    width: 160,
    child: FrostedSparkline([3, 5, 4, 7, 6, 9], label: 'Saved each week'),
  ),
);
