// The return key in a field, as a browser needs it
// (packs/_coord/specs/web-enter-keeps-typing.md): a field that keeps the
// focus after the return key (Civic's: the combobox's) takes it in
// onEditingComplete with no onSubmitted, so Flutter never restarts its text
// input (in a browser the restarted input takes no typing: the field looks
// focused, and letters and Backspace go nowhere); a field that gives up the
// focus (the search field, a plain text field) keeps onSubmitted, loses the
// focus, and is not restarted either. Civic has no tag input, multi-select
// or command palette (several answers are checkboxes).
// ignore_for_file: avoid_relative_lib_imports
import 'package:civic_ui/civic_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import '../example/lib/kit_gallery/kit.dart';

const _streets = [
  'Abbey Road',
  'Bridge Street',
  'Castle Hill',
  'Dock Lane',
  'Elm Row',
];

Future<void> _pump(WidgetTester tester, Widget field) async {
  tester.view.physicalSize = const Size(1440, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    kitApp(
      brightness: Brightness.light,
      home: Padding(
        padding: const EdgeInsets.all(CivicSpacing.s20),
        child: Align(
          alignment: AlignmentDirectional.topStart,
          child: SizedBox(width: 400, child: field),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

EditableText _field(WidgetTester tester) =>
    tester.widget<EditableText>(find.byType(EditableText));

/// The text input calls since the log was last cleared.
List<String> _calls(WidgetTester tester) => [
  for (final call in tester.testTextInput.log) call.method,
];

/// The field kept its text input through the return key: neither closed
/// nor attached again.
void _keptItsInput(WidgetTester tester) => expect(
  _calls(tester),
  isNot(
    anyOf(contains('TextInput.clearClient'), contains('TextInput.setClient')),
  ),
  reason: "the field's text input was restarted",
);

void main() {
  testWidgets('the return key in a combobox takes the lit answer; the field '
      'keeps the focus and its text input, and typing edits it again', (
    tester,
  ) async {
    final taken = <String>[];
    await _pump(
      tester,
      StatefulBuilder(
        builder: (context, setState) => CivicCombobox<String>(
          labelText: 'Street',
          options: _streets,
          value: taken.lastOrNull,
          onSelected: (street) => setState(() => taken.add(street)),
        ),
      ),
    );
    await tester.showKeyboard(find.byType(EditableText));
    await tester.enterText(find.byType(EditableText), 'Ca');
    await tester.pumpAndSettle();
    tester.testTextInput.log.clear();
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(taken, ['Castle Hill']);
    expect(_field(tester).controller.text, 'Castle Hill');
    expect(
      _field(tester).focusNode.hasFocus,
      isTrue,
      reason: 'the field keeps the focus',
    );
    _keptItsInput(tester);

    // Typing again reaches the field through the same input (the test
    // input refuses typing with no field attached).
    tester.testTextInput.enterText('Do');
    await tester.pumpAndSettle();
    expect(_field(tester).controller.text, 'Do');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(taken, ['Castle Hill', 'Dock Lane']);
    expect(_field(tester).focusNode.hasFocus, isTrue);
    _keptItsInput(tester);
  });

  testWidgets('the search key in a search field searches and gives up the '
      'focus; its text input is closed, not restarted', (tester) async {
    final searched = <String>[];
    await _pump(
      tester,
      CivicSearchField(
        labelText: 'Search for a street',
        onSubmitted: searched.add,
      ),
    );
    await tester.showKeyboard(find.byType(EditableText));
    await tester.enterText(find.byType(EditableText), 'Rope');
    await tester.pumpAndSettle();
    tester.testTextInput.log.clear();
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    expect(searched, ['Rope']);
    expect(_field(tester).focusNode.hasFocus, isFalse);
    expect(
      _calls(tester),
      isNot(contains('TextInput.setClient')),
      reason: "the field's text input was restarted",
    );
  });

  testWidgets('the return key in a text field told of it submits and gives '
      'up the focus; its text input is not restarted', (tester) async {
    final sent = <String>[];
    await _pump(
      tester,
      CivicTextField(labelText: 'Registration', onSubmitted: sent.add),
    );
    await tester.showKeyboard(find.byType(EditableText));
    await tester.enterText(find.byType(EditableText), 'BR51 KTE');
    await tester.pumpAndSettle();
    tester.testTextInput.log.clear();
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(sent, ['BR51 KTE']);
    expect(_field(tester).focusNode.hasFocus, isFalse);
    expect(_calls(tester), isNot(contains('TextInput.setClient')));
  });
}
