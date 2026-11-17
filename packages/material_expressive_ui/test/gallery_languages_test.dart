// Every gallery page right to left and at twice the text size, by day and by night: it lays out with no overflow and
// no other error. What mirrors is held by the parts' own right-to-left tests (rtl_mirror_test.dart); this holds the
// pages whole, previews and overlays included. A failure names the widget that overflowed and where it is built.
import 'package:flutter/foundation.dart' show FlutterError;
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart' show Brightness;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';
import 'package:leak_tracker_flutter_testing/leak_tracker_flutter_testing.dart';

import 'flutter_test_config.dart' show pageWalkLeakTesting;
import 'gallery_support.dart';
import 'support/tiers.dart';

/// Runs [pump] and expects no error reported while it runs, each error
/// given whole (an overflow's widget and its source line) on failure.
Future<void> _expectClean(Future<void> Function() pump) async {
  final errors = <String>[];
  final previous = FlutterError.onError;
  FlutterError.onError = (details) => errors.add(details.toString());
  try {
    await pump();
  } finally {
    FlutterError.onError = previous;
  }
  expect(errors, isEmpty, reason: errors.join('\n'));
}

void main() {
  LeakTesting.settings = pageWalkLeakTesting;
  setUpAll(loadExpressiveFonts);

  final preset = ExpressiveThemeData.presets.first;
  // Every page right to left and at 2.0 text, by day and night; the everyday
  // tier reads each of the four once, each on another page (support/tiers).
  for (final (row, page) in galleryPages.indexed) {
    for (final (m, b) in Brightness.values.indexed) {
      testWidgets(
        '${page.id} right to left, ${b.name}',
        tags: sweepUnless(everydayOnce(row, m, galleryPages.length, 4)),
        (tester) async {
          await _expectClean(
            () => pumpGalleryPage(
              tester,
              page,
              preset,
              b,
              direction: TextDirection.rtl,
            ),
          );
          expect(tester.takeException(), isNull);
        },
      );

      testWidgets(
        '${page.id} at text scale 2.0, ${b.name}',
        tags: sweepUnless(everydayOnce(row, 2 + m, galleryPages.length, 4)),
        (tester) async {
          tester.platformDispatcher.textScaleFactorTestValue = 2;
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          await _expectClean(() => pumpGalleryPage(tester, page, preset, b));
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
