// Every gallery page lays out at twice the text on a phone with nothing
// standing past its row or its column, as ui_core_test's
// DesignOverflowCheck reads them.
// ignore_for_file: avoid_relative_lib_imports
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studio_ui/studio_ui.dart';
import 'package:ui_core_test/ui_core_test.dart';

import '../example/lib/gallery_pages.dart';

void main() {
  setUpAll(studioLoadFonts);

  for (final page in galleryPages) {
    testWidgets('${page.id} at 2x text on a phone: nothing overflows', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpWidget(page.build(Brightness.light));
      // A spinner never settles: let the page arrive, then read it.
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));
      expect(tester.takeException(), isNull);
      final report = const DesignOverflowCheck(look: 'studio')
          .check(tester.element(find.byType(Navigator).first));
      expect(report.problems, isEmpty);
    });
  }
}
