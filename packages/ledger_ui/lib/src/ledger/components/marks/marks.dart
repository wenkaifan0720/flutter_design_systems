import 'package:flutter/widgets.dart';

import '../../format.dart';
import '../../internal/cap_center.dart';
import '../../internal/dashed.dart';
import '../../theme.dart';

/// How a [LedgerGlyph] is inked: [plain] on the light paper in a fine
/// ring, [move] (a move between the owner's own accounts) dashed and
/// open, [moneyIn] on the green wash, [inked] ringed in the ink (a firm
/// state: declined), [selected] ringed in the green on its wash (the chosen
/// option of a list).
enum LedgerGlyphTone {
  /// On the light paper, in a fine ring.
  plain,

  /// Dashed and open: a move between the owner's own accounts.
  move,

  /// On the green wash: money in.
  moneyIn,

  /// Ringed in the ink: a firm state (declined).
  inked,

  /// `.opt.is-on .glyph`: border, glyph and wash all the green's.
  selected,
}

/// How large a [LedgerGlyph] stands, and its glyph, as the source sizes
/// `.glyph` where it stands.
enum LedgerGlyphSize {
  /// 40, its glyph 18: a row's lead.
  row(40, 18),

  /// 36, its glyph 16: a day group's row, a freeze's effect.
  dense(36, 16),

  /// 36, its glyph 17: a cheque's pick line, a category option.
  pick(36, 17),

  /// 32, its glyph 15: a goal's line, a category's tile.
  small(32, 15),

  /// 56, 64 on the desktop, its glyph 22: a record's head.
  record(56, 22, 64);

  const LedgerGlyphSize(this.phone, this.glyph, [double? desk])
    : desk = desk ?? phone;

  /// Its round on a phone.
  final double phone;

  /// Its round from 1024.
  final double desk;

  /// The glyph inside.
  final double glyph;
}

/// A round mark wearing one Lucide glyph (`.glyph`): an account's, a
/// category's, a goal's, a move's (dashed). It names nothing to a screen
/// reader; the row it leads says what it is.
///
/// ```dart
/// LedgerGlyph(LucideIcons.wallet)
/// ```
///
/// ```dart
/// LedgerGlyph(LucideIcons.arrowRightLeft, tone: LedgerGlyphTone.move, size: LedgerGlyphSize.dense)
/// ```
class LedgerGlyph extends StatelessWidget {
  /// A round mark wearing [icon].
  const LedgerGlyph(
    this.icon, {
    this.tone = LedgerGlyphTone.plain,
    this.size = LedgerGlyphSize.row,
    super.key,
  });

  /// The Lucide glyph it wears.
  final IconData icon;

  /// How it is inked.
  final LedgerGlyphTone tone;

  /// How large it stands.
  final LedgerGlyphSize size;

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    final round = LedgerLayout.isWide(context) ? size.desk : size.phone;
    final (ring, fill, ink) = switch (tone) {
      LedgerGlyphTone.plain => (t.border, t.surface, t.textPrimary),
      LedgerGlyphTone.move => (t.textFaint, null, t.textSecondary),
      LedgerGlyphTone.moneyIn => (t.accentRule, t.accentSubtle, t.accent),
      LedgerGlyphTone.inked => (t.textPrimary, t.surface, t.textPrimary),
      LedgerGlyphTone.selected => (t.accent, t.accentSubtle, t.accent),
    };
    final glyph = Icon(icon, size: size.glyph, color: ink);
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: round,
        child: tone == LedgerGlyphTone.move
            // Dashed as Chrome dashes a border: 3 on, about 2 off, fitted.
            ? CustomPaint(
                painter: LedgerDashedOutline(
                  radius: BorderRadius.circular(round / 2),
                  color: ring,
                ),
                child: Center(child: glyph),
              )
            : DecoratedBox(
                decoration: BoxDecoration(
                  color: fill,
                  shape: BoxShape.circle,
                  border: Border.all(color: ring),
                ),
                child: Center(child: glyph),
              ),
      ),
    );
  }
}

/// How a [LedgerMonogram] is inked: [plain] on the light paper, [moneyIn]
/// green on the green wash (who paid the owner), [inked] the paper's
/// letters on a disc of the ink, ringed 3 out in the slip's paper and 1 in
/// the ink (the account holder's, on the member card).
enum LedgerMonogramTone {
  /// On the light paper.
  plain,

  /// Green on the green wash: who paid the owner.
  moneyIn,

  /// `.member-mg`: ink ground, `--paper-hi` letters, box-shadow 0 0 0 3px
  /// paper-hi, 0 0 0 4px ink.
  inked,
}

/// How large a [LedgerMonogram] stands, and its letters, as the source
/// sizes `.mg` where it stands.
enum LedgerMonogramSize {
  /// 40, its letters 16: a row's lead.
  row(40, 16),

  /// 36, its letters 15: a day group's row, a memo's foot.
  dense(36, 15),

  /// 56, its letters 21: a person to send to or split with.
  person(56, 21),

  /// 56 in the ink's ring, 64 on the desktop, its letters 22 (24): a
  /// record's head.
  record(56, 22, 64, 24),

  /// 72, 84 on the desktop, its letters 30 (32): the account holder's on
  /// the member card (`.member-mg` 72, italic 30/1; 84 and 32 from 1024).
  member(72, 30, 84, 32);

  const LedgerMonogramSize(
    this.phone,
    this.letters, [
    double? desk,
    double? deskLetters,
  ]) : desk = desk ?? phone,
       deskLetters = deskLetters ?? letters;

  /// Its round on a phone.
  final double phone;

  /// Its round from 1024.
  final double desk;

  /// Its letters' size on a phone.
  final double letters;

  /// Its letters' size from 1024.
  final double deskLetters;
}

/// A merchant's or a person's initials in the italic serif inside a fine
/// ring (`.mg`): "BF" for Blue Fern Café, green on its wash for who paid
/// the owner, the paper's letters on the ink for the account holder
/// ([LedgerMonogramTone.inked]). [selected] rings a chosen person in the
/// green, the paper between. It names nothing to a screen reader; the row
/// says who.
///
/// ```dart
/// LedgerMonogram('Blue Fern Café')
/// ```
///
/// ```dart
/// LedgerMonogram('Northwind Studio', tone: LedgerMonogramTone.moneyIn)
/// ```
///
/// ```dart
/// LedgerMonogram('Maren Holt', tone: LedgerMonogramTone.inked, size: LedgerMonogramSize.member)
/// ```
class LedgerMonogram extends StatelessWidget {
  /// The initials of [name], or [initials].
  const LedgerMonogram(
    this.name, {
    this.initials,
    this.tone = LedgerMonogramTone.plain,
    this.size = LedgerMonogramSize.row,
    this.selected = false,
    super.key,
  });

  /// Whose initials: the first letters of its first two words.
  final String name;

  /// The letters, when not the name's own (a person's chosen pair).
  final String? initials;

  /// How it is inked.
  final LedgerMonogramTone tone;

  /// How large it stands.
  final LedgerMonogramSize size;

  /// Whether the person is the one chosen (`.person.is-on`).
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    final wide = LedgerLayout.isWide(context);
    final round = wide ? size.desk : size.phone;
    final green = tone == LedgerMonogramTone.moneyIn || selected;
    final inked = tone == LedgerMonogramTone.inked && !selected;
    final record = size == LedgerMonogramSize.record;
    // `.mg-l` rings itself in the ink (in the green when money came in).
    final ring = green
        ? (record || selected ? t.accent : t.accentRule)
        : (record ? t.textPrimary : t.border);
    final letters = t.monogram
        .sized(wide ? size.deskLetters : size.letters)
        .line(wide ? size.deskLetters : size.letters)
        .colored(
          green
              ? t.accent
              : inked
              ? t.textInverse
              : t.textPrimary,
        );
    return ExcludeSemantics(
      child: Container(
        width: round,
        height: round,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: green
              ? t.accentSubtle
              : inked
              ? t.surfaceInverse
              : t.surface,
          shape: BoxShape.circle,
          // `.member-mg` has no border: its ring is its shadow.
          border: inked ? null : Border.all(color: ring),
          // The chosen person: 3 of the paper, then 1 of the green (CSS
          // lays its first shadow on top; Flutter paints them in order).
          // The inked disc: 3 of the slip's paper, then 1 of the ink.
          boxShadow: selected
              ? [
                  BoxShadow(color: t.accent, spreadRadius: _ringGap + 1),
                  BoxShadow(color: t.background, spreadRadius: _ringGap),
                ]
              : inked
              ? [
                  BoxShadow(
                    color: t.surfaceInverse,
                    spreadRadius: _ringGap + 1,
                  ),
                  BoxShadow(color: t.surface, spreadRadius: _ringGap),
                ]
              : null,
        ),
        // Its capitals on the disc's middle, as every face's label stands;
        // engraved in the disc, they keep their size with a large text (a
        // screen reader hears the row's name, not these).
        child: MediaQuery.withNoTextScaling(
          child: ledgerCapCenter(
            letters,
            Text(
              initials ?? LedgerFormat.initials(name),
              maxLines: 1,
              softWrap: false,
              style: letters,
            ),
          ),
        ),
      ),
    );
  }

  // `.person.is-on .mg`: box-shadow 0 0 0 3px paper, 0 0 0 4px green;
  // `.member-mg` the same 3 and 4 in the paper-hi and the ink.
  static const double _ringGap = 3;
}

/// A frame of the faint ink's dashes round its [child] (`border: 1px
/// dashed var(--ink-4)`, 6 round): what is not yet there. A new goal's
/// tile, the blank goal a form previews, the empty mark of a row before
/// it is saved. Dashed as Chrome dashes a border, 3 on about 2 off, fitted
/// round its corners. It says nothing; its child speaks.
///
/// ```dart
/// LedgerDashedFrame(padding: const EdgeInsets.all(18), child: Text('New goal'))
/// ```
class LedgerDashedFrame extends StatelessWidget {
  /// A dashed frame round [child].
  const LedgerDashedFrame({
    required this.child,
    this.padding = EdgeInsets.zero,
    super.key,
  });

  /// What the frame holds.
  final Widget child;

  /// Inside the dashes: 18 for a new goal's tile (`.goal-new`), 16 18 for
  /// a goal's blank preview (`.goal-blank`).
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    // `.goal-new`, `.goal-blank`, `.glyph-before`: 1px dashed --ink-4,
    // radius --r-sheet (6).
    return CustomPaint(
      painter: LedgerDashedOutline(
        radius: BorderRadius.circular(t.cardRadius),
        color: t.textFaint,
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

/// A day as a date tab (`.when`): the month in tracked mono capitals over
/// the day in the serif, on a small slip of the light paper, 40 by 44.
/// It names nothing to a screen reader; its row says the date.
///
/// ```dart
/// LedgerDateTab(DateTime(2026, 11, 1))
/// ```
class LedgerDateTab extends StatelessWidget {
  /// A date tab for [date].
  const LedgerDateTab(this.date, {super.key});

  /// The day shown.
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    // The slip grows with the reader's text size, as its words do.
    final grow = MediaQuery.textScalerOf(context).scale(_day) / _day;
    return ExcludeSemantics(
      child: Container(
        width: (_width * grow).roundToDouble(),
        height: (_height * grow).roundToDouble(),
        decoration: BoxDecoration(
          color: t.surface,
          border: Border.all(color: t.border),
          borderRadius: BorderRadius.circular(t.smallRadius),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              LedgerFormat.month(date, short: true).toUpperCase(),
              style: t.meta
                  .sized(_month)
                  .line(_monthLine)
                  .tracked(_monthTracking)
                  .medium,
            ),
            Text(
              '${date.day}',
              style: t.figureSmall
                  .sized(_day)
                  .line(_day)
                  .tracked(0)
                  .colored(t.textPrimary),
            ),
          ],
        ),
      ),
    );
  }

  // `.when`: 40 by 44; `.m` 500 8.5/10 mono, .08em; `.d` the serif 20/20.
  static const double _width = 40;
  static const double _height = 44;
  static const double _month = 8.5;
  static const double _monthLine = 10;
  static const double _monthTracking = .08;
  static const double _day = 20;
}

/// Which wash a [LedgerPill] stands on: the [success] (good news, a state
/// on track), the vermilion [over] (past a budget), the [plain] (a plain
/// state: behind, on autopay).
enum LedgerPillTone {
  /// The green wash: good news, a state on track.
  success,

  /// The vermilion wash: past a budget.
  over,

  /// The plain wash: a plain state (behind, on autopay).
  plain,
}

/// How large a [LedgerPill] stands: [regular] 24 tall (a figure's
/// change), [small] 20 (a goal's status beside its note).
enum LedgerPillSize {
  /// 24 tall: a figure's change.
  regular,

  /// 20 tall: a goal's status beside its note.
  small,
}

/// A figure's change or a record's state in the mono on its wash, round
/// (`.pill`): +3.86%, −6% vs September, Autopay on. It never acts.
///
/// ```dart
/// LedgerPill('+3.86%')
/// ```
///
/// ```dart
/// LedgerPill('Behind', tone: LedgerPillTone.plain, size: LedgerPillSize.small)
/// ```
class LedgerPill extends StatelessWidget {
  /// A pill worded [text].
  const LedgerPill(
    this.text, {
    this.tone = LedgerPillTone.success,
    this.size = LedgerPillSize.regular,
    super.key,
  });

  /// The pill's words.
  final String text;

  /// Which wash it stands on.
  final LedgerPillTone tone;

  /// How large it stands.
  final LedgerPillSize size;

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    final small = size == LedgerPillSize.small;
    final (ink, wash) = switch (tone) {
      LedgerPillTone.success => (t.accent, t.accentSubtle),
      LedgerPillTone.over => (t.over, t.dangerSubtle),
      LedgerPillTone.plain => (t.textSecondary, t.surfaceAlt),
    };
    final words = small ? t.pill.sized(_smallText).line(_smallText) : t.pill;
    // At a large text size the wash grows with its words rather than cut
    // them: its height is the least it stands.
    final larger = MediaQuery.textScalerOf(context).scale(1) > 1;
    final height = small ? _smallHeight : _height;
    return Container(
      height: larger ? null : height,
      constraints: larger ? BoxConstraints(minHeight: height) : null,
      padding: EdgeInsets.symmetric(horizontal: small ? _smallPad : _pad),
      decoration: BoxDecoration(
        color: wash,
        borderRadius: BorderRadius.circular(t.controlRadius),
      ),
      // Its own width under a loose one: a Container's alignment would stretch
      // it.
      child: Center(
        widthFactor: 1,
        heightFactor: larger ? 1 : null,
        child: Text(
          text,
          maxLines: 1,
          softWrap: false,
          style: words.colored(ink),
        ),
      ),
    );
  }

  // `.pill`: 24 tall, 0 10, 500 12/1 mono; `.goal-note .pill` 20, 0 8, 11.
  static const double _height = 24;
  static const double _pad = 10;
  static const double _smallHeight = 20;
  static const double _smallPad = 8;
  static const double _smallText = 11;
}

/// How a [LedgerTag] is ringed: [plain] in the faint ink (Pending), or
/// [unread] in the green (New).
enum LedgerTagTone {
  /// Ringed in the faint ink (Pending).
  plain,

  /// Ringed in the green (New).
  unread,
}

/// A word ringed small after a title in mono capitals (`.tag`): Pending
/// after a purchase not yet posted, New after an unread notification.
///
/// ```dart
/// LedgerTag('Pending')
/// ```
class LedgerTag extends StatelessWidget {
  /// A tag worded [text].
  const LedgerTag(this.text, {this.tone = LedgerTagTone.plain, super.key});

  /// The tag's words, set in capitals.
  final String text;

  /// How it is ringed.
  final LedgerTagTone tone;

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    final unread = tone == LedgerTagTone.unread;
    // At a large text size the ring grows with its word rather than cut it:
    // its 18 is the least it stands.
    final larger = MediaQuery.textScalerOf(context).scale(1) > 1;
    return Container(
      height: larger ? null : _height,
      constraints: larger ? const BoxConstraints(minHeight: _height) : null,
      padding: const EdgeInsets.symmetric(horizontal: _pad),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(t.controlRadius),
        border: Border.all(color: unread ? t.accentRule : t.textFaint),
      ),
      // Its own width under a loose one: a Container's alignment would stretch
      // it.
      child: Center(
        widthFactor: 1,
        heightFactor: larger ? 1 : null,
        // A mark beside a title, its word grows to [textScale] at most: at
        // the page's 200% its tracked capitals would outweigh the title and
        // run into the row's figure.
        child: MediaQuery.withClampedTextScaling(
          maxScaleFactor: textScale,
          child: Text(
            text.toUpperCase(),
            maxLines: 1,
            softWrap: false,
            style: t.tag.colored(unread ? t.accent : t.textSecondary),
          ),
        ),
      ),
    );
  }

  /// The most a tag's word grows with the reader's text (130%).
  static const double textScale = 1.3;

  // `.tag`: 18 tall, 0 7, a 1 px ring.
  static const double _height = 18;
  static const double _pad = 7;
}
