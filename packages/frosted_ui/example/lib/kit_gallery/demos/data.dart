/// [FrostedDataTable]: records to sort, select and page through, and
/// [FrostedTreeView]: nested rows to open and close.
library;

import 'package:flutter/material.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../kit.dart';

typedef _File = ({String name, String kind, int kb});

const List<_File> _files = [
  (name: 'Brief', kind: 'Document', kb: 48),
  (name: 'Cover', kind: 'Image', kb: 2310),
  (name: 'Budget', kind: 'Sheet', kb: 96),
  (name: 'Interview', kind: 'Audio', kb: 18420),
  (name: 'Notes', kind: 'Document', kb: 12),
  (name: 'Plan', kind: 'Document', kb: 64),
  (name: 'Poster', kind: 'Image', kb: 5120),
  (name: 'Survey', kind: 'Sheet', kb: 210),
];

String _size(int kb) =>
    kb >= 1024 ? '${(kb / 1024).toStringAsFixed(1)} MB' : '$kb KB';

class _Folder {
  const _Folder(this.name, [this.children = const []]);

  final String name;
  final List<_Folder> children;
}

const _roots = [
  _Folder('Projects', [
    _Folder('Launch', [_Folder('Brief'), _Folder('Plan')]),
    _Folder('Research', [_Folder('Survey'), _Folder('Interview')]),
  ]),
  _Folder('Shared', [_Folder('Poster')]),
  _Folder('Notes'),
];

Widget kitDataDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Data',
  sections: [
    kitSection('Data table', children: [kitSpecimenDataTable()]),
    kitSection('Tree view', children: [kitSpecimenTreeView()]),
  ],
);

DesignTableController<_File> _filesTable() => DesignTableController<_File>(
  rows: _files,
  rowKey: (f) => f.name,
  pageSize: 5,
  columns: [
    DesignTableColumn(id: 'name', label: 'Name', sortKey: (f) => f.name),
    DesignTableColumn(id: 'kind', label: 'Kind', sortKey: (f) => f.kind),
    DesignTableColumn(
      id: 'size',
      label: 'Size',
      numeric: true,
      sortKey: (f) => f.kb,
    ),
  ],
);

DesignTreeController<_Folder> _folders() => DesignTreeController<_Folder>(
  roots: _roots,
  childrenOf: (f) => f.children,
  expanded: [_roots.first],
);

/// Files to sort, select and page through, five a page.
Widget kitSpecimenDataTable() => KitOwned<DesignTableController<_File>>(
  _filesTable,
  (rows) => FrostedDataTable<_File>(
    controller: rows,
    label: 'Files',
    cellBuilder: (context, f, column) => Text(switch (column.id) {
      'name' => f.name,
      'kind' => f.kind,
      _ => _size(f.kb),
    }),
  ),
);

/// Folders, the first open.
Widget kitSpecimenTreeView() => KitOwned<DesignTreeController<_Folder>>(
  _folders,
  (nodes) => FrostedTreeView<_Folder>(
    controller: nodes,
    label: 'Folders',
    labelOf: (f) => f.name,
    leadingOf: (f) =>
        Icon(f.children.isEmpty ? LucideIcons.file : LucideIcons.folder),
  ),
);
