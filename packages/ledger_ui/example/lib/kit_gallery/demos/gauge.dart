/// The ledger's measures drawn as engravings: the gauge ([LedgerGauge]: a
/// hatched fill in its frame, the budget's tick, the month's pace in
/// green, its labels over and under it), the allocation's stack
/// ([LedgerStackBar] of [LedgerStackPart]), the budget's rule
/// ([LedgerBudgetRule]: what was spent against the budget and the
/// suggestion) and a chart's key ([LedgerChartKey] of [LedgerKeyEntry]).
/// Every figure is the pilot's (keel.dart).
library;

import 'package:flutter/material.dart';
import 'package:ledger_ui/ledger_ui.dart';

import '../kit.dart';

Widget kitGaugeDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Gauges',
  sections: [
    kitSection(
      "October's gauge",
      children: [kitSpan(KitSpan.half, kitSpecimenGaugeMonth())],
    ),
    kitSection(
      'A goal, a category, over',
      children: [kitSpan(KitSpan.margin, kitSpecimenGauges())],
    ),
    kitSection(
      'The allocation',
      children: [kitSpan(KitSpan.margin, kitSpecimenStackBar())],
    ),
    kitSection(
      "The budget's rule",
      children: [kitSpan(KitSpan.main, kitSpecimenBudgetRule())],
    ),
    kitSection(
      'Chart keys',
      children: [kitSpan(KitSpan.main, kitSpecimenChartKeys())],
    ),
  ],
);

LedgerStackTone _tone(String name) => switch (name) {
  'green' => LedgerStackTone.green,
  'pale' => LedgerStackTone.pale,
  _ => LedgerStackTone.ink,
};

// --- Specimens --------------------------------------------------------------
// One builder per specimen in metadata.yaml. The stage (kitSpecimenStage)
// styles them; a builder never names a style.

/// October so far: 92% of the budget spent at day 28's pace, its scale
/// from nothing to the budget.
Widget kitSpecimenGaugeMonth() => LedgerGauge(
  ratio: kitSpent / kitBudget,
  pace: kitDay / kitDaysInMonth,
  tick: false,
  paceLabel: kitPaceLabel,
  startLabel: LedgerFormat.money(0, showCents: false),
  endLabel: kitBudgetWhole,
);

/// Lisbon's share saved (green, no tick), Groceries within its budget at
/// the month's pace, and Dining out past it.
Widget kitSpecimenGauges() {
  final lisbon = kitGoals.first;
  final groceries = kitCategories.firstWhere((c) => c.name == 'Groceries');
  final dining = kitCategories.firstWhere((c) => c.over);
  return Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: LedgerSpacing.s24,
    children: [
      LedgerGauge(
        ratio: lisbon.saved / lisbon.target,
        tick: false,
        tone: LedgerGaugeTone.green,
        semanticLabel: 'Saved',
      ),
      LedgerGauge(
        ratio: groceries.spent / groceries.budget,
        budgetAt: 250 / 300,
        pace: kitDay / kitDaysInMonth,
        semanticLabel: '${groceries.name} spent',
      ),
      LedgerGauge(
        ratio: dining.spent / dining.budget,
        budgetAt: 250 / 300,
        pace: kitDay / kitDaysInMonth,
        semanticLabel: '${dining.name} spent',
      ),
    ],
  );
}

/// Investing's allocation: stocks, bonds and cash.
Widget kitSpecimenStackBar() => LedgerStackBar(
  parts: [
    for (final (_, value, tone, _) in kitAllocation)
      LedgerStackPart(value, _tone(tone)),
  ],
);

/// Dining out's budget in the edit sheet: spent past the budget, the
/// suggestion beyond, and its key.
Widget kitSpecimenBudgetRule() => Column(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.stretch,
  spacing: LedgerSpacing.s12,
  children: [
    const LedgerBudgetRule(
      spent: kitDiningSpent,
      budget: kitDiningBudget,
      suggested: kitDiningSuggested,
    ),
    LedgerChartKey(
      entries: [
        LedgerKeyEntry(
          LedgerKeySwatch.tick,
          'Budget ${LedgerFormat.money(kitDiningBudget, showCents: false)}',
        ),
        LedgerKeyEntry(
          LedgerKeySwatch.suggestion,
          'Suggested ${LedgerFormat.money(kitDiningSuggested, showCents: false)}',
        ),
        LedgerKeyEntry(
          kitDiningSpent > kitDiningBudget
              ? LedgerKeySwatch.spentOver
              : LedgerKeySwatch.spent,
          'Spent ${LedgerFormat.money(kitDiningSpent)}',
        ),
      ],
    ),
  ],
);

/// The keys over Spending's, Activity's and Everyday's charts.
Widget kitSpecimenChartKeys() => const Column(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.start,
  spacing: LedgerSpacing.s16,
  children: [
    LedgerChartKey(
      entries: [
        LedgerKeyEntry(LedgerKeySwatch.line, 'Spent, cumulative'),
        LedgerKeyEntry(LedgerKeySwatch.pace, 'Budget pace'),
      ],
    ),
    LedgerChartKey(
      entries: [
        LedgerKeyEntry(LedgerKeySwatch.bar, 'Spent per day'),
        LedgerKeyEntry(LedgerKeySwatch.payday, 'Paycheck'),
      ],
    ),
    LedgerChartKey(
      entries: [
        LedgerKeyEntry(LedgerKeySwatch.line, 'Balance, end of day'),
        LedgerKeyEntry(LedgerKeySwatch.payday, 'Paycheck'),
      ],
    ),
  ],
);
