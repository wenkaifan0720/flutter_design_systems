// After Enter, a field that keeps the focus keeps its text input: Flutter restarts the input of a field told of a
// submit that still holds the focus, and in a browser the restarted input takes no typing (the field looks focused,
// the arrows work, letters do nothing). So the fields that stay after Enter (a combobox's, a multi-select's, a
// command palette's search) take it in onEditingComplete with no onSubmitted.

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

import 'support.dart';

/// The one editable [tester] finds.
EditableText _editable(WidgetTester tester) =>
    tester.widget<EditableText>(find.byType(EditableText));

/// Sends Done, after forgetting the input calls before it.
Future<void> _enter(WidgetTester tester) async {
  tester.testTextInput.log.clear();
  await tester.testTextInput.receiveAction(TextInputAction.done);
  await tester.pumpAndSettle();
}

/// The field kept the focus and its text input through Enter, and typing after it still edits the field.
Future<void> _keepsTyping(WidgetTester tester, String more) async {
  expect(
    _editable(tester).focusNode.hasFocus,
    isTrue,
    reason: 'Enter took the focus',
  );
  expect(
    tester.testTextInput.log.map((call) => call.method),
    isNot(
      anyOf(contains('TextInput.clearClient'), contains('TextInput.setClient')),
    ),
    reason: "Enter restarted the field's text input",
  );
  // Straight to the input the field already holds: no tap, no new connection.
  tester.testTextInput.enterText(more);
  await tester.pumpAndSettle();
  expect(_editable(tester).controller.text, more);
}

Widget _sized(Widget child) =>
    neumorphicApp(Center(child: SizedBox(width: 320, child: child)));

void main() {
  setUpAll(() async {
    await loadNeumorphicFonts();
    await loadNeumorphicGlyphs();
  });

  testWidgets(
    "Enter in a combobox's field takes the lit option, and the field keeps the focus and the typing",
    (tester) async {
      final taken = <String>[];
      await tester.pumpWidget(
        _sized(
          NeumorphicCombobox<String>(
            label: 'Port',
            options: const ['Porto', 'Porto Santo', 'Lisbon'],
            onSelected: taken.add,
          ),
        ),
      );
      await tester.showKeyboard(find.byType(EditableText));
      await tester.enterText(find.byType(EditableText), 'Port');
      await tester.pumpAndSettle();
      await _enter(tester);
      expect(taken, ['Porto']);
      await _keepsTyping(tester, 'Lis');
    },
  );

  testWidgets(
    "Enter in a multi-select's field adds the lit tag, and the field keeps the focus and the typing",
    (tester) async {
      var genres = <String>[];
      await tester.pumpWidget(
        _sized(
          StatefulBuilder(
            builder: (context, setState) => NeumorphicMultiSelect<String>(
              label: 'Genres',
              values: genres,
              options: const ['Noir', 'Western', 'Horror'],
              onChanged: (next) => setState(() => genres = next),
            ),
          ),
        ),
      );
      await tester.showKeyboard(find.byType(EditableText));
      await tester.enterText(find.byType(EditableText), 'Wes');
      await tester.pumpAndSettle();
      await _enter(tester);
      expect(genres, ['Western']);
      await _keepsTyping(tester, 'Hor');
      // And the next Enter adds the next tag, without a click between.
      await _enter(tester);
      expect(genres, ['Western', 'Horror']);
      await _keepsTyping(tester, 'N');
    },
  );

  testWidgets(
    "Enter in a multi-select's field adds the words typed as a tag of their own, and keeps the typing",
    (tester) async {
      var tags = <String>[];
      await tester.pumpWidget(
        _sized(
          StatefulBuilder(
            builder: (context, setState) => NeumorphicMultiSelect<String>(
              label: 'Tags',
              values: tags,
              onCreate: (words) => words,
              onChanged: (next) => setState(() => tags = next),
            ),
          ),
        ),
      );
      await tester.showKeyboard(find.byType(EditableText));
      await tester.enterText(find.byType(EditableText), 'urgent');
      await tester.pumpAndSettle();
      await _enter(tester);
      expect(tags, ['urgent']);
      expect(_editable(tester).controller.text, isEmpty);
      await _keepsTyping(tester, 'later');
    },
  );

  testWidgets(
    "Enter in a command palette's search runs the lit command, and the search keeps the focus and the typing",
    (tester) async {
      final ran = <String>[];
      await tester.pumpWidget(
        _sized(
          NeumorphicCommand(
            autofocus: true,
            commands: [
              for (final name in const ['Archive', 'Duplicate', 'Rename'])
                RawCommand(label: name, onPressed: () => ran.add(name)),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.showKeyboard(find.byType(EditableText));
      await tester.enterText(find.byType(EditableText), 'dup');
      await tester.pumpAndSettle();
      await _enter(tester);
      expect(ran, ['Duplicate']);
      await _keepsTyping(tester, 'ren');
    },
  );

  testWidgets(
    'Enter in the command palette over the page runs the lit command and closes it',
    (tester) async {
      final ran = <String>[];
      await tester.pumpWidget(
        neumorphicApp(
          Builder(
            builder: (context) => Center(
              child: NeumorphicButton(
                'Commands',
                onPressed: () => showNeumorphicCommand(
                  context,
                  commands: [
                    for (final name in const ['Archive', 'Duplicate'])
                      RawCommand(label: name, onPressed: () => ran.add(name)),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Commands'));
      await tester.pumpAndSettle();
      await tester.showKeyboard(find.byType(EditableText));
      await tester.enterText(find.byType(EditableText), 'arc');
      await tester.pumpAndSettle();
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(ran, ['Archive']);
      expect(find.byType(EditableText), findsNothing);
    },
  );
}
