// The example app, as a reader copies it: the shelf pushes a book's page and its dialog removes the book; the form
// checks its fields, focuses the first wrong one, adds the book and clears; settings turn the appearance and the palette.
// At a phone's width the places are the strip at the foot, on a desk the menu bar.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';

// ignore_for_file: avoid_relative_lib_imports
import '../example/lib/main.dart';
import 'gallery_support.dart';
import 'support.dart';

Future<void> openApp(WidgetTester tester, double width) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, 900);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const ShelfApp());
  await settle(tester);
}

Future<void> goTo(WidgetTester tester, String place) async {
  await tester.tap(find.bySemanticsLabel(RegExp('^$place')).first);
  await settle(tester);
}

void main() {
  setUpAll(() async {
    await loadRetroDesktopFonts();
    await loadBundledFonts();
  });

  for (final (width, mode) in const [
    (390.0, RawNavigationMode.bar),
    (1440.0, RawNavigationMode.top),
  ]) {
    testWidgets(
      'at $width the places are the ${mode.name}, and a book opens and goes',
      (tester) async {
        await openApp(tester, width);
        expect(RetroDesktopAppShell.modeFor(width), mode);
        expect(find.text('Stoner'), findsOneWidget);
        await tester.tap(find.text('Piranesi'));
        await settle(tester);
        expect(find.textContaining('Started'), findsOneWidget);
        expect(
          find.text('Read'),
          findsOneWidget,
          reason: "The page says where the book stands",
        );
        await tester.tap(find.text('Remove book'));
        await settle(tester);
        expect(find.byType(RetroDesktopDialog), findsOneWidget);
        await tester.tap(find.text('Keep'));
        await settle(tester);
        expect(find.byType(RetroDesktopDialog), findsNothing);
        expect(
          find.textContaining('Started'),
          findsOneWidget,
          reason: 'Keep keeps the page',
        );
        await tester.tap(find.text('Remove book'));
        await settle(tester);
        await tester.tap(find.text('Remove'));
        await settle(tester);
        expect(
          find.text('Piranesi'),
          findsNothing,
          reason: 'Back on the shelf, the book gone',
        );
        expect(find.text('Removed Piranesi'), findsOneWidget);
        expect(find.text('Stoner'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets("on a desk a book page's way back starts where its window does", (
    tester,
  ) async {
    await openApp(tester, 1440);
    await tester.tap(find.text('Piranesi'));
    await settle(tester);
    expect(
      tester.getRect(find.byType(RetroDesktopBackButton)).left,
      closeTo(tester.getRect(find.byType(RetroDesktopWindow).last).left, 1),
    );
  });

  testWidgets("a book's row reads its tag in its name", (tester) async {
    await openApp(tester, 390);
    expect(find.bySemanticsLabel(RegExp('Piranesi.*Read')), findsOneWidget);
  });

  testWidgets('the form checks its fields, then adds the book', (tester) async {
    await openApp(tester, 390);
    await goTo(tester, 'Add');
    await tester.tap(find.text('Save'));
    await settle(tester);
    expect(find.text('Enter the title'), findsOneWidget);
    expect(find.text('Enter who wrote it'), findsOneWidget);
    final title = find.byType(EditableText).first;
    expect(
      tester.widget<EditableText>(title).focusNode.hasFocus,
      isTrue,
      reason: 'The first wrong field takes the focus',
    );
    await tester.enterText(title, 'Middlemarch');
    await tester.enterText(find.byType(EditableText).at(1), 'George Eliot');
    await tester.tap(find.text('Save'));
    await settle(tester);
    expect(find.text('Added Middlemarch'), findsOneWidget);
    expect(
      tester
          .widget<EditableText>(find.byType(EditableText).first)
          .controller
          .text,
      isEmpty,
      reason: 'Saved, the form clears for the next book',
    );
    expect(find.text('Enter the title'), findsNothing);
    expect(
      find.text('Not yet'),
      findsOneWidget,
      reason: 'The date field waits for a day',
    );
  });

  testWidgets('settings turn the appearance and the palette', (tester) async {
    await openApp(tester, 1440);
    await goTo(tester, 'Settings');
    RetroDesktopThemeData theme() =>
        RetroDesktopTheme.of(tester.element(find.byType(SettingsPage)));
    await tester.tap(find.text('Dark'));
    await settle(tester);
    expect(theme().colors.brightness, Brightness.dark);
    final second = RetroDesktopThemeData.palettes[1];
    await tester.tap(find.text(second.label));
    await settle(tester);
    expect(
      tester
          .widget<RetroDesktopListTile>(
            find.widgetWithText(RetroDesktopListTile, second.label),
          )
          .selected,
      isTrue,
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
        Directionality.of(tester.element(find.byType(RetroDesktopAppShell))),
        TextDirection.rtl,
      );
      final row = tester.getRect(find.text('Piranesi'));
      final shelf = tester.getRect(find.byType(RetroDesktopListSection));
      expect(
        shelf.right - row.right,
        lessThan(row.left - shelf.left),
        reason: 'A row starts at the right',
      );
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets("a palette's colours read left to right in an Arabic app too", (
    tester,
  ) async {
    tester.platformDispatcher.localesTestValue = const [Locale('ar')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await openApp(tester, 390);
    await goTo(tester, 'Settings');
    final stripes = find.descendant(
      of: find.byType(Swatches).first,
      matching: find.byType(ColoredBox),
    );
    expect(
      tester.getRect(stripes.at(0)).left,
      lessThan(tester.getRect(stripes.at(1)).left),
    );
  });
}
