/// A radius between Clay's corner steps, and the radius a part draws.
library;

import 'package:ui_core/ui_core.dart';

import '../surface.dart';
import '../theme.dart';

/// Scales a corner that sits between Clay's steps with the theme's control
/// step. [radius] is the corner at Clay's own control step (16); the result
/// keeps its proportion as an app's theme makes the steps rounder or
/// squarer: a link's focus well, a key cap, a table's rows and cells.
double clayCornerBetween(ClayThemeData theme, double radius) =>
    radius * theme.shapeScheme.corners.medium / 16;

/// The corner radius a part draws whose own corners are the step [base] (or
/// [own], a radius between the steps): a style's `shape` as given, outside
/// Clay's limits, as Material's `ButtonStyle.shape` is; else a style's
/// `corners`, held to [ClayThemeData.shapeLimits] (one step on every
/// corner, never square); else its own. A step is the theme's, so it
/// follows a rounder or a squarer scheme and its lerps.
double clayCornerRadius(
  ClayThemeData theme,
  RawStyleOf layered,
  RawCorner base, {
  double? own,
}) {
  final scale = theme.shapeScheme.corners;
  final mine = own ?? scale.radius(base);
  final shape = layered.shape;
  if (shape != null) return clayRadiusOf(shape, mine);
  final whole = RawCorners.all(base);
  final held = ClayThemeData.shapeLimits.clampCorners(
    layered.corners,
    base: whole,
    look: 'Clay',
  );
  return held == whole ? mine : scale.radius(held.topStart ?? base);
}
