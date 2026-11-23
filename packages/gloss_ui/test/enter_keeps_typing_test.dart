// Enter in a field that keeps the keyboard (the combobox's field, the tag
// input's, the command palette's search) leaves it able to type: the field
// keeps the focus and its text input. Flutter restarts the text input of a
// field that has onSubmitted and keeps its focus through the done action, and
// a browser's restarted input takes no typing (the field looks focused, the
// letters go nowhere); so these fields take Enter in onEditingComplete alone
// (packs/_coord/specs/web-enter-keeps-typing.md).
import 'package:material_ui/material_ui.dart' show MaterialApp;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gloss_ui/gloss_ui.dart';

Widget _app(Widget child) => MaterialApp(
  home: GlossTheme(
    data: GlossThemeData.light(),
    child: Builder(
      builder: (context) => ColoredBox(
        color: GlossTheme.of(context).colors.page,
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

// Enter (the done action) after [typed]; then the field must still have the
// focus, its text input must not have been closed or opened again, and typing
// must still edit it.
Future<void> _enter(WidgetTester tester, String typed) async {
  await tester.showKeyboard(find.byType(EditableText));
  await tester.enterText(find.byType(EditableText), typed);
  await tester.pumpAndSettle();
  tester.testTextInput.log.clear();
  await tester.testTextInput.receiveAction(TextInputAction.done);
  await tester.pumpAndSettle();
}

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
        GlossCombobox<String>(
          labelText: 'Ingredient',
          options: const ['Basil', 'Bay leaf', 'Butter'],
          onSelected: taken.add,
        ),
      ),
    );
    await _enter(tester, 'Bay');
    expect(taken, ['Bay leaf']);
    _keptTheKeyboard(tester);
    await _typesAgain(tester, 'But');
  });

  testWidgets("Enter in a tag input's field adds the tag and leaves the field "
      'typing for the next', (tester) async {
    var tags = <String>['Quick'];
    await tester.pumpWidget(
      _app(
        StatefulBuilder(
          builder: (context, setState) => GlossTagInput<String>(
            labelText: 'Tags',
            values: tags,
            options: const ['Quick', 'Batch', 'Freezer', 'Vegan'],
            onChanged: (next) => setState(() => tags = next),
          ),
        ),
      ),
    );
    await _enter(tester, 'Fre');
    expect(tags, ['Quick', 'Freezer']);
    _keptTheKeyboard(tester);
    await _typesAgain(tester, 'Veg');
  });

  testWidgets("Enter in a command palette's search runs the highlighted "
      'command and leaves the search typing', (tester) async {
    final ran = <String>[];
    await tester.pumpWidget(
      _app(
        SizedBox(
          height: 400,
          child: GlossCommandPalette(
            commands: [
              GlossCommand(label: 'Share', onPressed: () {}),
              GlossCommand(label: 'Duplicate', onPressed: () {}),
              GlossCommand(label: 'Archive', onPressed: () {}),
            ],
            onSelected: (c) => ran.add(c.label),
          ),
        ),
      ),
    );
    await _enter(tester, 'Dup');
    expect(ran, ['Duplicate']);
    _keptTheKeyboard(tester);
    await _typesAgain(tester, 'Arc');
  });
}
