/// The ThemeTokens v2 record a baked catalog theme is held in: its colours
/// for each appearance, its text slots and its corners.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import 'theme.dart' show LedgerThemeData;

/// One text slot of a baked catalog theme: the face it names, its size,
/// weight (100..900), line height as a multiple and tracking in points.
@immutable
final class LedgerTokenType {
  /// A text slot as the record names it.
  const LedgerTokenType({
    required this.font,
    required this.size,
    required this.weight,
    required this.height,
    required this.letterSpacing,
  });

  /// The face's family name.
  final String font;

  /// The size in logical pixels.
  final double size;

  /// The weight, 100 to 900.
  final int weight;

  /// The line height, as a multiple of [size].
  final double height;

  /// The tracking, in logical pixels.
  final double letterSpacing;
}

/// One elevation layer of a baked catalog theme.
@immutable
final class LedgerTokenShadow {
  /// An elevation layer as the record names it.
  const LedgerTokenShadow({
    required this.color,
    required this.blur,
    required this.offsetY,
    required this.spread,
  });

  /// The shadow's colour.
  final Color color;

  /// The blur radius.
  final double blur;

  /// How far the shadow falls below its part.
  final double offsetY;

  /// How far the shadow spreads past its part.
  final double spread;

  /// This layer as a Flutter shadow.
  BoxShadow get shadow => BoxShadow(
    color: color,
    blurRadius: blur,
    offset: Offset(0, offsetY),
    spreadRadius: spread,
  );
}

/// The colours of one appearance of a baked catalog theme: Cody's role
/// names, which is what ThemeTokens v2 records.
@immutable
final class LedgerTokenColors {
  /// One appearance's colours as the record names them.
  const LedgerTokenColors({
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

  /// The page's ground.
  final Color background;

  /// A raised surface.
  final Color surface;

  /// A sunken surface.
  final Color surfaceAlt;

  /// The inverse ground.
  final Color surfaceInverse;

  /// A hairline.
  final Color border;

  /// A rule.
  final Color borderStrong;

  /// The main words.
  final Color textPrimary;

  /// Secondary words.
  final Color textSecondary;

  /// Tertiary words.
  final Color textTertiary;

  /// Words on the inverse ground.
  final Color textInverse;

  /// The act colour.
  final Color accent;

  /// Words on [accent].
  final Color onAccent;

  /// The accent's wash.
  final Color accentSubtle;

  /// Success.
  final Color success;

  /// Words on [success].
  final Color onSuccess;

  /// Success's wash.
  final Color successSubtle;

  /// Caution.
  final Color warning;

  /// Caution's wash.
  final Color warningSubtle;

  /// Danger.
  final Color danger;

  /// Words on [danger].
  final Color onDanger;

  /// Danger's wash.
  final Color dangerSubtle;

  /// The scrim under a sheet or a dialog.
  final Color overlay;

  /// Words in the accent.
  final Color accentText;

  /// An emphasised ground.
  final Color emphasis;

  /// Words on [emphasis].
  final Color onEmphasis;

  /// The small elevation.
  final List<LedgerTokenShadow> shadowSm;

  /// The medium elevation.
  final List<LedgerTokenShadow> shadowMd;

  /// The large elevation.
  final List<LedgerTokenShadow> shadowLg;
}

/// The corner language of a baked catalog theme.
@immutable
final class LedgerTokenShape {
  /// A corner language as the record names it.
  const LedgerTokenShape({
    required this.cardRadius,
    required this.controlRadius,
    required this.smallRadius,
    required this.sheetRadius,
  });

  /// A card's corner.
  final double cardRadius;

  /// A control's corner.
  final double controlRadius;

  /// A small part's corner.
  final double smallRadius;

  /// A sheet's and a dialog's corner.
  final double sheetRadius;
}

/// A ThemeTokens v2 record, baked into constants
/// (`internal/themes/<id>.g.dart`, drift-gated against the JSON by the
/// catalog's tests): both appearances, the twelve type slots and the shape.
/// [LedgerThemeData.fromTokens] dresses the system in one.
@immutable
final class LedgerTokens {
  /// A theme record's appearances, type slots and shape.
  const LedgerTokens({
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

  /// The light appearance.
  final LedgerTokenColors light;

  /// The dark appearance.
  final LedgerTokenColors dark;

  /// The largest display slot.
  final LedgerTokenType giant;

  /// A page's hero figure.
  final LedgerTokenType hero;

  /// A display title.
  final LedgerTokenType display;

  /// The first heading.
  final LedgerTokenType h1;

  /// The second heading.
  final LedgerTokenType h2;

  /// The third heading.
  final LedgerTokenType h3;

  /// Large body words.
  final LedgerTokenType bodyLarge;

  /// Body words.
  final LedgerTokenType body;

  /// Small body words.
  final LedgerTokenType bodySmall;

  /// A caption.
  final LedgerTokenType caption;

  /// A control's label.
  final LedgerTokenType label;

  /// Mono words: amounts, dates, numbers.
  final LedgerTokenType mono;

  /// The corner language.
  final LedgerTokenShape shape;
}
