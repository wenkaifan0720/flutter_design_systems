// Expressive's six presets (ExpressiveThemeData.presets): baseline first,
// Compose's own scheme and the default, then slate, bloom, grove, ember and
// tide. Each is its own seed, and by day and by night every content pair
// and boundary meets its contrast floor (ExpressiveColors.contrastShortfalls
// is empty), at standard contrast and at high.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';

void main() {
  test('six palettes by name, the presets, baseline first', () {
    expect([
      for (final p in ExpressiveThemeData.palettes) p.id,
    ], ExpressiveThemeData.presets);
    expect(
      [for (final p in ExpressiveThemeData.palettes) p.label],
      ['Baseline', 'Slate', 'Bloom', 'Grove', 'Ember', 'Tide'],
    );
  });

  for (final b in Brightness.values) {
    test('${b.name}: a palette shows its preset\'s primary and surface', () {
      for (final p in ExpressiveThemeData.palettes) {
        final colors = ExpressiveThemeData.preset(p.id, b).colors;
        expect(p.swatchesFor(b), [
          colors.primary,
          colors.surface,
        ], reason: p.id);
        expect(
          ExpressiveThemeData.fromPalette(p, b),
          ExpressiveThemeData.preset(p.id, b),
        );
      }
    });
  }

  test("an app's own palette seeds its scheme", () {
    const own = RawNamedPalette(
      id: 'teal',
      label: 'Teal',
      swatches: [Color(0xFF00695C)],
      darkSwatches: [Color(0xFF80CBC4)],
    );
    expect(
      ExpressiveThemeData.fromPalette(own, Brightness.dark),
      ExpressiveThemeData.from(
        seed: const Color(0xFF80CBC4),
        brightness: Brightness.dark,
      ),
    );
  });

  testWidgets('the host wears its palette by day and by night', (tester) async {
    late ExpressiveThemeData seen;
    Widget host(Brightness b) => ExpressiveHost(
      brightness: b,
      palette: ExpressiveThemeData.palettes[3],
      child: Builder(
        builder: (context) {
          seen = ExpressiveTheme.of(context);
          return const SizedBox();
        },
      ),
    );
    for (final b in Brightness.values) {
      await tester.pumpWidget(
        Directionality(textDirection: TextDirection.ltr, child: host(b)),
      );
      await tester.pumpAndSettle();
      expect(
        seen.colors.primary,
        ExpressiveThemeData.preset('grove', b).colors.primary,
      );
    }
  });

  test('six presets, baseline first and the default', () {
    expect(ExpressiveThemeData.presets, [
      'baseline',
      'slate',
      'bloom',
      'grove',
      'ember',
      'tide',
    ]);
    expect(ExpressiveThemeData.defaultPreset, 'baseline');
  });

  for (final b in Brightness.values) {
    test('${b.name}: each preset its own primary', () {
      final primaries = {
        for (final name in ExpressiveThemeData.presets)
          ExpressiveThemeData.preset(name, b).colors.primary,
      };
      expect(primaries, hasLength(ExpressiveThemeData.presets.length));
    });

    for (final name in ExpressiveThemeData.presets) {
      for (final level in [0.0, 1.0]) {
        test('${b.name}, $name at contrast $level: no shortfalls', () {
          final theme = ExpressiveThemeData.preset(
            name,
            b,
            contrastLevel: level,
          );
          expect(theme.brightness, b);
          expect(theme.colors.contrastShortfalls(), isEmpty);
        });
      }
    }
  }
}
