// The example app, Shelf, as a reader uses it: a book opened from the list
// and back again on a phone and beside the side pane on a desk; a book added
// (its missing title said first), one deleted after the question's answer,
// and the appearance and palette changed.
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:terminal_ui/terminal_ui.dart';
import 'package:terminal_ui_example/main.dart';

Future<SemanticsHandle> _open(WidgetTester tester, {double width = 390}) async {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final semantics = tester.ensureSemantics();
  await tester.pumpWidget(ShelfApp(shelf: Shelf.sample()));
  await tester.pumpAndSettle();
  return semantics;
}

/// A place, as a screen reader hears it (the rail draws its number alone).
Finder _place(String label) =>
    find.bySemanticsLabel(RegExp('^$label')).hitTestable();

/// Scrolls [target] into view and taps it.
Future<void> _press(WidgetTester tester, Finder target) async {
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

/// Lets a toast's time run out, so no timer is left when the test ends.
Future<void> _wait(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 30));
  await tester.pumpAndSettle();
}

void main() {
  for (final width in [390.0, 1440.0]) {
    testWidgets('a book opens on a screen of its own and back returns to the '
        'list (${width.toInt()})', (tester) async {
      final semantics = await _open(tester, width: width);
      expect(find.text('Things Fall Apart'), findsOneWidget);
      await tester.tap(find.text('Middlemarch'));
      await tester.pumpAndSettle();
      expect(find.text('George Eliot'), findsOneWidget);
      // A phone's window list steps aside for the pushed screen; a desk's
      // side pane stays beside it.
      expect(_place('settings'), width < 600 ? findsNothing : findsWidgets);
      await tester.tap(find.bySemanticsLabel('back'));
      await tester.pumpAndSettle();
      expect(find.text('Things Fall Apart'), findsOneWidget);
      expect(_place('settings'), findsWidgets);
      semantics.dispose();
    });
  }

  testWidgets('a book without a title is not saved: the problem is said at '
      'the field', (tester) async {
    final semantics = await _open(tester);
    await tester.tap(_place('add').first);
    await tester.pumpAndSettle();
    await _press(tester, find.text('save book'));
    expect(find.textContaining('enter the book’s title'), findsOneWidget);
    await tester.enterText(
      find.descendant(
        of: find.byType(TermTextField).first,
        matching: find.byType(EditableText),
      ),
      'Small Things Like These',
    );
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    expect(find.textContaining('enter the book’s title'), findsNothing);
    await _press(tester, find.text('save book'));
    expect(find.text('Small Things Like These'), findsOneWidget);
    expect(find.text('added “Small Things Like These”'), findsOneWidget);
    await _wait(tester);
    semantics.dispose();
  });

  testWidgets("a book is deleted only on the question's answer", (
    tester,
  ) async {
    final semantics = await _open(tester);
    await _press(tester, find.text('Beloved'));
    await _press(tester, find.text('delete'));
    await tester.tap(find.text('keep').last);
    await tester.pumpAndSettle();
    expect(find.text('Toni Morrison'), findsOneWidget);
    await _press(tester, find.text('delete'));
    await tester.tap(find.text('delete').last);
    await tester.pumpAndSettle();
    expect(find.text('Things Fall Apart'), findsOneWidget);
    expect(find.text('Beloved'), findsNothing);
    expect(find.text('deleted “Beloved”'), findsOneWidget);
    await _wait(tester);
    semantics.dispose();
  });

  testWidgets('the settings change the appearance and the palette', (
    tester,
  ) async {
    final semantics = await _open(tester);
    await tester.tap(_place('settings').first);
    await tester.pumpAndSettle();
    TermThemeData theme() => TermTheme.of(tester.element(find.text('amber')));
    await tester.tap(find.text('dark'));
    await tester.pumpAndSettle();
    expect(theme().brightness, Brightness.dark);
    await _press(tester, find.text('amber'));
    expect(
      theme().background,
      TermThemeData.preset('amber', Brightness.dark).background,
    );
    await tester.tap(find.text('light'));
    await tester.pumpAndSettle();
    expect(
      theme().background,
      TermThemeData.preset('amber', Brightness.light).background,
    );
    semantics.dispose();
  });

  for (final width in [390.0, 1440.0]) {
    testWidgets('each palette shows its colour one cell after its name, by '
        'day and by night (${width.toInt()})', (tester) async {
      final semantics = await _open(tester, width: width);
      await tester.tap(_place('settings').first);
      await tester.pumpAndSettle();
      // Two cells of [colour] on the line of [name], a cell after it.
      void swatchAfter(String name, Color colour) {
        final swatch = find.byWidgetPredicate(
          (widget) =>
              widget is Text &&
              widget.data == '██' &&
              widget.style?.color == colour,
        );
        expect(swatch, findsOneWidget, reason: '$name shows $colour');
        final words = tester.getRect(find.text(name));
        final cells = tester.getRect(swatch);
        expect(cells.center.dy, moreOrLessEquals(words.center.dy, epsilon: 1));
        final cell = tester.element(find.text(name)).termGrid.cellWidth;
        expect(
          cells.left - words.right,
          moreOrLessEquals(cell, epsilon: 0.5),
          reason: '$name, a cell, its colour',
        );
      }

      for (final palette in TermThemeData.palettes) {
        swatchAfter(palette.label, palette.swatches.first);
      }
      await tester.tap(find.text('dark'));
      await tester.pumpAndSettle();
      for (final palette in TermThemeData.palettes) {
        swatchAfter(palette.label, palette.darkSwatches.first);
      }
      // The name says the palette; its cells add nothing to it.
      expect(_place('settings'), findsWidgets);
      expect(find.bySemanticsLabel('amber'), findsOneWidget);
      semantics.dispose();
    });
  }
}
