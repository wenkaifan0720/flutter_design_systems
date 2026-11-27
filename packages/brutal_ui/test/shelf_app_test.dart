// The example app, as a reader copies it: the shelf pushes a book's page and its dialog removes the book; the form
// checks its fields, focuses the first wrong one, adds the book and clears; settings turn the appearance and the
// palette. At a phone's width the places are the bar, at a tablet's the rail, at a desk's the side list.
import 'package:brutal_ui/brutal_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart' show ThemeMode;

// ignore_for_file: avoid_relative_lib_imports
import '../example/lib/main.dart';

/// Words as Brutal sets them: a place's name in capitals in the bar and the rail.
Finder words(String text) => find.byWidgetPredicate(
  (w) =>
      w is RichText &&
      w.text.toPlainText().trim().toLowerCase() == text.toLowerCase(),
);

Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 40; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Future<void> openApp(WidgetTester tester, double width) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, 900);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const ShelfApp());
  await settle(tester);
}

Future<void> go(WidgetTester tester, String place) async {
  await tester.tap(find.bySemanticsLabel(RegExp('^$place')).first);
  await settle(tester);
}

void main() {
  setUpAll(brutalLoadFonts);

  for (final (width, mode) in const [
    (390.0, RawNavigationMode.bar),
    (800.0, RawNavigationMode.rail),
    (1440.0, RawNavigationMode.sidebar),
  ]) {
    testWidgets(
      'at $width the places are the ${mode.name}, and a book opens and goes',
      (tester) async {
        await openApp(tester, width);
        expect(BrutalAppShell.modeFor(width), mode);
        expect(words('Stoner'), findsOneWidget);
        await tester.tap(words('Piranesi'));
        await settle(tester);
        expect(words('Started 2 Oct 2026'), findsOneWidget);
        await tester.tap(words('Remove from the shelf'));
        await settle(tester);
        expect(find.byType(BrutalDialog), findsOneWidget);
        await tester.tap(words('Keep'));
        await settle(tester);
        expect(find.byType(BrutalDialog), findsNothing);
        expect(
          words('Started 2 Oct 2026'),
          findsOneWidget,
          reason: 'Keep keeps the page',
        );
        await tester.tap(words('Remove from the shelf'));
        await settle(tester);
        await tester.tap(words('Remove'));
        await settle(tester);
        expect(
          words('Piranesi'),
          findsNothing,
          reason: 'Back on the shelf, the book gone',
        );
        expect(words('Removed Piranesi'), findsOneWidget);
        expect(words('Stoner'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('the form checks its fields, then adds the book', (tester) async {
    await openApp(tester, 390);
    await go(tester, 'Add a book');
    await tester.tap(words('Save'));
    await settle(tester);
    expect(words('Enter the title'), findsOneWidget);
    expect(words('Enter who wrote it'), findsOneWidget);
    final title = find.byType(EditableText).first;
    expect(
      tester.widget<EditableText>(title).focusNode.hasFocus,
      isTrue,
      reason: 'The first wrong field takes the focus',
    );
    await tester.enterText(title, 'Middlemarch');
    await tester.enterText(find.byType(EditableText).at(1), 'George Eliot');
    await tester.tap(words('Save'));
    await settle(tester);
    expect(words('Added Middlemarch'), findsOneWidget);
    expect(words('Enter the title'), findsNothing);
    expect(
      tester
          .widget<EditableText>(find.byType(EditableText).first)
          .controller
          .text,
      isEmpty,
      reason: 'Saved, the form clears for the next book',
    );
    await go(tester, 'Books');
    expect(words('Middlemarch'), findsOneWidget);
    expect(words('To read'), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('settings turn the appearance and the palette', (tester) async {
    await openApp(tester, 390);
    BrutalThemeData shown() =>
        BrutalTheme.of(tester.element(find.byType(BrutalAppShell)));
    await go(tester, 'Settings');
    await tester.tap(words('Dark'));
    await settle(tester);
    expect(shown().colors.brightness, Brightness.dark);
    final second = BrutalThemeData.palettes[1];
    await tester.tap(words(second.label));
    await settle(tester);
    expect(
      shown().colors.signal,
      BrutalThemeData.preset(second.id, Brightness.dark).colors.signal,
    );
    await tester.tap(words('Light'));
    await settle(tester);
    expect(shown().colors.brightness, Brightness.light);
    expect(
      shown().colors.signal,
      BrutalThemeData.preset(second.id, Brightness.light).colors.signal,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('on an Arabic device the app reads right to left', (
    tester,
  ) async {
    tester.platformDispatcher.localesTestValue = const [Locale('ar')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    for (final width in const [390.0, 1440.0]) {
      await openApp(tester, width);
      expect(
        Directionality.of(tester.element(find.byType(BrutalAppShell))),
        TextDirection.rtl,
      );
      final row = tester.getRect(words('Piranesi'));
      final shelf = tester.getRect(find.byType(BrutalListGroup));
      expect(
        shelf.right - row.right,
        lessThan(row.left - shelf.left),
        reason: 'A row starts at the right',
      );
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('on a desk a list and a form keep to one column, 720 at most', (
    tester,
  ) async {
    await openApp(tester, 1440);
    expect(
      tester.getSize(find.byType(BrutalListGroup)).width,
      lessThanOrEqualTo(720),
    );
    await go(tester, 'Add a book');
    final field = tester.getSize(find.byType(BrutalTextField).first).width;
    expect(field, lessThanOrEqualTo(720));
    expect(
      tester.getSize(find.byType(BrutalDatePicker)).width,
      field,
      reason: 'every field on one width',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    "on a phone the date field's calendar keeps clear of the places' bar",
    (tester) async {
      await openApp(tester, 390);
      await go(tester, 'Add a book');
      await tester.tap(find.byType(BrutalDatePicker));
      await settle(tester);
      final calendar = tester.getRect(find.byType(BrutalCalendar));
      // The bar's cell for Books: the bar's top edge.
      final bar = tester.getRect(find.bySemanticsLabel(RegExp('^Books')).first);
      expect(
        calendar.bottom,
        lessThanOrEqualTo(bar.top),
        reason: 'the calendar ends above the bar',
      );
      expect(calendar.top, greaterThanOrEqualTo(0));
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    "a book's page holds its card to the column, and says where the book stands",
    (tester) async {
      for (final width in const [390.0, 1440.0]) {
        await openApp(tester, width);
        await tester.tap(words('Piranesi'));
        await settle(tester);
        final card = tester.getSize(find.byType(BrutalBlock)).width;
        expect(card, width < 600 ? width - 32 : 720, reason: 'at $width');
        expect(words('Read'), findsOneWidget, reason: 'its status, at $width');
        expect(tester.takeException(), isNull);
      }
    },
  );

  testWidgets('on a desk the appearance and the palette take one width', (
    tester,
  ) async {
    await openApp(tester, 1440);
    await go(tester, 'Settings');
    final rule = BrutalTheme.of(tester.element(find.byType(BrutalAppShell)))
        .borderWidth;
    // Its row of cells and its frame's two rules, as drawn (the control's box
    // takes the column either way).
    final row = tester.getSize(
      find
          .descendant(
            of: find.byType(BrutalSegmentedButton<ThemeMode>),
            matching: find.byType(Row),
          )
          .first,
    );
    expect(
      row.width + 2 * rule,
      tester.getSize(find.byType(BrutalListGroup)).width,
    );
  });

  for (final rtl in const [false, true]) {
    testWidgets(
      "on a desk the app's name stands on its places' start edge (${rtl ? 'rtl' : 'ltr'})",
      (tester) async {
        if (rtl) {
          tester.platformDispatcher.localesTestValue = const [Locale('ar')];
          addTearDown(tester.platformDispatcher.clearLocalesTestValue);
        }
        await openApp(tester, 1440);
        final brand = tester.getRect(words('Shelf'));
        final glyph = tester.getRect(
          find.descendant(
            of: find.byType(BrutalAppShell),
            matching: find.byWidgetPredicate(
              (w) => w is Icon && w.icon == LucideIcons.bookOpen,
            ),
          ),
        );
        if (rtl) {
          expect(brand.right, moreOrLessEquals(glyph.right, epsilon: 1));
        } else {
          expect(brand.left, moreOrLessEquals(glyph.left, epsilon: 1));
        }
      },
    );
  }

  for (final b in Brightness.values) {
    testWidgets(
      "settings show each palette's colours beside its name (${b.name})",
      (tester) async {
        tester.platformDispatcher.platformBrightnessTestValue = b;
        addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
        await openApp(tester, 390);
        await go(tester, 'Settings');
        for (final palette in BrutalThemeData.palettes) {
          final row = find.ancestor(
            of: words(palette.label),
            matching: find.byType(BrutalListTile),
          );
          final drawn = {
            for (final e
                in find
                    .descendant(of: row, matching: find.byType(ColoredBox))
                    .evaluate())
              (e.widget as ColoredBox).color,
          };
          expect(
            drawn.containsAll(palette.swatchesFor(b)),
            isTrue,
            reason: '${palette.label}: $drawn',
          );
          // A square a glyph's size beside the name, the name right after it, no chevron.
          final swatch = tester.getRect(
            find.descendant(of: row, matching: find.byType(Swatches)),
          );
          expect(swatch.width, greaterThanOrEqualTo(20));
          expect(swatch.height, swatch.width);
          final name = tester.getRect(words(palette.label));
          expect(name.left - swatch.right, lessThanOrEqualTo(16));
          expect(
            find.descendant(of: row, matching: find.byType(Icon)),
            findsNothing,
          );
        }
        final chosen = tester.widget<BrutalListTile>(
          find.ancestor(
            of: words(BrutalThemeData.palettes.first.label),
            matching: find.byType(BrutalListTile),
          ),
        );
        expect(chosen.selected, isTrue);
      },
    );
  }
}
