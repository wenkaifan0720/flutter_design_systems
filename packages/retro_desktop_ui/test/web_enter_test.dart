// Enter in a browser (the coordinator's web-enter-keeps-typing spec, 11-16). Flutter restarts the text input of a field
// told of a submit (onSubmitted) that still has the focus after it, and in a browser the restarted input never takes the
// browser's focus: the field looks focused, the arrows work, and letters go nowhere. So a field that keeps the focus on
// Enter (the look's combobox: Enter takes the lit option and the field goes on) takes Enter in onEditingComplete with no
// onSubmitted, and a field that gives the focus up (a text field told of a submit) keeps onSubmitted alone. Each is
// checked as the spec asks: after the done action the focus is where it should be, no TextInput.clearClient or
// TextInput.setClient is sent after it (a restart), and typing edits the field again.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';

const _countries = ['Austria', 'Belgium', 'Chile', 'Denmark'];

Widget _host(Widget child) => MaterialApp(
  builder: (context, child) =>
      RetroDesktopTheme(data: RetroDesktopThemeData.classic(), child: child!),
  home: Align(
    alignment: Alignment.topLeft,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: SizedBox(width: 320, child: child),
    ),
  ),
);

EditableText _editor(WidgetTester tester) =>
    tester.widget<EditableText>(find.byType(EditableText));

// The text input calls since the log was last cleared.
List<String> _calls(WidgetTester tester) =>
    tester.testTextInput.log.map((call) => call.method).toList();

void _noRestart(WidgetTester tester) => expect(
  _calls(tester),
  isNot(
    anyOf(contains('TextInput.clearClient'), contains('TextInput.setClient')),
  ),
  reason: "the field's text input was restarted after Enter: in a browser, typing would go nowhere",
);

void main() {
  testWidgets(
    'Enter in a combobox takes the lit option, and the field keeps the focus and its text input',
    variant: const TargetPlatformVariant({
      TargetPlatform.macOS,
      TargetPlatform.iOS,
    }),
    (tester) async {
      final taken = <String>[];
      await tester.pumpWidget(
        _host(
          RetroDesktopCombobox<String>(
            label: 'Country',
            options: _countries,
            onSelected: taken.add,
          ),
        ),
      );
      await tester.showKeyboard(find.byType(EditableText));
      await tester.enterText(find.byType(EditableText), 'Bel');
      await tester.pumpAndSettle();
      tester.testTextInput.log.clear();
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(taken, ['Belgium']);
      expect(
        _editor(tester).focusNode.hasFocus,
        isTrue,
        reason: 'Enter took the focus from the combobox',
      );
      _noRestart(tester);
      // Typing goes on in the same field, through the same input: it edits, filters and takes again.
      tester.testTextInput.log.clear();
      tester.testTextInput.enterText('Chi');
      await tester.pumpAndSettle();
      expect(_editor(tester).controller.text, 'Chi');
      expect(find.text('Chile'), findsOneWidget);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(taken, ['Belgium', 'Chile']);
      expect(_editor(tester).focusNode.hasFocus, isTrue);
      _noRestart(tester);
    },
  );

  testWidgets(
    'Enter in a text field told of a submit gives the focus up, and its input is closed, not restarted',
    (tester) async {
      final said = <String>[];
      await tester.pumpWidget(
        _host(RetroDesktopTextField(label: 'Name', onSubmitted: said.add)),
      );
      await tester.showKeyboard(find.byType(EditableText));
      await tester.enterText(find.byType(EditableText), 'Ada');
      await tester.pump();
      tester.testTextInput.log.clear();
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(said, ['Ada']);
      expect(_editor(tester).focusNode.hasFocus, isFalse);
      expect(
        _calls(tester),
        isNot(contains('TextInput.setClient')),
        reason: 'the input was restarted',
      );
      // Typing again starts with a tap, as in any field that gave the focus up, and edits it.
      await tester.enterText(find.byType(EditableText), 'Ada Lovelace');
      await tester.pump();
      expect(_editor(tester).controller.text, 'Ada Lovelace');
    },
  );
}
