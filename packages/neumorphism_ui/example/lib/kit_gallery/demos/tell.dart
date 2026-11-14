/// States a page can communicate.
library;

import 'package:flutter/widgets.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

import '../kit.dart';

Widget kitTellDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Status and progress',
  sections: [
    kitSection('Notices', children: [kitSpecimenNotice()]),
    kitSection('A moment', children: [kitSpecimenCircularProgressIndicator()]),
    kitSection('Progress', children: [kitSpecimenLinearProgressIndicator()]),
    kitSection('Coming into view', children: [kitSpecimenSkeleton()]),
    kitSection('Complete', children: [kitSpecimenSuccessState()]),
    kitSection('Counts', children: [kitSpecimenBadge()]),
  ],
);
Widget kitSpecimenNotice() => const NeumorphicColumn(
  gap: 12,
  children: [
    NeumorphicBanner('Your changes are private.'),
    NeumorphicBanner('Your settings are saved.', tone: NeumorphicTone.success),
    NeumorphicBanner(
      'Your plan renews tomorrow.',
      tone: NeumorphicTone.warning,
    ),
    NeumorphicBanner(
      'We could not save this change.',
      tone: NeumorphicTone.danger,
    ),
  ],
);
Widget kitSpecimenCircularProgressIndicator() => const Wrap(
  spacing: 24,
  crossAxisAlignment: WrapCrossAlignment.center,
  children: [
    NeumorphicCircularProgressIndicator(),
    NeumorphicCircularProgressIndicator(
      value: .6,
      size: 40,
      label: 'Uploading',
    ),
  ],
);
Widget kitSpecimenLinearProgressIndicator() => const NeumorphicColumn(
  gap: 18,
  children: [
    NeumorphicLinearProgressIndicator(
      value: .4,
      label: 'Uploading',
      note: '4 of 10 files',
    ),
    NeumorphicLinearProgressIndicator(label: 'Connecting'),
  ],
);
Widget kitSpecimenSkeleton() => const NeumorphicColumn(
  gap: 18,
  children: [NeumorphicSkeleton.row(), NeumorphicSkeleton.lines(3)],
);
Widget kitSpecimenSuccessState() => NeumorphicSuccessState(
  title: 'All set',
  message: 'Your changes are saved.',
  action: NeumorphicButton('Continue', onPressed: () {}),
);
Widget kitSpecimenBadge() => const Wrap(
  spacing: 20,
  crossAxisAlignment: WrapCrossAlignment.center,
  children: [
    NeumorphicBadge(3),
    NeumorphicBadge(120),
    NeumorphicBadge(
      3,
      label: '3 unread messages',
      child: Icon(NeumorphicGlyphs.bell),
    ),
  ],
);
