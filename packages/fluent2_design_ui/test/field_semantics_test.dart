// ui_core's DesignFieldSemanticsCheck over every field the gallery shows:
// each page at a phone's width, Northwind's four screens at a desktop's
// too. A field's controls each take a tap through the semantics tree, no
// node takes a stepper button's tap in its place, and a field's label is
// read once.
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core_test/ui_core_test.dart';

import 'gallery_support.dart';

void main() {
  setUpAll(loadFluent2TestFonts);

  for (final page in galleryPages) {
    final widths = page.id.startsWith('app-')
        ? const [390.0, 1440.0]
        : const [galleryWidth];
    for (final width in widths) {
      testWidgets('${page.id}, ${width.round()} wide: every field takes a '
          "tap on each control and says its label once", (t) async {
        final semantics = t.ensureSemantics();
        await pumpWhole(t, page, width);
        const DesignFieldSemanticsCheck(look: 'Fluent 2')
            .check(shownScreen(t))
            .verify();
        semantics.dispose();
      });
    }
  }
}
