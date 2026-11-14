/// Fluent 2's table: a team's files sorted by a column, rows selected
/// with the select-all check (neutral and brand), its three sizes and
/// scrolling sideways when its columns outrun the phone; and the property
/// list, a file's details in columns and stacked.
library;

import 'package:flutter/material.dart';
import 'package:fluent2_design_ui/fluent2_design_ui.dart';

import '../kit.dart';

/// Holds a live value for a specimen: [builder] draws the control with the
/// value and the setter it hands the control.
class _Live<T> extends StatefulWidget {
  const _Live(this.initial, this.builder);

  final T initial;
  final Widget Function(T value, ValueChanged<T> set) builder;

  @override
  State<_Live<T>> createState() => _LiveState<T>();
}

class _LiveState<T> extends State<_Live<T>> {
  late T _value = widget.initial;

  @override
  Widget build(BuildContext context) =>
      widget.builder(_value, (v) => setState(() => _value = v));
}

Widget kitTableDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Table and properties',
  sections: [
    kitSection('Sorted by Modified', children: [kitSpecimenTableFiles()]),
    kitSection('Selected rows', children: [kitSpecimenTableSelected()]),
    kitSection(
      'Brand selection',
      children: [
        _filesTable(
          selectable: true,
          appearance: Fluent2TableSelectionAppearance.brand,
        ),
      ],
    ),
    for (final size in Fluent2TableSize.values)
      kitSection(
        'Size ${kitSay(size).toLowerCase()}',
        children: [_filesTable(size: size)],
      ),
    kitSection('Properties', children: [kitSpecimenPropertiesColumns()]),
    kitSection(
      'Properties stacked',
      children: [kitSpecimenPropertiesStacked()],
    ),
  ],
);

const List<(String, IconData, String, String, int)> _files = [
  ('Q3 plan.docx', Fluent2Icons.document, 'Kai Tanaka', '2h ago', 2),
  (
    'Brand guidelines.pdf',
    Fluent2Icons.documentText,
    'Mara Okafor',
    'Yesterday',
    8,
  ),
  ('Offsite photos', Fluent2Icons.folder, 'Noor Haddad', 'Mon', 140),
  ('Roadmap.pptx', Fluent2Icons.board, 'Ines Duarte', 'Oct 20', 12),
];

/// A table's live state: the sorted column, its direction, the rows
/// selected.
typedef _View = ({int column, Fluent2SortDirection direction, Set<int> picked});

const _View _start = (
  column: 2,
  direction: Fluent2SortDirection.descending,
  picked: {1},
);

const List<Fluent2TableColumn> _columns = [
  Fluent2TableColumn('Name', flex: 2, minWidth: 180, sortable: true),
  Fluent2TableColumn('Owner', minWidth: 128, sortable: true),
  Fluent2TableColumn('Modified', minWidth: 104, sortable: true),
  Fluent2TableColumn('Size', minWidth: 72, numeric: true, sortable: true),
];

/// [view] after a press on column [i]'s header: the same column flips its
/// direction, another sorts ascending.
_View _sortBy(_View view, int i) => (
  column: i,
  direction: view.column == i
      ? (view.direction == Fluent2SortDirection.ascending
            ? Fluent2SortDirection.descending
            : Fluent2SortDirection.ascending)
      : Fluent2SortDirection.ascending,
  picked: view.picked,
);

/// The files' rows in [view]'s order (Modified sorts by recency, the
/// order the list is written in).
List<Fluent2TableRow> _rows(_View view) {
  final order = [for (var i = 0; i < _files.length; i++) i];
  final up = view.direction == Fluent2SortDirection.ascending;
  order.sort((a, b) {
    final x = _files[a], y = _files[b];
    final c = switch (view.column) {
      0 => x.$1.compareTo(y.$1),
      1 => x.$3.compareTo(y.$3),
      3 => x.$5.compareTo(y.$5),
      _ => a.compareTo(b),
    };
    return up ? c : -c;
  });
  return [
    for (final i in order)
      Fluent2TableRow(
        onPressed: () {},
        cells: [
          Fluent2TableCell(
            _files[i].$1,
            media: Icon(_files[i].$2),
            primary: true,
          ),
          Fluent2TableCell(_files[i].$3),
          Fluent2TableCell(_files[i].$4),
          Fluent2TableCell('${_files[i].$5} MB'),
        ],
      ),
  ];
}

/// A live table of the team's files, for the demo's bands.
Widget _filesTable({
  Fluent2TableSize size = Fluent2TableSize.medium,
  bool selectable = false,
  Fluent2TableSelectionAppearance appearance =
      Fluent2TableSelectionAppearance.neutral,
}) => _Live<_View>(
  _start,
  (view, set) => Fluent2Table(
    label: 'Northwind files',
    size: size,
    selectionAppearance: appearance,
    columns: _columns,
    sortColumn: view.column,
    sortDirection: view.direction,
    onSort: (i) => set(_sortBy(view, i)),
    selected: selectable ? view.picked : null,
    onSelectionChanged: (s) =>
        set((column: view.column, direction: view.direction, picked: s)),
    rows: _rows(view),
  ),
);

const List<Fluent2DescriptionItem> _details = [
  Fluent2DescriptionItem('Type', 'Document', icon: Fluent2Icons.document),
  Fluent2DescriptionItem('Owner', 'Kai Tanaka', icon: Fluent2Icons.person),
  Fluent2DescriptionItem('Modified', 'Today 11:42', icon: Fluent2Icons.clock),
  Fluent2DescriptionItem('Size', '2.4 MB', icon: Fluent2Icons.cloud),
  Fluent2DescriptionItem(
    'Location',
    'Northwind / Planning',
    icon: Fluent2Icons.folder,
  ),
];

// --- Specimens --------------------------------------------------------------

Widget kitSpecimenTableFiles() => _Live<_View>(
  _start,
  (view, set) => Fluent2Table(
    label: 'Northwind files',
    columns: _columns,
    sortColumn: view.column,
    sortDirection: view.direction,
    onSort: (i) => set(_sortBy(view, i)),
    rows: _rows(view),
  ),
);

Widget kitSpecimenTableSelected() => _Live<_View>(
  _start,
  (view, set) => Fluent2Table(
    label: 'Northwind files',
    columns: _columns,
    sortColumn: view.column,
    sortDirection: view.direction,
    onSort: (i) => set(_sortBy(view, i)),
    selected: view.picked,
    onSelectionChanged: (s) =>
        set((column: view.column, direction: view.direction, picked: s)),
    rows: _rows(view),
  ),
);

Widget kitSpecimenPropertiesColumns() => const Fluent2DescriptionList(
  title: 'Details',
  layout: Fluent2DescriptionListLayout.columns,
  dividers: true,
  properties: _details,
);

Widget kitSpecimenPropertiesStacked() => const Fluent2DescriptionList(
  title: 'Details',
  layout: Fluent2DescriptionListLayout.stacked,
  properties: _details,
);
