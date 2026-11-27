// A part's own corners: the step each corner of a part takes, from its style's `corners`, held to Comic's limits
// and drawn on the theme's corner scale. A style's `shape` wins, as given; with no override a part keeps its own outline,
// the very border it drew before.
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../theme.dart';

/// The outline Comic draws at [step] of its scale for [t]: capsule for the extra small step, then small, medium and
/// large.
OutlinedBorder comicOwnShape(ComicThemeData t, RawCorner step) =>
    switch (step) {
      RawCorner.extraSmall => t.shapes.capsule,
      RawCorner.small => t.shapes.small,
      RawCorner.medium => t.shapes.medium,
      RawCorner.large => t.shapes.large,
      RawCorner.full => t.shapes.full,
      RawCorner.none || RawCorner.extraLarge => const RoundedRectangleBorder(),
    };

/// The outline a part whose own corners stand at [step] draws for [look]: [look]'s shape as given; else its corners
/// over the part's own, held to [ComicThemeData.shapeLimits] and drawn on [t]'s corner scale, start and end mirrored
/// right to left; else [own], or Comic's outline at [step].
OutlinedBorder comicPartShape(
  ComicThemeData t,
  RawStyleOf look,
  RawCorner step, {
  OutlinedBorder? own,
}) {
  final given = look.shape;
  if (given != null) return given;
  final fallback = own ?? comicOwnShape(t, step);
  final asked = look.corners;
  if (asked == null || asked.isEmpty) return fallback;
  final mine = RawCorners.all(step);
  final held = ComicThemeData.shapeLimits.clampCorners(
    asked,
    base: mine,
    look: 'Comic',
  );
  if (held == mine) return fallback;
  final scale = t.shapeScheme.corners;
  Radius at(RawCorner? corner) {
    final r = scale.radius(corner ?? step);
    return r <= 0 || !r.isFinite ? Radius.zero : Radius.circular(r);
  }

  return RoundedRectangleBorder(
    borderRadius: BorderRadiusDirectional.only(
      topStart: at(held.topStart),
      topEnd: at(held.topEnd),
      bottomStart: at(held.bottomStart),
      bottomEnd: at(held.bottomEnd),
    ),
  );
}

/// [shape] with its start and end corners placed for [direction], the page's: for a part drawn in a box that reads
/// in another direction (a code's boxes read left to right in any app), so its corners mirror with the page's parts.
OutlinedBorder comicPlacedShape(
  OutlinedBorder shape,
  TextDirection direction,
) =>
    shape is RoundedRectangleBorder &&
        shape.borderRadius is BorderRadiusDirectional
    ? shape.copyWith(borderRadius: shape.borderRadius.resolve(direction))
    : shape;

/// [comicPartShape] at each state, as a press reads its outline for its ring and wash.
WidgetStateProperty<OutlinedBorder?> comicPartShapes(
  ComicThemeData t,
  RawStyleOf look,
  RawCorner step,
) => WidgetStateProperty.resolveWith(
  (states) => comicPartShape(t, look.at(states), step),
);
