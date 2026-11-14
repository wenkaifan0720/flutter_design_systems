/// The motion part of a baked theme, how it resolves into the public
/// [ExpressiveMotion], and where each scheme's springs come from: w1-motion's
/// slot, with `motion.dart` and the generator's `emit/motion.ts`. Internal;
/// the generated themes name [ExpressiveBakedMotion] through `baked_theme.dart`.
///
/// The springs themselves are generated token Dart (w1-tokens' emitter):
/// `ExpressiveMotionTokens` and `StandardMotionTokens` from the pinned jar,
/// the Standard spatial springs being Compose's over the token DB's
/// (`overrides.yaml` `standard-spatial-springs`). This file only picks the
/// scheme's table and says which keys are spatial.
library;

import 'package:flutter/widgets.dart';

import '../../motion.dart';
import '../../theme.dart';
import '../themes/baked_theme.dart';
import '../tokens/expressive_motion_tokens.g.dart';
import '../tokens/standard_motion_tokens.g.dart';
import '../tokens/token_types.g.dart';

/// What a theme bakes for its motion: the `theme.json` motion scheme.
@immutable
class ExpressiveBakedMotion {
  /// A baked motion of the given [scheme].
  const ExpressiveBakedMotion({required this.scheme});

  /// The motion scheme: `expressive` or `standard`.
  final String scheme;
}

/// [baked]'s motion in [brightness]. A theme's motion carries its scheme
/// only; Reduce Motion and a pinned Standard subtree are read where a
/// component runs (`ExpressiveMotion.of`).
ExpressiveMotion expressiveResolveMotion(
  ExpressiveBakedTheme baked,
  Brightness brightness,
) => ExpressiveMotion(
  scheme: ExpressiveMotionScheme.values.byName(baked.motion.scheme),
);

/// The generated spring token of [key] in [scheme]: Compose's
/// `ExpressiveMotionTokens` or `StandardMotionTokens`.
SpringToken expressiveSpringTokenOf(
  ExpressiveMotionScheme scheme,
  ExpressiveMotionKey key,
) => switch (scheme) {
  ExpressiveMotionScheme.expressive => ExpressiveMotionTokens.of(key),
  ExpressiveMotionScheme.standard => StandardMotionTokens.of(key),
};

/// Whether [key] is a spatial spring (it moves, resizes or reshapes) rather
/// than an effects spring (opacity, colour): Compose's `*Spatial` versus
/// `*Effects` members of `MotionSchemeKeyTokens`.
bool expressiveIsSpatialKey(ExpressiveMotionKey key) => switch (key) {
  ExpressiveMotionKey.fastSpatial ||
  ExpressiveMotionKey.defaultSpatial ||
  ExpressiveMotionKey.slowSpatial => true,
  ExpressiveMotionKey.fastEffects ||
  ExpressiveMotionKey.defaultEffects ||
  ExpressiveMotionKey.slowEffects => false,
};
