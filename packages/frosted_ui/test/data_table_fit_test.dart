// The gallery's data table on a phone (390 wide): at the reader's own text size it keeps to its card, its checks
// giving up their inset first, and no word breaks; with larger text it scrolls sideways rather than breaking or
// cutting a word (Name, Kind and Size were cut at the card's edge at 100% when the checks took their inset).
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';

import 'gallery_support.dart';

void main() {
  setUpAll(() async {
    await frostedLoadFonts();
    await loadBundledFonts();
  });

  for (final scale in [1.0, 1.3, 2.0]) {
    testWidgets('at ${(scale * 100).round()}% on a phone the data table '
        '${scale == 1 ? 'keeps to its card' : 'scrolls sideways'}, '
        'every word whole', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final page = galleryPages.firstWhere((p) => p.id == 'data');
      await pumpGalleryPage(tester, page, 'opal', Brightness.light);
      final table = find
          .byWidgetPredicate(
            (w) => w.runtimeType.toString().startsWith('FrostedDataTable'),
          )
          .first;
      final sideways = find.descendant(
        of: table,
        matching: find.byWidgetPredicate(
          (w) =>
              w is SingleChildScrollView &&
              w.scrollDirection == Axis.horizontal,
        ),
      );
      expect(sideways, scale == 1 ? findsNothing : findsOne);
      final broken = <String>[];
      for (final e
          in find
              .descendant(of: table, matching: find.byType(RichText))
              .evaluate()) {
        final r = e.renderObject! as RenderParagraph;
        final text = r.text.toPlainText();
        final lines = r
            .getBoxesForSelection(
              TextSelection(baseOffset: 0, extentOffset: text.length),
            )
            .map((b) => b.top)
            .toSet();
        if (r.didExceedMaxLines || lines.length > 1) broken.add(text);
      }
      expect(broken, isEmpty, reason: 'words cut or broken');
    });
  }
}
