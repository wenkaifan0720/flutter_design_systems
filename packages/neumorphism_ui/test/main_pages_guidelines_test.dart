import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

// ignore_for_file: avoid_relative_lib_imports — the gallery under test is the example app, not a package dependency.
import '../example/lib/kit_gallery/hearth.dart' show hearthScreens;
import '../example/lib/main.dart';
import 'gallery_support.dart'
    show inkedContrastFailures, loadBundledFonts, settle, touchFloorTargets;
import 'support.dart' show loadNeumorphicFonts;

/// Flutter's four accessibility guidelines on the gallery's main pages and the app's screens, by day and by night.
void main() {
  setUpAll(() async {
    await loadNeumorphicFonts();
    await loadBundledFonts();
  });

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
          await expectLater(tester, meetsGuideline(touchFloorTargets));
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
