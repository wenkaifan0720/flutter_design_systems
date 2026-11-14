import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../../internal/hit_slop.dart';
import '../../theme.dart';
import '../pressable/pressable.dart';

/// How a [Fluent2Link] reads: Fluent's default brand link, or `subtle` in
/// the second ink.
enum Fluent2LinkAppearance {
  /// A link in the brand colour.
  brand,

  /// A subtle link in the neutral ink.
  subtle,
}

/// Fluent 2's Link: words in the link ink (`brandForegroundLink`, or the
/// second ink's link aliases when [appearance] is subtle), underlined
/// under the pointer and while pressed, always underlined when [inline]
/// (a link inside a sentence, which must not lean on colour alone); the
/// keyboard's focus rings it. Null [onTap] draws it disabled in the
/// disabled ink. Read as a link named by its words; Enter follows it.
///
/// ```dart
/// Fluent2Link('Open the brief', onPressed: openBrief)
/// ```
class Fluent2Link extends StatelessWidget {
  /// A link reading [text].
  const Fluent2Link(
    this.text, {
    required this.onPressed,
    this.appearance = Fluent2LinkAppearance.brand,
    this.inline = false,
    this.style,
    this.maxLines,
    this.semanticLabel,
    this.focusNode,
    this.autofocus = false,
    super.key,
  });

  /// The link's words.
  final String text;

  /// Called when the link is pressed; null draws it disabled.
  final VoidCallback? onPressed;

  /// Fluent's `appearance`: brand or subtle.
  final Fluent2LinkAppearance appearance;

  /// A link inside running text: underlined at rest too.
  final bool inline;

  /// The type the words take; null is body1 (an inline link passes its
  /// sentence's).
  final TextStyle? style;

  /// The most lines its words take; null takes as many as they need.
  final int? maxLines;

  /// What a screen reader says in place of [text].
  final String? semanticLabel;

  /// The control's focus node; null makes and disposes its own.
  final FocusNode? focusNode;

  /// Whether the control takes focus when it first builds.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    final c = t.colors;
    final subtle = appearance == Fluent2LinkAppearance.subtle;
    final live = onPressed != null;
    final tap = onPressed;
    // Inside a sentence (a WidgetSpan of a paragraph) the link is a run of
    // its words: the sentence scales it with the reader's text size, so it
    // takes no scale of its own, and it stands no taller than the line (a
    // 48 touch target there would open a gap in the paragraph, as Flutter's
    // own inline links stand no taller either).
    final inSentence =
        context.findAncestorRenderObjectOfType<RenderParagraph>() != null;
    final link = Fluent2Pressable(
      focusNode: focusNode,
      autofocus: autofocus,
      onPressed: tap,
      padded: !inSentence,
      role: Fluent2PressRole.link,
      radius: Fluent2Radius.small,
      label: semanticLabel ?? text,
      builder: (context, states) {
        final press = states.press;
        final ink = !live
            ? c.neutralForegroundDisabled
            : subtle
            ? press.pick(
                c.neutralForeground2Link,
                c.neutralForeground2LinkHover,
                c.neutralForeground2LinkPressed,
              )
            : press.pick(
                c.brandForegroundLink,
                c.brandForegroundLinkHover,
                c.brandForegroundLinkPressed,
              );
        final under =
            live &&
            (inline ||
                press == Fluent2Press.hover ||
                press == Fluent2Press.pressed);
        return Text(
          text,
          textScaler: inSentence ? TextScaler.noScaling : null,
          maxLines: maxLines,
          overflow: maxLines == null ? null : TextOverflow.ellipsis,
          style: (style ?? t.body1).copyWith(
            color: ink,
            decoration: under ? TextDecoration.underline : null,
            decorationColor: ink,
            decorationThickness: 1,
          ),
        );
      },
    );
    // A disabled link takes no taps, so it lends no slop over a neighbour.
    return inline || !live ? link : Fluent2HitSlop(child: link);
  }
}
