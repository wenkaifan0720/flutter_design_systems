/// The shape part of a baked theme and how it resolves into the public
/// [ExpressiveShapes]: w1-shape's slot, with `shape.dart` and the
/// generator's `emit/shape.ts`, which also writes the generated shape
/// library here (`library_shapes.g.dart`). Internal; the generated themes
/// name [ExpressiveBakedShapes] and [ShapeTokens] through `baked_theme.dart`.
///
/// A theme bakes Compose's themeable corner scale — the eight steps of its
/// `Shapes` class, each defaulting to the `ShapeTokens` corner
/// `ShapeDefaults` names — as symbolic token references (wave decision
/// E2). None and full are not themeable in Compose (`RectangleShape`,
/// `CircleShape`); they resolve from `ShapeTokens` directly.
library;

import 'package:flutter/widgets.dart';

import '../../shape.dart';
import '../themes/baked_theme.dart';
import '../tokens/token_types.g.dart';

export '../tokens/shape_tokens.g.dart' show ShapeTokens;

/// What a theme bakes for its shapes: the corners of each themeable step
/// of the scale.
@immutable
class ExpressiveBakedShapes {
  /// Baked shapes with the given corners for each step.
  const ExpressiveBakedShapes({
    required this.extraSmall,
    required this.small,
    required this.medium,
    required this.large,
    required this.largeIncreased,
    required this.extraLarge,
    required this.extraLargeIncreased,
    required this.extraExtraLarge,
  });

  /// The corners of the extra-small step.
  final CornersToken extraSmall;

  /// The corners of the small step.
  final CornersToken small;

  /// The corners of the medium step.
  final CornersToken medium;

  /// The corners of the large step.
  final CornersToken large;

  /// The corners of the large-increased step.
  final CornersToken largeIncreased;

  /// The corners of the extra-large step.
  final CornersToken extraLarge;

  /// The corners of the extra-large-increased step.
  final CornersToken extraLargeIncreased;

  /// The corners of the extra-extra-large step.
  final CornersToken extraExtraLarge;
}

/// Compose's default corner scale, `ShapeDefaults`: what every system
/// theme bakes today, and what a theme an app bakes wears
/// (`ExpressiveThemeSpec`, which carries no shapes).
const ExpressiveBakedShapes expressiveComposeDefaultShapes =
    ExpressiveBakedShapes(
      extraSmall: ShapeTokens.cornerExtraSmall,
      small: ShapeTokens.cornerSmall,
      medium: ShapeTokens.cornerMedium,
      large: ShapeTokens.cornerLarge,
      largeIncreased: ShapeTokens.cornerLargeIncreased,
      extraLarge: ShapeTokens.cornerExtraLarge,
      extraLargeIncreased: ShapeTokens.cornerExtraLargeIncreased,
      extraExtraLarge: ShapeTokens.cornerExtraExtraLarge,
    );

/// One token corner as a corner size: a length, or a share of the shorter
/// side (Compose's `CornerSize(percent)`).
ExpressiveCornerSize _cornerSizeOf(CornerToken corner) => switch (corner) {
  CornerDp(:final dp) => ExpressiveCornerSize.dp(dp),
  CornerPercent(:final percent) => ExpressiveCornerSize.fraction(percent / 100),
};

/// [corners] as a border.
ExpressiveCornerBorder _cornerBorderOf(CornersToken corners) =>
    ExpressiveCornerBorder(
      topStart: _cornerSizeOf(corners.topStart),
      topEnd: _cornerSizeOf(corners.topEnd),
      bottomEnd: _cornerSizeOf(corners.bottomEnd),
      bottomStart: _cornerSizeOf(corners.bottomStart),
    );

/// [baked]'s shape scale in [brightness] (shapes do not vary with it).
ExpressiveShapes expressiveResolveShapes(
  ExpressiveBakedTheme baked,
  Brightness brightness,
) {
  final s = baked.shapes;
  return ExpressiveShapes(
    none: _cornerBorderOf(ShapeTokens.cornerNone),
    extraSmall: _cornerBorderOf(s.extraSmall),
    small: _cornerBorderOf(s.small),
    medium: _cornerBorderOf(s.medium),
    large: _cornerBorderOf(s.large),
    largeIncreased: _cornerBorderOf(s.largeIncreased),
    extraLarge: _cornerBorderOf(s.extraLarge),
    extraLargeIncreased: _cornerBorderOf(s.extraLargeIncreased),
    extraExtraLarge: _cornerBorderOf(s.extraExtraLarge),
    full: _cornerBorderOf(ShapeTokens.cornerFull),
  );
}
