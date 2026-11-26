// Foundations › Colour shows each of the look's colours as a swatch: a face
// as wide as its name's column, not a hairline.
import 'dart:convert';

import 'package:appliance_ui/appliance_ui.dart';
import 'package:appliance_ui_example/gallery_pages.dart';
import 'package:appliance_ui_example/kit_gallery/larder/larder.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

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
  for (final width in [390.0, 1440.0]) {
    testWidgets('at $width, every colour shows as a swatch', (tester) async {
      tester.view
        ..devicePixelRatio = 1
        ..physicalSize = Size(width, 4000);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        LarderApp(
          parts: [
            for (final p in galleryPages) (title: p.title, build: p.build),
          ],
          initialPart: galleryPages.indexWhere((p) => p.id == 'foundations'),
        ),
      );
      for (var n = 0; n < 4; n++) {
        await tester.pump(const Duration(milliseconds: 500));
      }
      for (final name in [
        'Housing',
        'Face',
        'Well',
        'Key',
        'Print',
        'Signal',
        'Display',
        'Danger',
      ]) {
        final column = find
            .ancestor(of: find.text(name).first, matching: find.byType(Column))
            .first;
        final swatch = find
            .descendant(of: column, matching: find.byType(ApplianceSurface))
            .first;
        expect(
          tester.getSize(swatch).width,
          greaterThanOrEqualTo(tester.getSize(find.text(name).first).width),
          reason: "$name's swatch is narrower than its name",
        );
      }
    });
  }
}
