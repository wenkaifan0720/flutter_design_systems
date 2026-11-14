// The one line an error takes under its control: the warning mark and the words, in the caption and the ink.
import 'package:flutter/widgets.dart';

import '../glyphs.dart';
import '../theme.dart';

/// [child], usually a [Text], as an error message: every field, select and picker writes its failure with this.
class NeumorphicErrorLine extends StatelessWidget {
  /// An error line reading [child]; [live] announces it when it appears.
  const NeumorphicErrorLine({super.key, required this.child, this.live = true});

  /// The message.
  final Widget child;

  /// Whether a screen reader announces the line when it appears.
  final bool live;

  @override
  Widget build(BuildContext context) {
    final t = NeumorphicTheme.of(context);
    return Semantics(
      liveRegion: live,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExcludeSemantics(
            child: Icon(
              NeumorphicGlyphs.triangleAlert,
              color: t.colors.ink,
              size: 18,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: DefaultTextStyle.merge(
              style: t.textTheme.caption.copyWith(color: t.colors.ink),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}
