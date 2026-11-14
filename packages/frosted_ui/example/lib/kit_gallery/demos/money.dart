/// The figures: [FrostedMoney] standing alone at its four sizes and as money
/// in; [FrostedAmount] at a row's end (out, in, a balance, a day's net);
/// [FrostedFigure]s arranged by a [FrostedStats] as lines, columns and cells;
/// [FrostedPercent] at its two sizes with [FrostedNumberText] in a line of words; and
/// the [FrostedCounter] rolling to its value.
library;

import 'package:flutter/material.dart';
import 'package:frosted_ui/frosted_ui.dart';

import '../kit.dart';

Widget kitMoneyDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Money',
  sections: [
    kitSection(
      'Money at 64 (96 on the desktop), 40 and 28',
      children: [
        kitSpecimenMoneyDisplay(),
        kitSpecimenMoneyFigure(),
        kitSpecimenMoneySmall(),
      ],
    ),
    kitSection('Money in', children: [kitSpecimenMoneyIn()]),
    kitSection('Amounts at a row\'s end', children: [kitSpecimenAmounts()]),
    kitSection('Stats as lines', children: [kitSpecimenStatsLines()]),
    kitSection('Stats as columns', children: [kitSpecimenStatsColumns()]),
    kitSection('Stats as cells', children: [kitSpecimenStatsCells()]),
    kitSection(
      'A percentage, and figures in a line',
      children: [
        kitSpecimenPercent(),
        Builder(
          builder: (context) {
            final t = context.frostedTheme;
            return DefaultTextStyle(
              style: t.textTheme.bodyMedium,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('of \$'),
                  FrostedNumberText('4,000'),
                  Text(' limit'),
                ],
              ),
            );
          },
        ),
      ],
    ),
    kitSection(
      'A counter rolling to its value',
      children: [kitSpecimenCounter()],
    ),
  ],
);

/// The net worth at 64, its `$` and cents at 28 in the quiet ink.
Widget kitSpecimenMoneyDisplay() => const Align(
  alignment: AlignmentDirectional.centerStart,
  heightFactor: 1,
  child: FrostedMoney(48210.66),
);

/// October's spend at 40 in a tile.
Widget kitSpecimenMoneyFigure() => const Align(
  alignment: AlignmentDirectional.centerStart,
  heightFactor: 1,
  child: FrostedMoney(3214.09, size: FrostedMoneySize.regular),
);

/// The rent at 28 in its band, whole dollars.
Widget kitSpecimenMoneySmall() => const Align(
  alignment: AlignmentDirectional.centerStart,
  heightFactor: 1,
  child: FrostedMoney(1150, size: FrostedMoneySize.small),
);

/// Money in this month, green with its plus.
Widget kitSpecimenMoneyIn() => const Align(
  alignment: AlignmentDirectional.centerStart,
  heightFactor: 1,
  child: FrostedMoney(
    6825,
    flow: FrostedMoneyFlow.inflow,
    sign: true,
    size: FrostedMoneySize.small,
  ),
);

/// Four rows' amounts: a purchase out, a payment in, the Everyday balance
/// unsigned, and a day head's net at 12 in the text face.
Widget kitSpecimenAmounts() => Builder(
  builder: (context) {
    final t = context.frostedTheme;
    Widget row(String name, Widget amount) => Padding(
      padding: const EdgeInsets.symmetric(vertical: FrostedSpacing.s8),
      child: Row(
        children: [
          Expanded(child: Text(name, style: t.textTheme.titleMedium)),
          amount,
        ],
      ),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        row('Blue Fern Café', const FrostedAmount(-10.99)),
        row('Northwind Studio', const FrostedAmount(3412.5)),
        row('Everyday', const FrostedAmount(6248.30, signed: false)),
        Row(
          children: [
            Expanded(child: Text('Today', style: t.textTheme.labelMedium)),
            const FrostedAmount(-12.4, size: FrostedAmountSize.extraSmall),
          ],
        ),
      ],
    );
  },
);

/// The spending tile's three stats, figure at the start and caption at the
/// end, hairlines between.
Widget kitSpecimenStatsLines() => const FrostedStats(
  children: [
    FrostedFigure(3214.09, caption: 'Spent'),
    FrostedFigure(285.91, caption: 'Left'),
    FrostedFigure(3102.6, caption: 'September'),
  ],
);

/// A merchant record's summary: two figures side by side.
Widget kitSpecimenStatsColumns() => const Align(
  alignment: AlignmentDirectional.centerStart,
  heightFactor: 1,
  child: FrostedStats(
    variant: FrostedStatVariant.columns,
    children: [
      FrostedFigure(84.25, caption: 'in October'),
      FrostedFigure(6.48, caption: 'a visit'),
    ],
  ),
);

/// The credit card's three cells: due with its date, available, the limit.
Widget kitSpecimenStatsCells() => const FrostedStats(
  variant: FrostedStatVariant.cells,
  children: [
    FrostedFigure(1326.44, caption: 'Due', note: 'Nov 12'),
    FrostedFigure(2673.56, caption: 'Available'),
    FrostedFigure(4000, caption: 'Limit', cents: false),
  ],
);

/// A category's share of its budget at 20, a goal card's at 16.
Widget kitSpecimenPercent() => const Row(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.end,
  spacing: FrostedSpacing.s24,
  children: [
    FrostedFigure(0, caption: 'Of budget', value: FrostedPercent(115)),
    FrostedPercent(71, size: FrostedPercentSize.small),
  ],
);

/// The net worth rolling to its value (DERIVED: the source never rolls a
/// figure).
Widget kitSpecimenCounter() => const Align(
  alignment: AlignmentDirectional.centerStart,
  heightFactor: 1,
  child: FrostedCounter(48210.66, size: FrostedMoneySize.regular),
);
