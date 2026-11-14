/// Expressive's type: [ExpressiveTextTheme], the 30 styles (15 baseline,
/// 15 emphasized) of Compose's `TypeScaleTokens` set in Roboto Flex, which
/// `context.expressiveTheme.type` carries (CONTRACT §2 "Type"; wave
/// decision E7). Owner: w1-type.
///
/// Every style comes from the generated tokens (`internal/tokens/`:
/// `TypographyTokens.of(key)` over `TypeScaleTokens`), never a literal:
///
/// - family Roboto Flex (the bundled `RobotoFlex`, trimmed to `wght` +
///   `opsz`), the only typeface Expressive wears;
/// - size, weight, tracking and line height the token's;
/// - `FontVariation('wght', weight)` and `FontVariation('opsz', size)`:
///   Flutter never sets the optical size itself, and Roboto Flex's default
///   (14) would draw every other size with the wrong optics. The optical
///   size is the token's size: text scaling enlarges the glyphs, not their
///   optics, as on Android;
/// - the line height laid out as Compose lays it (`DefaultLineHeightStyle`:
///   alignment Center, trim None): [TextLeadingDistribution.even].
///
/// Line heights are the tokens' in every locale, as in Compose
/// ([ExpressiveLanguageHeight] names a locale's category, informationally).
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'fonts.dart';
import 'internal/tokens/keys.g.dart';
import 'internal/tokens/token_types.g.dart';
import 'internal/tokens/typography_tokens.g.dart';
import 'internal/type/language_height.g.dart';

/// How tall a language's script runs: the category of a locale's
/// language.
///
/// Every category wears the tokens' line heights exactly, as Compose's
/// `MaterialExpressiveTheme` lays out every locale (`TypeScaleTokens` has
/// one line height per style, whatever the script). The category is
/// informational: a caller may read it, the type scale does not vary by it.
enum ExpressiveLanguageHeight {
  /// Latin, Greek, Cyrillic and the like.
  englishLike,

  /// Chinese, Japanese and Korean.
  dense,

  /// Scripts that run taller than Latin (Arabic and Hebrew, the Indic and
  /// South-East Asian scripts, Vietnamese's stacked diacritics).
  tall;

  /// The category of [locale]'s language.
  static ExpressiveLanguageHeight of(Locale locale) {
    final language = locale.languageCode;
    if (LanguageHeightTokens.denseLanguages.contains(language)) return dense;
    if (LanguageHeightTokens.tallLanguages.contains(language)) return tall;
    return englishLike;
  }

  /// A style's line height [token] in this category: the token, always.
  double lineHeight(Sp token) => token;
}

/// The type scale of one theme: the 30 styles by [ExpressiveTypeKey]
/// ([of]) and by name.
@immutable
class ExpressiveTextTheme with Diagnosticable {
  /// A type scale of the given [languageHeight].
  const ExpressiveTextTheme({
    this.languageHeight = ExpressiveLanguageHeight.englishLike,
    this.displayFamily = family,
    this.textFamily = family,
    this.fontPackage = expressiveFontPackage,
  });

  /// The family used for display and headline styles.
  final String displayFamily;

  /// The family used for title, body and label styles.
  final String textFamily;

  /// The package bundling the families, or null for app-owned fonts.
  final String? fontPackage;

  /// This scale with the supplied settings replaced.
  ExpressiveTextTheme copyWith({
    ExpressiveLanguageHeight? languageHeight,
    String? displayFamily,
    String? textFamily,
  }) => ExpressiveTextTheme(
    languageHeight: languageHeight ?? this.languageHeight,
    displayFamily: displayFamily ?? this.displayFamily,
    textFamily: textFamily ?? this.textFamily,
    fontPackage: fontPackage,
  );

  /// The bundled variable Roboto Flex's family (the module's pubspec), in
  /// [expressiveFontPackage] when a package bundles it.
  static const String family = 'RobotoFlex';

  /// The language-height category the line heights follow.
  final ExpressiveLanguageHeight languageHeight;

  /// This scale in [locale]'s language-height category.
  ExpressiveTextTheme forLocale(Locale locale) =>
      copyWith(languageHeight: ExpressiveLanguageHeight.of(locale));

  /// The style of [key].
  TextStyle of(ExpressiveTypeKey key) =>
      (_styles[this] ??= <ExpressiveTypeKey, TextStyle>{}).putIfAbsent(
        key,
        () => _build(key),
      );

  // Animation frames must not be kept alive by a process-wide value-keyed cache.
  static final _styles = Expando<Map<ExpressiveTypeKey, TextStyle>>();

  /// The nearest scale: font families and the locale do not interpolate.
  static ExpressiveTextTheme lerp(
    ExpressiveTextTheme a,
    ExpressiveTextTheme b,
    double t,
  ) => t < .5 ? a : b;

  TextStyle _build(ExpressiveTypeKey key) {
    final token = TypographyTokens.of(key);
    final double size = token.fontSize;
    final display =
        key.name.startsWith('display') || key.name.startsWith('headline');
    final weight = token.fontWeight;
    return TextStyle(
      fontFamily: display ? displayFamily : textFamily,
      package: fontPackage,
      fontSize: size,
      fontWeight: weight,
      letterSpacing: token.letterSpacing,
      height: languageHeight.lineHeight(token.lineHeight) / token.fontSize,
      leadingDistribution: TextLeadingDistribution.even,
      fontVariations: <FontVariation>[
        FontVariation.weight(weight.value.toDouble()),
        FontVariation.opticalSize(size),
      ],
    );
  }

  /// Display, large.
  TextStyle get displayLarge => of(ExpressiveTypeKey.displayLarge);

  /// Display, medium.
  TextStyle get displayMedium => of(ExpressiveTypeKey.displayMedium);

  /// Display, small.
  TextStyle get displaySmall => of(ExpressiveTypeKey.displaySmall);

  /// Headline, large.
  TextStyle get headlineLarge => of(ExpressiveTypeKey.headlineLarge);

  /// Headline, medium.
  TextStyle get headlineMedium => of(ExpressiveTypeKey.headlineMedium);

  /// Headline, small.
  TextStyle get headlineSmall => of(ExpressiveTypeKey.headlineSmall);

  /// Title, large.
  TextStyle get titleLarge => of(ExpressiveTypeKey.titleLarge);

  /// Title, medium.
  TextStyle get titleMedium => of(ExpressiveTypeKey.titleMedium);

  /// Title, small.
  TextStyle get titleSmall => of(ExpressiveTypeKey.titleSmall);

  /// Body, large.
  TextStyle get bodyLarge => of(ExpressiveTypeKey.bodyLarge);

  /// Body, medium.
  TextStyle get bodyMedium => of(ExpressiveTypeKey.bodyMedium);

  /// Body, small.
  TextStyle get bodySmall => of(ExpressiveTypeKey.bodySmall);

  /// Label, large.
  TextStyle get labelLarge => of(ExpressiveTypeKey.labelLarge);

  /// Label, medium.
  TextStyle get labelMedium => of(ExpressiveTypeKey.labelMedium);

  /// Label, small.
  TextStyle get labelSmall => of(ExpressiveTypeKey.labelSmall);

  /// Display, large, emphasized.
  TextStyle get displayLargeEmphasized =>
      of(ExpressiveTypeKey.displayLargeEmphasized);

  /// Display, medium, emphasized.
  TextStyle get displayMediumEmphasized =>
      of(ExpressiveTypeKey.displayMediumEmphasized);

  /// Display, small, emphasized.
  TextStyle get displaySmallEmphasized =>
      of(ExpressiveTypeKey.displaySmallEmphasized);

  /// Headline, large, emphasized.
  TextStyle get headlineLargeEmphasized =>
      of(ExpressiveTypeKey.headlineLargeEmphasized);

  /// Headline, medium, emphasized.
  TextStyle get headlineMediumEmphasized =>
      of(ExpressiveTypeKey.headlineMediumEmphasized);

  /// Headline, small, emphasized.
  TextStyle get headlineSmallEmphasized =>
      of(ExpressiveTypeKey.headlineSmallEmphasized);

  /// Title, large, emphasized.
  TextStyle get titleLargeEmphasized =>
      of(ExpressiveTypeKey.titleLargeEmphasized);

  /// Title, medium, emphasized.
  TextStyle get titleMediumEmphasized =>
      of(ExpressiveTypeKey.titleMediumEmphasized);

  /// Title, small, emphasized.
  TextStyle get titleSmallEmphasized =>
      of(ExpressiveTypeKey.titleSmallEmphasized);

  /// Body, large, emphasized.
  TextStyle get bodyLargeEmphasized =>
      of(ExpressiveTypeKey.bodyLargeEmphasized);

  /// Body, medium, emphasized.
  TextStyle get bodyMediumEmphasized =>
      of(ExpressiveTypeKey.bodyMediumEmphasized);

  /// Body, small, emphasized.
  TextStyle get bodySmallEmphasized =>
      of(ExpressiveTypeKey.bodySmallEmphasized);

  /// Label, large, emphasized.
  TextStyle get labelLargeEmphasized =>
      of(ExpressiveTypeKey.labelLargeEmphasized);

  /// Label, medium, emphasized.
  TextStyle get labelMediumEmphasized =>
      of(ExpressiveTypeKey.labelMediumEmphasized);

  /// Label, small, emphasized.
  TextStyle get labelSmallEmphasized =>
      of(ExpressiveTypeKey.labelSmallEmphasized);

  @override
  bool operator ==(Object other) =>
      other is ExpressiveTextTheme &&
      other.languageHeight == languageHeight &&
      other.displayFamily == displayFamily &&
      other.textFamily == textFamily &&
      other.fontPackage == fontPackage;

  @override
  int get hashCode =>
      Object.hash(languageHeight, displayFamily, textFamily, fontPackage);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('displayFamily', displayFamily))
      ..add(StringProperty('textFamily', textFamily))
      ..add(StringProperty('fontPackage', fontPackage))
      ..add(
        EnumProperty<ExpressiveLanguageHeight>(
          'languageHeight',
          languageHeight,
        ),
      );
  }
}
