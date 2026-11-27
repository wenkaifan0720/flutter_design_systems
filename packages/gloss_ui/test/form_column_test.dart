// In one column every field takes the column's width: a select at a desk's
// width too. A text field takes part in a form (TextFormField parity): its
// validator's message stands under the well in ruby, saving hands the words
// over and resetting brings the first words back.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gloss_ui/gloss_ui.dart';

Future<void> _show(WidgetTester t, double width, Widget body) async {
  t.view.devicePixelRatio = 1;
  t.view.physicalSize = Size(width, 900);
  addTearDown(t.view.reset);
  await t.pumpWidget(
    WidgetsApp(
      color: const Color(0xFF0E7652),
      // A text field's selection floats on the app's overlay.
      builder: (context, _) => Overlay(
        initialEntries: [
          OverlayEntry(
            builder: (context) => GlossTheme(
              data: GlossThemeData.preset('jade', Brightness.light),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [body],
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
  await t.pumpAndSettle();
}

void main() {
  for (final width in [390.0, 1440.0]) {
    testWidgets('a select takes its column at ${width.toInt()}', (t) async {
      await _show(
        t,
        width,
        GlossSelect<String>(
          labelText: 'Palette',
          helperText: 'The colour of the gel in every place',
          value: 'jade',
          items: const [
            GlossSelectItem(value: 'jade', label: 'Jade'),
            GlossSelectItem(value: 'rose', label: 'Rose'),
          ],
          onChanged: (_) {},
        ),
      );
      // The select's well: the widest surface it paints.
      final wells = find
          .descendant(
            of: find.byType(GlossSelect<String>),
            matching: find.byType(GlossSurface),
          )
          .evaluate()
          .map((e) => e.size!.width);
      expect(wells.reduce((a, b) => a > b ? a : b), width - 48);
    });
  }

  testWidgets("a text form field shows its validator's message and saves", (
    t,
  ) async {
    final form = GlobalKey<FormState>();
    String? saved;
    await _show(
      t,
      390,
      Form(
        key: form,
        child: GlossTextFormField(
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
    final field = t.widget<GlossTextField>(find.byType(GlossTextField));
    expect(field.errorText, 'Enter the title');

    await t.enterText(find.byType(EditableText), 'Emma');
    expect(form.currentState!.validate(), isTrue);
    form.currentState!.save();
    expect(saved, 'Emma');

    form.currentState!.reset();
    await t.pump();
    expect(find.text('Dune'), findsOneWidget);
  });

  testWidgets('a text form field validates as the reader types when asked', (
    t,
  ) async {
    await _show(
      t,
      390,
      GlossTextFormField(
        labelText: 'Pages',
        autovalidateMode: AutovalidateMode.onUserInteraction,
        validator: (v) =>
            int.tryParse(v ?? '') == null ? 'Enter a number' : null,
      ),
    );
    expect(find.text('Enter a number'), findsNothing);
    await t.enterText(find.byType(EditableText), 'many');
    await t.pump();
    expect(find.text('Enter a number'), findsOneWidget);
  });
}
