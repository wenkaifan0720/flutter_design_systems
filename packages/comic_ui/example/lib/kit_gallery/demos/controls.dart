/// What a person presses, types or picks. The initial values are stable; all controls respond to input.
library;

import 'package:material_ui/material_ui.dart';
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
    kitSection('A date in a form', children: [kitSpecimenDateField()]),
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
  builder: (context) => Builder(
    builder: (context) => ComicButton.filled(
      kitSay(context, 'Do the thing'),
      icon: LucideIcons.play,
      onPressed: () =>
          kitFeedback(context, kitSay(context, 'The task is done.')),
    ),
  ),
);

Widget kitSpecimenLineButton() => Builder(
  builder: (context) => Builder(
    builder: (context) => ComicButton(
      kitSay(context, 'Later'),
      icon: LucideIcons.clock,
      onPressed: () =>
          kitFeedback(context, kitSay(context, 'Saved for later.')),
    ),
  ),
);

Widget kitSpecimenIconButton() => Builder(
  builder: (context) => kitState(
    false,
    (context, value, change) => ComicIconButton(
      LucideIcons.bell,
      semanticLabel: kitSay(context, 'Alerts'),
      // Alone on its column, the face stands on the keyline and its target grows toward the end.
      targetAlignment: AlignmentDirectional.centerStart,
      isSelected: value,
      onPressed: () => change(!value),
    ),
  ),
);

Widget kitSpecimenField() => Builder(
  builder: (context) => ComicColumn(
    gap: 10,
    children: [
      ComicTextField(hintText: kitSay(context, 'As it should be on the list')),
      ComicTextField(hintText: kitSay(context, 'Write a reply'), onPaper: true),
    ],
  ),
);

Widget kitSpecimenSendButton() => Builder(
  builder: (context) => Builder(
    builder: (context) => ComicSendButton(
      onPressed: () => kitFeedback(context, kitSay(context, 'Message sent.')),
    ),
  ),
);

Widget kitSpecimenSelectField() => kitState(
  'Thursday',
  (context, value, change) => ComicMenuAnchor<String>(
    // A list that opens from a field is as wide as the field, from its leading edge, and marks the field's value as a
    // select's list does: the selection fill and the check.
    matchAnchorWidth: true,
    items: [
      for (final day in const ['Thursday', 'Friday'])
        ComicMenuItem(day, kitSay(context, day), selected: day == value),
    ],
    onSelected: change,
    builder: (context, open) => ComicSelectField(
      value: kitSay(context, value),
      helperText: kitSay(context, 'Delivery day'),
      onPressed: open,
    ),
  ),
);

Widget kitSpecimenDateField() => kitState<DateTime?>(
  null,
  (context, value, change) => ComicDateField(
    labelText: kitSay(context, 'Started'),
    value: value,
    lastDate: kitToday,
    onChanged: change,
  ),
);

Widget kitSpecimenChoices() => kitState(
  'all',
  (context, value, change) => ComicChoices(
    options: [
      ComicChoice(kitSay(context, 'All'), value: 'all'),
      ComicChoice(kitSay(context, 'New'), value: 'new'),
      ComicChoice(kitSay(context, 'In stock'), value: 'stock'),
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
      semanticLabel: kitSay(context, 'Your own content'),
      onPressed: () => change(!value),
      padding: const EdgeInsets.all(12),
      child: Builder(
        // Resolve the title inside the choice's selected/unselected ink scope.
        builder: (context) => Text(
          kitSay(context, 'Your own content'),
          style: ComicTheme.of(context).type.title,
        ),
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
          kitSay(context, label),
          selected: value == label,
          onPressed: () => change(label),
        ),
    ],
  ),
);

Widget kitSpecimenCheck() => Builder(
  builder: (context) => Wrap(
    spacing: 12,
    children: [
      kitState(
        true,
        (context, value, change) => ComicCheckbox(
          semanticLabel: kitSay(context, 'Keep this issue'),
          value: value,
          onChanged: (next) => change(next ?? false),
        ),
      ),
      kitState(
        false,
        (context, value, change) => ComicCheckbox(
          semanticLabel: kitSay(context, 'Send updates'),
          value: value,
          onChanged: (next) => change(next ?? false),
        ),
      ),
    ],
  ),
);

Widget kitSpecimenStepper() => kitState(
  2,
  (context, value, change) => ComicNumberField(
    value: value,
    unit: kitSay(context, 'people'),
    helperText: kitSay(context, 'Up to six'),
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
      (context, value, change) => ComicSwitch(
        semanticLabel: 'Notifications',
        value: value,
        onChanged: change,
      ),
    ),
    kitState(
      false,
      (context, value, change) =>
          ComicSwitch(semanticLabel: 'Sound', value: value, onChanged: change),
    ),
  ],
);

Widget kitPressTile() => Builder(
  builder: (context) => Builder(
    builder: (context) {
      final t = ComicTheme.of(context);
      // A tile of one line keeps to its words, as a button does (ui_core's DesignWidthCheck).
      return Align(
        alignment: AlignmentDirectional.centerStart,
        child: ComicPressable(
          onPressed: () =>
              kitFeedback(context, kitSay(context, 'Issue 12 opened.')),
          semanticLabel: kitSay(context, 'Issue 12'),
          outline: WidgetStatePropertyAll(t.shapes.medium),
          child: DecoratedBox(
            decoration: ShapeDecoration(
              // On paper, as every panel is: an unfilled contour would show the gutter through it.
              color: t.colors.card,
              shape: t.shapes.medium.copyWith(
                side: BorderSide(color: t.colors.nightLine, width: 2.5),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(kitSay(context, 'Issue 12'), style: t.type.title),
            ),
          ),
        ),
      );
    },
  ),
);

Widget kitSpecimenSearch() => Builder(
  builder: (context) =>
      ComicSearchField(hintText: kitSay(context, 'Search issues')),
);

Widget kitSpecimenSelect() => kitState(
  'print',
  (context, value, change) => ComicSelect<String>(
    labelText: kitSay(context, 'Format'),
    options: [
      ComicSelectOption('print', kitSay(context, 'Print')),
      ComicSelectOption('digital', kitSay(context, 'Digital')),
    ],
    value: value,
    onChanged: change,
  ),
);
Widget kitSpecimenRadio() => kitState(
  'post',
  (context, value, change) => ComicRadioGroup<String>(
    labelText: kitSay(context, 'Delivery'),
    options: [
      ComicRadio('post', kitSay(context, 'By post')),
      ComicRadio(kitSay(context, 'collect'), kitSay(context, 'Collect')),
    ],
    groupValue: value,
    onChanged: change,
  ),
);
Widget kitSpecimenSegmented() => kitState(
  'all',
  (context, value, change) => ComicSegmentedButton<String>(
    semanticLabel: 'View',
    segments: [
      ComicButtonSegment(kitSay(context, 'all'), kitSay(context, 'All')),
      ComicButtonSegment(kitSay(context, 'saved'), kitSay(context, 'Saved')),
    ],
    value: value,
    onChanged: change,
  ),
);
Widget kitSpecimenTextArea() => Builder(
  builder: (context) => ComicTextArea(
    labelText: kitSay(context, 'Notes'),
    hintText: kitSay(context, 'A few words about the issue'),
  ),
);
Widget kitSpecimenCheckRow() => kitState(
  true,
  (context, value, change) => ComicCheckRow(
    label: kitSay(context, 'Keep a copy'),
    value: value,
    onChanged: change,
  ),
);

Widget kitSpecimenFileDrop() => kitState(
  const [
    ComicDroppedFile('cover-final.png', size: '2.4 MB'),
    ComicDroppedFile('page-03.jpg', size: '1.1 MB', progress: .6),
  ],
  (context, value, change) => ComicFileUpload(
    labelText: kitSay(context, 'Cover art'),
    hintText: kitSay(context, 'PNG or JPG, up to 10\u00A0MB'),
    files: [
      for (final file in value)
        ComicDroppedFile(
          file.name,
          size: file.size == null ? null : kitSay(context, file.size!),
          progress: file.progress,
          error: file.error,
        ),
    ],
    onChoose: () => change([
      ...value,
      ComicDroppedFile('page-${value.length + 1}.png', size: '0.8 MB'),
    ]),
    onRemove: (i) => change([...value]..removeAt(i)),
  ),
);
