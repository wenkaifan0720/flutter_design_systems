// The Foundations page's print runs: six across on a desk, each its run's panel on its gutter, so the strip reads as
// the six side by side; two across on a phone.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:comic_ui/comic_ui.dart';

import 'gallery_support.dart';
import 'support.dart';

void main() {
  setUpAll(loadComicFonts);

  for (final (width, across) in const [(1440.0, 6), (390.0, 2)]) {
    testWidgets('the print runs stand $across across at $width', (
      tester,
    ) async {
      final page = galleryPages.firstWhere((p) => p.id == 'foundations');
      await pumpGalleryPage(
        tester,
        page,
        'offset',
        Brightness.light,
        width: width,
      );
      final tops = <double>{
        for (final id in ComicThemeData.presets)
          tester.getRect(find.text(id.toUpperCase()).first).top.roundToDouble(),
      };
      expect(tops, hasLength(ComicThemeData.presets.length ~/ across));
      for (final id in ComicThemeData.presets) {
        final run = ComicThemeData.preset(id, Brightness.light).colors;
        // The run's panel and its gutter both show.
        final boxes = tester
            .widgetList<DecoratedBox>(
              find.ancestor(
                of: find.text(id.toUpperCase()).first,
                matching: find.byType(DecoratedBox),
              ),
            )
            .map(
              (b) => switch (b.decoration) {
                ShapeDecoration(:final color) => color,
                BoxDecoration(:final color) => color,
                _ => null,
              },
            )
            .toSet();
        expect(
          boxes,
          containsAll(<Color>[run.card, run.background]),
          reason: id,
        );
      }
    });
  }
}
