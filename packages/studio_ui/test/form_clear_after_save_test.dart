// A text form field with a controller: reset() puts back the controller's
// text from the field's last build, and reset() then clearing the
// controllers empties the form after a save, errors and all.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studio_ui/studio_ui.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;

Future<BuildContext> _pump(
  WidgetTester tester,
  TextEditingController title,
) async {
  late BuildContext form;
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => StudioHost(child: child!),
      home: StudioScreen(
        body: StudioForm(
          child: Builder(
            builder: (context) {
              form = context;
              return StudioTextFormField(
                controller: title,
                labelText: 'Title',
                validator: (value) =>
                    (value ?? '').trim().isEmpty ? 'Enter the title' : null,
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
    final title = TextEditingController(text: 'Room tone');
    addTearDown(title.dispose);
    final form = await _pump(tester, title);
    await tester.enterText(find.byType(EditableText), 'Room tone, take 2');
    await tester.pump();
    expect(title.text, 'Room tone, take 2');

    StudioForm.reset(form);
    await tester.pump();
    await tester.pump();
    expect(title.text, 'Room tone');
    expect(_shown(tester), 'Room tone');
  });

  testWidgets('reset() then clearing the controllers empties the form', (
    tester,
  ) async {
    final title = TextEditingController();
    addTearDown(title.dispose);
    final form = await _pump(tester, title);

    expect(StudioForm.submit(form), isFalse);
    await tester.pump();
    expect(find.text('Enter the title'), findsOneWidget);
    await tester.enterText(find.byType(EditableText), 'Room tone');
    await tester.pump();
    expect(StudioForm.submit(form), isTrue);

    StudioForm.reset(form);
    title.clear();
    await tester.pump();
    await tester.pump();
    expect(title.text, isEmpty);
    expect(_shown(tester), isEmpty);
    expect(find.text('Enter the title'), findsNothing);
  });
}
