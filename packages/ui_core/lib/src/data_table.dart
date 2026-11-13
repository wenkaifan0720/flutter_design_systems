/// A data table, headless: the model ([DesignTableController]: filter,
/// sort, select, paginate) and a body ([DesignDataTable]) whose rows take
/// one tab stop (Up and Down move between them, Home and End to the ends,
/// Space or a press selects, Shift with either selects a run, Ctrl or Cmd
/// with A selects the page, Enter opens a row) and whose headers sort on a press.
library;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'localizations.dart';
import 'pressable.dart';

/// Which way a column sorts.
enum DesignSortDirection {
  /// Smallest first.
  ascending,

  /// Largest first.
  descending,
}

/// A column of a [DesignTableController].
@immutable
class DesignTableColumn<R> {
  /// A column [id], headed [label]; [sortKey] makes it sortable.
  const DesignTableColumn({
    required this.id,
    required this.label,
    this.sortKey,
    this.numeric = false,
  });

  /// Its id.
  final String id;

  /// Its heading.
  final String label;

  /// What a row sorts by in this column; null: it does not sort.
  final Comparable<Object?> Function(R row)? sortKey;

  /// Whether it holds numbers (the look aligns them to the end).
  final bool numeric;

  /// Whether a press on its header sorts it.
  bool get sortable => sortKey != null;
}

/// A page's selection, for its select-all checkbox.
enum DesignSelection {
  /// No row on the page is selected.
  none,

  /// Some are.
  some,

  /// All are.
  all,
}

/// A table's data and its view of it: the filter, the sort, the selection
/// and the page.
///
/// The caller makes it (a State's field, say), keeps it across rebuilds
/// and disposes it; a widget it is given to only listens to it.
///
/// ```dart
/// DesignTableController<String>(rows: const ['a', 'b'], columns: [DesignTableColumn<String>(id: 'name', label: 'Name', sortKey: (row) => row)])
/// ```
class DesignTableController<R> extends ChangeNotifier {
  /// A table of [rows] in [columns]. [rowKey] tells rows apart across
  /// replacements of the data (the row itself by default); [pageSize] null
  /// shows every row.
  DesignTableController({
    required List<R> rows,
    required this.columns,
    Object Function(R row)? rowKey,
    int? pageSize,
    this.filter,
    this.cycleToUnsorted = true,
  }) : _rows = List.of(rows),
       _key = rowKey ?? ((R row) => row as Object),
       _perPage = pageSize;

  /// The columns, in order.
  final List<DesignTableColumn<R>> columns;

  /// Whether [query] keeps a row; null: every row is kept.
  final bool Function(R row, String query)? filter;

  /// Whether a third press on a sorted column's header unsorts it (else it
  /// flips between ascending and descending).
  final bool cycleToUnsorted;

  final Object Function(R row) _key;
  List<R> _rows;
  int? _perPage;
  int _page = 0;
  String _query = '';
  String? _sortColumn;
  DesignSortDirection _direction = DesignSortDirection.ascending;
  final Set<Object> _selected = {};
  Object? _anchor;
  List<R>? _view;

  /// Every row, unfiltered and unsorted.
  List<R> get rows => List.unmodifiable(_rows);

  /// Replaces the data; selected rows that remain stay selected.
  set rows(List<R> rows) {
    _rows = List.of(rows);
    final keys = {for (final r in _rows) _key(r)};
    _selected.retainWhere(keys.contains);
    _changed(keepPage: true);
  }

  /// The filter's query.
  String get query => _query;

  /// Filters by [query], back to the first page.
  set query(String query) {
    if (query == _query) return;
    _query = query;
    _changed();
  }

  /// The sorted column's id, or null.
  String? get sortColumn => _sortColumn;

  /// Which way it sorts.
  DesignSortDirection get sortDirection => _direction;

  /// The sort of the column [id]: its direction, or null while it is not
  /// the sorted column.
  DesignSortDirection? sortOf(String id) =>
      id == _sortColumn ? _direction : null;

  /// A header's press: sorts by the column [id] ascending, then descending,
  /// then (with [cycleToUnsorted]) not at all. Equal rows keep their order.
  void sort(String id) {
    final column = columns.firstWhere((c) => c.id == id);
    if (!column.sortable) return;
    if (_sortColumn != id) {
      _sortColumn = id;
      _direction = DesignSortDirection.ascending;
    } else if (_direction == DesignSortDirection.ascending) {
      _direction = DesignSortDirection.descending;
    } else if (cycleToUnsorted) {
      _sortColumn = null;
      _direction = DesignSortDirection.ascending;
    } else {
      _direction = DesignSortDirection.ascending;
    }
    _changed();
  }

  /// Sorts by [id] in [direction] (null [id]: unsorted).
  void sortBy(
    String? id, [
    DesignSortDirection direction = DesignSortDirection.ascending,
  ]) {
    _sortColumn = id;
    _direction = direction;
    _changed();
  }

  /// The rows the filter keeps, sorted: every page.
  List<R> get filteredRows {
    final cached = _view;
    if (cached != null) return cached;
    final f = filter;
    final kept = [
      for (final r in _rows)
        if (_query.isEmpty || f == null || f(r, _query)) r,
    ];
    final id = _sortColumn;
    if (id != null) {
      final key = columns.firstWhere((c) => c.id == id).sortKey!;
      final order = {for (var i = 0; i < kept.length; i++) _key(kept[i]): i};
      final sign = _direction == DesignSortDirection.ascending ? 1 : -1;
      kept.sort((a, b) {
        final c = _compare(key(a), key(b)) * sign;
        return c != 0 ? c : order[_key(a)]!.compareTo(order[_key(b)]!);
      });
    }
    return _view = List.unmodifiable(kept);
  }

  static int _compare(Comparable<Object?>? a, Comparable<Object?>? b) {
    if (a == null) return b == null ? 0 : 1;
    if (b == null) return -1;
    return a.compareTo(b);
  }

  /// Rows per page, or null for one page of all.
  int? get pageSize => _perPage;

  /// Changes the page size, keeping the first row shown on screen.
  set pageSize(int? size) {
    final first = _page * (_perPage ?? 0);
    _perPage = size;
    _page = size == null ? 0 : first ~/ size;
    _changed(keepPage: true);
  }

  /// The page shown, from 0.
  int get page => _page;

  /// How many pages there are (at least 1).
  int get pageCount {
    final size = _perPage;
    if (size == null || filteredRows.isEmpty) return 1;
    return (filteredRows.length + size - 1) ~/ size;
  }

  /// Shows page [page] (clamped).
  void goToPage(int page) {
    final p = page.clamp(0, pageCount - 1);
    if (p == _page) return;
    _page = p;
    notifyListeners();
  }

  /// The rows on the shown page.
  List<R> get pageRows {
    final size = _perPage;
    if (size == null) return filteredRows;
    final start = _page * size;
    if (start >= filteredRows.length) return const [];
    return filteredRows.sublist(
      start,
      (start + size).clamp(0, filteredRows.length),
    );
  }

  /// Whether [row] is selected.
  bool isSelected(R row) => _selected.contains(_key(row));

  /// The selected rows, in the view's order (filtered-out ones last).
  List<R> get selectedRows {
    final shown = [
      for (final r in filteredRows)
        if (isSelected(r)) r,
    ];
    final hidden = [
      for (final r in _rows)
        if (isSelected(r) && !shown.contains(r)) r,
    ];
    return [...shown, ...hidden];
  }

  /// How many rows are selected.
  int get selectedCount => _selected.length;

  /// Toggles [row]; with [extend] (Shift) selects every row of the view
  /// from the last toggled row to this one.
  void toggle(R row, {bool extend = false}) {
    final key = _key(row);
    final anchor = _anchor;
    if (extend && anchor != null) {
      final keys = [for (final r in filteredRows) _key(r)];
      final a = keys.indexOf(anchor);
      final b = keys.indexOf(key);
      if (a >= 0 && b >= 0) {
        final lo = a < b ? a : b;
        final hi = a < b ? b : a;
        _selected.addAll(keys.sublist(lo, hi + 1));
        notifyListeners();
        return;
      }
    }
    if (!_selected.remove(key)) _selected.add(key);
    _anchor = key;
    notifyListeners();
  }

  /// The shown page's selection, for its select-all box.
  DesignSelection get pageSelection {
    final page = pageRows;
    final n = page.where(isSelected).length;
    if (n == 0) return DesignSelection.none;
    return n == page.length ? DesignSelection.all : DesignSelection.some;
  }

  /// The select-all box's press: clears the page when all of it is
  /// selected, else selects all of it.
  void togglePage() {
    final keys = [for (final r in pageRows) _key(r)];
    if (pageSelection == DesignSelection.all) {
      _selected.removeAll(keys);
    } else {
      _selected.addAll(keys);
    }
    notifyListeners();
  }

  /// Selects every row the filter keeps, on every page.
  void selectAll() {
    _selected.addAll([for (final r in filteredRows) _key(r)]);
    notifyListeners();
  }

  /// Clears the selection.
  void clearSelection() {
    _selected.clear();
    _anchor = null;
    notifyListeners();
  }

  void _changed({bool keepPage = false}) {
    _view = null;
    _page = keepPage ? _page.clamp(0, pageCount - 1) : 0;
    notifyListeners();
  }
}

/// One row, as [DesignDataTable.rowBuilder] gets it.
@immutable
class DesignTableRow<R> {
  /// A row; the table makes these.
  const DesignTableRow({
    required this.row,
    required this.index,
    required this.selected,
    required this.states,
    required this.toggle,
  });

  /// The row's data.
  final R row;

  /// Its place on the page.
  final int index;

  /// Whether it is selected.
  final bool selected;

  /// Its pressable states ([WidgetState.focused] while the keyboard is on
  /// it, hovered, pressed, selected).
  final Set<WidgetState> states;

  /// Toggles its selection: for its own checkbox.
  final VoidCallback toggle;
}

/// A sortable header, as [DesignDataTable.headerBuilder] gets it.
typedef DesignTableHeaderBuilder<R> = Widget Function(
  BuildContext context,
  DesignTableColumn<R> column,
  DesignSortDirection? sort,
  Set<WidgetState> states,
);

/// The rows of a [DesignTableController]'s page under a header row, with
/// one tab stop for the rows. The look paints the header cells, the cells,
/// and each row around its cells.
///
/// ```dart
/// DesignDataTable<String>(controller: controller, headerBuilder: (context, column, sort, states) => Text(column.label), cellBuilder: (context, row, column) => Text(row), rowBuilder: (context, row, cells) => Row(children: cells))
/// ```
class DesignDataTable<R> extends StatefulWidget {
  /// The table of [controller].
  const DesignDataTable({
    super.key,
    required this.controller,
    required this.headerBuilder,
    required this.cellBuilder,
    required this.rowBuilder,
    this.headerRowBuilder,
    this.selectable = true,
    this.onActivate,
    this.sortedHint,
  });

  /// The model: the rows, the columns and the table's view of them.
  /// The caller makes it, keeps it across
  /// rebuilds and disposes it.
  final DesignTableController<R> controller;

  /// Paints a header cell.
  final DesignTableHeaderBuilder<R> headerBuilder;

  /// Paints a cell.
  final Widget Function(
    BuildContext context,
    R row,
    DesignTableColumn<R> column,
  )
  cellBuilder;

  /// Paints a row around its cells.
  final Widget Function(
    BuildContext context,
    DesignTableRow<R> row,
    List<Widget> cells,
  )
  rowBuilder;

  /// Paints the header row around its cells; null puts them in a row of
  /// equal shares.
  final Widget Function(BuildContext context, List<Widget> cells)?
  headerRowBuilder;

  /// Whether a press and Space select rows.
  final bool selectable;

  /// A row's Enter, or its press when the table does not select.
  final ValueChanged<R>? onActivate;

  /// What a screen reader hears after a sorted header's label; null:
  /// [DesignLocalizations.dataTableSortedHint].
  final String Function(DesignSortDirection direction)? sortedHint;

  @override
  State<DesignDataTable<R>> createState() => _DesignDataTableState<R>();
}

class _SelectPageIntent extends Intent {
  const _SelectPageIntent();
}

class _OpenRowIntent extends Intent {
  const _OpenRowIntent();
}

class _DesignDataTableState<R> extends State<DesignDataTable<R>> {
  final List<FocusNode> _nodes = [];
  int _current = 0;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_changed);
  }

  @override
  void didUpdateWidget(DesignDataTable<R> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_changed);
      widget.controller.addListener(_changed);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_changed);
    for (final n in _nodes) {
      n.dispose();
    }
    super.dispose();
  }

  void _changed() => setState(() {});

  void _syncNodes(int count) {
    while (_nodes.length < count) {
      _nodes.add(FocusNode(debugLabel: 'DesignDataTable row ${_nodes.length}'));
    }
    while (_nodes.length > count) {
      _nodes.removeLast().dispose();
    }
    if (_current >= count) _current = count == 0 ? 0 : count - 1;
    for (var i = 0; i < _nodes.length; i++) {
      _nodes[i].skipTraversal = i != _current;
    }
  }

  void _move(int to) {
    if (_nodes.isEmpty) return;
    final i = to.clamp(0, _nodes.length - 1);
    setState(() => _current = i);
    _nodes[i].requestFocus();
  }

  void _press(R row, int index, {bool? extend}) {
    setState(() => _current = index);
    if (widget.selectable) {
      widget.controller.toggle(
        row,
        extend: extend ?? HardwareKeyboard.instance.isShiftPressed,
      );
    } else {
      widget.onActivate?.call(row);
    }
  }

  KeyEventResult _key(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    final rows = widget.controller.pageRows;
    if (key == LogicalKeyboardKey.arrowDown) {
      _move(_current + 1);
    } else if (key == LogicalKeyboardKey.arrowUp) {
      _move(_current - 1);
    } else if (key == LogicalKeyboardKey.home) {
      _move(0);
    } else if (key == LogicalKeyboardKey.end) {
      _move(_nodes.length - 1);
    } else if (key == LogicalKeyboardKey.space &&
        HardwareKeyboard.instance.isShiftPressed &&
        widget.selectable &&
        _current < rows.length) {
      _press(rows[_current], _current, extend: true);
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  Widget _header(BuildContext context, DesignTableColumn<R> column) {
    final c = widget.controller;
    final sort = c.sortOf(column.id);
    if (!column.sortable) {
      return Semantics(
        container: true,
        header: true,
        child: widget.headerBuilder(context, column, null, const {}),
      );
    }
    // One node: a heading you can press, with its sort.
    return MergeSemantics(
      child: Semantics(
        header: true,
        child: DesignPressable(
          onPressed: () => c.sort(column.id),
          semanticLabel: column.label,
          semanticValue: sort == null
              ? null
              : (widget.sortedHint ??
                    DesignLocalizations.of(context).dataTableSortedHint)(sort),
          excludeSemantics: true,
          builder: (context, states, _) =>
              widget.headerBuilder(context, column, sort, states),
        ),
      ),
    );
  }

  Widget _row(BuildContext context, R row, int i) {
    final c = widget.controller;
    final selected = c.isSelected(row);
    final activate = widget.onActivate;
    return DesignPressable(
      key: ValueKey<Object?>(row),
      focusNode: _nodes[i],
      onPressed: () => _press(row, i),
      selected: selected,
      semanticSelected: widget.selectable ? selected : null,
      button: activate != null || widget.selectable,
      shortcuts: activate != null && widget.selectable
          ? const {SingleActivator(LogicalKeyboardKey.enter): _OpenRowIntent()}
          : null,
      actions: activate != null && widget.selectable
          ? {
              _OpenRowIntent: CallbackAction<_OpenRowIntent>(
                onInvoke: (_) => activate(row),
              ),
            }
          : null,
      builder: (context, states, _) => widget.rowBuilder(
        context,
        DesignTableRow(
          row: row,
          index: i,
          selected: selected,
          states: states,
          toggle: () => _press(row, i),
        ),
        [
          for (final column in c.columns)
            widget.cellBuilder(context, row, column),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final rows = c.pageRows;
    _syncNodes(rows.length);
    final header = [for (final column in c.columns) _header(context, column)];
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        widget.headerRowBuilder?.call(context, header) ??
            Row(children: [for (final h in header) Expanded(child: h)]),
        Shortcuts(
          shortcuts: const {
            SingleActivator(LogicalKeyboardKey.keyA, control: true):
                _SelectPageIntent(),
            SingleActivator(LogicalKeyboardKey.keyA, meta: true):
                _SelectPageIntent(),
          },
          child: Actions(
            actions: {
              _SelectPageIntent: CallbackAction<_SelectPageIntent>(
                onInvoke: (_) => widget.selectable ? c.togglePage() : null,
              ),
            },
            child: Focus(
              canRequestFocus: false,
              skipTraversal: true,
              includeSemantics: false,
              onKeyEvent: _key,
              child: FocusTraversalGroup(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < rows.length; i++)
                      _row(context, rows[i], i),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
