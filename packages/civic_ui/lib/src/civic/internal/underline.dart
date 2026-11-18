import 'package:flutter/widgets.dart';

/// Civic's underlined words: [child] (words that take the ambient text
/// style) in [style], merged over it, its underline clear of the letters
/// where the words read right to left. Arabic's letters join along the line
/// an underline takes and their tails fall through it, so there the words
/// stand a fifth of their size over the line (Flutter draws no
/// text-underline-offset): the underline is drawn under words of no colour,
/// and the words themselves, the same words laid out the same way, are
/// drawn over it, lifted. A shadow would lift the underline with them.
/// Elsewhere, and with no underline, [child] in [style]; [steady] words
/// with no underline stand lifted right to left too, so words that gain and
/// lose their underline (a tab as it is chosen) never move.
///
/// Plumbing; pages never place one.
class CivicUnderlined extends StatelessWidget {
  /// [child] in [style].
  const CivicUnderlined({
    super.key,
    required this.style,
    required this.child,
    this.steady = false,
  });

  /// The words' style, its underline among its decorations.
  final TextStyle style;

  /// The words.
  final Widget child;

  /// Whether the words stand lifted right to left with no underline too.
  final bool steady;

  @override
  Widget build(BuildContext context) {
    final words = style.color;
    final line = style.decoration;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final size = MediaQuery.textScalerOf(context).scale(
      style.fontSize ?? DefaultTextStyle.of(context).style.fontSize ?? 19,
    );
    if (!rtl ||
        words == null ||
        line == null ||
        !line.contains(TextDecoration.underline)) {
      final plain = DefaultTextStyle.merge(style: style, child: child);
      // Steady words stand where they would over an underline.
      return rtl && steady
          ? Transform.translate(offset: Offset(0, -0.2 * size), child: plain)
          : plain;
    }
    // Both layers take the constraints a lone text would, so they wrap
    // alike; only the words' layer moves, and only as it paints.
    return Stack(
      fit: StackFit.passthrough,
      children: [
        DefaultTextStyle.merge(
          style: style.copyWith(
            color: words.withValues(alpha: 0),
            decorationColor: style.decorationColor ?? words,
          ),
          child: child,
        ),
        ExcludeSemantics(
          child: Transform.translate(
            offset: Offset(0, -0.2 * size),
            child: DefaultTextStyle.merge(
              style: style.copyWith(decoration: TextDecoration.none),
              child: child,
            ),
          ),
        ),
      ],
    );
  }
}
