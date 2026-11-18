/// [FrostedMenuBar]: a desktop's menus along a strip of glass,
/// [FrostedContextMenu]: a menu where a right click or a long press asks for
/// one, and
/// [FrostedCommand]: a palette of commands found by typing, in place or
/// raised over the app with [FrostedCommand.show].
library;

import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:frosted_ui/frosted_ui.dart';

import '../kit.dart';

void _none() {}

/// A shortcut of the platform's main modifier (⌘ on a Mac, Ctrl elsewhere)
/// and [key], as Frosted writes it ([frostedShortcutLabel]).
String _keys(
  BuildContext context,
  LogicalKeyboardKey key, {
  bool shift = false,
}) {
  final apple =
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.iOS;
  return frostedShortcutLabel(
    context,
    SingleActivator(key, meta: apple, control: !apple, shift: shift),
  );
}

List<DesignMenuEntry> _menus(BuildContext context) => [
  DesignMenuEntry(
    label: 'File',
    children: [
      DesignMenuEntry(
        label: 'New',
        shortcut: _keys(context, LogicalKeyboardKey.keyN),
        onPressed: _none,
      ),
      DesignMenuEntry(
        label: 'Open…',
        shortcut: _keys(context, LogicalKeyboardKey.keyO),
        onPressed: _none,
      ),
      const DesignMenuEntry(
        label: 'Open recent',
        children: [
          DesignMenuEntry(label: 'Notes', onPressed: _none),
          DesignMenuEntry(label: 'Roadmap', onPressed: _none),
        ],
      ),
      const DesignMenuEntry.divider(),
      DesignMenuEntry(
        label: 'Close',
        shortcut: _keys(context, LogicalKeyboardKey.keyW),
        onPressed: _none,
      ),
    ],
  ),
  DesignMenuEntry(
    label: 'Edit',
    children: [
      DesignMenuEntry(
        label: 'Undo',
        shortcut: _keys(context, LogicalKeyboardKey.keyZ),
        onPressed: _none,
      ),
      // No onPressed: disabled.
      DesignMenuEntry(
        label: 'Redo',
        shortcut: _keys(context, LogicalKeyboardKey.keyZ, shift: true),
      ),
      const DesignMenuEntry.divider(),
      DesignMenuEntry(
        label: 'Cut',
        shortcut: _keys(context, LogicalKeyboardKey.keyX),
        onPressed: _none,
      ),
      DesignMenuEntry(
        label: 'Copy',
        shortcut: _keys(context, LogicalKeyboardKey.keyC),
        onPressed: _none,
      ),
      DesignMenuEntry(
        label: 'Paste',
        shortcut: _keys(context, LogicalKeyboardKey.keyV),
        onPressed: _none,
      ),
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

List<DesignCommand> _commands(BuildContext context) => [
  DesignCommand(
    label: 'New document',
    group: 'Create',
    shortcut: _keys(context, LogicalKeyboardKey.keyN),
    onPressed: _none,
  ),
  const DesignCommand(label: 'New folder', group: 'Create', onPressed: _none),
  DesignCommand(
    label: 'Search files',
    group: 'Go to',
    keywords: const ['find'],
    shortcut: _keys(context, LogicalKeyboardKey.keyP),
    onPressed: _none,
  ),
  const DesignCommand(label: 'Settings', group: 'Go to', onPressed: _none),
  const DesignCommand(
    label: 'Sign out',
    group: 'Account',
    keywords: ['log out'],
    onPressed: _none,
  ),
];

Widget kitCommandDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  measured: true,
  title: 'Command',
  sections: [
    kitSection(
      'Menu bar',
      children: [
        Builder(
          builder: (context) =>
              kitRow([FrostedMenuBar(menus: _menus(context))]),
        ),
      ],
    ),
    kitSection(
      'Context menu',
      children: [
        Builder(
          builder: (context) => FrostedContextMenu(
            label: 'Note',
            items: [
              DesignMenuEntry(
                label: 'Copy',
                shortcut: _keys(context, LogicalKeyboardKey.keyC),
                onPressed: _none,
              ),
              const DesignMenuEntry(label: 'Duplicate', onPressed: _none),
              const DesignMenuEntry.divider(),
              const DesignMenuEntry(label: 'Delete', onPressed: _none),
            ],
            child: const FrostedCard(
              child: Text('Right-click or long-press this note'),
            ),
          ),
        ),
      ],
    ),
    kitSection(
      'Command palette',
      children: [
        Builder(
          builder: (context) =>
              FrostedCommand(commands: _commands(context), maxHeight: 280),
        ),
        Builder(
          builder: (context) => kitRow([
            FrostedButton.glass(
              'Open the palette',
              onPressed: () =>
                  FrostedCommand.show(context, commands: _commands(context)),
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
