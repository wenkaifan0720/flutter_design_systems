/// What a person presses, types or picks. The initial values are stable; all controls respond to input.
library;

import 'package:flutter/material.dart';
import 'package:comic_ui/comic_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../kit.dart';

Widget kitControlsDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Buttons, fields and choices',
  sections: [
    kitSection('The act', children: [kitSpecimenActButton()]),
    kitSection('Any other action', children: [kitSpecimenLineButton()]),
    kitSection('An icon alone', children: [kitSpecimenIconButton()]),
    kitSection('A field', children: [kitSpecimenField()]),
    kitSection('A send button', children: [kitSpecimenSendButton()]),
    kitSection('A value to change', children: [kitSpecimenSelectField()]),
    kitSection('One of a few', children: [kitSpecimenChoices()]),
    kitSection('A box of your own', children: [kitSpecimenChoiceBox()]),
    kitSection('A filter', children: [kitSpecimenChip()]),
    kitSection('A tick', children: [kitSpecimenCheck()]),
    kitSection('A count', children: [kitSpecimenStepper()]),
    kitSection('On or off', children: [kitSpecimenSwitch()]),
    kitSection(
      'Search and choose',
      children: [
        kitSpecimenSearch(),
        kitSpecimenSelect(),
        kitSpecimenRadio(),
        kitSpecimenSegmented(),
        kitSpecimenTextArea(),
        kitSpecimenCheckRow(),
      ],
    ),
    kitSection('A tile of your own', children: [kitPressTile()]),
  ],
);

Widget kitSpecimenActButton() => Builder(
  builder: (context) => ComicButton.filled(
    'Do the thing',
    icon: LucideIcons.play,
    onPressed: () => kitFeedback(context, 'The task is done.'),
  ),
);

Widget kitSpecimenLineButton() => Builder(
  builder: (context) => ComicButton(
    'Later',
    icon: LucideIcons.clock,
    onPressed: () => kitFeedback(context, 'Saved for later.'),
  ),
);

Widget kitSpecimenIconButton() => kitState(
  false,
  (context, value, change) => ComicIconButton(
    LucideIcons.bell,
    label: 'Alerts',
    selected: value,
    onPressed: () => change(!value),
  ),
);

Widget kitSpecimenField() => const ComicColumn(
  gap: 10,
  children: [
    ComicTextField(hint: 'As it should be on the list'),
    ComicTextField(hint: 'Write a reply', onPaper: true),
  ],
);

Widget kitSpecimenSendButton() => Builder(
  builder: (context) =>
      ComicSendButton(onPressed: () => kitFeedback(context, 'Message sent.')),
);

Widget kitSpecimenSelectField() => kitState(
  'Thursday',
  (context, value, change) => ComicMenuAnchor<String>(
    // A list that opens from a field is as wide as the field, from its leading edge, and marks the field's value as a
    // select's list does: the selection fill and the check.
    matchAnchorWidth: true,
    items: [
      for (final day in const ['Thursday', 'Friday'])
        ComicMenuItem(day, day, selected: day == value),
    ],
    onSelected: change,
    builder: (context, open) =>
        ComicSelectField(value: value, note: 'Delivery day', onPressed: open),
  ),
);

Widget kitSpecimenChoices() => kitState(
  'all',
  (context, value, change) => ComicChoices(
    options: const [
      ComicChoice('All', value: 'all'),
      ComicChoice('New', value: 'new'),
      ComicChoice('In stock', value: 'stock'),
    ],
    value: value,
    onChanged: change,
  ),
);

// A box of one line keeps to its words, as a button does (ui_core's DesignWidthCheck).
Widget kitSpecimenChoiceBox() => kitState(
  true,
  (context, value, change) => Align(
    alignment: AlignmentDirectional.centerStart,
    child: ComicChoiceBox(
      selected: value,
      label: 'Your own content',
      onPressed: () => change(!value),
      padding: const EdgeInsets.all(12),
      child: Builder(
        // Resolve the title inside the choice's selected/unselected ink scope.
        builder: (context) =>
            Text('Your own content', style: ComicTheme.of(context).type.title),
      ),
    ),
  ),
);

Widget kitSpecimenChip() => kitState(
  'Mild',
  (context, value, change) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      for (final label in ['Mild', 'Hot'])
        ComicChip(
          label,
          selected: value == label,
          onPressed: () => change(label),
        ),
    ],
  ),
);

Widget kitSpecimenCheck() => Wrap(
  spacing: 12,
  children: [
    kitState(
      true,
      (context, value, change) => ComicCheckbox(
        label: 'Keep this issue',
        value: value,
        onChanged: (next) => change(next ?? false),
      ),
    ),
    kitState(
      false,
      (context, value, change) => ComicCheckbox(
        label: 'Send updates',
        value: value,
        onChanged: (next) => change(next ?? false),
      ),
    ),
  ],
);

Widget kitSpecimenStepper() => kitState(
  2,
  (context, value, change) => ComicNumberField(
    value: value,
    unit: 'people',
    note: 'Up to six',
    onChanged: change,
    min: 1,
    max: 6,
  ),
);

Widget kitSpecimenSwitch() => Wrap(
  spacing: 12,
  children: [
    kitState(
      true,
      (context, value, change) =>
          ComicSwitch(label: 'Notifications', value: value, onChanged: change),
    ),
    kitState(
      false,
      (context, value, change) =>
          ComicSwitch(label: 'Sound', value: value, onChanged: change),
    ),
  ],
);

Widget kitPressTile() => Builder(
  builder: (context) {
    final t = ComicTheme.of(context);
    // A tile of one line keeps to its words, as a button does (ui_core's DesignWidthCheck).
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: ComicPressable(
        onPressed: () => kitFeedback(context, 'Issue 12 opened.'),
        label: 'Issue 12',
        outline: WidgetStatePropertyAll(t.shapes.medium),
        child: DecoratedBox(
          decoration: ShapeDecoration(
            // On paper, as every panel is: an unfilled contour showed the gutter through it (r4).
            color: t.colors.card,
            shape: t.shapes.medium.copyWith(
              side: BorderSide(color: t.colors.nightLine, width: 2.5),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Text('Issue 12', style: t.type.title),
          ),
        ),
      ),
    );
  },
);

Widget kitSpecimenSearch() => const ComicSearchField(hint: 'Search issues');

Widget kitSpecimenSelect() => kitState(
  'print',
  (context, value, change) => ComicSelect<String>(
    label: 'Format',
    options: const [
      ComicSelectOption('print', 'Print'),
      ComicSelectOption('digital', 'Digital'),
    ],
    value: value,
    onChanged: change,
  ),
);
Widget kitSpecimenRadio() => kitState(
  'post',
  (context, value, change) => ComicRadioGroup<String>(
    label: 'Delivery',
    options: const [
      ComicRadio('post', 'By post'),
      ComicRadio('collect', 'Collect'),
    ],
    value: value,
    onChanged: change,
  ),
);
Widget kitSpecimenSegmented() => kitState(
  'all',
  (context, value, change) => ComicSegmentedButton<String>(
    label: 'View',
    segments: const [
      ComicButtonSegment('all', 'All'),
      ComicButtonSegment('saved', 'Saved'),
    ],
    value: value,
    onChanged: change,
  ),
);
Widget kitSpecimenTextArea() =>
    const ComicTextArea(label: 'Notes', hint: 'A few words about the issue');
Widget kitSpecimenCheckRow() => kitState(
  true,
  (context, value, change) =>
      ComicCheckRow(label: 'Keep a copy', value: value, onChanged: change),
);

Widget kitSpecimenFileDrop() => kitState(
  const [
    ComicDroppedFile('cover-final.png', size: '2.4 MB'),
    ComicDroppedFile('page-03.jpg', size: '1.1 MB', progress: .6),
  ],
  (context, value, change) => ComicFileUpload(
    label: 'Cover art',
    hint: 'PNG or JPG, up to 10\u00A0MB',
    files: value,
    onChoose: () => change([
      ...value,
      ComicDroppedFile('page-${value.length + 1}.png', size: '0.8 MB'),
    ]),
    onRemove: (i) => change([...value]..removeAt(i)),
  ),
);
