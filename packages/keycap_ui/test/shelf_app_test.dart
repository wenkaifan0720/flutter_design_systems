// The example app, as a reader copies it: the shelf pushes a book's page and its dialog removes the book; the form
// checks its fields, focuses the first wrong one, adds the book and clears; settings turn the appearance and the
// colourway. At a phone's width the places are the bar, at a tablet's the rail, at a desk's the side column.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keycap_ui/keycap_ui.dart';
import 'package:material_ui/material_ui.dart' show ThemeMode;

// ignore_for_file: avoid_relative_lib_imports
import '../example/lib/main.dart';

Finder words(String text) => find.byWidgetPredicate(
  (w) => w is RichText && w.text.toPlainText().trim() == text,
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
  setUpAll(keycapLoadFonts);

  for (final (width, mode) in const [
    (390.0, RawNavigationMode.bar),
    (800.0, RawNavigationMode.rail),
    (1440.0, RawNavigationMode.sidebar),
  ]) {
    testWidgets(
      'at $width the places are the ${mode.name}, and a book opens and goes',
      (tester) async {
        await openApp(tester, width);
        expect(KeycapScaffold.modeFor(width), mode);
        expect(words('Stoner'), findsOneWidget);
        await tester.tap(words('Piranesi'));
        await settle(tester);
        expect(words('Started Oct 2, 2026'), findsOneWidget);
        await tester.tap(words('Remove from the shelf'));
        await settle(tester);
        expect(find.byType(KeycapDialog), findsOneWidget);
        await tester.tap(words('Keep'));
        await settle(tester);
        expect(find.byType(KeycapDialog), findsNothing);
        expect(
          words('Started Oct 2, 2026'),
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

  testWidgets('settings turn the appearance and the colourway', (tester) async {
    await openApp(tester, 390);
    KeycapThemeData shown() =>
        KeycapTheme.of(tester.element(find.byType(KeycapScaffold)));
    await go(tester, 'Settings');
    await tester.tap(words('Dark'));
    await settle(tester);
    expect(shown().colors.brightness, Brightness.dark);
    final second = KeycapThemeData.palettes[1];
    await tester.tap(words(second.label));
    await settle(tester);
    expect(
      shown().colors,
      KeycapThemeData.preset(second.id, Brightness.dark).colors,
    );
    await tester.tap(words('Light'));
    await settle(tester);
    expect(
      shown().colors,
      KeycapThemeData.preset(second.id, Brightness.light).colors,
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
        Directionality.of(tester.element(find.byType(KeycapScaffold))),
        TextDirection.rtl,
      );
      final row = tester.getRect(words('Piranesi'));
      final shelf = tester.getRect(find.byType(KeycapListGroup));
      expect(
        shelf.right - row.right,
        lessThan(row.left - shelf.left),
        reason: 'A row starts at the right',
      );
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets(
    'on a desk a list and a form keep to one column, 720 at most, the Save key at its end',
    (tester) async {
      await openApp(tester, 1440);
      expect(
        tester.getSize(find.byType(KeycapListGroup)).width,
        lessThanOrEqualTo(720),
      );
      await go(tester, 'Add a book');
      final field = tester.getRect(find.byType(KeycapField).first);
      expect(field.width, lessThanOrEqualTo(720));
      final date = tester.getRect(
        find.descendant(
          of: find.byType(KeycapDatePicker),
          matching: find.byType(KeycapField),
        ),
      );
      expect(date.width, field.width, reason: 'every field on one width');
      final save = tester.getRect(
        find.ancestor(of: words('Save'), matching: find.byType(KeycapButton)),
      );
      expect(
        save.right,
        moreOrLessEquals(field.right, epsilon: 1),
        reason: "the foot's key on the column's end",
      );
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
        final card = tester.getSize(find.byType(KeycapCard)).width;
        expect(card, width < 600 ? width - 32 : 720, reason: 'at $width');
        expect(words('Read'), findsOneWidget, reason: 'its status, at $width');
        expect(tester.takeException(), isNull);
      }
    },
  );

  testWidgets('on a desk the appearance and the colourways take one width', (
    tester,
  ) async {
    await openApp(tester, 1440);
    await go(tester, 'Settings');
    expect(
      tester.getSize(find.byType(KeycapSegmentedButton<ThemeMode>)).width,
      tester.getSize(find.byType(KeycapListGroup)).width,
    );
  });

  for (final b in Brightness.values) {
    testWidgets(
      "settings show each colourway's colours beside its name (${b.name})",
      (tester) async {
        tester.platformDispatcher.platformBrightnessTestValue = b;
        addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
        for (final width in const [390.0, 1440.0]) {
          await openApp(tester, width);
          await go(tester, 'Settings');
          for (final palette in KeycapThemeData.palettes) {
            final row = find.ancestor(
              of: words(palette.label),
              matching: find.byType(KeycapListTile),
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
            expect(
              name.left - swatch.right,
              inInclusiveRange(0, 16),
              reason: 'at $width',
            );
            expect(
              find.descendant(of: row, matching: find.byType(Icon)),
              findsNothing,
            );
          }
          final chosen = tester.widget<KeycapListTile>(
            find.ancestor(
              of: words(KeycapThemeData.palettes.first.label),
              matching: find.byType(KeycapListTile),
            ),
          );
          expect(chosen.selected, isTrue);
        }
      },
    );
  }
}
