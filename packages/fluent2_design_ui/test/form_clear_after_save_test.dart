// A text form field with a controller: reset() puts back the controller's
// text from the field's last build, and reset() then clearing the
// controllers empties the form after a save, errors and all.
import 'package:flutter_test/flutter_test.dart';
import 'package:fluent2_design_ui/fluent2_design_ui.dart';
import 'package:material_ui/material_ui.dart';

Future<BuildContext> _pump(
  WidgetTester tester,
  TextEditingController title,
) async {
  late BuildContext form;
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => Fluent2Host(child: child!),
      home: Fluent2Scaffold(
        body: Fluent2Form(
          child: Builder(
            builder: (context) {
              form = context;
              return Fluent2FormSection(
                children: [
                  Fluent2TextFormField(
                    controller: title,
                    labelText: 'Title',
                    validator: (value) =>
                        (value ?? '').trim().isEmpty ? 'Enter the title' : null,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    ),
  );
  return form;
}

String _shown(WidgetTester tester) =>
    tester.widget<EditableText>(find.byType(EditableText)).controller.text;

void main() {
  testWidgets("reset() restores the controller's text from the last build", (
    tester,
  ) async {
    final title = TextEditingController(text: 'Dune');
    addTearDown(title.dispose);
    final form = await _pump(tester, title);
    await tester.enterText(find.byType(EditableText), 'Dune Messiah');
    await tester.pump();
    expect(title.text, 'Dune Messiah');

    Fluent2Form.reset(form);
    await tester.pump();
    await tester.pump();
    expect(title.text, 'Dune');
    expect(_shown(tester), 'Dune');
  });

  testWidgets('reset() then clearing the controllers empties the form', (
    tester,
  ) async {
    final title = TextEditingController();
    addTearDown(title.dispose);
    final form = await _pump(tester, title);

    // A failed submit shows the error and checks as the text is edited.
    expect(Fluent2Form.submit(form), isFalse);
    await tester.pump();
    expect(find.text('Enter the title'), findsOneWidget);
    await tester.enterText(find.byType(EditableText), 'Dune');
    await tester.pump();
    expect(Fluent2Form.submit(form), isTrue);

    Fluent2Form.reset(form);
    title.clear();
    await tester.pump();
    await tester.pump();
    expect(title.text, isEmpty);
    expect(_shown(tester), isEmpty);
    expect(find.text('Enter the title'), findsNothing);
  });
}
