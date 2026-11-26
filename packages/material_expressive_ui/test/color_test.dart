/// Color roles and contrast levels across the generated theme presets.
library;

import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';
import 'package:material_expressive_ui/src/material_expressive/internal/themes/baked_theme.dart';
import 'package:material_expressive_ui/src/material_expressive/internal/themes/registry.g.dart';

/// WCAG's contrast ratio of two opaque colours (ui_core's).
const _contrast = RawPalette.contrastRatio;

const _brightnesses = <Brightness>[Brightness.light, Brightness.dark];

void main() {
  test('copyWith replaces the roles given and keeps every other', () {
    final base = ExpressiveThemeData.preset(
      'baseline',
      Brightness.light,
    ).colors;
    const brand = Color(0xff006a60);
    final copy = base.copyWith(primary: brand, shadow: const Color(0xff000001));
    expect(copy.primary, brand);
    expect(copy.shadow, const Color(0xff000001));
    for (final role in ExpressiveColorRole.values) {
      if (role == ExpressiveColorRole.primary) continue;
      expect(copy.role(role), base.role(role), reason: role.name);
    }
    expect(base.copyWith(), base);
  });

  test('app seed palettes meet every content and boundary contrast floor, '
      'at every contrast level', () {
    final shortfalls = <String>[];
    for (final seed in const [
      Color(0xff00695c),
      Color(0xffffeeee),
      Color(0xff111111),
      Color(0xff888888),
    ]) {
      for (final brightness in Brightness.values) {
        for (final contrastLevel in const [0.0, 1.0]) {
          final theme = ExpressiveThemeData.from(
            seed: seed,
            brightness: brightness,
            contrastLevel: contrastLevel,
          );
          final label =
              '#${seed.toARGB32().toRadixString(16)} ${brightness.name} at '
              '$contrastLevel';
          for (final MapEntry(:key, :value)
              in theme.colors.contrastShortfalls().entries) {
            shortfalls.add('$label: $key ${value.toStringAsFixed(2)}');
          }
          final ink = theme.colors.onTertiaryContainer;
          final dragged = Color.alphaBlend(
            theme.states.layerOf(ink, {WidgetState.dragged})!,
            theme.colors.tertiaryContainer,
          );
          final ratio = RawPalette.contrastRatio(ink, dragged);
          if (ratio < 4.5) {
            shortfalls.add(
              '$label: dragged list text ${ratio.toStringAsFixed(2)}',
            );
          }
        }
      }
    }
    expect(shortfalls, isEmpty);
  });

  test('every preset level keeps dragged list text readable', () {
    final shortfalls = <String>[];
    for (final id in ExpressiveThemeData.presets) {
      for (final brightness in Brightness.values) {
        for (final contrastLevel in const [0.0, 1.0]) {
          final theme = ExpressiveThemeData.preset(
            id,
            brightness,
            contrastLevel: contrastLevel,
          );
          final ink = theme.colors.onTertiaryContainer;
          final dragged = Color.alphaBlend(
            theme.states.layerOf(ink, {WidgetState.dragged})!,
            theme.colors.tertiaryContainer,
          );
          final ratio = RawPalette.contrastRatio(ink, dragged);
          if (ratio < 4.5) {
            shortfalls.add(
              '$id ${brightness.name} at $contrastLevel: '
              '${ratio.toStringAsFixed(2)}',
            );
          }
        }
      }
    }
    expect(shortfalls, isEmpty);
  });

  test("from(seed) takes Material's contrast level, standard by default", () {
    const seed = Color(0xff00695c);
    for (final brightness in Brightness.values) {
      ExpressiveColorScheme at(double level) => ExpressiveThemeData.from(
        seed: seed,
        brightness: brightness,
        contrastLevel: level,
      ).colors;
      final standard = ExpressiveThemeData.from(
        seed: seed,
        brightness: brightness,
      ).colors;
      expect(standard, at(0));
      expect(at(1), isNot(standard));
      // Raising contrast widens the primary pair.
      expect(
        _contrast(at(1).onPrimary, at(1).primary),
        greaterThan(_contrast(standard.onPrimary, standard.primary)),
      );
    }
    // No reduced level: it would read under the look's floors.
    expect(
      () => ExpressiveThemeData.from(seed: seed, contrastLevel: -1),
      throwsAssertionError,
    );
    expect(
      () => ExpressiveThemeData.from(seed: seed, contrastLevel: 1.5),
      throwsAssertionError,
    );
    // Nor one between: Material's medium level takes a dragged row's words
    // under 4.5:1 on every light seed (3.7:1 at 0.5).
    expect(
      () => ExpressiveThemeData.from(seed: seed, contrastLevel: .5),
      throwsAssertionError,
    );
  });

  group('baseline', () {
    test('is Compose\'s default scheme in both brightnesses', () {
      final light = ExpressiveThemeData.preset('baseline', Brightness.light);
      final dark = ExpressiveThemeData.preset('baseline', Brightness.dark);
      // The default light and dark palettes follow Material’s color schemes.
      expect(light.colors.primary, const Color(0xFF6750A4));
      expect(light.colors.onPrimaryContainer, const Color(0xFF4F378B));
      expect(light.colors.onSecondaryContainer, const Color(0xFF4A4458));
      expect(dark.colors.primary, const Color(0xFFD0BCFF));
      expect(dark.colors.onPrimaryContainer, const Color(0xFFEADDFF));
      expect(light.colors.surface, isNot(dark.colors.surface));
    });

    test('light is expressiveLightColorScheme(): four roles at tone 30', () {
      final light = expressiveBakedThemes['baseline']!.colors.light;
      // ColorLightTokens has these at tone 10; expressiveLightColorScheme()
      // passes PaletteTokens.*30 instead.
      expect(light['onPrimaryContainer'], 0xFF4F378B);
      expect(light['onSecondaryContainer'], 0xFF4A4458);
      expect(light['onTertiaryContainer'], 0xFF633B48);
      expect(light['onErrorContainer'], 0xFF8C1D18);
      // The fixed roles keep ColorLightTokens' tone 10.
      expect(light['onPrimaryFixed'], 0xFF21005D);
    });

    test('surfaceTint is primary, as lightColorScheme() defaults it', () {
      for (final brightness in _brightnesses) {
        final c = ExpressiveThemeData.preset('baseline', brightness).colors;
        expect(c.surfaceTint, c.primary);
      }
    });
  });

  group('the seeded themes', () {
    // slate and bloom carry no brand identity: slate's seed is a desaturated
    // blue-grey (#52667A) and bloom's a muted orchid rose (#B5487A), picked
    // for their variant's character (neutral: calm, near-grey; vibrant: a
    // warm, saturated accent) and far from Material's baseline purple and
    // any well-known brand colour. grove (#2E7D5B, a forest green, tonal
    // spot) and ember (#C25A1F, a burnt orange, the hue-rotating expressive
    // variant) complete the five presets, on the
    // two variants slate and bloom leave out.
    test('slate is neutral, standard motion, calm; bloom vibrant, bold; '
        'grove tonal spot, balanced; ember expressive, bold', () {
      final slate = expressiveBakedThemes['slate']!;
      final bloom = expressiveBakedThemes['bloom']!;
      expect(slate.seed, 0xFF52667A);
      expect(slate.variant, 'neutral');
      expect(slate.expression, 'calm');
      expect(slate.motion.scheme, 'standard');
      expect(bloom.seed, 0xFFB5487A);
      expect(bloom.variant, 'vibrant');
      expect(bloom.expression, 'bold');
      expect(bloom.motion.scheme, 'expressive');
      final grove = expressiveBakedThemes['grove']!;
      final ember = expressiveBakedThemes['ember']!;
      expect(grove.seed, 0xFF2E7D5B);
      expect(grove.variant, 'tonalSpot');
      expect(grove.expression, 'balanced');
      expect(grove.motion.scheme, 'expressive');
      expect(ember.seed, 0xFFC25A1F);
      expect(ember.variant, 'expressive');
      expect(ember.expression, 'bold');
      expect(ember.motion.scheme, 'expressive');
      for (final theme in <ExpressiveBakedTheme>[slate, bloom, grove, ember]) {
        expect(theme.source, isNull);
        expect(theme.contrast, 0);
      }
    });

    test('are the presets after baseline, the default', () {
      expect(expressiveDefaultThemeId, 'baseline');
      expect(expressiveBakedThemes.keys, <String>[
        'baseline',
        'slate',
        'bloom',
        'grove',
        'ember',
        'tide',
      ]);
    });

    test('dark is baked, not light inverted', () {
      for (final id in <String>['slate', 'bloom', 'grove', 'ember', 'tide']) {
        final light = ExpressiveThemeData.preset(id, Brightness.light).colors;
        final dark = ExpressiveThemeData.preset(id, Brightness.dark).colors;
        expect(dark.surface.computeLuminance(), lessThan(0.05));
        expect(light.surface.computeLuminance(), greaterThan(0.8));
        // The fixed roles keep their tone across brightnesses (their L*;
        // the 2025 tonal spot draws its dark palettes less chromatic, so
        // grove's fixed roles keep their tone, not their ARGB).
        expect(
          _tone(dark.primaryFixed),
          closeTo(_tone(light.primaryFixed), 0.5),
        );
        expect(
          _tone(dark.onTertiaryFixed),
          closeTo(_tone(light.onTertiaryFixed), 0.5),
        );
      }
    });
  });

  group('every preset in both brightnesses', () {
    for (final id in expressiveBakedThemes.keys) {
      for (final brightness in _brightnesses) {
        final label = '$id ${brightness.name}';

        test('$label carries exactly the ExpressiveColorRoles', () {
          final baked = brightness == Brightness.dark
              ? expressiveBakedThemes[id]!.colors.dark
              : expressiveBakedThemes[id]!.colors.light;
          expect(
            baked.keys.toSet(),
            ExpressiveColorRole.values.map((role) => role.name).toSet(),
          );
          final c = ExpressiveThemeData.preset(id, brightness).colors;
          for (final role in ExpressiveColorRole.values) {
            expect(
              c.role(role).toARGB32(),
              baked[role.name],
              reason: role.name,
            );
          }
          expect(c.shadow, const Color(0xFF000000));
          expect(c.scrim.a, 1);
        });

        test('$label: every content pair reads at 4.5:1 or more', () {
          final c = ExpressiveThemeData.preset(id, brightness).colors;
          // Content pairs and onSurfaceVariant at 4.5:1; the outline is a
          // 3:1 boundary.
          expect(c.contrastShortfalls(), isEmpty, reason: label);
        });
      }
    }
  });

  // Seeded themes include both regular and high-contrast palettes.
  group('contrast levels', () {
    test('seeded themes resolve at 0, 0.5 and 1; baseline only at 0', () {
      for (final id in <String>['slate', 'bloom', 'grove', 'ember', 'tide']) {
        final baked = expressiveBakedThemes[id]!;
        expect(baked.colors.atContrast.keys.toSet(), <String>{'0.5', '1'});
        for (final brightness in _brightnesses) {
          final own = expressiveResolveColors(baked, brightness);
          expect(expressiveResolveColors(baked, brightness, contrast: 0), own);
          final high = expressiveResolveColors(baked, brightness, contrast: 1);
          expect(high, isNot(own));
          expect(
            high.primary.toARGB32(),
            (brightness == Brightness.dark
                ? baked.colors.atContrast['1']!.dark
                : baked.colors.atContrast['1']!.light)['primary'],
          );
          // Raising contrast widens the primary pair.
          expect(
            _contrast(high.onPrimary, high.primary),
            greaterThanOrEqualTo(_contrast(own.onPrimary, own.primary)),
            reason: '$id ${brightness.name}',
          );
          expect(
            _contrast(high.onPrimary, high.primary),
            greaterThanOrEqualTo(7),
            reason: '$id ${brightness.name} at contrast 1',
          );
        }
      }
      final baseline = expressiveBakedThemes['baseline']!;
      expect(baseline.colors.atContrast, isEmpty);
      expect(
        () => expressiveResolveColors(baseline, Brightness.light, contrast: 1),
        throwsStateError,
      );
    });

    test('every preset comes at standard and high contrast', () {
      for (final id in ExpressiveThemeData.presets) {
        final baked = expressiveBakedThemes[id]!;
        for (final brightness in _brightnesses) {
          final own = ExpressiveThemeData.preset(id, brightness);
          expect(
            ExpressiveThemeData.preset(id, brightness, contrastLevel: 0),
            own,
          );
          for (final level in const [1.0]) {
            final at = ExpressiveThemeData.preset(
              id,
              brightness,
              contrastLevel: level,
            );
            final label = '$id ${brightness.name} at $level';
            // Only the colours move: the id, motion, type and shapes stay.
            expect(at.copyWith(colors: own.colors), own, reason: label);
            expect(at.colors, isNot(own.colors), reason: label);
            // The baked level where there is one; baseline, Compose's fixed
            // scheme, from its seed.
            expect(
              at.colors,
              baked.colors.atContrast.isEmpty
                  ? ExpressiveThemeData.from(
                      seed: Color(baked.seed),
                      brightness: brightness,
                      contrastLevel: level,
                    ).colors
                  : expressiveResolveColors(baked, brightness, contrast: level),
              reason: label,
            );
            expect(at.colors.contrastShortfalls(), isEmpty, reason: label);
          }
        }
      }
      // Medium, baked but refused: a dragged row's words fall under 4.5:1
      // on its light containers.
      for (final level in const [.3, .5]) {
        expect(
          () => ExpressiveThemeData.preset(
            'grove',
            Brightness.light,
            contrastLevel: level,
          ),
          throwsAssertionError,
        );
      }
    });
  });

  // The high-contrast promise (the TS bake test's floor, bake.test.ts): at
  // contrast 1 every specified pair reaches min(its MCU curve, 7:1), within
  // 0.05. Every content pair's and onSurfaceVariant's curve and the
  // outline's reach 7 at contrast 1, so the floor is 7:1 for each.
  group('every content pair at contrast 1', () {
    for (final id in <String>['slate', 'bloom', 'grove', 'ember', 'tide']) {
      for (final brightness in _brightnesses) {
        final label = '$id ${brightness.name} at contrast 1';
        test('$label reads at 7:1 or more', () {
          final c = expressiveResolveColors(
            expressiveBakedThemes[id]!,
            brightness,
            contrast: 1,
          );
          const floor = 7 - 0.05;
          expect(
            c.contrastShortfalls(content: floor, boundary: floor),
            isEmpty,
            reason: label,
          );
        });
      }
    }
  });

  group('the contrast measure', () {
    test('is WCAG 2\'s ratio, whichever colour is lighter', () {
      const black = Color(0xFF000000);
      const white = Color(0xFFFFFFFF);
      expect(RawPalette.contrastRatio(black, white), closeTo(21, 1e-9));
      expect(RawPalette.contrastRatio(white, black), closeTo(21, 1e-9));
      expect(RawPalette.contrastRatio(white, white), 1);
    });

    test('names every pair below its floor, with its ratio', () {
      final c = ExpressiveThemeData.preset('baseline', Brightness.light).colors;
      expect(c.contrastShortfalls(), isEmpty);
      final strict = c.contrastShortfalls(content: 22, boundary: 22);
      expect(strict.keys, contains('content on primary'));
      expect(
        strict.keys,
        contains('onSurfaceVariant on surfaceContainerHighest'),
      );
      expect(strict['outline on surface'], _contrast(c.outline, c.surface));
    });
  });

  group('ExpressiveColorScheme', () {
    final c = ExpressiveThemeData.preset('baseline', Brightness.light).colors;

    test('role() resolves a token\'s symbolic colour', () {
      expect(c.role(ExpressiveColorRole.primary), c.primary);
      expect(
        c.role(ExpressiveColorRole.surfaceContainerHigh),
        c.surfaceContainerHigh,
      );
      expect(
        c.role(ExpressiveColorRole.onTertiaryFixedVariant),
        c.onTertiaryFixedVariant,
      );
    });

    test('contentColorFor() pairs like Compose\'s', () {
      expect(c.contentColorFor(c.primary), c.onPrimary);
      expect(c.contentColorFor(c.secondaryContainer), c.onSecondaryContainer);
      expect(c.contentColorFor(c.surfaceContainerLowest), c.onSurface);
      expect(c.contentColorFor(c.primaryFixedDim), c.onPrimaryFixed);
      expect(c.contentColorFor(const Color(0x00123456)), isNull);
    });

    test('equality is by every role', () {
      final again = ExpressiveThemeData.preset('baseline', Brightness.light);
      expect(again.colors, c);
      expect(again.colors.hashCode, c.hashCode);
      expect(
        ExpressiveThemeData.preset('slate', Brightness.light).colors,
        isNot(c),
      );
    });
  });

  group('ExpressiveColorScheme.lerp', () {
    final a = ExpressiveThemeData.preset('baseline', Brightness.light).colors;
    final b = ExpressiveThemeData.preset('bloom', Brightness.dark).colors;

    test('is each end at 0 and 1', () {
      expect(ExpressiveColorScheme.lerp(a, b, 0), a);
      expect(ExpressiveColorScheme.lerp(a, b, 1), b);
      expect(identical(ExpressiveColorScheme.lerp(a, a, 0.3), a), isTrue);
    });

    test('interpolates every role, as Color.lerp does', () {
      final half = ExpressiveColorScheme.lerp(a, b, 0.5);
      for (final role in ExpressiveColorRole.values) {
        expect(
          half.role(role),
          Color.lerp(a.role(role), b.role(role), 0.5),
          reason: role.name,
        );
      }
      expect(half.shadow, a.shadow);
    });

    test('clamps a spring\'s overshoot to the gamut', () {
      final over = ExpressiveColorScheme.lerp(a, b, 1.2);
      for (final role in ExpressiveColorRole.values) {
        final color = over.role(role);
        for (final channel in <double>[color.r, color.g, color.b, color.a]) {
          expect(channel, inInclusiveRange(0, 1), reason: role.name);
        }
      }
    });
  });
}

/// CIE L* of [c]: HCT's tone.
double _tone(Color c) {
  final y = c.computeLuminance();
  return y > 216 / 24389 ? 116 * math.pow(y, 1 / 3) - 16 : y * 24389 / 27;
}
