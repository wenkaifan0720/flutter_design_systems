/// An inline action set as words: a link.
library;

import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme.dart';
import 'pressable.dart';

/// Words that act: "Forgot password?", "View all", "Terms". The accent's
/// ink with a thin underline a little below the baseline, in the size of
/// the line it sits in ([style] unless stated, else the body). A link that
/// leaves the app ([external]) ends in a small arrow out, mirrored right to
/// left.
///
/// It is a control, not decoration: the pointer turns to a hand over it,
/// the keyboard focuses it (a ring on the `shapes.mark` step around the
/// words), Enter follows it, and a press takes the look's faint wash. It
/// never changes under a hovering pointer. A screen reader hears a link.
/// A null [onPressed] prints the words in the quiet ink with no underline.
///
/// ```dart
/// MinimalLink('Forgot password?', onPressed: reset)
/// ```
class MinimalLink extends StatelessWidget {
  /// A link saying [label].
  const MinimalLink(
    this.label, {
    super.key,
    this.onPressed,
    this.external = false,
    this.style,
    this.focusNode,
    this.autofocus = false,
  });

  /// What it says.
  final String label;

  /// Follows it; null disables it.
  final VoidCallback? onPressed;

  /// The link leaves the app (a web page, the mail app): an arrow out ends
  /// it.
  final bool external;

  /// The words' style before the link's colour and underline; null takes
  /// the theme's body.
  final TextStyle? style;

  /// Its focus node, for a caller that moves focus to it; null keeps one
  /// of its own.
  final FocusNode? focusNode;

  /// Whether it takes keyboard focus when it first appears.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    final live = onPressed != null;
    final ink = live ? t.primaryInk : t.mutedForeground;
    final base = (style ?? t.body).copyWith(
      color: ink,
      decoration: live ? TextDecoration.underline : TextDecoration.none,
      decorationColor: ink.withValues(alpha: 0.5),
      decorationThickness: 1,
    );
    final words = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(child: Text(label, style: base)),
        if (external) ...[
          const MinimalGap(MinimalSpacing.s2),
          // Out and onward: it points up and to the line's end, so right
          // to left it mirrors.
          MinimalIcon(
            LucideIcons.arrowUpRightDir,
            size: (base.fontSize ?? 14) * 0.95,
            color: ink,
          ),
        ],
      ],
    );
    // The link role rides the pressable's own node, the one that holds the
    // words, so a screen reader says "Terms, link".
    return MinimalPressable(
      focusNode: focusNode,
      autofocus: autofocus,
      // No action: plain words, not a dimmed control.
      onPressed: onPressed,
      link: true,
      shape: t.shapes.mark,
      // A hair of air so the ring and the wash clear the words, reaching
      // past the words' box: the words themselves start where the line
      // does, flush with the text above and beside them.
      outset: const EdgeInsets.symmetric(horizontal: MinimalSpacing.s2),
      child: words,
    );
  }
}
