/// A radius between Clay's corner steps.
library;

import '../theme.dart';

/// Scales a corner that sits between Clay's steps with the theme's control
/// step. [radius] is the corner at Clay's own control step (16); the result
/// keeps its proportion as an app's theme makes the steps rounder or
/// squarer: a link's focus well, a key cap, a table's rows and cells.
double clayCornerBetween(ClayThemeData theme, double radius) =>
    radius * theme.shapeScheme.corners.medium / 16;
