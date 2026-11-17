// Brindlemere parking permits' everyday screens in every setting Civic holds
// them to: at 390, 768 and 1440, by day and by night, and at 390 right to
// left in Arabic and at twice the text; nothing overflows or throws.
//
// The everyday run (screens_test) takes each screen once, the settings dealt
// round the screens, so each width, each theme, right to left and twice the
// text are met every run. The sweep (tagged `sweep`, run at READY and
// release) takes the rest, a phone's settings and the wider ones in a process
// each (screens_sweep_phone_test, screens_sweep_wide_test): Flutter 3.47's
// EditableText stays reachable after its test, so a screen with a field
// keeps its whole tree until its process ends, and one process for all 90
// reached 2.5 GB.
// ignore_for_file: avoid_relative_lib_imports
import 'dart:convert';

import 'package:civic_ui/civic_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../example/lib/everyday_screens.dart';

/// Loads the faces the screens are drawn in (from `setUpAll`).
Future<void> loadScreenFonts() async {
  final manifest = json.decode(
    await rootBundle.loadString('FontManifest.json'),
  ) as List<dynamic>;
  for (final entry in manifest.cast<Map<String, dynamic>>()) {
    final family = entry['family'] as String;
    final loader = FontLoader(
      family.startsWith('packages/') ? family : civicFontFamily(family),
    );
    for (final font
        in (entry['fonts'] as List<dynamic>).cast<Map<String, dynamic>>()) {
      loader.addFont(rootBundle.load(font['asset'] as String));
    }
    await loader.load();
  }
}

/// Shows [app] [width] wide and [height] tall, its words at [text] times
/// their size, then runs a second of its frames.
Future<void> showScreen(
  WidgetTester tester,
  Widget app, {
  required double width,
  double height = 900,
  double text = 1,
}) async {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = text;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  await tester.pumpWidget(app);
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// A setting a screen is held to: its width, its theme, its direction and
/// the scale of its words.
typedef ScreenSetting = (
  double width,
  Brightness brightness,
  TextDirection direction,
  double text,
);

/// Every setting.
const List<ScreenSetting> screenSettings = [
  (390, Brightness.light, TextDirection.ltr, 1),
  (390, Brightness.dark, TextDirection.ltr, 1),
  (768, Brightness.light, TextDirection.ltr, 1),
  (1440, Brightness.dark, TextDirection.ltr, 1),
  (390, Brightness.light, TextDirection.rtl, 1),
  (390, Brightness.light, TextDirection.ltr, 2),
];

/// Whether the everyday run takes screen [screen] in setting [setting]: each
/// screen once, the settings dealt round the screens.
bool everyRun(int screen, int setting) =>
    setting == screen % screenSettings.length;

/// A test of each everyday screen in each setting [include] takes (by the
/// screen's index and the setting's).
void screensMatrix(bool Function(int screen, int setting) include) {
  // Enough screens that every setting is dealt one every run.
  assert(everydayScreens.length >= screenSettings.length);
  for (final (i, screen) in everydayScreens.indexed) {
    for (final (j, (width, brightness, direction, text))
        in screenSettings.indexed) {
      if (!include(i, j)) continue;
      testWidgets(
        '${screen.id} at $width, ${brightness.name}, ${direction.name}, '
        'text ×$text',
        (tester) async {
          await showScreen(
            tester,
            screen.app(brightness, direction),
            width: width,
            text: text,
          );
          expect(tester.takeException(), isNull);
          expect(find.byType(CivicScaffold), findsOneWidget);
        },
      );
    }
  }
}
