// The package build moves the catalog gallery into example/lib; its tests intentionally import those demos.
// ignore_for_file: avoid_relative_lib_imports

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
          testWidgets('${entry.key} at $width $brightness text $scale', (
            tester,
          ) async {
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
          });
        }
      }
    }
  }
}
