// What a form's reset() does to a FrostedTextFormField with a controller, as
// its doc says and Material's TextFormField does: the field's initial value is
// the controller's text when it was last built, and reset() writes it back.
// Words typed since the last build go; words the page had built with come
// back. reset() and then clearing the controller empties the field, as the
// README's "clear the form after a save" snippet does.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;

void main() {
  late StateSetter rebuild;

  Future<(GlobalKey<FormState>, TextEditingController)> pump(
    WidgetTester tester,
  ) async {
    final key = GlobalKey<FormState>();
    final title = TextEditingController();
    addTearDown(title.dispose);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => FrostedHost(child: child!),
        home: FrostedScaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              rebuild = setState;
              return Form(
                key: key,
                child: FrostedTextFormField(
                  labelText: 'Title',
                  controller: title,
                  validator: (value) =>
                      (value ?? '').trim().isEmpty ? 'Enter the title' : null,
                ),
              );
            },
          ),
        ),
      ),
    );
    return (key, title);
  }

  testWidgets('reset() writes back the text the field was last built with', (
    tester,
  ) async {
    final (key, title) = await pump(tester);
    await tester.enterText(find.byType(EditableText), 'Middlemarch');
    key.currentState!.reset();
    await tester.pump();
    expect(title.text, isEmpty, reason: 'typed since the last build');

    await tester.enterText(find.byType(EditableText), 'Middlemarch');
    rebuild(() {});
    await tester.pump();
    await tester.enterText(find.byType(EditableText), 'Middlemarch, a study');
    key.currentState!.reset();
    await tester.pump();
    expect(
      title.text,
      'Middlemarch',
      reason: 'the text when it was last built',
    );
  });

  testWidgets('reset() and then clearing the controller empties the form', (
    tester,
  ) async {
    final (key, title) = await pump(tester);
    expect(key.currentState!.validate(), isFalse);
    await tester.pumpAndSettle();
    expect(find.text('Enter the title'), findsOneWidget);
    await tester.enterText(find.byType(EditableText), 'Middlemarch');
    rebuild(() {});
    await tester.pump();
    expect(key.currentState!.validate(), isTrue);
    key.currentState!.reset();
    title.clear();
    await tester.pumpAndSettle();
    expect(title.text, isEmpty);
    expect(find.text('Enter the title'), findsNothing);
    expect(
      key.currentState!.validate(),
      isFalse,
      reason: 'the empty field checks again',
    );
  });
}
