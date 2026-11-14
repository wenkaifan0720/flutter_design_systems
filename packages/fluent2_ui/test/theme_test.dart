import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluent2_ui/fluent2_ui.dart';

/// Every preset, light and dark, holds Fluent's contrast floors on every
/// pair a Fluent 2 page sets: words at 4.5:1 on each ground they stand on,
/// the strokes and glyphs a control is read by at 3:1.
void main() {
  final themes = [
    for (final id in Fluent2ThemeData.presets)
      for (final b in Brightness.values) Fluent2ThemeData.preset(id, b),
  ];

  String name(Fluent2ThemeData t) => '${t.id} ${t.brightness.name}';

  List<(String, Color, Color, double)> pairs(Fluent2ThemeData t) {
    final layer = Color.alphaBlend(
      t.colors.neutralBackground1.withValues(alpha: 0.5),
      t.background,
    );
    final grounds = <String, Color>{
      'surface': t.surface,
      'ground': t.background,
      'layer': layer,
      'surfaceAlt': t.surfaceAlt,
      'acrylic': t.acrylic.fallback,
    };
    return [
      for (final g in grounds.entries) ...[
        ('textPrimary on ${g.key}', t.textPrimary, g.value, 4.5),
        ('textSecondary on ${g.key}', t.textSecondary, g.value, 4.5),
        ('textTertiary on ${g.key}', t.textTertiary, g.value, 4.5),
        ('accentText on ${g.key}', t.accentText, g.value, 4.5),
        ('link on ${g.key}', t.link, g.value, 4.5),
        ('danger on ${g.key}', t.danger, g.value, 4.5),
        ('success on ${g.key}', t.success, g.value, 4.5),
        ('warning on ${g.key}', t.warning, g.value, 4.5),
        ('edge on ${g.key}', t.edge, g.value, 3),
        ('focus on ${g.key}', t.focus, g.value, 3),
      ],
      (
        'selected tab on the acrylic',
        t.colors.compoundBrandForeground1,
        t.acrylic.fallback,
        4.5,
      ),
      (
        'selected tab on surface',
        t.colors.compoundBrandForeground1,
        t.surface,
        4.5,
      ),
      (
        'nav glyph on ground',
        t.colors.neutralForeground2BrandSelected,
        t.background,
        3,
      ),
      ('textQuiet on surface', t.textQuiet, t.surface, 4.5),
      ('onAccent on accent', t.onAccent, t.accent, 4.5),
      (
        'onAccent on accent hover',
        t.onAccent,
        t.colors.brandBackgroundHover,
        4.5,
      ),
      (
        'onAccent on accent pressed',
        t.onAccent,
        t.colors.brandBackgroundPressed,
        4.5,
      ),
      ('textInverse on surfaceInverse', t.textInverse, t.surfaceInverse, 4.5),
      ('primary on accentSubtle', t.textPrimary, t.accentSubtle, 4.5),
      ('accentText on accentSubtle', t.accentText, t.accentSubtle, 4.5),
      for (final tone in Fluent2Tone.values) ...[
        // The tint laid on the page (the informative tint is a step of ink
        // by day).
        (
          '${tone.name} ink on its tint',
          t.tone(tone).ink,
          Color.alphaBlend(t.tone(tone).tint, t.background),
          4.5,
        ),
        (
          '${tone.name} onSolid on its solid',
          t.tone(tone).onSolid,
          t.tone(tone).solid,
          4.5,
        ),
      ],
      (
        'disabled words on disabled fill',
        t.textDisabled,
        t.colors.neutralBackgroundDisabled,
        1.5,
      ),
    ];
  }

  test('every preset and mode holds the contrast floors', () {
    final failures = <String>[];
    for (final t in themes) {
      for (final (label, ink, ground, floor) in pairs(t)) {
        final ratio = Fluent2ThemeData.contrast(ink, ground);
        if (ratio < floor) {
          failures.add(
            '${name(t)}: $label ${ratio.toStringAsFixed(2)} < $floor',
          );
        }
      }
    }
    expect(failures, isEmpty, reason: failures.join('\n'));
  });

  test('a theme from any brand colour holds the same floors', () {
    const seeds = [
      Color(0xFF0F6CBD), // Fluent's own blue
      Color(0xFFFFD400), // a yellow too light for white words
      Color(0xFF7FDBFF), // a pale cyan
      Color(0xFF0B1F3A), // a navy too dark for words on dark
      Color(0xFFE81123), // a red
      Color(0xFF00B294), // a teal
      Color(0xFF8A3FFC), // a violet
      Color(0xFF808080), // a mid grey
    ];
    final failures = <String>[];
    for (final seed in seeds) {
      for (final b in Brightness.values) {
        final t = Fluent2ThemeData.from(brand: seed, brightness: b);
        for (final (label, ink, ground, floor) in pairs(t)) {
          final ratio = Fluent2ThemeData.contrast(ink, ground);
          if (ratio < floor) {
            failures.add(
              '${seed.toARGB32().toRadixString(16)} ${b.name}: '
              '$label ${ratio.toStringAsFixed(2)} < $floor',
            );
          }
        }
      }
    }
    expect(failures, isEmpty, reason: failures.join('\n'));
  });

  test('a theme from Fluent\'s own blue is the lapis preset\'s brand', () {
    for (final b in Brightness.values) {
      final own = Fluent2ThemeData.preset('lapis', b);
      final made = Fluent2ThemeData.from(
        brand: own.brandVariants[7],
        brightness: b,
        density: Fluent2Density.compact,
      );
      expect(made.brandVariants[7], own.brandVariants[7]);
      expect(made.colors.neutralBackground1, own.colors.neutralBackground1);
      expect(made.density, Fluent2Density.compact);
    }
  });

  test('the presets are seven, the first the default, each designed twice', () {
    expect(Fluent2ThemeData.presets, [
      'lapis',
      'iris',
      'juniper',
      'clover',
      'pumpkin',
      'berry',
      'flint',
    ]);
    for (final id in Fluent2ThemeData.presets) {
      final light = Fluent2ThemeData.preset(id, Brightness.light);
      final dark = Fluent2ThemeData.preset(id, Brightness.dark);
      expect(light.isDark, isFalse);
      expect(dark.isDark, isTrue);
      expect(light.brandVariants, hasLength(16));
      expect(
        identical(light.brandVariants, dark.brandVariants),
        isTrue,
        reason: id,
      );
      expect(
        dark.surface.computeLuminance(),
        lessThan(light.surface.computeLuminance()),
      );
      expect(
        identical(Fluent2ThemeData.preset(id, Brightness.light), light),
        isTrue,
      );
    }
    expect(
      () => Fluent2ThemeData.preset('fluent', Brightness.light),
      throwsArgumentError,
    );
  });

  test('the lapis preset is Fluent web light and dark', () {
    final light = Fluent2ThemeData.preset('lapis', Brightness.light);
    final dark = Fluent2ThemeData.preset('lapis', Brightness.dark);
    expect(light.colors.brandBackground, const Color(0xFF0F6CBD));
    expect(light.colors.neutralBackground1, const Color(0xFFFFFFFF));
    expect(light.colors.neutralForeground1, const Color(0xFF242424));
    expect(dark.colors.neutralBackground1, const Color(0xFF292929));
    expect(dark.colors.brandBackground, const Color(0xFF115EA3));
  });

  test('the colours round-trip through their map', () {
    for (final t in themes) {
      expect(Fluent2Colors.fromMap(t.colors.toMap()).toMap(), t.colors.toMap());
    }
  });

  test('the type ramp is Fluent\'s, in Selawik', () {
    final t = themes.first;
    expect(t.body1.fontFamily, Fluent2ThemeData.face);
    expect(t.body1.fontSize, 14);
    expect(t.body1.fontSize! * t.body1.height!, closeTo(20, 0.001));
    expect(t.subtitle1.fontSize, 20);
    expect(t.subtitle1.fontWeight, FontWeight.w600);
    expect(t.title2.fontSize! * t.title2.height!, closeTo(36, 0.001));
    expect(t.caption1.fontSize, 12);
  });
}
