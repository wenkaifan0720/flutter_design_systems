/// A page's structure as the ledger sets it: the section head
/// ([LedgerHead]: the ink rule over the rubric, its mono note or green
/// link, the hero's footnote and range chips) over its body
/// ([LedgerSection]); the ledger's rows ([LedgerRows] of [LedgerRow]: a
/// glyph or a date tab, the title on its dot leader to the amount, the sub
/// line under); a record's details ([LedgerKeyValue]), facts
/// ([LedgerFacts]), head ([LedgerRecordHead]) and numbered notes
/// ([LedgerNotes]); a month's rule in the register ([LedgerMonthRule]); the
/// flag of a budget gone over ([LedgerFlag]); Move money's four ways
/// ([LedgerQuickActions]); a figure's change ([LedgerDelta]); and a link
/// standing on its own under what it closes ([LedgerMoreLink]). Every
/// word and figure is the pilot's (keel.dart). From 1024 wide each part
/// stands at the width the source's board gives it.
library;

import 'package:flutter/material.dart';
import 'package:ledger_ui/ledger_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../kit.dart';

Widget kitStructureDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Structure',
  sections: [
    kitSection(
      'Heads',
      children: [kitSpan(KitSpan.margin, kitSpecimenHeads())],
    ),
    kitSection(
      "The hero's head",
      children: [kitSpan(KitSpan.main, kitSpecimenHeroHead())],
    ),
    kitSection(
      'A figure and its change',
      children: [kitSpan(KitSpan.main, kitSpecimenDelta())],
    ),
    kitSection(
      'Rows of a ledger',
      children: [kitSpan(KitSpan.half, kitSpecimenAccounts())],
    ),
    kitSection(
      'Rows led by a date',
      children: [kitSpan(KitSpan.margin, kitSpecimenUpcoming())],
    ),
    kitSection(
      'Move money',
      children: [kitSpan(KitSpan.margin, kitSpecimenQuickActions())],
    ),
    kitSection(
      'Notes',
      children: [kitSpan(KitSpan.margin, kitSpecimenNotes())],
    ),
    kitSection(
      'A budget gone over',
      children: [kitSpan(KitSpan.half, kitSpecimenFlag())],
    ),
    kitSection(
      "A record's head",
      children: [kitSpan(KitSpan.main, kitSpecimenRecordHead())],
    ),
    kitSection(
      'Facts, two across on a phone',
      children: [kitSpan(KitSpan.margin, kitSpecimenFacts())],
    ),
    kitSection(
      'Facts, three across on a phone',
      children: [kitSpan(KitSpan.margin, kitSpecimenFactsThree())],
    ),
    kitSection(
      'A pair of facts',
      children: [kitSpan(KitSpan.margin, kitSpecimenFactsPair())],
    ),
    kitSection(
      'Keys and values',
      children: [kitSpan(KitSpan.margin, kitSpecimenDetails())],
    ),
    kitSection(
      "A month's rule",
      children: [kitSpan(KitSpan.full, kitSpecimenMonthRule())],
    ),
    kitSection(
      'A link on its own',
      children: [kitSpan(KitSpan.margin, kitSpecimenMoreLink())],
    ),
  ],
);

// --- Specimens --------------------------------------------------------------
// One builder per specimen in metadata.yaml. The stage (kitSpecimenStage)
// styles them; a builder never names a style.

/// Home's heads: Accounts over its Balance note, and the upcoming bills
/// with their link to all of them.
Widget kitSpecimenHeads() => Column(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.stretch,
  spacing: LedgerSpacing.s24,
  children: [
    const LedgerHead('Accounts', note: 'Balance'),
    LedgerHead(
      'Upcoming · 15 days',
      note: 'All bills',
      linkLabel: 'All bills',
      onTap: () {},
    ),
    LedgerHead('Goals', note: '${kitGoals.length} active'),
  ],
);

/// Home's hero head: Net worth, its footnote, and the range chips.
Widget kitSpecimenHeroHead() => LedgerHead.hero(
  'Net worth',
  footnote: '1',
  trailing: LedgerSegmentedControl(
    options: kitRanges,
    value: kitRange,
    onChanged: (_) {},
  ),
);

/// The net worth's change this month, under its figure.
Widget kitSpecimenDelta() => LedgerDelta(
  rise: LedgerFormat.money(kitNetWorthChange),
  words: const ['this month'],
  pill: const LedgerPill(kitNetWorthChangePct),
);

/// Home's accounts: each led by its glyph, its balance on the leader, its
/// sub line under, then the double rule and the net worth they sum to.
Widget kitSpecimenAccounts() => LedgerSection(
  head: const LedgerHead('Accounts', note: 'Balance'),
  child: Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      LedgerRows(
        children: [
          for (final a in kitAccounts)
            LedgerRow(
              leading: LedgerGlyph(a.icon),
              title: a.name,
              value: LedgerAmount(a.amount),
              subtitle: a.subStart,
              subtitleMonospace: a.subStartMono,
              trailingSubtitle: a.subEnd.isEmpty ? null : a.subEnd,
              trailingSubtitleTone: a.subEndGreen
                  ? LedgerTone.moneyIn
                  : LedgerTone.plain,
              onTap: () {},
            ),
        ],
      ),
      const LedgerStatementTotal(title: 'Net worth', amount: kitNetWorth),
    ],
  ),
);

/// Home's bills of the next 15 days, each led by its date tab; autopay's
/// note in the green.
Widget kitSpecimenUpcoming() => LedgerSection(
  head: LedgerHead(
    'Upcoming · 15 days',
    note: 'All bills',
    linkLabel: 'All bills',
    onTap: () {},
  ),
  child: LedgerRows(
    children: [
      for (final b in kitUpcoming)
        LedgerRow(
          leading: LedgerDateTab(b.due),
          title: b.name,
          value: LedgerAmount(b.amount),
          subtitle: b.status,
          subtitleTone: b.autopay ? LedgerTone.moneyIn : LedgerTone.plain,
          onTap: () {},
        ),
    ],
  ),
);

/// Move money's four ways: a strip across the phone, a list in the
/// desktop's margin.
Widget kitSpecimenQuickActions() => LedgerQuickActions(
  actions: [
    for (final (icon, label) in kitActs)
      LedgerQuickAction(icon, label, onTap: () {}),
  ],
);

/// Home's footnote to the net worth.
Widget kitSpecimenNotes() =>
    const LedgerNotes(notes: [LedgerNote('1', kitNetWorthNote)]);

/// October's flag: the one category over its budget.
Widget kitSpecimenFlag() => LedgerFlag(
  '$kitOverName is **over by ${LedgerFormat.money(kitOverBy)}**',
  onTap: () {},
);

/// Everyday's head: its glyph in the record's ring, the serif name, the
/// account's kind and mask.
Widget kitSpecimenRecordHead() => const LedgerRecordHead(
  leading: LedgerGlyph(LucideIcons.wallet, size: LedgerGlyphSize.record),
  name: 'Everyday',
  subtitle: kitEverydaySub,
);

/// Spending's month at a glance: left, against September, money in and
/// the pace, two across on a phone, one under another in the margin.
Widget kitSpecimenFacts() => LedgerSection(
  head: const LedgerHead('The month', note: 'At a glance'),
  child: LedgerFacts(facts: [for (final f in kitMonthFacts) kitFact(f)]),
);

/// Activity's month in and out, three across on a phone.
Widget kitSpecimenFactsThree() => LedgerFacts(
  columns: LedgerFactColumns.three,
  ruled: true,
  facts: [for (final f in kitActivityFacts) kitFact(f)],
);

/// Blue Fern Café's October beside its receipt: the visits and the total.
Widget kitSpecimenFactsPair() => LedgerFacts(
  columns: LedgerFactColumns.pair,
  facts: [
    const LedgerFact(
      'Visits',
      '$kitVisitCount',
      note: 'at $kitInsightMerchant',
    ),
    LedgerFact.money('Total', kitVisitTotal, note: 'in $kitMonthName'),
  ],
);

/// Everyday's details, each on its leader; the masks in the mono.
Widget kitSpecimenDetails() => LedgerSection(
  head: const LedgerHead('Details', note: 'Checking'),
  child: Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (final (name, value) in kitEverydayDetails)
        LedgerKeyValue(name, value, monospace: value.startsWith('··')),
    ],
  ),
);

/// The register's rule where September begins, under October's days.
Widget kitSpecimenMonthRule() =>
    LedgerMonthRule(kitSpentByMonth[1].$1, note: 'Last month');

/// The link under a merchant's month beside its receipt:
/// See all its visits, in the green capitals with the chevron.
Widget kitSpecimenMoreLink() => Align(
  alignment: AlignmentDirectional.centerStart,
  child: LedgerMoreLink('See all $kitVisitCount visits', onTap: () {}),
);
