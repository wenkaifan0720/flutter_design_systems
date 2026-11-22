// ignore_for_file: avoid_relative_lib_imports — the example app's pages are what this test checks; example/ is not a dependency of the package.

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import '../example/lib/kit_gallery/demos/raised.dart';
import '../example/lib/kit_gallery/demos/entries.dart';
import '../example/lib/kit_gallery/demos/complete.dart';

import 'support.dart';

void main() {
  setUpAll(loadRetroDesktopFonts);
  final demos = <String, Widget Function(Brightness)>{
    'raised': kitRaisedDemo,
    'entries': kitEntriesDemo,
    'complete': kitCompleteDemo,
  };
  for (final entry in demos.entries) {
    for (final width in [390.0, 1440.0]) {
      for (final brightness in Brightness.values) {
        for (final scale in [1.0, 2.0]) {
          // Every day: a light phone at 1x and a dark desk at 2x; the other six in the sweep.
          final everyday = width == 390
              ? brightness == Brightness.light && scale == 1
              : brightness == Brightness.dark && scale == 2;
          testWidgets(
            '${entry.key} at $width $brightness text $scale',
            tags: sweepUnless(everyday),
            (tester) async {
              tester.view.physicalSize = Size(width, 1400);
              tester.view.devicePixelRatio = 1;
              tester.platformDispatcher.textScaleFactorTestValue = scale;
              addTearDown(tester.view.reset);
              addTearDown(
                tester.platformDispatcher.clearTextScaleFactorTestValue,
              );
              await tester.pumpWidget(entry.value(brightness));
              await tester.pumpAndSettle();
              expect(tester.takeException(), isNull);
            },
          );
        }
      }
    }
  }
}
