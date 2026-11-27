/// The outline a shaped part of Civic draws.
library;

import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../theme.dart';

/// The outline of a part whose own corners take [step]: its style's
/// `shape` when it gives one (drawn as given), else its style's `corners`
/// over [step] on every corner, held to [CivicThemeData.shapeLimits], on
/// [t]'s scale. [side] strokes it. An app's corners reach its start corners
/// only with [start], its end ones only with [end]: a face joined to another
/// at one side (a split button's halves) keeps its joined corners its own.
OutlinedBorder civicShape(
  CivicThemeData t,
  RawStyleOf so,
  RawCorner step, {
  BorderSide side = BorderSide.none,
  bool start = true,
  bool end = true,
}) => civicShapeOf(
  t,
  so,
  RawCorners.all(step),
  side: side,
  start: start,
  end: end,
);

/// The outline of a part whose own corners are [base] (a sheet's top two,
/// say): as [civicShape], an app's corners over [base]; with [bottom] false
/// they reach its top corners alone (a sheet's foot stands on the screen's
/// edge).
OutlinedBorder civicShapeOf(
  CivicThemeData t,
  RawStyleOf so,
  RawCorners base, {
  BorderSide side = BorderSide.none,
  bool start = true,
  bool end = true,
  bool bottom = true,
}) {
  final shape = so.shape;
  if (shape != null) {
    return side == BorderSide.none ? shape : shape.copyWith(side: side);
  }
  final given = so.corners;
  final held = CivicThemeData.shapeLimits.clampCorners(
    given == null || (start && end && bottom)
        ? given
        : RawCorners(
            topStart: start ? given.topStart : null,
            bottomStart: start && bottom ? given.bottomStart : null,
            topEnd: end ? given.topEnd : null,
            bottomEnd: end && bottom ? given.bottomEnd : null,
          ),
    base: base,
    look: 'Civic',
  );
  return t.shapeScheme.corners.borderOf(held, side: side);
}
