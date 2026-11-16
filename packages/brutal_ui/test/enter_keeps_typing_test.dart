// Enter in a field that keeps the keyboard (the combobox's field, the tag
// input's, the command palette's search) leaves it able to type: the field
// keeps the focus and its text input. Flutter restarts the text input of a
// field that has onSubmitted and keeps its focus through the done action, and
// a browser's restarted input takes no typing (the field looks focused, the
// letters go nowhere); so these fields take Enter in onEditingComplete alone.
import 'package:brutal_ui/brutal_ui.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(Widget child) => MaterialApp(
  home: BrutalTheme(
    data: BrutalThemeData.light(),
    child: Builder(
      builder: (context) => ColoredBox(
        color: BrutalTheme.of(context).colors.paper,
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
        BrutalCombobox<String>(
          label: 'Venue',
          options: const ['Porto', 'Porto Santo', 'Lisbon'],
          labelOf: (v) => v,
          onSelected: taken.add,
        ),
      ),
    );
    await _enter(tester, 'Port');
    expect(taken, ['Porto']);
    _keptTheKeyboard(tester);
    await _typesAgain(tester, 'Lis');
  });

  testWidgets("Enter in a tag input's field adds the tag and leaves the field "
      'typing for the next', (tester) async {
    var kinds = <String>['Noir'];
    await tester.pumpWidget(
      _app(
        StatefulBuilder(
          builder: (context, setState) => BrutalTagInput<String>(
            label: 'Kinds of night',
            values: kinds,
            options: const ['Noir', 'Western', 'Satire', 'Romance'],
            labelOf: (k) => k,
            onChanged: (next) => setState(() => kinds = next),
          ),
        ),
      ),
    );
    await _enter(tester, 'Sat');
    expect(kinds, ['Noir', 'Satire']);
    _keptTheKeyboard(tester);
    await _typesAgain(tester, 'Wes');
  });

  testWidgets("Enter in a command palette's search runs the highlighted "
      'command and leaves the search typing', (tester) async {
    final ran = <String>[];
    await tester.pumpWidget(
      _app(
        SizedBox(
          height: 400,
          child: BrutalCommandPalette(
            commands: [
              BrutalCommand(label: 'Share', onPressed: () {}),
              BrutalCommand(label: 'Duplicate', onPressed: () {}),
              BrutalCommand(label: 'Archive', onPressed: () {}),
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
