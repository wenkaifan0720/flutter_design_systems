import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../theme.dart';

/// A heading's words at the reader's text size, at most [most] times their
/// size, and never so large that its longest word is wider than the room:
/// it wraps between words, never inside one.
class CivicFitWords extends StatelessWidget {
  /// [text] in [style].
  const CivicFitWords(
    this.text, {
    super.key,
    required this.style,
    this.textAlign,
    this.most = CivicLayout.headingScaleMost,
  });

  /// The words.
  final String text;

  /// Their style.
  final TextStyle style;

  /// Their alignment.
  final TextAlign? textAlign;

  /// The most the reader's text size grows them by.
  final double most;

  /// The text scaler [text] in [style] takes in [maxWidth]: the reader's,
  /// at most [most] times, and no larger than fits its longest word.
  static TextScaler scalerFor(
    BuildContext context,
    String text,
    TextStyle style,
    double maxWidth, {
    double most = CivicLayout.headingScaleMost,
  }) {
    final asked = MediaQuery.textScalerOf(context).clamp(maxScaleFactor: most);
    final size = style.fontSize ?? 16;
    final scale = asked.scale(size) / size;
    if (!maxWidth.isFinite || scale <= 1) return asked;
    var longest = 0.0;
    for (final word in text.split(RegExp(r'\s+'))) {
      if (word.isEmpty) continue;
      final painter = TextPainter(
        text: TextSpan(text: word, style: style),
        textDirection: Directionality.of(context),
        maxLines: 1,
      )..layout();
      longest = math.max(longest, painter.width);
      painter.dispose();
    }
    if (longest <= 0) return asked;
    final fits = maxWidth / longest;
    return fits < scale ? TextScaler.linear(math.max(1, fits)) : asked;
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => Text(
      text,
      style: style,
      textAlign: textAlign,
      textScaler: scalerFor(
        context,
        text,
        style,
        constraints.maxWidth,
        most: most,
      ),
    ),
  );
}
