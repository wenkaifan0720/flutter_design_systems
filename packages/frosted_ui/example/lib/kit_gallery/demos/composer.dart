/// [FrostedComposer]: a thread's reply line with its attach and voice seats,
/// an assistant's prompt box, one busy with stop in the seat, and one
/// disabled.
library;

import 'package:flutter/material.dart';
import 'package:frosted_ui/frosted_ui.dart';

import '../kit.dart';

Widget kitComposerDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Composer',
  sections: [
    kitSection('Messages', children: [kitSpecimenComposerMessages()]),
    kitSection('Assistant', children: [kitSpecimenComposerAssistant()]),
    kitSection('Busy', children: [kitSpecimenComposerBusy()]),
    kitSection(
      'Disabled',
      children: [const FrostedComposer(hint: 'Message Jonah', enabled: false)],
    ),
  ],
);

/// A reply line: attach before the text, the voice seat at its end.
Widget kitSpecimenComposerMessages() => FrostedComposer(
  hint: 'Message Jonah',
  onSend: (_) {},
  onAttach: () {},
  onVoice: () {},
);

/// An assistant's box: the text over its row of tools.
Widget kitSpecimenComposerAssistant() => FrostedComposer(
  variant: FrostedComposerVariant.assistant,
  onSend: (_) {},
  onAttach: () {},
);

/// A reply streaming: stop in the seat.
Widget kitSpecimenComposerBusy() => FrostedComposer(
  variant: FrostedComposerVariant.assistant,
  busy: true,
  onSend: (_) {},
  onStop: () {},
);
