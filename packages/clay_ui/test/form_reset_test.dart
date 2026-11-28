// What a form's reset() does to a Clay text field with a controller, as the
// README's forms section says: in a RawFormField the form keeps the field's
// value and error, and the controller keeps the words. reset() takes the error
// away and leaves the controller's text as it is; reset() and then clearing
// the controller empties the field, as the README's "clear the form after a
// save" snippet does.
import 'package:clay_ui/clay_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

class _Form extends StatefulWidget {
  const _Form({required this.formKey, required this.title, this.onAdd});

  final GlobalKey<RawFormState> formKey;
  final TextEditingController title;
  final ValueChanged<String>? onAdd;

  @override
  State<_Form> createState() => _FormState();
}

class _FormState extends State<_Form> {
  final _focus = FocusNode();

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ClayForm(
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
          builder: (field) => ClayTextField(
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

void main() {
  Future<(GlobalKey<RawFormState>, TextEditingController, List<String>)> pump(
    WidgetTester tester,
  ) async {
    final key = GlobalKey<RawFormState>();
    final title = TextEditingController();
    addTearDown(title.dispose);
    final added = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => ClayHost(child: child!),
        home: Scaffold(
          body: _Form(formKey: key, title: title, onAdd: added.add),
        ),
      ),
    );
    return (key, title, added);
  }

  testWidgets("reset() takes the error away and leaves the controller's text", (
    tester,
  ) async {
    final (key, title, _) = await pump(tester);
    key.currentState!.submit();
    await tester.pumpAndSettle();
    expect(find.text('Enter the title'), findsOneWidget);
    await tester.enterText(find.byType(EditableText), 'Middlemarch');
    key.currentState!.reset();
    await tester.pumpAndSettle();
    expect(title.text, 'Middlemarch');
    expect(find.text('Enter the title'), findsNothing);
  });

  testWidgets('a save that resets and clears the controller empties the form', (
    tester,
  ) async {
    final (key, title, added) = await pump(tester);
    await tester.enterText(find.byType(EditableText), 'Middlemarch');
    key.currentState!.submit();
    await tester.pumpAndSettle();
    expect(added, ['Middlemarch']);
    expect(title.text, isEmpty);
    expect(find.text('Middlemarch'), findsNothing);
    expect(find.text('Enter the title'), findsNothing);
  });
}
