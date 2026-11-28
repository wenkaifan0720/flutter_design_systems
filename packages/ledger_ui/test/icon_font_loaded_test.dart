// ledgerLoadFonts loads the icon font Ledger's parts draw their glyphs from
// (Lucide) as well as its faces, so on the web a glyph is drawn on the first
// frame and never comes up as an empty box. A family that was never loaded
// falls back to the test font, whose glyphs are filled squares; once Lucide
// is loaded, its minus is a thin bar.
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledger_ui/ledger_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

void main() {
  testWidgets('ledgerLoadFonts loads the Lucide icon font', (tester) async {
    await tester.runAsync(ledgerLoadFonts);
    final key = GlobalKey();
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: RepaintBoundary(
            key: key,
            child: const ColoredBox(
              color: Color(0xFFFFFFFF),
              child: Icon(
                LucideIcons.minus,
                size: 48,
                color: Color(0xFF000000),
              ),
            ),
          ),
        ),
      ),
    );
    final inked = await tester.runAsync(() async {
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage();
      final bytes = (await image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      ))!;
      final pixels = image.width * image.height;
      image.dispose();
      var dark = 0;
      for (var i = 0; i < bytes.lengthInBytes; i += 4) {
        if (bytes.getUint8(i) < 128) dark++;
      }
      return dark / pixels;
    });
    // A bar inks a few hundredths of its square; a fallback box most of it.
    expect(inked, inInclusiveRange(0.02, 0.25), reason: 'inked $inked');
  });
}
