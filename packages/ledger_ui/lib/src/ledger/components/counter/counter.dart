import 'package:flutter/widgets.dart';

import '../../theme.dart';

/// A number set anew when it changes, as a clerk re-inks a figure: engraved
/// in the serif, and only the characters that changed are rewritten, each
/// fading out where it stands as its successor inks in over it, in
/// [LedgerMotion.slow]; nothing rolls or slides. Characters are aligned from
/// the end, so the units stay put when a new leading digit is written in, and
/// every digit takes the width of the widest one so the figure never shivers.
/// It lands on exactly the value it was given and, with reduced motion on,
/// swaps.
/// It reads as the figure printed ([format] renders it: `12 days`, `1,284`).
/// [style] defaults to the engraved medium figure.
///
/// ```dart
/// LedgerCounter(streak, format: (v) => '\$v days')
/// ```
class LedgerCounter extends StatelessWidget {
  /// A number at [value] that is re-inked when it changes.
  const LedgerCounter(this.value, {this.style, this.format, super.key});

  /// The number shown.
  final int value;

  /// The type it prints in; null is the theme's medium figure.
  final TextStyle? style;

  /// How the value is rendered; plain digits when omitted.
  final String Function(int value)? format;

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    final type = (style ?? t.figureMedium).colored(
      style?.color ?? t.textPrimary,
    );
    final text = format?.call(value) ?? '$value';
    final digit = _widestDigit(type);
    // The place stands the line a Text of the style takes, a whole pixel.
    final line = ((type.fontSize ?? 16) * (type.height ?? 1)).roundToDouble();
    return Semantics(
      label: text,
      excludeSemantics: true,
      // Its places stand in the reading order of the figure, left to right
      // in any page: mirrored, "12 days" would read "syad 21".
      child: Row(
        mainAxisSize: MainAxisSize.min,
        textDirection: TextDirection.ltr,
        textBaseline: TextBaseline.alphabetic,
        children: [
          for (var i = 0; i < text.length; i++)
            _Place(
              // Keyed from the end: a new leading digit does not move the rest.
              key: ValueKey<int>(text.length - i),
              char: text[i],
              style: type,
              width: _isDigit(text[i]) ? digit : null,
              height: line,
              duration: LedgerMotion.of(context, LedgerMotion.slow),
            ),
        ],
      ),
    );
  }

  static bool _isDigit(String c) => c.codeUnitAt(0) ^ 0x30 <= 9;

  /// The widest digit of [style], so a digit's place never changes width.
  static double _widestDigit(TextStyle style) {
    var widest = 0.0;
    for (var d = 0; d < 10; d++) {
      final painter = TextPainter(
        text: TextSpan(text: '$d', style: style),
        textDirection: TextDirection.ltr,
        textScaler: TextScaler.noScaling,
      )..layout();
      if (painter.width > widest) widest = painter.width;
      painter.dispose();
    }
    return widest;
  }
}

/// One character's place: when its character changes, the old one fades out
/// where it stands and the new one inks in over it.
class _Place extends StatelessWidget {
  const _Place({
    required super.key,
    required this.char,
    required this.style,
    required this.width,
    required this.height,
    required this.duration,
  });

  final String char;
  final TextStyle style;
  final double? width;
  final double height;
  final Duration duration;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    height: height,
    child: AnimatedSwitcher(
      duration: duration,
      switchInCurve: LedgerMotion.out,
      switchOutCurve: LedgerMotion.out.flipped,
      layoutBuilder: (current, previous) =>
          Stack(alignment: Alignment.center, children: [...previous, ?current]),
      child: Text(
        char,
        key: ValueKey<String>(char),
        maxLines: 1,
        softWrap: false,
        textScaler: TextScaler.noScaling,
        style: style,
      ),
    ),
  );
}
