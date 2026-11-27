// Forms, as Material's are: in one column every field takes the column's width (a select, a combobox, a
// multi-select, a picker's field, a date field); a text field takes part in its Form (validator, onSaved, reset); a date
// field holds no day until one is chosen; a field that fails carries the look's error mark, raised on a bead warmed by
// the pigment, as an error notice's is; a destructive act never takes the pigment of the page's one act; and every
// field names itself in one label style.
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter_test/flutter_test.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

Future<void> _pump(
  WidgetTester t,
  Widget child, {
  double width = 1440,
  double column = 760,
}) async {
  t.view.physicalSize = Size(width, 1200);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: (context, page) =>
          NeumorphicHost(brightness: Brightness.light, child: page!),
      home: Material(
        type: MaterialType.transparency,
        child: SingleChildScrollView(
          child: Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(width: column, child: child),
            ),
          ),
        ),
      ),
    ),
  );
  await t.pumpAndSettle();
}

const _options = [
  NeumorphicMenuItem('s', 'Small'),
  NeumorphicMenuItem('m', 'Medium'),
];

void main() {
  for (final width in [390.0, 1440.0]) {
    final column = width < 600 ? 342.0 : 760.0;
    testWidgets('at ${width.toInt()} every field takes the column', (t) async {
      final key = GlobalKey();
      await _pump(
        t,
        width: width,
        column: column,
        Column(
          key: key,
          spacing: 16,
          children: [
            NeumorphicTextField(labelText: 'Title', onChanged: (_) {}),
            NeumorphicSelect<String>(
              labelText: 'Size',
              value: 'm',
              options: _options,
              onChanged: (_) {},
            ),
            NeumorphicDateField(
              labelText: 'Started',
              value: null,
              onChanged: (_) {},
            ),
            NeumorphicSelectField(value: 'Oak', onPressed: () {}),
          ],
        ),
      );
      final left = t.getTopLeft(find.byKey(key)).dx;
      for (final type in [
        NeumorphicTextField,
        NeumorphicSelect<String>,
        NeumorphicDateField,
        NeumorphicSelectField,
      ]) {
        final face = find.descendant(
          of: find.byType(type),
          matching: find.byType(NeumorphicFieldBox),
        );
        final r = t.getRect(
          face.evaluate().isEmpty
              ? find
                    .descendant(
                      of: find.byType(type),
                      matching: find.byType(NeumorphicTap),
                    )
                    .first
              : face.first,
        );
        expect(r.left, moreOrLessEquals(left, epsilon: 1), reason: '$type');
        expect(r.width, moreOrLessEquals(column, epsilon: 1), reason: '$type');
      }
    });
  }

  testWidgets('a select alone in a row keeps to its content', (t) async {
    await _pump(
      t,
      Row(
        children: [
          NeumorphicSelect<String>(
            value: 'm',
            options: _options,
            onChanged: (_) {},
          ),
        ],
      ),
    );
    expect(
      t.getSize(find.byType(NeumorphicSelect<String>)).width,
      lessThan(300),
    );
  });

  testWidgets('a text form field validates, saves and resets in its Form', (
    t,
  ) async {
    final form = GlobalKey<FormState>();
    String? saved;
    await _pump(
      t,
      Form(
        key: form,
        child: NeumorphicTextFormField(
          labelText: 'Title',
          initialValue: 'Dune',
          validator: (v) => (v ?? '').trim().isEmpty ? 'Enter the title' : null,
          onSaved: (v) => saved = v,
        ),
      ),
    );
    await t.enterText(find.byType(EditableText), '');
    expect(form.currentState!.validate(), isFalse);
    await t.pump();
    expect(find.text('Enter the title'), findsOneWidget);
    await t.enterText(find.byType(EditableText), 'Piranesi');
    expect(form.currentState!.validate(), isTrue);
    form.currentState!.save();
    expect(saved, 'Piranesi');
    form.currentState!.reset();
    await t.pump();
    expect(find.text('Dune'), findsOneWidget);
    expect(find.text('Enter the title'), findsNothing);
  });

  testWidgets('a date field holds no day until one is chosen', (t) async {
    final semantics = t.ensureSemantics();
    DateTime? day;
    await _pump(
      t,
      StatefulBuilder(
        builder: (context, setState) => NeumorphicDateField(
          labelText: 'Started',
          value: day,
          hintText: 'Not yet',
          firstDate: DateTime(2026, 11),
          lastDate: DateTime(2026, 11, 30),
          onChanged: (v) => setState(() => day = v),
        ),
      ),
    );
    expect(find.text('Not yet'), findsOneWidget);
    await t.tap(find.text('Not yet'));
    await t.pumpAndSettle();
    await t.tap(find.text('12').last);
    await t.pumpAndSettle();
    // The sheet returns the day only when it is confirmed.
    await t.tap(find.text('Choose').last);
    await t.pumpAndSettle();
    expect(day, DateTime(2026, 11, 12));
    // The day with its year, as a field shows one.
    expect(find.textContaining('2026'), findsOneWidget);
    expect(
      t.getSemantics(
        find
            .descendant(
              of: find.byType(NeumorphicDateField),
              matching: find.byType(NeumorphicTap),
            )
            .first,
      ),
      isSemantics(
        label: 'Started',
        value: NeumorphicFormat.mediumDate(
          t.element(find.byType(NeumorphicDateField)),
          DateTime(2026, 11, 12),
        ),
        isButton: true,
      ),
    );
    semantics.dispose();
  });

  bool beaded(WidgetTester t, Finder mark) => t
      .widgetList<CustomPaint>(
        find.ancestor(of: mark, matching: find.byType(CustomPaint)),
      )
      .any((p) => p.painter.runtimeType.toString().contains('Bead'));

  testWidgets("a field that fails carries the look's error mark on a bead", (
    t,
  ) async {
    await _pump(
      t,
      Column(
        children: [
          const NeumorphicTextField(
            labelText: 'Title',
            errorText: 'Enter the title',
          ),
          NeumorphicSelect<String>(
            labelText: 'Size',
            options: _options,
            errorText: 'Choose a size',
            onChanged: (_) {},
          ),
        ],
      ),
    );
    final marks = find.byIcon(NeumorphicGlyphs.triangleAlert);
    // The text field's own mark at its end, and each field's line under it.
    expect(marks, findsNWidgets(3));
    for (final mark in marks.evaluate()) {
      expect(beaded(t, find.byWidget(mark.widget)), isTrue);
    }
  });

  testWidgets("a destructive act never takes the page's pigment", (t) async {
    await _pump(
      t,
      Row(
        children: [
          NeumorphicButton.filled('Save', onPressed: () {}),
          NeumorphicButton.filled(
            'Delete',
            isDestructiveAction: true,
            onPressed: () {},
          ),
        ],
      ),
    );
    Color ink(String words) =>
        t.renderObject<RenderParagraph>(find.text(words)).text.style!.color!;
    final c = NeumorphicTheme.of(t.element(find.text('Save'))).colors;
    expect(ink('Save'), c.onAccent);
    expect(ink('Delete'), isNot(c.onAccent));
  });

  testWidgets('every field names itself in one label style', (t) async {
    await _pump(
      t,
      Column(
        spacing: 16,
        children: [
          NeumorphicTextField(labelText: 'Title', onChanged: (_) {}),
          NeumorphicSelect<String>(
            labelText: 'Size',
            value: 'm',
            options: _options,
            onChanged: (_) {},
          ),
          NeumorphicDateField(
            labelText: 'Started',
            value: null,
            onChanged: (_) {},
          ),
          NeumorphicFormField(
            labelText: 'Palette',
            child: NeumorphicRadioGroup<String>(
              semanticLabel: 'Palette',
              value: 's',
              options: const [
                NeumorphicRadio('s', 'Small'),
                NeumorphicRadio('m', 'Medium'),
              ],
              onChanged: (_) {},
            ),
          ),
          NeumorphicFormField(
            labelText: 'Appearance',
            child: NeumorphicSegmentedButton<String>(
              semanticLabel: 'Appearance',
              value: 's',
              segments: const [
                NeumorphicButtonSegment('s', 'Light'),
                NeumorphicButtonSegment('m', 'Dark'),
              ],
              onChanged: (_) {},
            ),
          ),
          const NeumorphicFormField(
            labelText: 'Notes',
            child: SizedBox(height: 20),
          ),
        ],
      ),
    );
    TextStyle style(String words) =>
        t.renderObject<RenderParagraph>(find.text(words).first).text.style!;
    final first = style('Title');
    for (final words in ['Size', 'Started', 'Palette', 'Appearance', 'Notes']) {
      final s = style(words);
      expect(
        (s.fontSize, s.fontWeight, s.color),
        (first.fontSize, first.fontWeight, first.color),
        reason: words,
      );
    }
  });
}
