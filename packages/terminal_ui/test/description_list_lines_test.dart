// A description list's lines stay on the grid whatever face draws a glyph:
// one the bundled face lacks (★) comes from a fallback, and its row is still
// one line tall.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terminal_ui/terminal_ui.dart';

import 'faces.dart';

void main() {
  setUpAll(loadFaces);

  for (final width in [800.0, 200.0]) {
    testWidgets('every row whole lines at ${width.round()} wide', (
      tester,
    ) async {
      final theme = TermThemeData.dark();
      await tester.pumpWidget(
        MaterialApp(
          home: TermTheme(
            data: theme,
            child: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: width,
                child: const TermDescriptionList(
                  items: [
                    ('status', 'reading'),
                    ('rating', '★★★★☆ 🙂'),
                    ('format', 'paperback'),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      final lh = theme.grid.lineHeight;
      for (final word in ['reading', '★★★★☆ 🙂', 'paperback']) {
        expect(
          tester.getSize(find.text(word)).height,
          closeTo(lh, 0.01),
          reason: word,
        );
        // A fallback face's taller line can't stretch it: the line is
        // forced to the grid's.
        final strut = tester.widget<Text>(find.text(word)).strutStyle;
        expect(strut?.forceStrutHeight, isTrue, reason: word);
        expect(strut!.fontSize! * strut.height!, closeTo(lh, 0.01));
      }
    });
  }
}
