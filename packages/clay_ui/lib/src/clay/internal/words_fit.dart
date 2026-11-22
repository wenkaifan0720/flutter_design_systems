/// Words measured as a part draws them, so a part at a large text size can
/// keep every word whole: it scrolls, or lowers its own text size, rather
/// than break a word across two lines.
library;

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

final _gaps = RegExp(r'\s+');

/// The widest word of [texts] in [style], at [context]'s text size and
/// reading direction; with [whole], the widest whole text (a part that keeps
/// to one line).
double clayWidestWord(
  BuildContext context,
  Iterable<String> texts,
  TextStyle style, {
  bool whole = false,
}) {
  final painter = TextPainter(
    textDirection: Directionality.of(context),
    textScaler: MediaQuery.textScalerOf(context),
    locale: Localizations.maybeLocaleOf(context),
    maxLines: 1,
  );
  final drawn = DefaultTextStyle.of(context).style.merge(style);
  var widest = 0.0;
  for (final text in texts) {
    for (final word in whole ? [text] : text.split(_gaps)) {
      if (word.isEmpty) continue;
      painter
        ..text = TextSpan(text: word, style: drawn)
        ..layout();
      widest = math.max(widest, painter.width);
    }
  }
  painter.dispose();
  return widest;
}

/// [scaler] lowered just enough that a word [widest] wide at [scaler] fits
/// [room]; [scaler] itself where it fits.
TextScaler clayScalerToFit(
  TextScaler scaler, {
  required double fontSize,
  required double widest,
  required double room,
}) {
  if (widest <= room || widest <= 0 || room <= 1) return scaler;
  // A pixel spare: text widths round, and a word a hair too wide breaks.
  final factor = scaler.scale(fontSize) / fontSize * (room - 1) / widest;
  return TextScaler.linear(factor);
}
