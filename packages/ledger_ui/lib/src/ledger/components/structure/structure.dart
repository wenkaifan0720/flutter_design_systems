import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../chrome_metrics.dart';
import '../../format.dart';
import '../../internal/cap_center.dart';
import '../../internal/end_glyph.dart';
import '../../internal/leader.dart';
import '../../internal/whole_pixel.dart';
import '../../theme.dart';
import '../money/money.dart';
import '../pressable/pressable.dart';

/// [text] with its `**strong**` runs set in [strong]: how a page's words
/// mark the part the source sets in `<b>`.
TextSpan ledgerMarked(String text, TextStyle base, TextStyle strong) {
  final parts = text.split('**');
  return TextSpan(
    style: base,
    children: [
      for (var i = 0; i < parts.length; i++)
        if (parts[i].isNotEmpty)
          TextSpan(text: parts[i], style: i.isOdd ? strong : null),
    ],
  );
}

/// A section's head (`.head`): the ink rule across the column, 11 under it
/// the [label] in the tracked capitals, a footnote mark beside it, and at
/// its end a mono [note] (Balance, Day 28 of 31), the note as a green link
/// with its chevron when [onTap] is set (All bills, View all), or a
/// [trailing] control (the range chips). [LedgerHead.hero], a page's first
/// head, centres its parts 10 under the rule; a [faintRule] head draws its
/// rule in the hairline's ink. The label is read as a heading.
///
/// ```dart
/// LedgerHead('Accounts', note: 'Balance')
/// ```
///
/// ```dart
/// LedgerHead('Upcoming · 15 days', note: 'All bills', onTap: () => open('/bills'))
/// ```
///
/// ```dart
/// LedgerHead.hero('Net worth', footnote: '1', trailing: range)
/// ```
class LedgerHead extends StatelessWidget {
  /// A section's head.
  const LedgerHead(
    this.label, {
    this.note,
    this.onTap,
    this.linkLabel,
    this.footnote,
    this.trailing,
    this.faintRule = false,
    this.linkKey,
    super.key,
  }) : _hero = false;

  /// A page's first head: its parts centred, 10 under the rule.
  const LedgerHead.hero(
    this.label, {
    this.note,
    this.onTap,
    this.linkLabel,
    this.footnote,
    this.trailing,
    this.faintRule = false,
    this.linkKey,
    super.key,
  }) : _hero = true;

  /// The rubric, set in capitals.
  final String label;

  /// The words at the head's end; a link's words when [onTap] is set.
  final String? note;

  /// Makes the [note] a link to where the section goes on.
  final VoidCallback? onTap;

  /// The link's spoken name when the note alone says too little.
  final String? linkLabel;

  /// A footnote's mark after the label (`1`), its note under the page.
  final String? footnote;

  /// A control at the head's end in place of the note.
  final Widget? trailing;

  final bool _hero;

  /// Ruled in the hairline's ink rather than the ink.
  final bool faintRule;

  /// The walkthrough key set on the link's hit target (the note with
  /// [onTap]; `.head-link`), not on the whole head.
  final Key? linkKey;

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    final rubric = Semantics(
      header: true,
      child: Text.rich(
        TextSpan(
          text: label.toUpperCase(),
          style: t.label,
          children: [
            if (footnote case final mark?)
              WidgetSpan(
                alignment: PlaceholderAlignment.baseline,
                baseline: TextBaseline.alphabetic,
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(start: _markGap),
                  child: Transform.translate(
                    offset: const Offset(0, -_markRise),
                    // A mark, not a figure: it grows to 130% at most.
                    child: MediaQuery.withClampedTextScaling(
                      maxScaleFactor: _markScale,
                      child: Text(mark, style: t.footnote),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
    final Widget? end =
        trailing ??
        switch (note) {
          null => null,
          final words when onTap != null => _HeadLink(
            words: words,
            label: linkLabel ?? words,
            onTap: onTap!,
            linkKey: linkKey,
          ),
          final words => Text(words.toUpperCase(), style: t.meta),
        };
    final larger = MediaQuery.textScalerOf(context).scale(1) > 1;
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: faintRule ? t.border : t.headRule),
        ),
      ),
      padding: EdgeInsets.only(
        top: _hero ? _heroTop : LedgerChromeMetrics.headTop,
      ),
      // At a large text size the note turns under the rubric when the two
      // do not fit one line, rather than squeeze the rubric's words apart.
      // The rubric's sans and the note's mono on one baseline stand 16.12
      // tall: held to a whole pixel, so the section under it is too.
      child: larger && end != null
          ? Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: LedgerChromeMetrics.headGap,
              runSpacing: _runGap,
              children: [rubric, end],
            )
          : LedgerWholeHeight(
              child: Row(
                crossAxisAlignment: _hero
                    ? CrossAxisAlignment.center
                    : CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                spacing: LedgerChromeMetrics.headGap,
                children: [
                  Flexible(child: rubric),
                  ?end,
                ],
              ),
            ),
    );
  }

  // `.hero .head`: centred, 10 under the rule; `.fn`: 3 after the label,
  // raised 5 (vertical-align: 5px).
  static const double _heroTop = 10;
  static const double _runGap = 4;
  static const double _markGap = 3;
  static const double _markRise = 5;
  static const double _markScale = 1.3;
}

class _HeadLink extends StatelessWidget {
  const _HeadLink({
    required this.words,
    required this.label,
    required this.onTap,
    this.linkKey,
  });

  final String words;
  final String label;
  final VoidCallback onTap;
  final Key? linkKey;

  @override
  Widget build(BuildContext context) {
    // `.head-link` hung its chevron 3 past the column (margin-right -3);
    // the link's chevron now sets its own ink on the column's end
    // (LedgerEndGlyph), so the link stands in the column.
    return LedgerMoreLink(words, key: linkKey, label: label, onTap: onTap);
  }
}

/// A link standing on its own under what it closes (`a.head-link.more`:
/// "See all 13 visits"): its [words] in
/// the green mono capitals (500 11 on 16, tracked .04em), the 14 chevron 2
/// after them; the link a head's note draws, outside a head. [label] names
/// it when its words say too little; its key sits on its hit target.
///
/// ```dart
/// LedgerMoreLink('See all 13 visits', onTap: () => open('/activity/search'))
/// ```
class LedgerMoreLink extends StatelessWidget {
  /// A link worded [words] that calls [onTap].
  const LedgerMoreLink(
    this.words, {
    required this.onTap,
    this.label,
    super.key,
  });

  /// The link's words, set in capitals.
  final String words;

  /// Where it goes; null draws it inert.
  final VoidCallback? onTap;

  /// Its spoken name; null speaks its words.
  final String? label;

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    return LedgerPressable(
      onTap: onTap,
      role: LedgerPressRole.link,
      label: label ?? words,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: LedgerChromeMetrics.linkGap,
        children: [
          // `.head-link`: white-space nowrap.
          Text(words.toUpperCase(), softWrap: false, style: t.link),
          LedgerEndGlyph(
            LucideIcons.chevronRight,
            size: LedgerChromeMetrics.linkGlyph,
            color: t.accentText,
          ),
        ],
      ),
    );
  }
}

/// A section of a page: its [head], then 8 under it what it holds.
///
/// ```dart
/// LedgerSection(head: const LedgerHead('Goals', note: '3 active'), child: goals)
/// ```
class LedgerSection extends StatelessWidget {
  /// A section: [head] over [child].
  const LedgerSection({required this.head, required this.child, super.key});

  /// The section's head, usually a [LedgerHead].
  final Widget head;

  /// What the section holds.
  final Widget child;

  // Its rows start on its edge and end on its other (design6 P), so the
  // keyline check reads it as one region, named by its head.
  @override
  Widget build(BuildContext context) => DesignKeylineRegion(
    label: switch (head) {
      final LedgerHead h => h.label,
      _ => null,
    },
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        head,
        const SizedBox(height: LedgerChromeMetrics.headAfter),
        child,
      ],
    ),
  );
}

/// A ledger's rows (`.ledger`): one under another, the hairline between
/// each, none after the last. [divided] false stands them with no rules
/// (a list of lit rows).
///
/// ```dart
/// LedgerRows(children: [for (final a in accounts) LedgerRow(title: a.name, value: LedgerAmount(a.balance))])
/// ```
class LedgerRows extends StatelessWidget {
  /// Rows, the hairline between each unless not [divided].
  const LedgerRows({required this.children, this.divided = true, super.key});

  /// The rows, usually [LedgerRow]s.
  final List<Widget> children;

  /// Whether a hairline stands between the rows.
  final bool divided;

  @override
  Widget build(BuildContext context) {
    final rule = context.ledgerTheme.hairline;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0 && divided)
            ColoredBox(color: rule, child: const SizedBox(height: 1)),
          children[i],
        ],
      ],
    );
  }
}

/// The ledger row (`.row`): a [leading] (a monogram, a glyph or a date tab),
/// the [title] joined to its [value] by the dot leader, and under them two sub
/// lines, [subtitle] and [trailingSubtitle] (in the mono, or green, as their
/// tones say), 14 above and below. [onTap] makes the whole row one link;
/// [semanticLabel] names it when its words say too little. Stand rows in
/// [LedgerRows] for the hairlines between them.
///
/// ```dart
/// LedgerRow(leading: const LedgerGlyph(LucideIcons.wallet), title: 'Everyday', value: const LedgerAmount(6248.30), subtitle: 'Checking ··4821', subtitleMonospace: true)
/// ```
class LedgerRow extends StatelessWidget {
  /// A row titled [title].
  const LedgerRow({
    required this.title,
    this.leading,
    this.value,
    this.subtitle,
    this.trailingSubtitle,
    this.subtitleMonospace = false,
    this.subtitleTone = LedgerTone.plain,
    this.trailingSubtitleTone = LedgerTone.plain,
    this.tag,
    this.trailing,
    this.onTap,
    this.semanticLabel,
    this.focusNode,
    this.autofocus = false,
    super.key,
  });

  /// The row's words, joined to its [value] by the dot leader.
  final String title;

  /// A mark before the words (a glyph, a monogram).
  final Widget? leading;

  /// The value at the line's end, on the leader (a [LedgerAmount]).
  final Widget? value;

  /// The sub line's start words.
  final String? subtitle;

  /// The sub line's end words.
  final String? trailingSubtitle;

  /// The start words in the mono (an account's kind and mask).
  final bool subtitleMonospace;

  /// The ink of the sub line's start words.
  final LedgerTone subtitleTone;

  /// The ink of the sub line's end words.
  final LedgerTone trailingSubtitleTone;

  /// A tag after the title (Pending).
  final Widget? tag;

  /// A mark at the row's end (a chevron, a switch).
  final Widget? trailing;

  /// Makes the whole row one link.
  final VoidCallback? onTap;

  /// The control's focus; null keeps one of its own. The caller disposes
  /// the node it gives.
  final FocusNode? focusNode;

  /// Whether it takes focus when it first appears.
  final bool autofocus;

  /// What a screen reader says when the row's words say too little.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    final name = ledgerTitle(context, title, tag: tag);
    final line = value == null
        ? name
        : LedgerLeaderLine(start: name, end: value!);
    final sub = ledgerSubLine(
      context,
      start: subtitle,
      end: trailingSubtitle,
      startMono: subtitleMonospace,
      startTone: subtitleTone,
      endTone: trailingSubtitleTone,
    );
    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: _pad),
      child: Row(
        spacing: _gap,
        children: [
          ?leading,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                line,
                if (sub != null) ...[const SizedBox(height: _subTop), sub],
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
    if (onTap == null) {
      return semanticLabel == null
          ? MergeSemantics(child: row)
          : Semantics(label: semanticLabel, excludeSemantics: true, child: row);
    }
    return MergeSemantics(
      child: LedgerPressable(
        focusNode: focusNode,
        autofocus: autofocus,
        onTap: onTap,
        role: LedgerPressRole.link,
        label: semanticLabel,
        excludeChild: semanticLabel != null,
        child: ColoredBox(color: t.background.withValues(alpha: 0), child: row),
      ),
    );
  }

  // `.row`: 14 0, its parts 14 apart; `.sub` 3 under the line.
  static const double _pad = 14;
  static const double _gap = 14;
  static const double _subTop = 3;
}

/// A row's title (`.title`, 500 15 on 20), a [tag] 8 after it raised 2,
/// as the rows set it. Plumbing of the rows.
Widget ledgerTitle(
  BuildContext context,
  String title, {
  Widget? tag,
  TextStyle? style,
  int? maxLines,
}) {
  final t = context.ledgerTheme;
  final words = Text.rich(
    TextSpan(
      text: title,
      children: [
        if (tag != null)
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Padding(
              padding: const EdgeInsetsDirectional.only(start: 8),
              child: Transform.translate(
                offset: const Offset(0, -1),
                child: tag,
              ),
            ),
          ),
      ],
    ),
    maxLines: maxLines,
    overflow: maxLines == null ? null : TextOverflow.ellipsis,
    style: style ?? t.rowTitle,
  );
  // A title cut to its lines ellipsizes; one that wraps breaks no word.
  return maxLines == null ? _WholeWords(child: words) : words;
}

/// Lays its words out no narrower than their longest word, as CSS breaks
/// no word (`.row-main .line > .title { min-width: 0; white-space:
/// normal }`): a lone word wider than the room stands
/// whole and runs past its box's end, into the leader's margin, where
/// Flutter would break it letter by letter. Its own box keeps the room it
/// was given, so the leader and the value stand where they would.
class _WholeWords extends SingleChildRenderObjectWidget {
  const _WholeWords({required super.child});

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderWholeWords(Directionality.of(context));

  @override
  void updateRenderObject(BuildContext context, _RenderWholeWords box) =>
      box.textDirection = Directionality.of(context);
}

class _RenderWholeWords extends RenderShiftedBox {
  _RenderWholeWords(this._textDirection) : super(null);

  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    if (value == _textDirection) return;
    _textDirection = value;
    markNeedsLayout();
  }

  /// The room, widened to the longest word when that is wider.
  BoxConstraints _inner(RenderBox words, BoxConstraints c) {
    if (!c.hasBoundedWidth) return c;
    final word = words.getMinIntrinsicWidth(double.infinity);
    return word <= c.maxWidth ? c : c.copyWith(maxWidth: word);
  }

  @override
  void performLayout() {
    final words = child;
    if (words == null) {
      size = constraints.smallest;
      return;
    }
    words.layout(_inner(words, constraints), parentUsesSize: true);
    size = constraints.constrain(words.size);
    // The overflow runs past the end: right in a left-to-right line.
    (words.parentData! as BoxParentData).offset = Offset(
      _textDirection == TextDirection.rtl ? size.width - words.size.width : 0,
      0,
    );
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final words = child;
    if (words == null) return constraints.smallest;
    return constraints.constrain(
      words.getDryLayout(_inner(words, constraints)),
    );
  }

  @override
  double? computeDryBaseline(
    BoxConstraints constraints,
    TextBaseline baseline,
  ) {
    final words = child;
    return words?.getDryBaseline(_inner(words, constraints), baseline);
  }
}

/// A row's sub line (`.sub`, 13 on 18 in the third ink): its start words
/// and its end words at the far side, 12 apart at least; null with
/// neither. Plumbing of the rows.
Widget? ledgerSubLine(
  BuildContext context, {
  String? start,
  String? end,
  bool startMono = false,
  LedgerTone startTone = LedgerTone.plain,
  LedgerTone endTone = LedgerTone.plain,
}) {
  if ((start == null || start.isEmpty) && (end == null || end.isEmpty)) {
    return null;
  }
  final t = context.ledgerTheme;
  Color ink(LedgerTone tone) => switch (tone) {
    LedgerTone.moneyIn => t.moneyIn,
    LedgerTone.over => t.over,
    _ => t.textTertiary,
  };
  final base = t.bodySmall;
  final strong = base.medium.colored(t.textSecondary);
  // `.sub .mono`: the mono at 12, untracked, on the line's 18.
  final mono = t.amount
      .sized(_mono)
      .tracked(0)
      .line(base.fontSize! * base.height!)
      .copyWith(fontWeight: FontWeight.w400);
  final startSpan = start == null || start.isEmpty
      ? null
      : ledgerMarked(
          start,
          (startMono ? mono : base).colored(ink(startTone)),
          strong,
        );
  final endSpan = end == null || end.isEmpty
      ? null
      : ledgerMarked(end, base.colored(ink(endTone)), strong);
  // Each end's share of the row is its own width's (CSS's flex-shrink over
  // its flex-basis): both stand whole while they fit, and give way in
  // proportion, the end words wrapping against the row's end, when not.
  final scaler = MediaQuery.textScalerOf(context);
  final direction = Directionality.of(context);
  int share(InlineSpan span) {
    final p = TextPainter(
      text: span,
      textDirection: direction,
      textScaler: scaler,
    )..layout();
    final w = p.width;
    p.dispose();
    return math.max(1, (w * 100).ceil());
  }

  // At a large text size the two give way by turning rather than squeezing
  // (a squeezed word breaks letter by letter): the end words stand under the
  // start's when both do not fit one line.
  if (scaler.scale(1) > 1 && startSpan != null && endSpan != null) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.end,
      spacing: _gap,
      children: [
        Text.rich(startSpan),
        Text.rich(endSpan, textAlign: TextAlign.end),
      ],
    );
  }
  // The mono and the sans on one baseline stand 18.23 tall: held to a whole
  // pixel, so the row, its rule and every row under it are too.
  return LedgerWholeHeight(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (startSpan != null)
          Flexible(
            flex: endSpan == null ? 1 : share(startSpan),
            child: Text.rich(startSpan),
          ),
        if (endSpan != null) ...[
          const SizedBox(width: _gap),
          Flexible(
            flex: startSpan == null ? 1 : share(endSpan),
            child: Text.rich(endSpan, textAlign: TextAlign.end),
          ),
        ],
      ],
    ),
  );
}

const double _mono = 12;
const double _gap = 12;

/// A record's key and its value on the dot leader (`.kv`): the key in the
/// second ink, the value medium (in the mono when [monospace]: a mask), and an
/// [action] 10 beside it (Change), 11 above and below. The key and the
/// value read as one line; the action is its own button beside it. Stand
/// them in [LedgerRows].
///
/// ```dart
/// LedgerKeyValue('Status', 'Pending')
/// ```
///
/// ```dart
/// LedgerKeyValue('Account', '··4821', monospace: true)
/// ```
class LedgerKeyValue extends StatelessWidget {
  /// A detail: [name] and its [value].
  const LedgerKeyValue(
    this.name,
    this.value, {
    this.monospace = false,
    this.action,
    super.key,
  });

  /// The detail's name, in the second ink.
  final String name;

  /// The detail's value.
  final String value;

  /// Whether the value is set in the mono (a mask, a number).
  final bool monospace;

  /// A quiet act beside the value (Change).
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    final words = t.rowTitle;
    final figure = monospace
        ? t.amount.sized(_monoSize).tracked(0).line(_line)
        : words;
    final wraps = !monospace && MediaQuery.textScalerOf(context).scale(1) > 1;
    // The key and its value read as one node; the action (Change) stands
    // outside the merge as its own button, as the source's separate
    // "Change category" button, so a tap on its node
    // reaches it.
    final line = MergeSemantics(
      child: LedgerLeaderLine(
        start: Text(
          name,
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.ellipsis,
          style: words
              .copyWith(fontWeight: FontWeight.w400)
              .colored(t.textSecondary),
        ),
        // At a large text size, turned under its key, a value of words wraps
        // whole rather than run past the slip's edge; a mask stays one line.
        end: Text(
          value,
          maxLines: wraps ? null : 1,
          softWrap: wraps,
          style: figure,
        ),
      ),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: _pad),
      child: action == null
          ? line
          : Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              spacing: _actionGap,
              children: [
                Expanded(child: line),
                action!,
              ],
            ),
    );
  }

  // `.kv`: 11 0, 15/20; `.kv-v .mono` 13 medium; the action 10 after it.
  static const double _pad = 11;
  static const double _line = 20;
  static const double _monoSize = 13;
  static const double _actionGap = 10;
}

/// How a [LedgerFacts] stands its facts: [two] across (one under another
/// on the desktop's margin), [three] across (likewise), or [pair]: two
/// across everywhere (`.facts-2`), under the ink rule only where no head
/// stands over it ([LedgerFacts.ruled]), as on a phone.
enum LedgerFactColumns {
  /// Two across; one under another on the desktop's margin.
  two,

  /// Three across; one under another on the desktop's margin.
  three,

  /// Two across everywhere, under the ink rule only where no head stands over
  /// it.
  pair,
}

/// One fact of a [LedgerFacts]: its [label] in the capitals, its value in
/// the serif (money with its cents set smaller), and its [note].
///
/// ```dart
/// LedgerFact.money('Left', 213.88, note: '3 days to go')
/// ```
///
/// ```dart
/// LedgerFact('Pace', '90%', note: 'Day 28 of 31; 92% spent')
/// ```
class LedgerFact {
  /// A fact worded [text], under its [label] and over its [note].
  const LedgerFact(
    this.label,
    String this.text, {
    required this.note,
    this.tone = LedgerTone.plain,
  }) : amount = null,
       showSign = false,
       showCents = true;

  /// A sum: its dollars, and its cents set smaller (`fact_money`).
  const LedgerFact.money(
    this.label,
    num this.amount, {
    required this.note,
    this.showSign = false,
    this.showCents = true,
    this.tone = LedgerTone.plain,
  }) : text = null;

  /// The fact's name, in the capitals.
  final String label;

  /// The fact's words, when it is not money.
  final String? text;

  /// The fact's money, when it is ([LedgerFact.money]).
  final num? amount;

  /// Whether the money shows its sign.
  final bool showSign;

  /// Whether the money shows its cents.
  final bool showCents;

  /// A line under the fact.
  final String note;

  /// [LedgerTone.moneyIn] sets it green, [LedgerTone.over] vermilion.
  final LedgerTone tone;
}

/// A record's facts at a glance (`.facts`): each a label, a figure in the
/// serif and a note, ruled in a grid of [columns] on a phone (the ink rule
/// over them when [ruled]: no head stands above them), one under another
/// in the desktop's margin (a [LedgerFactColumns.pair] two across there
/// too, under the ink rule when [ruled]). Read fact by fact.
///
/// ```dart
/// LedgerFacts(facts: [LedgerFact.money('Left', 213.88, note: '3 days to go'), LedgerFact('Pace', '90%', note: 'Day 28 of 31')])
/// ```
class LedgerFacts extends StatelessWidget {
  /// The [facts], laid in [columns].
  const LedgerFacts({
    required this.facts,
    this.columns = LedgerFactColumns.two,
    this.ruled = false,
    super.key,
  });

  /// The facts, in order.
  final List<LedgerFact> facts;

  /// How the facts stand.
  final LedgerFactColumns columns;

  /// Whether the ink rule stands over them (no head stands above).
  final bool ruled;

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    final wide = LedgerLayout.isWide(context);
    // At a large text size a phone's facts stand one under another, as the
    // desktop's do, rather than break their words to fit a third of a line.
    final larger = MediaQuery.textScalerOf(context).scale(1) > 1;
    final stacked = (wide || larger) && columns != LedgerFactColumns.pair;
    final across = stacked
        ? 1
        : columns == LedgerFactColumns.three
        ? 3
        : 2;
    final (size, line, cents) = switch ((stacked, columns, wide)) {
      (true, _, _) => (32.0, 34.0, 18.0),
      (false, LedgerFactColumns.three, _) => (24.0, 28.0, 15.0),
      _ => (28.0, 30.0, 18.0),
    };
    final rule = BorderSide(color: t.border);
    Widget cell(int i) {
      final at = i % across;
      final last = at == across - 1;
      // The rule between two facts stands at a cell's end, so in a
      // right-to-left page it still parts them rather than close the row.
      final EdgeInsetsDirectional pad;
      if (stacked) {
        pad = EdgeInsetsDirectional.only(
          top: i == 0 ? _firstTop : _top,
          bottom: _top,
        );
      } else if (across == 3) {
        pad = EdgeInsetsDirectional.only(
          start: at == 0 ? 0 : _three,
          end: last ? 0 : _three,
          top: _cellTop,
          bottom: _cellFoot,
        );
      } else {
        pad = EdgeInsetsDirectional.only(
          start: at == 0 ? 0 : _two,
          end: at == 0 ? _two : 0,
          top: _cellTop,
          bottom: _cellFoot,
        );
      }
      return Container(
        padding: pad,
        decoration: BoxDecoration(
          border: BorderDirectional(
            bottom: rule,
            end: !stacked && !last ? rule : BorderSide.none,
          ),
        ),
        child: _Fact(facts[i], size: size, line: line, cents: cents),
      );
    }

    final rows = <Widget>[
      for (var r = 0; r < facts.length; r += across)
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = r; i < r + across; i++)
                Expanded(
                  child: i < facts.length ? cell(i) : const SizedBox.shrink(),
                ),
            ],
          ),
        ),
    ];
    // `.facts` draws the ink rule; `.head:not(.desk) + .facts` drops it
    // under a head, the desktop's pair too (its
    // `.facts-2` rule, loses to that selector); the
    // desktop's stacked facts draw none.
    final topRule = ruled && (!wide || columns == LedgerFactColumns.pair);
    return Container(
      decoration: topRule
          ? BoxDecoration(
              border: Border(top: BorderSide(color: t.headRule)),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: rows,
      ),
    );
  }

  // `.fact`: 14 0 16, 16 either side of its rule; `.facts-3` 12; the
  // desktop's 16 0 (the first 6 over).
  static const double _cellTop = 14;
  static const double _cellFoot = 16;
  static const double _two = 16;
  static const double _three = 12;
  static const double _top = 16;
  static const double _firstTop = 6;
}

class _Fact extends StatelessWidget {
  const _Fact(
    this.fact, {
    required this.size,
    required this.line,
    required this.cents,
  });

  final LedgerFact fact;
  final double size;
  final double line;
  final double cents;

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    final ink = switch (fact.tone) {
      LedgerTone.moneyIn => t.moneyIn,
      LedgerTone.over => t.over,
      _ => t.textPrimary,
    };
    final figure = t.figureSmall.sized(size).line(line).tracked(0).colored(ink);
    final InlineSpan value;
    if (fact.amount case final amount?) {
      final parts = LedgerFormat.moneyParts(amount, showSign: fact.showSign);
      final whole = fact.showCents
          ? '${parts.sign}\$${parts.whole}'
          : LedgerFormat.money(
              amount,
              showCents: false,
              showSign: fact.showSign,
            );
      value = TextSpan(
        text: whole,
        children: [
          if (fact.showCents)
            TextSpan(
              text: '.${parts.cents}',
              style: TextStyle(
                fontSize: cents,
                // `.fact .v .c` keeps the figure's line in px (`.v`'s
                // 28px/30px): the cents' own half-leading
                // drops the line's foot under the figure's, as CSS's
                // inline box does (3.4 deeper at 28/18).
                height: line / cents,
                // `.v.pos .c`: the green at .75; else the second ink.
                color: fact.tone == LedgerTone.moneyIn
                    ? t.moneyIn.withValues(alpha: .75)
                    : t.textSecondary,
              ),
            ),
        ],
      );
    } else {
      value = TextSpan(text: fact.text);
    }
    return MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(fact.label.toUpperCase(), style: t.label),
          const SizedBox(height: _valueTop),
          // A figure wider than its column is set smaller, never cut. It
          // reads left to right in any page, its sign before it ("−6%").
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text.rich(
              value,
              maxLines: 1,
              softWrap: false,
              textDirection: TextDirection.ltr,
              style: figure,
            ),
          ),
          const SizedBox(height: _noteTop),
          Text(fact.note, style: t.bodySmall),
        ],
      ),
    );
  }

  // `.fact .v` 6 under the label; `.s` 2 under the value.
  static const double _valueTop = 6;
  static const double _noteTop = 2;
}

/// One footnote of a [LedgerNotes]: its [mark] and its words.
///
/// ```dart
/// LedgerNote('1', 'Sum of five accounts.')
/// ```
class LedgerNote {
  /// A footnote marked [mark], worded [text].
  const LedgerNote(this.mark, this.text);

  /// The footnote's mark, matching a head's `footnote`.
  final String mark;

  /// Its words, `**strong**` runs set in the ink.
  final String text;
}

/// A page's footnotes (`.notes`): each mark in the green mono hung in its
/// 10 wide column, its words in the second ink, 8 apart: marginalia on the
/// desktop, under the section on a phone.
///
/// ```dart
/// LedgerNotes(notes: [LedgerNote('1', 'Sum of five accounts.')])
/// ```
class LedgerNotes extends StatelessWidget {
  /// A page's [notes].
  const LedgerNotes({required this.notes, super.key});

  /// The footnotes, in order.
  final List<LedgerNote> notes;

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    final words = t.bodySmall.colored(t.textSecondary);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: _gap,
      children: [
        for (final note in notes)
          MergeSemantics(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: _gap,
              children: [
                SizedBox(
                  width: _markWidth,
                  child: Text(
                    note.mark,
                    style: t.footnote.line(words.fontSize! * words.height!),
                  ),
                ),
                Expanded(
                  child: Text.rich(
                    ledgerMarked(
                      note.text,
                      words,
                      words.colored(t.textPrimary),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // `.notes` 8 apart; `.note` 8 after its 10 wide mark.
  static const double _gap = 8;
  static const double _markWidth = 10;
}

/// A record's head (`.rec-head`): its [leading] (a [LedgerGlyph] or a
/// [LedgerMonogram] at record size) and beside it the record's [name] in
/// the serif, 30 (40 on the desktop), its [subtitle] under it with a [mono]
/// part (the mask). The name is read as a heading.
///
/// ```dart
/// LedgerRecordHead(leading: const LedgerGlyph(LucideIcons.wallet, size: LedgerGlyphSize.record), name: 'Everyday', subtitle: 'Checking ··4821')
/// ```
class LedgerRecordHead extends StatelessWidget {
  /// A record's head: its [leading] beside its [name].
  const LedgerRecordHead({
    required this.leading,
    required this.name,
    this.subtitle,
    this.mono,
    super.key,
  });

  /// The record's mark before its name (a monogram, a glyph).
  final Widget leading;

  /// The record's name, read as a heading.
  final String name;

  /// The words under the name.
  final String? subtitle;

  /// Words set in the mono after the [subtitle] (`··9015`).
  final String? mono;

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    final wide = LedgerLayout.isWide(context);
    final title = wide
        ? t.title.sized(_nameWide).line(_nameLineWide)
        : t.title.line(_nameLine);
    final base = t.bodySmall;
    return Row(
      spacing: _gap,
      children: [
        leading,
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(header: true, child: Text(name, style: title)),
              if (subtitle != null || mono != null) ...[
                const SizedBox(height: _subTop),
                Text.rich(
                  TextSpan(
                    style: base,
                    children: [
                      // The space before the mask is the sub's
                      // (`APY · <span class=mono>··9015</span>`).
                      if (subtitle case final words?)
                        TextSpan(text: mono == null ? words : '$words '),
                      if (mono case final code?)
                        TextSpan(
                          text: code,
                          style: t.amount
                              .sized(_monoSize)
                              .tracked(0)
                              .line(base.fontSize! * base.height!)
                              .copyWith(
                                fontWeight: FontWeight.w400,
                                color: base.color,
                              ),
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // `.rec-head` 14 apart; `.rec-name` 30/32 (40/42); `.rec-sub` 3 under,
  // its `.mono` 12.
  static const double _gap = 14;
  static const double _nameLine = 32;
  static const double _nameWide = 40;
  static const double _nameLineWide = 42;
  static const double _subTop = 3;
  static const double _monoSize = 12;
}

/// Where a register runs back into an earlier month (`.month-rule`): the
/// ink rule, 12 under it the month in the capitals and a mono [note] at
/// the end (Last month).
///
/// ```dart
/// LedgerMonthRule('September 2026', note: 'Last month')
/// ```
class LedgerMonthRule extends StatelessWidget {
  /// A rule naming [month], with an optional [note].
  const LedgerMonthRule(this.month, {this.note, super.key});

  /// The month, in the capitals.
  final String month;

  /// Words at the rule's end, in the mono (Last month).
  final String? note;

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: t.headRule)),
      ),
      padding: const EdgeInsets.only(top: _top),
      // Two faces on one baseline, held to a whole pixel as the head is.
      child: LedgerWholeHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          // Never closer than the gap: at a large text size the month wraps.
          spacing: _gap,
          children: [
            Flexible(
              child: Semantics(
                header: true,
                child: Text(month.toUpperCase(), style: t.label),
              ),
            ),
            if (note case final words?)
              Text(words.toUpperCase(), style: t.meta),
          ],
        ),
      ),
    );
  }

  static const double _top = 12;
  static const double _gap = 12;
}

/// A flag under a section (`.flag`): a vermilion bead, the words with
/// their `**strong**` part in the vermilion (Dining out is **over by
/// $36.40**), and a chevron at the end; the whole line one link.
///
/// ```dart
/// LedgerFlag('Dining out is **over by \$36.40**', onTap: () {})
/// ```
class LedgerFlag extends StatelessWidget {
  /// A flag worded [text].
  const LedgerFlag(this.text, {this.onTap, super.key});

  /// The flag's words, their `**strong**` part in the vermilion.
  final String text;

  /// Makes the flag one link.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    final words = t.bodySmall.colored(t.textSecondary);
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: t.hairline)),
      ),
      padding: const EdgeInsets.only(top: _top),
      child: MergeSemantics(
        child: LedgerPressable(
          onTap: onTap,
          role: LedgerPressRole.link,
          excludeChild: false,
          child: Row(
            spacing: _gap,
            children: [
              Container(
                width: _bead,
                height: _bead,
                decoration: BoxDecoration(
                  color: t.danger,
                  shape: BoxShape.circle,
                ),
              ),
              Expanded(
                child: Text.rich(
                  ledgerMarked(text, words, words.semibold.colored(t.over)),
                ),
              ),
              LedgerEndGlyph(
                LucideIcons.chevronRight,
                size: _chevron,
                color: t.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // `.flag`: 12 under its hairline, its parts 10 apart; the bead 8, the
  // chevron 16.
  static const double _top = 12;
  static const double _gap = 10;
  static const double _bead = 8;
  static const double _chevron = 16;
}

/// One way of a [LedgerQuickActions]: its glyph, its words, where it
/// goes, and the walkthrough [key] its link carries (the source's
/// `.action` links).
///
/// ```dart
/// LedgerQuickAction(LucideIcons.arrowRightLeft, 'Transfer', onTap: () {}, key: const ValueKey('home-transfer'))
/// ```
class LedgerQuickAction {
  /// A way worded [label], with its [icon].
  const LedgerQuickAction(this.icon, this.label, {this.onTap, this.key});

  /// The way's glyph.
  final IconData icon;

  /// The way's words.
  final String label;

  /// Where the way goes.
  final VoidCallback? onTap;

  /// Set on the way's hit target (its whole link), on a phone and on the
  /// desktop alike.
  final Key? key;
}

/// The ways to move money (`.actions`): on a phone a strip ruled above
/// and below, each way a 44 ink ring over its words, hairlines between;
/// in the desktop's margin a list, each a 36 ring, its words and a
/// chevron, the hairline under each. Every way is a link.
///
/// ```dart
/// LedgerQuickActions(actions: [LedgerQuickAction(LucideIcons.arrowRightLeft, 'Transfer', onTap: () {})])
/// ```
class LedgerQuickActions extends StatelessWidget {
  /// The [actions], laid out for the window.
  const LedgerQuickActions({required this.actions, super.key});

  /// The ways, in order.
  final List<LedgerQuickAction> actions;

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    final wide = LedgerLayout.isWide(context);
    Widget ring(IconData icon, double round, double glyph) => Container(
      width: round,
      height: round,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: t.textPrimary),
      ),
      child: Icon(icon, size: glyph, color: t.textPrimary),
    );
    Widget press(LedgerQuickAction a, Widget child) => LedgerPressable(
      key: a.key,
      onTap: a.onTap,
      role: LedgerPressRole.link,
      label: a.label,
      child: ColoredBox(color: t.background.withValues(alpha: 0), child: child),
    );
    // At a large text size a phone's strip becomes the desktop's list: a
    // quarter of the line would break each way's name.
    if (wide || MediaQuery.textScalerOf(context).scale(1) > 1) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final a in actions)
            press(
              a,
              Container(
                padding: const EdgeInsets.symmetric(vertical: _deskPad),
                // The rule under it drawn over its foot, so its row stands on
                // the middle of the whole box.
                foregroundDecoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: t.hairline)),
                ),
                child: Row(
                  spacing: _deskGap,
                  children: [
                    ring(a.icon, _deskRing, _deskGlyph),
                    Expanded(
                      child: ledgerCapCenter(
                        t.rowTitle,
                        Text(
                          a.label,
                          style: t.rowTitle.sized(_deskText).line(_line),
                        ),
                      ),
                    ),
                    LedgerEndGlyph(
                      LucideIcons.chevronRight,
                      size: _chevron,
                      color: t.textFaint,
                    ),
                  ],
                ),
              ),
            ),
        ],
      );
    }
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: t.border),
          bottom: BorderSide(color: t.border),
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < actions.length; i++)
              Expanded(
                child: Container(
                  decoration: i == 0
                      ? null
                      : BoxDecoration(
                          border: BorderDirectional(
                            start: BorderSide(color: t.hairline),
                          ),
                        ),
                  child: press(
                    actions[i],
                    Padding(
                      padding: const EdgeInsets.only(top: _top, bottom: _foot),
                      child: Column(
                        spacing: _gap,
                        children: [
                          ring(actions[i].icon, _ring, _glyph),
                          Text(
                            actions[i].label,
                            textAlign: TextAlign.center,
                            style: t.rowTitle.sized(_text).line(_line),
                          ),
                        ],
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

  // `.action`: 16 0 14, 9 apart, 500 12.5/16; `.ring` 44, its glyph 19.
  // From 1024: 10 0, 14 apart, 14.5; the ring 36, its glyph 17; the
  // chevron 16.
  static const double _top = 16;
  static const double _foot = 14;
  static const double _gap = 9;
  static const double _text = 12.5;
  static const double _line = 16;
  static const double _ring = 44;
  static const double _glyph = 19;
  static const double _deskPad = 10;
  static const double _deskGap = 14;
  static const double _deskText = 14.5;
  static const double _deskRing = 36;
  static const double _deskGlyph = 17;
  static const double _chevron = 16;
}

/// A figure's change under it (`.delta`): an optional [rise] in the green
/// after its arrow, then each of [words] (their `**strong**` runs in the
/// ink), then a [pill], wrapping 10 apart, in the second ink at 15.
///
/// ```dart
/// LedgerDelta(rise: '\$2,904.18', words: ['this month'], pill: LedgerPill('+3.86%'))
/// ```
class LedgerDelta extends StatelessWidget {
  /// A change: a [rise], [words] and a [pill].
  const LedgerDelta({this.rise, this.words = const [], this.pill, super.key});

  /// The amount the figure rose by, set green after the arrow.
  final String? rise;

  /// The words after the rise, their `**strong**` runs in the ink.
  final List<String> words;

  /// A pill after the words (the percentage).
  final Widget? pill;

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    final base = t.body.colored(t.textSecondary);
    return Wrap(
      spacing: _gap,
      runSpacing: _runGap,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (rise case final up?)
          Row(
            mainAxisSize: MainAxisSize.min,
            spacing: _riseGap,
            children: [
              Icon(LucideIcons.arrowUpRight, size: _arrow, color: t.moneyIn),
              Text(up, style: base.semibold.colored(t.moneyIn)),
            ],
          ),
        for (final w in words)
          Text.rich(
            ledgerMarked(w, base, base.semibold.colored(t.textPrimary)),
          ),
        ?pill,
      ],
    );
  }

  // `.delta`: 6 10 apart; `.up` 4 after its 18 arrow, 600.
  static const double _gap = 10;
  static const double _runGap = 6;
  static const double _riseGap = 4;
  static const double _arrow = 18;
}

/// The dot leader alone, filling its width, centred on its line (a goal's
/// line, where the parts stand centred). Plumbing of the rows.
class LedgerLeaderFill extends StatelessWidget {
  /// The dot leader across its width.
  const LedgerLeaderFill({super.key});

  @override
  Widget build(BuildContext context) => SizedBox(
    height: LedgerChromeMetrics.leaderHeight,
    child: CustomPaint(
      painter: LedgerLeaderPainter(context.ledgerTheme.textFaint),
      size: Size.infinite,
    ),
  );
}
