import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../theme.dart';

/// The ink act's word ([style], coloured: a button's label, a chosen day's
/// figure) as it sets on its pill or disc. By night, where the word is dark
/// on a light pill, one cut heavier (700 for 600): light words on the night
/// glass beside it (Cancel's) spread into the dark and read a cut heavier
/// than a dark word on light, so the act's word read lighter than its
/// neighbour's. An optical match, not more emphasis. Otherwise [style].
TextStyle frostedInkWord(FrostedThemeData t, TextStyle style) {
  final ink = style.color;
  if (!t.isDark || ink == null || ink.computeLuminance() >= .2) return style;
  final weight = math.min(
    900,
    (style.fontWeight ?? FontWeight.w400).value + 100,
  );
  return style.copyWith(
    fontWeight: FontWeight(weight),
    fontVariations: [
      for (final v in style.fontVariations ?? const <FontVariation>[])
        if (v.axis != 'wght') v,
      FontVariation.weight(weight.toDouble()),
    ],
  );
}

/// The ink that reads on an opaque [fill]: [preferred] when it reads 4.5:1
/// there, else white or the theme's dark ink, whichever reads better (a
/// count's words on the unread dot, a tone's glyph on its disc). Plumbing of
/// the components.
Color frostedInkOn(FrostedThemeData t, Color fill, {Color? preferred}) {
  if (preferred != null && FrostedThemeData.contrast(preferred, fill) >= 4.5) {
    return preferred;
  }
  const white = Color(0xFFFFFFFF);
  final dark = t.isDark ? t.colorScheme.background : t.colorScheme.textPrimary;
  return FrostedThemeData.contrast(white, fill) >=
          FrostedThemeData.contrast(dark, fill)
      ? white
      : dark;
}
