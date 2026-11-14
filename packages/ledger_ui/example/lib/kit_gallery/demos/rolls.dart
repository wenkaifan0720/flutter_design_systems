/// What a list and a record carry: the avatar stack ([LedgerAvatarStack]),
/// the week strip ([LedgerWeekStrip]) and the counter ([LedgerCounter]), its
/// figure re-inked as it changes. The first section is live: add a day. The
/// words are a stationery studio's books, not the pilot's.
library;

import 'package:flutter/material.dart';
import 'package:ledger_ui/ledger_ui.dart';

import '../kit.dart';

Widget kitRollsDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Stacks, weeks & counters',
  sections: [
    kitSection('Live', children: [const _Live()]),
    kitSection('Avatar stack', children: [kitSpecimenAvatarStack()]),
    kitSection('A week', children: [kitSpecimenWeekStrip()]),
    kitSection('A counter', children: [kitSpecimenCounter()]),
  ],
);

class _Live extends StatefulWidget {
  const _Live();

  @override
  State<_Live> createState() => _LiveState();
}

class _LiveState extends State<_Live> {
  int _streak = 12;

  @override
  Widget build(BuildContext context) => Row(
    spacing: LedgerSpacing.s16,
    // The button leads: the counter's figure stands centred in its places,
    // in from the column's edge.
    children: [
      LedgerButton('Add a day', onPressed: () => setState(() => _streak += 1)),
      LedgerCounter(_streak),
    ],
  );
}

// --- Specimens --------------------------------------------------------------
// One builder per specimen in metadata.yaml. The stage (kitSpecimenStage)
// styles them; a builder never names a style.

/// Who shares the books: four faces and the five more.
Widget kitSpecimenAvatarStack() => const Align(
  alignment: AlignmentDirectional.centerStart,
  child: LedgerAvatarStack(
    names: ['Maren Holt', 'Jonas Ahn', 'Priya Rao', 'Lee Wong'],
    total: 9,
  ),
);

/// A habit's week to Wednesday, Oct 28: one kept, one missed, today still
/// to do.
Widget kitSpecimenWeekStrip() => const Align(
  alignment: AlignmentDirectional.centerStart,
  child: LedgerWeekStrip(
    label: 'Morning pages this week',
    days: [
      LedgerDayMark.kept,
      LedgerDayMark.missed,
      LedgerDayMark.today,
      LedgerDayMark.upcoming,
      LedgerDayMark.upcoming,
      LedgerDayMark.upcoming,
      LedgerDayMark.upcoming,
    ],
  ),
);

/// A streak in the engraved figure.
Widget kitSpecimenCounter() => Align(
  alignment: AlignmentDirectional.centerStart,
  child: LedgerCounter(12, format: (v) => '$v days'),
);
