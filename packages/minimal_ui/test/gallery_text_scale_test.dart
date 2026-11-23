// Every gallery page lays out on a phone at the largest text Minimal lays
// out (200%) with nothing overflowing (DesignOverflowCheck).
// ignore_for_file: avoid_relative_lib_imports
@Tags(['goldens'])
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core_review/ui_core_review.dart';

import '../example/lib/main.dart';
import 'flutter_test_config.dart' show longWalkLeakTesting;

void main() {
  for (final page in galleryPagesAll) {
    final slug = GalleryApp.pageSlug(page.name);
    testWidgets('${page.name} at 200% text on a phone', (tester) async {
      // Tall enough that every section is laid out.
      tester.view.physicalSize = const Size(390, 12000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        GalleryApp.at(Uri.parse('http://localhost/?page=$slug&text=2')),
      );
      for (var i = 0; i < 3; i++) {
        await tester.pump(const Duration(seconds: 1));
      }
      const DesignOverflowCheck(look: 'Minimal')
          .check(tester.element(find.byType(GalleryApp)))
          .verify();
    }, experimentalLeakTesting: longWalkLeakTesting);
  }
}
