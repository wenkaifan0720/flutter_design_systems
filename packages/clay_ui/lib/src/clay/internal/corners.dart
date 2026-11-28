/// A radius between Clay's corner steps, the radius a part draws, and the
/// corner of the slab a row stands on.
library;

import 'package:flutter/widgets.dart';
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

/// The corner radius of the slab a row stands on (a [ClayGroup]'s), so what
/// a row draws inside it (its plate, an open swipe row's actions) keeps
/// concentric with it whatever corners the group's style gives it.
class ClaySlabCorner extends InheritedWidget {
  /// Gives [child] the slab's corner [radius].
  const ClaySlabCorner({super.key, required this.radius, required super.child});

  /// The slab's corner radius.
  final double radius;

  /// The corner of the slab round [context], or null off a slab.
  static double? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ClaySlabCorner>()?.radius;

  @override
  bool updateShouldNotify(ClaySlabCorner old) => old.radius != radius;
}
