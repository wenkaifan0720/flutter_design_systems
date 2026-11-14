/// The marks: [FrostedMonogram] and [FrostedIconMark] in their hues and quiet, at
/// 32, 36 and 56; [FrostedDateBlock] plain and soon; [FrostedTransactionMark]
/// by kind; [FrostedTag] in its tones, on the glass and with a figure;
/// [FrostedSwatch] before a legend's name; [FrostedPeople] of [FrostedPerson]s,
/// one chosen; and [FrostedCheckbox] at rest and kept.
library;

import 'package:flutter/material.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../kit.dart';

Widget kitMarksDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Marks',
  sections: [
    kitSection('Monograms', children: [kitSpecimenMonograms()]),
    kitSection('Tokens, and the quiet token', children: [kitSpecimenTokens()]),
    kitSection('Three sizes', children: [kitSpecimenMarkSizes()]),
    kitSection('Date blocks', children: [kitSpecimenDateBlocks()]),
    kitSection(
      'A transaction\'s mark by kind',
      children: [kitSpecimenTransactionMarks()],
    ),
    kitSection('Chips', children: [kitSpecimenChips()]),
    kitSection(
      'Swatches before a legend\'s names',
      children: [
        Builder(
          builder: (context) {
            final t = context.frostedTheme;
            // A Wrap: at large text the names take a second line.
            return Wrap(
              spacing: FrostedSpacing.s16,
              runSpacing: FrostedSpacing.s8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                for (final (hue, name) in [
                  (t.hues.orchid, 'Groceries'),
                  (t.hues.coral, 'Dining'),
                  (t.hues.mint, 'Transport'),
                ])
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: FrostedSpacing.s6,
                    children: [
                      FrostedSwatch(hue),
                      Text(name, style: t.textTheme.bodyMedium),
                    ],
                  ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: FrostedSpacing.s6,
                  children: [
                    FrostedSwatch(t.hues.seafoam, part: true),
                    Text('Left', style: t.textTheme.bodyMedium),
                  ],
                ),
              ],
            );
          },
        ),
      ],
    ),
    kitSection('People to pick from', children: [kitSpecimenPeople()]),
    kitSection('One chosen', children: [kitSpecimenPeopleChosen()]),
    kitSection('Checks at rest and kept', children: [kitSpecimenCheck()]),
  ],
);

/// Three merchants in their categories' hues, and a person with none.
Widget kitSpecimenMonograms() => Builder(
  builder: (context) {
    final t = context.frostedTheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: FrostedSpacing.s12,
      children: [
        FrostedMonogram('Blue Fern Café', hue: t.hues.coral),
        FrostedMonogram('Linden Court Apartments', hue: t.hues.periwinkle),
        FrostedMonogram('Cinema Lumen', hue: t.hues.lemon),
        const FrostedMonogram('Jonah Reyes'),
      ],
    );
  },
);

/// Three accounts' tokens in their hues, and the quiet token of a repeat.
Widget kitSpecimenTokens() => Builder(
  builder: (context) {
    final t = context.frostedTheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: FrostedSpacing.s12,
      children: [
        FrostedIconMark(
          LucideIcons.wallet,
          hue: t.hues.cyan,
          label: 'Everyday',
        ),
        FrostedIconMark(
          LucideIcons.plane,
          hue: t.hues.sunset,
          label: 'Lisbon fund',
        ),
        FrostedIconMark(
          LucideIcons.house,
          hue: t.hues.periwinkle,
          label: 'Rent',
        ),
        const FrostedIconMark(LucideIcons.repeat, quiet: true),
      ],
    );
  },
);

/// A monogram and a token at 32, 36 and 56.
Widget kitSpecimenMarkSizes() => Builder(
  builder: (context) {
    final t = context.frostedTheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      spacing: FrostedSpacing.s12,
      children: [
        for (final size in FrostedMarkSize.values) ...[
          FrostedMonogram('Blue Fern Café', hue: t.hues.coral, size: size),
          FrostedIconMark(LucideIcons.wallet, hue: t.hues.cyan, size: size),
        ],
      ],
    );
  },
);

/// A bill's date, and one due soon in the rent's hue.
Widget kitSpecimenDateBlocks() => Builder(
  builder: (context) => Row(
    mainAxisSize: MainAxisSize.min,
    spacing: FrostedSpacing.s12,
    children: [
      FrostedDateBlock(DateTime(2026, 11, 12)),
      FrostedDateBlock(
        DateTime(2026, 11, 1),
        soon: true,
        hue: context.frostedTheme.hues.periwinkle,
      ),
    ],
  ),
);

/// A purchase, money in, a move between accounts and a card payment.
Widget kitSpecimenTransactionMarks() => Builder(
  builder: (context) => Row(
    mainAxisSize: MainAxisSize.min,
    spacing: FrostedSpacing.s12,
    children: [
      FrostedTransactionMark.purchase(
        'Blue Fern Café',
        hue: context.frostedTheme.hues.coral,
      ),
      const FrostedTransactionMark.income('Northwind Studio'),
      const FrostedTransactionMark.move(),
      const FrostedTransactionMark.payment(),
    ],
  ),
);

/// Chips in every tone as the source sets them (Posted with its check,
/// On track green, Behind warm with the clock, Over budget, Frozen cold
/// with the snowflake), the card's glass pill, and one with a figure.
Widget kitSpecimenChips() => const Wrap(
  spacing: FrostedSpacing.s8,
  runSpacing: FrostedSpacing.s8,
  children: [
    FrostedTag('Posted', icon: LucideIcons.check),
    FrostedTag('On track', icon: LucideIcons.check, tone: FrostedTone.success),
    FrostedTag('Behind', icon: LucideIcons.clock, tone: FrostedTone.warning),
    FrostedTag('Over budget', tone: FrostedTone.danger),
    FrostedTag('Frozen', icon: LucideIcons.snowflake, tone: FrostedTone.info),
    FrostedTag('Credit', variant: FrostedTagVariant.glass),
    FrostedTag('results', figure: '13'),
  ],
);

/// Four people to send to, none chosen yet.
Widget kitSpecimenPeople() => FrostedPeople(
  children: [
    for (final name in const [
      'Jonah Reyes',
      'Priya Anand',
      'Sam Okoro',
      'Ines Park',
    ])
      FrostedPerson(name, onChanged: (_) {}),
  ],
);

/// A split: Priya chosen with what she owes, the others stepped back.
Widget kitSpecimenPeopleChosen() => FrostedPeople(
  children: [
    FrostedPerson('Jonah Reyes', dimmed: true, onChanged: (_) {}),
    FrostedPerson(
      'Priya Anand',
      note: '\$42.10',
      selected: true,
      onChanged: (_) {},
    ),
    FrostedPerson('Sam Okoro', dimmed: true, onChanged: (_) {}),
    FrostedPerson('Ines Park', dimmed: true, onChanged: (_) {}),
  ],
);

/// A check at rest beside its words, and one kept that only reports
/// (DERIVED: the ring at rest is drawn from the tokens).
Widget kitSpecimenCheck() => Builder(
  builder: (context) {
    final t = context.frostedTheme;
    return Wrap(
      spacing: FrostedSpacing.s24,
      runSpacing: FrostedSpacing.s12,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          spacing: FrostedSpacing.s8,
          children: [
            FrostedCheckbox(
              value: false,
              label: 'Round up spare change',
              onChanged: (_) {},
            ),
            // Flexible: at large text the words wrap beside the box.
            Flexible(
              child: Text(
                'Round up spare change',
                style: t.textTheme.titleMedium,
              ),
            ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          spacing: FrostedSpacing.s8,
          children: [
            // A live check (a null onChanged would paint it disabled).
            FrostedCheckbox(value: true, label: 'Rent paid', onChanged: (_) {}),
            Flexible(child: Text('Rent paid', style: t.textTheme.titleMedium)),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          spacing: FrostedSpacing.s8,
          children: [
            FrostedCheckbox(
              value: null,
              tristate: true,
              label: 'Some bills paid',
              onChanged: (_) {},
            ),
            Flexible(
              child: Text('Some bills paid', style: t.textTheme.titleMedium),
            ),
          ],
        ),
      ],
    );
  },
);
