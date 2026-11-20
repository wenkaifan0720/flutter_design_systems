// A long list: a select's, a combobox's and a tag field's list opens with its value
// in view though it stands near the end, and wherever the keyboard goes (an arrow round the ends, Home, End, a
// letter) its option is scrolled into view.
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledger_ui/ledger_ui.dart';
import 'package:ledger_ui/ledger_host.dart';
import 'package:ledger_ui/src/ledger/internal/option_paper.dart';

const _names = [
  'Allowance',
  'Bakery',
  'Books',
  'Car',
  'Charity',
  'Childcare',
  'Clothing',
  'Coffee',
  'Dining out', //
  'Electricity',
  'Fitness',
  'Fuel',
  'Garden',
  'Gifts',
  'Groceries',
  'Health',
  'Holidays',
  'Household', //
  'Insurance',
  'Internet',
  'Music',
  'Parking',
  'Pets',
  'Pharmacy',
  'Phone',
  'Rent',
  'Repairs',
  'Savings', //
  'Subscriptions', 'Taxes', 'Transport', 'Travel', 'Utilities', 'Water',
];

Future<void> _pump(WidgetTester t, Widget field) async {
  t.view.physicalSize = const Size(390, 844);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: (context, page) =>
          LedgerHost(brightness: Brightness.light, child: page!),
      home: Align(
        alignment: Alignment.topCenter,
        child: Padding(padding: const EdgeInsets.all(24), child: field),
      ),
    ),
  );
  await t.pumpAndSettle();
}

Future<void> _key(WidgetTester t, LogicalKeyboardKey key) async {
  await t.sendKeyEvent(key);
  await t.pumpAndSettle();
}

/// [row] stands whole inside the list's view.
void _inView(WidgetTester t, Finder row, String words) {
  final view = t.getRect(
    find.ancestor(of: row, matching: find.byType(Scrollable)).first,
  );
  final r = t.getRect(row);
  expect(
    r.top >= view.top - 0.5 && r.bottom <= view.bottom + 0.5,
    isTrue,
    reason: '$words stands in the list\'s view ($r in $view)',
  );
}

// The select: the option that holds the keyboard, and its row.
Finder _selectRow(String words) => find.text(words).last;
String? _onOption(WidgetTester t) {
  for (final n in _names) {
    final f = find.text(n);
    if (f.evaluate().isEmpty) continue;
    if (Focus.of(t.element(f.last)).hasPrimaryFocus) return n;
  }
  return null;
}

// A combobox's or a tag field's list: the lit option, and its row.
Finder _row(String words) =>
    find.byWidgetPredicate((w) => w is LedgerOptionRow && w.label == words);
String? _lit(WidgetTester t) {
  final lit = [
    for (final row in t.widgetList<LedgerOptionRow>(
      find.byType(LedgerOptionRow),
    ))
      if (row.states.contains(WidgetState.focused)) row.label,
  ];
  return lit.length == 1 ? lit.single : null;
}

void main() {
  testWidgets('a select opens on its value near the end, in view; Home, End, a letter and the arrows round the ends '
      'keep the keyboard\'s option in view', (t) async {
    await _pump(
      t,
      LedgerSelect<String>(
        label: 'Category',
        value: 'Transport',
        items: [for (final n in _names) LedgerSelectItem(value: n, label: n)],
        onChanged: (_) {},
      ),
    );
    await t.tap(
      find
          .descendant(
            of: find.byType(LedgerSelect<String>),
            matching: find.byType(LedgerPressable),
          )
          .first,
    );
    await t.pumpAndSettle();
    expect(_onOption(t), 'Transport');
    _inView(t, _selectRow('Transport'), 'the chosen Transport');
    final moves = <(LogicalKeyboardKey, String)>[
      (LogicalKeyboardKey.home, 'Allowance'),
      (LogicalKeyboardKey.end, 'Water'),
      (LogicalKeyboardKey.arrowDown, 'Allowance'),
      (LogicalKeyboardKey.arrowUp, 'Water'),
      (LogicalKeyboardKey.keyH, 'Health'),
      (LogicalKeyboardKey.keyS, 'Savings'),
    ];
    for (final (key, to) in moves) {
      await _key(t, key);
      expect(_onOption(t), to, reason: '${key.keyLabel} goes to $to');
      _inView(t, _selectRow(to), to);
    }
  });

  testWidgets('a combobox opens lit on its value near the end, in view; the arrows round the ends keep the lit '
      'option in view', (t) async {
    await _pump(
      t,
      LedgerCombobox<String>(
        label: 'Category',
        value: 'Transport',
        options: _names,
        onSelected: (_) {},
      ),
    );
    await t.tap(find.byType(EditableText).first);
    await t.pumpAndSettle();
    expect(_lit(t), 'Transport');
    _inView(t, _row('Transport'), 'the chosen Transport');
    for (final (key, to) in const [
      (LogicalKeyboardKey.arrowDown, 'Travel'),
      (LogicalKeyboardKey.arrowDown, 'Utilities'),
      (LogicalKeyboardKey.arrowDown, 'Water'),
      (LogicalKeyboardKey.arrowDown, 'Allowance'),
      (LogicalKeyboardKey.arrowUp, 'Water'),
    ]) {
      await _key(t, key);
      expect(_lit(t), to);
      _inView(t, _row(to), to);
    }
  });

  testWidgets(
    'a tag field\'s arrows round the ends keep the lit option in view',
    (t) async {
      await _pump(
        t,
        LedgerMultiSelect<String>(
          label: 'Categories',
          values: const ['Groceries'],
          options: _names,
          onChanged: (_) {},
        ),
      );
      await t.tap(find.byType(EditableText).first);
      await t.pumpAndSettle();
      expect(_lit(t), 'Allowance');
      _inView(t, _row('Allowance'), 'Allowance');
      for (final (key, to) in const [
        (LogicalKeyboardKey.arrowUp, 'Water'),
        (LogicalKeyboardKey.arrowUp, 'Utilities'),
        (LogicalKeyboardKey.arrowDown, 'Water'),
        (LogicalKeyboardKey.arrowDown, 'Allowance'),
      ]) {
        await _key(t, key);
        expect(_lit(t), to);
        _inView(t, _row(to), to);
      }
    },
  );
}
