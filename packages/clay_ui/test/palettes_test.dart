// Clay's six palettes (ClayThemeData.presets): Clay's own first, each a
// clay of its own at Clay's tones with a key of its own. Every word reads
// 4.5:1 on what it sits on, the key's words too, and the focus rim stands
// 3:1, by day and by night.
import 'package:clay_ui/clay_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test("six palettes, Clay's own first", () {
    expect(ClayThemeData.presets, [
      'clay',
      'mint',
      'sky',
      'butter',
      'peach',
      'lavender',
    ]);
  });

  for (final b in Brightness.values) {
    final own = b == Brightness.dark
        ? const ClayColors.dark()
        : const ClayColors.light();

    test("${b.name}: clay is Clay's own", () {
      expect(ClayColors.preset('clay', b), own);
      expect(ClayThemeData.preset('clay', b).colors, own);
    });

    test('${b.name}: each palette its own key', () {
      final keys = {
        for (final name in ClayThemeData.presets)
          ClayColors.preset(name, b).accent,
      };
      expect(keys, hasLength(ClayThemeData.presets.length));
    });

    for (final name in ClayThemeData.presets) {
      final c = ClayThemeData.preset(name, b).colors;

      test('${b.name}, $name: its theme wears its colours', () {
        expect(c, ClayColors.preset(name, b));
        expect(c.brightness, b);
      });

      test('${b.name}, $name: words read 4.5:1 on ground, clay and well', () {
        for (final (words, ink) in [
          ('ink', c.ink),
          ('secondary ink', c.inkSecondary),
          ('danger ink', c.dangerInk),
        ]) {
          for (final (ground, fill) in [
            ('ground', c.ground),
            ('clay', c.clay),
            ('well', c.well),
          ]) {
            expect(
              clayContrast(ink, fill),
              greaterThanOrEqualTo(4.5),
              reason: '$words on $ground',
            );
          }
        }
      });

      test(
        "${b.name}, $name: the key's words and the inverse's read 4.5:1",
        () {
          expect(clayContrast(c.onAccent, c.accent), greaterThanOrEqualTo(4.5));
          expect(
            clayContrast(c.onInverse, c.inverse),
            greaterThanOrEqualTo(4.5),
          );
        },
      );

      test('${b.name}, $name: accent ink reads 4.5:1 on ground and clay', () {
        expect(clayContrast(c.accentInk, c.ground), greaterThanOrEqualTo(4.5));
        expect(clayContrast(c.accentInk, c.clay), greaterThanOrEqualTo(4.5));
      });

      test('${b.name}, $name: the focus rim stands 3:1 from clay and well', () {
        expect(clayContrast(c.focus, c.clay), greaterThanOrEqualTo(3));
        expect(clayContrast(c.focus, c.well), greaterThanOrEqualTo(3));
      });

      test("${b.name}, $name: its clay at Clay's own tones", () {
        double gap(
          ClayColors p,
          Color Function(ClayColors) a,
          Color Function(ClayColors) z,
        ) => clayContrast(a(p), z(p));
        for (final (pair, a, z)
            in <
              (String, Color Function(ClayColors), Color Function(ClayColors))
            >[
              ('ink on ground', (p) => p.ink, (p) => p.ground),
              ('secondary on clay', (p) => p.inkSecondary, (p) => p.clay),
              ('secondary on well', (p) => p.inkSecondary, (p) => p.well),
              ('disabled on ground', (p) => p.inkDisabled, (p) => p.ground),
              ('clay on ground', (p) => p.clay, (p) => p.ground),
              ('well on ground', (p) => p.well, (p) => p.ground),
            ]) {
          final mine = gap(own, a, z);
          expect(gap(c, a, z), closeTo(mine, mine * 0.02), reason: pair);
        }
      });
    }
  }
}
