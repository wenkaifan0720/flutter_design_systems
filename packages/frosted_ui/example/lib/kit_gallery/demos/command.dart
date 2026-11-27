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

List<RawMenuEntry> _menus(BuildContext context) => [
  RawMenuEntry(
    label: 'File',
    children: [
      RawMenuEntry(
        label: 'New',
        shortcut: _keys(context, LogicalKeyboardKey.keyN),
        onPressed: _none,
      ),
      RawMenuEntry(
        label: 'Open…',
        shortcut: _keys(context, LogicalKeyboardKey.keyO),
        onPressed: _none,
      ),
      const RawMenuEntry(
        label: 'Open recent',
        children: [
          RawMenuEntry(label: 'Notes', onPressed: _none),
          RawMenuEntry(label: 'Roadmap', onPressed: _none),
        ],
      ),
      const RawMenuEntry.divider(),
      RawMenuEntry(
        label: 'Close',
        shortcut: _keys(context, LogicalKeyboardKey.keyW),
        onPressed: _none,
      ),
    ],
  ),
  RawMenuEntry(
    label: 'Edit',
    children: [
      RawMenuEntry(
        label: 'Undo',
        shortcut: _keys(context, LogicalKeyboardKey.keyZ),
        onPressed: _none,
      ),
      // No onPressed: disabled.
      RawMenuEntry(
        label: 'Redo',
        shortcut: _keys(context, LogicalKeyboardKey.keyZ, shift: true),
      ),
      const RawMenuEntry.divider(),
      RawMenuEntry(
        label: 'Cut',
        shortcut: _keys(context, LogicalKeyboardKey.keyX),
        onPressed: _none,
      ),
      RawMenuEntry(
        label: 'Copy',
        shortcut: _keys(context, LogicalKeyboardKey.keyC),
        onPressed: _none,
      ),
      RawMenuEntry(
        label: 'Paste',
        shortcut: _keys(context, LogicalKeyboardKey.keyV),
        onPressed: _none,
      ),
    ],
  ),
  const RawMenuEntry(
    label: 'View',
    children: [
      RawMenuEntry(label: 'Sidebar', checked: true, onPressed: _none),
      RawMenuEntry(label: 'Status bar', checked: false, onPressed: _none),
    ],
  ),
];

List<RawCommand> _commands(BuildContext context) => [
  RawCommand(
    label: 'New document',
    group: 'Create',
    shortcut: _keys(context, LogicalKeyboardKey.keyN),
    onPressed: _none,
  ),
  const RawCommand(label: 'New folder', group: 'Create', onPressed: _none),
  RawCommand(
    label: 'Search files',
    group: 'Go to',
    keywords: const ['find'],
    shortcut: _keys(context, LogicalKeyboardKey.keyP),
    onPressed: _none,
  ),
  const RawCommand(label: 'Settings', group: 'Go to', onPressed: _none),
  const RawCommand(
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
            semanticLabel: 'Note',
            items: [
              RawMenuEntry(
                label: 'Copy',
                shortcut: _keys(context, LogicalKeyboardKey.keyC),
                onPressed: _none,
              ),
              const RawMenuEntry(label: 'Duplicate', onPressed: _none),
              const RawMenuEntry.divider(),
              const RawMenuEntry(label: 'Delete', onPressed: _none),
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
    RawMenuEntry(
      label: 'File',
      children: [RawMenuEntry(label: 'New transfer', onPressed: () {})],
    ),
    RawMenuEntry(
      label: 'Edit',
      children: [RawMenuEntry(label: 'Copy', onPressed: () {})],
    ),
    RawMenuEntry(
      label: 'View',
      children: [RawMenuEntry(label: 'Activity', onPressed: () {})],
    ),
  ],
);
