// Every live page fits: at a phone, a tablet and two desktop widths, in both directions and at twice the text, on its
// own; and through the gallery's own navigation at a phone's and a desktop's width. Hearth, the app, is its own world:
// gallery_app_test holds it to its sizes, and here it opens from the navigation and fits at twice the text.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

// ignore: avoid_relative_lib_imports
import '../example/lib/main.dart';
// ignore: avoid_relative_lib_imports
import '../example/lib/kit_gallery/live.dart';
// ignore: avoid_relative_lib_imports
import '../example/lib/kit_gallery/hearth.dart'
    show hearthScreens, isHearthScreen;
import 'gallery_support.dart' show loadBundledFonts, settle;
import 'support.dart' show loadNeumorphicFonts;

void main() {
  setUpAll(() async {
    await loadNeumorphicFonts();
    await loadBundledFonts();
  });

  for (final page in liveGalleryPages) {
    if (isHearthScreen(page.id)) continue;
    for (final width in [390.0, 768.0, 1024.0, 1440.0]) {
      for (final direction in TextDirection.values) {
        for (final scale in [1.0, 2.0]) {
          testWidgets(
            'live ${page.id} fits $width ${direction.name} at $scale text',
            (tester) async {
              tester.view.physicalSize = Size(width, 1000);
              tester.view.devicePixelRatio = 1;
              addTearDown(tester.view.reset);
              await tester.pumpWidget(
                MaterialApp(
                  builder: (context, child) => MediaQuery(
                    data: MediaQuery.of(context)
                        .copyWith(textScaler: TextScaler.linear(scale)),
                    child: Directionality(
                      textDirection: direction,
                      child: NeumorphicTheme(
                        data: NeumorphicThemeData.porcelain(),
                        child: child!,
                      ),
                    ),
                  ),
                  home: LiveExample(page: page.id),
                ),
              );
              await settle(tester);
              expect(tester.takeException(), isNull);
            },
          );
        }
      }
    }
    for (final width in [390.0, 1440.0]) {
      testWidgets('live ${page.id} through the navigation at $width', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          GalleryApp(initialPage: page.id, initialCustomizing: true),
        );
        await settle(tester);
        expect(tester.takeException(), isNull);
        // The Overview opens on its pitch, not on its name (a phone shows no rail to name it).
        expect(
          page.id == 'overview'
              ? find.byKey(const Key('overview-dial'))
              : find.text(page.title),
          findsWidgets,
        );
      });
    }
  }

  for (final screen in hearthScreens) {
    for (final width in [390.0, 768.0, 1440.0]) {
      testWidgets('Hearth ${screen.id} fits $width at twice the text', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await tester.pumpWidget(GalleryApp(initialPage: screen.id));
        await settle(tester);
        expect(tester.takeException(), isNull);
        expect(find.byKey(ValueKey('hearth-${screen.id}')), findsOneWidget);
      });
    }
  }
  for (final width in [390.0, 1440.0]) {
    testWidgets('Hearth opens from the gallery\'s navigation at $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const GalleryApp(initialPage: 'charts'));
      await settle(tester);
      // A phone's pages are in the drawer behind the menu key; a desk's on the rail.
      if (width < 1024) {
        await tester.tap(find.byKey(const Key('gallery-menu')));
        await settle(tester);
      }
      await tester.tap(
        find.byKey(Key(width < 1024 ? 'drawer-home' : 'nav-home')).last,
      );
      await settle(tester);
      expect(tester.takeException(), isNull);
      expect(find.byKey(const ValueKey('hearth-home')), findsOneWidget);
    });
  }
}
