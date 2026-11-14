/// The ways in: the search entry ([LedgerSearchEntry]) with and without its
/// filter, and the date picker ([LedgerDatePicker]) compact, inline and as
/// wheels. The first section is live: the picker keeps its value. The words are a
/// stationery studio's books, not the pilot's.
library;

import 'package:flutter/material.dart';
import 'package:ledger_ui/ledger_ui.dart';

import '../kit.dart';

Widget kitEntryDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Search & dates',
  sections: [
    kitSection('Live', children: [const _Live()]),
    kitSection('Search entry', children: [kitSpecimenSearchEntry()]),
    kitSection('With its filters', children: [kitSpecimenSearchEntryFilter()]),
    kitSection('Dates, compact', children: [kitSpecimenDateCompact()]),
    kitSection('Dates, the month', children: [kitSpecimenDateInline()]),
    kitSection('Dates, wheels', children: [kitSpecimenDateWheel()]),
  ],
);

class _Live extends StatefulWidget {
  const _Live();

  @override
  State<_Live> createState() => _LiveState();
}

class _LiveState extends State<_Live> {
  DateTime _due = _day;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      LedgerDatePicker(
        label: 'Due',
        value: _due,
        mode: LedgerDatePickerMode.dateAndTime,
        today: kitNow,
        onChanged: (v) => setState(() => _due = v),
      ),
      const LedgerGap(LedgerSpacing.s16),
      LedgerDatePicker(
        label: 'Remind me',
        value: _due,
        presentation: LedgerDatePickerPresentation.inline,
        today: kitNow,
        onChanged: (v) => setState(() => _due = v),
      ),
    ],
  );
}

/// The day the date specimens hold: the first of the month after the
/// pilot's moment, at nine in the morning.
final DateTime _day = DateTime(2026, 11, 4, 9, 30);

// --- Specimens --------------------------------------------------------------
// One builder per specimen in metadata.yaml. The stage (kitSpecimenStage)
// styles them; a builder never names a style.

/// The way into the search, a link.
Widget kitSpecimenSearchEntry() =>
    LedgerSearchEntry(hint: 'Search entries and invoices', onTap: () {});

/// The way into the search with the filters beside it, two in force.
Widget kitSpecimenSearchEntryFilter() => LedgerSearchEntry(
  hint: 'Search entries and invoices',
  onTap: () {},
  onFilterPressed: () {},
  filterCount: 2,
);

/// The compact line: the due date and time in pills on the dot leader.
Widget kitSpecimenDateCompact() => LedgerDatePicker(
  label: 'Due',
  value: _day,
  mode: LedgerDatePickerMode.dateAndTime,
  onChanged: (_) {},
);

/// November on the page, the fourth chosen, the first of the month ringed.
Widget kitSpecimenDateInline() => LedgerDatePicker(
  label: 'Due',
  value: _day,
  presentation: LedgerDatePickerPresentation.inline,
  today: DateTime(2026, 11, 1),
  onChanged: (_) {},
);

/// The day and the time as wheels.
Widget kitSpecimenDateWheel() => LedgerDatePicker(
  label: 'Due',
  value: _day,
  mode: LedgerDatePickerMode.dateAndTime,
  presentation: LedgerDatePickerPresentation.wheel,
  onChanged: (_) {},
);
