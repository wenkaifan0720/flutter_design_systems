// Large text: every gallery page at 200% text (WCAG's resize-text criterion)
// lays out with nothing overflowing, as ui_core's DesignOverflowCheck reads
// the layout: controls grow taller rather than cutting words. The everyday
// tier takes the first page; the sweep the rest.
// The gallery is the example app; a test reads its pages from there.
// ignore_for_file: avoid_relative_lib_imports
import 'dart:convert';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledger_ui/ledger_ui.dart';
import 'package:ui_core_test/ui_core_test.dart';

import 'tiers.dart';

import '../example/lib/gallery_pages.dart';

void main() {
  setUpAll(_loadFonts);
  for (final (i, page) in galleryPages.indexed) {
    testWidgets('${page.id} lays out at 200% text', tags: sweepUnless(i == 0), (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpWidget(page.build(Brightness.light));
      for (var i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 400));
      }
      final error = tester.takeException();
      // Each flex that overflowed, by the widget that made it.
      final over = [
        for (final o in tester.allRenderObjects)
          if (o.toStringShort().contains('OVERFLOWING'))
            '${'${o.debugCreator}'.split(' ← ').take(16).join(' ← ')} '
                '| words: ${_words(o)}',
      ];
      expect(
        error,
        isNull,
        reason: [
          if (error is FlutterError) error.toStringDeep() else '$error',
          ...over,
        ].join('\n'),
      );
      const DesignOverflowCheck(look: 'Ledger')
          .check(tester.binding.rootElement!)
          .verify();
    });
  }
}

/// The words under a render object, to say which one it is.
String _words(RenderObject o) {
  final words = <String>[];
  void visit(RenderObject c) {
    if (c is RenderParagraph) words.add(c.text.toPlainText());
    c.visitChildren(visit);
  }

  visit(o);
  return words.join(' / ');
}

/// The look's own faces, as the app bundles them: words measured in the
/// fonts a reader sees, not the test's square glyphs.
Future<void> _loadFonts() async {
  final manifest = json.decode(
    await rootBundle.loadString('FontManifest.json'),
  ) as List<dynamic>;
  for (final entry in manifest.cast<Map<String, dynamic>>()) {
    final family = entry['family'] as String;
    final loader = FontLoader(
      family.startsWith('packages/') ? family : ledgerFontFamily(family),
    );
    for (final font
        in (entry['fonts'] as List<dynamic>).cast<Map<String, dynamic>>()) {
      loader.addFont(rootBundle.load(font['asset'] as String));
    }
    await loader.load();
  }
}
