import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

// ignore: avoid_relative_lib_imports
import '../example/lib/kit_gallery/hearth.dart' show hearthScreens;
// ignore: avoid_relative_lib_imports
import '../example/lib/kit_gallery/live.dart';
// ignore: avoid_relative_lib_imports
import '../example/lib/main.dart';
import 'gallery_support.dart'
    show inkedContrastFailures, loadBundledFonts, settle;
import 'support.dart' show loadNeumorphicFonts;
import 'world_checks.dart';

/// ui_core's shared world checks, as every look runs them: the gallery right to left, every page at twice the text
/// size, and Flutter's four accessibility guidelines on the main pages by day and by night.
void main() {
  setUpAll(() async {
    await loadNeumorphicFonts();
    await loadBundledFonts();
  });

  void desktop(WidgetTester tester, double width, double height) {
    tester.view.physicalSize = Size(width, height);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  // The pilaster's keys and a page's own controls stand mirrored when the gallery reads right to left.
  for (final page in const ['buttons', 'fields', 'selection']) {
    testWidgets('$page mirrors right to left', (tester) async {
      desktop(tester, 1440, 900);
      await expectMirrorsInRtl(
        tester,
        (direction) => GalleryApp(
          key: ValueKey(direction),
          initialPage: page,
          initialCustom: GalleryCustom(
            rightToLeft: direction == TextDirection.rtl,
          ),
        ),
        parts: [
          find.byKey(const Key('gallery-customize')),
          find.byKey(const Key('gallery-appearance')),
          find.byKey(Key('nav-$page')),
          find.byKey(const Key('nav-overview')),
        ],
      );
    });
  }

  // Every page at text 2.0 on a phone and a desk. The Feedback page's spinners never stop, so it never settles:
  // gallery_large_text_test holds it with a bounded settle.
  for (final page in liveGalleryPages) {
    if (page.id == 'feedback') continue;
    for (final width in const [390.0, 1440.0]) {
      testWidgets('${page.id} at text 2.0, $width wide', (tester) async {
        desktop(tester, width, 2400);
        await expectNoOverflowAtTextScale(
          tester,
          GalleryApp(initialPage: page.id),
        );
      });
    }
  }

  // The main pages and the app's screens, by day and by night.
  final main = {
    for (final id in const [
      'overview',
      'buttons',
      'fields',
      'selection',
      'pickers',
      'navigation',
      'lists',
      'cards',
      'dialogs',
    ])
      id,
    for (final screen in hearthScreens) screen.id,
  };
  for (final page in main) {
    for (final brightness in Brightness.values) {
      testWidgets('$page meets the guidelines ${brightness.name}', (
        tester,
      ) async {
        // A phone's pixels: at one pixel a point the contrast sampler reads a 14 px stem's antialiasing as the ink.
        tester.view.physicalSize = const Size(390 * 3, 3000 * 3);
        tester.view.devicePixelRatio = 3;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          GalleryApp(initialPage: page, initialBrightness: brightness),
        );
        await settle(tester);
        // The exception, named: text contrast is read with each paragraph's own ink against the colour most of its box
        // is painted (inkedContrastFailures), not by Flutter's textContrastGuideline. That guideline captures at one
        // pixel per logical pixel whatever the view's ratio, where a 14 to 16 px stem never fills a pixel: it took a
        // shade of the ground beside the words for their ink ("Every page", "App bar", "Hour": 1.03 to 1.12, both
        // colours the ground's). Its reading is kept in the failure message; the three target guidelines stand as they
        // are.
        final semantics = tester.ensureSemantics();
        try {
          await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
          await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
          await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
          final pixels = await textContrastGuideline.evaluate(tester);
          final inked = await inkedContrastFailures(tester);
          expect(
            inked,
            isEmpty,
            reason: pixels.passed
                ? null
                : "Flutter's reading: ${pixels.reason}",
          );
        } finally {
          semantics.dispose();
        }
      }, tags: ['goldens']);
    }
  }
}
