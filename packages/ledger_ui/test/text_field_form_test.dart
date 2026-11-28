// What a form does to a LedgerTextField with a controller, as its doc and the
// README's Forms section say. It is not a form field itself: a Material
// Form's reset() and validate() pass it by. In a RawFormField under a
// RawForm, reset() takes the error away and leaves the controller's text;
// reset() and then clearing the controller empties the field, as the
// README's QuickAdd does. The README's AddBookPage empties its title after a
// save by clearing the controller.
import 'package:flutter_test/flutter_test.dart';
import 'package:ledger_ui/ledger_ui.dart';
import 'package:material_ui/material_ui.dart';

class _QuickAdd extends StatefulWidget {
  const _QuickAdd({required this.formKey, required this.title, this.onAdd});

  final GlobalKey<RawFormState> formKey;
  final TextEditingController title;
  final ValueChanged<String>? onAdd;

  @override
  State<_QuickAdd> createState() => _QuickAddState();
}

class _QuickAddState extends State<_QuickAdd> {
  final _focus = FocusNode();

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RawForm(
    key: widget.formKey,
    onSubmit: () {
      widget.onAdd?.call(widget.title.text.trim());
      widget.formKey.currentState!.reset();
      widget.title.clear();
    },
    child: Column(
      children: [
        RawFormField<String>(
          focusNode: _focus,
          validator: (_) =>
              widget.title.text.trim().isEmpty ? 'Enter the title' : null,
          builder: (field) => LedgerTextField(
            labelText: 'Title',
            controller: widget.title,
            focusNode: _focus,
            errorText: field.errorText,
            onChanged: field.didChange,
          ),
        ),
      ],
    ),
  );
}

Future<void> _pump(WidgetTester tester, Widget page) => tester.pumpWidget(
  MaterialApp(
    builder: (context, child) => LedgerHost(child: child!),
    home: page,
  ),
);

void main() {
  testWidgets("a Material Form's reset() and validate() pass it by", (
    tester,
  ) async {
    final form = GlobalKey<FormState>();
    final title = TextEditingController();
    addTearDown(title.dispose);
    await _pump(
      tester,
      LedgerScreen(
        body: Form(
          key: form,
          child: LedgerTextField(labelText: 'Title', controller: title),
        ),
      ),
    );
    await tester.enterText(find.byType(EditableText), 'Emma');
    form.currentState!.reset();
    await tester.pump();
    expect(title.text, 'Emma');
    expect(form.currentState!.validate(), isTrue);
  });

  testWidgets(
    "in a RawFormField, reset() takes the error away and leaves the controller's text",
    (tester) async {
      final key = GlobalKey<RawFormState>();
      final title = TextEditingController();
      addTearDown(title.dispose);
      await _pump(
        tester,
        LedgerScreen(
          body: _QuickAdd(formKey: key, title: title),
        ),
      );
      key.currentState!.submit();
      await tester.pumpAndSettle();
      expect(find.text('Enter the title'), findsOneWidget);
      await tester.enterText(find.byType(EditableText), 'Middlemarch');
      key.currentState!.reset();
      await tester.pumpAndSettle();
      expect(title.text, 'Middlemarch');
      expect(find.text('Enter the title'), findsNothing);
    },
  );

  testWidgets('a save that resets and clears the controller empties the form', (
    tester,
  ) async {
    final key = GlobalKey<RawFormState>();
    final title = TextEditingController();
    addTearDown(title.dispose);
    final added = <String>[];
    await _pump(
      tester,
      LedgerScreen(
        body: _QuickAdd(formKey: key, title: title, onAdd: added.add),
      ),
    );
    await tester.enterText(find.byType(EditableText), 'Middlemarch');
    key.currentState!.submit();
    await tester.pumpAndSettle();
    expect(added, ['Middlemarch']);
    expect(title.text, isEmpty);
    expect(find.text('Middlemarch'), findsNothing);
    expect(find.text('Enter the title'), findsNothing);
  });

  testWidgets(
    "clearing the controller after a save empties the README's AddBookPage title",
    (tester) async {
      final title = TextEditingController();
      addTearDown(title.dispose);
      final saved = <String>[];
      await _pump(
        tester,
        LedgerScreen.form(
          body: Column(
            children: [
              LedgerTextField(labelText: 'Title', controller: title),
              LedgerButton.filled(
                'Save book',
                onPressed: () {
                  saved.add(title.text.trim());
                  title.clear();
                },
              ),
            ],
          ),
        ),
      );
      await tester.enterText(find.byType(EditableText), 'Middlemarch');
      await tester.tap(find.text('Save book'));
      await tester.pumpAndSettle();
      expect(saved, ['Middlemarch']);
      expect(find.text('Middlemarch'), findsNothing);
    },
  );
}
