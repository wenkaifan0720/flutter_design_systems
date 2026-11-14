import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../internal/dashed.dart';
import '../../internal/end_glyph.dart';
import '../../theme.dart';
import '../button/button.dart';
import '../engravings/engravings.dart';
import '../gauge/gauge.dart';
import '../marks/marks.dart';
import '../money/money.dart';
import '../notice/notice.dart';
import '../pressable/pressable.dart';
import '../receipt/receipt.dart';
import '../seal/seal.dart';
import '../structure/structure.dart';

/// The serif at [px] on a [line], tracked [em]: the slips' words in the
/// serif (`font: 400 <px>/<line> var(--serif)`).
TextStyle _serif(LedgerThemeData t, double px, double line, double em) =>
    t.title.sized(px).line(line).tracked(em);

/// A card's statement printed on a slip (`.statement`): the guilloche band,
/// its [kind] and [number], the [balance] engraved under its label against
/// when it is [due] (the date in the serif, [dueNote] in the mono under it)
/// over the ink rule, then its [details] (key and value lines) and the
/// [last] payment's row under a rule.
///
/// ```dart
/// LedgerStatementSlip(kind: 'Keel Card · Statement', number: '··7730', balance: 1326.44, due: 'Nov 12', dueNote: 'In 15 days', details: const [LedgerKeyValue('Autopay', 'Full balance')])
/// ```
class LedgerStatementSlip extends StatelessWidget {
  /// A statement for [number] owing [balance] by [due].
  const LedgerStatementSlip({
    required this.kind,
    required this.number,
    required this.balance,
    required this.due,
    required this.dueNote,
    required this.details,
    this.last,
    this.balanceLabel = 'Statement balance',
    this.dueLabel = 'Due',
    super.key,
  });

  /// The slip's kind (Keel Card · Statement) and the card's last four.
  final String kind;

  /// The card's last four.
  final String number;

  /// What the statement owes, engraved at a section's size.
  final double balance;

  /// The day it is due (Nov 12) and how far off (In 15 days).
  final String due;

  /// How far off the due day is (In 15 days).
  final String dueNote;

  /// Its key and value lines ([LedgerKeyValue]s).
  final List<Widget> details;

  /// The last payment's row ([LedgerRow]), under a rule.
  final Widget? last;

  /// The balance's label.
  final String balanceLabel;

  /// The due day's label.
  final String dueLabel;

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    final wide = LedgerLayout.isWide(context);
    // `.statement`: padding 0 20px 4px (0 32px 6px from 1024).
    final side = wide ? 32.0 : 20.0;
    final balanceColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(balanceLabel.toUpperCase(), style: t.label),
        // `.stmt-fig .fig`: margin-top 10px; `.fig-m`.
        const SizedBox(height: 10),
        LedgerFigure(balance, size: LedgerFigureSize.section),
      ],
    );
    final larger = MediaQuery.textScalerOf(context).scale(1) > 1;
    // `.stmt-due`: text-align right. At a large text size, where it may turn
    // under the balance, its lines share their start instead.
    final dueAlign = larger ? TextAlign.start : TextAlign.end;
    final dueColumn = Column(
      crossAxisAlignment: larger
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.end,
      children: [
        Text(dueLabel.toUpperCase(), style: t.label),
        // `.stmt-date`: margin-top 6px, 400 28px/30px var(--serif),
        // letter-spacing -.005em.
        const SizedBox(height: 6),
        Text(due, textAlign: dueAlign, style: _serif(t, 28, 30, -.005)),
        // `.stmt-due .meta`: margin-top 2px.
        const SizedBox(height: 2),
        Text(dueNote.toUpperCase(), textAlign: dueAlign, style: t.meta),
      ],
    );
    return LedgerSlip(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const LedgerSlipBand(),
          Padding(
            padding: EdgeInsets.fromLTRB(side, 0, side, wide ? 6 : 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LedgerSlipHead(kind, number),
                // `.stmt-fig`: flex, align-items flex-end, space-between,
                // gap 16px, padding 2px 0 18px, border-bottom 1px solid
                // var(--ink).
                Container(
                  padding: const EdgeInsets.only(top: 2, bottom: 18),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: t.headRule)),
                  ),
                  // At a large text size the due day turns under the
                  // balance when the two do not fit one line, rather than
                  // squeeze its words down a column.
                  child: larger
                      ? Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.end,
                          spacing: 16,
                          runSpacing: 12,
                          children: [balanceColumn, dueColumn],
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          spacing: 16,
                          children: [
                            balanceColumn,
                            Flexible(child: dueColumn),
                          ],
                        ),
                ),
                LedgerRows(children: details),
                if (last != null)
                  // `.stmt-last`: border-top 1px solid var(--rule).
                  Container(
                    decoration: BoxDecoration(
                      border: Border(top: BorderSide(color: t.border)),
                    ),
                    child: last,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A memo on its slip (`.memo`): a short verdict in the serif at 28 (its
/// [text], then its [over] words in the vermilion italic, then
/// [textAfter]) beside its [seal] (pressed at the memo's 92; under the words
/// at a large text size), and under a
/// hairline its foot: a [leading] (a monogram), the [note] (its [noteAmount]
/// in the semibold mono ink, then [noteAfter]) and a chevron. With [onTap]
/// the foot is one link. Line breaks in the words are the caller's (\n).
///
/// ```dart
/// LedgerMemo(text: 'Dining out is\n', over: '\$36.40 over', textAfter: '\nbudget.', seal: const LedgerSeal(kicker: 'Dining', value: 'Over', foot: '+\$36.40', tone: LedgerSealTone.over), leading: const LedgerMonogram('Blue Fern Café', size: LedgerMonogramSize.dense), note: '13 visits to Blue Fern Café\ncame to ', noteAmount: '\$84.25', noteAfter: '.', onTap: () {})
/// ```
class LedgerMemo extends StatelessWidget {
  /// A memo: its verdict's words beside its [seal], its [note] under them.
  const LedgerMemo({
    required this.text,
    required this.seal,
    required this.note,
    this.over,
    this.textAfter,
    this.leading,
    this.noteAmount,
    this.noteAfter,
    this.onTap,
    this.focusNode,
    this.autofocus = false,
    super.key,
  });

  /// The verdict's words before the over words.
  final String text;

  /// The words set in the vermilion italic (`.over`): how far over.
  final String? over;

  /// The verdict's words after them.
  final String? textAfter;

  /// The verdict, pressed at the memo's size.
  final LedgerSeal seal;

  /// The foot's mark before its words (a dense [LedgerMonogram]).
  final Widget? leading;

  /// The foot's words, then its amount and the words after it.
  final String note;

  /// The foot's amount, in the semibold mono ink.
  final String? noteAmount;

  /// The foot's words after its amount.
  final String? noteAfter;

  /// Opens what the foot names (the merchant).
  final VoidCallback? onTap;

  /// The control's focus; null keeps one of its own. The caller disposes
  /// the node it gives.
  final FocusNode? focusNode;

  /// Whether it takes focus when it first appears.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    // `.memo-text`: 400 28px/30px var(--serif), letter-spacing -.005em;
    // `.memo-text .over`: italic, var(--red).
    final words = _serif(t, 28, 30, -.005);
    // `.memo-foot`: 13px/18px, var(--ink-2); `b.ink.mono`: 600, var(--ink),
    // the mono at 12, untracked.
    final foot = t.bodySmall.colored(t.textSecondary);
    final amount = t.amount
        .sized(12)
        .tracked(0)
        .line(18)
        .semibold
        .colored(t.textPrimary);
    final footRow = Container(
      // `.memo-foot`: margin-top 16px (the gap above), padding-top 14px,
      // border-top 1px solid var(--rule-2), gap 12px, align-items center.
      padding: const EdgeInsets.only(top: 14),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: t.hairline)),
      ),
      child: Row(
        spacing: 12,
        children: [
          ?leading,
          Expanded(
            child: Text.rich(
              TextSpan(
                text: note,
                children: [
                  if (noteAmount != null)
                    TextSpan(text: noteAmount, style: amount),
                  if (noteAfter != null) TextSpan(text: noteAfter),
                ],
              ),
              style: foot,
            ),
          ),
          // `.memo-foot .go`: var(--ink-3), its glyph 16.
          ExcludeSemantics(
            child: LedgerEndGlyph(
              LucideIcons.chevronRight,
              size: 16,
              color: t.textTertiary,
            ),
          ),
        ],
      ),
    );
    final verdict = Text.rich(
      TextSpan(
        text: text,
        children: [
          if (over != null)
            TextSpan(text: over, style: words.italic.colored(t.over)),
          if (textAfter != null) TextSpan(text: textAfter),
        ],
      ),
      style: words,
    );
    // `.memo .seal`: 92 by 92.
    final stamp = LedgerSeal(
      kicker: seal.kicker,
      value: seal.value,
      foot: seal.foot,
      tone: seal.tone,
      size: LedgerSealSize.memo,
    );
    // At a large text size the seal is pressed under the verdict, at its
    // end, rather than squeeze the words down a narrow column beside it.
    final larger = MediaQuery.textScalerOf(context).scale(1) > 1;
    return LedgerSlip(
      // `.memo`: padding 20px.
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // `.memo-top`: flex, align-items center, space-between, gap 12px.
          if (larger)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 12,
              children: [
                verdict,
                Align(alignment: AlignmentDirectional.centerEnd, child: stamp),
              ],
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              spacing: 12,
              children: [
                Flexible(child: verdict),
                stamp,
              ],
            ),
          const SizedBox(height: 16),
          if (onTap == null)
            MergeSemantics(child: footRow)
          else
            MergeSemantics(
              child: LedgerPressable(
                focusNode: focusNode,
                autofocus: autofocus,
                onTap: onTap,
                role: LedgerPressRole.link,
                child: footRow,
              ),
            ),
        ],
      ),
    );
  }
}

/// A memo slip (`.goal-memo`): a goal's standing as its [label] (in the
/// second ink), the owner's own [note] in the serif at 22, and the
/// [actions] it offers (buttons, 10 apart, wrapping), on the light paper.
///
/// ```dart
/// LedgerMemoSlip(label: 'On track', note: 'Flights in March, the rest by May.', actions: [LedgerButton('Add money', icon: LucideIcons.plus, onPressed: () {})])
/// ```
class LedgerMemoSlip extends StatelessWidget {
  /// A goal's standing [label], the owner's [note] and its [actions].
  const LedgerMemoSlip({
    required this.label,
    required this.note,
    this.actions = const [],
    super.key,
  });

  /// The goal's standing (On track), in the second ink.
  final String label;

  /// The owner's own note, in the serif.
  final String note;

  /// Its acts ([LedgerButton]s), in order.
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    return LedgerSlip(
      // `.goal-memo`: padding 18px 20px 20px.
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // `.goal-memo .label`: var(--ink-2).
          Text(label.toUpperCase(), style: t.label.colored(t.textSecondary)),
          // `.memo-note`: margin-top 8px, 400 22px/27px var(--serif),
          // letter-spacing -.003em.
          const SizedBox(height: 8),
          Text(note, style: _serif(t, 22, 27, -.003)),
          if (actions.isNotEmpty) ...[
            // `.memo-acts`: flex-wrap, gap 10px, margin-top 16px.
            const SizedBox(height: 16),
            Wrap(spacing: 10, runSpacing: 10, children: actions),
          ],
        ],
      ),
    );
  }
}

/// The frozen card's notice on its slip (`.frozen-banner`): the ringed
/// [icon] beside its [title] in the serif and its [text], then what being
/// frozen does ([effects], under a hairline) and the act that undoes it
/// ([actionLabel], the primary button across the slip). From 1024 the act
/// stands beside the head and the effects side by side.
///
/// ```dart
/// LedgerFrozenBanner(title: 'Frozen today at 9:41 AM', text: 'Nothing is cancelled. Unfreeze it any time.', effects: const [LedgerEffect(icon: LucideIcons.ban, title: 'Declined', text: 'New purchases and cash withdrawals.', blocking: true)], actionLabel: 'Unfreeze card', onActionPressed: () {})
/// ```
class LedgerFrozenBanner extends StatelessWidget {
  /// The frozen card's notice: [title], [text], its [effects] and the act that
  /// undoes it.
  const LedgerFrozenBanner({
    required this.title,
    required this.text,
    required this.effects,
    required this.actionLabel,
    required this.onActionPressed,
    this.icon = LucideIcons.snowflake,
    this.actionIcon = LucideIcons.lockOpen,
    this.actionKey,
    super.key,
  });

  /// When the card was frozen, in the serif.
  final String title;

  /// What freezing means, under the title.
  final String text;

  /// What being frozen does.
  final List<LedgerEffect> effects;

  /// The act's words (Unfreeze card).
  final String actionLabel;

  /// Undoes the freeze; null disables the act.
  final VoidCallback? onActionPressed;

  /// The ringed glyph beside the title.
  final IconData icon;

  /// The act's glyph.
  final IconData actionIcon;

  /// The act's own key (the button a walkthrough taps).
  final Key? actionKey;

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    final wide = LedgerLayout.isWide(context);
    final head = Row(
      // `.fb-head`: flex, align-items center, gap 14px.
      spacing: 14,
      children: [
        // `.frozen-banner .ring`: 40 round, 1px solid var(--ink); its
        // glyph 18.
        ExcludeSemantics(
          child: Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: t.textPrimary),
            ),
            child: Icon(icon, size: 18, color: t.textPrimary),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // `.fb-t`: 400 22px/26px var(--serif), letter-spacing
              // -.005em.
              Semantics(
                header: true,
                child: Text(title, style: _serif(t, 22, 26, -.005)),
              ),
              // `.fb-s`: margin-top 2px, 13px/18px, var(--ink-3).
              const SizedBox(height: 2),
              Text(text, style: t.bodySmall),
            ],
          ),
        ),
      ],
    );
    final act = LedgerButton.filled(
      actionLabel,
      key: actionKey,
      icon: actionIcon,
      expand: !wide,
      onPressed: onActionPressed,
    );
    // `.frozen-banner .effects`: border-top 1px solid var(--rule-2).
    final rule = BoxDecoration(
      border: Border(top: BorderSide(color: t.hairline)),
    );
    if (wide) {
      // From 1024: a grid, "head btn" over "fx fx", align-items center,
      // gap 14px 24px, padding 18px 22px 8px; the effects in a row 28px
      // apart, no rule under each.
      return LedgerSlip(
        padding: const EdgeInsets.fromLTRB(22, 18, 22, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              spacing: 24,
              children: [
                Expanded(child: head),
                act,
              ],
            ),
            const SizedBox(height: 14),
            Container(
              decoration: rule,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 28,
                children: [for (final e in effects) Expanded(child: e)],
              ),
            ),
          ],
        ),
      );
    }
    return LedgerSlip(
      // `.frozen-banner`: padding 16px 16px 18px.
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // `.fb-head`: padding-bottom 4px.
          Padding(padding: const EdgeInsets.only(bottom: 4), child: head),
          // `.frozen-banner .effects`: margin-top 6px, then its rule.
          LedgerEffects(ruled: true, children: effects),
          // `.fb-btn`: width 100%, margin-top 14px.
          const SizedBox(height: 14),
          act,
        ],
      ),
    );
  }
}

/// A dialog's lead (`.dialog-lead`): what the act does, said plainly in
/// the serif at 22 before what it does in detail; 12 above, 4 under. Each
/// line of [text] (split at \n) its own paragraph.
///
/// ```dart
/// LedgerDialogLead('Freezing stops the card, not the account.\nUnfreeze it any time.')
/// ```
class LedgerDialogLead extends StatelessWidget {
  /// A dialog's lead worded [text].
  const LedgerDialogLead(this.text, {super.key});

  /// What the act does; each line (split at \
  /// ) its own paragraph.
  final String text;

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    return Padding(
      // `.dialog-lead`: padding 12px 0 4px; 400 22px/27px var(--serif),
      // letter-spacing -.003em, var(--ink).
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Text(text, style: _serif(t, 22, 27, -.003)),
    );
  }
}

/// A done page's head (`.done-head`): what happened and when in the green
/// mono ([meta]), then the [title] in the serif at 32 (44 from 1024)
/// ending in its [emphasis] in the green italic, kept on the title's last
/// line by a no-break space. The page's heading.
///
/// ```dart
/// LedgerDoneHead(meta: 'Transfer sent · 9:41 AM', title: '\$500.00 is on its way to', emphasis: 'Savings')
/// ```
class LedgerDoneHead extends StatelessWidget {
  /// A done page's head: its [meta] over its [title] and [emphasis].
  const LedgerDoneHead({
    required this.meta,
    required this.title,
    this.emphasis,
    super.key,
  });

  /// What happened and when, in the green mono.
  final String meta;

  /// The title, in the serif, before its [emphasis].
  final String title;

  /// Where it went: set in the green italic (`.done-t em`).
  final String? emphasis;

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    final wide = LedgerLayout.isWide(context);
    // `.done-t`: 400 32px/36px var(--serif), letter-spacing -.005em (44px/
    // 48px from 1024).
    final style = wide ? _serif(t, 44, 48, -.005) : _serif(t, 32, 36, -.005);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // `.done-head .meta`: var(--green).
        Text(meta.toUpperCase(), style: t.meta.colored(t.accent)),
        // `.done-t`: margin-top 8px.
        const SizedBox(height: 8),
        Semantics(
          header: true,
          child: Text.rich(
            TextSpan(
              text: title,
              children: [
                if (emphasis != null)
                  TextSpan(
                    // `&nbsp;<em>`: italic, var(--green).
                    text: ' $emphasis',
                    style: style.italic.colored(t.accent),
                  ),
              ],
            ),
            style: style,
          ),
        ),
      ],
    );
  }
}

/// One half of a [LedgerSplitTicket]: who ([name], their [initials] when
/// not the name's own), what they did ([note]) and their share.
class LedgerSplitHalf {
  /// One person's half: [name], their [note] and their [amount].
  const LedgerSplitHalf({
    required this.name,
    required this.note,
    required this.amount,
    this.initials,
  });

  /// Who.
  final String name;

  /// What their share is (Your half, Owes you).
  final String note;

  /// Their share.
  final double amount;

  /// The monogram's letters, when not the name's own.
  final String? initials;
}

/// A purchase split as a ticket torn in two (`.ticket`), on the light
/// paper: its [start] (what and when) and [end] (the total) in the mono
/// over a hairline, then [mine] and [theirs] side by side, each a monogram,
/// a name, what they did and their share engraved, the perforation and a
/// notch between; theirs on the green wash, its monogram green.
///
/// ```dart
/// LedgerSplitTicket(start: 'Blue Fern Café · Wed, Oct 28', end: 'Total \$6.75', mine: const LedgerSplitHalf(name: 'Maren Holt', initials: 'MH', note: 'Your half', amount: 3.38), theirs: const LedgerSplitHalf(name: 'Sam Ortiz', initials: 'SO', note: 'Owes you', amount: 3.37))
/// ```
class LedgerSplitTicket extends StatelessWidget {
  /// A split: [start] and [end] over [mine] and [theirs].
  const LedgerSplitTicket({
    required this.start,
    required this.end,
    required this.mine,
    required this.theirs,
    super.key,
  });

  /// What and when, at the ticket's start.
  final String start;

  /// The total, at the ticket's end.
  final String end;

  /// The owner's half.
  final LedgerSplitHalf mine;

  /// The other person's half, on the green wash.
  final LedgerSplitHalf theirs;

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    // `.half-them`: background rgba(222, 231, 221, .5) (the green wash).
    final wash = t.accentSubtle.withValues(alpha: .5);
    // `.ticket-top .meta`: 10, on the meta's 16 line.
    final meta = t.meta.sized(11).line(16);
    Widget half(LedgerSplitHalf h, {required bool them}) => Container(
      color: them ? wash : null,
      // `.half`: column, align-items flex-start, padding 16px 16px 18px.
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      child: MergeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LedgerMonogram(
              h.name,
              initials: h.initials,
              tone: them
                  ? LedgerMonogramTone.moneyIn
                  : LedgerMonogramTone.plain,
            ),
            // `.half .mg`: margin-bottom 10px.
            const SizedBox(height: 10),
            // `.half-n`: 500 15px/20px var(--sans).
            Text(h.name, style: t.rowTitle),
            // `.half-s`: 13px/18px, var(--ink-3).
            Text(h.note, style: t.bodySmall),
            // `.half .fig`: margin-top 14px; `.fig-m`.
            const SizedBox(height: 14),
            LedgerFigure(h.amount, size: LedgerFigureSize.section),
          ],
        ),
      ),
    );
    return LedgerSlip(
      // `.ticket`: overflow hidden.
      child: ClipRRect(
        borderRadius: BorderRadius.circular(t.smallRadius),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // `.ticket-top`: space-between, gap 12px, padding 12px 16px
            // 11px, border-bottom 1px solid var(--rule-2).
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 11),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: t.hairline)),
              ),
              // At a large text size the end turns under the start when the
              // two do not fit one line.
              child: MediaQuery.textScalerOf(context).scale(1) > 1
                  ? Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      spacing: 12,
                      runSpacing: 2,
                      children: [
                        Text(start.toUpperCase(), style: meta),
                        Text(end.toUpperCase(), style: meta),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      spacing: 12,
                      children: [
                        Flexible(child: Text(start.toUpperCase(), style: meta)),
                        Text(end.toUpperCase(), style: meta),
                      ],
                    ),
            ),
            // `.ticket-halves`: flex, align-items stretch.
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: half(mine, them: false)),
                  _TicketPerf(wash: wash),
                  Expanded(child: half(theirs, them: true)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The tear between a ticket's halves (`.ticket-perf`): 18 wide, its end
/// half on the wash, the perforation running down its middle and a
/// half-round notch (`.notch-b`, 18 by 9) cut from the foot.
class _TicketPerf extends StatelessWidget {
  const _TicketPerf({required this.wash});

  final Color wash;

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    return ExcludeSemantics(
      child: SizedBox(
        width: 18,
        child: Stack(
          children: [
            // background: linear-gradient(90deg, transparent 0 9px, wash
            // 9px).
            PositionedDirectional(
              start: 9,
              end: 0,
              top: 0,
              bottom: 0,
              child: ColoredBox(color: wash),
            ),
            Column(
              children: [
                // `.vperf`: flex 1, width 6.
                const Expanded(child: LedgerPerforation(vertical: true)),
                CustomPaint(
                  size: const Size(18, 9),
                  painter: _NotchUpPainter(t.background),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// `.notch-b`: the page's paper, its top corners round (999px 999px 0 0),
/// `inset 0 1px 0 rgba(20, 26, 31, .08)` along its round edge.
class _NotchUpPainter extends CustomPainter {
  _NotchUpPainter(this.paper);

  final Color paper;

  @override
  void paint(Canvas canvas, Size size) {
    final r = Radius.circular(size.width / 2);
    // The cut reaches over the ticket's 1 px foot, so the edge stops at the
    // notch rather than running across its mouth.
    final shape = RRect.fromRectAndCorners(
      Rect.fromLTWH(0, 0, size.width, size.height + 1),
      topLeft: r,
      topRight: r,
    );
    canvas.drawRRect(shape, Paint()..color = paper);
    canvas
      ..save()
      ..clipRRect(shape)
      ..drawRRect(
        shape.shift(const Offset(0, 1)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = const Color(0x14141A1F),
      )
      ..restore();
  }

  @override
  bool shouldRepaint(_NotchUpPainter old) => old.paper != paper;
}

/// What a goal will hold once the money lands (`.add-after`): the [title] on
/// the dot leader to the [value] (the sum and its share), the green gauge
/// filled to [ratio], and under it how it adds up ([subtitle]) and the target
/// ([trailingSubtitle]); a rule above and below. The add money sheet's line.
///
/// ```dart
/// LedgerSavedAfter(value: '\$2,950 · 74%', ratio: .7375, subtitle: '\$2,840 saved + \$110', trailingSubtitle: 'of \$4,000')
/// ```
class LedgerSavedAfter extends StatelessWidget {
  /// What a goal will hold: [value] and the gauge at [ratio].
  const LedgerSavedAfter({
    required this.value,
    required this.ratio,
    this.title = 'Saved after',
    this.subtitle,
    this.trailingSubtitle,
    super.key,
  });

  /// The line's words, on the dot leader.
  final String title;

  /// The sum after and its share of the target, in the mono.
  final String value;

  /// How full the goal stands after, 0 to 1.
  final double ratio;

  /// How it adds up, under the line ($2,840 saved + $110).
  final String? subtitle;

  /// The target, at the sub line's end (of $4,000).
  final String? trailingSubtitle;

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    final sub = ledgerSubLine(context, start: subtitle, end: trailingSubtitle);
    return Container(
      // `.add-after`: padding 14px 0, border-top and border-bottom 1px
      // solid var(--rule).
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        border: Border.symmetric(horizontal: BorderSide(color: t.border)),
      ),
      child: MergeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LedgerLeaderLine(
              start: Text(title, style: t.rowTitle),
              // `.pct`: 500 13px/16px var(--mono), var(--ink).
              end: Text(
                value,
                softWrap: false,
                style: t.amount.sized(13).line(16).tracked(0),
              ),
            ),
            // `.add-after .gauge`: margin-top 10px.
            const SizedBox(height: 10),
            LedgerGauge(
              ratio: ratio,
              tick: false,
              tone: LedgerGaugeTone.green,
              semanticLabel: title,
            ),
            if (sub != null) ...[
              // `.sub`: margin-top 3px.
              const SizedBox(height: 3),
              sub,
            ],
          ],
        ),
      ),
    );
  }
}

/// The row that sums what came before the rows shown (`.row-before`): a
/// dashed box with its [icon] (40 by 44, the faint ink), the [title] in
/// the second ink on the dot leader to its [value], and its [subtitle] (how
/// many) under them; 14 above and below, as a ledger row.
///
/// ```dart
/// LedgerBeforeRow(title: 'Saved before Jun 1', value: const LedgerAmount(790, tone: LedgerTone.moneyIn, showSign: true), subtitle: '3 contributions')
/// ```
class LedgerBeforeRow extends StatelessWidget {
  /// A row summing what came before: [title] and its [value].
  const LedgerBeforeRow({
    required this.title,
    required this.value,
    this.subtitle,
    this.icon = LucideIcons.archive,
    super.key,
  });

  /// The row's words, in the second ink.
  final String title;

  /// The sum (a [LedgerAmount]).
  final Widget value;

  /// How many rows it sums, under the line (3 contributions).
  final String? subtitle;

  /// The glyph in the dashed box.
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    final subLine = ledgerSubLine(context, start: subtitle);
    final radius = BorderRadius.circular(t.smallRadius);
    return MergeSemantics(
      child: Padding(
        // `.row`: padding 14px 0, its parts 14px apart.
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          spacing: 14,
          children: [
            // `.glyph-before`: 40 by 44, 1px dashed var(--ink-4), radius
            // var(--r-sheet), var(--ink-3); its glyph 16.
            ExcludeSemantics(
              child: CustomPaint(
                painter: LedgerDashedOutline(
                  radius: radius,
                  color: t.textFaint,
                ),
                child: SizedBox(
                  width: 40,
                  height: 44,
                  child: Icon(icon, size: 16, color: t.textTertiary),
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  LedgerLeaderLine(
                    // `.row-before .title`: 500, var(--ink-2).
                    start: Text(
                      title,
                      style: t.rowTitle.medium.colored(t.textSecondary),
                    ),
                    end: value,
                  ),
                  if (subLine != null) ...[const SizedBox(height: 3), subLine],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
