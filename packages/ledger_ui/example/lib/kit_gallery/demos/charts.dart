/// Every chart the ledger engraves, each fed the pilot's data and sized by
/// the width it is given (from 1024 wide, the source's desktop plot): the
/// net worth by month ([LedgerNetWorthChart]), the month's spending against
/// the budget's pace ([LedgerCumulativeChart]), the days as hatched bars
/// with the rent day broken off ([LedgerDayBars]), one merchant's visits
/// on a ruler ([LedgerVisitRuler]), a balance through the month
/// ([LedgerMonthLine]), a year of interest with its bracket
/// ([LedgerMonthBars]), the bills summed as they fall due
/// ([LedgerStepTotal]) and the saving toward a goal ([LedgerGoalChart]),
/// each under its key ([LedgerChartKey]) where the source keys it.
library;

import 'package:flutter/material.dart';
import 'package:ledger_ui/ledger_ui.dart';

import '../kit.dart';

Widget kitChartsDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Charts',
  sections: [
    kitSection(
      'Net worth',
      children: [kitSpan(KitSpan.main, kitSpecimenNetWorthChart())],
    ),
    kitSection(
      'Spent against the budget',
      children: [kitSpan(KitSpan.main, kitSpecimenCumulativeChart())],
    ),
    kitSection(
      'Spent per day',
      children: [kitSpan(KitSpan.main, kitSpecimenDayBars())],
    ),
    kitSection(
      'A category by day',
      children: [kitSpan(KitSpan.main, kitSpecimenDayBarsCategory())],
    ),
    kitSection(
      "A merchant's visits",
      children: [kitSpan(KitSpan.margin, kitSpecimenVisitRuler())],
    ),
    kitSection(
      'A balance through the month',
      children: [kitSpan(KitSpan.main, kitSpecimenMonthLine())],
    ),
    kitSection(
      'A value through the month',
      children: [kitSpan(KitSpan.main, kitSpecimenMonthLineValue())],
    ),
    kitSection(
      'Interest by month',
      children: [kitSpan(KitSpan.main, kitSpecimenMonthBars())],
    ),
    kitSection(
      'Bills as they fall due',
      children: [kitSpan(KitSpan.main, kitSpecimenStepTotal())],
    ),
    kitSection(
      'Saved toward the goals',
      children: [kitSpan(KitSpan.main, kitSpecimenGoalChart())],
    ),
    kitSection(
      'A goal and its projection',
      children: [kitSpan(KitSpan.main, kitSpecimenGoalProjection())],
    ),
  ],
);

List<LedgerGridLine> _grid(List<(double, String)> lines) => [
  for (final (value, label) in lines) LedgerGridLine(value, label),
];

/// The month's short name, as the rulers set their first day (Oct 1).
String get _month => LedgerFormat.month(kitNow, short: true);

/// A chart under its key, 12 apart (`.legend { margin-bottom: 12px }`).
Widget _keyed(List<LedgerKeyEntry> key, Widget chart) => Column(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.stretch,
  spacing: 12,
  children: [
    LedgerChartKey(entries: key),
    chart,
  ],
);

// --- Specimens --------------------------------------------------------------
// One builder per specimen in metadata.yaml. The stage (kitSpecimenStage)
// styles them; a builder never names a style.

/// Home's net worth over twelve month ends, in thousands.
Widget kitSpecimenNetWorthChart() => LedgerNetWorthChart(
  values: kitNetWorthK,
  low: kitNetWorthLo,
  high: kitNetWorthHi,
  grid: _grid(kitNetWorthGrid),
  endLabel: kitNetWorthLast,
  months: kitNetWorthMonths,
);

/// Spending's October, summed day by day against the budget's pace, the
/// rent's day noted.
Widget kitSpecimenCumulativeChart() => _keyed(
  const [
    LedgerKeyEntry(LedgerKeySwatch.line, 'Spent, cumulative'),
    LedgerKeyEntry(LedgerKeySwatch.pace, 'Budget pace'),
  ],
  LedgerCumulativeChart(
    cumulative: kitCumulative,
    budget: kitBudget,
    days: kitDaysInMonth,
    high: kitCumulativeHi,
    grid: _grid(kitCumulativeGrid),
    budgetLabel: kitBudgetLabel,
    note: const LedgerChartNote(
      0,
      '**$kitRentWord**$kitRentNote',
      lift: kitRentLiftPhone,
      deskLift: kitRentLift,
    ),
    month: _month,
  ),
);

/// Activity's October by day: the rent day broken off above the cap, the
/// paydays ringed.
Widget kitSpecimenDayBars() => _keyed(
  const [
    LedgerKeyEntry(LedgerKeySwatch.bar, 'Spent per day'),
    LedgerKeyEntry(LedgerKeySwatch.payday, 'Paycheck'),
  ],
  LedgerDayBars(
    values: kitDaily,
    days: kitDaysInMonth,
    cap: kitDailyCap,
    capLabels: {
      for (final MapEntry(key: day, value: (amount, words))
          in kitCapLabels.entries)
        day: '**$amount**$words',
    },
    marks: [for (final (day, text) in kitPaydays) LedgerChartMark(day, text)],
    grid: _grid(kitDailyGrid),
    month: _month,
  ),
);

/// Dining out's October by day, 120 tall on a phone and 268 on the
/// desktop as the category page stands it (pages_b.category).
Widget kitSpecimenDayBarsCategory() => LedgerDayBars(
  values: kitDiningDays,
  days: kitDaysInMonth,
  grid: _grid(kitDiningGrid),
  high: kitDiningHi,
  month: _month,
  height: 120,
  deskHeight: 268,
);

/// Blue Fern Café's October: thirteen visits, today's solid.
Widget kitSpecimenVisitRuler() => LedgerVisitRuler(
  visits: kitVisits,
  days: kitMonthDays,
  today: kitToday,
  current: kitVisitDay,
  startLabel: '$_month 1',
  endLabel: '$_month $kitMonthDays',
);

/// Everyday's balance at each day's end: the paydays above, the card's
/// payment below.
Widget kitSpecimenMonthLine() => _keyed(
  const [
    LedgerKeyEntry(LedgerKeySwatch.line, 'Balance, end of day'),
    LedgerKeyEntry(LedgerKeySwatch.payday, 'Paycheck'),
  ],
  LedgerMonthLine(
    values: kitEveryday,
    start: kitEverydayStart,
    days: kitDaysInMonth,
    low: kitEverydayLo,
    high: kitEverydayHi,
    grid: _grid(kitEverydayGrid),
    marks: [
      for (final (day, text, above) in kitEverydayMarks)
        LedgerChartMark(day, text, below: !above),
    ],
    month: _month,
  ),
);

/// Investing's October, its end labelled above the line; 176 tall on a
/// phone as the investing page stands it (pages_b.investing).
Widget kitSpecimenMonthLineValue() => LedgerMonthLine(
  values: kitInvesting,
  start: kitInvestingStart,
  days: kitDaysInMonth,
  low: kitInvestingLo,
  high: kitInvestingHi,
  grid: _grid(kitInvestingGrid),
  endLabel: kitInvestingEnd,
  endAbove: true,
  month: _month,
  height: 176,
);

/// Savings' interest by month, the year to date bracketed, October's
/// solid and marked.
Widget kitSpecimenMonthBars() => _keyed(
  const [LedgerKeyEntry(LedgerKeySwatch.barGreen, 'Interest earned, by month')],
  LedgerMonthBars(
    values: kitInterest,
    bracket: LedgerChartBracket(
      kitInterestFirst,
      kitInterest.length - 1,
      '$kitInterestYear**$kitInterestYtd**',
    ),
    marks: [LedgerChartMark(kitInterest.length - 1, kitInterestLast)],
    months: kitInterestMonths,
  ),
);

/// November's bills summed as they fall due, the two large ones named.
Widget kitSpecimenStepTotal() => _keyed(
  [
    LedgerKeyEntry(
      LedgerKeySwatch.line,
      'Due through ${LedgerFormat.month(kitBills.first.due)}',
    ),
  ],
  LedgerStepTotal(
    steps: kitBillSteps,
    days: kitBillDays,
    high: kitBillsHi,
    grid: _grid(kitBillsGrid),
    notes: [
      for (final (index, name, rest, lift, deskLift) in kitBillNotes)
        LedgerChartNote(
          index,
          '**$name**\n$rest',
          lift: lift,
          deskLift: deskLift,
          deskText: '**$name** $rest',
        ),
    ],
    month: kitBillsMonth,
  ),
);

/// The goals' saved total at each month end against their summed target,
/// the gap to go dimensioned; 280 tall on a phone and 268 on the desktop
/// as the Goals page stands it (pages_c.goals).
Widget kitSpecimenGoalChart() => _keyed(
  const [LedgerKeyEntry(LedgerKeySwatch.line, 'Saved, at each month end')],
  LedgerGoalChart(
    history: [
      for (var i = 0; i < kitSavedByMonth.length; i++) (i, kitSavedByMonth[i]),
    ],
    months: kitSavedByMonth.length,
    target: kitGoalsTarget,
    low: kitGoalsLo,
    high: kitGoalsHi,
    grid: _grid(kitGoalsGrid),
    targetLabel: kitGoalsTargetLabel,
    gapLabel: 'To go **$kitGoalsGap**',
    keys: kitGoalsMonths,
    now: kitSavedByMonth.length - 1,
    height: 280,
    deskHeight: 268,
  ),
);

/// Lisbon in May: saved so far, then on at its auto-save to its date.
Widget kitSpecimenGoalProjection() => _keyed(
  [
    const LedgerKeyEntry(LedgerKeySwatch.line, 'Saved'),
    LedgerKeyEntry(
      LedgerKeySwatch.pace,
      'At ${LedgerFormat.money(kitLisbonProj[1].$2 - kitLisbonProj[0].$2, showCents: false)} a month',
    ),
  ],
  LedgerGoalChart(
    history: kitLisbonHist,
    projection: kitLisbonProj,
    months: kitLisbonMonths,
    target: kitLisbonTarget,
    low: kitLisbonLo,
    high: kitLisbonHi,
    grid: _grid(kitLisbonGrid),
    targetLabel: kitLisbonTargetLabel,
    endLabel: kitLisbonEnd,
    keys: kitLisbonKeys,
    now: kitLisbonNow,
  ),
);
