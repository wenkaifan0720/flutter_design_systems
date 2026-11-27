// Any control in a MinimalForm: ui_core's RawFormField round a select, a
// date, a checkbox and a radio group, its errorText on a MinimalFormField
// round the control and the control's focus node handed to both. A failed
// submit shows each error and focuses the first wrong control (the date
// picker's and the radio group's focusNode, new in 0.8.0); a date in error
// draws its pill's edge in the danger colour; after that each error
// follows its control; a submit with every field fine saves each value.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';

class _Form extends StatefulWidget {
  const _Form();

  @override
  State<_Form> createState() => _FormState();
}

class _FormState extends State<_Form> {
  final repeatNode = FocusNode();
  final startNode = FocusNode();
  final termsNode = FocusNode();
  final planNode = FocusNode();
  final saved = <String, Object?>{};
  var submitted = 0;

  @override
  void dispose() {
    for (final node in [repeatNode, startNode, termsNode, planNode]) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MinimalForm(
    onSubmit: () => submitted++,
    child: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: MinimalSpacing.s16,
          children: [
            RawFormField<String>(
              focusNode: repeatNode,
              validator: (value) => value == null ? 'Choose how often' : null,
              onSaved: (value) => saved['repeat'] = value,
              builder: (field) => MinimalFormField(
                errorText: field.errorText,
                focusNode: repeatNode,
                child: MinimalSelect<String>(
                  labelText: 'Repeats',
                  value: field.value,
                  hintText: 'Choose',
                  focusNode: repeatNode,
                  options: const [
                    MinimalSelectOption('daily', 'Every day'),
                    MinimalSelectOption('weekly', 'Every week'),
                  ],
                  onChanged: field.didChange,
                ),
              ),
            ),
            RawFormField<DateTime>(
              focusNode: startNode,
              validator: (value) =>
                  value == null ? 'Pick the day you started' : null,
              onSaved: (value) => saved['started'] = value,
              builder: (field) => MinimalFormField(
                errorText: field.errorText,
                focusNode: startNode,
                child: MinimalDatePicker(
                  labelText: 'Started',
                  mode: MinimalDatePickerMode.date,
                  value: field.value,
                  hintText: 'Not yet',
                  focusNode: startNode,
                  onChanged: field.didChange,
                ),
              ),
            ),
            RawFormField<bool>(
              focusNode: termsNode,
              initialValue: false,
              validator: (value) =>
                  value ?? false ? null : 'Accept the terms to go on',
              onSaved: (value) => saved['terms'] = value,
              builder: (field) => MinimalFormField(
                errorText: field.errorText,
                focusNode: termsNode,
                labelText: 'I accept the terms',
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: MinimalCheckbox(
                    value: field.value ?? false,
                    focusNode: termsNode,
                    onChanged: field.didChange,
                  ),
                ),
              ),
            ),
            RawFormField<String>(
              focusNode: planNode,
              validator: (value) => value == null ? 'Choose a plan' : null,
              onSaved: (value) => saved['plan'] = value,
              builder: (field) => MinimalFormField(
                labelText: 'Plan',
                group: true,
                errorText: field.errorText,
                focusNode: planNode,
                child: MinimalRadioGroup<String>(
                  value: field.value,
                  focusNode: planNode,
                  options: const [
                    MinimalRadioOption(value: 'free', label: 'Free'),
                    MinimalRadioOption(value: 'pro', label: 'Pro'),
                  ],
                  onChanged: field.didChange,
                ),
              ),
            ),
            Builder(
              builder: (context) => MinimalButton(
                'Save',
                onPressed: () => MinimalForm.submit(context),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

Future<_FormState> _pump(WidgetTester tester) async {
  tester.view
    ..physicalSize = const Size(390, 1200)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => MinimalHost(child: child!),
      home: const Scaffold(body: _Form()),
    ),
  );
  await tester.pumpAndSettle();
  return tester.state<_FormState>(find.byType(_Form));
}

const _errors = [
  'Choose how often',
  'Pick the day you started',
  'Accept the terms to go on',
  'Choose a plan',
];

void main() {
  testWidgets('a failed submit shows each error and focuses the first', (
    tester,
  ) async {
    final form = await _pump(tester);
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    for (final error in _errors) {
      expect(find.text(error), findsOneWidget, reason: error);
    }
    expect(form.repeatNode.hasFocus, isTrue);
    expect(form.submitted, 0);
  });

  testWidgets('the date picker and the radio group take the focus', (
    tester,
  ) async {
    final form = await _pump(tester);
    final field = tester.state<FormFieldState<String>>(
      find.byWidgetPredicate(
        (w) => w is RawFormField<String> && w.focusNode == form.repeatNode,
      ),
    );
    field.didChange('daily');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(form.startNode.hasFocus, isTrue);
    form.planNode.requestFocus();
    await tester.pump();
    expect(form.planNode.hasFocus, isTrue);
  });

  testWidgets('a date in error draws its edge in the danger colour', (
    tester,
  ) async {
    await _pump(tester);
    final theme = MinimalThemeData.standard();
    // The pill's rim: a rounded rectangle paints as a BoxDecoration.
    Color edge() {
      final box = tester
          .widgetList<Container>(
            find.descendant(
              of: find.byType(MinimalDatePicker),
              matching: find.byType(Container),
            ),
          )
          .map((c) => c.decoration)
          .whereType<BoxDecoration>()
          .firstWhere((d) => d.border != null);
      return (box.border! as Border).top.color;
    }

    expect(edge(), isNot(theme.destructive));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(edge(), theme.destructive);
  });

  testWidgets('errors follow their controls; a fine submit saves each', (
    tester,
  ) async {
    final form = await _pump(tester);
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(MinimalCheckbox));
    await tester.pumpAndSettle();
    expect(find.text('Accept the terms to go on'), findsNothing);
    await tester.tap(find.text('Pro'));
    await tester.pumpAndSettle();
    expect(find.text('Choose a plan'), findsNothing);
    for (final state in tester.stateList<FormFieldState<Object?>>(
      find.byWidgetPredicate((w) => w is RawFormField),
    )) {
      if (state.value == null) {
        state.didChange(
          state is FormFieldState<DateTime> ? DateTime(2026, 11, 9) : 'daily',
        );
      }
    }
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(form.submitted, 1);
    expect(form.saved, {
      'repeat': 'daily',
      'started': DateTime(2026, 11, 9),
      'terms': true,
      'plan': 'pro',
    });
  });
}
