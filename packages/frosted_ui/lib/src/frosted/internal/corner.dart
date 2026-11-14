import 'package:flutter/painting.dart';

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

/// The corner [border] rounds to, as a [BorderRadius], for a face drawn by
/// radius ([frostedCornerOf]; a stadium or circle at half [height]).
BorderRadius frostedRadiusOf(OutlinedBorder border, {double height = 0}) =>
    BorderRadius.circular(frostedCornerOf(border, height: height) ?? 0);
