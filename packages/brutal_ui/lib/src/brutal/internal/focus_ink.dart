import 'package:flutter/widgets.dart';

import '../theme.dart';

/// Retains the signal hue and adjusts its lightness when the surface needs
/// more contrast. A focused edge replaces pixels of [background].
Color brutalFocusInk(BrutalColors colors, Color background) {
  if (brutalContrast(colors.signal, background) >= 3) return colors.signal;
  final ink = BrutalColors.wordsOn(background);
  for (var step = 1; step < 10; step++) {
    final color = Color.lerp(colors.signal, ink, step / 10)!;
    if (brutalContrast(color, background) >= 3) return color;
  }
  return ink;
}
