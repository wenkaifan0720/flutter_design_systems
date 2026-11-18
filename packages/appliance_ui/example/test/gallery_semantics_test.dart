// Every page of the gallery reads to a screen reader in full, on a phone and
// on a desk: each section's heading is in the semantics tree, and on a desk so
// are the side panel's places. A Navigator or an app nested in a page (the
// desk's body, the router's pages, a framed preview) stands in a semantics
// container of its own. Without one, its first page's modal barrier blocks
// the semantics of everything painted before it in the same container.
import 'dart:convert';

import 'package:appliance_ui/appliance_ui.dart';
import 'package:appliance_ui_example/gallery_pages.dart';
import 'package:appliance_ui_example/kit_gallery/larder/larder.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

// Appliance's own faces, so the pages lay out as they do in the gallery (the
// test font's square glyphs are wider).
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

// Whether a node of the semantics tree reads [words] (alone, or merged with
// what stands beside them, as a specimen's legend under its row's name).
bool _read(String words) =>
    find.semantics.byLabel(RegExp(RegExp.escape(words))).evaluate().isNotEmpty;

void main() {
  setUpAll(_loadFonts);
  for (final width in [390.0, 1440.0]) {
    for (final (i, page) in galleryPages.indexed) {
      testWidgets('at $width, ${page.title}: every section heading is read', (
        tester,
      ) async {
        final semantics = tester.ensureSemantics();
        // Tall enough that every section stands in the window.
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(width, 16000);
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          LarderApp(
            parts: [
              for (final p in galleryPages) (title: p.title, build: p.build),
            ],
            initialPart: i,
          ),
        );
        // The part's page opens after the first frame; spinners never settle.
        for (var n = 0; n < 4; n++) {
          await tester.pump(const Duration(milliseconds: 500));
        }
        // Every legend over a section: a demo's sections, the inventory's
        // groups.
        final titles = [
          for (final h in tester.widgetList<ApplianceSectionHeader>(
            find.byType(ApplianceSectionHeader),
          ))
            h.text,
        ];
        expect(titles, isNotEmpty, reason: '${page.title} shows no section');
        final unread = [
          for (final t in titles)
            if (!_read(t)) t,
        ];
        expect(unread, isEmpty, reason: 'headings missing from semantics');
        if (width >= 1024) {
          final places = ['Home', 'Shop', 'Basket', 'Orders', 'Settings'];
          final lost = [
            for (final p in places)
              if (find.semantics.byLabel(RegExp('^$p\\b')).evaluate().isEmpty)
                p,
          ];
          expect(lost, isEmpty, reason: "the side panel's places unread");
        }
        semantics.dispose();
      });
    }
  }

  // Larder's own places on a desk: its pages stand in a navigator beside the
  // side panel, and both are read.
  for (final place in [LarderPlace.home, LarderPlace.orders]) {
    testWidgets('at 1440, Larder ${place.name}: the side panel and the page '
        'are read', (tester) async {
      final semantics = tester.ensureSemantics();
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1440, 900);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(LarderApp(initialPlace: place));
      for (var n = 0; n < 4; n++) {
        await tester.pump(const Duration(milliseconds: 500));
      }
      // The places other than the one open (whose name the page's bar reads
      // too).
      final lost = [
        for (final p in ['Home', 'Shop', 'Basket', 'Orders', 'Settings'])
          if (p.toLowerCase() != place.name &&
              find.semantics.byLabel(RegExp('^$p\\b')).evaluate().isEmpty)
            p,
      ];
      expect(lost, isEmpty, reason: "the side panel's places unread");
      final headings = [
        for (final h in tester.widgetList<ApplianceSectionHeader>(
          find.byType(ApplianceSectionHeader),
        ))
          if (!_read(h.text)) h.text,
      ];
      expect(headings, isEmpty, reason: "the page's headings unread");
      semantics.dispose();
    });
  }
}
