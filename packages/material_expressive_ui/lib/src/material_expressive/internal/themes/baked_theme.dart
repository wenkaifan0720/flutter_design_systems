/// A generated theme preset with color, type, shape and motion definitions.
/// The registry lists these presets in display order.
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

  /// Light and dark color roles.
  final ExpressiveBakedColors colors;

  /// The type scale.
  final ExpressiveBakedTextTheme type;

  /// The corner scale.
  final ExpressiveBakedShapes shapes;

  /// The motion scheme.
  final ExpressiveBakedMotion motion;
}
