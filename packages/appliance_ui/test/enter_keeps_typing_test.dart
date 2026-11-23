// A field that keeps the focus after Enter (the combobox's, the tag input's,
// the command palette's) takes Enter in onEditingComplete and has no
// onSubmitted: Enter does its work, the field keeps the focus, the text
// input connection is neither closed nor opened again (on the web a
// reopened one never takes the browser's focus, and typing stops), and
// typing still edits the field.
import 'package:appliance_ui/appliance_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(Widget child) => MaterialApp(
  debugShowCheckedModeBanner: false,
  builder: (context, app) => ApplianceHost(child: app!),
  home: ApplianceScreen(
    body: Align(alignment: Alignment.topCenter, child: child),
  ),
);

/// Focuses the field, types [first], sends Enter, and checks the focus and
/// the connection held; then types [more] into it and returns its text.
Future<String> _enterThenType(
  WidgetTester tester, {
  required String first,
  required String more,
}) async {
  final field = find.byType(EditableText);
  await tester.showKeyboard(field);
  await tester.enterText(field, first);
  await tester.pump();
  tester.testTextInput.log.clear();
  await tester.testTextInput.receiveAction(TextInputAction.done);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  final editable = tester.widget<EditableText>(field);
  expect(editable.focusNode.hasFocus, isTrue, reason: 'Enter kept the focus');
  final calls = [for (final c in tester.testTextInput.log) c.method];
  expect(
    calls,
    isNot(
      anyOf(contains('TextInput.clearClient'), contains('TextInput.setClient')),
    ),
    reason: 'the connection stayed open through Enter: $calls',
  );
  expect(tester.testTextInput.hasAnyClients, isTrue);
  tester.testTextInput.enterText(more);
  await tester.pump();
  return tester.widget<EditableText>(field).controller.text;
}

void main() {
  testWidgets('combobox: Enter takes the option and typing goes on', (
    tester,
  ) async {
    String? chosen;
    await tester.pumpWidget(
      _app(
        StatefulBuilder(
          builder: (context, setState) => SizedBox(
            width: 320,
            child: ApplianceCombobox<String>(
              labelText: 'Finish',
              options: const ['Chalk', 'Clay', 'Slate'],
              value: chosen,
              onSelected: (v) => setState(() => chosen = v),
            ),
          ),
        ),
      ),
    );
    final text = await _enterThenType(tester, first: 'Cl', more: 'Sla');
    expect(chosen, 'Clay');
    expect(text, 'Sla');
  });

  testWidgets('tag input: Enter adds the tag and typing goes on', (
    tester,
  ) async {
    var tags = <String>['Oak'];
    await tester.pumpWidget(
      _app(
        StatefulBuilder(
          builder: (context, setState) => SizedBox(
            width: 320,
            child: ApplianceTagInput<String>(
              labelText: 'Materials',
              values: tags,
              options: const ['Oak', 'Ash', 'Walnut', 'Linen'],
              onCreate: (text) => text.trim().isEmpty ? null : text.trim(),
              onChanged: (v) => setState(() => tags = v),
            ),
          ),
        ),
      ),
    );
    final text = await _enterThenType(tester, first: 'Wal', more: 'Li');
    expect(tags, ['Oak', 'Walnut']);
    expect(text, 'Li');
  });

  testWidgets('command palette: Enter runs the command and typing goes on', (
    tester,
  ) async {
    final ran = <String>[];
    await tester.pumpWidget(
      _app(
        SizedBox(
          width: 360,
          child: ApplianceCommandPalette(
            commands: [
              RawCommand(
                label: 'Start the timer',
                onPressed: () => ran.add('timer'),
              ),
              RawCommand(
                label: 'Descale the kettle',
                onPressed: () => ran.add('descale'),
              ),
            ],
          ),
        ),
      ),
    );
    final text = await _enterThenType(tester, first: 'desc', more: 'tim');
    expect(ran, ['descale']);
    expect(text, endsWith('tim'));
  });
}
