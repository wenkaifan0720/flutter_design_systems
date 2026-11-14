/// The type scale's values: w1-type's test, with `type.dart`, its
/// `internal/type/` part and the generator's `emit/type.ts`. Every one of
/// the 30 styles is the generated tokens' size, line height, tracking and
/// weight in Roboto Flex, with opsz = size and wght = weight.
library;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';
import 'package:material_expressive_ui/src/material_expressive/internal/tokens/tokens.g.dart';
import 'package:material_expressive_ui/src/material_expressive/internal/type/font_metrics.g.dart';
import 'package:material_expressive_ui/src/material_expressive/internal/type/text_height.dart';

/// [style]'s value on the variation axis [axis].
double? _axis(TextStyle style, String axis) {
  final values = <double>[
    for (final variation in style.fontVariations ?? const <FontVariation>[])
      if (variation.axis == axis) variation.value,
  ];
  expect(values.length, lessThanOrEqualTo(1), reason: 'one $axis');
  return values.isEmpty ? null : values.single;
}

/// Every named getter, by its key.
Map<ExpressiveTypeKey, TextStyle> _named(ExpressiveTextTheme t) =>
    <ExpressiveTypeKey, TextStyle>{
      ExpressiveTypeKey.displayLarge: t.displayLarge,
      ExpressiveTypeKey.displayMedium: t.displayMedium,
      ExpressiveTypeKey.displaySmall: t.displaySmall,
      ExpressiveTypeKey.headlineLarge: t.headlineLarge,
      ExpressiveTypeKey.headlineMedium: t.headlineMedium,
      ExpressiveTypeKey.headlineSmall: t.headlineSmall,
      ExpressiveTypeKey.titleLarge: t.titleLarge,
      ExpressiveTypeKey.titleMedium: t.titleMedium,
      ExpressiveTypeKey.titleSmall: t.titleSmall,
      ExpressiveTypeKey.bodyLarge: t.bodyLarge,
      ExpressiveTypeKey.bodyMedium: t.bodyMedium,
      ExpressiveTypeKey.bodySmall: t.bodySmall,
      ExpressiveTypeKey.labelLarge: t.labelLarge,
      ExpressiveTypeKey.labelMedium: t.labelMedium,
      ExpressiveTypeKey.labelSmall: t.labelSmall,
      ExpressiveTypeKey.displayLargeEmphasized: t.displayLargeEmphasized,
      ExpressiveTypeKey.displayMediumEmphasized: t.displayMediumEmphasized,
      ExpressiveTypeKey.displaySmallEmphasized: t.displaySmallEmphasized,
      ExpressiveTypeKey.headlineLargeEmphasized: t.headlineLargeEmphasized,
      ExpressiveTypeKey.headlineMediumEmphasized: t.headlineMediumEmphasized,
      ExpressiveTypeKey.headlineSmallEmphasized: t.headlineSmallEmphasized,
      ExpressiveTypeKey.titleLargeEmphasized: t.titleLargeEmphasized,
      ExpressiveTypeKey.titleMediumEmphasized: t.titleMediumEmphasized,
      ExpressiveTypeKey.titleSmallEmphasized: t.titleSmallEmphasized,
      ExpressiveTypeKey.bodyLargeEmphasized: t.bodyLargeEmphasized,
      ExpressiveTypeKey.bodyMediumEmphasized: t.bodyMediumEmphasized,
      ExpressiveTypeKey.bodySmallEmphasized: t.bodySmallEmphasized,
      ExpressiveTypeKey.labelLargeEmphasized: t.labelLargeEmphasized,
      ExpressiveTypeKey.labelMediumEmphasized: t.labelMediumEmphasized,
      ExpressiveTypeKey.labelSmallEmphasized: t.labelSmallEmphasized,
    };

void main() {
  test(
    'custom families survive locale changes without contaminating defaults',
    () {
      const custom = ExpressiveTextTheme(
        displayFamily: 'AppDisplay',
        textFamily: 'AppText',
        fontPackage: null,
      );
      const original = ExpressiveTextTheme();
      expect(custom.displayLarge.fontFamily, 'AppDisplay');
      expect(custom.bodyLarge.fontFamily, 'AppText');
      expect(custom.bodyLarge.fontSize, original.bodyLarge.fontSize);
      expect(custom.bodyLarge.height, original.bodyLarge.height);
      expect(original.bodyLarge.fontFamily, expressiveFontFamily('RobotoFlex'));
      final localized = custom.forLocale(const Locale('ja'));
      expect(localized.displayFamily, 'AppDisplay');
      expect(localized.textFamily, 'AppText');
      expect(localized.fontPackage, isNull);
      expect(custom.copyWith(), custom);
    },
  );

  test('type interpolation does not change its family early', () {
    const a = ExpressiveTextTheme(textFamily: 'Start', fontPackage: null);
    const b = ExpressiveTextTheme(textFamily: 'End', fontPackage: null);
    final quarter = ExpressiveTextTheme.lerp(a, b, .25);
    expect(quarter.bodyLarge.fontFamily, 'Start');
    final middle = ExpressiveTextTheme.lerp(a, b, .5);
    expect(middle.bodyLarge.fontFamily, 'End');
    expect(identical(middle.bodyLarge, middle.bodyLarge), isTrue);
  });

  const scale = ExpressiveTextTheme();

  test('every theme wears the one scale, English-like', () {
    for (final id in ExpressiveThemeData.presets) {
      for (final brightness in Brightness.values) {
        final t = ExpressiveThemeData.preset(id, brightness);
        expect(t.type, scale);
        expect(t.type.languageHeight, ExpressiveLanguageHeight.englishLike);
      }
    }
  });

  test('every style is its generated tokens, in Roboto Flex', () {
    expect(ExpressiveTypeKey.values, hasLength(30));
    for (final key in ExpressiveTypeKey.values) {
      final token = TypographyTokens.of(key);
      final style = scale.of(key);
      final reason = key.name;
      expect(token.fontFamily, FontFamilyToken.sansSerif, reason: reason);
      expect(
        style.fontFamily,
        expressiveFontFamily('RobotoFlex'),
        reason: reason,
      );
      expect(style.fontSize, token.fontSize, reason: reason);
      expect(lineHeight(style), closeTo(token.lineHeight, 1e-9));
      expect(style.letterSpacing, token.letterSpacing, reason: reason);
      expect(style.fontWeight, token.fontWeight, reason: reason);
      expect(style.leadingDistribution, TextLeadingDistribution.even);
      expect(style.fontVariations, hasLength(2), reason: reason);
    }
  });

  test('opsz is the font size and wght the weight, in every style', () {
    for (final key in ExpressiveTypeKey.values) {
      final style = scale.of(key);
      expect(_axis(style, 'opsz'), style.fontSize, reason: key.name);
      expect(
        _axis(style, 'wght'),
        style.fontWeight!.value.toDouble(),
        reason: key.name,
      );
    }
  });

  test('the named getters are the keyed styles', () {
    final named = _named(scale);
    expect(named.keys.toSet(), ExpressiveTypeKey.values.toSet());
    for (final MapEntry(:key, :value) in named.entries) {
      expect(value, scale.of(key), reason: key.name);
    }
  });

  test('spot values against Compose\'s TypeScaleTokens', () {
    // Read by hand from TypeScaleTokens.kt (v0_103): BodyLarge 16/24,
    // +0.5, W400; DisplayLarge 57/64, -0.2 (the jar over the DB's -0.25).
    final body = scale.bodyLarge;
    expect(
      (body.fontSize, body.fontSize! * body.height!, body.letterSpacing),
      (16.0, 24.0, 0.5),
    );
    expect(body.fontWeight, FontWeight.w400);
    final display = scale.displayLarge;
    expect(
      (display.fontSize, display.fontSize! * display.height!),
      (57.0, 64.0),
    );
    expect(display.letterSpacing, -0.2);
  });

  group('language height', () {
    test('categories', () {
      ExpressiveLanguageHeight of(String code) =>
          ExpressiveLanguageHeight.of(Locale(code));
      expect(of('en'), ExpressiveLanguageHeight.englishLike);
      expect(of('de'), ExpressiveLanguageHeight.englishLike);
      expect(of('ru'), ExpressiveLanguageHeight.englishLike);
      expect(of('ja'), ExpressiveLanguageHeight.dense);
      expect(of('zh'), ExpressiveLanguageHeight.dense);
      expect(of('ar'), ExpressiveLanguageHeight.tall);
      expect(of('hi'), ExpressiveLanguageHeight.tall);
      expect(of('vi'), ExpressiveLanguageHeight.tall);
    });

    test('every category keeps the tokens\' line heights, as Compose', () {
      final dense = scale.forLocale(const Locale('ja'));
      final tall = scale.forLocale(const Locale('ar'));
      expect(dense.languageHeight, ExpressiveLanguageHeight.dense);
      expect(tall.languageHeight, ExpressiveLanguageHeight.tall);
      for (final key in ExpressiveTypeKey.values) {
        final token = TypographyTokens.of(key);
        for (final s in [dense, tall]) {
          final style = s.of(key);
          expect(lineHeight(style), closeTo(token.lineHeight, 1e-9));
          expect(style.fontSize, token.fontSize);
          expect(style.letterSpacing, token.letterSpacing);
          expect(_axis(style, 'opsz'), style.fontSize);
        }
      }
      expect(lineHeight(tall.bodyLarge), 24);
    });
  });

  testWidgets('the bundled Roboto Flex loads and varies on wght and opsz', (
    tester,
  ) async {
    final bytes = rootBundle.load('assets/fonts/RobotoFlex.ttf');
    await tester.runAsync(
      () => (FontLoader(
        expressiveFontFamily(ExpressiveTextTheme.family),
      )..addFont(bytes)).load(),
    );
    double width(TextStyle style) {
      final painter = TextPainter(
        text: TextSpan(text: 'Expressive type', style: style),
        textDirection: TextDirection.ltr,
      )..layout();
      final width = painter.width;
      painter.dispose();
      return width;
    }

    final base = scale.bodyLarge;
    final bold = base.copyWith(
      fontWeight: FontWeight.w700,
      fontVariations: const <FontVariation>[
        FontVariation.weight(700),
        FontVariation.opticalSize(16),
      ],
    );
    final display = base.copyWith(
      fontVariations: const <FontVariation>[
        FontVariation.weight(400),
        FontVariation.opticalSize(144),
      ],
    );
    expect(width(bold), isNot(width(base)));
    expect(width(display), isNot(width(base)));
  });

  testWidgets('a style shorter than the font keeps its edges, as Compose', (
    tester,
  ) async {
    // Compose's LineHeightStyle(Center, Trim.None): where the line height
    // is under Roboto Flex's ascent + descent, the first line keeps the
    // font's ascent and the last its descent (the oracle's type/display-*).
    final bytes = rootBundle.load('assets/fonts/RobotoFlex.ttf');
    await tester.runAsync(
      () => (FontLoader(
        expressiveFontFamily(ExpressiveTextTheme.family),
      )..addFont(bytes)).load(),
    );
    const font =
        ExpressiveRobotoFlexMetrics.ascent +
        ExpressiveRobotoFlexMetrics.descent;
    final short = <ExpressiveTypeKey>[];
    for (final key in ExpressiveTypeKey.values) {
      final (style, behavior) = expressiveTextLayout(scale.of(key));
      final painter = TextPainter(
        text: TextSpan(text: 'Expressive\nType 2026', style: style),
        textDirection: TextDirection.ltr,
        textHeightBehavior: behavior,
      )..layout();
      final token = TypographyTokens.of(key);
      final overhang = token.fontSize * font - token.lineHeight;
      final expected = 2 * token.lineHeight + (overhang > 0 ? overhang : 0);
      if (overhang > 0) short.add(key);
      expect(painter.height, closeTo(expected, 1), reason: key.name);
      painter.dispose();
    }
    expect(
      short,
      containsAll(<ExpressiveTypeKey>[
        ExpressiveTypeKey.displayLarge,
        ExpressiveTypeKey.displayMedium,
      ]),
    );
    expect(short, hasLength(4), reason: 'display large/medium, both weights');
  });
}

/// [s]'s line height in sp.
double lineHeight(TextStyle s) => s.fontSize! * s.height!;
