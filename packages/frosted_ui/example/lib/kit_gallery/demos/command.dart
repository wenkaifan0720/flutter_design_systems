/// [FrostedMenuBar]: a desktop's menus along a strip of glass, and
/// [FrostedCommand]: a palette of commands found by typing, in place or
/// raised over the app with [FrostedCommand.show].
library;

import 'package:flutter/material.dart';
import 'package:frosted_ui/frosted_ui.dart';

import '../kit.dart';

void _none() {}

final _menus = [
  const DesignMenuEntry(
    label: 'File',
    children: [
      DesignMenuEntry(label: 'New', shortcut: '⌘N', onPressed: _none),
      DesignMenuEntry(label: 'Open…', shortcut: '⌘O', onPressed: _none),
      DesignMenuEntry(
        label: 'Open recent',
        children: [
          DesignMenuEntry(label: 'Notes', onPressed: _none),
          DesignMenuEntry(label: 'Roadmap', onPressed: _none),
        ],
      ),
      DesignMenuEntry.divider(),
      DesignMenuEntry(label: 'Close', shortcut: '⌘W', onPressed: _none),
    ],
  ),
  const DesignMenuEntry(
    label: 'Edit',
    children: [
      DesignMenuEntry(label: 'Undo', shortcut: '⌘Z', onPressed: _none),
      // No onPressed: disabled.
      DesignMenuEntry(label: 'Redo', shortcut: '⇧⌘Z'),
      DesignMenuEntry.divider(),
      DesignMenuEntry(label: 'Cut', shortcut: '⌘X', onPressed: _none),
      DesignMenuEntry(label: 'Copy', shortcut: '⌘C', onPressed: _none),
      DesignMenuEntry(label: 'Paste', shortcut: '⌘V', onPressed: _none),
    ],
  ),
  const DesignMenuEntry(
    label: 'View',
    children: [
      DesignMenuEntry(label: 'Sidebar', checked: true, onPressed: _none),
      DesignMenuEntry(label: 'Status bar', checked: false, onPressed: _none),
    ],
  ),
];

const _commands = [
  DesignCommand(
    label: 'New document',
    group: 'Create',
    shortcut: '⌘N',
    onPressed: _none,
  ),
  DesignCommand(label: 'New folder', group: 'Create', onPressed: _none),
  DesignCommand(
    label: 'Search files',
    group: 'Go to',
    keywords: ['find'],
    shortcut: '⌘P',
    onPressed: _none,
  ),
  DesignCommand(label: 'Settings', group: 'Go to', onPressed: _none),
  DesignCommand(
    label: 'Sign out',
    group: 'Account',
    keywords: ['log out'],
    onPressed: _none,
  ),
];

Widget kitCommandDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Command',
  sections: [
    kitSection(
      'Menu bar',
      children: [
        kitRow([FrostedMenuBar(menus: _menus)]),
      ],
    ),
    kitSection(
      'Command palette',
      children: [
        const FrostedCommand(commands: _commands, maxHeight: 280),
        Builder(
          builder: (context) => kitRow([
            FrostedButton.glass(
              'Open the palette',
              onPressed: () =>
                  FrostedCommand.show(context, commands: _commands),
            ),
          ]),
        ),
      ],
    ),
  ],
);

/// An app's menus, along a desktop window's top.
Widget kitSpecimenMenuBar() => FrostedMenuBar(
  menus: [
    DesignMenuEntry(
      label: 'File',
      children: [DesignMenuEntry(label: 'New transfer', onPressed: () {})],
    ),
    DesignMenuEntry(
      label: 'Edit',
      children: [DesignMenuEntry(label: 'Copy', onPressed: () {})],
    ),
    DesignMenuEntry(
      label: 'View',
      children: [DesignMenuEntry(label: 'Activity', onPressed: () {})],
    ),
  ],
);
