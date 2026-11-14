/// The meters: the [FrostedTrack] of bands at its three sizes with its
/// labels, pace tick, scale and [FrostedLegend]; [FrostedBar] in its four
/// styles; [FrostedMeter] plain, over and small; [FrostedBudgetBar];
/// [FrostedCompareBars]; [FrostedMerchantBars]; [FrostedInOut]; [FrostedSplitBar];
/// [FrostedStatementTimeline]; [FrostedVisitStrip]; [FrostedDueLine];
/// [FrostedBalanceChanges]; [FrostedRoute]; and [FrostedDoneMark].
library;

import 'package:flutter/material.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../kit.dart';

Widget kitMetersDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Meters',
  sections: [
    kitSection(
      'The prism track',
      children: [
        kitSpecimenTrackGoals(),
        kitSpecimenLegendAllocation(),
        kitSpecimenTrackPace(),
        kitSpecimenTrackAllocation(),
        kitSpecimenTrackSpending(),
        kitSpecimenSplitBar(),
      ],
    ),
    kitSection(
      "A move's tracks: leaving Everyday, arriving in Savings",
      children: [kitSpecimenTrackMove()],
    ),
    kitSection(
      'Bars',
      children: [
        kitSpecimenBar(),
        kitSpecimenBarThin(),
        kitSpecimenTube(),
        kitSpecimenTubeLarge(),
      ],
    ),
    kitSection(
      'Meters',
      children: [
        kitSpecimenMeter(),
        kitSpecimenMeterOver(),
        kitSpecimenMeterSmall(),
      ],
    ),
    kitSection('Over bar', children: [kitSpecimenOverBar()]),
    kitSection('Compare', children: [kitSpecimenCompareBars()]),
    kitSection('Merchants', children: [kitSpecimenMerchantBars()]),
    kitSection('In and out', children: [kitSpecimenInOut()]),
    kitSection('Statement', children: [kitSpecimenStatement()]),
    kitSection('Visit strip', children: [kitSpecimenVisitStrip()]),
    kitSection('Balance changes', children: [kitSpecimenBalanceChanges()]),
    kitSection('Done', children: [kitSpecimenDoneMark()]),
  ],
);

/// The goals' large track: three goals and what is left, the three-across
/// legend under it.
Widget kitSpecimenTrackGoals() => Builder(
  builder: (context) {
    final h = context.frostedTheme.hues;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        FrostedTrack(
          bands: [
            FrostedBand(20860, hue: h.azure, name: 'Emergency fund'),
            FrostedBand(2840, hue: h.sunset, name: 'Lisbon in May'),
            FrostedBand(640, hue: h.lime, name: 'New bike'),
            FrostedBand(5460, variant: FrostedBandVariant.left, name: 'to go'),
          ],
        ),
        FrostedLegend(
          variant: FrostedLegendVariant.threeColumns,
          children: [
            FrostedLegendEntry('Emergency fund', hue: h.azure, amount: 20860),
            FrostedLegendEntry('Lisbon in May', hue: h.sunset, amount: 2840),
            FrostedLegendEntry('New bike', hue: h.lime, amount: 640),
          ],
        ),
      ],
    );
  },
);

/// Where the year's saving went: the three goals on the large track, the
/// legend three across on a phone and, beside the chart on the desktop,
/// rows with hairlines between.
Widget kitSpecimenLegendAllocation() => Builder(
  builder: (context) {
    final h = context.frostedTheme.hues;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        FrostedTrack(
          bands: [
            FrostedBand(5586.27, hue: h.azure, name: 'Emergency fund'),
            FrostedBand(2200, hue: h.sunset, name: 'Lisbon in May'),
            FrostedBand(640, hue: h.lime, name: 'New bike'),
          ],
        ),
        FrostedLegend(
          variant: FrostedLegendVariant.allocation,
          children: [
            FrostedLegendEntry('Emergency fund', hue: h.azure, amount: 5586.27),
            FrostedLegendEntry('Lisbon in May', hue: h.sunset, amount: 2200),
            FrostedLegendEntry('New bike', hue: h.lime, amount: 640),
          ],
        ),
      ],
    );
  },
);

/// A record's merchant in its category's September: the small track with
/// the rest as a part band, the budget's pace tick and label, and the two
/// parts under it.
Widget kitSpecimenTrackPace() => Builder(
  builder: (context) {
    final t = context.frostedTheme;
    final hue = t.hues.coral;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FrostedTrack(
          size: FrostedTrackSize.small,
          bands: [
            FrostedBand(38.40, hue: hue, name: 'Mesa Taqueria'),
            FrostedBand(
              224.70,
              hue: hue,
              variant: FrostedBandVariant.part,
              name: 'The rest of September',
            ),
          ],
          pace: 250 / 263.10,
          paceLabel: 'Budget \$250',
          scaleStart: Text('\$0', style: t.textTheme.labelMedium),
        ),
        FrostedLegend(
          variant: FrostedLegendVariant.rows,
          children: [
            FrostedLegendEntry(
              'Mesa Taqueria',
              hue: hue,
              amount: 38.40,
              current: true,
            ),
            FrostedLegendEntry(
              'The rest of September',
              hue: hue,
              amount: 224.70,
              part: true,
            ),
          ],
        ),
      ],
    );
  },
);

/// Investing by kind: the small track and its rows with their shares.
Widget kitSpecimenTrackAllocation() => Builder(
  builder: (context) {
    final h = context.frostedTheme.hues;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FrostedTrack(
          size: FrostedTrackSize.small,
          bands: [
            FrostedBand(39432.60, hue: h.turquoise, name: 'Stocks'),
            FrostedBand(7336.10, hue: h.lavender, name: 'Bonds'),
            FrostedBand(2152, hue: h.silver, name: 'Cash'),
          ],
        ),
        FrostedLegend(
          variant: FrostedLegendVariant.rows,
          children: [
            FrostedLegendEntry(
              'Stocks',
              hue: h.turquoise,
              share: 81,
              amount: 39432.60,
            ),
            FrostedLegendEntry(
              'Bonds',
              hue: h.lavender,
              share: 15,
              amount: 7336.10,
            ),
            FrostedLegendEntry('Cash', hue: h.silver, share: 4, amount: 2152),
          ],
        ),
      ],
    );
  },
);

/// Where October went: the eight categories on the large track and the
/// two-column legend under it.
Widget kitSpecimenTrackSpending() => Builder(
  builder: (context) {
    final h = context.frostedTheme.hues;
    const names = [
      'Rent & home',
      'Groceries',
      'Dining out',
      'Shopping',
      'Fun',
      'Transport',
      'Health',
      'Subscriptions',
    ];
    const amounts = [
      1150.0,
      412.36,
      286.40,
      214.75,
      143.45,
      118.20,
      96.0,
      64.96,
    ];
    final hues = h.categories;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 14,
      children: [
        FrostedTrack(
          bands: [
            for (var i = 0; i < names.length; i++)
              FrostedBand(amounts[i], hue: hues[i], name: names[i]),
          ],
        ),
        FrostedLegend(
          children: [
            for (var i = 0; i < names.length; i++)
              FrostedLegendEntry(names[i], hue: hues[i], amount: amounts[i]),
          ],
        ),
      ],
    );
  },
);

/// A split's two shares, each named inside its band.
Widget kitSpecimenSplitBar() => Builder(
  builder: (context) => FrostedSplitBar(
    hue: context.frostedTheme.hues.lemon,
    shares: const [FrostedShare('You', 14), FrostedShare('Jonah', 14)],
  ),
);

/// The least tracks of a move: \$500 leaving Everyday, \$500 arriving in
/// Savings.
Widget kitSpecimenTrackMove() => Builder(
  builder: (context) {
    final h = context.frostedTheme.hues;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        FrostedTrack(
          size: FrostedTrackSize.extraSmall,
          bands: [
            FrostedBand(5748.30, hue: h.cyan, name: 'Everyday'),
            FrostedBand(
              500,
              hue: h.cyan,
              variant: FrostedBandVariant.leave,
              name: 'leaving',
            ),
          ],
        ),
        FrostedTrack(
          size: FrostedTrackSize.extraSmall,
          bands: [
            FrostedBand(21500, hue: h.seafoam, name: 'Savings'),
            FrostedBand(
              500,
              hue: h.seafoam,
              variant: FrostedBandVariant.arrive,
              name: 'arriving',
            ),
          ],
        ),
      ],
    );
  },
);

/// A merchant's share as the 6 bar.
Widget kitSpecimenBar() => Builder(
  builder: (context) => FrostedBar(
    0.7773,
    hue: context.frostedTheme.hues.coral,
    variant: FrostedBarVariant.bar,
  ),
);

/// The thin bar under a merchant row.
Widget kitSpecimenBarThin() => Builder(
  builder: (context) => FrostedBar(
    0.6819,
    hue: context.frostedTheme.hues.coral,
    variant: FrostedBarVariant.thin,
  ),
);

/// A goal's tube, 71% saved.
Widget kitSpecimenTube() => Builder(
  builder: (context) => FrostedBar(0.71, hue: context.frostedTheme.hues.sunset),
);

/// The card's limit as the large tube with the autopay tick and its scale.
Widget kitSpecimenTubeLarge() => Builder(
  builder: (context) => FrostedBar(
    0.6299,
    hue: context.frostedTheme.hues.iris,
    variant: FrostedBarVariant.tubeLarge,
    tick: 0.5,
    scaleStart: '63% used',
    scaleEnd: '\$740.18 to go',
  ),
);

/// A pane's meter, 92% of its budget.
Widget kitSpecimenMeter() => Builder(
  builder: (context) =>
      FrostedMeter(0.9164, hue: context.frostedTheme.hues.orchid),
);

/// A pane over its budget: the budget in the hue, the rest in red.
Widget kitSpecimenMeterOver() => Builder(
  builder: (context) => FrostedMeter(
    250 / 286.40,
    hue: context.frostedTheme.hues.coral,
    over: true,
  ),
);

/// A small pane's 3 meter.
Widget kitSpecimenMeterSmall() => Builder(
  builder: (context) => FrostedMeter(
    0.74,
    hue: context.frostedTheme.hues.mint,
    size: FrostedMeterSize.small,
  ),
);

/// Dining out over its budget on the large over bar.
Widget kitSpecimenOverBar() => Builder(
  builder: (context) => FrostedBudgetBar(
    spent: 286.40,
    budget: 250,
    hue: context.frostedTheme.hues.coral,
    size: FrostedBudgetBarSize.large,
  ),
);

/// Dining out month by month, the \$250 budget's tick on both.
Widget kitSpecimenCompareBars() => Builder(
  builder: (context) {
    final hue = context.frostedTheme.hues.coral;
    return FrostedCompareBars(
      children: [
        FrostedCompareRow(
          name: 'September',
          amount: 263.10,
          fraction: 263.10 / 286.40,
          hue: hue,
          tick: 250 / 286.40,
        ),
        FrostedCompareRow(
          name: 'October so far',
          amount: 286.40,
          fraction: 1,
          hue: hue,
          tick: 250 / 286.40,
        ),
      ],
    );
  },
);

/// Dining out's merchants in October, each a link.
Widget kitSpecimenMerchantBars() => Builder(
  builder: (context) {
    final hue = context.frostedTheme.hues.coral;
    return FrostedMerchantBars(
      children: [
        FrostedMerchant(
          name: 'Blue Fern Café',
          subtitle: '13 visits',
          amount: 84.25,
          fraction: 1,
          hue: hue,
          onPressed: () {},
        ),
        FrostedMerchant(
          name: 'Rosemary & Rye',
          subtitle: '3 visits',
          amount: 65.49,
          fraction: 65.49 / 84.25,
          hue: hue,
          onPressed: () {},
        ),
        FrostedMerchant(
          name: 'Noodle Hall',
          subtitle: '3 visits',
          amount: 57.45,
          fraction: 57.45 / 84.25,
          hue: hue,
          onPressed: () {},
        ),
        FrostedMerchant(
          name: 'Mesa Taqueria',
          subtitle: '2 visits',
          amount: 38.40,
          fraction: 38.40 / 84.25,
          hue: hue,
          onPressed: () {},
        ),
      ],
    );
  },
);

/// October's money in against what went out, where it went and what was
/// kept.
Widget kitSpecimenInOut() => Builder(
  builder: (context) {
    final h = context.frostedTheme.hues;
    return FrostedInOut(
      moneyIn: 6825,
      spent: 2486.12,
      bands: [
        FrostedBand(1150, hue: h.periwinkle, name: 'Rent & home'),
        FrostedBand(412.36, hue: h.orchid, name: 'Groceries'),
        FrostedBand(286.40, hue: h.coral, name: 'Dining out'),
        FrostedBand(214.75, hue: h.apricot, name: 'Shopping'),
        FrostedBand(143.45, hue: h.lemon, name: 'Fun'),
        FrostedBand(118.20, hue: h.mint, name: 'Transport'),
        FrostedBand(96, hue: h.teal, name: 'Health'),
        FrostedBand(64.96, hue: h.sky, name: 'Subscriptions'),
      ],
    );
  },
);

/// The credit card's statement: paid Oct 12, closed Oct 28, due Nov 12.
Widget kitSpecimenStatement() => FrostedStatementTimeline(
  paid: DateTime(2026, 10, 12),
  closed: DateTime(2026, 10, 28),
  due: DateTime(2026, 11, 12),
  paidAmount: 1180.22,
  closedAmount: 1326.44,
);

/// Mesa Taqueria's September: two visits on the 3rd, the record's own on
/// the 29th.
Widget kitSpecimenVisitStrip() => Builder(
  builder: (context) => FrostedVisitStrip(
    month: DateTime(2026, 9),
    visits: [DateTime(2026, 9, 3), DateTime(2026, 9, 3), DateTime(2026, 9, 29)],
    current: DateTime(2026, 9, 29),
    hue: context.frostedTheme.hues.coral,
  ),
);

/// Everyday and Savings after \$500 moves between them.
Widget kitSpecimenBalanceChanges() => Builder(
  builder: (context) {
    final h = context.frostedTheme.hues;
    return FrostedBalanceChanges(
      children: [
        FrostedBalanceChange(
          name: 'Everyday',
          icon: LucideIcons.wallet,
          hue: h.cyan,
          before: 6248.30,
          after: 5748.30,
        ),
        FrostedBalanceChange(
          name: 'Savings',
          icon: LucideIcons.landmark,
          hue: h.seafoam,
          before: 21500,
          after: 22000,
        ),
      ],
    );
  },
);

/// A transfer sent: the check in its rings.
Widget kitSpecimenDoneMark() => const FrostedDoneMark();
