// Panels that carry something: an event, a memory, a step, a voice, a chapter. Each is a `ComicPanel` already laid out, on plain
// data; a page stands them in a `ComicTier` and need not write their insides.
import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../glyphs.dart';

import '../balloons.dart';
import '../controls.dart';
import '../frames.dart';
import '../heads.dart';
import '../layout.dart';
import '../people.dart';
import '../print.dart';
import '../component_themes.dart';
import '../internal/track.dart';
import '../theme.dart';
import '../localizations.dart';

/// A coloured band of dots with a drawing on it: where an event's or a memory's picture goes when you have no picture. [ground]
/// is 1 to 4 (lamp, tint, you, night), the fourth lighting the drawing's loose lines. Give it a [leading], or any [child] such as a
/// `ComicMedia(bare: true)`, a sound effect if it wants one. It fills what it's given.
///
/// ```dart
/// ComicArtBand(ground: 2, leading: Icon(ComicGlyphs.house), sfx: 'Crunch!')
/// ```
class ComicArtBand extends StatelessWidget {
  /// Creates a [ComicArtBand].
  const ComicArtBand({
    super.key,
    this.ground = 1,
    this.leading,
    this.markSize = 104,
    this.sfx,
    this.sfxSize = 22,
    this.caption,
    this.child,
    this.markInset = EdgeInsets.zero,
  });

  /// The background treatment behind this content.
  final int ground;

  /// An optional caller-supplied graphic.
  final Widget? leading;

  /// [markSize]: the height allocated to the mark in logical pixels. [sfxSize]: the sound-effect text size in logical pixels.
  final double markSize, sfxSize;

  /// [sfx]: the optional printed sound effect. [caption]: the optional narration caption.
  final String? sfx, caption;

  /// Content placed inside this widget.
  final Widget? child;

  /// Space around the supplied mark.
  final EdgeInsetsGeometry markInset;
  @override
  Widget build(BuildContext context) {
    final t = ComicTheme.of(context);
    final c = t.colors;
    final (slantStart, slantEnd) = comicSlantInset(context);
    return ColoredBox(
      color: c.artGround(ground),
      child: ComicBenDay(
        color: ground == 4 ? c.art4Dot : c.artDot,
        pitch: 10,
        radius: 2,
        child: Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.hardEdge,
          children: [
            ?child,
            if (leading != null)
              Center(
                child: Padding(
                  padding: markInset,
                  child: SizedBox(
                    height: markSize,
                    child: FittedBox(child: leading!),
                  ),
                ),
              ),
            if (caption != null)
              PositionedDirectional(
                top: 0,
                start: slantStart,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 240),
                  child: ComicCaption(caption!, tight: true),
                ),
              ),
            if (sfx != null)
              PositionedDirectional(
                end: (t.desk ? 12 : 7) + slantEnd,
                bottom: t.desk ? 10 : 6,
                child: ComicSfx(sfx!, size: sfxSize, fill: c.sfxOn(ground)),
              ),
          ],
        ),
      ),
    );
  }
}

/// Something coming up: a date in its caption, a title, where, who's in, a count. Its drawing or picture stands in a cell at its
/// end on a phone and a band on top on a desktop. [big] is the one that's the star of the row: it counts down with [count] in
/// the lettering, and its ground is dotted. Lay them in `ComicTier(phone: ComicTierLayout.stack)`.
///
/// ```dart
/// ComicEventPanel(when: 'Sat 14 Nov', title: 'Morning walk', where: 'From the station', leading: Icon(ComicGlyphs.house), people: const [ComicPerson(initials: 'AB', size: 24)], tally: '5 in')
/// ```
class ComicEventPanel extends StatelessWidget {
  /// Creates a [ComicEventPanel].
  const ComicEventPanel({
    super.key,
    required this.when,
    required this.title,
    this.whenIcon,
    this.where,
    this.leading,
    this.art,
    this.ground = 1,
    this.people = const [],
    this.tally,
    this.big = false,
    this.count,
    this.countWord,
    this.trailing,
    this.onPressed,
    this.focusNode,
    this.autofocus = false,
  });

  /// [when]: the date or time label of the event. [title]: the primary heading.
  final String when, title;

  /// An optional glyph beside the event's date or time.
  final IconData? whenIcon;

  /// [where]: the place or location label. [tally]: the count label printed with this content. [count]: the count printed in the main figure. [countWord]: the unit or caption printed beside the count.
  final String? where, tally, count, countWord;

  /// An optional caller-supplied graphic.
  final Widget? leading;

  /// A picture or a drawing, in place of a [leading].
  final Widget? art;

  /// The background treatment behind this content.
  final int ground;

  /// People displayed beside this content.
  final List<ComicPerson> people;

  /// Uses the emphasized, larger presentation.
  final bool big;

  /// Content after the main words.
  final Widget? trailing;

  /// Called when activated; null disables the action.
  final VoidCallback? onPressed;

  /// The caller's focus node, if any; the part makes its own when null.
  final FocusNode? focusNode;

  /// Whether the part asks for the focus when it first appears.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final t = ComicTheme.of(context);
    final c = t.colors;
    final desk = t.desk;
    final markSize = desk ? (big ? 96.0 : 82.0) : (big ? 78.0 : 70.0);
    final cnt = tally == null
        ? null
        : Text(
            tally!.toUpperCase(),
            style: t.type.text(
              12,
              1.3,
              weight: FontWeight.w800,
              tracking: .05,
              color: c.text,
            ),
          );
    final foot = people.isEmpty && cnt == null && trailing == null
        ? null
        : Padding(
            padding: const EdgeInsets.only(top: 4),
            child: big && desk
                ? ComicSplit(
                    start: ComicPeople(people, max: 6),
                    end: trailing ?? cnt ?? const SizedBox.shrink(),
                    gap: 10,
                    runGap: 6,
                  )
                : ComicColumn(
                    gap: 6,
                    children: [
                      if (people.isNotEmpty) ComicPeople(people, max: 6),
                      ?cnt,
                      ?trailing,
                    ],
                  ),
          );
    final words = Padding(
      padding: desk
          ? const EdgeInsets.fromLTRB(16, 14, 16, 16)
          : const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: ComicColumn(
        gap: 6,
        children: [
          if (count != null)
            Wrap(
              spacing: 6,
              runSpacing: 2,
              crossAxisAlignment: WrapCrossAlignment.end,
              children: [
                Text(
                  count!,
                  style: t.type.letter(46, lineHeight: .8, tracking: .03),
                ),
                if (countWord != null)
                  Text(
                    countWord!.toUpperCase(),
                    style: t.type.letter(20, lineHeight: 1, tracking: .05),
                  ),
              ],
            ),
          ComicLetters(
            title,
            style: t.type.item.copyWith(fontSize: big ? 28 : null),
          ),
          if (where != null) Text(where!, style: t.type.meta),
          if (foot != null)
            ComicGrow(
              child: Align(
                alignment: AlignmentDirectional.bottomStart,
                heightFactor: 1,
                child: foot,
              ),
            ),
        ],
      ),
    );
    final picture = art != null || leading != null
        ? ComicArtBand(
            ground: ground,
            leading: leading,
            markSize: markSize,
            markInset: desk ? const EdgeInsets.only(top: 18) : EdgeInsets.zero,
            child: art,
          )
        : null;
    final line = BorderSide(color: c.nightLine, width: t.rim(3));
    final caption = ComicCaption(when, icon: whenIcon);
    final Widget body;
    if (picture == null) {
      body = ComicColumn(
        children: [
          caption,
          ComicGrow(child: words),
        ],
      );
    } else if (desk) {
      body = ComicColumn(
        children: [
          SizedBox(
            height: 112,
            child: Stack(
              fit: StackFit.expand,
              children: [
                DecoratedBox(
                  position: DecorationPosition.foreground,
                  decoration: BoxDecoration(border: Border(bottom: line)),
                  child: picture,
                ),
                PositionedDirectional(
                  top: 0,
                  start: 0,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 200),
                    child: caption,
                  ),
                ),
              ],
            ),
          ),
          ComicGrow(child: words),
        ],
      );
    } else {
      body = _CellAtEnd(
        cell: DecoratedBox(
          position: DecorationPosition.foreground,
          decoration: BoxDecoration(border: BorderDirectional(start: line)),
          child: picture,
        ),
        cellWidth: 92,
        child: ComicColumn(
          children: [
            caption,
            ComicGrow(child: words),
          ],
        ),
      );
    }
    return ComicPanel(
      focusNode: focusNode,
      autofocus: autofocus,
      bleed: true,
      ground: big ? ComicPanelFill.dots : ComicPanelFill.plain,
      onPressed: onPressed,
      label: title,
      child: body,
    );
  }
}

/// Words with a cell at their end, the cell taking the words' height.
class _CellAtEnd extends StatelessWidget {
  const _CellAtEnd({
    required this.child,
    required this.cell,
    required this.cellWidth,
    this.atStart = false,
  });
  final Widget child, cell;
  final double cellWidth;
  final bool atStart;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final w = box.hasBoundedWidth ? box.maxWidth : 320.0;
      final cellW = math.min(cellWidth, w * .45);
      final total = w.round();
      final wide = math.max(1, cellW.round());
      // The row first measures each cell with no height: an art cell fills, so it says how tall it would like to be.
      final art = LimitedBox(maxHeight: cellW, child: cell);
      return ComicEqualRow(
        flex: atStart ? [wide, total - wide] : [total - wide, wide],
        columns: total,
        children: atStart ? [art, child] : [child, art],
      );
    },
  );
}

/// A memory or a past thing: a band of colour with a drawn object and a sound effect, then a lettered line and a few words on
/// paper. [ground] is 1 to 4. Keep the words short: this is a panel of a strip. In a `ComicTier(phone: ComicTierLayout.strip)` these
/// make a wall; give two in a `ComicTier(slanted: true)` the page's one lean.
///
/// ```dart
/// ComicMarkPanel(date: 'Sun 8 Nov', leading: Icon(ComicGlyphs.house), sfx: 'Munch!', title: 'Brunch', words: 'Two breakfasts. Both for one.')
/// ```
class ComicMarkPanel extends StatelessWidget {
  /// Creates a [ComicMarkPanel].
  const ComicMarkPanel({
    super.key,
    required this.title,
    this.date,
    this.leading,
    this.ground = 1,
    this.sfx,
    this.words,
    this.art,
    this.onPressed,
    this.focusNode,
    this.autofocus = false,
  });

  /// The primary heading.
  final String title;

  /// [date]: the date printed with this content. [sfx]: the optional printed sound effect. [words]: the words displayed in this composition.
  final String? date, sfx, words;

  /// An optional caller-supplied graphic.
  final Widget? leading;

  /// The background treatment behind this content.
  final int ground;

  /// A picture or a scene behind the mark.
  final Widget? art;

  /// Called when activated; null disables the action.
  final VoidCallback? onPressed;

  /// The caller's focus node, if any; the part makes its own when null.
  final FocusNode? focusNode;

  /// Whether the part asks for the focus when it first appears.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final t = ComicTheme.of(context);
    final c = t.colors;
    final (slantStart, slantEnd) = comicSlantInset(context);
    final desk = t.desk;
    return ComicPanel(
      focusNode: focusNode,
      autofocus: autofocus,
      bleed: true,
      onPressed: onPressed,
      label: title,
      child: ComicColumn(
        children: [
          SizedBox(
            height: desk ? 158 : 128,
            child: ComicArtBand(
              ground: ground,
              leading: leading,
              markSize: desk ? 130 : 104,
              sfx: sfx,
              sfxSize: desk ? 32 : 22,
              caption: date,
              markInset: EdgeInsetsDirectional.only(
                start: slantStart > 0 ? (desk ? 30 : 12) : 0,
              ),
              child: art,
            ),
          ),
          ComicGrow(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: c.paper,
                border: Border(
                  top: BorderSide(color: c.outline, width: t.rim(3)),
                ),
              ),
              child: Padding(
                padding: EdgeInsetsDirectional.fromSTEB(
                  slantStart > 0 ? (desk ? 22 : 14) : 9,
                  10,
                  slantEnd > 0 ? (desk ? 56 : 22) : 9,
                  9,
                ),
                child: ComicColumn(
                  children: [
                    Text(
                      title.toUpperCase(),
                      style: t.type.letter(
                        16,
                        lineHeight: 1.05,
                        color: c.onPaper,
                        tracking: .05,
                      ),
                    ),
                    if (words != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          words!,
                          style: t.type.text(
                            12,
                            1.3,
                            weight: FontWeight.w700,
                            color: c.onPaper,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A numbered step: its number in a lamp's corner, a drawn cell with a sound effect, then a sentence and an action. The cell stands
/// at its start on a phone and on top on a desktop. [long] is the slow step of a method: on a phone its picture goes over its
/// words, wide. Lay them in a `ComicTier`.
///
/// ```dart
/// ComicStepPanel(number: '1', leading: Icon(ComicGlyphs.house), sfx: 'Sizzle!', words: 'Soften the onions.', action: ComicButton('8 min', size: ComicButtonSize.small))
/// ```
class ComicStepPanel extends StatelessWidget {
  /// Creates a [ComicStepPanel].
  const ComicStepPanel({
    super.key,
    required this.number,
    required this.words,
    this.leading,
    this.ground = 1,
    this.sfx,
    this.action,
    this.long = false,
  });

  /// [number]: the number printed in the figure. [words]: the words displayed in this composition.
  final String number, words;

  /// An optional caller-supplied graphic.
  final Widget? leading;

  /// The background treatment behind this content.
  final int ground;

  /// The optional printed sound effect.
  final String? sfx;

  /// The optional action beside this content.
  final Widget? action;

  /// Uses the wider form of the composition.
  final bool long;
  @override
  Widget build(BuildContext context) {
    final t = ComicTheme.of(context);
    final c = t.colors;
    final desk = t.desk;
    final line = BorderSide(color: c.outline, width: t.rim(3));
    final corner = Container(
      width: 30,
      height: 30,
      padding: const EdgeInsets.all(6),
      alignment: Alignment.center,
      decoration: ShapeDecoration(
        color: c.caption,
        shape: t.shapes.small.copyWith(
          side: BorderSide(color: c.outline, width: t.rim(2.5)),
        ),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          number,
          style: t.type.letter(22, lineHeight: 1, color: c.onCaption),
        ),
      ),
    );
    final top = desk || long;
    final artCell = Stack(
      fit: StackFit.expand,
      children: [
        ComicArtBand(
          ground: ground,
          leading: leading,
          markSize: desk ? 100 : (long ? 100 : 92),
          markInset: const EdgeInsets.only(top: 12),
        ),
        PositionedDirectional(top: 0, start: 0, child: corner),
        if (sfx != null)
          PositionedDirectional(
            top: long ? null : (desk ? 8 : 5),
            bottom: long ? 8 : null,
            start: long ? 12 : null,
            end: long ? null : (desk ? 10 : 6),
            child: ComicSfx(
              sfx!,
              size: long ? (desk ? 34 : 26) : (desk ? 26 : 20),
              fill: c.sfxOn(ground),
            ),
          ),
      ],
    );
    final body = Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(12, 10, 10, 12),
      child: ComicColumn(
        children: [
          ComicGrow(
            child: Text(
              words,
              style: t.type.text(16, 1.4, weight: FontWeight.w600),
            ),
          ),
          if (action != null) ...[
            const SizedBox(height: 10),
            Align(
              alignment: AlignmentDirectional.centerStart,
              widthFactor: 1,
              heightFactor: 1,
              child: action,
            ),
          ],
        ],
      ),
    );
    return ComicPanel(
      bleed: true,
      child: top
          ? ComicColumn(
              children: [
                DecoratedBox(
                  position: DecorationPosition.foreground,
                  decoration: BoxDecoration(border: Border(bottom: line)),
                  child: SizedBox(height: desk ? 132 : 116, child: artCell),
                ),
                ComicGrow(child: body),
              ],
            )
          : _StepRow(line: line, art: artCell, body: body),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.line, required this.art, required this.body});
  final BorderSide line;
  final Widget art, body;
  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(minHeight: 118),
    child: _CellAtEnd(
      atStart: true,
      cellWidth: 136,
      cell: DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(border: BorderDirectional(end: line)),
        child: art,
      ),
      child: body,
    ),
  );
}

/// Someone speaking in a panel of a strip: the time in a caption, what they said in a balloon, their portrait under it, their name
/// on a plate. Four of these make a thread read as a strip, on alternating dots with [mine] for your own.
///
/// ```dart
/// ComicVoicePanel(time: 'Tue 21:16', words: 'Booked for the fourth.', name: 'Sam')
/// ```
class ComicVoicePanel extends StatelessWidget {
  /// Creates a [ComicVoicePanel].
  const ComicVoicePanel({
    super.key,
    required this.words,
    required this.name,
    this.time,
    this.portrait,
    this.slotId,
    this.warm = false,
  });

  /// [words]: the words displayed in this composition. [name]: the displayed name of this record or person.
  final String words, name;

  /// [time]: the time printed with this content. [slotId]: the host image slot supplying this picture.
  final String? time, slotId;

  /// An optional caller-supplied portrait widget.
  final Widget? portrait;

  /// The second ground: dots in the act's tint, to alternate down a strip.
  final bool warm;
  @override
  Widget build(BuildContext context) {
    final t = ComicTheme.of(context);
    final c = t.colors;
    final desk = t.desk;
    final figure = desk ? 150.0 : 116.0;
    return ComicPanel(
      bleed: true,
      ground: warm ? ComicPanelFill.currentUserDots : ComicPanelFill.dots,
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: desk ? 334 : 294),
        child: ComicColumn(
          children: [
            if (time != null) ComicCaption(time!, tight: true),
            Padding(
              padding: EdgeInsets.fromLTRB(
                desk ? 16 : 10,
                time == null ? (desk ? 40 : 36) : (desk ? 16 : 12),
                desk ? 16 : 10,
                0,
              ),
              child: ComicBalloon(words, small: !desk, fill: true, tailAt: .5),
            ),
            ComicGrow(child: const SizedBox(height: 4)),
            Center(
              heightFactor: 1,
              child: comicOwnSize(
                width: figure,
                height: figure,
                alignment: AlignmentDirectional.center,
                child: slotId != null
                    ? ComicPerson(slotId: slotId, size: figure, label: name)
                    : portrait ?? ComicPerson.seeded(name, size: figure),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                color: c.paper,
                border: Border(
                  top: BorderSide(color: c.outline, width: t.rim(3)),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.fromLTRB(4, 8, 4, 9),
                child: Text(
                  name.toUpperCase(),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.type.letter(
                    desk ? 20 : 18,
                    lineHeight: .95,
                    color: c.onPaper,
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

/// A chapter: a band of art with a caption, a lettered head on a well, then its rows, usually `ComicTimedRow`s with `inset: 14`.
/// Three of these side by side read as a book of days.
///
/// ```dart
/// ComicChapterPanel(caption: 'Chapter 1', title: 'The drive', art: ComicArtBand(ground: 2, leading: Icon(ComicGlyphs.house)), children: [ComicTimedRow('16:00', title: 'Leave', isFirst: true, inset: 14)])
/// ```
class ComicChapterPanel extends StatelessWidget {
  /// Creates a [ComicChapterPanel].
  const ComicChapterPanel({
    super.key,
    required this.title,
    required this.children,
    this.caption,
    this.art,
  });

  /// The primary heading.
  final String title;

  /// The optional narration caption.
  final String? caption;

  /// A caller-supplied illustration or image widget.
  final Widget? art;

  /// Child widgets in their display order.
  final List<Widget> children;
  @override
  Widget build(BuildContext context) {
    final t = ComicTheme.of(context);
    final c = t.colors;
    final desk = t.desk;
    final line = BorderSide(color: c.nightLine, width: t.rim(3));
    return ComicPanel(
      bleed: true,
      child: ComicColumn(
        children: [
          if (art != null)
            DecoratedBox(
              position: DecorationPosition.foreground,
              decoration: BoxDecoration(border: Border(bottom: line)),
              child: SizedBox(
                height: desk ? 128 : 112,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    art!,
                    if (caption != null)
                      PositionedDirectional(
                        top: 0,
                        start: 0,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 300),
                          child: ComicCaption(caption!),
                        ),
                      ),
                  ],
                ),
              ),
            )
          else if (caption != null)
            ComicCaption(caption!),
          DecoratedBox(
            decoration: BoxDecoration(
              color: c.inset,
              border: Border(bottom: line),
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                desk ? 18 : 14,
                desk ? 12 : 10,
                desk ? 18 : 14,
                (desk ? 10 : 8) + 3,
              ),
              child: ComicLetters(title),
            ),
          ),
          for (final row in children) ComicGrow(child: row),
        ],
      ),
    );
  }
}

/// One person speaking in a thread: a head, then a balloon whose tail reaches back at them. It keeps the head's size and lets the
/// balloon wrap, at any width.
///
/// ```dart
/// ComicSpeech(person: const ComicPerson(initials: 'AB', size: 48), text: 'Chili is on me.', author: 'Sam · 21:20')
/// ```
class ComicSpeech extends StatelessWidget {
  /// Creates a [ComicSpeech].
  const ComicSpeech({
    super.key,
    required this.person,
    this.text,
    this.author,
    this.fill = false,
    this.child,
    this.rating,
    this.when,
  });

  /// Stars out of five, for a review: [author], the stars and [when] then stand over the words.
  final int? rating;

  /// The date or time label of the event.
  final String? when;

  /// The person associated with this content.
  final ComicPerson person;

  /// [text]: the words displayed in this composition. [author]: the attribution printed with the words.
  final String? text, author;

  /// The balloon takes the row, not just its words' width.
  final bool fill;

  /// Content placed inside this widget.
  final Widget? child;
  @override
  Widget build(BuildContext context) {
    final inside = rating == null ? child : _review(ComicTheme.of(context));
    final who = rating == null ? author : null;
    final said = rating == null ? text : null;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        person,
        const SizedBox(width: 12),
        fill
            ? Expanded(
                child: ComicBalloon(
                  said,
                  by: who,
                  tail: ComicTail.side,
                  room: false,
                  fill: true,
                  child: inside,
                ),
              )
            : Flexible(
                child: ComicBalloon(
                  said,
                  by: who,
                  tail: ComicTail.side,
                  room: false,
                  child: inside,
                ),
              ),
      ],
    );
  }

  Widget _review(ComicThemeData t) {
    final head = t.type.text(
      12,
      1.25,
      weight: FontWeight.w800,
      color: t.colors.onPaperSecondary,
      tracking: .05,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 2,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (author != null) Text(author!.toUpperCase(), style: head),
            ComicStars(rating!, onPaper: true),
            if (when != null) Text(when!.toUpperCase(), style: head),
          ],
        ),
        const SizedBox(height: 4),
        if (text != null)
          Text(
            text!.toUpperCase(),
            style: t.type.balloon.copyWith(color: t.colors.onPaper),
          ),
      ],
    );
  }
}

/// What you'd say back: your head, a reply field, and its action. The act is a label on a desktop and an icon on a phone.
/// Stands under a thread.
///
/// ```dart
/// ComicReply(person: const ComicPerson(initials: 'Me', size: 44), hint: 'Say something…', onSend: () {})
/// ```
class ComicReply extends StatelessWidget {
  /// Creates a [ComicReply].
  const ComicReply({
    super.key,
    required this.person,
    this.hint,
    this.label,
    this.icon,
    this.controller,
    this.onSend,
    this.onSubmitted,
    this.plain = false,
  });

  /// The person associated with this content.
  final ComicPerson person;

  /// Placeholder text shown when the field is empty.
  final String? hint;

  /// The visible or spoken name of the component.
  final String? label;

  /// The optional glyph beside the words.
  final IconData? icon;

  /// The caller-owned editing controller.
  final TextEditingController? controller;

  /// Submits the composed message.
  final VoidCallback? onSend;

  /// Reports text submitted from the keyboard.
  final ValueChanged<String>? onSubmitted;

  /// The act stands quiet: a plain square, for a reply nobody is waiting on.
  final bool plain;
  @override
  Widget build(BuildContext context) {
    final desk = ComicTheme.of(context).desk;
    final label = this.label ?? ComicLocalizations.of(context).send;
    final glyph = icon ?? ComicGlyphs.send;
    // On a phone the send is a square as tall as the field beside it, at every density.
    final square = WidgetStatePropertyAll<Size?>(
      Size.square(ComicTrack.fieldHeight(context)),
    );
    final act = plain
        ? desk
              ? ComicButton(label, icon: glyph, onPressed: onSend)
              : ComicIconButton(
                  glyph,
                  label: label,
                  onPressed: onSend,
                  style: ComicStyle(minimumSize: square),
                )
        : desk
        ? ComicButton.filled(label, icon: glyph, onPressed: onSend)
        : ComicIconButton(
            glyph,
            label: label,
            onPressed: onSend,
            style: ComicStyle(
              minimumSize: square,
              fill: WidgetStatePropertyAll(
                ComicTheme.of(context).colors.primary,
              ),
              foreground: WidgetStatePropertyAll(
                ComicTheme.of(context).colors.onPrimary,
              ),
            ),
          );
    final row = Row(
      children: [
        person,
        const SizedBox(width: 10),
        Expanded(
          child: ComicTextField(
            onPaper: true,
            hint: hint,
            controller: controller,
            onSubmitted: onSubmitted,
          ),
        ),
        const SizedBox(width: 10),
        act,
      ],
    );
    return desk
        ? Align(
            alignment: AlignmentDirectional.centerStart,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: row,
            ),
          )
        : row;
  }
}

/// A sentence with its one figure lit: "You owe Sam €19." A head or a mark at its start, the words in the lettering, a quiet line
/// under them. For the panel that tells someone where they stand.
///
/// ```dart
/// ComicClaim(before: 'You owe Sam', figure: '€19', note: 'Your share of Saturday.', person: const ComicPerson(initials: 'SD', size: 56))
/// ```
class ComicClaim extends StatelessWidget {
  /// Creates a [ComicClaim].
  const ComicClaim({
    super.key,
    this.before,
    required this.figure,
    this.after,
    this.note,
    this.person,
  });

  /// [before]: content preceding the main figure. [after]: content following the main figure. [note]: secondary explanatory text.
  final String? before, after, note;

  /// The primary printed figure.
  final String figure;

  /// The person associated with this content.
  final Widget? person;
  @override
  Widget build(BuildContext context) {
    final t = ComicTheme.of(context);
    final style = t.type.letter(t.desk ? 36 : 28);
    return ComicBeside(
      object: person ?? const SizedBox.shrink(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text.rich(
            TextSpan(
              style: style,
              children: [
                if (before != null) TextSpan(text: '${before!.toUpperCase()} '),
                TextSpan(
                  text: figure.toUpperCase(),
                  style: TextStyle(color: t.colors.primaryLargeText),
                ),
                if (after != null) TextSpan(text: ' ${after!.toUpperCase()}'),
              ],
            ),
          ),
          if (note != null) Text(note!, style: t.type.small),
        ],
      ),
    );
  }
}

/// A row of two to four figures in wells, the last on the lamp if [highlightLast]: a recipe's times, a booking's nights. Lettered numbers,
/// quiet words under them.
///
/// ```dart
/// ComicFigures(const [('20 min', 'Prep'), ('1 h 10', 'Cook'), ('1 h 30', 'Total')], highlightLast: true)
/// ```
class ComicFigures extends StatelessWidget {
  /// Creates a [ComicFigures].
  const ComicFigures(this.items, {super.key, this.highlightLast = false});

  /// Items displayed in their supplied order.
  final List<(String, String)> items;

  /// Emphasizes the final figure in the group.
  final bool highlightLast;
  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return ComicEqualRow(
      flex: List.filled(items.length, 1),
      gap: 8,
      children: [
        for (var i = 0; i < items.length; i++)
          ComicWell(
            lamp: highlightLast && i == items.length - 1,
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 13),
            child: Builder(
              builder: (context) {
                final t = ComicTheme.of(context);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(
                        items[i].$1.toUpperCase(),
                        maxLines: 1,
                        style: t.type.letter(24, lineHeight: 1, tracking: .03),
                      ),
                    ),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(
                        items[i].$2.toUpperCase(),
                        maxLines: 1,
                        style: t.type.text(
                          12,
                          1.25,
                          weight: FontWeight.w800,
                          color: t.colors.textSecondary,
                          tracking: .05,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
      ],
    );
  }
}

/// A row of a measured list: an amount in a fixed column, then what it's of, a small note after. Ingredients, parts, a kit list.
///
/// ```dart
/// ComicAmountRow('2 tsp', 'smoked paprika', note: 'or sweet', isFirst: true)
/// ```
class ComicAmountRow extends StatelessWidget {
  /// Creates a [ComicAmountRow].
  const ComicAmountRow(
    this.amount,
    this.name, {
    super.key,
    this.note,
    this.isFirst = false,
  });

  /// [amount]: the amount represented by this entry. [name]: the displayed name of this record or person.
  final String amount, name;

  /// Secondary explanatory text.
  final String? note;

  /// Omits a separating rule before the first entry.
  final bool isFirst;
  @override
  Widget build(BuildContext context) {
    final t = ComicTheme.of(context);
    final c = t.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: isFirst
            ? null
            : Border(
                top: BorderSide(color: c.divider, width: t.rule(2)),
              ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9.5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            SizedBox(
              width: 84,
              child: Text(
                amount,
                style: t.type.text(16, 1.4, weight: FontWeight.w800).tabular,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text.rich(
                TextSpan(
                  style: t.type.text(16, 1.4, weight: FontWeight.w600),
                  children: [
                    TextSpan(text: name),
                    if (note != null)
                      TextSpan(text: ' $note', style: t.type.small),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A dated line of a ledger: a small date, a title and its meta, a lettered value at its end.
///
/// ```dart
/// ComicLedgerRow(date: 'Tue 10 Nov', title: 'Birch Cabin', subtitle: '€90 each', value: '€540', isFirst: true)
/// ```
class ComicLedgerRow extends StatelessWidget {
  /// Creates a [ComicLedgerRow].
  const ComicLedgerRow({
    super.key,
    required this.title,
    required this.value,
    this.date,
    this.subtitle,
    this.isFirst = false,
    this.isCurrentUser = false,
  });

  /// [title]: the primary heading. [value]: the current value represented by the control or record.
  final String title, value;

  /// [date]: the date printed with this content. [subtitle]: secondary information printed with the entry.
  final String? date, subtitle;

  /// Omits a separating rule before the first entry.
  final bool isFirst;

  /// Its meta is about you, in the act's words.
  final bool isCurrentUser;
  @override
  Widget build(BuildContext context) {
    final t = ComicTheme.of(context);
    final c = t.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: isFirst
            ? null
            : Border(
                top: BorderSide(color: c.divider, width: t.rule(2)),
              ),
      ),
      child: Padding(
        padding: EdgeInsets.only(top: isFirst ? 3 : 12, bottom: 12),
        child: Row(
          children: [
            if (date != null) ...[
              SizedBox(
                width: 62,
                child: Text(
                  date!.toUpperCase(),
                  style: t.type.text(
                    12,
                    1.25,
                    weight: FontWeight.w800,
                    color: c.textSecondary,
                    tracking: .04,
                  ),
                ),
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: t.type.title),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: t.type.meta.copyWith(
                        color: isCurrentUser ? c.primaryText : null,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              value.toUpperCase(),
              style: t.type.letter(24, lineHeight: .95, tracking: .03),
            ),
          ],
        ),
      ),
    );
  }
}
