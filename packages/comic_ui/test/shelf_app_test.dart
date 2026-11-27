// The example app, as a reader copies it: the shelf pushes a book's page and its dialog removes the book; the form
// checks its fields, focuses the first wrong one, adds the book and clears; settings turn the appearance and the palette. At a
// phone's width the places are the tab bar, at a tablet's a rail, at a desk's the masthead.
import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:comic_ui/comic_ui.dart';

// ignore_for_file: avoid_relative_lib_imports
import '../example/lib/main.dart';
import 'gallery_support.dart';
import 'support.dart';

/// Words as Comic letters them: a title or a button in capitals.
Finder words(String text) => find.byWidgetPredicate(
  (w) =>
      w is RichText &&
      w.text.toPlainText().trim().toLowerCase() == text.toLowerCase(),
);

Future<void> openApp(WidgetTester tester, double width) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, 900);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const ShelfApp());
  await settle(tester);
}

void main() {
  setUpAll(() async {
    await loadComicFonts();
    await loadBundledFonts();
  });

  for (final (width, mode) in const [
    (390.0, RawNavigationMode.bar),
    (800.0, RawNavigationMode.rail),
    (1440.0, RawNavigationMode.top),
  ]) {
    testWidgets(
      'at $width the places are the ${mode.name}, and a book opens and goes',
      (tester) async {
        await openApp(tester, width);
        expect(ComicAppShell.modeFor(width), mode);
        expect(words('Stoner'), findsOneWidget);
        await tester.tap(words('Piranesi'));
        await settle(tester);
        expect(words('Started 2 Oct 2026'), findsOneWidget);
        await tester.tap(words('Remove from the shelf'));
        await settle(tester);
        expect(find.byType(ComicDialog), findsOneWidget);
        await tester.tap(words('Keep'));
        await settle(tester);
        expect(find.byType(ComicDialog), findsNothing);
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
    await tester.tap(find.bySemanticsLabel(RegExp('^Add a book')).first);
    await settle(tester);
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
    expect(
      tester
          .widget<EditableText>(find.byType(EditableText).first)
          .controller
          .text,
      isEmpty,
      reason: 'Saved, the form clears for the next book',
    );
    await tester.tap(find.bySemanticsLabel(RegExp('^Books')).first);
    await settle(tester);
    expect(words('Middlemarch'), findsOneWidget);
    expect(words('To read'), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('settings turn the appearance and the palette', (tester) async {
    await openApp(tester, 390);
    ComicThemeData shown() =>
        ComicTheme.of(tester.element(find.byType(ComicAppShell)));
    expect(shown().id, ComicThemeData.palettes.first.id);
    await tester.tap(find.bySemanticsLabel(RegExp('^Settings')).first);
    await settle(tester);
    await tester.tap(words('Dark'));
    await settle(tester);
    expect(shown().brightness, Brightness.dark);
    final second = ComicThemeData.palettes[1];
    await tester.ensureVisible(words(second.label));
    await tester.tap(words(second.label));
    await settle(tester);
    expect(shown().id, second.id);
    expect(shown().brightness, Brightness.dark);
    await tester.tap(words('Light'));
    await settle(tester);
    expect(shown().brightness, Brightness.light);
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
        Directionality.of(tester.element(find.byType(ComicAppShell))),
        TextDirection.rtl,
      );
      final row = tester.getRect(words('Piranesi'));
      final shelf = tester.getRect(find.byType(ComicListSection));
      expect(
        shelf.right - row.right,
        lessThan(row.left - shelf.left),
        reason: 'A row starts at the right',
      );
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets(
    "on a desk a book's page has its way back beside its title, under the masthead",
    (tester) async {
      await openApp(tester, 1440);
      await tester.tap(words('Piranesi'));
      await settle(tester);
      final back = tester.getRect(find.bySemanticsLabel(RegExp('^Back')).last);
      final title = tester.getRect(words('Piranesi'));
      expect(
        (back.center.dy - title.center.dy).abs(),
        lessThan(4),
        reason: 'One row: the way back, then the title',
      );
      expect(back.right, lessThan(title.left));
      expect(
        find.byType(ComicAppBar).hitTestable(),
        findsNothing,
        reason: 'No bar of its own under the masthead',
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets("a book's row reads its tag in its name", (tester) async {
    await openApp(tester, 390);
    expect(find.bySemanticsLabel(RegExp('Piranesi.*Read')), findsOneWidget);
  });

  testWidgets("a book's page says where the book stands", (tester) async {
    await openApp(tester, 390);
    await tester.tap(words('Piranesi'));
    await settle(tester);
    expect(words('Read'), findsOneWidget);
  });

  testWidgets("a palette's colours read left to right in an Arabic app too", (
    tester,
  ) async {
    tester.platformDispatcher.localesTestValue = const [Locale('ar')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await openApp(tester, 390);
    await tester.tap(find.bySemanticsLabel(RegExp('^Settings')).first);
    await settle(tester);
    final stripes = find.descendant(
      of: find.byType(Swatches).first,
      matching: find.byType(ColoredBox),
    );
    expect(
      tester.getRect(stripes.at(0)).left,
      lessThan(tester.getRect(stripes.at(1)).left),
    );
  });

  testWidgets('on a desk a list and a form keep to one column, 720 at most', (
    tester,
  ) async {
    await openApp(tester, 1440);
    expect(
      tester.getSize(find.byType(ComicListSection)).width,
      lessThanOrEqualTo(720),
    );
    await tester.tap(find.bySemanticsLabel(RegExp('^Add a book')).first);
    await settle(tester);
    expect(
      tester.getSize(find.byType(ComicTextField).first).width,
      lessThanOrEqualTo(720),
    );
    expect(tester.takeException(), isNull);
  });

  for (final b in Brightness.values) {
    testWidgets(
      "settings show each palette's colours beside its name (${b.name})",
      (tester) async {
        tester.platformDispatcher.platformBrightnessTestValue = b;
        addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
        for (final width in const [390.0, 1440.0]) {
          await openApp(tester, width);
          await tester.tap(find.bySemanticsLabel(RegExp('^Settings')).first);
          await settle(tester);
          for (final palette in ComicThemeData.palettes) {
            final name = words(palette.label);
            final swatch = find.byWidgetPredicate(
              (w) =>
                  w is Swatches && listEquals(w.colors, palette.swatchesFor(b)),
            );
            expect(
              swatch,
              findsOneWidget,
              reason: '${palette.label} at $width',
            );
            final square = tester.getRect(swatch);
            final text = tester.getRect(name);
            expect(square.width, greaterThanOrEqualTo(20));
            expect(square.height, square.width);
            // Right beside the name, on its line.
            expect(
              text.left - square.right,
              inInclusiveRange(0, 16),
              reason: '${palette.label} at $width',
            );
            expect((text.center.dy - square.center.dy).abs(), lessThan(4));
          }
          // A screen reader hears each palette's name once, as a radio.
          final first = ComicThemeData.palettes.first.label;
          expect(find.bySemanticsLabel(first), findsOneWidget);
        }
      },
    );
  }
}
