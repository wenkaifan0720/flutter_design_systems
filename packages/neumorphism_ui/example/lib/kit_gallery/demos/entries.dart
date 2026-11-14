/// Typed choices, codes and longer text, with enabled and disabled states.
library;

import 'package:flutter/widgets.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

import '../kit.dart';

Widget kitEntriesDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Search, codes and choices',
  sections: [
    kitSection('Search', children: [kitSpecimenSearchField()]),
    kitSection('A longer note', children: [kitSpecimenTextArea()]),
    kitSection('A code', children: [kitSpecimenCodeField()]),
    kitSection('One of a list', children: [kitSpecimenSelect()]),
    kitSection('Checks', children: [kitSpecimenCheckbox()]),
    kitSection('One choice', children: [kitSpecimenRadioGroup()]),
    kitSection('A period', children: [kitSpecimenSegmented()]),
    kitSection('A score', children: [kitSpecimenRating()]),
    kitSection('Files', children: [kitSpecimenFileDrop()]),
  ],
);
Widget kitSpecimenSearchField() => const NeumorphicColumn(
  gap: 12,
  children: [
    NeumorphicSearchField(hint: 'Search the shelf'),
    NeumorphicSearchField(hint: 'Search unavailable', enabled: false),
  ],
);
Widget kitSpecimenTextArea() => const NeumorphicTextArea(
  label: 'A note for tomorrow',
  hint: 'Write a few words',
  helper: 'Only you can see this.',
);
Widget kitSpecimenCodeField() => const NeumorphicInputOtp(
  label: 'Verification code',
  helper: 'Enter the six digits we sent you.',
);
Widget kitSpecimenSelect() {
  var value = 'room';
  return StatefulBuilder(
    builder: (context, setState) => NeumorphicSelect<String>(
      label: 'Space',
      value: value,
      helper: 'Choose somewhere quiet.',
      options: const [
        NeumorphicMenuItem('room', 'Reading room'),
        NeumorphicMenuItem('window', 'Beside the window'),
        NeumorphicMenuItem('court', 'Courtyard', enabled: false),
      ],
      onChanged: (v) => setState(() => value = v),
    ),
  );
}

Widget kitSpecimenCheckbox() {
  bool? value = true;
  return StatefulBuilder(
    builder: (context, setState) => NeumorphicColumn(
      gap: 8,
      children: [
        NeumorphicCheckRow(
          label: 'Remember this space',
          value: value,
          tristate: true,
          onChanged: (v) => setState(() => value = v),
        ),
        NeumorphicCheckRow(
          label: 'Some reminders',
          note: 'Mixed, then off on the next press',
          value: null,
          tristate: true,
          onChanged: (_) {},
        ),
        const NeumorphicCheckRow(label: 'Unavailable', value: false),
        Row(
          children: [
            NeumorphicCheckbox(
              value: false,
              label: 'A check with an error',
              error: true,
              onChanged: (_) {},
            ),
            const Text('Review this choice'),
          ],
        ),
      ],
    ),
  );
}

Widget kitSpecimenRadioGroup() {
  var value = 'room';
  return StatefulBuilder(
    builder: (context, setState) => NeumorphicRadioGroup<String>(
      label: 'Space',
      value: value,
      options: const [
        NeumorphicRadio('room', 'Reading room', note: 'Near the books'),
        NeumorphicRadio('window', 'Beside the window'),
        NeumorphicRadio('court', 'Courtyard', enabled: false),
      ],
      onChanged: (v) => setState(() => value = v),
    ),
  );
}

Widget kitSpecimenSegmented() {
  var value = 'day';
  return StatefulBuilder(
    builder: (context, setState) => NeumorphicSegmentedButton<String>(
      label: 'Period',
      value: value,
      segments: const [
        NeumorphicButtonSegment('day', 'Day'),
        NeumorphicButtonSegment('week', 'Week'),
        NeumorphicButtonSegment('month', 'Month'),
      ],
      onChanged: (v) => setState(() => value = v),
    ),
  );
}

Widget kitSpecimenRating() {
  var stars = 4;
  return StatefulBuilder(
    builder: (context, setState) => NeumorphicColumn(
      gap: 12,
      children: [
        NeumorphicRating(
          label: 'Your rating',
          value: stars.toDouble(),
          onChanged: (v) => setState(() => stars = v),
        ),
        const NeumorphicRating(label: 'Average rating', value: 3.5, size: 18),
      ],
    ),
  );
}

Widget kitSpecimenFileDrop() {
  var files = <String>['floor-plan.pdf'];
  return StatefulBuilder(
    builder: (context, setState) => NeumorphicFileUpload(
      hint: 'PDF or image, up to 10\u00a0MB',
      files: files,
      onPressed: () =>
          setState(() => files = [...files, 'photo-${files.length}.jpg']),
      onRemove: (i) => setState(() => files = [...files]..removeAt(i)),
    ),
  );
}
