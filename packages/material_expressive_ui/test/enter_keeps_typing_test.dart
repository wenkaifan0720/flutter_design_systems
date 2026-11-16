/// Enter in a field that keeps the focus leaves its text input alone. In a
/// browser, Flutter restarts the text input of a field that has `onSubmitted`
/// and still holds the focus after the done action
/// (`EditableText._finalizeEditing`), and the web engine's new input takes no
/// typing: the field looks focused, the arrows work, letters do nothing. So a
/// field that keeps the focus after Enter (the multi-select's, the
/// combobox's) takes it in `onEditingComplete` with no `onSubmitted`; a field
/// that gives the focus up keeps `onSubmitted` alone.
library;

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';
import 'package:material_expressive_ui/material_expressive_host.dart';

Widget _page(Widget child) => MaterialApp(
  debugShowCheckedModeBanner: false,
  builder: (context, app) => ExpressiveHost(
    light: ExpressiveThemeData.preset('bloom', Brightness.light),
    brightness: Brightness.light,
    child: app!,
  ),
  home: Padding(
    padding: const EdgeInsets.all(24),
    child: Align(
      alignment: AlignmentDirectional.topStart,
      child: SizedBox(width: 320, child: child),
    ),
  ),
);

EditableText _editable(WidgetTester tester) =>
    tester.widget<EditableText>(find.byType(EditableText));

/// The field kept its text input through the done action: no restart.
void _keptItsInput(WidgetTester tester) => expect(
  tester.testTextInput.log.map((call) => call.method),
  isNot(
    anyOf(contains('TextInput.clearClient'), contains('TextInput.setClient')),
  ),
  reason:
      "the field's text input was restarted, which a browser types into "
      'no more',
);

/// Types [words], then the done action (Enter); the field must keep the
/// focus and its text input, and typing must edit it again.
Future<void> _enterKeepsTyping(WidgetTester tester, String words) async {
  await tester.showKeyboard(find.byType(EditableText));
  await tester.enterText(find.byType(EditableText), words);
  await tester.pumpAndSettle();
  tester.testTextInput.log.clear();
  await tester.testTextInput.receiveAction(TextInputAction.done);
  await tester.pumpAndSettle();
  expect(
    _editable(tester).focusNode.hasFocus,
    isTrue,
    reason: 'Enter took the focus away',
  );
  _keptItsInput(tester);
  tester.testTextInput.updateEditingValue(
    const TextEditingValue(
      text: 'Bl',
      selection: TextSelection.collapsed(offset: 2),
    ),
  );
  await tester.pumpAndSettle();
  expect(
    _editable(tester).controller.text,
    'Bl',
    reason: 'typing went nowhere',
  );
}

const List<ExpressiveSelectOption<String>> _colours = [
  ExpressiveSelectOption('red', 'Red'),
  ExpressiveSelectOption('green', 'Green'),
  ExpressiveSelectOption('blue', 'Blue'),
];

void main() {
  testWidgets("Enter in a multi-select adds a value, and the field keeps the "
      'focus and its text input for the next', (tester) async {
    var values = <String>[];
    await tester.pumpWidget(
      _page(
        StatefulBuilder(
          builder: (context, setState) => ExpressiveMultiSelect<String>(
            label: 'Colours',
            options: _colours,
            values: values,
            onCreate: (text) => text,
            onChanged: (next) => setState(() => values = next),
          ),
        ),
      ),
    );
    await _enterKeepsTyping(tester, 'Gr');
    expect(values, hasLength(1), reason: 'Enter added nothing');
    tester.testTextInput.log.clear();
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(values, hasLength(2), reason: 'a second Enter added nothing');
    expect(_editable(tester).focusNode.hasFocus, isTrue);
    _keptItsInput(tester);
  });

  testWidgets('Enter in a combobox tells onSubmitted, and the field keeps the '
      'focus and its text input', (tester) async {
    final submitted = <String>[];
    await tester.pumpWidget(
      _page(
        ExpressiveCombobox<String>(
          label: 'Colour',
          options: _colours,
          onSubmitted: submitted.add,
        ),
      ),
    );
    await _enterKeepsTyping(tester, 'Gr');
    expect(submitted, ['Gr']);
  });

  testWidgets('Enter in a text field with onSubmitted tells it and gives the '
      'focus up', (tester) async {
    final submitted = <String>[];
    await tester.pumpWidget(
      _page(ExpressiveTextField(label: 'Code', onSubmitted: submitted.add)),
    );
    await tester.showKeyboard(find.byType(EditableText));
    await tester.enterText(find.byType(EditableText), 'SAVE10');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(submitted, ['SAVE10']);
    expect(_editable(tester).focusNode.hasFocus, isFalse);
  });
}
