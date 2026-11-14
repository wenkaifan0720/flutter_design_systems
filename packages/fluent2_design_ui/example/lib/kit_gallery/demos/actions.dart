/// The keys of a shortcut, written out at the end of what they do, as
/// Fluent's menus write them.
library;

import 'package:flutter/material.dart';
import 'package:fluent2_design_ui/fluent2_design_ui.dart';

import '../kit.dart';

Widget kitActionsDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Shortcuts',
  sections: [
    kitSection('Keys to press', children: [kitSpecimenKbd()]),
  ],
);

Widget kitSpecimenKbd() => Builder(
  builder: (context) {
    final t = context.fluent2Theme;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 320),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: Fluent2Spacing.s,
        children: [
          for (final (keys, what) in const [
            (['Ctrl', 'K'], 'Search commands'),
            (['Ctrl', 'Shift', 'N'], 'New meeting'),
            (['Esc'], 'Close'),
          ])
            Row(
              spacing: Fluent2Spacing.m,
              children: [
                Expanded(child: Text(what, style: t.body1)),
                Fluent2Kbd(keys),
              ],
            ),
        ],
      ),
    );
  },
);
