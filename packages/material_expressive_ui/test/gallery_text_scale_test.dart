// Large text: every gallery page at 200% text (WCAG's resize-text criterion)
// lays out with nothing overflowing, as ui_core's DesignOverflowCheck reads
// the layout: controls grow taller rather than cutting words. The everyday
// tier takes the first page; the sweep the rest.
// The gallery is the example app; a test reads its pages from there.
// ignore_for_file: avoid_relative_lib_imports
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core_test/ui_core_test.dart';

import '../example/lib/main.dart';
import '../example/lib/kit_gallery/theme.dart';
import 'gallery_support.dart';
import 'support/tiers.dart';

void main() {
  setUpAll(loadExpressiveFonts);
  for (final (i, page) in galleryExamplePages.indexed) {
    testWidgets('${page.id} lays out at 200% text', tags: sweepUnless(i == 0), (
      tester,
    ) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await pumpGalleryPage(tester, page, kitPreset, Brightness.light);
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
      const DesignOverflowCheck(look: 'Material Expressive')
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
