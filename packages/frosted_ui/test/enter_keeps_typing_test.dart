// After Enter, typing still reaches a field that keeps the focus. In a
// browser, Flutter restarts the text input of a field told of a submit that
// still holds the focus (EditableText's onSubmitted path, Flutter 3.47.0), and
// the web engine's new input never takes the browser's focus: the field looks
// focused and the arrows work, but letters do nothing. So a field that keeps
// the focus after Enter (a combobox's field, a multi-select's, a palette's
// search, an "add another" field) takes Enter in onEditingComplete with no
// onSubmitted, and a field that lets the focus go keeps onSubmitted with no
// onEditingComplete. For each: focus it, type, send the done action, then
// read where the focus is, that the text input was not restarted
// (TextInput.clearClient / setClient after the action), and that typing on
// edits the field.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';

const _cities = ['Amsterdam', 'Berlin', 'Dublin', 'Lisbon', 'Madrid'];
const _tags = ['Design', 'Review', 'Writing', 'Travel'];

Widget _host(Widget child) {
  final t = FrostedThemeData.opal();
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    builder: (context, page) =>
        FrostedHost(theme: t, darkTheme: t, child: page!),
    home: ColoredBox(
      color: t.colorScheme.background,
      child: Align(
        alignment: Alignment.topLeft,
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: SizedBox(width: 400, child: child),
        ),
      ),
    ),
  );
}

EditableText _editable(WidgetTester tester) =>
    tester.widget<EditableText>(find.byType(EditableText));

/// Types [text] as the keyboard does: into the text input's current client
/// only, with no tap or showKeyboard to attach it again.
Future<void> _type(WidgetTester tester, String text) async {
  tester.testTextInput.enterText(text);
  await tester.pumpAndSettle();
}

/// Focuses the field, types [text] and sends the done action, recording the
/// text input's calls from the action on.
Future<void> _enter(WidgetTester tester, String text) async {
  await tester.showKeyboard(find.byType(EditableText));
  await tester.pumpAndSettle();
  await _type(tester, text);
  tester.testTextInput.log.clear();
  await tester.testTextInput.receiveAction(TextInputAction.done);
  await tester.pumpAndSettle();
}

/// The text input's calls since the done action.
List<String> _calls(WidgetTester tester) => [
  for (final call in tester.testTextInput.log) call.method,
];

/// A field that keeps the focus after Enter: it still has it, its text input
/// was not restarted, and typing on edits it.
Future<void> _keepsTyping(WidgetTester tester, String more) async {
  expect(
    _editable(tester).focusNode.hasFocus,
    isTrue,
    reason: 'Enter took the focus',
  );
  expect(
    _calls(tester),
    isNot(
      anyOf(contains('TextInput.clearClient'), contains('TextInput.setClient')),
    ),
    reason: "the field's text input was restarted",
  );
  await _type(tester, more);
  expect(
    _editable(tester).controller.text,
    more,
    reason: 'typing after Enter went nowhere',
  );
}

/// A field that lets the focus go after Enter: it has let it go, and its text
/// input was closed, not restarted.
void _letsGo(WidgetTester tester) {
  expect(
    _editable(tester).focusNode.hasFocus,
    isFalse,
    reason: 'Enter kept the focus',
  );
  expect(
    _calls(tester),
    isNot(contains('TextInput.setClient')),
    reason: "the field's text input was restarted",
  );
}

void main() {
  testWidgets(
    "a combobox takes the option on Enter and its field keeps typing",
    (tester) async {
      String? city;
      await tester.pumpWidget(
        _host(
          StatefulBuilder(
            builder: (context, setState) => FrostedCombobox<String>(
              labelText: 'City',
              options: _cities,
              value: city,
              onSelected: (v) => setState(() => city = v),
            ),
          ),
        ),
      );
      await _enter(tester, 'Ber');
      expect(city, 'Berlin');
      await _keepsTyping(tester, 'Dub');
    },
  );

  testWidgets(
    'a multi-select adds the tag on Enter and its field keeps typing for the next',
    (tester) async {
      var chosen = <String>[];
      await tester.pumpWidget(
        _host(
          StatefulBuilder(
            builder: (context, setState) => FrostedMultiSelect<String>(
              labelText: 'Tags',
              options: _tags,
              values: chosen,
              onChanged: (v) => setState(() => chosen = v),
            ),
          ),
        ),
      );
      await _enter(tester, 'Rev');
      expect(chosen, ['Review']);
      await _keepsTyping(tester, 'Wri');
      tester.testTextInput.log.clear();
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(chosen, [
        'Review',
        'Writing',
      ], reason: 'a second tag needed a click');
      await _keepsTyping(tester, 'Tra');
    },
  );

  testWidgets(
    'a palette built in place runs the command on Enter and its search keeps typing',
    (tester) async {
      final ran = <String>[];
      await tester.pumpWidget(
        _host(
          FrostedCommand(
            commands: [
              RawCommand(label: 'New payment', onPressed: () => ran.add('pay')),
              RawCommand(
                label: 'Settings',
                onPressed: () => ran.add('settings'),
              ),
            ],
          ),
        ),
      );
      await _enter(tester, 'pay');
      expect(ran, ['pay']);
      await _keepsTyping(tester, 'set');
    },
  );

  testWidgets(
    'a text field told of Enter in onEditingComplete keeps typing (an "add another" field)',
    (tester) async {
      final added = <String>[];
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _host(
          FrostedTextField(
            labelText: 'Add a guest',
            controller: controller,
            onEditingComplete: () {
              added.add(controller.text);
              controller.clear();
            },
          ),
        ),
      );
      await _enter(tester, 'Ada');
      expect(added, ['Ada']);
      await _keepsTyping(tester, 'Grace');
    },
  );

  testWidgets(
    'a text field told of Enter in onSubmitted lets the focus go once',
    (tester) async {
      final submitted = <String>[];
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _host(
          FrostedTextField(
            labelText: 'Name',
            controller: controller,
            onSubmitted: submitted.add,
          ),
        ),
      );
      await _enter(tester, 'Ada');
      expect(submitted, ['Ada']);
      _letsGo(tester);
    },
  );

  testWidgets(
    "a colour picker's hex field sets the colour on Enter and lets the focus go",
    (tester) async {
      var colour = const Color(0xFF000000);
      await tester.pumpWidget(
        _host(
          StatefulBuilder(
            builder: (context, setState) => FrostedColorPicker(
              value: colour,
              onChanged: (c) => setState(() => colour = c),
            ),
          ),
        ),
      );
      await _enter(tester, '336699');
      expect(colour.toARGB32(), 0xFF336699);
      _letsGo(tester);
    },
  );
}
