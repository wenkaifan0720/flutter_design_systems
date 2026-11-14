/// [FrostedSwipeActions] on a row: the trailing actions (Pin in the ink,
/// Delete in the danger fill) and a leading one (Paid on the wash), one
/// standing open for the preview.
library;

import 'package:flutter/material.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../kit.dart';

Widget kitSwipeDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Swipe actions',
  sections: [
    kitSection(
      'Drag a row',
      children: [
        FrostedListSection(
          hairlines: true,
          rows: [
            FrostedSwipeActions(
              fullSwipe: true,
              trailing: [
                FrostedSwipeAction(
                  label: 'Delete',
                  icon: LucideIcons.trash2,
                  tone: FrostedSwipeTone.destructive,
                  onPressed: () {},
                ),
                FrostedSwipeAction(
                  label: 'Pin',
                  icon: LucideIcons.pin,
                  tone: FrostedSwipeTone.accent,
                  onPressed: () {},
                ),
              ],
              child: kitSwipeRow('Harbor Transit', '\$42.00'),
            ),
            FrostedSwipeActions(
              leading: [
                FrostedSwipeAction(
                  label: 'Paid',
                  icon: LucideIcons.check,
                  onPressed: () {},
                ),
              ],
              child: kitSwipeRow('Cinema Lumen', '\$28.50'),
            ),
          ],
        ),
      ],
    ),
    kitSection('Open', children: [kitSpecimenSwipeTrailing()]),
    kitSection('Leading', children: [kitSpecimenSwipeLeading()]),
  ],
);

/// A row of the ledger for a swipe to carry: the name and the amount, a
/// row of a list's one glass (never a pane of its own).
Widget kitSwipeRow(String name, String amount) => Builder(
  builder: (context) {
    final t = context.frostedTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: FrostedSpacing.s12),
      child: Row(
        spacing: FrostedSpacing.s12,
        children: [
          Expanded(child: Text(name, style: t.textTheme.titleMedium)),
          Text(amount, style: t.textTheme.amountSmall.tabular),
        ],
      ),
    );
  },
);

/// The trailing actions standing open: Pin in the ink, Delete in the
/// danger fill.
Widget kitSpecimenSwipeTrailing() => FrostedListSection(
  rows: [
    FrostedSwipeActions(
      initiallyOpen: true,
      trailing: [
        FrostedSwipeAction(
          label: 'Delete',
          icon: LucideIcons.trash2,
          tone: FrostedSwipeTone.destructive,
          onPressed: () {},
        ),
        FrostedSwipeAction(
          label: 'Pin',
          icon: LucideIcons.pin,
          tone: FrostedSwipeTone.accent,
          onPressed: () {},
        ),
      ],
      child: kitSwipeRow('Harbor Transit', '\$42.00'),
    ),
  ],
);

/// A leading action standing open: Paid on the wash.
Widget kitSpecimenSwipeLeading() => FrostedListSection(
  rows: [
    FrostedSwipeActions(
      initiallyOpen: true,
      leading: [
        FrostedSwipeAction(
          label: 'Paid',
          icon: LucideIcons.check,
          onPressed: () {},
        ),
      ],
      child: kitSwipeRow('Cinema Lumen', '\$28.50'),
    ),
  ],
);
