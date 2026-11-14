/// How far a control's hand lettering grows with the reader's text size.
library;

import 'package:flutter/widgets.dart';

/// The largest a control's lettering grows: what a 16 px label reaches at
/// 200%. Comic letters its controls at 18 and 20 px, so at 200% they would
/// stand at 40 px and push a row's neighbours out; they grow with the reader's
/// setting until 32 px and stop there, never below their own size.
const double comicLetteringMost = 32;

/// The reader's text scaler, capped so [style]'s lettering stops growing at
/// [comicLetteringMost].
TextScaler comicLetteringScaler(BuildContext context, TextStyle style) {
  final scaler = MediaQuery.textScalerOf(context);
  final size = style.fontSize ?? 14;
  if (size >= comicLetteringMost) return TextScaler.noScaling;
  return scaler.clamp(maxScaleFactor: comicLetteringMost / size);
}

double _contrast(Color a, Color b) {
  final x = a.computeLuminance(), y = b.computeLuminance();
  return (x > y ? x + .05 : y + .05) / (x > y ? y + .05 : x + .05);
}

/// Letters drawn on a face of their own (an avatar's), which keeps its own fill
/// where a filled ground around it rescopes the theme's inks: [wanted] when it
/// reads 4.5:1 on [ground], else whichever of [inks] reads best there.
Color comicInkOn(Color ground, Color wanted, Iterable<Color> inks) {
  if (_contrast(wanted, ground) >= 4.5) return wanted;
  var best = wanted;
  for (final ink in inks) {
    if (_contrast(ink, ground) > _contrast(best, ground)) best = ink;
  }
  return best;
}
