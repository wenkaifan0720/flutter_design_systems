// Right to left: every gallery page, shown right to left as the Customize panel's Direction (or a link's dir=rtl)
// sets it, lays out right to left under its own app (each page is one, whose localizations would set left to right)
// with nothing overflowing, and its first section's words stand at the right.
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:frosted_ui/frosted_host.dart';

import 'gallery_support.dart';

// The gallery is the example app; a test sets the direction it shows.
// ignore_for_file: avoid_relative_lib_imports
import '../example/lib/kit_gallery/kit.dart';

void main() {
  setUpAll(frostedLoadFonts);
  final (preset, day) = presetsAndModes.first;
  for (final page in galleryPages) {
    testWidgets('${page.id} lays out right to left', (tester) async {
      kitShownDirection = TextDirection.rtl;
      addTearDown(() => kitShownDirection = TextDirection.ltr);
      await pumpGalleryPage(tester, page, preset, day);
      expect(tester.takeException(), isNull);
      final hosts = find.byType(FrostedHost);
      expect(hosts, findsWidgets);
      for (final host in hosts.evaluate()) {
        expect(Directionality.of(host), TextDirection.rtl);
      }
      final sections = find.byWidgetPredicate(
        (w) =>
            w.key is ValueKey<String> &&
            (w.key! as ValueKey<String>).value.startsWith('kit-section/'),
      );
      if (sections.evaluate().isEmpty) return;
      final section = tester.getRect(sections.first);
      final label = find.descendant(
        of: sections.first,
        matching: find.byType(RichText),
      );
      final words = tester.renderObject<RenderParagraph>(label.first);
      final box = words.getBoxesForSelection(
        TextSelection(
          baseOffset: 0,
          extentOffset: words.text.toPlainText().length,
        ),
      );
      final origin = tester.getTopLeft(label.first);
      final right =
          box.map((b) => b.right).reduce((a, b) => a > b ? a : b) + origin.dx;
      // A label that wraps hangs its break's space past the edge (a few
      // pixels); one that stayed left to right ends far short of it.
      expect(
        right,
        inInclusiveRange(section.right - 1, section.right + 5),
        reason: 'the first section label ends at its right edge',
      );
    });
  }
}
