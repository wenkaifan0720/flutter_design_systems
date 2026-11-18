/// Dates, times and colour: `TermDatePicker`, `TermDateRangePicker`,
/// `TermTimeField`, `TermCalendar` and `TermColorPicker`; and a
/// `TermCombobox` that looks its options up, slowly, and one that fails.
library;

import 'package:flutter/widgets.dart';
import 'package:terminal_ui/terminal_ui.dart';

import '../kit.dart';

Widget kitPickersDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'pickers',
  sections: [
    ...kitParts(const [
      ('a date', 'DatePicker'),
      ('a range of dates', 'DateRangePicker'),
      ('a time', 'TimePicker'),
      ('a calendar', 'Calendar'),
      ('a colour', 'ColorPicker'),
    ]),
    // A search's states: the list says it is looking, then what it found;
    // or that it failed, over a row that tries again.
    kitSection(
      'a branch, looked up',
      children: const [
        TermCombobox<String>(
          labelText: 'branch',
          hintText: 'type to search',
          options: [],
          search: _slowBranches,
          debounceDuration: Duration(milliseconds: 250),
        ),
        TermCombobox<String>(
          labelText: 'branch (offline)',
          hintText: 'type to search',
          options: [],
          search: _offline,
        ),
      ],
    ),
  ],
);

const _branches = [
  'main',
  'release/2.4',
  'feat/canary-deploys',
  'fix/oom-on-cold-start',
];

Future<Iterable<String>> _slowBranches(String query) async {
  await Future<void>.delayed(const Duration(milliseconds: 1200));
  final q = query.toLowerCase();
  return _branches.where((b) => b.contains(q));
}

Future<Iterable<String>> _offline(String query) async {
  await Future<void>.delayed(const Duration(milliseconds: 600));
  throw StateError('offline');
}
