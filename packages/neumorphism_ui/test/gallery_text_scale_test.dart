import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core_review/ui_core_review.dart' show DesignOverflowCheck;

// ignore_for_file: avoid_relative_lib_imports — the gallery under test is the example app, not a package dependency.
import '../example/lib/kit_gallery/live.dart';
import '../example/lib/main.dart';
import 'gallery_support.dart' show loadBundledFonts;
import 'support.dart' show loadNeumorphicFonts, sweepUnlessTurn;
import 'world_checks.dart';

/// Every gallery page at twice the text size, on a phone and on a desktop: nothing overflows, nothing throws, and
/// ui_core's overflow check finds no text cut and nothing past its box.
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

  // Every page at text 2.0 on a phone and a desk. The Feedback page's spinners never stop, so it never settles:
  // gallery_large_text_test holds it with a bounded settle.
  // Each page at one of the two widths every time, in turn, the other width than gallery_large_text_test takes it at;
  // the sweep runs the rest.
  for (final (turn, page) in liveGalleryPages.indexed) {
    if (page.id == 'feedback') continue;
    for (final (cell, width) in const [390.0, 1440.0].indexed) {
      testWidgets('${page.id} at text 2.0, $width wide', (tester) async {
        desktop(tester, width, 2400);
        await expectNoOverflowAtTextScale(
          tester,
          GalleryApp(initialPage: page.id),
        );
        const DesignOverflowCheck(look: 'Neumorphism')
            .check(tester.element(find.byType(GalleryApp)))
            .verify();
      }, tags: sweepUnlessTurn(turn, cell, 2));
    }
  }
}
