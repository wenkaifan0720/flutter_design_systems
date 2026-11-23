// Every gallery page lays out at twice the text on a phone with nothing
// standing past its row or its column, as ui_core_test's
// DesignOverflowCheck reads them.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core_test/ui_core_test.dart';

// The gallery is the example app; a test reads its presets from there.
// ignore_for_file: avoid_relative_lib_imports
import '../example/lib/kit_gallery/theme.dart' show kitPreset;
import 'gallery_support.dart';

void main() {
  setUpAll(loadFluent2TestFonts);

  for (final page in galleryPages) {
    testWidgets('${page.id} at 2x text on a phone: nothing overflows', (
      tester,
    ) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await pumpGalleryPage(tester, page, kitPreset, Brightness.light);
      expect(tester.takeException(), isNull);
      final report = const DesignOverflowCheck(look: 'fluent2')
          .check(tester.element(find.byType(Navigator).first));
      expect(report.problems, isEmpty);
    });
  }
}
