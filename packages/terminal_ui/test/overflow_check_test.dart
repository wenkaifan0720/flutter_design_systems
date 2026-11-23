// Every gallery page lays out at twice the text on a phone with nothing
// standing past its row or its column, as ui_core_test's
// DesignOverflowCheck reads them.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core_test/ui_core_test.dart';

// The example's pages are the ones under test.
// ignore_for_file: avoid_relative_lib_imports
import '../example/lib/gallery_pages.dart';
import 'faces.dart';

void main() {
  setUpAll(loadFaces);

  for (final page in galleryPages) {
    testWidgets('${page.id} at 2x text on a phone: nothing overflows', (
      tester,
    ) async {
      // Tall enough that every part of the page is laid out.
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 8000);
      addTearDown(tester.view.reset);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpWidget(page.build(Brightness.dark));
      for (var k = 0; k < 8; k++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(tester.takeException(), isNull);
      final report = const DesignOverflowCheck(look: 'terminal')
          .check(tester.element(find.byType(Navigator).first));
      expect(report.problems, isEmpty);
    });
  }
}
