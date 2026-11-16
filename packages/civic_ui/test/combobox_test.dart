// A combobox's keys, through Civic's own CivicCombobox (ui_core's list keys):
// a list opened before the words are edited (by a press, or Down or Up on a
// closed list) shows every answer, the one chosen lit; Down or Up on a closed
// list only opens it; Up and Down walk the list round its ends; once the words
// are edited the list shows those they match, the first lit; the return key
// takes the lit answer and closes the list; Escape closes it; Home and End stay
// with the words. A test takes an answer as a phone's keyboard does,
// receiveAction(TextInputAction.done), not an Enter key event.
// ignore_for_file: avoid_relative_lib_imports
import 'package:civic_ui/civic_ui.dart';
import 'package:civic_ui/src/civic/internal/list_option.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../example/lib/kit_gallery/kit.dart';

const _streets = [
  'Abbey Road',
  'Bridge Street',
  'Castle Hill',
  'Dock Lane',
  'Elm Row',
];

/// A combobox of [_streets] holding [value]; returns the answers taken.
Future<List<String>> _combobox(WidgetTester tester, {String? value}) async {
  tester.view.physicalSize = const Size(1440, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final taken = <String>[];
  var shown = value;
  await tester.pumpWidget(
    kitApp(
      brightness: Brightness.light,
      home: Padding(
        padding: const EdgeInsets.all(CivicSpacing.s20),
        child: Align(
          alignment: AlignmentDirectional.topStart,
          child: SizedBox(
            width: 400,
            child: StatefulBuilder(
              builder: (context, setState) => CivicCombobox<String>(
                labelText: 'Street',
                options: _streets,
                value: shown,
                onSelected: (street) => setState(() {
                  taken.add(street);
                  shown = street;
                }),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return taken;
}

Iterable<CivicListOption> _rows() => find
    .byType(CivicListOption)
    .evaluate()
    .map((e) => e.widget as CivicListOption);

/// The answers the open list shows, in order; empty while it is closed.
List<String> _listed() => [for (final row in _rows()) row.label];

/// The one answer lit (the keys' place), null unless exactly one is.
String? _lit() {
  final lit = _rows().where((row) => row.focused).toList();
  return lit.length == 1 ? lit.single.label : null;
}

/// The one answer marked chosen, null unless exactly one is.
String? _chosen() {
  final chosen = _rows().where((row) => row.chosen).toList();
  return chosen.length == 1 ? chosen.single.label : null;
}

Future<void> _press(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyEvent(key);
  await tester.pumpAndSettle();
}

Future<void> _take(WidgetTester tester) async {
  await tester.testTextInput.receiveAction(TextInputAction.done);
  await tester.pumpAndSettle();
}

String _words(WidgetTester tester) =>
    tester.widget<EditableText>(find.byType(EditableText)).controller.text;

void main() {
  testWidgets('a press opens every answer, the one chosen lit and marked', (
    tester,
  ) async {
    await _combobox(tester, value: 'Castle Hill');
    await tester.tap(find.byType(EditableText));
    await tester.pumpAndSettle();
    expect(_listed(), _streets);
    expect(_lit(), 'Castle Hill');
    expect(_chosen(), 'Castle Hill');
  });

  testWidgets('Up and Down walk the list round its ends', (tester) async {
    await _combobox(tester, value: 'Elm Row');
    await tester.tap(find.byType(EditableText));
    await tester.pumpAndSettle();
    expect(_lit(), 'Elm Row');
    await _press(tester, LogicalKeyboardKey.arrowDown);
    expect(_lit(), 'Abbey Road', reason: 'Down at the last goes round');
    await _press(tester, LogicalKeyboardKey.arrowUp);
    expect(_lit(), 'Elm Row', reason: 'Up at the first goes round');
    await _press(tester, LogicalKeyboardKey.arrowUp);
    expect(_lit(), 'Dock Lane');
    expect(_chosen(), 'Elm Row', reason: 'walking chooses nothing');
  });

  testWidgets('the return key takes the lit answer and closes the list; '
      'Down or Up on the closed list only opens it, on that answer', (
    tester,
  ) async {
    final taken = await _combobox(tester, value: 'Bridge Street');
    await tester.tap(find.byType(EditableText));
    await tester.pumpAndSettle();
    await _press(tester, LogicalKeyboardKey.arrowDown);
    expect(_lit(), 'Castle Hill');
    await _take(tester);
    expect(taken, ['Castle Hill']);
    expect(_listed(), isEmpty, reason: 'taking one closes the list');
    expect(_words(tester), 'Castle Hill');

    await _press(tester, LogicalKeyboardKey.arrowDown);
    expect(_listed(), _streets, reason: 'Down reopens every answer');
    expect(_lit(), 'Castle Hill', reason: 'and only opens it');
    expect(_chosen(), 'Castle Hill');
    await _press(tester, LogicalKeyboardKey.escape);
    expect(_listed(), isEmpty);
    expect(taken, ['Castle Hill'], reason: 'Escape takes nothing');
    await _press(tester, LogicalKeyboardKey.arrowUp);
    expect(_listed(), _streets);
    expect(_lit(), 'Castle Hill', reason: 'Up only opens it too');
  });

  testWidgets('with none chosen, Down opens every answer at the first', (
    tester,
  ) async {
    await _combobox(tester);
    await tester.tap(find.byType(EditableText));
    await tester.pumpAndSettle();
    await _press(tester, LogicalKeyboardKey.escape);
    expect(_listed(), isEmpty);
    await _press(tester, LogicalKeyboardKey.arrowDown);
    expect(_listed(), _streets);
    expect(_lit(), 'Abbey Road');
    expect(_chosen(), isNull);
  });

  testWidgets('every answer shows until the words are edited, then those '
      'they match, the first lit', (tester) async {
    final taken = await _combobox(tester, value: 'Abbey Road');
    await tester.tap(find.byType(EditableText));
    await tester.pumpAndSettle();
    expect(
      _listed(),
      _streets,
      reason: "the chosen answer's words filter nothing",
    );
    await tester.enterText(find.byType(EditableText), 'l');
    await tester.pumpAndSettle();
    expect(_listed(), ['Castle Hill', 'Dock Lane', 'Elm Row']);
    expect(_lit(), 'Castle Hill');
    await _press(tester, LogicalKeyboardKey.arrowUp);
    expect(_lit(), 'Elm Row', reason: 'the matches go round too');
    await _take(tester);
    expect(taken, ['Elm Row']);
    expect(_words(tester), 'Elm Row');
  });

  testWidgets('Home and End move in the words and leave the list be', (
    tester,
  ) async {
    await _combobox(tester, value: 'Dock Lane');
    await tester.tap(find.byType(EditableText));
    await tester.pumpAndSettle();
    TextSelection selection() => tester
        .widget<EditableText>(find.byType(EditableText))
        .controller
        .selection;
    await _press(tester, LogicalKeyboardKey.home);
    expect((selection().baseOffset, selection().extentOffset), (0, 0));
    expect(_lit(), 'Dock Lane');
    await _press(tester, LogicalKeyboardKey.end);
    expect((selection().baseOffset, selection().extentOffset), (9, 9));
    expect(_lit(), 'Dock Lane');
  });
}
