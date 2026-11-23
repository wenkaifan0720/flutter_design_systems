// At 200% text on a phone, by day and by night, nothing on any page of
// Keycap's gallery overflows its row or column, down the page
// (DesignOverflowCheck), and nothing throws.
// ignore_for_file: avoid_relative_lib_imports
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core_test/ui_core_test.dart';

import '../example/lib/gallery_pages.dart';

void main() {
  for (final page in galleryPages) {
    for (final dark in [false, true]) {
      testWidgets(
        '${page.id} at 200% text on a phone, ${dark ? 'by night' : 'by day'}',
        (tester) async {
          tester.view.physicalSize = const Size(390, 844);
          tester.view.devicePixelRatio = 1;
          tester.platformDispatcher.textScaleFactorTestValue = 2;
          addTearDown(tester.view.reset);
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          final built = page.build(dark ? Brightness.dark : Brightness.light);
          await tester.pumpWidget(built);
          void noOverflow() =>
              const DesignOverflowCheck(look: 'Keycap')
                  .check(tester.element(find.byWidget(built)))
                  .verify();

          // A spinner turns for ever: a second lays everything out without
          // waiting for it to settle.
          await tester.pump(const Duration(seconds: 1));
          expect(tester.takeException(), isNull);
          noOverflow();
          // Down the page: every section lays out as it scrolls into view.
          final scrollable = find.byType(Scrollable).first;
          for (var i = 0; i < 12; i++) {
            await tester.drag(scrollable, const Offset(0, -700));
            await tester.pump(const Duration(milliseconds: 300));
            expect(tester.takeException(), isNull);
            noOverflow();
          }
        },
      );
    }
  }
}
