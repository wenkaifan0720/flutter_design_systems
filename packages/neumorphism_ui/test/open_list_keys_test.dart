// An open list by the keys: opened from a key (Enter, Space, Down) its focus is on the
// chosen option, or the first with none chosen; the arrows move at once and wrap, Home and End go to the ends, a typed
// letter jumps, Enter chooses and closes, Escape closes and gives focus back to the field. The arrows work as well right
// after a pointer opened it. The combobox's, the tag input's and the menu bar's keys are ui_core's, held here in the
// look's own wrappers.
import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';
import 'package:neumorphism_ui/src/neumorphism/internal/panel.dart';

import 'support.dart';

const _countries = ['Austria', 'Belgium', 'Canada', 'Denmark'];

class _Select extends StatefulWidget {
  const _Select({required this.node, this.initial, required this.chosen});
  final FocusNode node;
  final String? initial;
  final List<String> chosen;
  @override
  State<_Select> createState() => _SelectState();
}

class _SelectState extends State<_Select> {
  late String? value = widget.initial;
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: SizedBox(
      width: 320,
      child: NeumorphicSelect<String>(
        labelText: 'Country',
        focusNode: widget.node,
        value: value,
        options: [for (final c in _countries) NeumorphicMenuItem(c, c)],
        onChanged: (v) {
          widget.chosen.add(v);
          setState(() => value = v);
        },
      ),
    ),
  );
}

/// The label of the menu row holding focus, or null with none.
String? _focusedRow(WidgetTester tester) {
  final focus = FocusManager.instance.primaryFocus;
  for (final tap in tester.widgetList<NeumorphicTap>(
    find.byType(NeumorphicTap),
  )) {
    if (tap.focusNode != null &&
        tap.focusNode == focus &&
        _countries.contains(tap.semanticLabel)) {
      return tap.semanticLabel;
    }
  }
  return null;
}

bool _listOpen() => find
    .byWidgetPredicate(
      (w) => w is NeumorphicTap && w.semanticLabel == 'Denmark',
    )
    .evaluate()
    .isNotEmpty;

Future<(FocusNode, List<String>)> _pump(
  WidgetTester tester, {
  String? initial = 'Belgium',
}) async {
  tester.view.physicalSize = const Size(1440, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final node = FocusNode();
  addTearDown(node.dispose);
  final chosen = <String>[];
  await tester.pumpWidget(
    neumorphicApp(
      _Select(node: node, initial: initial, chosen: chosen),
      width: 1440,
    ),
  );
  await tester.pumpAndSettle();
  node.requestFocus();
  await tester.pumpAndSettle();
  return (node, chosen);
}

Future<void> _press(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyEvent(key);
  await tester.pumpAndSettle();
}

void main() {
  for (final (name, key) in [
    ('Enter', LogicalKeyboardKey.enter),
    ('Space', LogicalKeyboardKey.space),
    ('Down', LogicalKeyboardKey.arrowDown),
  ]) {
    testWidgets('a select opened by $name: focus on the chosen option; Escape '
        'closes and gives focus back to the field', (tester) async {
      final (node, chosen) = await _pump(tester);
      await _press(tester, key);
      expect(_listOpen(), isTrue);
      expect(_focusedRow(tester), 'Belgium');
      await _press(tester, LogicalKeyboardKey.escape);
      expect(_listOpen(), isFalse);
      expect(node.hasPrimaryFocus, isTrue);
      expect(chosen, isEmpty);
    });
  }

  testWidgets('with nothing chosen, the list opens on the first option', (
    tester,
  ) async {
    await _pump(tester, initial: null);
    await _press(tester, LogicalKeyboardKey.arrowDown);
    expect(_focusedRow(tester), 'Austria');
  });

  testWidgets('the arrows move at once and wrap, Home and End go to the ends, '
      'a letter jumps, Enter chooses and closes', (tester) async {
    final (node, chosen) = await _pump(tester);
    await _press(tester, LogicalKeyboardKey.enter);
    await _press(tester, LogicalKeyboardKey.arrowDown);
    expect(_focusedRow(tester), 'Canada');
    await _press(tester, LogicalKeyboardKey.arrowDown);
    await _press(tester, LogicalKeyboardKey.arrowDown);
    expect(_focusedRow(tester), 'Austria', reason: 'Down wraps');
    await _press(tester, LogicalKeyboardKey.arrowUp);
    expect(_focusedRow(tester), 'Denmark', reason: 'Up wraps');
    await _press(tester, LogicalKeyboardKey.home);
    expect(_focusedRow(tester), 'Austria');
    await _press(tester, LogicalKeyboardKey.end);
    expect(_focusedRow(tester), 'Denmark');
    await tester.sendKeyEvent(LogicalKeyboardKey.keyC, character: 'c');
    await tester.pumpAndSettle();
    expect(_focusedRow(tester), 'Canada');
    await _press(tester, LogicalKeyboardKey.enter);
    expect(_listOpen(), isFalse);
    expect(chosen, ['Canada']);
    expect(node.hasPrimaryFocus, isTrue);
  });

  testWidgets('opened by a pointer, the arrows work at once', (tester) async {
    final (_, chosen) = await _pump(tester);
    await tester.tap(find.byType(NeumorphicSelect<String>));
    await tester.pumpAndSettle();
    expect(_listOpen(), isTrue);
    expect(_focusedRow(tester), 'Belgium');
    await _press(tester, LogicalKeyboardKey.arrowDown);
    expect(_focusedRow(tester), 'Canada');
    await _press(tester, LogicalKeyboardKey.enter);
    expect(chosen, ['Canada']);
  });

  // The pointer's row stands up and the keys' place lifts, so a pointer's move takes the keys' place: one place in the
  // list, as in a native menu, never a lifted row and a raised one at once.
  testWidgets('a select\'s pointer takes the keys\' place, and the keys go on '
      'from it', (tester) async {
    final (_, chosen) = await _pump(tester);
    await _press(tester, LogicalKeyboardKey.enter);
    await _press(tester, LogicalKeyboardKey.arrowDown);
    expect(_focusedRow(tester), 'Canada');
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: const Offset(1, 1));
    addTearDown(mouse.removePointer);
    await mouse.moveTo(
      tester.getCenter(
        find.byWidgetPredicate(
          (w) => w is NeumorphicTap && w.semanticLabel == 'Austria',
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(_focusedRow(tester), 'Austria');
    await _press(tester, LogicalKeyboardKey.arrowDown);
    expect(_focusedRow(tester), 'Belgium', reason: 'the keys go on from it');
    await mouse.moveTo(const Offset(1, 1));
    await tester.pumpAndSettle();
    expect(_focusedRow(tester), 'Belgium', reason: 'leaving moves nothing');
    await _press(tester, LogicalKeyboardKey.arrowDown);
    await _press(tester, LogicalKeyboardKey.enter);
    expect(chosen, ['Canada']);
  });

  // A combobox's and a tag input's lists are ui_core's (its own list keys, 10e2d9d2d2): the keys stay in the field
  // (Home, End and a letter edit the words), the list's place is its focused row, and the platform's submit action
  // (Enter in a text field) takes it.
  testWidgets(
    'a combobox: Down on the closed list only opens it, on the '
    'chosen option, every option listed; the arrows wrap; Escape closes, '
    'the field keeps focus; it reopens on its value; submit takes the place',
    (tester) async {
      final taken = await _combobox(tester);
      expect(_rows(), 0);
      await _press(tester, LogicalKeyboardKey.arrowDown);
      expect(_rows(), 4);
      expect(_place(tester), 'Belgium');
      await _press(tester, LogicalKeyboardKey.arrowDown);
      expect(_place(tester), 'Canada');
      await _press(tester, LogicalKeyboardKey.arrowDown);
      await _press(tester, LogicalKeyboardKey.arrowDown);
      expect(_place(tester), 'Austria', reason: 'Down wraps');
      await _press(tester, LogicalKeyboardKey.arrowUp);
      expect(_place(tester), 'Denmark', reason: 'Up wraps');
      await _press(tester, LogicalKeyboardKey.escape);
      expect(_rows(), 0);
      expect(_field(tester).focusNode.hasFocus, isTrue);
      await _press(tester, LogicalKeyboardKey.arrowDown);
      expect(_rows(), 4);
      expect(_place(tester), 'Belgium', reason: 'it reopens on its value');
      await _press(tester, LogicalKeyboardKey.arrowDown);
      await _submit(tester);
      expect(taken, ['Canada']);
      expect(_rows(), 0);
      await _press(tester, LogicalKeyboardKey.arrowUp);
      expect(_rows(), 4);
      expect(
        _place(tester),
        'Canada',
        reason: 'Up only opens, on the new value',
      );
    },
  );

  testWidgets('a combobox lists every option until its words are edited, then '
      'the ones they match', (tester) async {
    await _combobox(tester);
    await _press(tester, LogicalKeyboardKey.arrowDown);
    expect(_rows(), 4);
    await tester.enterText(find.byType(EditableText), 'an');
    await tester.pumpAndSettle();
    expect(_rows(), 1);
    expect(_place(tester), 'Canada');
  });

  testWidgets('a combobox passes over an option out of use, draws it out of '
      'use, and with none chosen opens on the first in use', (tester) async {
    final taken = await _combobox(
      tester,
      value: null,
      enabled: (c) => c != 'Austria' && c != 'Canada',
    );
    await _press(tester, LogicalKeyboardKey.arrowDown);
    expect(_place(tester), 'Belgium');
    expect(_out('Austria'), isTrue);
    expect(_out('Canada'), isTrue);
    expect(_out('Belgium'), isFalse);
    await _press(tester, LogicalKeyboardKey.arrowDown);
    expect(_place(tester), 'Denmark');
    await _press(tester, LogicalKeyboardKey.arrowDown);
    expect(_place(tester), 'Belgium', reason: 'round past Austria');
    await _press(tester, LogicalKeyboardKey.arrowUp);
    expect(_place(tester), 'Denmark');
    await _submit(tester);
    expect(taken, ['Denmark']);
  });

  // The pointer's row and the keys' place both stand up off the panel, so the look keeps them one place
  // (highlightFollowsPointer, ui_core fec8131445): two lifted rows would read as two current options.
  testWidgets('a combobox\'s pointer moves the keys\' place: one lifted row, '
      'the keys go on from it, it stays when the pointer leaves, and a row '
      'out of use never takes it', (tester) async {
    final taken = await _combobox(tester, enabled: (c) => c != 'Austria');
    await _press(tester, LogicalKeyboardKey.arrowDown);
    expect(_place(tester), 'Belgium');
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: const Offset(1, 1));
    addTearDown(mouse.removePointer);
    Future<void> over(String label) async {
      await mouse.moveTo(
        tester.getCenter(
          find.byWidgetPredicate(
            (w) => w is NeumorphicPanelRow && w.label == label,
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    await over('Denmark');
    expect(_place(tester), 'Denmark');
    expect(_hovered(), isEmpty, reason: 'one place, not a hover beside it');
    await _press(tester, LogicalKeyboardKey.arrowUp);
    expect(_place(tester), 'Canada', reason: 'the keys go on from it');
    await over('Austria');
    expect(_place(tester), 'Canada', reason: 'out of use, it takes nothing');
    await mouse.moveTo(const Offset(1, 1));
    await tester.pumpAndSettle();
    expect(_place(tester), 'Canada', reason: 'it stays as the pointer leaves');
    await _submit(tester);
    expect(taken, ['Canada']);
  });

  testWidgets('a tag input: Down opens its list on the first option; the '
      'arrows wrap and pass over one out of use; submit adds the place', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    var values = <String>[];
    await tester.pumpWidget(
      neumorphicApp(
        Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: 320,
            child: StatefulBuilder(
              builder: (context, setState) => NeumorphicMultiSelect<String>(
                labelText: 'Countries',
                values: values,
                options: _countries,
                isOptionEnabled: (c) => c != 'Belgium',
                onChanged: (v) => setState(() => values = v),
              ),
            ),
          ),
        ),
        width: 1440,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(EditableText));
    await tester.pumpAndSettle();
    if (_rows() > 0) await _press(tester, LogicalKeyboardKey.escape);
    expect(_rows(), 0);
    await _press(tester, LogicalKeyboardKey.arrowDown);
    expect(_rows(), 4);
    expect(_place(tester), 'Austria');
    expect(_out('Belgium'), isTrue);
    await _press(tester, LogicalKeyboardKey.arrowDown);
    expect(_place(tester), 'Canada', reason: 'past Belgium');
    await _press(tester, LogicalKeyboardKey.arrowUp);
    await _press(tester, LogicalKeyboardKey.arrowUp);
    expect(_place(tester), 'Denmark', reason: 'Up wraps');
    await _submit(tester);
    expect(values, ['Denmark']);
  });

  testWidgets('a menu bar\'s menu takes typed letters: the next item a letter '
      'starts, round past the end', (tester) async {
    final previous = FocusManager.instance.highlightStrategy;
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
    addTearDown(() => FocusManager.instance.highlightStrategy = previous);
    await tester.pumpWidget(
      neumorphicApp(
        Align(
          alignment: Alignment.topLeft,
          child: NeumorphicMenuBar(
            menus: [
              RawMenuEntry(
                label: 'File',
                children: [
                  for (final item in ['New', 'Open', 'Print', 'Quit'])
                    RawMenuEntry(label: item, onPressed: () {}),
                ],
              ),
            ],
          ),
        ),
        width: 1440,
      ),
    );
    await tester.pumpAndSettle();
    await _press(tester, LogicalKeyboardKey.tab);
    await _press(tester, LogicalKeyboardKey.arrowDown);
    expect(_place(tester, among: null), 'New');
    await _press(tester, LogicalKeyboardKey.keyQ);
    expect(_place(tester, among: null), 'Quit');
    await tester.pump(const Duration(seconds: 1));
    await _press(tester, LogicalKeyboardKey.keyN);
    expect(_place(tester, among: null), 'New', reason: 'round past the end');
    await tester.pump(const Duration(seconds: 1));
    await _press(tester, LogicalKeyboardKey.keyP);
    expect(_place(tester, among: null), 'Print');
  });
}

int _rows() => find.byType(NeumorphicPanelRow).evaluate().length;

List<String?> _hovered() => [
  for (final row
      in find
          .byType(NeumorphicPanelRow)
          .evaluate()
          .map((e) => e.widget as NeumorphicPanelRow))
    if (row.states.contains(WidgetState.hovered)) row.label,
];

/// The label of the list row holding the keys' place ([among] the countries, unless null), or null with none.
String? _place(WidgetTester tester, {List<String>? among = _countries}) {
  for (final row in tester.widgetList<NeumorphicPanelRow>(
    find.byType(NeumorphicPanelRow),
  )) {
    if (row.states.contains(WidgetState.focused) &&
        (among == null || among.contains(row.label))) {
      return row.label;
    }
  }
  return null;
}

bool _out(String label) => find
    .byWidgetPredicate(
      (w) =>
          w is NeumorphicPanelRow &&
          w.label == label &&
          w.states.contains(WidgetState.disabled),
    )
    .evaluate()
    .isNotEmpty;

EditableText _field(WidgetTester tester) =>
    tester.widget<EditableText>(find.byType(EditableText));

Future<void> _submit(WidgetTester tester) async {
  await tester.testTextInput.receiveAction(TextInputAction.done);
  await tester.pumpAndSettle();
}

/// A combobox of the countries holding [value], focused with its list closed; what it takes is in the list returned.
Future<List<String>> _combobox(
  WidgetTester tester, {
  String? value = 'Belgium',
  bool Function(String option)? enabled,
}) async {
  tester.view.physicalSize = const Size(1440, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final taken = <String>[];
  await tester.pumpWidget(
    neumorphicApp(
      Align(
        alignment: Alignment.topCenter,
        child: SizedBox(
          width: 320,
          child: StatefulBuilder(
            builder: (context, setState) => NeumorphicCombobox<String>(
              labelText: 'Country',
              options: _countries,
              isOptionEnabled: enabled,
              value: taken.isEmpty ? value : taken.last,
              onSelected: (v) => setState(() => taken.add(v)),
            ),
          ),
        ),
      ),
      width: 1440,
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.byType(EditableText));
  await tester.pumpAndSettle();
  if (_rows() > 0) await _press(tester, LogicalKeyboardKey.escape);
  return taken;
}
