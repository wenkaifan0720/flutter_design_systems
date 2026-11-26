// A TermMedia's alt words, shown while its picture loads or where it fails,
// read at 4.5:1 on the shade behind them, by day and by night.
import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terminal_ui/terminal_ui.dart';

import 'faces.dart';

void main() {
  setUpAll(loadFaces);

  for (final id in TermThemeData.palettes.map((p) => p.id)) {
    for (final b in Brightness.values) {
      testWidgets('$id, ${b.name}: the alt words read on the shade', (
        tester,
      ) async {
        final theme = TermThemeData.preset(id, b);
        await tester.pumpWidget(
          MaterialApp(
            home: TermTheme(
              data: theme,
              child: Center(
                child: SizedBox(
                  width: 300,
                  height: 160,
                  // Bytes that never make a picture: the shade and its words.
                  child: TermMedia(
                    image: MemoryImage(Uint8List.fromList(const [0])),
                    alt: 'Route guide cover',
                  ),
                ),
              ),
            ),
          ),
        );
        final words = tester.widget<Text>(find.text('Route guide cover'));
        final shade = tester
            .widgetList<ColoredBox>(
              find.ancestor(
                of: find.text('Route guide cover'),
                matching: find.byType(ColoredBox),
              ),
            )
            .first
            .color;
        // On whole 8-bit channels, as the screen draws the shade.
        final drawn = Color(
          Color.alphaBlend(shade, theme.background).toARGB32(),
        );
        expect(
          RawPalette.contrastRatio(words.style!.color!, drawn),
          greaterThanOrEqualTo(4.5),
        );
        // The picture that never decodes leaves the cache holding it.
        await tester.pumpWidget(const SizedBox());
        imageCache
          ..clear()
          ..clearLiveImages();
      });
    }
  }
}
