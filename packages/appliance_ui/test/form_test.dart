// ApplianceForm: an ApplianceTextFormField checks its words when the form
// submits; a failed submit shows each error beside the red lamp, focuses the
// first wrong field, and after that the errors follow the edits; any other
// control takes part through ui_core's RawFormField round an ApplianceField;
// a submit with every field fine saves each value and calls onSubmit.
import 'package:appliance_ui/appliance_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp, Scaffold;

class _Form extends StatefulWidget {
  const _Form();

  @override
  State<_Form> createState() => _FormState();
}

class _FormState extends State<_Form> {
  final nameNode = FocusNode();
  final dayNode = FocusNode();
  final saved = <String, Object?>{};
  var submitted = 0;

  @override
  void dispose() {
    nameNode.dispose();
    dayNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ApplianceForm(
    onSubmit: () => submitted++,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 16,
        children: [
          ApplianceTextFormField(
            labelText: 'Name',
            focusNode: nameNode,
            validator: (value) =>
                (value ?? '').trim().isEmpty ? 'Enter a name' : null,
            onSaved: (value) => saved['name'] = value,
          ),
          RawFormField<DateTime>(
            focusNode: dayNode,
            validator: (value) => value == null ? 'Pick a delivery day' : null,
            onSaved: (value) => saved['day'] = value,
            builder: (field) => ApplianceDatePicker(
              labelText: 'Delivery',
              value: field.value,
              errorText: field.errorText,
              focusNode: dayNode,
              onChanged: field.didChange,
              firstDate: DateTime(2026),
              lastDate: DateTime(2027, 12, 31),
            ),
          ),
          Builder(
            builder: (context) => ApplianceButton(
              'Save',
              onPressed: () => ApplianceForm.submit(context),
            ),
          ),
        ],
      ),
    ),
  );
}

Future<_FormState> _pump(WidgetTester tester) async {
  tester.view
    ..physicalSize = const Size(390, 800)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, app) =>
          ApplianceHost(brightness: Brightness.light, child: app!),
      home: const Scaffold(body: _Form()),
    ),
  );
  await tester.pumpAndSettle();
  return tester.state<_FormState>(find.byType(_Form));
}

void main() {
  testWidgets('a failed submit shows each error and focuses the first', (
    tester,
  ) async {
    final form = await _pump(tester);
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a name'), findsOneWidget);
    expect(find.text('Pick a delivery day'), findsOneWidget);
    expect(form.nameNode.hasFocus, isTrue);
    expect(form.submitted, 0);
  });

  testWidgets('errors follow the edits; a fine submit saves each', (
    tester,
  ) async {
    final form = await _pump(tester);
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText), 'Ada');
    await tester.pumpAndSettle();
    expect(find.text('Enter a name'), findsNothing);
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(form.dayNode.hasFocus, isTrue);
    tester
        .state<FormFieldState<DateTime>>(
          find.byWidgetPredicate((w) => w is RawFormField<DateTime>),
        )
        .didChange(DateTime(2026, 11, 23));
    await tester.pumpAndSettle();
    expect(find.text('Pick a delivery day'), findsNothing);
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(form.submitted, 1);
    expect(form.saved, {'name': 'Ada', 'day': DateTime(2026, 11, 23)});
  });
}
