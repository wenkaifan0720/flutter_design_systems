import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

// ignore_for_file: avoid_relative_lib_imports — the gallery under test is the example app, not a package dependency.
import '../example/lib/gallery.dart';
import '../example/lib/kit_gallery/live.dart';
import 'gallery_support.dart' show loadBundledFonts, settle;
import 'support.dart' show loadNeumorphicFonts, sweepUnlessTurn;

/// Every gallery page at the largest text a reader sets (2.0), on a phone and on a desktop: nothing overflows, and no
/// part throws while it lays its words out.
void main() {
  setUpAll(() async {
    await loadNeumorphicFonts();
    await loadBundledFonts();
  });
  // Each page at one of the two widths every time, in turn, the other width than gallery_text_scale_test takes it at;
  // the sweep runs the rest.
  for (final (turn, page) in liveGalleryPages.indexed) {
    for (final (cell, width) in const [390.0, 1440.0].indexed) {
      testWidgets('${page.id} at text 2.0, $width wide', (tester) async {
        tester.view.physicalSize = Size(width, 2400);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          GalleryApp(
            initialPage: page.id,
            initialCustom: const GalleryCustom(textScale: 2),
          ),
        );
        await settle(tester);
        expect(tester.takeException(), isNull);
      }, tags: sweepUnlessTurn(turn + 1, cell, 2));
    }
  }
}
