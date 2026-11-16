// Brindlemere parking permits' ten screens, pixel for pixel: at 390 by day
// and by night, and at 1440 by day on a desk's platform. The goldens are
// kept beside the catalog and laid here by the package build; a published
// or vendored copy goes without them, and compares nothing.
// `flutter test --update-goldens --tags goldens` records them; elsewhere
// than macOS, `flutter test --exclude-tags goldens`.
// ignore_for_file: avoid_relative_lib_imports
import 'dart:convert';
import 'dart:io';

import 'package:civic_ui/civic_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../example/lib/everyday_screens.dart';

Future<void> _loadFonts() async {
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

final bool _recorded =
    autoUpdateGoldenFiles || Directory('test/goldens').existsSync();

final _shot = GlobalKey();

void main() {
  setUpAll(_loadFonts);

  const configs = [
    (390.0, Brightness.light),
    (390.0, Brightness.dark),
    (1440.0, Brightness.light),
  ];

  for (final screen in everydayScreens) {
    for (final (width, brightness) in configs) {
      testWidgets(
        '${screen.id} at $width by ${brightness == Brightness.dark ? 'night' : 'day'} matches its golden',
        (tester) async {
          tester.view.physicalSize = Size(width, width < 600 ? 844 : 900);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          await tester.pumpWidget(
            RepaintBoundary(
              key: _shot,
              child: screen.app(brightness, TextDirection.ltr),
            ),
          );
          for (var i = 0; i < 20; i++) {
            await tester.pump(const Duration(milliseconds: 50));
          }
          expect(tester.takeException(), isNull);
          await expectLater(
            find.byKey(_shot),
            matchesGoldenFile(
              'goldens/screens/${screen.id}_${brightness.name}_${width.toInt()}.png',
            ),
          );
        },
        // A desk's platform at 1440: a pointer's tap floors.
        variant: width >= 1024
            ? TargetPlatformVariant.only(TargetPlatform.macOS)
            : const DefaultTestVariant(),
        skip: !_recorded,
        tags: const ['goldens'],
      );
    }
  }
}
