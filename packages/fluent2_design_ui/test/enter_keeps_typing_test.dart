// Submitting a combobox or multi-select keeps its text input connection
// open so the next keystroke edits the same field. Fields that give up
// focus on submit close the connection.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluent2_design_ui/fluent2_design_ui.dart';
import 'package:fluent2_design_ui/src/fluent2_design/components/input/field_core.dart'
    show Fluent2OptionFace;

const _options = [
  Fluent2Option('equipment', 'Equipment'),
  Fluent2Option('access', 'Access'),
  Fluent2Option('room', 'Room booking'),
];

Future<void> _stage(WidgetTester t, Widget body) async {
  t.view.physicalSize = const Size(1440, 900);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: (context, navigator) =>
          Fluent2Host(brightness: Brightness.light, child: navigator!),
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(width: 320, child: body),
          ),
        ),
      ),
    ),
  );
  await t.pumpAndSettle();
}

/// The text input channel's methods called since the log was cleared.
List<String> _calls(WidgetTester t) => [
  for (final call in t.testTextInput.log) call.method,
];

/// Types [words] into the field holding the focus, as a keyboard does, then
/// sends the keyboard's done action (Enter) with the channel's log cleared.
Future<void> _typeThenEnter(WidgetTester t, String words) async {
  await t.showKeyboard(find.byType(EditableText));
  await t.enterText(find.byType(EditableText), words);
  await t.pumpAndSettle();
  t.testTextInput.log.clear();
  await t.testTextInput.receiveAction(TextInputAction.done);
  await t.pumpAndSettle();
}

/// The field kept its text input through Enter.
void _keptItsInput(WidgetTester t) => expect(
  _calls(t),
  isNot(
    anyOf(contains('TextInput.clearClient'), contains('TextInput.setClient')),
  ),
  reason: "the field's text input was restarted: a browser takes no typing",
);

/// Types on, through the connection the field holds (no new one).
Future<void> _typeOn(WidgetTester t, String words) async {
  t.testTextInput.enterText(words);
  await t.pumpAndSettle();
}

String _words(WidgetTester t) =>
    t.widget<EditableText>(find.byType(EditableText)).controller.text;

List<String> _shown(WidgetTester t) => [
  for (final f in t.widgetList<Fluent2OptionFace>(
    find.byType(Fluent2OptionFace),
  ))
    f.label,
];

void main() {
  testWidgets('Enter in a combobox takes the active option, and the field '
      'keeps the focus and its text input: typing on edits it', (t) async {
    final field = FocusNode(debugLabel: 'combobox');
    addTearDown(field.dispose);
    String? value;
    final chosen = <String>[];
    await _stage(
      t,
      StatefulBuilder(
        builder: (context, set) => Fluent2Combobox<String>(
          semanticLabel: 'Type',
          value: value,
          options: _options,
          focusNode: field,
          onChanged: (v) {
            chosen.add(v);
            set(() => value = v);
          },
        ),
      ),
    );
    await _typeThenEnter(t, 'Acc');
    expect(chosen, ['access']);
    expect(field.hasFocus, isTrue, reason: 'the field keeps the focus');
    _keptItsInput(t);
    await _typeOn(t, 'Ro');
    expect(_words(t), 'Ro');
    expect(_shown(t), ['Room booking'], reason: 'the words filter the list');
    _keptItsInput(t);
    await t.testTextInput.receiveAction(TextInputAction.done);
    await t.pumpAndSettle();
    expect(chosen, ['access', 'room']);
    expect(field.hasFocus, isTrue);
    _keptItsInput(t);
  });

  testWidgets("Enter in a multi-select adds the active option, and the field "
      'keeps the focus and its text input for the next one', (t) async {
    final field = FocusNode(debugLabel: 'multi-select');
    addTearDown(field.dispose);
    var chosen = <String>[];
    await _stage(
      t,
      StatefulBuilder(
        builder: (context, set) => Fluent2MultiSelect<String>(
          semanticLabel: 'Types',
          options: _options,
          selected: chosen,
          focusNode: field,
          onChanged: (v) => set(() => chosen = v),
        ),
      ),
    );
    await _typeThenEnter(t, 'Acc');
    expect(chosen, ['access']);
    expect(field.hasFocus, isTrue, reason: 'the field keeps the focus');
    _keptItsInput(t);
    await _typeOn(t, 'Ro');
    expect(_words(t), 'Ro');
    await t.testTextInput.receiveAction(TextInputAction.done);
    await t.pumpAndSettle();
    expect(chosen, ['access', 'room'], reason: 'a tag per Enter, no click');
    expect(field.hasFocus, isTrue);
    _keptItsInput(t);
  });

  testWidgets('Enter in a text field submits its words and gives up the '
      'focus, opening no new text input', (t) async {
    final field = FocusNode(debugLabel: 'text field');
    addTearDown(field.dispose);
    final submitted = <String>[];
    await _stage(
      t,
      Fluent2TextField(
        semanticLabel: 'Name',
        focusNode: field,
        onChanged: (_) {},
        onSubmitted: submitted.add,
      ),
    );
    await _typeThenEnter(t, 'Northwind');
    expect(submitted, ['Northwind']);
    expect(field.hasFocus, isFalse);
    expect(_calls(t), isNot(contains('TextInput.setClient')));
  });

  testWidgets('Enter in a spin button takes the typed value and gives up the '
      'focus, opening no new text input', (t) async {
    final field = FocusNode(debugLabel: 'spin button');
    addTearDown(field.dispose);
    num value = 2;
    await _stage(
      t,
      StatefulBuilder(
        builder: (context, set) => Fluent2SpinButton(
          semanticLabel: 'Seats',
          value: value,
          min: 0,
          max: 10,
          focusNode: field,
          onChanged: (v) => set(() => value = v),
        ),
      ),
    );
    await _typeThenEnter(t, '7');
    expect(value, 7);
    expect(field.hasFocus, isFalse);
    expect(_calls(t), isNot(contains('TextInput.setClient')));
  });
}
