// The example app, Shelf, as a reader uses it: a book opened from the list
// and back again on a phone and beside the side bar on a desktop; a book
// added (its missing title said first), one deleted after the dialog's
// answer, and the appearance and palette changed.
import 'package:flutter_test/flutter_test.dart';
import 'package:ledger_ui/ledger_ui.dart';
import 'package:ledger_ui_example/main.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

Future<void> _open(WidgetTester tester, {double width = 390}) async {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ShelfApp(shelf: Shelf.sample()));
  await tester.pumpAndSettle();
}

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

/// A row's title, its tag set in its line.
Finder _row(String title) =>
    find.textContaining(RegExp('^${RegExp.escape(title)}'));

/// A book only the list shows.
final _list = _row('Things Fall Apart');

void main() {
  for (final width in [390.0, 1440.0]) {
    testWidgets('a book opens on a page of its own and back returns to the '
        'list (${width.toInt()})', (tester) async {
      await _open(tester, width: width);
      expect(_list, findsOneWidget);
      if (width > 600) {
        // Every row as tall as the next, whatever its status's mark (a
        // done book's wash beside a ringed tag).
        final heights = {
          for (final row in find.byType(LedgerRow).evaluate())
            (row.renderObject! as RenderBox).size.height,
        };
        expect(heights, hasLength(1));
      }
      await tester.tap(_row('Middlemarch'));
      await tester.pumpAndSettle();
      expect(find.text('George Eliot'), findsOneWidget);
      if (width > 600) {
        // The page's two acts side by side on the desktop's form column.
        expect(
          tester.getTopLeft(find.text('Delete book')).dy,
          tester.getTopLeft(find.text('Change book')).dy,
        );
      }
      // A phone's bar steps aside for the pushed page; a desktop's side
      // bar stays beside it.
      expect(
        find.text('Settings').hitTestable(),
        width < 600 ? findsNothing : findsOneWidget,
      );
      await tester.tap(find.byType(LedgerBack));
      await tester.pumpAndSettle();
      expect(_list, findsOneWidget);
      expect(find.text('Settings').hitTestable(), findsOneWidget);
    });
  }

  testWidgets('a book without a title is not saved: the problem is said at '
      'the field', (tester) async {
    await _open(tester);
    await tester.tap(find.byIcon(LucideIcons.plus));
    await tester.pumpAndSettle();
    await _press(tester, find.text('Save book'));
    expect(find.text('Enter the book’s title'), findsOneWidget);
    await tester.enterText(
      find.descendant(
        of: find.byType(LedgerTextField).first,
        matching: find.byType(EditableText),
      ),
      'Small Things Like These',
    );
    // Done with the keyboard: the field no longer keeps its caret in view.
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    expect(find.text('Enter the book’s title'), findsNothing);
    await _press(tester, find.text('Save book'));
    expect(_list, findsOneWidget);
    expect(_row('Small Things Like These'), findsOneWidget);
    expect(find.text('Added “Small Things Like These”'), findsOneWidget);
    await _wait(tester);
  });

  testWidgets('an optional date is chosen in the form', (tester) async {
    await _open(tester);
    await tester.tap(find.byIcon(LucideIcons.plus));
    await tester.pumpAndSettle();
    await _press(tester, find.text('Select date'));
    // A day, then the sheet's Done (a status of the form is Done too): the
    // field stays unset until a day is picked.
    await tester.tap(find.text('15').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Done').last);
    await tester.pumpAndSettle();
    expect(find.text('Select date'), findsNothing);
  });

  testWidgets("a book is deleted only on the dialog's answer", (tester) async {
    await _open(tester);
    await _press(tester, _row('Beloved'));
    await _press(tester, find.text('Delete book'));
    await tester.tap(find.text('Keep it'));
    await tester.pumpAndSettle();
    expect(find.text('Toni Morrison'), findsOneWidget);
    await _press(tester, find.text('Delete book'));
    await tester.tap(find.text('Delete book').last);
    await tester.pumpAndSettle();
    expect(_list, findsOneWidget);
    expect(find.text('Toni Morrison'), findsNothing);
    expect(find.text('Deleted “Beloved”'), findsOneWidget);
    await _wait(tester);
  });

  testWidgets('the settings change the appearance and the palette', (
    tester,
  ) async {
    await _open(tester);
    await tester.tap(find.byIcon(LucideIcons.settings));
    await tester.pumpAndSettle();
    LedgerThemeData theme() =>
        tester.element(find.text('Terracotta')).ledgerTheme;
    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();
    expect(theme().isDark, isTrue);
    await _press(tester, find.text('Terracotta'));
    expect(
      theme().accent,
      LedgerThemeData.palettes
          .firstWhere((p) => p.id == 'terracotta')
          .swatchesFor(Brightness.dark)
          .first,
    );
    await _press(tester, find.text('Light'));
    expect(theme().isDark, isFalse);
  });

  for (final width in [390.0, 1440.0]) {
    testWidgets('each palette shows its colour beside its name, by day and by '
        'night (${width.toInt()})', (tester) async {
      await _open(tester, width: width);
      await tester.tap(find.byIcon(LucideIcons.settings).first);
      await tester.pumpAndSettle();
      // A round of [colour] between the radio's ring and [name], on its line.
      void swatchBefore(String name, Color colour) {
        final swatch = find.descendant(
          of: find.byType(LedgerRadio<String>),
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is DecoratedBox &&
                widget.decoration is BoxDecoration &&
                (widget.decoration as BoxDecoration).shape == BoxShape.circle &&
                (widget.decoration as BoxDecoration).color == colour,
          ),
        );
        expect(swatch, findsOneWidget, reason: '$name shows $colour');
        final words = tester.getRect(find.text(name));
        final round = tester.getRect(swatch);
        expect(round.center.dy, moreOrLessEquals(words.center.dy, epsilon: 1));
        final gap = words.left - round.right;
        expect(gap, inInclusiveRange(8, 24), reason: '$name beside its colour');
      }

      for (final palette in LedgerThemeData.palettes) {
        swatchBefore(palette.label, palette.swatches.first);
      }
      await tester.tap(find.text('Dark'));
      await tester.pumpAndSettle();
      for (final palette in LedgerThemeData.palettes) {
        swatchBefore(palette.label, palette.darkSwatches.first);
      }
      final handle = tester.ensureSemantics();
      expect(find.bySemanticsLabel('Terracotta'), findsOneWidget);
      handle.dispose();
    });
  }
}
