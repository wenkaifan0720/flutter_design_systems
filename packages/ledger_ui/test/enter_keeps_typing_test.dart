// After Enter, a field that keeps the focus keeps taking typing (packs/_coord/specs/web-enter-keeps-typing.md). Flutter
// restarts the text input of a field told of a submit (onSubmitted) while it keeps the focus, and in a browser the
// restarted input takes no typing: the field looks focused, the arrows work, letters and Backspace do nothing. A field
// with neither onSubmitted nor onEditingComplete loses the focus on Enter instead (a tag per click). Ledger's fields
// that keep the focus after Enter (the combobox's, the tag field's, the command palette's search and the composer's)
// take Enter in onEditingComplete with no onSubmitted. Each here: focus, type, the done action (the composer's send),
// then the focus is still the field's, no TextInput.clearClient or setClient went to the platform after it, and typing
// edits the field again.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledger_ui/ledger_ui.dart';
import 'package:ledger_ui/ledger_host.dart';

Future<void> _pump(WidgetTester t, Widget field) async {
  await t.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: (context, page) =>
          LedgerHost(brightness: Brightness.light, child: page!),
      home: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: field,
      ),
    ),
  );
  await t.pumpAndSettle();
}

EditableText _field(WidgetTester t) =>
    t.widget<EditableText>(find.byType(EditableText));

/// Focuses the field, types [words], and sends [action] as the platform's
/// text input does on Enter, recording what goes to the platform after it.
Future<void> _typeAndEnter(
  WidgetTester t,
  String words, {
  TextInputAction action = TextInputAction.done,
}) async {
  await t.showKeyboard(find.byType(EditableText));
  await t.enterText(find.byType(EditableText), words);
  await t.pumpAndSettle();
  t.testTextInput.log.clear();
  await t.testTextInput.receiveAction(action);
  await t.pumpAndSettle();
}

/// The field kept the focus and its text input through Enter, and typing
/// [more] edits it again without a press to bring it back.
Future<void> _keepsTyping(WidgetTester t, String more) async {
  expect(_field(t).focusNode.hasFocus, isTrue, reason: 'Enter took the focus');
  expect(
    t.testTextInput.log.map((call) => call.method),
    isNot(
      anyOf(contains('TextInput.clearClient'), contains('TextInput.setClient')),
    ),
    reason: "the field's text input was restarted",
  );
  t.testTextInput.enterText(more);
  await t.pumpAndSettle();
  expect(_field(t).controller.text, more, reason: 'the typing went nowhere');
}

void main() {
  testWidgets('the combobox takes an option on Enter and keeps typing', (
    t,
  ) async {
    final taken = <String>[];
    await _pump(
      t,
      LedgerCombobox<String>(
        label: 'Payee',
        options: const ['Corner Market', 'Cedar Books', 'City Water'],
        onSelected: taken.add,
      ),
    );
    await _typeAndEnter(t, 'Cor');
    expect(taken, ['Corner Market']);
    await _keepsTyping(t, 'Ci');
  });

  testWidgets('the tag field adds a tag on Enter and keeps typing the next', (
    t,
  ) async {
    var people = <String>[];
    await _pump(
      t,
      StatefulBuilder(
        builder: (context, setState) => LedgerMultiSelect<String>(
          label: 'Split with',
          values: people,
          options: const ['Maren', 'Theo', 'Ana'],
          onChanged: (v) => setState(() => people = v),
        ),
      ),
    );
    await _typeAndEnter(t, 'Ma');
    expect(people, ['Maren']);
    await _keepsTyping(t, 'Th');
    t.testTextInput.log.clear();
    await t.testTextInput.receiveAction(TextInputAction.done);
    await t.pumpAndSettle();
    expect(people, ['Maren', 'Theo'], reason: 'a second tag took a press');
    await _keepsTyping(t, 'A');
  });

  testWidgets('the command palette on a page runs an act on Enter and keeps '
      'its search', (t) async {
    final ran = <String>[];
    await _pump(
      t,
      SizedBox(
        height: 480,
        child: LedgerCommandPalette(
          commands: const [
            LedgerCommand(label: 'New entry', group: 'Entries'),
            LedgerCommand(label: 'Export October', group: 'Entries'),
          ],
          onSelected: (c) => ran.add(c.label),
        ),
      ),
    );
    await _typeAndEnter(t, 'New');
    expect(ran, ['New entry']);
    await _keepsTyping(t, 'Exp');
  });

  testWidgets('the composer sends on Enter and keeps the next message', (
    t,
  ) async {
    final reply = TextEditingController();
    addTearDown(reply.dispose);
    final sent = <String>[];
    await _pump(
      t,
      LedgerComposer(
        controller: reply,
        hint: 'Write a reply',
        onSubmitted: () {
          sent.add(reply.text);
          reply.clear();
        },
      ),
    );
    await _typeAndEnter(t, 'Lunch at noon', action: TextInputAction.send);
    expect(sent, ['Lunch at noon']);
    await _keepsTyping(t, 'And');
  });

  testWidgets('an empty composer keeps the focus on Enter and sends nothing', (
    t,
  ) async {
    final sent = <String>[];
    await _pump(
      t,
      LedgerComposer(hint: 'Write a reply', onSubmitted: () => sent.add('')),
    );
    await _typeAndEnter(t, '', action: TextInputAction.send);
    expect(sent, isEmpty);
    await _keepsTyping(t, 'Hi');
  });
}
