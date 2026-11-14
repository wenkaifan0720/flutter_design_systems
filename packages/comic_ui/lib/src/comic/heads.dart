// Heads and small words: lettered titles, a section's head on the gutter, a panel's head, labels, tags and the small print.
import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'glyphs.dart';

import 'frames.dart';
import 'internal/geometry.dart';
import 'internal/reach.dart';
import 'layout.dart';
import 'theme.dart';
import 'localizations.dart';
import 'press.dart';
import 'internal/cap_label.dart';

/// Words in the lettering, in caps, plain: a panel's title. Pass any `t.type` style from the lettering set; `panel` if left out.
///
/// ```dart
/// ComicLetters('All six of us!')
/// ```
class ComicLetters extends StatelessWidget {
  /// Creates a [ComicLetters].
  const ComicLetters(
    this.words, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
  });

  /// The words displayed in this composition.
  final String words;

  /// The visual treatment supplied by the caller.
  final TextStyle? style;

  /// How text aligns within its line box.
  final TextAlign? textAlign;

  /// The greatest number of text lines to display.
  final int? maxLines;
  @override
  Widget build(BuildContext context) => Text(
    words.toUpperCase(),
    style: style ?? ComicTheme.of(context).type.panel,
    textAlign: textAlign,
    maxLines: maxLines,
    overflow: maxLines == null ? null : TextOverflow.ellipsis,
  );
}

/// A section's head, on the gutter between tiers: big lettering, a small word after it on one baseline. If both won't fit on
/// a line the small word goes under.
///
/// ```dart
/// ComicSectionHeader('Coming up', note: 'Next three weeks')
/// ```
class ComicSectionHeader extends StatelessWidget {
  /// Creates a [ComicSectionHeader].
  const ComicSectionHeader(this.title, {super.key, this.note});

  /// The primary heading.
  final String title;

  /// Secondary explanatory text.
  final String? note;
  @override
  Widget build(BuildContext context) {
    final t = ComicTheme.of(context);
    final head = Text(title.toUpperCase(), style: t.type.section);
    final small = note == null
        ? null
        : Text(
            note!.toUpperCase(),
            style: t.type.label.copyWith(color: t.colors.textSecondary),
          );
    return Padding(
      padding: EdgeInsets.fromLTRB(2, t.desk ? 22 : 16, 2, 0),
      child: small == null
          ? head
          : LayoutBuilder(
              builder: (context, box) {
                double wide(Text x) {
                  final tp = TextPainter(
                    text: TextSpan(text: x.data, style: x.style),
                    textDirection: Directionality.of(context),
                    maxLines: 1,
                    textScaler: MediaQuery.textScalerOf(context),
                  )..layout();
                  final w = tp.width;
                  tp.dispose();
                  return w;
                }

                final fits =
                    !box.hasBoundedWidth ||
                    wide(head) + 12 + wide(small) <= box.maxWidth;
                return fits
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          head,
                          const SizedBox(width: 12),
                          Flexible(child: small),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [head, const SizedBox(height: 4), small],
                      );
              },
            ),
    );
  }
}

/// A panel's head: its lettered title, a quiet line under it, a way to more at its end.
///
/// ```dart
/// ComicPanelHead('Who owes who', sub: 'Since the last settle-up', more: 'See all', onMore: () {})
/// ```
class ComicPanelHead extends StatelessWidget {
  /// Creates a [ComicPanelHead].
  const ComicPanelHead(
    this.title, {
    super.key,
    this.sub,
    this.more,
    this.onMore,
    this.trailing,
    this.style,
    this.gapBelow = 12,
  });

  /// The primary heading.
  final String title;

  /// [sub]: the secondary line under the main heading. [more]: the label for the additional-content action.
  final String? sub, more;

  /// Opens the additional content.
  final VoidCallback? onMore;

  /// In place of the way to more.
  final Widget? trailing;

  /// The visual treatment supplied by the caller.
  final TextStyle? style;

  /// Space after the heading in logical pixels.
  final double gapBelow;
  @override
  Widget build(BuildContext context) {
    final t = ComicTheme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: gapBelow),
      // The title keeps most of the row: a long note beside it wraps, it doesn't crush it.
      child: ComicFitRow(
        fill: 0,
        fillShare: .58,
        gap: 10,
        align: ComicFitAlign.bottom,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              ComicLetters(title, style: style),
              if (sub != null) ...[
                const SizedBox(height: 4),
                Text(sub!, style: t.type.small),
              ],
            ],
          ),
          if (trailing != null)
            trailing!
          else if (more != null)
            ComicMoreLink(more!, onPressed: onMore),
        ],
      ),
    );
  }
}

/// A score out of stars, drawn: the font has none. Lit on the lamp, the rest empty.
///
/// ```dart
/// ComicStars(4)
/// ```
class ComicStars extends StatelessWidget {
  /// Creates a [ComicStars].
  const ComicStars(
    this.count, {
    super.key,
    this.of = 5,
    this.size = 13,
    this.onPaper = false,
    this.label,
  });

  /// Overrides the localized rating label.
  final String? label;

  /// [count]: the count printed in the main figure. [of]: the total used to normalize the displayed value.
  final int count, of;

  /// The visual size in logical pixels.
  final double size;

  /// It stands on a balloon, which is paper by night as well: its outline stays dark there.
  final bool onPaper;
  @override
  Widget build(BuildContext context) {
    final c = ComicTheme.of(context).colors;
    return Semantics(
      label: label ?? ComicLocalizations.of(context).rating(count, of),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < of; i++)
            comicOwnSize(
              // A sixth of a star between neighbours: at 1 px the arm tips met and the row read as one strip (r4).
              width: size + math.max(1, size / 6),
              height: size,
              child: CustomPaint(
                painter: _StarPainter(
                  i < count ? c.caption : (onPaper ? c.paper : c.card),
                  onPaper ? c.onPaper : c.text,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StarPainter extends CustomPainter {
  _StarPainter(this.fill, this.line);
  final Color fill, line;
  @override
  void paint(Canvas canvas, Size s) {
    final r = s.height / 2 - .6;
    final star = polyPath([
      for (var i = 0; i < 10; i++)
        polar(
          s.width / 2,
          s.height / 2 + .4,
          i.isEven ? r : r * .48,
          90.0 + i * 36,
        ),
    ]);
    canvas.drawPath(star, fillPaint(fill));
    canvas.drawPath(star, strokePaint(line, 1.1));
  }

  @override
  bool shouldRepaint(_StarPainter o) => o.fill != fill || o.line != line;
}

/// A way to more: a word and a arrow in the group's colour. A small tap target of its own: 44 tall.
///
/// ```dart
/// ComicMoreLink('See all', onPressed: () {})
/// ```
class ComicMoreLink extends StatelessWidget {
  /// Creates a [ComicMoreLink].
  const ComicMoreLink(
    this.label, {
    super.key,
    this.onPressed,
    this.focusNode,
    this.autofocus = false,
  });

  /// The visible or spoken name of the component.
  final String label;

  /// Called when activated; null disables the action.
  final VoidCallback? onPressed;

  /// The caller's focus node, if any; the part makes its own when null.
  final FocusNode? focusNode;

  /// Whether the part asks for the focus when it first appears.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final t = ComicTheme.of(context);
    return ComicPressable(
      focusNode: focusNode,
      autofocus: autofocus,
      onPressed: onPressed,
      label: label,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: t.type.text(
                14,
                1.3,
                weight: FontWeight.w700,
                color: t.colors.shadeText,
              ),
            ),
          ),
          const SizedBox(width: 2),
          Icon(
            Directionality.of(context) == TextDirection.rtl
                ? ComicGlyphs.chevronLeft
                : ComicGlyphs.chevronRight,
            size: 16,
            color: t.colors.shadeText,
          ),
        ],
      ),
    );
  }
}

/// A small label in caps: a form field's name, a column's name.
///
/// ```dart
/// ComicLabel('How many')
/// ```
class ComicLabel extends StatelessWidget {
  /// Creates a [ComicLabel].
  const ComicLabel(this.words, {super.key, this.quiet = false});

  /// The words displayed in this composition.
  final String words;

  /// Uses the quieter ink treatment.
  final bool quiet;
  @override
  Widget build(BuildContext context) {
    final t = ComicTheme.of(context);
    return Text(
      words.toUpperCase(),
      style: t.type.label.copyWith(
        color: quiet ? t.colors.textSecondary : t.colors.text,
      ),
    );
  }
}

/// A small square tag: a status, a kind, a count of what's left. It hugs its word. Leave [tone] off for a plain one.
///
/// ```dart
/// ComicTag('Booked', tone: ComicSpeaker.narrator, icon: ComicGlyphs.check)
/// ```
class ComicTag extends StatelessWidget {
  /// Creates a [ComicTag].
  const ComicTag(
    this.word, {
    super.key,
    this.tone,
    this.icon,
    this.iconEnd = false,
  });

  /// The word printed by this label.
  final String word;

  /// The semantic or surface tone of this component.
  final ComicSpeaker? tone;

  /// The optional glyph beside the words.
  final IconData? icon;

  /// The icon after the word, for an arrow that says where a press goes.
  final bool iconEnd;
  @override
  Widget build(BuildContext context) {
    final t = ComicTheme.of(context);
    final c = t.colors;
    final plain = c.dark ? c.inset : c.card;
    final (fill, letters) = tone == null
        ? (plain, c.text)
        : comicToneInks(tone!, c);
    return Align(
      alignment: AlignmentDirectional.centerStart,
      widthFactor: 1,
      heightFactor: 1,
      child: Container(
        // The words keep 4 px inside the rim, past a capsule's curve.
        constraints: const BoxConstraints(minHeight: 30),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: ShapeDecoration(
          color: fill,
          shape: t.shapes.capsule.copyWith(
            side: BorderSide(color: c.nightLine, width: t.rim(2)),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null && !iconEnd) ...[
              Icon(icon, size: 14, color: letters),
              const SizedBox(width: 5),
            ],
            Flexible(
              child: CapLabel(
                child: Text(
                  word.toUpperCase(),
                  style: t.type.text(
                    12,
                    1,
                    weight: FontWeight.w800,
                    color: letters,
                    tracking: .05,
                  ),
                ),
              ),
            ),
            if (icon != null && iconEnd) ...[
              const SizedBox(width: 5),
              Icon(icon, size: 14, color: letters),
            ],
          ],
        ),
      ),
    );
  }
}

/// The small print a comic carries at its foot: who made it, and what this page is. Put it last on a page that has a colophon
/// to give; it isn't automatic. A bold first word if you give [lead].
///
/// ```dart
/// ComicIndicia('Published on every first Friday. No refunds on the cake.', lead: 'Volume 1, number 27.')
/// ```
class ComicIndicia extends StatelessWidget {
  /// Creates a [ComicIndicia].
  const ComicIndicia(this.words, {super.key, this.lead});

  /// The words displayed in this composition.
  final String words;

  /// Whether this entry receives the leading emphasis.
  final String? lead;
  @override
  Widget build(BuildContext context) {
    final t = ComicTheme.of(context);
    final style = t.type.text(
      12,
      1.45,
      weight: FontWeight.w600,
      color: t.colors.textSecondary,
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 6, 2, 12),
      child: Text.rich(
        TextSpan(
          style: style,
          children: [
            if (lead != null)
              TextSpan(
                text: '$lead ',
                style: style.copyWith(
                  fontWeight: FontWeight.w800,
                  color: t.colors.text,
                ),
              ),
            TextSpan(text: words),
          ],
        ),
      ),
    );
  }
}

/// A score the reader gives: a row of stars to press, lit up to the one chosen. Pressing the chosen star again clears
/// it when [clearable]. Each star is its own 44 target with a round mark of its own size; [ComicStars] shows a score
/// that isn't asked for.
///
/// ```dart
/// ComicRating(label: 'Rate this issue', value: 3, onChanged: (v) => setState(() => rating = v))
/// ```
class ComicRating extends StatelessWidget {
  /// Creates a rating input.
  const ComicRating({
    super.key,
    required this.label,
    required this.value,
    this.of = 5,
    this.onChanged,
    this.size = 28,
    this.clearable = true,
  }) : assert(value >= 0 && value <= of);

  /// The question, as a screen reader names the group.
  final String label;

  /// Stars chosen, from 0 (none) to [of].
  final int value;

  /// How many stars there are.
  final int of;

  /// Reports a new score; null shows the score without taking presses.
  final ValueChanged<int>? onChanged;

  /// A star's size.
  final double size;

  /// Pressing the chosen star again clears the score to 0.
  final bool clearable;

  @override
  Widget build(BuildContext context) {
    final t = ComicTheme.of(context);
    final c = t.colors;
    final words = ComicLocalizations.of(context);
    // Each star keeps its target's slot, the wash's ring round it; the first slot's lead and the wash's room stand
    // outward, so the first star starts on the column's edge as the read-only stars do.
    final face = size + 8;
    final room = (math.max(face, ComicTapTarget.targetOf(context)) - face) / 2;
    return ComicOutward(
      margin: EdgeInsetsDirectional.only(start: room + 4),
      child: Semantics(
        label: label,
        value: words.rating(value, of),
        container: true,
        explicitChildNodes: true,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < of; i++)
              Padding(
                padding: EdgeInsets.all(room),
                child: ComicPressable(
                  label: words.rate(i + 1, of),
                  selected: i + 1 == value,
                  target: true,
                  outline: WidgetStatePropertyAll(t.shapes.full),
                  onPressed: onChanged == null
                      ? null
                      : () =>
                            onChanged!(clearable && i + 1 == value ? 0 : i + 1),
                  child: SizedBox.square(
                    dimension: face,
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: CustomPaint(
                        painter: _StarPainter(
                          i < value ? c.caption : c.card,
                          c.text,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
