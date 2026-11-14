/// Secondary actions and chips on the same control scale as the primary action.
library;

import 'package:flutter/widgets.dart';

import 'press.dart';
import 'theme.dart';
import 'component_themes.dart';
import 'styled.dart';

/// A textual navigation action, underlined and announced as a link.
///
/// ```dart
/// ComicLink('Read the issue', onPressed: open)
/// ```
class ComicLink extends StatelessWidget {
  /// Creates a link.
  const ComicLink(
    this.label, {
    super.key,
    this.onPressed,
    this.focusNode,
    this.style,
    this.inSentence = true,
    this.autofocus = false,
  });

  /// Per-state appearance above the quiet-button theme.
  final ComicStyle? style;

  /// Destination name.
  final String label;

  /// Caller-owned focus and sentence underline.
  final FocusNode? focusNode;

  /// Underlines the link when it appears within prose.
  final bool inSentence;

  /// Navigation callback; null is disabled.
  final VoidCallback? onPressed;

  /// Whether the part asks for the focus when it first appears.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final t = ComicTheme.of(context);
    final layers = [style, t.textButtonTheme];
    final base = ComicStyleOf(layers, const {});
    // A link is words: given a whole column, they start on its edge, as every other line in it does, never centred in
    // their least target (11-12).
    return Align(
      alignment: AlignmentDirectional.centerStart,
      widthFactor: 1,
      heightFactor: 1,
      child: _link(t, layers, base),
    );
  }

  Widget _link(ComicThemeData t, List<ComicStyle?> layers, ComicStyleOf base) {
    return ComicPressable(
      autofocus: autofocus,
      label: label,
      link: true,
      button: false,
      onPressed: onPressed,
      focusNode: focusNode,
      target: true,
      outline: base.shapes(t.shapes.small),
      overlay: base.overlay,
      builder: (context, states) {
        final look = ComicStyleOf(layers, states);
        return AnimatedComicShape(
          shape: look.shape ?? t.shapes.small,
          builder: (context, shape) => Container(
            constraints: BoxConstraints(
              minWidth: look.minimumSize?.width ?? 0,
              minHeight: look.minimumSize?.height ?? 0,
            ),
            padding:
                look.padding(Directionality.of(context)) ??
                t.density.padding(const EdgeInsets.symmetric(vertical: 12)),
            decoration: ShapeDecoration(
              color: look.fill,
              shape: (shape ?? const RoundedRectangleBorder()).copyWith(
                side: look.side ?? BorderSide.none,
              ),
            ),
            child: Text(
              label,
              style: (look.textStyle ?? t.type.body).copyWith(
                color:
                    look.foreground ??
                    look.textStyle?.color ??
                    t.colors.shadeText,
                decoration: inSentence
                    ? TextDecoration.underline
                    : TextDecoration.none,
              ),
            ),
          ),
        );
      },
    );
  }
}
