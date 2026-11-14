// Large text: every gallery page at 200% text (WCAG's resize-text criterion, the host's ceiling) lays out with
// nothing overflowing: controls grow taller rather than cutting words, and long words wrap or ellipsize on purpose.
// A RenderFlex overflow, or any other layout error, fails the page.
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'gallery_support.dart';

import 'package:frosted_ui/frosted_ui.dart';

void main() {
  setUpAll(frostedLoadFonts);
  final (preset, day) = presetsAndModes.first;
  for (final page in galleryPages) {
    testWidgets('${page.id} lays out at 200% text', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await pumpGalleryPage(tester, page, preset, day);
      final error = tester.takeException();
      // Each flex that overflowed, by the widget that made it.
      final over = [
        for (final o in tester.allRenderObjects)
          if (o.toStringShort().contains('OVERFLOWING'))
            '${'${o.debugCreator}'.split(' ← ').take(24).join(' ← ')} '
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
