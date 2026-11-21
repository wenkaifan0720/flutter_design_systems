// The web's Enter rule (a field that keeps the focus after Enter takes it in
// onEditingComplete, `field.submit`, and has no onSubmitted): the done
// action then keeps the focus, never restarts the text input's connection
// (no clearClient, no setClient: on the web a restarted input element never
// gets the field's geometry, so it never takes the browser's focus, and
// letters stop reaching the field), and typing goes on editing the field.
// One test per field ui_core hands a look: the combobox's, the tag input's,
// the command palette's.
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/ui_core.dart';

import 'behaviour_harness.dart';

late FocusNode _focus;
late TextEditingController _text;

// The field as the doc examples wire it: Enter in onEditingComplete.
Widget _field(DesignComboboxField field) {
  _focus = field.focusNode;
  _text = field.controller;
  return SizedBox(
    width: 200,
    child: EditableText(
      controller: field.controller,
      focusNode: field.focusNode,
      style: const TextStyle(fontSize: 14, color: Color(0xFF000000)),
      cursorColor: const Color(0xFF000000),
      backgroundCursorColor: const Color(0xFF808080),
      onEditingComplete: field.submit,
    ),
  );
}

// Types [typed], sends the done action, and checks the rule; returns what
// the field says after the action.
Future<String> _enter(WidgetTester tester, String typed) async {
  await tester.enterText(find.byType(EditableText), typed);
  await tester.pumpAndSettle();
  tester.testTextInput.log.clear();
  await tester.testTextInput.receiveAction(TextInputAction.done);
  await tester.pumpAndSettle();
  final after = _text.text;
  expect(_focus.hasFocus, isTrue, reason: 'the field keeps the focus');
  expect(
    tester.testTextInput.log.map((call) => call.method),
    isNot(
      anyOf(contains('TextInput.clearClient'), contains('TextInput.setClient')),
    ),
    reason: 'the connection is not restarted',
  );
  // Typing goes on: the platform's next edit reaches the field.
  tester.testTextInput.updateEditingValue(
    TextEditingValue(
      text: '${after}x',
      selection: TextSelection.collapsed(offset: after.length + 1),
    ),
  );
  await tester.pump();
  expect(_text.text, '${after}x', reason: 'typing edits the field');
  return after;
}

void main() {
  testWidgets('a combobox: Enter takes the option, and typing goes on', (
    tester,
  ) async {
    String? taken;
    await tester.pumpWidget(
      harness(
        Center(
          child: RawCombobox<String>(
            options: const ['Apple', 'Pear'],
            onSelected: (option) => taken = option,
            fieldBuilder: (context, field) => _field(field),
            optionBuilder: (context, option, states) =>
                SizedBox(height: 44, child: Text(option)),
          ),
        ),
      ),
    );
    expect(await _enter(tester, 'Ap'), 'Apple');
    expect(taken, 'Apple');
  });

  testWidgets('a tag input: Enter adds the tag, and the next one types', (
    tester,
  ) async {
    var values = <String>[];
    await tester.pumpWidget(
      harness(
        Center(
          child: StatefulBuilder(
            builder: (context, setState) => RawTagInput<String>(
              values: values,
              onChanged: (next) => setState(() => values = next),
              onCreate: (text) => text,
              fieldBuilder: (context, field) => _field(field),
              optionBuilder: (context, option, states) => Text(option),
              tagBuilder: (context, value, tag) => Text(value),
            ),
          ),
        ),
      ),
    );
    expect(await _enter(tester, 'red'), isEmpty);
    expect(values, ['red']);
  });

  testWidgets('a command palette: Enter runs the command, and the search '
      'goes on', (tester) async {
    final ran = <String>[];
    await tester.pumpWidget(
      harness(
        Center(
          child: RawCommandPalette(
            commands: [
              RawCommand(label: 'Zoom in', onPressed: () => ran.add('zoom')),
            ],
            autofocus: true,
            fieldBuilder: (context, field) => _field(field),
            itemBuilder: (context, command, states) =>
                SizedBox(height: 44, child: Text(command.label)),
          ),
        ),
      ),
    );
    await _enter(tester, 'zo');
    expect(ran, ['zoom']);
  });
}
