// The keys of the lists Ledger's combobox and tag field open, ui_core's own since its final 0.2.0 (10e2d9d2d2,
// msg_2ec6da32e619), held in Ledger's wrappers: a press opens every option, the combobox's on its value; Up and Down
// go round the ends; on a closed list they only open it, where it stood; Home and End are the words'; edited words
// filter; an empty field's Down opens every option at the first; Enter takes the lit one and closes the list (chosen
// here as the platform's text input does, with its done action). Neither wrapper offers a disabled option, so
// ui_core's passing over one has nothing of Ledger's to hold.
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledger_ui/ledger_ui.dart';
import 'package:ledger_ui/ledger_host.dart';
import 'package:ledger_ui/src/ledger/internal/option_paper.dart';

const _payees = [
  'Corner Market',
  'Cedar Books',
  'Blue Fern Café',
  'City Water',
];
const _people = ['Maren', 'Theo', 'Ana', 'Jun'];

/// The payee the combobox took last, and the people the tag field holds.
String? _taken;
List<String> _split = const [];

class _Payee extends StatefulWidget {
  const _Payee(this.initial);

  final String? initial;

  @override
  State<_Payee> createState() => _PayeeState();
}

class _PayeeState extends State<_Payee> {
  late String? _value = widget.initial;

  @override
  Widget build(BuildContext context) => LedgerCombobox<String>(
    label: 'Payee',
    options: _payees,
    value: _value,
    onSelected: (v) => setState(() => _value = _taken = v),
  );
}

class _Split extends StatefulWidget {
  const _Split();

  @override
  State<_Split> createState() => _SplitState();
}

class _SplitState extends State<_Split> {
  @override
  Widget build(BuildContext context) => LedgerMultiSelect<String>(
    label: 'Split with',
    values: _split,
    options: _people,
    onChanged: (v) => setState(() => _split = v),
  );
}

Future<void> _pump(WidgetTester t, Widget field) async {
  await t.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: (context, page) =>
          LedgerHost(brightness: Brightness.light, child: page!),
      home: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: field,
      ),
    ),
  );
  await t.pumpAndSettle();
}

Future<void> _key(WidgetTester t, LogicalKeyboardKey key) async {
  await t.sendKeyEvent(key);
  await t.pumpAndSettle();
}

Future<void> _done(WidgetTester t) async {
  await t.testTextInput.receiveAction(TextInputAction.done);
  await t.pumpAndSettle();
}

Finder get _entry => find.byType(EditableText).first;

/// The options the open list shows, in order.
List<String> _listed(WidgetTester t) => [
  for (final row in t.widgetList<LedgerOptionRow>(find.byType(LedgerOptionRow)))
    row.label,
];

/// The one option lit (the keyboard's, its words under the double rule), or null.
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
  setUp(() {
    _taken = null;
    _split = const ['Maren'];
  });

  testWidgets('a combobox: a press opens every option on its value; the '
      'arrows go round; Enter takes and closes; on a closed list Down and Up '
      'only open it; Home and End are the words\'; edited words filter', (
    t,
  ) async {
    await _pump(t, const _Payee('Cedar Books'));
    await t.tap(_entry);
    await t.pumpAndSettle();
    expect(_listed(t), _payees, reason: 'a press lists every option');
    expect(_lit(t), 'Cedar Books', reason: 'lit on its value');

    final moves = <String?>[];
    for (final k in [
      LogicalKeyboardKey.arrowDown,
      LogicalKeyboardKey.arrowDown,
      LogicalKeyboardKey.arrowDown,
      LogicalKeyboardKey.arrowUp,
    ]) {
      await _key(t, k);
      moves.add(_lit(t));
    }
    expect(moves, [
      'Blue Fern Café',
      'City Water',
      'Corner Market',
      'City Water',
    ], reason: 'Down past the last and Up past the first go round');

    await _key(t, LogicalKeyboardKey.arrowUp);
    expect(_lit(t), 'Blue Fern Café');
    await _done(t);
    expect(_taken, 'Blue Fern Café');
    expect(_listed(t), isEmpty, reason: 'taking one closes the list');

    await _key(t, LogicalKeyboardKey.arrowDown);
    expect(_listed(t), _payees, reason: 'Down reopens it on every option');
    expect(_lit(t), 'Blue Fern Café', reason: 'and only opens it');
    await _key(t, LogicalKeyboardKey.escape);
    expect(_listed(t), isEmpty);
    await _key(t, LogicalKeyboardKey.arrowUp);
    expect(_lit(t), 'Blue Fern Café', reason: 'Up only opens it too');

    await _key(t, LogicalKeyboardKey.home);
    expect(_lit(t), 'Blue Fern Café', reason: 'Home is the words\'');
    await _key(t, LogicalKeyboardKey.end);
    expect(_lit(t), 'Blue Fern Café', reason: 'End is the words\'');

    await t.enterText(_entry, 'Ci');
    await t.pumpAndSettle();
    expect(_listed(t), ['City Water'], reason: 'edited words filter');
    expect(_lit(t), 'City Water');
    await _done(t);
    expect(_taken, 'City Water');
  });

  testWidgets('a combobox with none taken: Down opens every option at the '
      'first', (t) async {
    await _pump(t, const _Payee(null));
    await t.tap(_entry);
    await t.pumpAndSettle();
    await _key(t, LogicalKeyboardKey.escape);
    expect(_listed(t), isEmpty);
    await _key(t, LogicalKeyboardKey.arrowDown);
    expect(_listed(t), _payees);
    expect(_lit(t), 'Corner Market');
  });

  testWidgets('a tag field: a press opens every person not yet on it; the '
      'arrows go round; on a closed list Down only opens it, at the first; '
      'Enter takes the lit one; edited words filter', (t) async {
    await _pump(t, const _Split());
    await t.tap(_entry);
    await t.pumpAndSettle();
    expect(_listed(t), ['Theo', 'Ana', 'Jun'], reason: 'Maren is a tag');
    expect(_lit(t), 'Theo');

    final moves = <String?>[];
    for (final k in [
      LogicalKeyboardKey.arrowUp,
      LogicalKeyboardKey.arrowDown,
      LogicalKeyboardKey.arrowDown,
    ]) {
      await _key(t, k);
      moves.add(_lit(t));
    }
    expect(moves, ['Jun', 'Theo', 'Ana'], reason: 'round both ends');

    await _key(t, LogicalKeyboardKey.escape);
    expect(_listed(t), isEmpty);
    await _key(t, LogicalKeyboardKey.arrowDown);
    expect(_listed(t), ['Theo', 'Ana', 'Jun']);
    expect(_lit(t), 'Theo', reason: 'Down only opens it, at the first');
    await _done(t);
    expect(_split, ['Maren', 'Theo']);

    await t.enterText(_entry, 'j');
    await t.pumpAndSettle();
    expect(_listed(t), ['Jun'], reason: 'edited words filter');
    expect(_lit(t), 'Jun');
    await _done(t);
    expect(_split, ['Maren', 'Theo', 'Jun']);
  });
}
