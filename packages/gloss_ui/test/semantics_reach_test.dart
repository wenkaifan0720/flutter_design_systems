// A screen reader reaches every heading of every gallery page, and every place
// beside it: an app or navigator nested in a page (Simmer's desk pane, a
// GlossPreview) blocks only what is under its own routes, never what was
// painted before it.
// ignore_for_file: avoid_relative_lib_imports
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gloss_ui/gloss_ui.dart';

import '../example/lib/gallery_pages.dart';
import '../example/lib/kit_gallery/kit.dart';
import '../example/lib/kit_gallery/simmer/simmer.dart';

Finder _heard(String words) =>
    find.bySemanticsLabel(RegExp('(^|\n)${RegExp.escape(words)}(\n|\$)'));

// Gloss's own faces, so a page lays out as it does on a phone.
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
  for (final width in const [390.0, 1440.0]) {
    for (final (i, page) in galleryPages.indexed) {
      testWidgets('${page.id} at ${width.toInt()}: every heading is heard', (
        tester,
      ) async {
        final semantics = tester.ensureSemantics();
        // Tall, so a page's sections stand on the screen together.
        tester.view.physicalSize = Size(width, 3000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          SimmerApp(
            parts: [
              for (final p in galleryPages) (title: p.title, build: p.build),
            ],
            initialPart: i,
          ),
        );
        // Some pages run on (a spinner): settle by time, not by quiet.
        for (var n = 0; n < 4; n++) {
          await tester.pump(const Duration(milliseconds: 500));
        }
        final screen = Offset.zero & tester.view.physicalSize;
        final sections = find.byType(KitSection);
        expect(sections, findsWidgets);
        for (final e in sections.evaluate()) {
          final r = tester.getRect(find.byWidget(e.widget));
          if (!r.overlaps(screen)) continue;
          expect(
            _heard((e.widget as KitSection).title),
            findsWidgets,
            reason: '${page.id}: "${(e.widget as KitSection).title}"',
          );
        }
        // On a desk the page stands in Simmer's own navigator, beside the
        // sidebar; every place stays heard.
        if (width >= 1024) {
          for (final place in const [
            'Gloss',
            'Today',
            'Recipes',
            'List',
            'Settings',
          ]) {
            expect(
              find.bySemanticsLabel(RegExp('^${RegExp.escape(place)}(\n|\$)')),
              findsWidgets,
              reason: '${page.id}: the place $place',
            );
          }
        }
        semantics.dispose();
      });
    }
  }

  testWidgets('a heading before a GlossPreview is heard', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: GlossTheme(
          data: GlossThemeData.jade(Brightness.light),
          child: Column(
            children: [
              Semantics(header: true, child: const Text('Before the preview')),
              const Expanded(
                child: GlossPreview(
                  child: GlossScreen(body: Text('Serves two.')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));
    expect(_heard('Before the preview'), findsOneWidget);
    expect(_heard('Serves two.'), findsOneWidget);
    semantics.dispose();
  });
}
