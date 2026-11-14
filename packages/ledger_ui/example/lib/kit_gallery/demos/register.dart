/// The register: the transactions as a statement ([LedgerRegister]), in
/// day groups ([LedgerDayGroup]: the day, its date for Today and
/// Yesterday, its net) of rows ([LedgerTransactionRow]: the merchant's
/// monogram, a pending one tagged, its category and time under it, its
/// signed amount), in columns under their heads from 1024 wide; Home's
/// recent activity, each row carrying its day; and the month's bills
/// ([LedgerBillList] of [LedgerBillRow]: the date tab, the payee on its
/// leader, the account and the status, the amount). Every row is the
/// pilot's (keel.dart).
library;

import 'package:flutter/material.dart';
import 'package:ledger_ui/ledger_ui.dart';

import '../kit.dart';

Widget kitRegisterDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Register',
  sections: [
    kitSection(
      "Activity's days",
      children: [kitSpan(KitSpan.full, kitSpecimenRegister())],
    ),
    kitSection(
      'One account (Everyday)',
      children: [
        kitSpan(
          KitSpan.full,
          LedgerRegister(
            columns: LedgerRegisterColumns.oneAccount,
            heads: const ['Time', 'Merchant', 'Category', 'Amount'],
            children: [for (final d in kitEverydayDays) _day(d)],
          ),
        ),
      ],
    ),
    kitSection(
      'Recent activity, day and time',
      children: [kitSpan(KitSpan.full, kitSpecimenRecent())],
    ),
    kitSection(
      'A month rule',
      children: [
        kitSpan(
          KitSpan.full,
          LedgerRegister(
            children: [
              _day(kitDays.last),
              LedgerMonthRule(kitSpentByMonth[1].$1, note: 'Last month'),
            ],
          ),
        ),
      ],
    ),
    kitSection(
      'The bill list',
      children: [kitSpan(KitSpan.full, kitSpecimenBills())],
    ),
  ],
);

LedgerTransactionRow _row(KitTx t, {bool withDay = false}) =>
    LedgerTransactionRow(
      title: t.title,
      category: t.subtitle,
      when: withDay ? '${t.day}, ${t.time}' : t.time,
      account: t.account,
      amount: t.amount,
      initials: t.lead,
      glyph: t.icon,
      pending: t.pending,
      onTap: () {},
    );

LedgerDayGroup _day(KitDay d) => LedgerDayGroup(
  d.label,
  note: d.note,
  net: d.net,
  rows: [for (final t in d.rows) _row(t)],
);

// --- Specimens --------------------------------------------------------------
// One builder per specimen in metadata.yaml. The stage (kitSpecimenStage)
// styles them; a builder never names a style.

/// Activity's first two days, under the desktop's column heads.
Widget kitSpecimenRegister() => LedgerRegister(
  heads: const ['Time', 'Merchant', 'Category', 'Account', 'Amount'],
  children: [for (final d in kitDays.take(2)) _day(d)],
);

/// A purchase not yet posted: Blue Fern Café this morning.
Widget kitSpecimenTransactionRow() => LedgerRegister(
  children: [
    LedgerDayGroup(
      kitDays.first.label,
      note: kitDays.first.note,
      net: kitDays.first.net,
      rows: <LedgerTransactionRow>[_row(kitBlueFern)],
    ),
  ],
);

/// Home's recent activity: each row its day and time, no day groups.
Widget kitSpecimenRecent() => LedgerRegister(
  showDay: true,
  children: <LedgerTransactionRow>[
    for (final t in kitRecent) _row(t, withDay: true),
  ],
);

/// November's bills under their column heads, then the month's total.
Widget kitSpecimenBills() {
  final month = LedgerFormat.month(kitBills.first.due);
  return LedgerSection(
    head: LedgerHead(
      'Bills',
      note: '$month · ${LedgerFormat.plural(kitBills.length, 'payee')}',
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LedgerBillList(
          heads: const ['Due', 'Payee', 'Account', 'Status', 'Amount'],
          children: [
            for (final b in kitBills)
              LedgerBillRow(
                due: b.due,
                name: b.name,
                account: b.account,
                status: b.status,
                amount: b.amount,
                autopay: b.autopay,
                onTap: () {},
              ),
          ],
        ),
        LedgerStatementTotal(title: '$month total', amount: kitBillsTotal),
      ],
    ),
  );
}
