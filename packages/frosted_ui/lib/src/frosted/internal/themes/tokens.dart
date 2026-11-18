import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter/painting.dart';

/// One text slot of a baked catalog theme: the face it names, its size,
/// weight (100..900), line height as a multiple and tracking in points.
@immutable
final class FrostedTokenType {
  /// A type role of its [font], [size], [weight], [height] and [letterSpacing].
  const FrostedTokenType({
    required this.font,
    required this.size,
    required this.weight,
    required this.height,
    required this.letterSpacing,
  });

  /// The family.
  final String font;

  /// The size, in points.
  final double size;

  /// The weight, 100 to 900.
  final int weight;

  /// The line height, a multiple of [size].
  final double height;

  /// The tracking, in points.
  final double letterSpacing;
}

/// One elevation layer of a baked catalog theme.
@immutable
final class FrostedTokenShadow {
  /// A shadow of its [color], [blur], [offsetY] and [spread].
  const FrostedTokenShadow({
    required this.color,
    required this.blur,
    required this.offsetY,
    required this.spread,
  });

  /// Its colour.
  final Color color;

  /// How soft it is.
  final double blur;

  /// How far below the face it falls.
  final double offsetY;

  /// How far past the face it reaches.
  final double spread;

  /// This layer as a Flutter shadow.
  BoxShadow get shadow => BoxShadow(
    color: color,
    blurRadius: blur,
    offset: Offset(0, offsetY),
    spreadRadius: spread,
  );
}

/// The colours of one appearance of a baked catalog theme: Cody's role names,
/// which is what ThemeTokens v2 records.
@immutable
final class FrostedTokenColors {
  /// One appearance's colours.
  const FrostedTokenColors({
    required this.background,
    required this.surface,
    required this.surfaceAlt,
    required this.surfaceInverse,
    required this.border,
    required this.borderStrong,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.textInverse,
    required this.accent,
    required this.onAccent,
    required this.accentSubtle,
    required this.success,
    required this.onSuccess,
    required this.successSubtle,
    required this.warning,
    required this.warningSubtle,
    required this.danger,
    required this.onDanger,
    required this.dangerSubtle,
    required this.overlay,
    required this.accentText,
    required this.emphasis,
    required this.onEmphasis,
    required this.shadowSm,
    required this.shadowMd,
    required this.shadowLg,
  });

  /// The canvas every page stands on.
  final Color background;

  /// A tile's ground.
  final Color surface;

  /// A quieter ground: a well, a wash.
  final Color surfaceAlt;

  /// The ink slab's ground (a toast, the act).
  final Color surfaceInverse;

  /// The hairline.
  final Color border;

  /// A heavier rule.
  final Color borderStrong;

  /// The words.
  final Color textPrimary;

  /// The second line's words.
  final Color textSecondary;

  /// Quiet words: placeholders, captions.
  final Color textTertiary;

  /// Words on [surfaceInverse].
  final Color textInverse;

  /// The accent.
  final Color accent;

  /// Words and glyphs on [accent].
  final Color onAccent;

  /// The accent's wash (a chosen row).
  final Color accentSubtle;

  /// Good news.
  final Color success;

  /// Words and glyphs on [success].
  final Color onSuccess;

  /// Good news's wash.
  final Color successSubtle;

  /// A warning.
  final Color warning;

  /// A warning's wash.
  final Color warningSubtle;

  /// A loss or an error.
  final Color danger;

  /// Words and glyphs on [danger].
  final Color onDanger;

  /// An error's wash.
  final Color dangerSubtle;

  /// The scrim under a sheet or a dialog.
  final Color overlay;

  /// The accent set as words on the canvas.
  final Color accentText;

  /// The ink act's fill.
  final Color emphasis;

  /// Words and glyphs on [emphasis].
  final Color onEmphasis;

  /// A small lift's shadows.
  final List<FrostedTokenShadow> shadowSm;

  /// A middle lift's shadows.
  final List<FrostedTokenShadow> shadowMd;

  /// A large lift's shadows.
  final List<FrostedTokenShadow> shadowLg;

  /// This with the named roles replaced.
  FrostedTokenColors copyWith({
    Color? background,
    Color? surface,
    Color? surfaceAlt,
    Color? surfaceInverse,
    Color? border,
    Color? borderStrong,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? textInverse,
    Color? accent,
    Color? onAccent,
    Color? accentSubtle,
    Color? success,
    Color? onSuccess,
    Color? successSubtle,
    Color? warning,
    Color? warningSubtle,
    Color? danger,
    Color? onDanger,
    Color? dangerSubtle,
    Color? overlay,
    Color? accentText,
    Color? emphasis,
    Color? onEmphasis,
    List<FrostedTokenShadow>? shadowSm,
    List<FrostedTokenShadow>? shadowMd,
    List<FrostedTokenShadow>? shadowLg,
  }) => FrostedTokenColors(
    background: background ?? this.background,
    surface: surface ?? this.surface,
    surfaceAlt: surfaceAlt ?? this.surfaceAlt,
    surfaceInverse: surfaceInverse ?? this.surfaceInverse,
    border: border ?? this.border,
    borderStrong: borderStrong ?? this.borderStrong,
    textPrimary: textPrimary ?? this.textPrimary,
    textSecondary: textSecondary ?? this.textSecondary,
    textTertiary: textTertiary ?? this.textTertiary,
    textInverse: textInverse ?? this.textInverse,
    accent: accent ?? this.accent,
    onAccent: onAccent ?? this.onAccent,
    accentSubtle: accentSubtle ?? this.accentSubtle,
    success: success ?? this.success,
    onSuccess: onSuccess ?? this.onSuccess,
    successSubtle: successSubtle ?? this.successSubtle,
    warning: warning ?? this.warning,
    warningSubtle: warningSubtle ?? this.warningSubtle,
    danger: danger ?? this.danger,
    onDanger: onDanger ?? this.onDanger,
    dangerSubtle: dangerSubtle ?? this.dangerSubtle,
    overlay: overlay ?? this.overlay,
    accentText: accentText ?? this.accentText,
    emphasis: emphasis ?? this.emphasis,
    onEmphasis: onEmphasis ?? this.onEmphasis,
    shadowSm: shadowSm ?? this.shadowSm,
    shadowMd: shadowMd ?? this.shadowMd,
    shadowLg: shadowLg ?? this.shadowLg,
  );
}

/// The corner language of a baked catalog theme.
@immutable
final class FrostedTokenShape {
  /// The look's corners.
  const FrostedTokenShape({
    required this.cardRadius,
    required this.controlRadius,
    required this.smallRadius,
    required this.sheetRadius,
  });

  /// A tile's corner.
  final double cardRadius;

  /// A control's corner.
  final double controlRadius;

  /// A small part's corner.
  final double smallRadius;

  /// A sheet's corner.
  final double sheetRadius;
}

/// A ThemeTokens v2 record, baked into constants
/// (`internal/themes/<id>.g.dart`, drift-gated against the JSON by the
/// catalog's tests): both appearances, the twelve type slots and the shape.
/// `FrostedThemeData._fromTokens` dresses the system in one.
@immutable
final class FrostedTokens {
  /// A look's raw tokens: colours in both appearances, the type roles and the
  /// corners.
  const FrostedTokens({
    required this.light,
    required this.dark,
    required this.giant,
    required this.hero,
    required this.display,
    required this.h1,
    required this.h2,
    required this.h3,
    required this.bodyLarge,
    required this.body,
    required this.bodySmall,
    required this.caption,
    required this.label,
    required this.mono,
    required this.shape,
  });

  /// The light appearance's colours.
  final FrostedTokenColors light;

  /// The dark appearance's colours.
  final FrostedTokenColors dark;

  /// The largest figure's type.
  final FrostedTokenType giant;

  /// A hero figure's type.
  final FrostedTokenType hero;

  /// A display title's type.
  final FrostedTokenType display;

  /// The first heading's type.
  final FrostedTokenType h1;

  /// The second heading's type.
  final FrostedTokenType h2;

  /// The third heading's type.
  final FrostedTokenType h3;

  /// Large body text's type.
  final FrostedTokenType bodyLarge;

  /// Body text's type.
  final FrostedTokenType body;

  /// Small body text's type.
  final FrostedTokenType bodySmall;

  /// A caption's type.
  final FrostedTokenType caption;

  /// A control's label's type.
  final FrostedTokenType label;

  /// Fixed-width text's type.
  final FrostedTokenType mono;

  /// The corners.
  final FrostedTokenShape shape;
}
