// A control's one-line label drawn with its capitals on its box's middle (ui_core's DesignCapCenter), at the cap height
// of the face it is set in. Every face wraps its label once, here, never its icon or its row; page code never does.
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../theme.dart';

/// Draws [child], a control's one-line label or a one-line text entry, with its capitals on its box's middle. The cap height is the display
/// face's when [display] says so, else read from the child's style when it is a [Text] set in the display face, else
/// the text face's.
class CapLabel extends StatelessWidget {
  /// Creates a [CapLabel].
  const CapLabel({super.key, this.display, required this.child});

  /// Whether the label is set in the display face; null reads it from a [Text] child's style.
  final bool? display;

  /// The label.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final face = ComicTheme.of(context).type.typeface;
    final family = switch (child) {
      final Text text => text.style?.fontFamily,
      _ => null,
    };
    final lettered =
        display ??
        (family != null &&
            (family == face.display || family.endsWith('/${face.display}')));
    return DesignCapCenter(
      capHeightFactor: lettered ? face.displayCapHeight : face.textCapHeight,
      child: child,
    );
  }
}
