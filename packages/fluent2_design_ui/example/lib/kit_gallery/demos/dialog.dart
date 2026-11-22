/// [Fluent2Dialog], Fluent 2's alert dialog: a decision (Cancel / Delete),
/// a choice with its words, an acknowledgement with one act, and
/// [Fluent2Dialog.confirm] raising one over the app.
library;

import 'package:material_ui/material_ui.dart';
import 'package:fluent2_design_ui/fluent2_design_ui.dart';

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
              kitW('Delete file'),
              icon: Fluent2Icons.delete,
              onPressed: () => Fluent2Dialog.confirm(
                KitGalleryNavigator.dialogContext(context),
                title: kitW('Delete Launch plan.docx?'),
                message: kitW('It moves to the recycle bin for 30 days.'),
                confirmLabel: kitW('Delete'),
                danger: true,
              ),
            ),
            Fluent2Button(
              kitW('Leave meeting'),
              icon: Fluent2Icons.arrowExit,
              onPressed: () => Fluent2Dialog.confirm(
                KitGalleryNavigator.dialogContext(context),
                title: kitW('Leave Design review?'),
                message: kitW('The meeting goes on without you.'),
                confirmLabel: kitW('Leave'),
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

/// Delete a file: Cancel beside Delete, a loss, on danger's solid.
Widget kitSpecimenDialogConfirm() => Fluent2Dialog(
  title: kitW('Delete Launch plan.docx?'),
  content: Text(kitW('It moves to the recycle bin for 30 days.')),
  actions: [
    Fluent2Button(kitW('Cancel'), onPressed: () {}),
    Fluent2Button(
      kitW('Delete'),
      appearance: Fluent2ButtonAppearance.primary,
      danger: true,
      onPressed: () {},
    ),
  ],
);

/// Unsaved changes: three acts, the primary last, its other answer beside
/// it and Cancel furthest (last in a phone's stack).
Widget kitSpecimenDialogChoice() => Fluent2Dialog(
  title: kitW('Save changes to Q4 notes?'),
  content: Text(kitW('Your edits since 14:20 are not saved yet.')),
  actions: [
    Fluent2Button(kitW('Cancel'), onPressed: () {}),
    Fluent2Button(kitW("Don't save"), onPressed: () {}),
    Fluent2Button(
      kitW('Save'),
      appearance: Fluent2ButtonAppearance.primary,
      onPressed: () {},
    ),
  ],
);

/// One act and nothing to decide.
Widget kitSpecimenDialogAck() => Fluent2Dialog(
  title: kitW('Invite sent'),
  content: Text(kitW('Priya Raman can join Northwind from her email.')),
  actions: [
    Fluent2Button(
      kitW('Done'),
      appearance: Fluent2ButtonAppearance.primary,
      onPressed: () {},
    ),
  ],
);
