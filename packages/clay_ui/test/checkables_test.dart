// Every checkbox, radio and switch on Clay's gallery pages and Steady's screens says what it is (ui_core_test's
// DesignCheckableCheck): nothing checked or toggled also says it is a button, and every radio says whether it is
// checked. Each page is laid out whole, so every part of it is in the semantics tree.
// ignore_for_file: avoid_relative_lib_imports
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core_test/ui_core_test.dart';

import '../example/lib/everyday_screens.dart';
import '../example/lib/gallery_pages.dart';

Future<void> _check(WidgetTester tester, Widget page, double width) async {
  tester.view.physicalSize = Size(width, 12000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(page);
  // A skeleton breathes and a spinner turns for ever: a second lays
  // everything out without waiting for them to settle.
  await tester.pump(const Duration(seconds: 1));
  const DesignCheckableCheck(look: 'Clay')
      .check(tester.element(find.byType(Overlay).first))
      .verify();
}

void main() {
  for (final page in galleryPages) {
    testWidgets('gallery ${page.id}: each checkable says what it is', (
      tester,
    ) async {
      await _check(tester, page.build(Brightness.light), 1440);
    });
  }
  for (final screen in everydayScreens) {
    for (final width in const [390.0, 1440.0]) {
      testWidgets('${screen.id} at ${width.toInt()}: each checkable says what '
          'it is', (tester) async {
        await _check(
          tester,
          screen.app(Brightness.light, TextDirection.ltr),
          width,
        );
      });
    }
  }
}
