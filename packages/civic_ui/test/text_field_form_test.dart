// What a form does with CivicTextField, as its doc and the README say: the
// field is not a FormField, so a Form's reset() and validate() pass it by and
// its text stays; clearing its controller empties it. The README's Forms
// snippet clears the form after a save that way.
import 'package:civic_ui/civic_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

// The README's Forms snippet, its save trimmed to what it clears.
class _BookForm extends StatefulWidget {
  const _BookForm({required this.saved});

  final List<String> saved;

  @override
  State<_BookForm> createState() => _BookFormState();
}

class _BookFormState extends State<_BookForm> {
  final _title = TextEditingController();
  String? _titleError;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  void _save() {
    setState(
      () => _titleError = _title.text.trim().isEmpty
          ? 'Enter the book’s title'
          : null,
    );
    if (_titleError != null) return;
    widget.saved.add(_title.text.trim());
    _title.clear();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: CivicSpacing.s24,
    children: [
      CivicTextField(
        labelText: 'Title',
        controller: _title,
        errorText: _titleError,
      ),
      CivicButton(onPressed: _save, child: const Text('Save book')),
    ],
  );
}

Widget _app(Widget home) => MaterialApp(
  builder: (context, child) => CivicHost(child: child!),
  home: Material(child: home),
);

String _shown(WidgetTester tester) =>
    tester.widget<EditableText>(find.byType(EditableText)).controller.text;

void main() {
  testWidgets("a Form's reset() and validate() pass the field by", (
    tester,
  ) async {
    final form = GlobalKey<FormState>();
    final title = TextEditingController(text: 'Middlemarch');
    addTearDown(title.dispose);
    await tester.pumpWidget(
      _app(
        Form(
          key: form,
          child: CivicTextField(labelText: 'Title', controller: title),
        ),
      ),
    );
    await tester.enterText(find.byType(EditableText), 'Emma');
    await tester.pump();
    form.currentState!.reset();
    await tester.pump();
    expect(title.text, 'Emma');
    expect(_shown(tester), 'Emma');
    expect(form.currentState!.validate(), isTrue);
    title.clear();
    await tester.pump();
    expect(_shown(tester), isEmpty);
  });

  testWidgets("the README's form is empty again after a save", (tester) async {
    final saved = <String>[];
    await tester.pumpWidget(_app(_BookForm(saved: saved)));
    await tester.tap(find.text('Save book'));
    await tester.pumpAndSettle();
    expect(find.text('Enter the book’s title'), findsOneWidget);
    await tester.enterText(find.byType(EditableText), 'Persuasion');
    await tester.tap(find.text('Save book'));
    await tester.pumpAndSettle();
    expect(saved, ['Persuasion']);
    expect(_shown(tester), isEmpty);
    expect(find.text('Enter the book’s title'), findsNothing);
  });
}
