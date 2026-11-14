/// The wordmark, the app's name as its mark: beside the ink mark wearing
/// the prism's glyph, in its type alone, or on a badge of the ink.
library;

import 'package:flutter/material.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../kit.dart';

Widget kitWordmarkDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Wordmark',
  sections: [
    kitSection('Beside its mark', children: [kitSpecimenWordmarkMark()]),
    kitSection('In its type', children: [kitSpecimenWordmarkType()]),
    kitSection('On a badge', children: [kitSpecimenWordmarkBadge()]),
  ],
);

// --- catalog specimens -------------------------------------------------------

/// A brand word beside the ink mark, as the sidebar heads itself.
Widget kitSpecimenWordmarkMark() => const Align(
  alignment: AlignmentDirectional.centerStart,
  heightFactor: 1,
  child: FrostedWordmark('harbor'),
);

/// Northlight in the wordmark type alone.
Widget kitSpecimenWordmarkType() => const Align(
  alignment: AlignmentDirectional.centerStart,
  heightFactor: 1,
  child: FrostedWordmark('Northlight', form: FrostedWordmarkForm.type),
);

/// Northlight on a badge of the ink, its own glyph on the mark.
Widget kitSpecimenWordmarkBadge() => const Align(
  alignment: AlignmentDirectional.centerStart,
  heightFactor: 1,
  child: FrostedWordmark(
    'Northlight',
    form: FrostedWordmarkForm.badge,
    glyph: LucideIcons.sparkles,
  ),
);
