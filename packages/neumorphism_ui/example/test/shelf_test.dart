// The example app, Shelf, does what its pages say: a book opens its page
// beside the places, a delete asks first and pops with the answer, the form
// says what is missing and saves what is there, and settings change the
// palette and the appearance, each palette shown by its colours.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neumorphism_ui_example/main.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

Future<Library> _pump(WidgetTester t, {double width = 390}) async {
  t.view.physicalSize = Size(width, width < 600 ? 844 : 900);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  final app = ShelfApp();
  await t.pumpWidget(app);
  await t.pumpAndSettle();
  expect(t.takeException(), isNull);
  return app.library;
}

void main() {
  for (final width in [390.0, 1440.0]) {
    testWidgets(
      'a book opens its page; a delete asks first (${width.toInt()})',
      (t) async {
        final library = await _pump(t, width: width);
        await t.tap(find.text('Middlemarch'));
        await t.pumpAndSettle();
        expect(find.text('George Eliot'), findsOneWidget);
        // At 1440 the sidebar stays beside the pushed page.
        expect(
          find.byType(NeumorphicBrandRow),
          width > 1000 ? findsOneWidget : findsNothing,
        );
        await t.tap(find.text('Delete'));
        await t.pumpAndSettle();
        expect(find.text('Delete "Middlemarch"?'), findsOneWidget);
        await t.tap(find.text('Keep'));
        await t.pumpAndSettle();
        expect(library.books.map((b) => b.title), contains('Middlemarch'));
        await t.tap(find.text('Delete'));
        await t.pumpAndSettle();
        await t.tap(find.text('Delete').last);
        await t.pumpAndSettle();
        expect(
          library.books.map((b) => b.title),
          isNot(contains('Middlemarch')),
        );
        expect(find.text('Deleted "Middlemarch"'), findsOneWidget);
        expect(find.text('Stoner'), findsOneWidget);
      },
    );
  }

  testWidgets('the form says what is missing, then saves', (t) async {
    final library = await _pump(t);
    await t.tap(find.bySemanticsLabel('Add a book'));
    await t.pumpAndSettle();
    await t.tap(find.text('Save'));
    await t.pumpAndSettle();
    expect(find.text('Enter the title'), findsOneWidget);
    await t.enterText(find.byType(EditableText).first, 'Piranesi');
    await t.tap(find.text('Save'));
    await t.pumpAndSettle();
    expect(library.books.last.title, 'Piranesi');
    expect(find.text('Piranesi'), findsOneWidget);
  });

  testWidgets('settings change the palette and the appearance', (t) async {
    final library = await _pump(t);
    await t.tap(find.text('Settings').last);
    await t.pumpAndSettle();
    await t.tap(find.text('Verona'));
    await t.pumpAndSettle();
    expect(library.palette.id, 'verona');
    expect(
      NeumorphicTheme.of(t.element(find.text('Verona'))).colors.accent,
      NeumorphicThemeData.preset('verona', Brightness.light).colors.accent,
    );
    // Each palette shows its colours beside its name, as they show now.
    List<List<Color>> shown() => [
      for (final s in t.widgetList<Swatches>(find.byType(Swatches))) s.colors,
    ];
    expect(shown(), [
      for (final p in NeumorphicThemeData.palettes)
        p.swatchesFor(Brightness.light),
    ]);
    await t.tap(find.text('Dark'));
    await t.pumpAndSettle();
    expect(library.brightness, Brightness.dark);
    expect(shown(), [
      for (final p in NeumorphicThemeData.palettes)
        p.swatchesFor(Brightness.dark),
    ]);
    expect(NeumorphicTheme.of(t.element(find.text('Verona'))).dark, isTrue);
  });
}
