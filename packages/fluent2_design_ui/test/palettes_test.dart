// The six palettes: each reads in both appearances (Fluent's words on the ground and the card, the words on the brand
// fill, the brand's words and links, the brand stroke and the focus stroke), and each palette's swatches are its brand
// as it reads and its ground.
// flint has no hue to mark a choice, so its brand inks (a chosen page's, a link's) read stronger than the neutral
// inks a page not chosen stands in.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluent2_design_ui/fluent2_design_ui.dart';

void main() {
  test('six palettes for a picker, lapis the default', () {
    expect(
      [for (final palette in Fluent2ThemeData.palettes) palette.id],
      ['lapis', 'iris', 'juniper', 'pumpkin', 'berry', 'flint'],
    );
    expect(
      () => Fluent2ThemeData.preset('clover', Brightness.light),
      throwsArgumentError,
    );
    for (final palette in Fluent2ThemeData.palettes) {
      expect(palette.label, isNotEmpty);
      for (final brightness in Brightness.values) {
        final t = Fluent2ThemeData.preset(palette.id, brightness);
        // As stored: the ground is a blend, so the swatch is its 8 bits.
        expect(
          [
            for (final swatch
                in brightness == Brightness.dark
                    ? palette.darkSwatches
                    : palette.swatches)
              swatch.toARGB32(),
          ],
          [
            t.colors.compoundBrandBackground.toARGB32(),
            t.background.toARGB32(),
          ],
          reason: '${palette.id} by ${brightness.name}',
        );
      }
    }
  });

  for (final id in Fluent2ThemeData.palettes.map((p) => p.id)) {
    for (final brightness in Brightness.values) {
      test('$id reads in ${brightness.name}', () {
        final t = Fluent2ThemeData.preset(id, brightness);
        final c = t.colors;
        void reads(String what, Color ink, Color ground, double ratio) =>
            expect(
              RawPalette.contrastRatio(ink, ground),
              greaterThanOrEqualTo(ratio),
              reason: '$what in $id ${brightness.name}',
            );
        for (final ground in [t.background, c.neutralBackground1]) {
          reads('the words', c.neutralForeground1, ground, 4.5);
          reads('the quieter words', c.neutralForeground2, ground, 4.5);
          reads('the brand words', c.brandForeground1, ground, 4.5);
          reads('a link', c.brandForegroundLink, ground, 4.5);
          reads('the brand stroke', c.compoundBrandStroke, ground, 3);
          reads('the focus stroke', c.strokeFocus2, ground, 3);
        }
        reads(
          'the words on the brand',
          c.neutralForegroundOnBrand,
          c.brandBackground,
          4.5,
        );
      });
    }
  }

  for (final brightness in Brightness.values) {
    test('flint marks a choice by weight in ${brightness.name}', () {
      final t = Fluent2ThemeData.flint(brightness);
      final c = t.colors;
      double on(Color ink) =>
          RawPalette.contrastRatio(ink, c.neutralBackground1);
      for (final (what, ink) in [
        ('a chosen page', c.compoundBrandForeground1),
        ('the brand words', c.brandForeground1),
        ('a link', c.brandForegroundLink),
        ('a hovered quiet item', c.neutralForeground3BrandHover),
      ]) {
        for (final (quiet, rest) in [
          ('the quieter words', c.neutralForeground2),
          ('a page not chosen', c.neutralForeground3),
        ]) {
          expect(
            on(ink),
            greaterThan(on(rest)),
            reason: '$what over $quiet, ${brightness.name}',
          );
        }
      }
    });
  }
}
