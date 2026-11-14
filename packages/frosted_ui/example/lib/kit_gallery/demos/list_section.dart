/// The list section, a titled section of rows of one kind: in its tile
/// under a head saying how many, with an act at the head's end, or on the
/// canvas under a section head on a phone.
library;

import 'package:flutter/material.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../kit.dart';

Widget kitListSectionDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'List section',
  sections: [
    kitSection(
      'Transactions in their tile',
      children: [kitSpecimenListSection()],
    ),
    kitSection(
      'With See all at the head\'s end',
      children: [kitSpecimenListSectionAction()],
    ),
    kitSection(
      'On the canvas under a section head (the desktop heads its tile)',
      children: [kitSpecimenListSectionCanvas()],
    ),
  ],
);

List<Widget> _recent(BuildContext context) {
  final t = context.frostedTheme;
  return [
    const FrostedDayHead('Today', net: -9.65, first: true),
    FrostedTransactionRow(
      mark: FrostedTransactionMark.purchase(
        'Blue Fern Café',
        hue: t.hues.coral,
      ),
      title: 'Blue Fern Café',
      subtitle: 'Dining out · 8:12 AM',
      amount: -6.75,
      pending: true,
      account: 'Harbor Card',
      accountIcon: LucideIcons.creditCard,
      onPressed: () {},
    ),
    FrostedTransactionRow(
      mark: FrostedTransactionMark.purchase('Harbor Transit', hue: t.hues.mint),
      title: 'Harbor Transit',
      subtitle: 'Transport · 7:48 AM',
      amount: -2.90,
      pending: true,
      account: 'Everyday',
      accountIcon: LucideIcons.wallet,
      onPressed: () {},
    ),
    // The day's net is its rows' sum (round 11: +$3,409.60 over the one
    // $3,412.50 row).
    const FrostedDayHead('Fri, Oct 23', net: 3412.50),
    FrostedTransactionRow(
      mark: FrostedTransactionMark.income('Northwind Studio'),
      title: 'Northwind Studio',
      subtitle: 'Paycheck · 6:31 AM',
      amount: 3412.50,
      account: 'Everyday',
      accountIcon: LucideIcons.wallet,
      onPressed: () {},
    ),
  ];
}

// --- catalog specimens -------------------------------------------------------

/// Everyday's transactions in their tile, 32 in October at the head's end.
Widget kitSpecimenListSection() => Builder(
  builder: (context) => FrostedListSection(
    title: 'Transactions',
    aside: '32 in October',
    rows: _recent(context),
  ),
);

/// Home's recent activity with See all at the head's end.
Widget kitSpecimenListSectionAction() => Builder(
  builder: (context) => FrostedListSection(
    title: 'Recent',
    trailing: FrostedButton.glass(
      'See all',
      size: FrostedButtonSize.small,
      onPressed: () {},
    ),
    rows: _recent(context).take(3).toList(),
  ),
);

/// Home's accounts under a section head on the canvas (the desktop heads
/// the tile instead).
Widget kitSpecimenListSectionCanvas() => Builder(
  builder: (context) {
    final t = context.frostedTheme;
    return FrostedListSection(
      title: 'Accounts',
      aside: '3 accounts',
      tile: false,
      rows: [
        FrostedListTile(
          leading: FrostedIconMark(LucideIcons.wallet, hue: t.hues.cyan),
          title: 'Everyday',
          meta: 'Checking ·· 4821',
          trailing: const FrostedAmount(6248.30, signed: false),
          onPressed: () {},
        ),
        FrostedListTile(
          leading: FrostedIconMark(LucideIcons.piggyBank, hue: t.hues.seafoam),
          title: 'Savings',
          meta: '4.10% APY ·· 9015',
          trailing: const FrostedAmount(21500, signed: false),
          onPressed: () {},
        ),
        FrostedListTile(
          leading: FrostedIconMark(LucideIcons.plane, hue: t.hues.sunset),
          title: 'Lisbon fund',
          meta: 'Goal pot',
          trailing: const FrostedAmount(2840, signed: false),
          onPressed: () {},
        ),
      ],
    );
  },
);
