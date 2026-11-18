// Simmer's everyday screens at a phone's, a tablet's and a desktop's width, by day and by night: each lays out with
// nothing overflowing and nothing thrown.
// ignore_for_file: avoid_relative_lib_imports
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gloss_ui/gloss_ui.dart';

import '../example/lib/everyday_screens.dart';

Future<void> _loadFonts() async {
  final manifest = json.decode(
    await rootBundle.loadString('FontManifest.json'),
  ) as List<dynamic>;
  for (final entry in manifest.cast<Map<String, dynamic>>()) {
    final family = entry['family'] as String;
    final loader = FontLoader(
      family.startsWith('packages/') ? family : glossRegisteredFamily(family),
    );
    for (final font
        in (entry['fonts'] as List<dynamic>).cast<Map<String, dynamic>>()) {
      loader.addFont(rootBundle.load(font['asset'] as String));
    }
    await loader.load();
  }
}

void main() {
  setUpAll(_loadFonts);
  for (final screen in everydayScreens) {
    for (final width in const [390.0, 768.0, 1440.0]) {
      for (final brightness in Brightness.values) {
        testWidgets('${screen.id} at ${width.toInt()} by ${brightness.name}', (
          tester,
        ) async {
          tester.view.physicalSize = Size(width, width < 600 ? 844 : 900);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          await tester.pumpWidget(screen.app(brightness, TextDirection.ltr));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        });
      }
    }
  }
}
