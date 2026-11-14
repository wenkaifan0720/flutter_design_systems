/// [FrostedActionBar]: the Review page's footer in the screen's own band (the
/// summary beside the ink act), the act alone, the bar busy, and floating
/// off the edges.
library;

import 'package:flutter/material.dart';
import 'package:frosted_ui/frosted_ui.dart';

import '../kit.dart';

Widget kitActionBarDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Action bar',
  footer: FrostedActionBar(
    summary: '\$500.00',
    detail: 'To Jonah Reyes · arrives Thursday',
    label: 'Transfer',
    onPressed: () {},
  ),
  sections: [
    kitSection(
      'Docked, on its own band',
      children: [kitSpecimenActionBarDocked()],
    ),
    kitSection('The act alone', children: [kitSpecimenActionBarAlone()]),
    kitSection(
      'Busy',
      children: [
        FrostedActionBar(
          summary: '\$500.00',
          detail: 'To Jonah Reyes',
          label: 'Transfer',
          busy: true,
          onPressed: () {},
        ),
      ],
    ),
    kitSection('Floating', children: [kitSpecimenActionBarFloating()]),
  ],
);

/// Review's footer: the amount and its line beside Transfer.
Widget kitSpecimenActionBarDocked() => FrostedActionBar(
  summary: '\$500.00',
  detail: 'To Jonah Reyes · arrives Thursday',
  label: 'Transfer',
  onPressed: () {},
);

/// A bar standing off the edges on the high glass.
Widget kitSpecimenActionBarFloating() => FrostedActionBar(
  floating: true,
  label: 'Remind me Thursday',
  onPressed: () {},
);

/// The one act across the width.
Widget kitSpecimenActionBarAlone() =>
    FrostedActionBar(label: 'Continue', onPressed: () {});
