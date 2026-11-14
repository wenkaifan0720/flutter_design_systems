/// The cards: the [FrostedCreditCard] plain, frozen and on its desktop
/// stage; the [FrostedDebitCard] beside its words; the [FrostedCardNumber] for
/// the person alone; a [FrostedGoalCard] and a [FrostedGoalRow]; the
/// [FrostedNewGoal] card; and the [FrostedMosaic] of [FrostedPane]s, with one
/// pane on its own.
library;

import 'package:flutter/material.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:frosted_ui/frosted_host.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../kit.dart';

Widget kitCardDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Cards',
  sections: [
    kitSection(
      // The stage turns the card from 600 wide; on a phone the third is the
      // plain card again, so the caption says so (round 11).
      'The credit card: plain, frozen, and on its stage (from 600 wide)',
      children: [
        kitSpecimenCreditCard(),
        kitSpecimenCreditCardFrozen(),
        kitSpecimenCreditCardStage(),
      ],
    ),
    kitSection('Debit card', children: [kitSpecimenDebitCard()]),
    kitSection('Card number', children: [kitSpecimenCardNumber()]),
    kitSection(
      'Goals',
      children: [
        kitSpecimenGoalCard(),
        kitSpecimenGoalRow(),
        kitSpecimenNewGoal(),
      ],
    ),
    kitSection('The spend mosaic', children: [kitSpecimenMosaic()]),
  ],
);

/// A credit card: \$1,326.44 of a \$4,000 limit, autopay on, a link.
Widget kitSpecimenCreditCard() => FrostedCreditCard(
  balance: 1326.44,
  limit: 4000,
  mask: '4821',
  brand: 'harbor',
  note: 'Autopay · due Nov 12',
  onPressed: () {},
);

/// The card frozen: the frost and its snowflake over the pearl.
Widget kitSpecimenCreditCardFrozen() => const FrostedCreditCard(
  balance: 1326.44,
  limit: 4000,
  mask: '4821',
  brand: 'harbor',
  note: 'Autopay · due Nov 12',
  frozen: true,
);

/// The card on its 300 stage, turned 4deg, from
/// the desktop width; the plain card on a phone.
Widget kitSpecimenCreditCardStage() => const FrostedCreditCard(
  balance: 1326.44,
  limit: 4000,
  mask: '4821',
  brand: 'harbor',
  note: 'Autopay · due Nov 12',
  stage: true,
);

/// The everyday debit card's art beside its name and account.
Widget kitSpecimenDebitCard() => Builder(
  builder: (context) {
    final t = context.frostedTheme;
    return Row(
      spacing: FrostedChromeMetrics.debitCardGap,
      children: [
        const FrostedDebitCard(mask: '3907'),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 2,
            children: [
              Text('Everyday debit ·· 3907', style: t.textTheme.titleMedium),
              Text(
                'Pays from Everyday · expires 09/29',
                style: t.textTheme.bodyMedium.c(t.colorScheme.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  },
);

/// The credit card's number, expiry, CVC and name, as the details sheet
/// shows them.
Widget kitSpecimenCardNumber() => const FrostedCardNumber(
  number: '4242424242427730',
  expires: '09/29',
  cvc: '317',
  name: 'Maren Holt',
);

/// Lisbon in May, behind: \$2,840.00 of \$4,000, 71%.
Widget kitSpecimenGoalCard() => Builder(
  builder: (context) => FrostedGoalCard(
    name: 'Lisbon in May',
    subtitle: 'by May 2027',
    icon: LucideIcons.plane,
    hue: context.frostedTheme.hues.sunset,
    saved: 2840,
    target: 4000,
    status: FrostedGoalStatus.behind,
    onPressed: () {},
  ),
);

/// Home's goals: Lisbon behind, the Emergency fund and the bike on track.
Widget kitSpecimenGoalRow() => Builder(
  builder: (context) {
    final h = context.frostedTheme.hues;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FrostedGoalRow(
          name: 'Lisbon in May',
          icon: LucideIcons.plane,
          hue: h.sunset,
          saved: 2840,
          target: 4000,
          by: 'May 2027',
          status: FrostedGoalStatus.behind,
          first: true,
          onPressed: () {},
        ),
        FrostedGoalRow(
          name: 'Emergency fund',
          icon: LucideIcons.shield,
          hue: h.azure,
          saved: 20860,
          target: 24000,
          onPressed: () {},
        ),
        FrostedGoalRow(
          name: 'New bike',
          icon: LucideIcons.bike,
          hue: h.lime,
          saved: 640,
          target: 1800,
          by: 'Oct 2027',
          onPressed: () {},
        ),
      ],
    );
  },
);

/// The card that starts a goal.
Widget kitSpecimenNewGoal() => FrostedNewGoal(onPressed: () {});

/// October's mosaic: the rent across the top, groceries and shopping down
/// the first column, dining over the block of four down the second.
Widget kitSpecimenMosaic() => Builder(
  builder: (context) {
    final h = context.frostedTheme.hues;
    return FrostedMosaic(
      title: 'October',
      panes: [
        FrostedPane.rent(
          name: 'Rent & home',
          hue: h.periwinkle,
          spent: 1150,
          budget: 1150,
          ticket: FrostedTicket(
            name: 'Linden Court',
            title: 'Linden Court Apartments',
            subtitle: 'One payment from Everyday',
            hue: h.periwinkle,
            chip: 'Paid',
            chipIcon: LucideIcons.check,
          ),
          paid: 'Paid Oct 1',
          nextDue: 'Next due Nov 1',
          onPressed: () {},
        ),
        FrostedPane(
          name: 'Groceries',
          hue: h.orchid,
          spent: 412.36,
          budget: 450,
          variant: FrostedPaneVariant.featured,
          meta: '8% less than Sep',
          onPressed: () {},
        ),
        FrostedPane(
          name: 'Dining out',
          hue: h.coral,
          spent: 286.40,
          budget: 250,
          variant: FrostedPaneVariant.featured,
          alert: 'Over by \$36.40',
          onPressed: () {},
        ),
        FrostedPane(
          name: 'Shopping',
          hue: h.apricot,
          spent: 214.75,
          budget: 300,
          onPressed: () {},
        ),
        FrostedPane(
          name: 'Fun',
          hue: h.lemon,
          spent: 143.45,
          budget: 200,
          variant: FrostedPaneVariant.small,
          onPressed: () {},
        ),
        FrostedPane(
          name: 'Transport',
          hue: h.mint,
          spent: 118.20,
          budget: 160,
          variant: FrostedPaneVariant.small,
          onPressed: () {},
        ),
        FrostedPane(
          name: 'Health',
          hue: h.teal,
          spent: 96,
          budget: 120,
          variant: FrostedPaneVariant.small,
          onPressed: () {},
        ),
        FrostedPane(
          name: 'Subs',
          hue: h.sky,
          spent: 64.96,
          budget: 70,
          variant: FrostedPaneVariant.small,
          onPressed: () {},
        ),
      ],
    );
  },
);
