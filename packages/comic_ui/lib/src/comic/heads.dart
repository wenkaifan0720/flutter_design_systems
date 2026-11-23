// Heads and small words: lettered titles, a section's head on the gutter, a panel's head, labels, tags and the small print.
import 'package:flutter/foundation.dart';

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'glyphs.dart';

import 'frames.dart';
import 'internal/geometry.dart';
import 'layout.dart';
import 'theme.dart';
import 'localizations.dart';
import 'press.dart';
import 'internal/cap_label.dart';
import 'internal/lettering.dart' show comicDisplayFor, comicMarkedLeading;
import 'knobs.dart' show ComicSpace;

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
  }) : assert(
         maxLines == null || maxLines > 0,
         'lettering shows at least one line',
       );

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
    style: style != null
        ? comicMarkedLeading(words, style!)
        : comicDisplayFor(words, ComicTheme.of(context).type.panel),
    textAlign: textAlign,
    maxLines: maxLines,
    overflow: maxLines == null ? null : TextOverflow.ellipsis,
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('words', words))
      ..add(DiagnosticsProperty<TextStyle>('style', style, defaultValue: null))
      ..add(EnumProperty<TextAlign>('textAlign', textAlign, defaultValue: null))
      ..add(IntProperty('maxLines', maxLines, defaultValue: null));
  }
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
    final head = Text(
      title.toUpperCase(),
      style: comicDisplayFor(title, t.type.section),
    );
    // The title alone is the header, so the note after it reads as words of
    // its own.
    final heading = Semantics(container: true, header: true, child: head);
    final small = note == null
        ? null
        : Text(
            note!.toUpperCase(),
            style: t.type.label.copyWith(color: t.colors.textSecondary),
          );
    return Padding(
      padding: EdgeInsets.fromLTRB(
        ComicSpace.fine,
        t.desk ? ComicSpace.room : ComicSpace.gap,
        ComicSpace.fine,
        0,
      ),
      child: small == null
          ? heading
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
                          heading,
                          const SizedBox(width: ComicSpace.near),
                          Flexible(child: small),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          heading,
                          const SizedBox(height: ComicSpace.tight),
                          small,
                        ],
                      );
              },
            ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('title', title))
      ..add(StringProperty('note', note, defaultValue: null));
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
                const SizedBox(height: ComicSpace.tight),
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

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('title', title))
      ..add(StringProperty('sub', sub, defaultValue: null))
      ..add(StringProperty('more', more, defaultValue: null))
      ..add(ObjectFlagProperty<VoidCallback>.has('onMore', onMore))
      ..add(DiagnosticsProperty<TextStyle>('style', style, defaultValue: null))
      ..add(DoubleProperty('gapBelow', gapBelow, defaultValue: 12));
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
              // A sixth of a star between neighbours: at 1 px the arm tips meet and the row reads as one strip.
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

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('label', label, defaultValue: null))
      ..add(IntProperty('count', count))
      ..add(IntProperty('of', of, defaultValue: 5))
      ..add(DoubleProperty('size', size, defaultValue: 13))
      ..add(
        FlagProperty(
          'onPaper',
          value: onPaper,
          ifTrue: 'onPaper',
          defaultValue: false,
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

  /// {@macro comic.label}
  final String label;

  /// {@macro comic.onPressed}
  final VoidCallback? onPressed;

  /// {@macro comic.focusNode}
  final FocusNode? focusNode;

  /// {@macro comic.autofocus}
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
          const SizedBox(width: ComicSpace.fine),
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

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('label', label))
      ..add(ObjectFlagProperty<VoidCallback>.has('onPressed', onPressed))
      ..add(
        DiagnosticsProperty<FocusNode>(
          'focusNode',
          focusNode,
          defaultValue: null,
        ),
      )
      ..add(
        FlagProperty(
          'autofocus',
          value: autofocus,
          ifTrue: 'autofocus',
          defaultValue: false,
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

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('words', words))
      ..add(
        FlagProperty(
          'quiet',
          value: quiet,
          ifTrue: 'quiet',
          defaultValue: false,
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
        padding: const EdgeInsets.symmetric(
          horizontal: ComicSpace.gap,
          vertical: ComicSpace.close,
        ),
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
              const SizedBox(width: ComicSpace.tight),
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
              const SizedBox(width: ComicSpace.tight),
              Icon(icon, size: 14, color: letters),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('word', word))
      ..add(EnumProperty<ComicSpeaker>('tone', tone, defaultValue: null))
      ..add(DiagnosticsProperty<IconData>('icon', icon, defaultValue: null))
      ..add(
        FlagProperty(
          'iconEnd',
          value: iconEnd,
          ifTrue: 'iconEnd',
          defaultValue: false,
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
      padding: const EdgeInsets.fromLTRB(
        ComicSpace.fine,
        ComicSpace.close,
        ComicSpace.fine,
        ComicSpace.near,
      ),
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

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('words', words))
      ..add(StringProperty('lead', lead, defaultValue: null));
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
    // Each star's press stands at its floor (the design kit's tap target), the star itself on its slot's start, so the
    // first inks on the column's keyline as the read-only stars do; the stars sit a floor apart. The marks of a press
    // (the dots under the pointer, the chosen disc) fill the star's own round face, which pops under the keyboard.
    return Semantics(
      label: label,
      value: words.rating(value, of),
      container: true,
      explicitChildNodes: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < of; i++)
            ComicPressable(
              label: words.rate(i + 1, of),
              selected: i + 1 == value,
              targetAlignment: AlignmentDirectional.centerStart,
              outline: WidgetStatePropertyAll(t.shapes.full),
              onPressed: onChanged == null
                  ? null
                  : () => onChanged!(clearable && i + 1 == value ? 0 : i + 1),
              child: SizedBox.square(
                dimension: size,
                child: CustomPaint(
                  painter: _StarPainter(i < value ? c.caption : c.card, c.text),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('label', label))
      ..add(IntProperty('value', value))
      ..add(IntProperty('of', of, defaultValue: 5))
      ..add(ObjectFlagProperty<ValueChanged<int>>.has('onChanged', onChanged))
      ..add(DoubleProperty('size', size, defaultValue: 28))
      ..add(
        FlagProperty(
          'clearable',
          value: clearable,
          ifFalse: 'clearable: false',
          defaultValue: true,
        ),
      );
  }
}
