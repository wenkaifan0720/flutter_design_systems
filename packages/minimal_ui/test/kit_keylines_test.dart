// ui_core's keyline check (DesignKeylineCheck) over the regions Minimal's
// card, sections and page body mark, on the same screens as
// keylines_test.dart. Where the check misreads a screen it is skipped with
// the misreading named.
// ignore_for_file: avoid_relative_lib_imports, avoid_print
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/alignment.dart';

import 'keylines_test.dart'
    show
        keylineScreens,
        loadKeylineFonts,
        openKeylineScreen,
        precacheShownImages;

/// Screens the check misreads, by `name at width`, with the misreading.
const Map<String, String> _misreadings = {};

void main() {
  setUpAll(loadKeylineFonts);

  for (final size in const [Size(390, 844), Size(1440, 900)]) {
    for (final screen in keylineScreens) {
      final at = '${screen.name} at ${size.width.round()}';
      testWidgets(at, skip: _misreadings.containsKey(at), (tester) async {
        await openKeylineScreen(tester, screen, size);
        await precacheShownImages(tester);
        final root = screen.scope ?? find.byType(WidgetsApp);
        final report = await const DesignKeylineCheck(look: 'Minimal')
            .check(tester.element(root.first), runAsync: tester.runAsync);
        print('$at: ${report.problems.length} named');
        for (final p in report.problems) {
          print('  $p');
        }
        report.verify();
      }, tags: 'goldens');
    }
  }
}
