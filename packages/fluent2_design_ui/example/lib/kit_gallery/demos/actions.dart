/// The keys of a shortcut, written out at the end of what they do, as
/// Fluent's menus write them.
library;

import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
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
    // The app's shortcuts take Command on a Mac and Ctrl elsewhere; ui_core
    // writes their keys as the platform does.
    final apple = switch (defaultTargetPlatform) {
      TargetPlatform.macOS || TargetPlatform.iOS => true,
      _ => false,
    };
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 320),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: Fluent2Spacing.s,
        children: [
          for (final (keys, what) in [
            (
              SingleActivator(
                LogicalKeyboardKey.keyK,
                control: !apple,
                meta: apple,
              ),
              'Search commands',
            ),
            (
              SingleActivator(
                LogicalKeyboardKey.keyN,
                control: !apple,
                meta: apple,
                shift: true,
              ),
              'New meeting',
            ),
            (const SingleActivator(LogicalKeyboardKey.escape), 'Close'),
          ])
            Row(
              spacing: Fluent2Spacing.m,
              children: [
                Expanded(child: Text(what, style: t.body1)),
                Fluent2Kbd.shortcut(keys),
              ],
            ),
        ],
      ),
    );
  },
);
