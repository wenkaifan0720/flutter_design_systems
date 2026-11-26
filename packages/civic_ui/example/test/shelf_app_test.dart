// The example app, Shelf, as a reader uses it: a book opened from the list
// and back again on a phone and beside the side navigation on a desktop;
// a book added (its missing title said first), one deleted after the
// dialog's answer, and the appearance and palette changed.
import 'package:civic_ui/civic_ui.dart';
import 'package:civic_ui_example/main.dart';
import 'package:flutter_test/flutter_test.dart';
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

void main() {
  for (final width in [390.0, 1440.0]) {
    testWidgets('a book opens on a page of its own and back returns to the '
        'list (${width.toInt()})', (tester) async {
      await _open(tester, width: width);
      expect(find.text('Your reading list'), findsOneWidget);
      await tester.tap(find.text('Middlemarch'));
      await tester.pumpAndSettle();
      expect(find.text('George Eliot'), findsOneWidget);
      // A phone's bar steps aside for the pushed page; a desktop's side
      // navigation stays beside it.
      expect(
        find.text('Settings').hitTestable(),
        width < 600 ? findsNothing : findsOneWidget,
      );
      await tester.tap(find.byIcon(LucideIcons.chevronLeft));
      await tester.pumpAndSettle();
      expect(find.text('Your reading list'), findsOneWidget);
      expect(find.text('Settings').hitTestable(), findsOneWidget);
    });
  }

  testWidgets('a book without a title is not saved: the problem is said at '
      'the top and at the field', (tester) async {
    await _open(tester);
    await tester.tap(find.byIcon(LucideIcons.plus));
    await tester.pumpAndSettle();
    await _press(tester, find.text('Save book'));
    expect(find.text('There is a problem'), findsOneWidget);
    expect(find.text('Enter the book’s title'), findsNWidgets(2));
    await tester.enterText(
      find.descendant(
        of: find.widgetWithText(CivicTextField, 'Title'),
        matching: find.byType(EditableText),
      ),
      'Small Things Like These',
    );
    // Done with the keyboard: the field no longer keeps its caret in view.
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await _press(tester, find.text('Save book'));
    expect(find.text('Your reading list'), findsOneWidget);
    expect(find.text('Small Things Like These'), findsOneWidget);
    expect(find.text('Added “Small Things Like These”'), findsOneWidget);
    await _wait(tester);
  });

  testWidgets("a book is deleted only on the dialog's answer", (tester) async {
    await _open(tester);
    await _press(tester, find.text('Beloved'));
    await _press(tester, find.text('Delete book'));
    await tester.tap(find.text('Keep it'));
    await tester.pumpAndSettle();
    expect(find.text('Toni Morrison'), findsOneWidget);
    await _press(tester, find.text('Delete book'));
    await tester.tap(find.text('Delete book').last);
    await tester.pumpAndSettle();
    expect(find.text('Your reading list'), findsOneWidget);
    expect(find.text('Beloved'), findsNothing);
    expect(find.text('Deleted “Beloved”'), findsOneWidget);
    await _wait(tester);
  });

  testWidgets('the settings change the appearance and the palette', (
    tester,
  ) async {
    await _open(tester);
    await tester.tap(find.byIcon(LucideIcons.settings));
    await tester.pumpAndSettle();
    CivicThemeData theme() =>
        tester.element(find.text('Appearance')).civicTheme;
    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();
    expect(theme().isDark, isTrue);
    await tester.tap(find.text('Plum'));
    await tester.pumpAndSettle();
    expect(
      theme().action,
      CivicThemeData.palettes
          .firstWhere((p) => p.id == 'plum')
          .darkSwatches
          .first,
    );
    await tester.tap(find.text('Light'));
    await tester.pumpAndSettle();
    expect(theme().isDark, isFalse);
  });

  for (final width in [390.0, 1440.0]) {
    testWidgets('each palette shows its colour beside its name, as it shows '
        'by day and by night (${width.toInt()})', (tester) async {
      await _open(tester, width: width);
      await tester.tap(find.text('Settings').first);
      await tester.pumpAndSettle();
      // A round swatch of [colour] on the line of [name].
      void swatchBeside(String name, Color colour) {
        final swatch = find.byWidgetPredicate(
          (widget) =>
              widget is DecoratedBox &&
              widget.decoration is BoxDecoration &&
              (widget.decoration as BoxDecoration).shape == BoxShape.circle &&
              (widget.decoration as BoxDecoration).color == colour,
        );
        expect(swatch, findsOneWidget, reason: '$name shows $colour');
        final words = tester.getRect(find.text(name));
        final round = tester.getRect(swatch);
        expect(
          (round.center.dy - words.center.dy).abs(),
          lessThan(words.height),
          reason: '$name and its colour share a line',
        );
        // Between the circle and the words, 12 before the words.
        final gap =
            Directionality.of(tester.element(swatch)) == TextDirection.ltr
            ? words.left - round.right
            : round.left - words.right;
        expect(gap, moreOrLessEquals(12, epsilon: 0.5), reason: '$name beside');
      }

      for (final palette in CivicThemeData.palettes) {
        swatchBeside(palette.label, palette.swatches.first);
      }
      await tester.tap(find.text('Dark'));
      await tester.pumpAndSettle();
      for (final palette in CivicThemeData.palettes) {
        swatchBeside(palette.label, palette.darkSwatches.first);
      }
      // The name says the palette; the colour stays out of its row's name.
      expect(
        tester.getSemantics(find.text('Plum')).label,
        isNot(contains('Color')),
      );
    });
  }
}
