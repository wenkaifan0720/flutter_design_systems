// Enter in a field that keeps the keyboard (the combobox's field, the tag
// input's, the command palette's search) leaves it able to type: the field
// keeps the focus and its text input. Flutter restarts the text input of a
// field that has onSubmitted and keeps its focus through the done action, and
// a browser's restarted input takes no typing (the field looks focused, the
// letters go nowhere); so these fields take Enter in onEditingComplete alone.
import 'package:material_ui/material_ui.dart' show MaterialApp;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studio_ui/studio_ui.dart';

Widget _app(Widget child) => MaterialApp(
  home: StudioTheme(
    data: StudioThemeData.light(),
    child: Builder(
      builder: (context) => ColoredBox(
        color: StudioTheme.of(context).colors.chassis,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(width: 360, child: child),
          ),
        ),
      ),
    ),
  ),
);

EditableText _field(WidgetTester tester) =>
    tester.widget<EditableText>(find.byType(EditableText));

// Enter (the done action) after [typed].
Future<void> _enter(WidgetTester tester, String typed) async {
  await tester.showKeyboard(find.byType(EditableText));
  await tester.enterText(find.byType(EditableText), typed);
  await tester.pumpAndSettle();
  tester.testTextInput.log.clear();
  await tester.testTextInput.receiveAction(TextInputAction.done);
  await tester.pumpAndSettle();
}

// The field still has the focus, and its text input was neither closed nor
// opened again.
void _keptTheKeyboard(WidgetTester tester) {
  expect(
    _field(tester).focusNode.hasFocus,
    isTrue,
    reason: 'Enter took the focus from the field',
  );
  expect(
    tester.testTextInput.log.map((call) => call.method),
    isNot(
      anyOf(contains('TextInput.clearClient'), contains('TextInput.setClient')),
    ),
    reason: "Enter restarted the field's text input",
  );
}

Future<void> _typesAgain(WidgetTester tester, String typed) async {
  tester.testTextInput.enterText(typed);
  await tester.pumpAndSettle();
  expect(_field(tester).controller.text, typed);
}

void main() {
  testWidgets("Enter in a combobox's field takes the highlighted option and "
      'leaves the field typing', (tester) async {
    final taken = <String>[];
    await tester.pumpWidget(
      _app(
        StudioCombobox<String>(
          label: 'Show',
          options: const ['Night Desk', 'Night Shift', 'Field Notes'],
          labelOf: (v) => v,
          onSelected: taken.add,
        ),
      ),
    );
    await _enter(tester, 'Night');
    expect(taken, ['Night Desk']);
    _keptTheKeyboard(tester);
    await _typesAgain(tester, 'Fie');
  });

  testWidgets("Enter in a tag input's field adds the tag and leaves the field "
      'typing for the next', (tester) async {
    var topics = <String>['Interviews'];
    await tester.pumpWidget(
      _app(
        StatefulBuilder(
          builder: (context, setState) => StudioTagInput<String>(
            label: 'Topics',
            values: topics,
            options: const ['Interviews', 'Science', 'Music', 'History'],
            labelOf: (k) => k,
            onChanged: (next) => setState(() => topics = next),
          ),
        ),
      ),
    );
    await _enter(tester, 'Sci');
    expect(topics, ['Interviews', 'Science']);
    _keptTheKeyboard(tester);
    await _typesAgain(tester, 'Mus');
  });

  testWidgets("Enter in a command palette's search runs the highlighted "
      'command and leaves the search typing', (tester) async {
    final ran = <String>[];
    await tester.pumpWidget(
      _app(
        SizedBox(
          height: 400,
          child: StudioCommandPalette(
            commands: [
              StudioCommand(label: 'New episode', onPressed: () {}),
              StudioCommand(label: 'Start recording', onPressed: () {}),
              StudioCommand(label: 'Export mix', onPressed: () {}),
            ],
            onSelected: (c) => ran.add(c.label),
          ),
        ),
      ),
    );
    await _enter(tester, 'Start');
    expect(ran, ['Start recording']);
    _keptTheKeyboard(tester);
    await _typesAgain(tester, 'Exp');
  });
}
