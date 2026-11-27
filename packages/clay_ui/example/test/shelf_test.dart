// Shelf, the example app, works end to end: a book opens on its own page
// beside the sidebar, deleting it asks first and Undo brings it back where it
// stood, saving the form without a title says so at the field, and a palette
// chosen in Settings colours the app.
import 'package:clay_ui/clay_ui.dart';
import 'package:clay_ui_example/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Future<Shelf> _open(WidgetTester tester, double width) async {
  tester.view
    ..physicalSize = Size(width, 900)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final shelf = Shelf.sample();
  await tester.pumpWidget(ShelfApp(shelf: shelf));
  await tester.pumpAndSettle();
  return shelf;
}

void main() {
  setUpAll(clayLoadFonts);

  testWidgets(
    'a book opens beside the sidebar; Undo brings a deleted one back',
    (tester) async {
      final shelf = await _open(tester, 1440);
      await tester.tap(find.text('Beloved'));
      await tester.pumpAndSettle();
      expect(find.text('Toni Morrison'), findsOneWidget);
      expect(find.byType(ClaySidebar), findsOneWidget);

      await tester.tap(find.text('Delete book'));
      await tester.pumpAndSettle();
      expect(find.text('Delete “Beloved”?'), findsOneWidget);
      await tester.tap(find.text('Delete book').last);
      await tester.pumpAndSettle();
      expect(shelf.byId('4'), isNull);
      expect(find.text('Deleted “Beloved”'), findsOneWidget);
      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      expect(shelf.books.map((b) => b.id), ['1', '2', '3', '4', '5']);
    },
  );

  testWidgets('keeping a book leaves it where it is', (tester) async {
    final shelf = await _open(tester, 390);
    await tester.tap(find.text('Beloved'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete book'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Keep it'));
    await tester.pumpAndSettle();
    expect(shelf.byId('4'), isNotNull);
    expect(find.text('Toni Morrison'), findsOneWidget);
  });

  testWidgets('a form saved without a title says so at the field', (
    tester,
  ) async {
    final shelf = await _open(tester, 390);
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save book'));
    await tester.pumpAndSettle();
    expect(find.text('Enter the book’s title'), findsOneWidget);
    expect(shelf.books, hasLength(5));

    await tester.enterText(find.byType(EditableText).first, 'Emma');
    await tester.pump();
    expect(find.text('Enter the book’s title'), findsNothing);
    await tester.tap(find.text('Save book'));
    await tester.pumpAndSettle();
    expect(shelf.books.first.title, 'Emma');
    expect(shelf.books.first.started, isNull);
    // Back on Books, with the new book at the top.
    expect(find.text('6 books'), findsOneWidget);
  });

  testWidgets('a palette chosen in Settings colours the app', (tester) async {
    final shelf = await _open(tester, 390);
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mint'));
    await tester.pumpAndSettle();
    expect(shelf.palette.id, 'mint');
    final accent = ClayTheme.of(tester.element(find.text('Colour')))
        .colors
        .accent;
    expect(
      accent,
      ClayThemeData.preset('mint', Brightness.light).colors.accent,
    );
  });
}
