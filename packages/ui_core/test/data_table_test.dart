import 'dart:ui' show Tristate;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/ui_core.dart';

import 'behaviour_contract.dart';
import 'behaviour_harness.dart';

typedef _Person = ({String name, int age});

const List<_Person> _people = [
  (name: 'Ada', age: 36),
  (name: 'Bo', age: 25),
  (name: 'Cy', age: 36),
  (name: 'Di', age: 19),
  (name: 'Ed', age: 52),
];

final List<DesignTableColumn<_Person>> _columns = [
  DesignTableColumn(id: 'name', label: 'Name', sortKey: (p) => p.name),
  DesignTableColumn(
    id: 'age',
    label: 'Age',
    sortKey: (p) => p.age,
    numeric: true,
  ),
  const DesignTableColumn(id: 'note', label: 'Note'),
];

DesignTableController<_Person> _controller({int? pageSize}) =>
    DesignTableController(
      rows: _people,
      columns: _columns,
      rowKey: (p) => p.name,
      pageSize: pageSize,
      filter: (p, q) => p.name.toLowerCase().contains(q.toLowerCase()),
    );

List<String> _names(List<_Person> rows) => [for (final p in rows) p.name];

final Map<String, Set<WidgetState>> _rowStates = {};

// The bare reference painter: text cells in rows, a header that says its sort.
Widget _table(
  DesignTableController<_Person> c, {
  ValueChanged<_Person>? onActivate,
  bool selectable = true,
}) => harness(_view(c, onActivate: onActivate, selectable: selectable));

Widget _view(
  DesignTableController<_Person> c, {
  ValueChanged<_Person>? onActivate,
  bool selectable = true,
}) => Column(
  children: [
    DesignDataTable<_Person>(
      controller: c,
      selectable: selectable,
      onActivate: onActivate,
      headerBuilder: (context, column, sort, states) => SizedBox(
        height: 44,
        child: Text('${column.label}${sort == null ? '' : ' (${sort.name})'}'),
      ),
      cellBuilder: (context, row, column) => Text(switch (column.id) {
        'name' => row.name,
        'age' => '${row.age}',
        _ => '',
      }),
      rowBuilder: (context, row, cells) {
        _rowStates[row.row.name] = row.states;
        return SizedBox(
          height: 44,
          child: Row(children: [for (final c in cells) Expanded(child: c)]),
        );
      },
    ),
    // A control after the table, to tab out to.
    Focus(
      child: Builder(
        builder: (context) =>
            Text(Focus.of(context).hasFocus ? 'after: focused' : 'after'),
      ),
    ),
  ],
);

Finder _rowOf(String name) =>
    find.ancestor(of: find.text(name), matching: find.byType(DesignPressable));

void main() {
  setUp(_rowStates.clear);

  bool focused(WidgetTester t, String name) =>
      semanticsOf(
        t,
        _rowOf(name),
      ).getSemanticsData().flagsCollection.isFocused ==
      Tristate.isTrue;

  behaviourContract(
    'DesignDataTable',
    build: (c) => Owned<DesignTableController<_Person>>(
      create: _controller,
      builder: (context, c) => _view(c),
    ),
    node: () => _rowOf('Ada'),
    semantics: isSemantics(
      isButton: true,
      isFocusable: true,
      hasTapAction: true,
      hasSelectedState: true,
      isSelected: false,
    ),
    root: () => find.byType(DesignDataTable<_Person>),
    noDisabledState: 'a table is never disabled; a look greys a row',
    keyboard: (p) async {
      final t = p.tester;
      expect(
        t.getSemantics(find.text('Age')),
        isSemantics(label: 'Age', isHeader: true, isButton: true),
        reason: 'a sortable header is a heading you can press',
      );
      await p.tabInto();
      await p.key(LogicalKeyboardKey.arrowDown);
      expect(focused(t, 'Bo'), isTrue);
      await p.key(LogicalKeyboardKey.space);
      expect(semanticsOf(t, _rowOf('Bo')), isSemantics(isSelected: true));
      await p.key(LogicalKeyboardKey.end);
      expect(focused(t, 'Ed'), isTrue);
      await p.tab();
      expect(p.focusIn(), isFalse, reason: 'one tab stop for the rows');
      await p.tab(back: true);
      await p.tab(back: true);
      await p.key(LogicalKeyboardKey.enter);
      expect(
        t.getSemantics(find.text('Age (ascending)')),
        isSemantics(label: 'Age', value: 'sorted ascending'),
        reason: 'Enter on a header sorts, and the sort is heard',
      );
    },
    rtl: (p) async {
      expect(
        p.tester.getCenter(find.text('Name')).dx,
        greaterThan(p.tester.getCenter(find.text('Age')).dx),
        reason: 'the first column is on the right',
      );
    },
    motion: (p) async {
      await p.tabInto();
      await p.key(LogicalKeyboardKey.arrowDown);
    },
  );

  test('a header sorts up, down, then not at all; equal rows keep their '
      'order', () {
    final c = _controller();
    c.sort('age');
    expect(_names(c.filteredRows), ['Di', 'Bo', 'Ada', 'Cy', 'Ed']);
    c.sort('age');
    expect(c.sortOf('age'), DesignSortDirection.descending);
    expect(_names(c.filteredRows), ['Ed', 'Ada', 'Cy', 'Bo', 'Di']);
    c.sort('age');
    expect(c.sortColumn, isNull);
    expect(_names(c.filteredRows), _names(_people));
    c.sort('note');
    expect(c.sortColumn, isNull, reason: 'a column with no key does not sort');
  });

  test('pages; a filter goes back to the first page; a new page size keeps '
      'the first row shown', () {
    final c = _controller(pageSize: 2);
    expect(c.pageCount, 3);
    c.goToPage(2);
    expect(_names(c.pageRows), ['Ed']);
    c.goToPage(9);
    expect(c.page, 2, reason: 'clamped');
    c.pageSize = 4;
    expect(c.page, 1);
    expect(_names(c.pageRows), ['Ed']);
    c.query = 'd';
    expect(c.page, 0);
    expect(_names(c.filteredRows), ['Ada', 'Di', 'Ed']);
    c.query = 'zzz';
    expect(c.pageCount, 1);
    expect(c.pageRows, isEmpty);
  });

  test('selection: a toggle, a Shift run, the page box, and rows that survive '
      'new data', () {
    final c = _controller(pageSize: 3);
    c.toggle(_people[0]);
    c.toggle(_people[2], extend: true);
    expect(_names(c.selectedRows), ['Ada', 'Bo', 'Cy']);
    expect(c.pageSelection, DesignSelection.all);
    c.togglePage();
    expect(c.selectedCount, 0);
    c.toggle(_people[1]);
    expect(c.pageSelection, DesignSelection.some);
    c.togglePage();
    expect(c.pageSelection, DesignSelection.all);
    c.rows = _people.where((p) => p.name != 'Cy').toList();
    expect(_names(c.selectedRows), ['Ada', 'Bo']);
    c.selectAll();
    expect(c.selectedCount, 4);
    c.clearSelection();
    expect(c.selectedRows, isEmpty);
  });

  testWidgets('one tab stop for the rows: arrows, Home and End move; Space '
      'selects, Shift with Space a run; Ctrl+A the page; Enter opens', (
    tester,
  ) async {
    final c = _controller();
    addTearDown(c.dispose);
    final opened = <String>[];
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
    addTearDown(
      () => FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.automatic,
    );
    await tester.pumpWidget(_table(c, onActivate: (p) => opened.add(p.name)));

    // Tab: the two sortable headers, then the rows' single stop.
    for (var i = 0; i < 3; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    }
    await tester.pump();
    expect(_rowStates['Ada'], contains(WidgetState.focused));
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(_rowStates['Cy'], contains(WidgetState.focused));
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.sendKeyEvent(LogicalKeyboardKey.end);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pump();
    expect(_names(c.selectedRows), ['Cy', 'Di', 'Ed']);
    expect(_rowStates['Ed'], contains(WidgetState.selected));
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(opened, ['Ed']);
    expect(c.selectedCount, 3, reason: 'Enter opens, it does not select');

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    expect(c.pageSelection, DesignSelection.all);

    await tester.sendKeyEvent(LogicalKeyboardKey.home);
    await tester.pump();
    expect(_rowStates['Ada'], contains(WidgetState.focused));
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(find.text('after: focused'), findsOneWidget, reason: 'one stop');
  });

  testWidgets('a header press sorts; a screen reader hears the sort; a row '
      'is selected for it too', (tester) async {
    final semantics = tester.ensureSemantics();
    final c = _controller();
    addTearDown(c.dispose);
    await tester.pumpWidget(_table(c));
    await tester.tap(find.text('Age'));
    await tester.pump();
    expect(find.text('Age (ascending)'), findsOneWidget);
    expect(c.sortColumn, 'age');
    expect(
      tester.getSemantics(find.text('Age (ascending)')),
      isSemantics(label: 'Age', value: 'sorted ascending', isButton: true),
    );

    await tester.tap(find.text('Bo'));
    await tester.pump();
    expect(c.isSelected(_people[1]), isTrue);
    expect(
      tester.getSemantics(find.text('Bo')),
      isSemantics(isSelected: true, isButton: true),
    );
    semantics.dispose();
  });

  testWidgets('a table that does not select opens a row on a press', (
    tester,
  ) async {
    final c = _controller();
    addTearDown(c.dispose);
    final opened = <String>[];
    await tester.pumpWidget(
      _table(c, selectable: false, onActivate: (p) => opened.add(p.name)),
    );
    await tester.tap(find.text('Di'));
    expect(opened, ['Di']);
    expect(c.selectedCount, 0);
  });

  testWidgets('right to left: the first column is on the right', (
    tester,
  ) async {
    final c = _controller();
    addTearDown(c.dispose);
    await tester.pumpWidget(
      harness(
        DesignDataTable<_Person>(
          controller: c,
          headerBuilder: (context, column, sort, states) => Text(column.label),
          cellBuilder: (context, row, column) => const SizedBox(),
          rowBuilder: (context, row, cells) => Row(children: cells),
        ),
        textDirection: TextDirection.rtl,
      ),
    );
    expect(
      tester.getCenter(find.text('Name')).dx,
      greaterThan(tester.getCenter(find.text('Age')).dx),
    );
  });
}
