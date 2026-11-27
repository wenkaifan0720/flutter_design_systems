// Keycap's fields in one column: every field takes the column's width, a select and a date key too; a text field
// checks itself in a form, as TextFormField does; a footer's keys stand on the page's column; a date with its year, as the
// date key shows it.
import 'package:material_ui/material_ui.dart' show MaterialApp;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keycap_ui/keycap_ui.dart';

Widget _app(Widget child) => MaterialApp(
  debugShowCheckedModeBanner: false,
  builder: (context, page) =>
      KeycapHost(brightness: Brightness.light, child: page!),
  home: child,
);

Future<void> _desk(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(1440, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(_app(child));
  await tester.pump(const Duration(seconds: 1));
}

Rect _field(WidgetTester tester, Finder of) => tester.getRect(
  find.descendant(of: of, matching: find.byType(KeycapField)).first,
);

void main() {
  testWidgets(
    'on a desk a select and a date key stand on their column\'s edges, as a text field does',
    (tester) async {
      await _desk(
        tester,
        KeycapScreen(
          maxWidth: 560,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const KeycapTextField(labelText: 'Title'),
              KeycapSelect<String>(
                labelText: 'Status',
                value: 'reading',
                items: const [
                  KeycapSelectItem(value: 'reading', label: 'Reading'),
                ],
                onChanged: (_) {},
              ),
              KeycapDatePicker(
                labelText: 'Started',
                value: null,
                firstDate: DateTime(2000),
                lastDate: DateTime(2030),
                onChanged: (_) {},
              ),
            ],
          ),
        ),
      );
      final text = _field(tester, find.byType(KeycapTextField));
      for (final other in [
        find.byType(KeycapSelect<String>),
        find.byType(KeycapDatePicker),
      ]) {
        final r = _field(tester, other);
        expect(r.left, text.left, reason: '$other');
        expect(r.right, text.right, reason: '$other');
      }
    },
  );

  testWidgets(
    'a text field checks itself in a form: its error under it, the focus to it',
    (tester) async {
      final form = GlobalKey<RawFormState>();
      var sent = 0;
      String? saved;
      await _desk(
        tester,
        KeycapScreen(
          body: RawForm(
            key: form,
            onSubmit: () => sent++,
            child: KeycapTextField(
              labelText: 'Title',
              validator: (v) =>
                  (v ?? '').trim().isEmpty ? 'Enter the title' : null,
              onSaved: (v) => saved = v,
            ),
          ),
        ),
      );
      expect(form.currentState!.submit(), isFalse);
      await tester.pump();
      expect(find.text('Enter the title'), findsOneWidget);
      expect(sent, 0);
      expect(
        FocusManager.instance.primaryFocus?.context
            ?.findAncestorWidgetOfExactType<KeycapTextField>(),
        isNotNull,
      );
      await tester.enterText(find.byType(EditableText), 'Piranesi');
      await tester.pump();
      expect(form.currentState!.submit(), isTrue);
      await tester.pump();
      expect(find.text('Enter the title'), findsNothing);
      expect(sent, 1);
      expect(saved, 'Piranesi');
    },
  );

  testWidgets("on a desk a footer's keys stand on the page's column", (
    tester,
  ) async {
    await _desk(
      tester,
      KeycapScreen(
        maxWidth: 560,
        topBar: const KeycapAppBar(title: 'Add a book'),
        body: const KeycapTextField(labelText: 'Title'),
        footer: KeycapButton.accent(
          onPressed: () {},
          child: const Text('Save'),
        ),
      ),
    );
    final field = _field(tester, find.byType(KeycapTextField));
    final save = tester.getRect(find.byType(KeycapButton));
    expect(save.right, lessThanOrEqualTo(field.right + 0.5));
    expect(save.left, greaterThanOrEqualTo(field.left - 0.5));
  });

  testWidgets('a date with its year, as the date key shows it', (tester) async {
    late String said;
    final day = DateTime(2026, 1, 4);
    await _desk(
      tester,
      KeycapScreen(
        body: Builder(
          builder: (context) {
            said = KeycapFormat.date(context, day);
            return KeycapDatePicker(
              labelText: 'Started',
              value: day,
              firstDate: DateTime(2000),
              lastDate: DateTime(2030),
              onChanged: (_) {},
            );
          },
        ),
      ),
    );
    expect(said, 'Jan 4, 2026');
    expect(find.text(said), findsOneWidget);
  });
}
