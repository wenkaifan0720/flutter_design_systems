// A heading keeps its words whole at the reader's text size: where its longest word would not fit the width, the
// size steps down only as far as that word needs, never under the size as set.
import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../layout.dart' show neumorphicWidestWord;

/// The text scale for [text] in [style] across [width]: the reader's own, or less where its longest word would break in
/// two at it (at twice the text a sheet's "Neumorphism gallery" would break into "Neumorphis" and "m"). Never under no
/// scaling, so a word longer than the width at the size as set still breaks, as it would without this.
TextScaler neumorphicWholeWordScaler(
  BuildContext context,
  String text,
  TextStyle style,
  double width,
) {
  final scaler = MediaQuery.textScalerOf(context);
  if (!width.isFinite || width <= 0) return scaler;
  final widest = neumorphicWidestWord(text, style, textScaler: scaler);
  if (widest <= width) return scaler;
  final size = style.fontSize ?? 14;
  final reader = scaler.scale(size) / size;
  // A word's width grows with the scale; a pixel under the width keeps a rounded glyph advance from breaking it.
  return TextScaler.linear(math.max(1, reader * (width - 1) / widest));
}
