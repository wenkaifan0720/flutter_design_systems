// A field that keeps the focus after Enter keeps its text input too. Flutter
// restarts the input of a field that is told of a submit (onSubmitted) and
// still holds the focus afterwards, and in a browser the restarted input
// takes no typing: the field looks focused, the arrows work, letters go
// nowhere. So a field that stays (a combobox's, a tag input's, the command
// palette's search) takes Enter in onEditingComplete, with no onSubmitted;
// a field that gives the focus up keeps onSubmitted alone.
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:minimal_ui/minimal_host.dart';

Widget _page(Widget child) => MaterialApp(
  debugShowCheckedModeBanner: false,
  builder: (context, navigator) => MinimalHost(
    light: MinimalThemeData.preset('standard', Brightness.light),
    dark: MinimalThemeData.preset('standard', Brightness.dark),
    brightness: Brightness.light,
    child: navigator!,
  ),
  home: Scaffold(
    body: Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SizedBox(width: 360, child: child),
      ),
    ),
  ),
);

EditableText _field(WidgetTester tester) =>
    tester.widget<EditableText>(find.byType(EditableText));

/// The keyboard's done action (a browser's Enter), its text input calls
/// recorded from here on.
Future<void> _done(WidgetTester tester) async {
  tester.testTextInput.log.clear();
  await tester.testTextInput.receiveAction(TextInputAction.done);
  await tester.pumpAndSettle();
}

/// Typing into the field's text input as it stands, without focusing it
/// again (enterText would take the focus back first).
Future<void> _typeOn(WidgetTester tester, String text) async {
  tester.testTextInput.updateEditingValue(
    TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    ),
  );
  await tester.pumpAndSettle();
}

/// The field kept the focus and its text input through the done action, and
/// what is typed next lands in it.
Future<void> _keptTyping(WidgetTester tester, String next) async {
  expect(
    _field(tester).focusNode.hasFocus,
    isTrue,
    reason: 'Enter took the focus away',
  );
  expect(
    tester.testTextInput.log.map((call) => call.method),
    isNot(
      anyOf(contains('TextInput.clearClient'), contains('TextInput.setClient')),
    ),
    reason: "the field's text input was restarted (in a browser it then takes no typing)",
  );
  await _typeOn(tester, next);
  expect(
    _field(tester).controller.text,
    next,
    reason: 'the typing went nowhere',
  );
}

void main() {
  testWidgets(
    'a combobox: Enter takes the lit option, and the field keeps the focus and its typing',
    (tester) async {
      final taken = <String>[];
      await tester.pumpWidget(
        _page(
          MinimalCombobox<String>(
            labelText: 'Port',
            options: const ['Porto', 'Porto Santo', 'Lisbon'],
            onSelected: taken.add,
          ),
        ),
      );
      await tester.showKeyboard(find.byType(EditableText));
      await tester.enterText(find.byType(EditableText), 'Port');
      await tester.pumpAndSettle();
      await _done(tester);
      expect(taken, ['Porto']);
      await _keptTyping(tester, 'Lis');
      await _done(tester);
      expect(taken, ['Porto', 'Lisbon']);
      expect(_field(tester).focusNode.hasFocus, isTrue);
    },
  );

  testWidgets(
    'a tag input: Enter adds the typed tag, and the field keeps the focus and its typing',
    (tester) async {
      var tags = <String>[];
      late StateSetter set;
      await tester.pumpWidget(
        _page(
          StatefulBuilder(
            builder: (context, setState) {
              set = setState;
              return MinimalMultiSelect<String>(
                labelText: 'Labels',
                values: tags,
                options: const ['Noir', 'Western', 'Horror'],
                onCreate: (text) => text.trim().isEmpty ? null : text.trim(),
                onChanged: (next) => setState(() => tags = next),
              );
            },
          ),
        ),
      );
      await tester.showKeyboard(find.byType(EditableText));
      await tester.enterText(find.byType(EditableText), 'alpha');
      await tester.pumpAndSettle();
      await _done(tester);
      expect(tags, ['alpha']);
      await _keptTyping(tester, 'beta');
      await _done(tester);
      expect(tags, ['alpha', 'beta']);
      expect(_field(tester).focusNode.hasFocus, isTrue);
      // The last tag gone (the first one came above): the entry is the same
      // field, its text input open.
      tester.testTextInput.log.clear();
      set(() => tags = []);
      await tester.pumpAndSettle();
      await _keptTyping(tester, 'gamma');
    },
  );

  testWidgets(
    "the command palette: Enter runs the lit command once, and the search keeps the focus and its typing",
    (tester) async {
      final ran = <String>[];
      await tester.pumpWidget(
        _page(
          MinimalCommand(
            // An action without its own onSelected is dimmed and cannot run.
            actions: [
              MinimalCommandItem('Mark done', onSelected: () {}),
              MinimalCommandItem('Archive', onSelected: () {}),
            ],
            onSelected: (action) => ran.add(action.label),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(EditableText), 'arch');
      await tester.pumpAndSettle();
      await _done(tester);
      expect(ran, ['Archive']);
      await _keptTyping(tester, 'mark');
      await _done(tester);
      expect(ran, ['Archive', 'Mark done']);
      // The key itself (a desktop's Enter, which the palette binds) runs it
      // once too.
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(ran, ['Archive', 'Mark done', 'Mark done']);
    },
  );

  testWidgets(
    'a field that gives the focus up says what was entered once, and lets go',
    (tester) async {
      final said = <String>[];
      for (final field in <Widget>[
        MinimalTextField(labelText: 'Name', onSubmitted: said.add),
        MinimalSearchField(hintText: 'Search habits', onSubmitted: said.add),
      ]) {
        said.clear();
        await tester.pumpWidget(_page(field));
        await tester.showKeyboard(find.byType(EditableText));
        await tester.enterText(find.byType(EditableText), 'Ada');
        await tester.pumpAndSettle();
        await _done(tester);
        expect(said, ['Ada'], reason: '${field.runtimeType}');
        expect(
          _field(tester).focusNode.hasFocus,
          isFalse,
          reason: '${field.runtimeType}',
        );
      }
    },
  );
}
