/// A desktop app's menu bar: File, Edit, View, with shortcuts, checks, a
/// submenu and a disabled item, live.
library;

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../kit.dart';

Widget kitMenuBarDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Menu bar',
  sections: [
    kitSection(
      'Menu bar',
      children: [
        const _Bar(),
        kitNote(
          '← → move along the bar, ↓ opens; with a menu open, a pointer over '
          'another name opens that one.',
        ),
      ],
    ),
  ],
);

class _Bar extends StatefulWidget {
  const _Bar();

  @override
  State<_Bar> createState() => _BarState();
}

/// File, Edit and View: [say] reports a command; Sidebar and Wrap lines
/// are checks.
List<MinimalMenuEntry> _menus({
  required ValueChanged<String> say,
  required bool sidebar,
  required bool wrap,
  required VoidCallback onSidebar,
  required VoidCallback onWrap,
}) => [
  MinimalMenuEntry(
    'File',
    children: [
      MinimalMenuEntry(
        'New issue',
        icon: LucideIcons.plus,
        shortcut: _command(LogicalKeyboardKey.keyN),
        onPressed: () => say('New issue'),
      ),
      MinimalMenuEntry(
        'Open…',
        icon: LucideIcons.folderOpen,
        shortcut: _command(LogicalKeyboardKey.keyO),
        onPressed: () => say('Open'),
      ),
      MinimalMenuEntry(
        'Open recent',
        children: [
          MinimalMenuEntry('HAB-12', onPressed: () => say('HAB-12')),
          MinimalMenuEntry('HAB-9', onPressed: () => say('HAB-9')),
        ],
      ),
      const MinimalMenuEntry.divider(),
      MinimalMenuEntry('Print…', shortcut: _command(LogicalKeyboardKey.keyP)),
    ],
  ),
  MinimalMenuEntry(
    'Edit',
    children: [
      MinimalMenuEntry(
        'Undo',
        shortcut: _command(LogicalKeyboardKey.keyZ),
        onPressed: () => say('Undo'),
      ),
      MinimalMenuEntry(
        'Redo',
        shortcut: _command(LogicalKeyboardKey.keyZ, shift: true),
        onPressed: () => say('Redo'),
      ),
      const MinimalMenuEntry.divider(),
      MinimalMenuEntry(
        'Find',
        icon: LucideIcons.search,
        shortcut: _command(LogicalKeyboardKey.keyF),
        onPressed: () => say('Find'),
      ),
    ],
  ),
  MinimalMenuEntry(
    'View',
    children: [
      MinimalMenuEntry('Sidebar', checked: sidebar, onPressed: onSidebar),
      MinimalMenuEntry('Wrap lines', checked: wrap, onPressed: onWrap),
    ],
  ),
];

class _BarState extends State<_Bar> {
  bool _sidebar = true;
  bool _wrap = false;

  @override
  Widget build(BuildContext context) => Align(
    alignment: AlignmentDirectional.centerStart,
    child: MinimalMenuBar(
      menus: _menus(
        say: (what) => showMinimalSnackBar(context, what),
        sidebar: _sidebar,
        wrap: _wrap,
        onSidebar: () => setState(() => _sidebar = !_sidebar),
        onWrap: () => setState(() => _wrap = !_wrap),
      ),
    ),
  );
}

// --- catalog specimens -------------------------------------------------------

/// The bar, its menus closed.
Widget kitSpecimenMenuBar() => Center(
  child: MinimalMenuBar(
    menus: _menus(
      say: (_) {},
      sidebar: true,
      wrap: false,
      onSidebar: () {},
      onWrap: () {},
    ),
  ),
);

/// A command's shortcut on the platform's own command key: ⌘ on a Mac or
/// an iPad, Ctrl elsewhere.
SingleActivator _command(LogicalKeyboardKey key, {bool shift = false}) {
  final apple =
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.iOS;
  return SingleActivator(key, meta: apple, control: !apple, shift: shift);
}
