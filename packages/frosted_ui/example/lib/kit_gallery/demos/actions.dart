/// [FrostedButtonGroup] and [FrostedKbd]: acts that belong together, and
/// the keys that reach them.
library;

import 'package:flutter/material.dart';
import 'package:frosted_ui/frosted_ui.dart';

import '../kit.dart';

Widget kitActionsDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  measured: true,
  title: 'Button group & keys',
  sections: [
    kitSection(
      'Button group',
      children: [
        kitRow([
          FrostedButtonGroup(
            label: 'History',
            items: [
              FrostedButtonGroupItem(
                label: 'Undo',
                icon: FrostedGlyphs.undo,
                showLabel: false,
                onPressed: () {},
              ),
              FrostedButtonGroupItem(
                label: 'Redo',
                icon: FrostedGlyphs.redo,
                showLabel: false,
                onPressed: () {},
              ),
            ],
          ),
          KitHeld<int>(
            0,
            (i, set) => FrostedButtonGroup(
              label: 'View',
              items: [
                for (final (n, word) in const ['Day', 'Week', 'Month'].indexed)
                  FrostedButtonGroupItem(
                    label: word,
                    selected: i == n,
                    onPressed: () => set(n),
                  ),
              ],
            ),
          ),
        ]),
      ],
    ),
    kitSection(
      'Keys',
      children: [
        kitRow(const [
          FrostedKbd('Esc'),
          FrostedKbd.combo(['⌘', 'K'], semanticsLabel: 'Command K'),
          FrostedKbd.combo(['Ctrl', 'Shift', 'P']),
        ]),
      ],
    ),
  ],
);

/// Undo and redo, joined: a toolbar's pair of glyph buttons.
Widget kitSpecimenButtonGroup() => Center(
  heightFactor: 1,
  child: FrostedButtonGroup(
    items: [
      FrostedButtonGroupItem(
        label: 'Undo',
        icon: FrostedGlyphs.undo,
        showLabel: false,
        onPressed: () {},
      ),
      FrostedButtonGroupItem(
        label: 'Redo',
        icon: FrostedGlyphs.redo,
        showLabel: false,
        onPressed: () {},
      ),
    ],
  ),
);

/// A shortcut's keys, as a menu or a tooltip names them.
Widget kitSpecimenKbd() => const Center(
  heightFactor: 1,
  child: Row(
    mainAxisSize: MainAxisSize.min,
    spacing: 4,
    children: [FrostedKbd('⌘'), FrostedKbd('K')],
  ),
);
