// A wrong field reads as wrong on the field itself: the danger's mark at its
// end, in the danger's ink, beside the glass's tint, its message under it.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:frosted_ui/src/frosted/internal/well.dart';

Future<void> _pump(WidgetTester t, Widget field) async {
  await t.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: (context, page) => FrostedHost(child: page!),
      home: Center(child: SizedBox(width: 360, child: field)),
    ),
  );
  await t.pumpAndSettle();
}

Finder _inWell(IconData glyph) => find.descendant(
  of: find.byType(FrostedWell),
  matching: find.byWidgetPredicate((w) => w is Icon && w.icon == glyph),
);

void main() {
  testWidgets('a wrong text field shows the danger mark at its end', (t) async {
    await _pump(t, const FrostedTextField(labelText: 'Title'));
    expect(_inWell(FrostedGlyphs.danger), findsNothing);
    await _pump(
      t,
      const FrostedTextField(labelText: 'Title', errorText: 'Enter the title'),
    );
    expect(_inWell(FrostedGlyphs.danger), findsOneWidget);
    final c = FrostedTheme.of(t.element(find.byType(FrostedWell))).colorScheme;
    expect(t.widget<Icon>(_inWell(FrostedGlyphs.danger)).color, c.over);
    // At the end of the well, past the entry.
    final well = t.getRect(find.byType(FrostedWell));
    final mark = t.getRect(_inWell(FrostedGlyphs.danger));
    expect(well.right - mark.right, lessThan(24));
  });

  testWidgets('a wrong text form field shows it once it is checked', (t) async {
    final key = GlobalKey<FormState>();
    await _pump(
      t,
      Form(
        key: key,
        child: FrostedTextFormField(
          labelText: 'Title',
          validator: (v) => (v ?? '').isEmpty ? 'Enter the title' : null,
        ),
      ),
    );
    expect(_inWell(FrostedGlyphs.danger), findsNothing);
    key.currentState!.validate();
    await t.pumpAndSettle();
    expect(_inWell(FrostedGlyphs.danger), findsOneWidget);
  });

  testWidgets('a wrong date field shows the mark in its calendar\'s place', (
    t,
  ) async {
    await _pump(
      t,
      FrostedDateField(labelText: 'Started', value: null, onChanged: (_) {}),
    );
    expect(_inWell(FrostedGlyphs.calendar), findsOneWidget);
    expect(_inWell(FrostedGlyphs.danger), findsNothing);
    await _pump(
      t,
      FrostedDateField(
        labelText: 'Started',
        value: null,
        errorText: 'Choose the day',
        onChanged: (_) {},
      ),
    );
    expect(_inWell(FrostedGlyphs.calendar), findsNothing);
    expect(_inWell(FrostedGlyphs.danger), findsOneWidget);
  });
}
