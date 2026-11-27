// Forms: in a form's column every field takes the column's width (a select
// and a date field as a text field does; one alone on a page, as a
// toolbar's filter, keeps its own width),
// Fluent2TextFormField validates in a Fluent2Form as Flutter's TextFormField
// does in a Form, its error read as the field's, and the date field takes an
// unset value and prints a medium date with its year.
import 'package:material_ui/material_ui.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluent2_design_ui/fluent2_design_ui.dart';
import 'package:fluent2_design_ui/src/fluent2_design/components/input/field_core.dart'
    show Fluent2FieldButton;

Widget _app(Widget child) => MaterialApp(
  debugShowCheckedModeBanner: false,
  builder: (context, page) =>
      Fluent2Host(brightness: Brightness.light, child: page!),
  home: Fluent2Scaffold(
    body: Align(
      alignment: AlignmentDirectional.topStart,
      child: SizedBox(width: 560, child: child),
    ),
  ),
);

Future<void> _wide(WidgetTester tester) async {
  tester.view
    ..physicalSize = const Size(1440, 900)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

const _options = [
  Fluent2Option('fiction', 'Fiction'),
  Fluent2Option('history', 'History'),
];

void main() {
  testWidgets('in a form a select and a date field take its column\'s width, '
      'as a text field does', (tester) async {
    await _wide(tester);
    await tester.pumpWidget(
      _app(
        Fluent2Form(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: Fluent2Spacing.l,
            children: [
              Fluent2FormField(
                labelText: 'Title',
                child: Fluent2TextField(
                  key: const Key('text'),
                  onChanged: (_) {},
                ),
              ),
              Fluent2FormField(
                labelText: 'Shelf',
                child: Fluent2Select<String>(
                  key: const Key('select'),
                  value: null,
                  options: _options,
                  onChanged: (_) {},
                ),
              ),
              Fluent2FormField(
                labelText: 'Started',
                child: Fluent2DatePicker(
                  key: const Key('date'),
                  value: null,
                  onChanged: (_) {},
                ),
              ),
            ],
          ),
        ),
      ),
    );
    final text = tester.getRect(find.byKey(const Key('text')));
    for (final key in const ['select', 'date']) {
      final rect = tester.getRect(find.byKey(Key(key)));
      expect(rect.width, moreOrLessEquals(560, epsilon: 0.5), reason: key);
      expect(rect.left, moreOrLessEquals(text.left, epsilon: 0.5), reason: key);
      expect(
        rect.right,
        moreOrLessEquals(text.right, epsilon: 0.5),
        reason: key,
      );
    }
  });

  testWidgets('outside a form a select keeps its own width, 250 to 320, in a '
      'column or a Row', (tester) async {
    await _wide(tester);
    for (final row in const [false, true]) {
      final select = Fluent2Select<String>(
        key: const Key('select'),
        value: 'fiction',
        options: _options,
        onChanged: (_) {},
      );
      await tester.pumpWidget(
        _app(
          row
              ? Row(children: [select])
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [select],
                ),
        ),
      );
      // Its face: the select's own box stretches with the column round it.
      final face = find.descendant(
        of: find.byKey(const Key('select')),
        matching: find.byType(Fluent2FieldButton),
      );
      final width = tester.getSize(face).width;
      expect(width, inInclusiveRange(250, 320), reason: row ? 'row' : 'column');
    }
  });

  testWidgets('a form section is a form\'s column: its select spans it', (
    tester,
  ) async {
    await _wide(tester);
    await tester.pumpWidget(
      _app(
        Fluent2FormSection(
          title: 'Book',
          children: [
            Fluent2FormField(
              labelText: 'Title',
              child: Fluent2TextField(
                key: const Key('text'),
                onChanged: (_) {},
              ),
            ),
            Fluent2FormField(
              labelText: 'Shelf',
              child: Fluent2Select<String>(
                key: const Key('select'),
                value: null,
                options: _options,
                onChanged: (_) {},
              ),
            ),
          ],
        ),
      ),
    );
    expect(
      tester.getSize(find.byKey(const Key('select'))).width,
      moreOrLessEquals(
        tester.getSize(find.byKey(const Key('text'))).width,
        epsilon: 0.5,
      ),
    );
  });

  testWidgets('Fluent2TextFormField validates, reads its error, saves and '
      'resets in a form', (tester) async {
    final semantics = tester.ensureSemantics();
    String? saved;
    var submitted = 0;
    late BuildContext formContext;
    await tester.pumpWidget(
      _app(
        Fluent2Form(
          onSubmit: () => submitted++,
          child: Builder(
            builder: (context) {
              formContext = context;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: Fluent2Spacing.l,
                children: [
                  Fluent2TextFormField(
                    labelText: 'Title',
                    required: true,
                    validator: (value) =>
                        (value ?? '').trim().isEmpty ? 'Enter a title' : null,
                    onSaved: (value) => saved = value,
                  ),
                  const Fluent2TextFormField(labelText: 'Author'),
                ],
              );
            },
          ),
        ),
      ),
    );

    expect(Fluent2Form.submit(formContext), isFalse);
    await tester.pumpAndSettle();
    expect(find.text('Enter a title'), findsOneWidget);
    expect(submitted, 0);
    final title = find.byType(EditableText).first;
    // The failed submit moved focus to the wrong field, which reads its
    // error once, as its own.
    expect(tester.widget<EditableText>(title).focusNode.hasFocus, isTrue);
    final node = tester.getSemantics(title);
    expect(node.label, contains('Title'));
    expect(node.hint, contains('Enter a title'));
    expect('Title'.allMatches(node.label).length, 1);
    expect(
      node.getSemanticsData().validationResult,
      SemanticsValidationResult.invalid,
    );

    await tester.enterText(title, 'Stoner');
    await tester.pumpAndSettle();
    expect(find.text('Enter a title'), findsNothing);

    expect(Fluent2Form.submit(formContext), isTrue);
    expect(saved, 'Stoner');
    expect(submitted, 1);

    Fluent2Form.reset(formContext);
    await tester.pumpAndSettle();
    expect(tester.widget<EditableText>(title).controller.text, isEmpty);
    semantics.dispose();
  });

  testWidgets('the date field takes an unset value and prints a medium date '
      'with its year', (tester) async {
    await _wide(tester);
    DateTime? picked;
    await tester.pumpWidget(
      _app(
        StatefulBuilder(
          builder: (context, setState) => Fluent2DatePicker(
            hintText: 'Choose a date',
            today: DateTime(2026, 11, 26),
            value: picked,
            onChanged: (value) => setState(() => picked = value),
          ),
        ),
      ),
    );
    expect(find.text('Choose a date'), findsOneWidget);
    await tester.tap(find.text('Choose a date'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('18'));
    await tester.pumpAndSettle();
    expect(picked, DateTime(2026, 11, 18));
    final medium = Fluent2Format.date(DateTime(2026, 11, 18), year: true);
    expect(medium, 'Nov 18, 2026');
    expect(find.text(medium), findsOneWidget);
  });
}
