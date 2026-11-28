// How Fluent 2's parts read an app's per-part corners: a style's
// `corners` held to Fluent's steps over the part's own, drawn in the
// theme's corner scale.
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../styled.dart';
import '../theme.dart';

/// [corners] held to Fluent 2's steps over a part's own [own]; null when
/// [corners] names none (the part draws its own corners).
RawCorners? fluent2HeldCorners(
  Fluent2ThemeData t,
  RawCorners? corners,
  RawCorner own,
) {
  if (corners == null || corners.isEmpty) return null;
  return Fluent2ThemeData.shapeLimits.clampCorners(
    corners,
    base: RawCorners.all(own),
    look: 'Fluent 2',
  );
}

/// The outline [corners] draw on a part whose own step is [own], each corner
/// at its held step in [t]'s scale, start and end as the part reads; null
/// when [corners] names none.
OutlinedBorder? fluent2CornersOutline(
  Fluent2ThemeData t,
  RawCorners? corners,
  RawCorner own,
) {
  final held = fluent2HeldCorners(t, corners, own);
  return held == null ? null : t.shapeScheme.corners.borderOf(held);
}

/// The radius [step] stands for in [t]'s scale on a part [height] tall: a
/// full corner is half the height.
Radius fluent2StepRadius(Fluent2ThemeData t, RawCorner? step, double height) =>
    switch (step) {
      null || RawCorner.none => Radius.zero,
      RawCorner.full => Radius.circular(height / 2),
      _ => Radius.circular(t.shapeScheme.corners.radius(step)),
    };

/// [held]'s corners as radii on a part [height] tall, those whose flag is
/// false left square: what a joined part (a split button's half, a sheet's
/// top edge) draws.
BorderRadiusDirectional fluent2HeldRadii(
  Fluent2ThemeData t,
  RawCorners held,
  double height, {
  bool topStart = true,
  bool topEnd = true,
  bool bottomStart = true,
  bool bottomEnd = true,
}) => BorderRadiusDirectional.only(
  topStart: topStart
      ? fluent2StepRadius(t, held.topStart, height)
      : Radius.zero,
  topEnd: topEnd ? fluent2StepRadius(t, held.topEnd, height) : Radius.zero,
  bottomStart: bottomStart
      ? fluent2StepRadius(t, held.bottomStart, height)
      : Radius.zero,
  bottomEnd: bottomEnd
      ? fluent2StepRadius(t, held.bottomEnd, height)
      : Radius.zero,
);

/// What Fluent 2's parts read of their corners.
extension Fluent2CornerReading on Fluent2StyleOf {
  /// The outline a part whose own step is [own] draws: a layer's `shape`
  /// as given (it wins); else a layer's `corners`, held to Fluent's steps
  /// over the part's own and drawn in [t]'s scale. A layer that names
  /// corners in other states draws the part's own here as the same kind of
  /// outline, so a change of corners eases. Null when no layer names either
  /// (the part draws its own corner).
  OutlinedBorder? outline(Fluent2ThemeData t, RawCorner own) {
    final drawn = shape ?? fluent2CornersOutline(t, corners, own);
    if (drawn != null) return drawn;
    return layers.any((l) => l?.corners != null)
        ? t.shapeScheme.corners.border(own)
        : null;
  }

  /// The corners a layer names, held over the part's own [own]; null when a
  /// layer's `shape` wins or none names corners.
  RawCorners? heldCorners(Fluent2ThemeData t, RawCorner own) =>
      shape != null ? null : fluent2HeldCorners(t, corners, own);
}
