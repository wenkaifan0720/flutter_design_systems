/// The rest of the desktop's entry controls, with working controlled values.
library;

import 'package:flutter/material.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';

import '../kit.dart';

Widget kitEntriesDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Search, selection and dates',
  sections: [
    kitSection('Search', children: [kitSpecimenSearchField()]),
    kitSection('A code field', children: [kitSpecimenCodeField()]),
    kitSection('A select menu', children: [kitSpecimenSelect()]),
    kitSection(
      'Switches',
      children: [kitSpecimenSwitch(), kitSpecimenSwitchRow()],
    ),
    kitSection('Radio group', children: [kitSpecimenRadioGroup()]),
    kitSection('Segments', children: [kitSpecimenSegmentedButton()]),
    kitSection('Slider', children: [kitSpecimenSlider()]),
    kitSection('Calendar', children: [kitSpecimenDatePicker()]),
    kitSection('Time', children: [kitSpecimenTimePicker()]),
  ],
);
Widget kitSpecimenSearchField() => const RetroDesktopSearchField(
  hint: 'Search documents',
  name: 'Search documents',
);
Widget kitSpecimenCodeField() => const RetroDesktopInputOtp(
  label: 'Verification code',
  helper: 'Enter the six digits from your message.',
);
Widget kitSpecimenSelect() => kitValue(
  'local',
  (value, change) => RetroDesktopSelect<String>(
    label: 'Destination',
    value: value,
    onChanged: change,
    options: const [
      RetroDesktopOption('local', 'This computer'),
      RetroDesktopOption('server', 'File server'),
      RetroDesktopOption('off', 'Unavailable', enabled: false),
    ],
  ),
);
Widget kitSpecimenSwitch() => kitValue(
  false,
  (value, change) =>
      RetroDesktopSwitch(value: value, label: 'Synchronize', onChanged: change),
);
Widget kitSpecimenSwitchRow() => kitValue(
  true,
  (value, change) => RetroDesktopSwitchRow(
    label: 'Keep a local copy',
    note: 'Available when you are offline',
    value: value,
    onChanged: change,
  ),
);
Widget kitSpecimenRadioGroup() => kitValue(
  'ask',
  (value, change) => RetroDesktopRadioGroup<String>(
    label: 'When a file exists',
    value: value,
    onChanged: change,
    options: const [
      RetroDesktopRadio('ask', 'Ask every time'),
      RetroDesktopRadio('keep', 'Keep both files'),
      RetroDesktopRadio('replace', 'Replace the older file'),
    ],
  ),
);
Widget kitSpecimenSegmentedButton() => kitValue(
  'list',
  (value, change) => RetroDesktopSegmentedButton<String>(
    label: 'View',
    value: value,
    onChanged: change,
    segments: const [
      RetroDesktopButtonSegment('list', 'List'),
      RetroDesktopButtonSegment('grid', 'Grid'),
    ],
  ),
);
Widget kitSpecimenSlider() => kitValue(
  .4,
  (value, change) => RetroDesktopSlider(
    label: 'Volume',
    value: value,
    divisions: 10,
    onChanged: change,
  ),
);
Widget kitSpecimenDatePicker() => kitValue(
  DateTime(2026, 6, 10),
  (value, change) => RetroDesktopDatePicker(
    value: value,
    onChanged: change,
    first: DateTime(2026),
    last: DateTime(2027),
  ),
);
Widget kitSpecimenTimePicker() => kitValue(
  const RetroDesktopTime(15, 45),
  (value, change) => RetroDesktopTimePicker(value: value, onChanged: change),
);
