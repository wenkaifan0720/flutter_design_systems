// A tag's four tones stand apart in every palette, by day and by night, so
// colour tells a status as well as its word: neutral, accent, success and
// danger fills at least 10 apart in HCT. In Mint by day a success tag and a
// neutral one were 6 apart, a success tag and an accent one 7: a reader saw
// three greens.
import 'package:clay_ui/clay_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core_test/ui_core_test.dart';

void main() {
  for (final palette in ClayThemeData.palettes) {
    for (final brightness in Brightness.values) {
      testWidgets("${palette.label} ${brightness.name}: a tag's tones stand "
          'apart', (tester) async {
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: ClayTheme(
              data: ClayThemeData.fromPalette(palette, brightness),
              child: Column(
                children: [
                  for (final tone in ClayTagTone.values)
                    ClayTag(tone.name, tone: tone),
                ],
              ),
            ),
          ),
        );
        final fills = {
          for (final tone in ClayTagTone.values)
            tone.name: tester
                .widget<ClaySurface>(
                  find
                      .descendant(
                        of: find.widgetWithText(ClayTag, tone.name),
                        matching: find.byType(ClaySurface),
                      )
                      .first,
                )
                .face
                .color,
        };
        final names = fills.keys.toList();
        final close = <String>[];
        for (var i = 0; i < names.length; i++) {
          for (var j = i + 1; j < names.length; j++) {
            final d = DesignToneCheck.distance(
              fills[names[i]]!,
              fills[names[j]]!,
            );
            if (d < 10) {
              close.add('${names[i]} and ${names[j]} ${d.toStringAsFixed(1)}');
            }
          }
        }
        expect(close, isEmpty);
      });
    }
  }
}
