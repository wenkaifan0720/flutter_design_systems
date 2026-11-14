/// What a person presses, types or picks.
library;

import 'package:flutter/material.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../kit.dart';

Widget kitControlsDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Buttons, fields and choices',
  sections: [
    kitSection('The default button', children: [kitSpecimenActButton()]),
    kitSection('A line button', children: [kitSpecimenLineButton()]),
    kitSection('An icon button', children: [kitSpecimenIconButton()]),
    kitSection('A popup', children: [kitSpecimenPopup()]),
    kitSection('A text box', children: [kitSpecimenTextBox()]),
    kitSection('A key', children: [kitSpecimenKbd()]),
    kitSection('A checkbox', children: [kitSpecimenCheck()]),
    kitSection('A radio', children: [_radioExamples()]),
    kitSection('A check row', children: [kitSpecimenCheckRow()]),
    kitSection('A chip', children: [kitSpecimenChip()]),
    kitSection('A flag', children: [kitSpecimenFlag()]),
    kitSection('A priority', children: [kitSpecimenPriority()]),
    kitSection('A progress bar', children: [kitSpecimenProgress()]),
    kitSection('An etched line', children: [kitSpecimenEtch()]),
    kitSection('A disclosure', children: [kitSpecimenDisclosure()]),
    kitSection('Choices', children: [kitSpecimenChoices()]),
    kitSection('A stepper', children: [kitSpecimenStepper()]),
    kitSection('A group box', children: [kitSpecimenGroupBox()]),
    kitSection('Folder tabs', children: [kitSpecimenFolderTabs()]),
  ],
);

Widget kitSpecimenActButton() => kitAction(
  'Document opened',
  (press) => RetroDesktopButton(
    'Open it',
    isDefaultAction: true,
    icon: LucideIcons.play,
    onPressed: press,
  ),
);

Widget kitSpecimenLineButton() => kitAction(
  'Action completed',
  // Each size on a line of its own: buttons sharing a row show one height.
  (press) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      RetroDesktopButton('Snooze', onPressed: press),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          RetroDesktopButton(
            'Small',
            size: RetroDesktopButtonSize.small,
            onPressed: press,
          ),
          RetroDesktopButton(
            'Add',
            icon: LucideIcons.plus,
            size: RetroDesktopButtonSize.small,
            onPressed: press,
          ),
        ],
      ),
    ],
  ),
);

Widget kitSpecimenIconButton() => kitAction(
  'Toolbar action completed',
  // Each size on a line of its own.
  (press) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      RetroDesktopIconButton(LucideIcons.tag, label: 'Tag', onPressed: press),
      const SizedBox(height: 8),
      RetroDesktopIconButton(
        LucideIcons.plus,
        label: 'Add',
        size: RetroDesktopButtonSize.small,
        onPressed: press,
      ),
    ],
  ),
);

Widget kitSpecimenPopup() => kitValue(
  'Pick one',
  (value, change) => RetroDesktopMenuAnchor<String>(
    items: const [
      RetroDesktopMenuItem('Documents', 'Documents'),
      RetroDesktopMenuItem('Archive', 'Archive'),
    ],
    onSelected: change,
    builder: (context, open) => RetroDesktopPopupButton(value, onPressed: open),
  ),
);

Widget kitSpecimenTextBox() => const RetroDesktopColumn(
  gap: 8,
  children: [
    RetroDesktopTextField(
      hint: 'Search everything',
      leading: Icon(LucideIcons.search),
      trailing: RetroDesktopKbd('Ctrl K'),
    ),
    RetroDesktopTextField(initial: 'What you wrote'),
    RetroDesktopTextField(hint: 'A few lines', lines: 3),
  ],
);

Widget kitSpecimenKbd() => const RetroDesktopKbd('Ctrl K');

Widget kitSpecimenCheck() => Wrap(
  spacing: 12,
  children: [
    for (final item in [
      (true, 'Option'),
      (false, 'Option'),
      (true, 'With a label'),
    ])
      kitValue(
        item.$1,
        (value, change) => RetroDesktopCheckbox(
          value: value,
          onChanged: (next) => change(next ?? false),
          label: item.$2,
        ),
      ),
  ],
);

/// Two radio groups with their own questions, for the example's Selection page (two alike, both "Choice: First,
/// Second", read as one demo shown twice).
Widget kitRadioSamples() => _radioExamples();

Widget _radioExamples() => Wrap(
  spacing: 24,
  runSpacing: 12,
  children: [
    kitValue(
      1,
      (value, change) => RetroDesktopRadioGroup<int>(
        label: 'Sort by',
        options: const [
          RetroDesktopRadio<int>(1, 'Name'),
          RetroDesktopRadio<int>(2, 'Date changed'),
        ],
        value: value,
        onChanged: change,
      ),
    ),
    kitValue(
      2,
      (value, change) => RetroDesktopRadioGroup<int>(
        label: 'Paper',
        options: const [
          RetroDesktopRadio<int>(1, 'A4'),
          RetroDesktopRadio<int>(2, 'Letter'),
        ],
        value: value,
        onChanged: change,
      ),
    ),
  ],
);

Widget kitSpecimenCheckRow() => kitValue(
  true,
  (value, change) => RetroDesktopCheckRow(
    label: 'Before something is due',
    note: 'An hour ahead',
    value: value,
    onChanged: change,
  ),
);

// The small chip on a line of its own: chips sharing a row show one height.
Widget kitSpecimenChip() => Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        kitValue(
          true,
          (value, change) => RetroDesktopChip(
            'All',
            selected: value,
            onPressed: () => change(!value),
          ),
        ),
        kitValue(
          false,
          (value, change) => RetroDesktopChip(
            'first',
            leading: const Text('#'),
            selected: value,
            onPressed: () => change(!value),
          ),
        ),
        kitAction(
          'Tag added',
          (press) => RetroDesktopChip.outlined(
            'Tag',
            icon: LucideIcons.plus,
            onPressed: press,
          ),
        ),
      ],
    ),
    const SizedBox(height: 8),
    kitValue(
      false,
      (value, change) => RetroDesktopChip(
        'Small',
        size: RetroDesktopButtonSize.small,
        selected: value,
        onPressed: () => change(!value),
      ),
    ),
  ],
);

Widget kitSpecimenFlag() => const RetroDesktopFlag('1 day late');

Widget kitSpecimenPriority() => const Wrap(
  spacing: 12,
  children: [
    RetroDesktopPriority(1),
    RetroDesktopPriority(2),
    RetroDesktopPriority(3),
  ],
);

Widget kitSpecimenProgress() =>
    const RetroDesktopLinearProgressIndicator(value: .4, label: '2 of 5 done');

Widget kitSpecimenEtch() => const RetroDesktopDivider.etched();

Widget kitSpecimenDisclosure() => const RetroDesktopDisclosure(
  note: '12 versions',
  initiallyExpanded: true,
  title: 'Versions',
  child: Text('What it opens onto.'),
);

Widget kitSpecimenChoices() => kitValue(
  'Every week',
  (value, change) => RetroDesktopChoices(
    options: const [
      RetroDesktopChoice('Every day', note: 'At nine'),
      RetroDesktopChoice('Every week', note: 'On Monday'),
      RetroDesktopChoice('Never', note: 'Only when asked'),
    ],
    onChanged: change,
    value: value,
  ),
);

Widget kitSpecimenStepper() => kitValue(
  2,
  (value, change) => RetroDesktopNumberField(
    value: value,
    max: 5,
    onChanged: change,
    unit: 'a day',
    note: 'Up to 5',
  ),
);

Widget kitSpecimenGroupBox() => const RetroDesktopGroupBox(
  title: 'Checklist',
  icon: LucideIcons.listChecks,
  count: '2 of 4',
  child: Text('What belongs together.'),
);

Widget kitSpecimenFolderTabs() => kitValue(
  0,
  (value, change) => RetroDesktopTabBar(
    tabs: const ['Today', 'Soon', 'Later'],
    onChanged: change,
    selectedIndex: value,
    counts: ['3', '4', '5'],
    child: RetroDesktopList(
      share: true,
      children: [
        RetroDesktopListTile(
          title: 'One row',
          subtitle: value == 0
              ? 'Under the first tab'
              : value == 1
              ? 'Coming soon'
              : 'Saved for later',
        ),
      ],
    ),
  ),
);
