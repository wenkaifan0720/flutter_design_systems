// Every gallery page lays out on a phone at twice the text size with nothing
// overflowing (DesignOverflowCheck).
// ignore_for_file: avoid_relative_lib_imports — the example's pages are what this test checks; example/ is not a dependency of the package.
import 'dart:convert';

import 'package:appliance_ui/appliance_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core_test/ui_core_test.dart';

import '../example/lib/gallery_pages.dart';
import '../example/lib/kit_gallery/larder/larder.dart';

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
  for (final (i, page) in galleryPages.indexed) {
    testWidgets('${page.title} at 200% text on a phone', (tester) async {
      // Tall enough that every section is laid out.
      tester.view.physicalSize = const Size(390, 16000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        LarderApp(
          parts: [
            for (final p in galleryPages) (title: p.title, build: p.build),
          ],
          initialPart: i,
          textScale: 2,
        ),
      );
      // The part's page opens after the first frame; spinners never settle.
      for (var n = 0; n < 4; n++) {
        await tester.pump(const Duration(milliseconds: 500));
      }
      const DesignOverflowCheck(look: 'Appliance')
          .check(tester.element(find.byType(LarderApp)))
          .verify();
    });
  }
}
