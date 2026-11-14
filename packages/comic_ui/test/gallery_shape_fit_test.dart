// Exercise the actual reading, frame and composed-panel specimens, not replicas.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:comic_ui/comic_ui.dart';

// ignore_for_file: avoid_relative_lib_imports
import '../example/lib/kit_gallery/kit.dart';
import '../example/lib/main.dart';
import 'gallery_support.dart';
import 'shape_fit_support.dart';
import 'support.dart';

void main() {
  setUpAll(() async {
    await loadComicFonts();
    await loadBundledFonts();
  });
  for (final corners in GalleryCorners.values) {
    for (final width in [390.0, 1440.0]) {
      for (final brightness in Brightness.values) {
        for (final id in ['complete', 'frames', 'panels', 'rows']) {
          testWidgets(
            '$id / ${corners.name} / $width / ${brightness.name}: 4 px outline clearance',
            (tester) async {
              kitShownTheme = (brightness) =>
                  GalleryCustom(corners: corners).theme('offset', brightness);
              addTearDown(() => kitShownTheme = null);
              final page = galleryPages.singleWhere((page) => page.id == id);
              await pumpGalleryPage(
                tester,
                page,
                'offset',
                brightness,
                width: width,
              );
              expect(tester.takeException(), isNull);
              expectComicContentClearance(tester);
              if (id == 'complete') {
                final calendar = find.byType(ComicDatePicker);
                final scroll = find.descendant(
                  of: calendar,
                  matching: find.byType(Scrollable),
                );
                expect(scroll, findsOneWidget);
                expect(
                  tester
                      .state<ScrollableState>(scroll)
                      .position
                      .maxScrollExtent,
                  0,
                  reason: 'All seven date columns must fit a normal phone',
                );
              }
            },
          );
        }
      }
    }
  }
}
