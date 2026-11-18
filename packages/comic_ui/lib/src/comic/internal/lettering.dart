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

/// Whether [text] holds a letter of a right-to-left script (Hebrew, Arabic and their presentation forms). The
/// lettering face has none of their letters, and its slanted punctuation, drawn to follow a capital, sat over the
/// script's last letter: words in such a script are set in the text face.
bool comicRightToLeftScript(String text) => _rightToLeft.hasMatch(text);

/// Keeps the visual weight of Bangers when a right-to-left word uses a fallback
/// face. Connected letters use the font's own spacing.
TextStyle comicDisplayFor(String words, TextStyle style) =>
    comicRightToLeftScript(words)
    ? style.copyWith(fontWeight: FontWeight.w700, letterSpacing: 0)
    : style;

final RegExp _rightToLeft = RegExp('[\u0590-\u08FF\uFB1D-\uFDFF\uFE70-\uFEFF]');

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

/// Supplies the solid colour painted behind each line of display lettering.
class ComicPrintGround extends InheritedWidget {
  /// Gives [child] a solid background for its lettering.
  const ComicPrintGround(this.color, {super.key, required super.child});

  /// The colour behind each line of type.
  final Color color;

  /// The nearest solid lettering background.
  static Color? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ComicPrintGround>()?.color;

  @override
  bool updateShouldNotify(ComicPrintGround oldWidget) =>
      color != oldWidget.color;
}
