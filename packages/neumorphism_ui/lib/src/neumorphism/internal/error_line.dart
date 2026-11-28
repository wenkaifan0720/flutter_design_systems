// The one line an error takes under its control: the look's error mark on its warmed bead, and the words in the caption
// and the ink.
import 'package:flutter/widgets.dart';

import '../theme.dart';
import 'error_mark.dart';

/// [child], usually a [Text], as an error message: every field, select and picker writes its failure with this.
class NeumorphicErrorLine extends StatelessWidget {
  /// An error line reading [child]; [live] announces it when it appears.
  const NeumorphicErrorLine({
    super.key,
    required this.child,
    this.live = true,
    this.mark = true,
  });

  /// The message.
  final Widget child;

  /// Whether a screen reader announces the line when it appears.
  final bool live;

  /// Whether the line carries the error mark: false under a field that already carries it at its end, so the mark
  /// shows once.
  final bool mark;

  @override
  Widget build(BuildContext context) {
    final t = NeumorphicTheme.of(context);
    return Semantics(
      liveRegion: live,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // The error mark in the danger ink and the words in it: the line reads as a failure, not as a note, and
          // never by colour alone.
          if (mark) ...[
            const NeumorphicErrorMark(size: 20, glyphSize: 12),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: DefaultTextStyle.merge(
              style: t.textTheme.caption.copyWith(
                color: t.colors.danger,
                fontWeight: FontWeight.w600,
              ),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}
