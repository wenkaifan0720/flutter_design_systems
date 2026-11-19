/// How far a control's hand lettering grows with the reader's text size.
library;

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../fonts.dart' show comicFontFamily;
import 'lettering_reach.dart';

/// The largest a control's lettering grows: what a 16 px label reaches at
/// 200%. Comic letters its controls at 18 and 20 px, so at 200% they would
/// stand at 40 px and push a row's neighbours out; they grow with the reader's
/// setting until 32 px and stop there, never below their own size.
const double comicLetteringMost = 32;

/// The most a calendar's month name, weekday initials and day numbers grow with the reader's text size: twice, as
/// Material's calendar on a phone. Larger, seven initials fill a phone's row of day cells and touch, seven days'
/// numbers outgrow the phone (the date picker's grid scrolled sideways) or crowd their cells' rules, and the month's
/// name outgrows the space between its arrows and breaks mid-word.
const double comicCalendarScaleMost = 2;

/// The most a chart's scale words grow with the reader's text size: 1.3 times, as Material's slider value label. They
/// stand side by side under the bar; larger, one leaves the other too narrow for its words.
const double comicScaleWordsMost = 1.3;

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
/// face. Connected letters use the font's own spacing. Lettering whose marks
/// reach past a plain capital gets the leading they need ([comicMarkedLeading]).
TextStyle comicDisplayFor(String words, TextStyle style) =>
    comicRightToLeftScript(words)
    ? style.copyWith(fontWeight: FontWeight.w700, letterSpacing: 0)
    : comicMarkedLeading(words, style);

/// The least line pitch, as a multiple of the size, at which lines of [words] in the look's lettering clear each
/// other: the farthest any of its glyphs reaches above the line, over the farthest any reaches below it, and a hair
/// between. Null when no letter of [words] reaches past a plain capital, as in English, whose lettering keeps its tight
/// leading. Bangers' marks stand above its capitals (an acute 1.12 times the size, a stacked Vietnamese tone 1.39), so
/// at the lettering's 0.95 they cut into the line above. As Material gives a tall script more room, a language whose
/// marks reach higher gets more, the whole paragraph alike so its lines stay evenly spaced.
double? comicMarkedPitch(String words) {
  var marked = false;
  var top = comicPlainReach[0], bottom = comicPlainReach[1];
  // The parts set the lettering in capitals; a lowercase letter's marks are measured too.
  for (final text in [words, words.toUpperCase()]) {
    for (final rune in text.runes) {
      final letter = _letterReach[rune];
      final reach = letter ?? _signReach[rune];
      if (reach == null) continue;
      marked = marked || letter != null;
      top = math.max(top, reach.$1);
      bottom = math.max(bottom, reach.$2);
    }
  }
  return marked ? (top + bottom) / 100 + _hair : null;
}

/// [style] with the leading [words]' marks need ([comicMarkedPitch]) when it is set in the look's own lettering face
/// and its own leading is tighter; else [style].
TextStyle comicMarkedLeading(String words, TextStyle style) {
  if (style.fontFamily != comicFontFamily('Bangers')) return style;
  final pitch = comicMarkedPitch(words);
  final size = style.fontSize ?? 14;
  if (pitch == null || (style.height ?? 0) >= pitch) return style;
  return style.copyWith(height: (size * pitch).ceilToDouble() / size);
}

/// The room between one line's lowest mark and the next line's highest, as a multiple of the size.
const double _hair = .02;

final Map<int, (int, int)> _letterReach = _byRune(comicMarkedLetterReach);
final Map<int, (int, int)> _signReach = _byRune(comicReachingSignReach);

Map<int, (int, int)> _byRune(List<(int, int, String)> table) => {
  for (final (top, bottom, glyphs) in table)
    for (final rune in glyphs.runes) rune: (top, bottom),
};

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
