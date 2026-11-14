/// The shape a baked theme takes in generated code. `tools/expressive_tokens`
/// writes one `<id>.g.dart` per `themes/<id>/theme.json` — a [ExpressiveBakedTheme]
/// const — and `registry.g.dart`, which lists them in module.yaml's preset
/// order (`bun run --filter expressive-tokens generate`; `check` fails on
/// drift). This type is hand-written; the consts never are.
///
/// A baked theme is its record plus one part per themed foundation, each
/// part's type owned by that foundation (`internal/<foundation>/baked_*.dart`,
/// exported from here for the generated files) and written by its emitter
/// (`emit/<foundation>.ts`). Wave 1 fills the parts, never this file.
///
/// Internal: `ExpressiveThemeData.preset` reads it, and nothing outside the
/// system names it.
library;

import 'package:flutter/foundation.dart' show immutable;

import '../color/baked_colors.dart';
import '../motion/baked_motion.dart';
import '../shape/baked_shapes.dart';
import '../type/baked_type_scale.dart';

export '../color/baked_colors.dart';
export '../motion/baked_motion.dart';
export '../shape/baked_shapes.dart';
export '../type/baked_type_scale.dart';

/// One theme as generated: its `theme.json` record and each foundation's
/// part.
@immutable
class ExpressiveBakedTheme {
  /// A baked theme with the given record and foundation parts.
  const ExpressiveBakedTheme({
    required this.id,
    required this.seed,
    required this.variant,
    required this.contrast,
    required this.expression,
    required this.source,
    required this.colors,
    required this.type,
    required this.shapes,
    required this.motion,
  });

  /// The theme's id: its `themes/<id>/` directory, and its preset name.
  final String id;

  /// The seed colour, ARGB.
  final int seed;

  /// The dynamic-scheme variant: `tonalSpot`, `neutral`, `vibrant` or
  /// `expressive`.
  final String variant;

  /// The contrast level: 0, 0.5 or 1.
  final double contrast;

  /// The expression budget: `calm`, `balanced` or `bold`.
  final String expression;

  /// Where the colours come from when not from the baker —
  /// `compose-baseline`, Compose's own default scheme — or null.
  final String? source;

  /// Every colour role, light and dark (w1-color).
  final ExpressiveBakedColors colors;

  /// The type scale's part (w1-type).
  final ExpressiveBakedTextTheme type;

  /// The shape scale's part (w1-shape).
  final ExpressiveBakedShapes shapes;

  /// The motion part: the scheme (w1-motion).
  final ExpressiveBakedMotion motion;
}
