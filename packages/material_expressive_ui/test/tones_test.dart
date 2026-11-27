// Tags keep their tones apart in all six palettes, by day and by night (F8):
// the neutral tag is outlined, a status at rest, so no palette's grey
// container can match it; the four filled tones stand at least 24 apart in
// RGB; the primary tone wears the palette's own primary container, so an
// orange palette's tag is orange.
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart' show MaterialApp;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';

double _apart(Color a, Color b) => math.sqrt(
  math.pow((a.r - b.r) * 255, 2) +
      math.pow((a.g - b.g) * 255, 2) +
      math.pow((a.b - b.b) * 255, 2),
);

void main() {
  for (final palette in ExpressiveThemeData.palettes) {
    for (final b in Brightness.values) {
      testWidgets('${palette.id}, ${b.name}: the tag tones stay apart', (
        tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            debugShowCheckedModeBanner: false,
            builder: (context, child) =>
                ExpressiveHost(brightness: b, palette: palette, child: child!),
            home: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final tone in ExpressiveTone.values)
                  ExpressiveTag(tone.name, tone: tone, key: ValueKey(tone)),
              ],
            ),
          ),
        );
        await tester.pumpAndSettle();
        ExpressiveSurface surface(ExpressiveTone tone) =>
            tester.widget<ExpressiveSurface>(
              find.descendant(
                of: find.byKey(ValueKey(tone)),
                matching: find.byType(ExpressiveSurface),
              ),
            );
        final neutral = surface(ExpressiveTone.neutral);
        expect(neutral.side.style, BorderStyle.solid);
        expect(neutral.color.a, 0);
        final filled = [
          for (final tone in ExpressiveTone.values)
            if (tone != ExpressiveTone.neutral) (tone, surface(tone).color),
        ];
        for (var i = 0; i < filled.length; i++) {
          for (var j = i + 1; j < filled.length; j++) {
            expect(
              _apart(filled[i].$2, filled[j].$2),
              greaterThanOrEqualTo(24),
              reason: '${filled[i].$1.name} and ${filled[j].$1.name}',
            );
          }
        }
        final colors = ExpressiveThemeData.fromPalette(palette, b).colors;
        expect(surface(ExpressiveTone.primary).color, colors.primaryContainer);
      });
    }
  }
}
