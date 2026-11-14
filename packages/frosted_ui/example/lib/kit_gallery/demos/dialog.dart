/// [FrostedDialog]: a decision (Cancel / Freeze), a loss in the danger fill,
/// an acknowledgement with one act, and [FrostedDialog.show] raising one
/// over the app.
library;

import 'package:flutter/material.dart';
import 'package:frosted_ui/frosted_ui.dart';

import '../kit.dart';

Widget kitDialogDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Dialog',
  sections: [
    kitSection(
      'Raised over the app',
      children: [
        Builder(
          builder: (context) => FrostedButton(
            'Freeze card',
            expand: true,
            onPressed: () => FrostedDialog.show(
              context,
              title: 'Freeze this card?',
              message:
                  'Payments stop until you unfreeze it. Subscriptions '
                  'on it will fail.',
              confirmLabel: 'Freeze',
              cancelLabel: 'Cancel',
            ),
          ),
        ),
        Builder(
          builder: (context) => FrostedButton.glass(
            'Delete goal',
            expand: true,
            onPressed: () => FrostedDialog.show(
              context,
              title: 'Delete Lisbon in May?',
              message: 'Its \$2,840.00 moves back to Everyday.',
              confirmLabel: 'Delete',
              cancelLabel: 'Keep',
              destructive: true,
            ),
          ),
        ),
      ],
    ),
    kitSection('A decision', children: [kitSpecimenDialogConfirm()]),
    kitSection('A loss', children: [kitSpecimenDialogDanger()]),
    kitSection('An acknowledgement', children: [kitSpecimenDialogAck()]),
  ],
);

/// The Freeze sheet: Cancel on the glass beside Freeze in the ink.
Widget kitSpecimenDialogConfirm() => Center(
  child: FrostedDialog(
    title: 'Freeze this card?',
    message: 'Payments stop until you unfreeze it.',
    confirmLabel: 'Freeze',
    cancelLabel: 'Cancel',
    onConfirm: () {},
    onCancel: () {},
  ),
);

/// A loss: Delete in the danger fill beside Keep.
Widget kitSpecimenDialogDanger() => Center(
  child: FrostedDialog(
    title: 'Delete Lisbon in May?',
    message: 'Its \$2,840.00 moves back to Everyday.',
    confirmLabel: 'Delete',
    cancelLabel: 'Keep',
    destructive: true,
    onConfirm: () {},
    onCancel: () {},
  ),
);

/// One act and nothing to decide.
Widget kitSpecimenDialogAck() => Center(
  child: FrostedDialog(
    title: 'Transfer sent',
    message: '\$500.00 reaches Jonah Reyes on Thursday.',
    confirmLabel: 'Done',
    onConfirm: () {},
  ),
);
