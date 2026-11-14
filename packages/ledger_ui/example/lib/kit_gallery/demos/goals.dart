/// What the owner saves toward and spends against: a goal's line
/// ([LedgerGoalLine]: its glyph and name on the leader to its share, the
/// green gauge, what is saved of the target and by when), its card on the
/// Goals page ([LedgerGoalCard]: the line, its status pill and note, the
/// note in the margin's column from 1024 wide), and a category's month
/// ([LedgerCategoryLine]: the name on the leader to what it spent, the
/// gauge with its budget and the month's pace, vermilion over budget).
/// Every figure is the pilot's (keel.dart).
library;

import 'package:flutter/material.dart';
import 'package:ledger_ui/ledger_ui.dart';

import '../kit.dart';

Widget kitGoalsDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Goals',
  sections: [
    kitSection(
      'Goal lines',
      children: [kitSpan(KitSpan.margin, kitSpecimenGoalLines())],
    ),
    kitSection(
      'Goal cards',
      children: [kitSpan(KitSpan.main, kitSpecimenGoalCards())],
    ),
    kitSection(
      'Category lines',
      children: [kitSpan(KitSpan.main, kitSpecimenCategoryLines())],
    ),
    kitSection(
      'Within, and over its budget',
      children: [kitSpan(KitSpan.main, kitSpecimenCategoryOver())],
    ),
  ],
);

LedgerGoalLine _line(KitGoal g) => LedgerGoalLine(
  icon: g.icon,
  name: g.name,
  saved: g.saved,
  target: g.target,
  by: g.by,
  onTap: () {},
);

LedgerCategoryLine _category(KitCategory c) => LedgerCategoryLine(
  name: c.name,
  spent: c.spent,
  budget: c.budget,
  pace: kitDay / kitDaysInMonth,
  subtitle: c.subStart,
  trailingSubtitle: c.subEnd.isEmpty ? null : c.subEnd,
  onTap: () {},
);

// --- Specimens --------------------------------------------------------------
// One builder per specimen in metadata.yaml. The stage (kitSpecimenStage)
// styles them; a builder never names a style.

/// Home's three goals under their head.
Widget kitSpecimenGoalLines() => LedgerSection(
  head: LedgerHead('Goals', note: '${kitGoals.length} active'),
  child: LedgerRows(
    children: <LedgerGoalLine>[for (final g in kitGoals) _line(g)],
  ),
);

/// The Goals page's cards: Lisbon behind, the others on track.
Widget kitSpecimenGoalCards() => LedgerSection(
  head: LedgerHead(
    'Your goals',
    note: '${kitWord(kitGoals.length, cap: true)} active',
  ),
  child: LedgerRows(
    children: [
      for (final g in kitGoals)
        LedgerGoalCard(
          icon: g.icon,
          name: g.name,
          saved: g.saved,
          target: g.target,
          by: g.by,
          status: g.status,
          behindSchedule: g.behind,
          note: g.note,
          onTap: () {},
        ),
    ],
  ),
);

/// Spending's first four categories against their budgets and the pace.
Widget kitSpecimenCategoryLines() => LedgerSection(
  head: const LedgerHead('Categories', note: 'Spent · budget'),
  child: LedgerRows(
    children: <LedgerCategoryLine>[
      for (final c in kitCategories.take(4)) _category(c),
    ],
  ),
);

/// Dining out, the one category over its budget, beside Groceries within.
Widget kitSpecimenCategoryOver() => LedgerRows(
  children: <LedgerCategoryLine>[
    for (final c in kitCategories.where((c) => c.name != 'Rent & home'))
      if (c.over || c.name == 'Groceries') _category(c),
  ],
);
