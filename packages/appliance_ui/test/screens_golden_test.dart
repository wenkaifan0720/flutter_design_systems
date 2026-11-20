// Larder's everyday screens on a phone and a desktop, by day and by night,
// each matching its golden.
// ignore_for_file: avoid_relative_lib_imports
import 'dart:convert';
import 'dart:io';

import 'package:appliance_ui/appliance_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../example/lib/everyday_screens.dart';

/// Compare saved images when they are available, or record them when requested.
final bool _recorded =
    autoUpdateGoldenFiles || Directory('test/goldens').existsSync();

Future<void> _loadFonts() async {
  final manifest = json.decode(
    await rootBundle.loadString('FontManifest.json'),
  ) as List<dynamic>;
  for (final entry in manifest.cast<Map<String, dynamic>>()) {
    final family = entry['family'] as String;
    final loader = FontLoader(
      family.startsWith('packages/')
          ? family
          : applianceRegisteredFamily(family),
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
    for (final width in const [390.0, 1440.0]) {
      for (final brightness in Brightness.values) {
        final name = '${screen.id}_${width.toInt()}_${brightness.name}';
        testWidgets(
          '${screen.id} at ${width.toInt()} by ${brightness.name} matches its golden',
          (tester) async {
            tester.view.physicalSize = Size(width, width < 600 ? 844 : 900);
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.reset);
            await tester.pumpWidget(screen.app(brightness, TextDirection.ltr));
            await tester.pumpAndSettle();
            await expectLater(
              find.byType(WidgetsApp).first,
              matchesGoldenFile('goldens/screens/$name.png'),
            );
          },
          // Pixels recorded on macOS: `flutter test --exclude-tags goldens`
          // leaves them out elsewhere.
          skip: !_recorded,
          tags: const ['goldens'],
        );
      }
    }
  }
}
