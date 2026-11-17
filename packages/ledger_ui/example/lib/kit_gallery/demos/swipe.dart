/// A list row's acts under it, opened by a drag ([LedgerSwipeActions]), held
/// open on its trailing and its leading acts. The first section is live:
/// swipe the row. The words are a stationery studio's books, not the
/// pilot's.
library;

import 'package:flutter/material.dart';
import 'package:ledger_ui/ledger_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../kit.dart';

Widget kitSwipeDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Swipe actions',
  sections: [
    kitSection('Live', children: [_live]),
    kitSection('Swipe, trailing', children: [kitSpecimenSwipeTrailing()]),
    kitSection('Swipe, leading', children: [kitSpecimenSwipeLeading()]),
  ],
);

/// The row to swipe, its acts both sides.
final Widget _live = LedgerSwipeActions(
  leading: [
    LedgerSwipeAction(
      'Done',
      icon: LucideIcons.check,
      tone: LedgerSwipeTone.accent,
      onPressed: () {},
    ),
  ],
  trailing: [
    LedgerSwipeAction('Snooze', icon: LucideIcons.clock, onPressed: () {}),
    LedgerSwipeAction(
      'Delete',
      icon: LucideIcons.trash2,
      tone: LedgerSwipeTone.destructive,
      onPressed: () {},
    ),
  ],
  child: _row,
);

/// The row a swipe reveals acts under: an invoice.
const Widget _row = LedgerRow(
  title: 'Studio rent, November',
  value: LedgerAmount(1240),
  subtitle: 'Due Nov 1',
);

// --- Specimens --------------------------------------------------------------
// One builder per specimen in metadata.yaml. The stage (kitSpecimenStage)
// styles them; a builder never names a style.

/// A row held open on Snooze and Delete.
Widget kitSpecimenSwipeTrailing() => LedgerSwipeActions(
  initiallyOpen: true,
  trailing: [
    LedgerSwipeAction('Snooze', icon: LucideIcons.clock, onPressed: () {}),
    LedgerSwipeAction(
      'Delete',
      icon: LucideIcons.trash2,
      tone: LedgerSwipeTone.destructive,
      onPressed: () {},
    ),
  ],
  child: _row,
);

/// A row held open on Done.
Widget kitSpecimenSwipeLeading() => LedgerSwipeActions(
  initiallyOpen: true,
  leading: [
    LedgerSwipeAction(
      'Done',
      icon: LucideIcons.check,
      tone: LedgerSwipeTone.accent,
      onPressed: () {},
    ),
  ],
  child: _row,
);
