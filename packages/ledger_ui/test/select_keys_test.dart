// A select's list from the keyboard: Enter, Space or Down opens it
// with the keyboard on the chosen option, or the first while none is chosen; the arrows move at once, round from the
// last to the first, Home and End go to its ends, a typed letter to the next option it starts; Enter chooses and
// closes, Escape closes, and either way the keyboard is back on the field. The arrows work as soon as a pointer has
// opened it too.
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledger_ui/ledger_ui.dart';

const _options = [
  LedgerSelectItem(value: 'USD', label: 'US dollar'),
  LedgerSelectItem(value: 'EUR', label: 'Euro'),
  LedgerSelectItem(value: 'GBP', label: 'Pound sterling'),
  LedgerSelectItem(value: 'JPY', label: 'Japanese yen'),
];

/// What the select chose last.
String? _chose;

Future<void> _pump(WidgetTester t, {String? value = 'EUR'}) async {
  _chose = null;
  await t.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: (context, page) =>
          LedgerHost(brightness: Brightness.light, child: page!),
      home: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: LedgerSelect<String>(
          labelText: 'Currency',
          value: value,
          items: _options,
          onChanged: (v) => _chose = v,
        ),
      ),
    ),
  );
  await t.pumpAndSettle();
}

Future<void> _key(WidgetTester t, LogicalKeyboardKey key) async {
  await t.sendKeyEvent(key);
  await t.pumpAndSettle();
}

bool _open(WidgetTester t) => find.text('Japanese yen').evaluate().isNotEmpty;

/// The option holding the keyboard, by its words.
String? _onOption(WidgetTester t) {
  for (final o in _options) {
    final f = find.text(o.label);
    if (f.evaluate().isEmpty) continue;
    if (Focus.of(t.element(f.last)).hasPrimaryFocus) return o.label;
  }
  return null;
}

/// Whether the field (its face, showing [words]) holds the keyboard.
bool _onField(WidgetTester t, String words) =>
    Focus.of(t.element(find.text(words).first)).hasPrimaryFocus;

void main() {
  for (final key in [
    LogicalKeyboardKey.enter,
    LogicalKeyboardKey.space,
    LogicalKeyboardKey.arrowDown,
  ]) {
    testWidgets('${key.keyLabel} opens it on the chosen option', (t) async {
      await _pump(t);
      await _key(t, LogicalKeyboardKey.tab);
      await _key(t, key);
      expect(_open(t), isTrue);
      expect(_onOption(t), 'Euro');
    });
  }

  testWidgets('with none chosen, it opens on the first option', (t) async {
    await _pump(t, value: null);
    await _key(t, LogicalKeyboardKey.tab);
    await _key(t, LogicalKeyboardKey.arrowDown);
    expect(_open(t), isTrue);
    expect(_onOption(t), 'US dollar');
  });

  testWidgets('the arrows move at once and round the ends; Home, End and a '
      'letter go where they say', (t) async {
    await _pump(t);
    await _key(t, LogicalKeyboardKey.tab);
    await _key(t, LogicalKeyboardKey.enter);
    final moves = <String?>[];
    for (final k in [
      LogicalKeyboardKey.arrowDown,
      LogicalKeyboardKey.arrowDown,
      LogicalKeyboardKey.arrowDown,
      LogicalKeyboardKey.arrowUp,
      LogicalKeyboardKey.home,
      LogicalKeyboardKey.end,
      LogicalKeyboardKey.keyP,
      LogicalKeyboardKey.keyE,
      LogicalKeyboardKey.keyU,
    ]) {
      await _key(t, k);
      moves.add(_onOption(t));
    }
    expect(moves, [
      'Pound sterling',
      'Japanese yen',
      'US dollar',
      'Japanese yen',
      'US dollar',
      'Japanese yen',
      'Pound sterling',
      'Euro',
      'US dollar',
    ]);
    expect(_open(t), isTrue);
  });

  testWidgets('Enter chooses and closes; Escape closes; the keyboard is back '
      'on the field', (t) async {
    await _pump(t);
    await _key(t, LogicalKeyboardKey.tab);
    await _key(t, LogicalKeyboardKey.enter);
    await _key(t, LogicalKeyboardKey.arrowDown);
    await _key(t, LogicalKeyboardKey.enter);
    expect(_chose, 'GBP');
    expect(_open(t), isFalse);
    expect(_onField(t, 'Euro'), isTrue);
    await _key(t, LogicalKeyboardKey.enter);
    expect(_open(t), isTrue);
    await _key(t, LogicalKeyboardKey.escape);
    expect(_open(t), isFalse);
    expect(_onField(t, 'Euro'), isTrue);
  });

  testWidgets('the arrows move as soon as a pointer has opened it', (t) async {
    await _pump(t);
    await t.tap(
      find
          .descendant(
            of: find.byType(LedgerSelect<String>),
            matching: find.byType(LedgerPressable),
          )
          .first,
    );
    await t.pumpAndSettle();
    expect(_open(t), isTrue);
    await _key(t, LogicalKeyboardKey.arrowDown);
    expect(_onOption(t), 'Pound sterling');
  });
}
