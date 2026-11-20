// Every page of Clay's gallery builds and lays out on a phone and a desk, by day and by night, and at 200% text on a
// phone, with nothing thrown and nothing leaked.
// ignore_for_file: avoid_relative_lib_imports
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import '../example/lib/gallery_pages.dart';

void main() {
  const cases = [
    (name: 'phone by day', width: 390.0, dark: false, scale: 1.0),
    (name: 'phone by night', width: 390.0, dark: true, scale: 1.0),
    (name: 'desk by day', width: 1440.0, dark: false, scale: 1.0),
    (name: 'desk by night', width: 1440.0, dark: true, scale: 1.0),
    (name: 'phone at 200% text', width: 390.0, dark: false, scale: 2.0),
  ];
  for (final page in galleryPages) {
    for (final c in cases) {
      testWidgets('${page.id}, ${c.name}', (tester) async {
        tester.view.physicalSize = Size(c.width, 900);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = c.scale;
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await tester.pumpWidget(
          page.build(c.dark ? Brightness.dark : Brightness.light),
        );
        // A skeleton breathes and a spinner turns for ever: a second lays
        // everything out without waiting for them to settle.
        await tester.pump(const Duration(seconds: 1));
        expect(tester.takeException(), isNull);
        // Down the page: every section lays out as it scrolls into view.
        final scrollable = find.byType(Scrollable).first;
        for (var i = 0; i < 12; i++) {
          await tester.drag(scrollable, const Offset(0, -700));
          await tester.pump(const Duration(milliseconds: 300));
          expect(tester.takeException(), isNull);
        }
      });
    }
  }
}
