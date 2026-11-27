import 'package:flutter/painting.dart';
import 'package:ui_core/ui_core.dart';

/// The corner radius [border] rounds to, for what draws a radius rather than
/// a border (a clip, a shadow, a ring's gap): a rounded or continuous
/// border's top-left radius, a continuous rectangle's at the radius it reads
/// as, a bevel's cut, a stadium's or a circle's half its [height]; null when
/// the border has no single radius.
double? frostedCornerOf(OutlinedBorder border, {double height = 0}) =>
    switch (border) {
      RoundedRectangleBorder(:final borderRadius) ||
      RoundedSuperellipseBorder(:final borderRadius) ||
      BeveledRectangleBorder(
        :final borderRadius,
      ) => borderRadius.resolve(TextDirection.ltr).topLeft.x,
      ContinuousRectangleBorder(:final borderRadius) =>
        borderRadius.resolve(TextDirection.ltr).topLeft.x / 2.3,
      StadiumBorder() || CircleBorder() => height / 2,
      _ => null,
    };

/// The step of Frosted's own scale [border] stands at: a stadium or a
/// circle [RawCorner.full]; a corner of 0 [RawCorner.none]; else the step
/// whose own radius (6, 10, 12, 18, 22) is nearest its corner, the smaller
/// on a tie.
RawCorner frostedStepOf(OutlinedBorder border) {
  if (border is StadiumBorder || border is CircleBorder) return RawCorner.full;
  final r = frostedCornerOf(border) ?? 0;
  if (r <= 0) return RawCorner.none;
  const steps = [
    (RawCorner.extraSmall, 6.0),
    (RawCorner.small, 10.0),
    (RawCorner.medium, 12.0),
    (RawCorner.large, 18.0),
    (RawCorner.extraLarge, 22.0),
  ];
  var best = steps.first;
  for (final s in steps) {
    if ((s.$2 - r).abs() < (best.$2 - r).abs()) best = s;
  }
  return best.$1;
}

/// The corner [border] rounds to, as a [BorderRadius], for a face drawn by
/// radius ([frostedCornerOf]; a stadium or circle at half [height]).
BorderRadius frostedRadiusOf(OutlinedBorder border, {double height = 0}) =>
    BorderRadius.circular(frostedCornerOf(border, height: height) ?? 0);
