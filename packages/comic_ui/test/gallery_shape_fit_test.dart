// Exercise the actual reading, frame and composed-panel specimens, not replicas.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:comic_ui/comic_ui.dart';

// ignore_for_file: avoid_relative_lib_imports
import '../example/lib/kit_gallery/kit.dart';
import 'gallery_support.dart';
import 'shape_fit_support.dart';
import 'support.dart';
import 'tiers.dart';

void main() {
  setUpAll(() async {
    await loadComicFonts();
    await loadBundledFonts();
  });
  for (final (c, corners) in GalleryCorners.values.indexed) {
    for (final (w, width) in [390.0, 1440.0].indexed) {
      for (final (b, brightness) in Brightness.values.indexed) {
        for (final (s, id) in [
          'complete',
          'frames',
          'panels',
          'rows',
        ].indexed) {
          // Every run fits each specimen once under each corner family, the width and the mode turning with them so
          // any two of the four settings meet in each pair of their values; the sweep the other 48.
          final everyday = w == (c + s) % 2 && b == (c + s ~/ 2) % 2;
          testWidgets(
            '$id / ${corners.name} / $width / ${brightness.name}: 4 px outline clearance',
            (tester) async {
              kitShownTheme = (brightness) =>
                  CornerCustom(corners: corners).theme('offset', brightness);
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
            tags: sweepUnless(everyday),
          );
        }
      }
    }
  }
}
