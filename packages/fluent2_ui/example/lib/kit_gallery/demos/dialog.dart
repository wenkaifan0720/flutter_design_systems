/// [Fluent2Dialog], Fluent 2's alert dialog: a decision (Cancel / Delete),
/// a choice with its words, an acknowledgement with one act, and
/// [Fluent2Dialog.confirm] raising one over the app.
library;

import 'package:flutter/material.dart';
import 'package:fluent2_ui/fluent2_ui.dart';

import '../kit.dart';

Widget kitDialogDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Dialog',
  sections: [
    kitSection(
      'Raised over the app',
      children: [
        Builder(
          builder: (context) => kitRow([
            Fluent2Button(
              'Delete file',
              icon: Fluent2Icons.delete,
              onPressed: () => Fluent2Dialog.confirm(
                context,
                title: 'Delete Launch plan.docx?',
                message: 'It moves to the recycle bin for 30 days.',
                confirmLabel: 'Delete',
              ),
            ),
            Fluent2Button(
              'Leave meeting',
              icon: Fluent2Icons.arrowExit,
              onPressed: () => Fluent2Dialog.confirm(
                context,
                title: 'Leave Design review?',
                message: 'The meeting goes on without you.',
                confirmLabel: 'Leave',
              ),
            ),
          ]),
        ),
      ],
    ),
    kitSection('A decision', children: [kitSpecimenDialogConfirm()]),
    kitSection('A choice', children: [kitSpecimenDialogChoice()]),
    kitSection('An acknowledgement', children: [kitSpecimenDialogAck()]),
  ],
);

// --- Specimens --------------------------------------------------------------
// One builder per specimen in metadata.yaml. The stage (kitSpecimenStage)
// styles them; a builder never names a style.

/// Delete a file: Cancel beside Delete in the brand.
Widget kitSpecimenDialogConfirm() => Fluent2Dialog(
  title: 'Delete Launch plan.docx?',
  content: const Text('It moves to the recycle bin for 30 days.'),
  actions: [
    Fluent2Button('Cancel', onPressed: () {}),
    Fluent2Button(
      'Delete',
      appearance: Fluent2ButtonAppearance.primary,
      onPressed: () {},
    ),
  ],
);

/// Unsaved changes: three acts, the primary last, its other answer beside
/// it and Cancel furthest (last in a phone's stack).
Widget kitSpecimenDialogChoice() => Fluent2Dialog(
  title: 'Save changes to Q4 notes?',
  content: const Text('Your edits since 14:20 are not saved yet.'),
  actions: [
    Fluent2Button('Cancel', onPressed: () {}),
    Fluent2Button("Don't save", onPressed: () {}),
    Fluent2Button(
      'Save',
      appearance: Fluent2ButtonAppearance.primary,
      onPressed: () {},
    ),
  ],
);

/// One act and nothing to decide.
Widget kitSpecimenDialogAck() => Fluent2Dialog(
  title: 'Invite sent',
  content: const Text('Priya Raman can join Northwind from her email.'),
  actions: [
    Fluent2Button(
      'Done',
      appearance: Fluent2ButtonAppearance.primary,
      onPressed: () {},
    ),
  ],
);
