/// Choosing and listing: the menu of months Spending can show
/// ([LedgerMenu]), the budget sheet's suggestion ([LedgerSuggestion]),
/// the categories as tiles, options and a margin's mini line
/// ([LedgerCategoryTile], [LedgerOption], [LedgerCategoryMini]), a goal's
/// icon ([LedgerIconPicker]), Move's four ways ([LedgerWays]), an
/// allocation's kinds and a portfolio's funds ([LedgerAllocationRow],
/// [LedgerHoldings]), two acts side by side ([LedgerButtonRow]) and the
/// account holder's certificate ([LedgerMemberCard]). Every word is the
/// pilot's (keel.dart, else the source line named beside it).
library;

import 'package:flutter/material.dart';
import 'package:ledger_ui/ledger_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../kit.dart';

Widget kitChoicesDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Choices & the member card',
  sections: [
    kitSection('Menu', children: [kitSpecimenMenu()]),
    kitSection(
      'Suggestion',
      children: [kitSpan(KitSpan.half, kitSpecimenSuggestion())],
    ),
    kitSection(
      'Category tiles',
      children: [kitSpan(KitSpan.margin, kitSpecimenCategoryTiles())],
    ),
    kitSection(
      'Category options',
      children: [kitSpan(KitSpan.half, kitSpecimenCategoryOptions())],
    ),
    kitSection(
      'Category mini',
      children: [kitSpan(KitSpan.margin, kitSpecimenCategoryMini())],
    ),
    kitSection(
      'Icon picker',
      children: [kitSpan(KitSpan.half, kitSpecimenIconPicker())],
    ),
    kitSection(
      'Ways to move money',
      children: [kitSpan(KitSpan.full, kitSpecimenWays())],
    ),
    kitSection(
      'Allocation',
      children: [kitSpan(KitSpan.margin, kitSpecimenAllocation())],
    ),
    kitSection(
      'Holdings',
      children: [kitSpan(KitSpan.full, kitSpecimenHoldings())],
    ),
    kitSection(
      'Two acts',
      children: [kitSpan(KitSpan.main, kitSpecimenButtonRow())],
    ),
    kitSection(
      'Member card',
      children: [kitSpan(KitSpan.main, kitSpecimenMemberCard())],
    ),
  ],
);

// Values the gallery's keel.dart does not bind, taken from the source.

/// with the sample data
const String _suggestWhy =
    'Your September and October average, rounded up to \$5.';

/// the new goal's icons, in order.
const List<LedgerIconChoice> _goalIcons = [
  LedgerIconChoice(LucideIcons.plane, 'plane'),
  LedgerIconChoice(LucideIcons.shield, 'shield'),
  LedgerIconChoice(LucideIcons.bike, 'bike'),
  LedgerIconChoice(LucideIcons.house, 'house'),
  LedgerIconChoice(LucideIcons.car, 'car'),
  LedgerIconChoice(LucideIcons.gift, 'gift'),
  LedgerIconChoice(LucideIcons.graduationCap, 'graduation-cap'),
  LedgerIconChoice(LucideIcons.heart, 'heart'),
  LedgerIconChoice(LucideIcons.umbrella, 'umbrella'),
  LedgerIconChoice(LucideIcons.piggyBank, 'piggy-bank'),
];

// Each holding: name, symbol, kind, shares ("N shares", else "Settled
// cash"), value, today.
const List<(String, String, String, String, double, double)> _holdings = [
  ('Keel Total Market', 'KTMX', 'Stocks', '182.4 shares', 26410.2, 262.1),
  ('Keel International', 'KINX', 'Stocks', '301 shares', 9782.4, 71.48),
  ('Keel Bond Index', 'KBND', 'Bonds', '146.2 shares', 7336.1, 18.34),
  ('Clean Energy Leaders', 'KCLN', 'Stocks', '90 shares', 3240, 39.45),
  ('Cash', 'CASH', 'Cash', 'Settled cash', 2152, 0),
];

/// the sample person, as the profile's card prints it.
const String _holder = 'Maren Holt';
const String _holderInitials = 'MH';
const String _holderEmail = 'maren.holt@example.com';
const String _holderPhone = '(•••) •••-0119';

LedgerStackTone _tone(String hatch) => switch (hatch) {
  'green' => LedgerStackTone.green,
  'pale' => LedgerStackTone.pale,
  _ => LedgerStackTone.ink,
};

// --- Specimens --------------------------------------------------------------
// One builder per specimen in metadata.yaml. The stage (kitSpecimenStage)
// styles them; a builder never names a style.

/// Spending's months, newest first, October checked.
Widget kitSpecimenMenu() => Align(
  alignment: AlignmentDirectional.centerStart,
  child: LedgerMenu(
    head: 'Spent by month',
    semanticLabel: 'Months',
    items: [
      for (final (i, m) in kitSpentByMonth.indexed)
        LedgerMenuItem(m.$1, amount: m.$2, selected: i == 0, onTap: () {}),
    ],
  ),
);

/// The budget sheet's suggestion for Dining out: $275.
Widget kitSpecimenSuggestion() => LedgerSuggestion(
  amount: kitDiningSuggested,
  text: _suggestWhy,
  onTap: () {},
);

/// The empty search's eight categories to browse instead, Dining out over.
Widget kitSpecimenCategoryTiles() => LedgerCategoryTiles(
  tiles: [
    for (final c in kitCategories)
      LedgerCategoryTile(
        icon: c.icon,
        name: c.name,
        spent: c.spent,
        overBudget: c.spent > c.budget,
        onTap: () {},
      ),
  ],
);

/// The category sheet of the Blue Fern Café purchase: Dining out chosen.
Widget kitSpecimenCategoryOptions() => LedgerRows(
  children: [
    for (final c in kitCategories)
      LedgerOption(
        icon: c.icon,
        label: c.name,
        selected: c.name == kitBlueFernCategory,
        onTap: () {},
      ),
  ],
);

/// A purchase's category in its margin: October's Dining out on its gauge,
/// and the same in September, a month gone by.
Widget kitSpecimenCategoryMini() {
  final dining = kitCategories.firstWhere((c) => c.name == kitOverName);
  return Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: LedgerSpacing.s40,
    children: [
      LedgerCategoryMini(
        name: dining.name,
        spent: dining.spent,
        budget: dining.budget,
        pace: kitDay / kitDaysInMonth,
        subtitle: dining.subStart,
        trailingSubtitle: dining.subEnd,
        onTap: () {},
      ),
      // a month gone by, Dining out's September (the sample data
      // categories.dining.september).
      const LedgerCategoryMini(
        name: 'Dining out',
        spent: 256.6,
        subtitle: 'Spent in September',
      ),
    ],
  );
}

/// The new goal's ten icons, the plane chosen.
Widget kitSpecimenIconPicker() =>
    LedgerIconPicker(choices: _goalIcons, selectedIndex: 0, onSelected: (_) {});

/// Move's four ways: six bills due in November, Lisbon
/// behind.
Widget kitSpecimenWays() {
  final behind = kitGoals.firstWhere((g) => g.behind);
  return LedgerWays(
    ways: [
      for (final (i, a) in kitActs.indexed)
        LedgerWay(
          icon: a.$1,
          title: a.$2,
          text: switch (i) {
            0 => 'Between your accounts',
            // word(len(nov), True): the six bills in kitBills.
            1 => 'Six due in ${LedgerFormat.month(kitBills.first.due)}',
            2 => '${behind.name.split(' ').first} is behind',
            _ => 'Share a purchase',
          },
          onTap: () {},
        ),
    ],
  );
}

/// Investing's allocation: the hatched bar over its three kinds.
Widget kitSpecimenAllocation() => Column(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.stretch,
  spacing: LedgerSpacing.s8,
  children: [
    LedgerStackBar(
      parts: [
        for (final a in kitAllocation) LedgerStackPart(a.$2, _tone(a.$3)),
      ],
    ),
    LedgerRows(
      children: [
        for (final a in kitAllocation)
          LedgerAllocationRow(
            tone: _tone(a.$3),
            name: a.$1,
            amount: a.$2,
            share: a.$4,
          ),
      ],
    ),
  ],
);

/// Investing's five funds.
Widget kitSpecimenHoldings() => LedgerHoldings(
  rows: [
    for (final h in _holdings)
      LedgerHoldingRow(
        name: h.$1,
        symbol: h.$2,
        kind: h.$3,
        shares: h.$4,
        value: h.$5,
        today: h.$6,
      ),
  ],
);

/// The sent transfer's two acts.
Widget kitSpecimenButtonRow() => LedgerButtonRow(
  children: [
    LedgerButton.filled(
      'Back to Home',
      icon: LucideIcons.house,
      expand: true,
      onPressed: () {},
    ),
    LedgerButton(
      'View transfer',
      icon: LucideIcons.receipt,
      expand: true,
      onPressed: () {},
    ),
  ],
);

/// The profile's certificate: Maren Holt, a member since March 2023.
Widget kitSpecimenMemberCard() => const LedgerMemberCard(
  kind: 'Keel · Account holder',
  since: 'Since Mar 2023',
  name: _holder,
  initials: _holderInitials,
  subtitle: 'Member since March 2023',
  seal: LedgerSeal(kicker: 'Keel', value: 'Member', foot: 'Since 2023'),
  details: [
    LedgerKeyValue('Email', _holderEmail),
    LedgerKeyValue('Phone', _holderPhone),
    LedgerKeyValue('Main account', kitPaycheckAccount),
  ],
);
