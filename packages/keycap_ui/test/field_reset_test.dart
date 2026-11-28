// A text field with a controller in a form: reset() clears the errors and the
// field's saved value, the text stays the controller's; clearing the
// controller empties the field. As the README's "clear the form after a save"
// snippet does it.
import 'package:material_ui/material_ui.dart' show MaterialApp;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keycap_ui/keycap_ui.dart';

void main() {
  testWidgets('reset() clears the error and keeps the controller\'s text; '
      'clear() empties the field', (tester) async {
    final form = GlobalKey<RawFormState>();
    final title = TextEditingController();
    addTearDown(title.dispose);
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        builder: (context, page) =>
            KeycapHost(brightness: Brightness.light, child: page!),
        home: KeycapScreen(
          body: RawForm(
            key: form,
            child: KeycapTextField(
              labelText: 'Title',
              controller: title,
              validator: (v) =>
                  (v ?? '').length > 12 ? 'Twelve letters at most' : null,
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    String shown() =>
        tester.widget<EditableText>(find.byType(EditableText)).controller.text;

    await tester.enterText(find.byType(EditableText), 'The Left Hand');
    await tester.pump();
    expect(form.currentState!.submit(), isFalse);
    await tester.pump();
    expect(find.text('Twelve letters at most'), findsOneWidget);

    form.currentState!.reset();
    await tester.pump();
    expect(find.text('Twelve letters at most'), findsNothing);
    expect(title.text, 'The Left Hand');
    expect(shown(), 'The Left Hand');

    title.clear();
    await tester.pump();
    expect(shown(), isEmpty);
    expect(find.text('The Left Hand'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
