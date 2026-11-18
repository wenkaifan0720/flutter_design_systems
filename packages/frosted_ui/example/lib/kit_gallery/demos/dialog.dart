/// [FrostedDialog]: a decision (Cancel / Freeze), a loss in the danger fill,
/// an acknowledgement with one act, and [FrostedDialog.show] raising one
/// over the app.
library;

import 'package:material_ui/material_ui.dart';
import 'package:frosted_ui/frosted_ui.dart';

import '../kit.dart';

Widget kitDialogDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  measured: true,
  title: kitSay('Dialog'),
  sections: [
    kitSection(
      kitSay('Raised over the app'),
      children: [
        Builder(
          builder: (context) => FrostedButton(
            kitSay('Freeze card'),
            expand: true,
            onPressed: () => FrostedDialog.show(
              context,
              title: kitSay('Freeze this card?'),
              message: kitSay(
                'Payments stop until you unfreeze it. Subscriptions on it will fail.',
              ),
              confirmLabel: kitSay('Freeze'),
              cancelLabel: kitSay('Cancel'),
            ),
          ),
        ),
        Builder(
          builder: (context) => FrostedButton.glass(
            kitSay('Delete goal'),
            expand: true,
            onPressed: () => FrostedDialog.show(
              context,
              title: kitSay('Delete Lisbon in May?'),
              message: kitSay('Its \$2,840.00 moves back to Everyday.'),
              confirmLabel: kitSay('Delete'),
              cancelLabel: kitSay('Keep'),
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
    title: kitSay('Freeze this card?'),
    message: kitSay('Payments stop until you unfreeze it.'),
    confirmLabel: kitSay('Freeze'),
    cancelLabel: kitSay('Cancel'),
    onConfirm: () {},
    onCancel: () {},
  ),
);

/// A loss: Delete in the danger fill beside Keep.
Widget kitSpecimenDialogDanger() => Center(
  child: FrostedDialog(
    title: kitSay('Delete Lisbon in May?'),
    message: kitSay('Its \$2,840.00 moves back to Everyday.'),
    confirmLabel: kitSay('Delete'),
    cancelLabel: kitSay('Keep'),
    destructive: true,
    onConfirm: () {},
    onCancel: () {},
  ),
);

/// One act and nothing to decide.
Widget kitSpecimenDialogAck() => Center(
  child: FrostedDialog(
    title: kitSay('Transfer sent'),
    message: kitSay('\$500.00 reaches Jonah Reyes on Thursday.'),
    confirmLabel: kitSay('Done'),
    onConfirm: () {},
  ),
);
