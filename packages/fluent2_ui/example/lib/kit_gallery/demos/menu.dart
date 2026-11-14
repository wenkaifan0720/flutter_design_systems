/// Fluent 2's menu: [Fluent2Menu.show] dropping a file's commands from its
/// more button and the menu button's sort order with its checks, and the
/// same popover drawn in place (glyphs, shortcuts, a divider, Delete in
/// the danger ink; a group header over checkable items).
library;

import 'package:flutter/material.dart';
import 'package:fluent2_ui/fluent2_ui.dart';

import '../kit.dart';

const List<Fluent2MenuItem<String>> _fileCommands = [
  Fluent2MenuItem('open', 'Open', icon: Fluent2Icons.open),
  Fluent2MenuItem('rename', 'Rename', icon: Fluent2Icons.edit, secondary: 'F2'),
  Fluent2MenuItem('copy', 'Copy link', icon: Fluent2Icons.link),
  Fluent2MenuItem('move', 'Move to', icon: Fluent2Icons.folder),
  Fluent2MenuItem(
    'delete',
    'Delete',
    icon: Fluent2Icons.delete,
    danger: true,
    divider: true,
  ),
];

List<Fluent2MenuItem<String>> _sortBy(String current) => [
  for (final (id, label) in const [
    ('name', 'Name'),
    ('modified', 'Modified'),
    ('size', 'File size'),
  ])
    Fluent2MenuItem(id, label, checked: id == current),
];

Widget kitMenuDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Menu',
  sections: [
    kitSection('Opened from a control', children: [const _Open()]),
    kitSection('In place', children: [kitSpecimenMenuFile()]),
    kitSection('Checkable, under a header', children: [kitSpecimenMenuSort()]),
  ],
);

class _Open extends StatefulWidget {
  const _Open();

  @override
  State<_Open> createState() => _OpenState();
}

class _OpenState extends State<_Open> {
  String _sort = 'modified';
  String? _last;

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: Fluent2Spacing.s,
      children: [
        kitRow([
          Builder(
            builder: (anchor) => Fluent2IconButton(
              Fluent2Icons.moreHorizontal,
              label: 'More options',
              onPressed: () async {
                final picked = await Fluent2Menu.show<String>(
                  anchor,
                  items: _fileCommands,
                );
                if (picked != null) setState(() => _last = picked);
              },
            ),
          ),
          Builder(
            builder: (anchor) => Fluent2MenuButton(
              'Sort',
              icon: Fluent2Icons.arrowSort,
              onPressed: () async {
                final picked = await Fluent2Menu.show<String>(
                  anchor,
                  title: 'Sort by',
                  items: _sortBy(_sort),
                );
                if (picked != null) setState(() => _sort = picked);
              },
            ),
          ),
        ]),
        Text(
          'Sorted by $_sort${_last == null ? '' : ' · last: $_last'}',
          style: t.caption1.c(t.textSecondary),
        ),
      ],
    );
  }
}

// --- Specimens --------------------------------------------------------------
// One builder per specimen in metadata.yaml. The stage (kitSpecimenStage)
// styles them; a builder never names a style.

/// A file's commands: glyphs, Rename's shortcut, Delete under a divider in
/// the danger ink.
Widget kitSpecimenMenuFile() => Align(
  alignment: AlignmentDirectional.centerStart,
  child: Fluent2Menu<String>(items: _fileCommands, onSelected: (_) {}),
);

/// The sort order under its group header, Modified checked.
Widget kitSpecimenMenuSort() => Align(
  alignment: AlignmentDirectional.centerStart,
  child: Fluent2Menu<String>(
    title: 'Sort by',
    items: _sortBy('modified'),
    onSelected: (_) {},
  ),
);
