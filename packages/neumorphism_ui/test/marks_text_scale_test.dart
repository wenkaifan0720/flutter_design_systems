// Tags, monograms and the glyph in an icon well grow with the reader's text, as the words beside them do, and each
// mark holds what it draws: at 130% and 200% a tag's words, a monogram's letters and a well's glyph are as large as
// the page's words at that size.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

import 'support.dart';

Future<Map<String, Rect>> _marks(WidgetTester t, double scale) async {
  t.view.physicalSize = const Size(390, 844);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(
    neumorphicApp(
      MediaQuery(
        data: MediaQueryData(
          size: const Size(390, 844),
          textScaler: TextScaler.linear(scale),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            NeumorphicTag('Reading'),
            NeumorphicMonogram('SW'),
            NeumorphicIconWell(NeumorphicGlyphs.lock),
          ],
        ),
      ),
    ),
  );
  await t.pumpAndSettle();
  return {
    'tag words': t.getRect(find.text('Reading')),
    'monogram': t.getRect(find.byType(NeumorphicMonogram)),
    'letters': t.getRect(find.text('SW')),
    'well': t.getRect(find.byType(NeumorphicIconWell)),
    'glyph': t.getRect(
      find.descendant(
        of: find.byType(NeumorphicIconWell),
        matching: find.byType(Icon),
      ),
    ),
  };
}

void main() {
  setUpAll(loadNeumorphicFonts);

  for (final scale in [1.3, 2.0]) {
    testWidgets('marks grow with the text at ${(scale * 100).round()}%', (
      t,
    ) async {
      final at1 = await _marks(t, 1);
      final at = await _marks(t, scale);
      for (final part in ['tag words', 'letters', 'glyph']) {
        expect(
          at[part]!.height,
          moreOrLessEquals(at1[part]!.height * scale, epsilon: 1),
          reason: '$part at ${scale}x',
        );
      }
      // Each mark holds what it draws.
      expect(
        at['monogram']!.width,
        greaterThanOrEqualTo(at['letters']!.width + 8),
      );
      expect(at['well']!.width, greaterThanOrEqualTo(at['glyph']!.width + 8));
    });
  }
}
