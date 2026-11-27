import 'package:flutter/widgets.dart';

import '../theme.dart';

/// The words of an action that destroys something, the danger's glyph,
/// `✗`, a cell before them, in their ink. In a palette of one ink the
/// danger ink is the words' ink, so the glyph is what tells `delete` from
/// `keep`; in the rest it says it again, as nothing is said by colour
/// alone. A screen reader hears the words alone. [marked] false: [child].
class TermDangerMarked extends StatelessWidget {
  /// [child], the words, marked when [marked].
  const TermDangerMarked({
    super.key,
    required this.marked,
    required this.style,
    required this.child,
  });

  /// Whether the action destroys something.
  final bool marked;

  /// The words' style, the glyph's too.
  final TextStyle style;

  /// The words.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!marked) return child;
    return Row(
      mainAxisSize: MainAxisSize.min,
      // On the words' first line, when they wrap.
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ExcludeSemantics(
          child: Text('✗', maxLines: 1, softWrap: false, style: style),
        ),
        SizedBox(width: context.termGrid.cellWidth),
        Flexible(child: child),
      ],
    );
  }
}
