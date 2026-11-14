// Every gallery page right to left and at twice the text size, by day and by night: it lays out with no overflow and
// no other error. What mirrors is held by the parts' own right-to-left tests (rtl_mirror_test.dart); this holds the
// pages whole, previews and overlays included. A failure names the widget that overflowed and where it is built.
import 'package:flutter/foundation.dart' show FlutterError;
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart' show Brightness;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';

import 'gallery_support.dart';

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
  setUpAll(loadExpressiveFonts);

  final preset = ExpressiveThemeData.presets.first;
  for (final page in galleryPages) {
    for (final b in Brightness.values) {
      testWidgets('${page.id} right to left, ${b.name}', (tester) async {
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
      });

      testWidgets('${page.id} at text scale 2.0, ${b.name}', (tester) async {
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await _expectClean(() => pumpGalleryPage(tester, page, preset, b));
        expect(tester.takeException(), isNull);
      });
    }
  }
}
