// Terminal's six palettes as ui_core's named palettes, for a picker: each
// one's theme is its preset by day and by night; an app's own palette takes
// its first swatch as the accent, stepped until it reads.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terminal_ui/terminal_ui.dart';

void main() {
  test('each named palette is its preset, by day and by night', () {
    expect(TermThemeData.palettes.map((p) => p.label), [
      'Standard',
      'Harbor',
      'Dusk',
      'Mono',
      'Phosphor',
      'Amber',
    ]);
    for (final p in TermThemeData.palettes) {
      for (final b in Brightness.values) {
        final named = TermThemeData.fromPalette(p, b);
        final preset = TermThemeData.preset(p.id, b);
        expect(named.background, preset.background, reason: p.id);
        expect(named.accent, preset.accent, reason: p.id);
        // The swatches show the palette as the picker draws it.
        expect(p.swatchesFor(b).first, preset.accent, reason: p.id);
        expect(p.swatchesFor(b).last, preset.background, reason: p.id);
      }
    }
  });

  test("an app's own palette takes its swatch as the accent", () {
    const own = RawNamedPalette(
      id: 'brand',
      label: 'Brand',
      swatches: [Color(0xFF7DD3FC)],
      darkSwatches: [Color(0xFF0A7D4F)],
    );
    for (final b in Brightness.values) {
      final t = TermThemeData.fromPalette(own, b);
      expect(t.brightness, b);
      // The accent is the palette's own swatch, stepped to read (not the
      // first palette's).
      expect(
        t.accent,
        TermThemeData.from(
          b == Brightness.dark ? TermPalette.night : TermPalette.paper,
          brightness: b,
          accent: own.swatchesFor(b).first,
        ).accent,
      );
      expect(
        RawPalette.contrastRatio(t.accent, t.background),
        greaterThanOrEqualTo(4.5),
      );
    }
  });
}
