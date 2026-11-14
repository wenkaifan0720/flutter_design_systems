import 'package:flutter/widgets.dart';

import '../../format.dart';
import '../../theme.dart';
import '../gauge/gauge.dart';
import '../marks/marks.dart';
import '../money/money.dart';
import '../pressable/pressable.dart';

/// A goal's line (`.goal`): its glyph and name on the leader to the share
/// saved, the green gauge under them, then what is saved of the target
/// and [by] when (by May 2027, reaches May 2027); 16 above and below.
/// The share ends at the line's end, the leader filling what the name
/// leaves. A [target] of 0 (a goal with none set yet) reads 0% on an
/// empty gauge, as the new goal's preview stands before its target is
/// typed ("0%", gauge(0)); the words keep the
/// sums given ("$0 of $0"). One link to the goal, read as its name,
/// share and date.
///
/// ```dart
/// LedgerGoalLine(icon: LucideIcons.plane, name: 'Lisbon in May', saved: 2840, target: 4000, by: 'by May 2027', onTap: () {})
/// ```
class LedgerGoalLine extends StatelessWidget {
  /// A goal named [name]: [saved] of its [target].
  const LedgerGoalLine({
    required this.icon,
    required this.name,
    required this.saved,
    required this.target,
    this.by,
    this.onTap,
    this.focusNode,
    this.autofocus = false,
    super.key,
  });

  /// The goal's glyph.
  final IconData icon;

  /// The goal's name.
  final String name;

  /// What is saved so far.
  final num saved;

  /// What the goal is saving for; 0 when none is set.
  final num target;

  /// When it is due or will be reached (by May 2027).
  final String? by;

  /// Opens the goal.
  final VoidCallback? onTap;

  /// The control's focus; null keeps one of its own. The caller disposes
  /// the node it gives.
  final FocusNode? focusNode;

  /// Whether it takes focus when it first appears.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final percent = LedgerFormat.percent(saved, target);
    return LedgerPressable(
      focusNode: focusNode,
      autofocus: autofocus,
      onTap: onTap,
      role: LedgerPressRole.link,
      label: [name, '$percent%', ?by].join(', '),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: _GoalBody(
          icon: icon,
          name: name,
          saved: saved,
          target: target,
          by: by,
        ),
      ),
    );
  }
}

class _GoalBody extends StatelessWidget {
  const _GoalBody({
    required this.icon,
    required this.name,
    required this.saved,
    required this.target,
    this.by,
  });

  final IconData icon;
  final String name;
  final num saved;
  final num target;
  final String? by;

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    final percent = LedgerFormat.percent(saved, target);
    final base = t.bodySmall;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          spacing: _gap,
          children: [
            LedgerGlyph(icon, size: LedgerGlyphSize.small),
            // The name on the leader to the share, which ends the line: the
            // leader takes what the name leaves (a Flexible name beside an
            // Expanded leader would split the room and strand the share).
            Expanded(
              child: LedgerLeaderLine(
                centred: true,
                inset: _gap + _leaderMargin,
                start: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.rowTitle,
                ),
                // `.pct`: 500 13/16 mono, the ink.
                end: Text(
                  '$percent%',
                  style: t.amount
                      .sized(13)
                      .line(16)
                      .tracked(0)
                      .colored(t.textPrimary),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        LedgerGauge(
          ratio: _share(saved, target),
          tick: false,
          tone: LedgerGaugeTone.green,
          semanticLabel: 'Saved',
        ),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          spacing: 12,
          children: [
            Flexible(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: LedgerFormat.money(saved, showCents: false),
                      style: t.amount
                          .sized(12)
                          .tracked(0)
                          .line(base.fontSize! * base.height!)
                          .colored(t.textSecondary),
                    ),
                    TextSpan(
                      text:
                          ' of ${LedgerFormat.money(target, showCents: false)}',
                    ),
                  ],
                ),
                style: base,
              ),
            ),
            if (by case final words?) Text(words, style: base),
          ],
        ),
      ],
    );
  }

  // `.goal .line`: 12 apart; `.leader` 8 inside the gaps (20 clear).
  static const double _gap = 12;
  static const double _leaderMargin = 8;
}

/// What is saved over the target; a target of 0 has none saved toward it.
double _share(num saved, num target) =>
    target == 0 ? 0 : (saved / target).toDouble();

/// A goal's card (`.goal-card`): its [LedgerGoalLine]'s parts 18 above
/// and below, then its [status] pill (green on track, the ink behind) and
/// its [note]; on the desktop the note stands in a 264 column beside them,
/// 44 off. A [target] of 0 reads 0% on an empty gauge, as on
/// [LedgerGoalLine]. One link to the goal.
///
/// ```dart
/// LedgerGoalCard(icon: LucideIcons.plane, name: 'Lisbon in May', saved: 2840, target: 4000, by: 'by May 2027', status: 'Behind', behindSchedule: true, note: 'Add \$110 to stay on track.', onTap: () {})
/// ```
class LedgerGoalCard extends StatelessWidget {
  /// A goal's card: [name], [saved] of [target], its [status] and [note].
  const LedgerGoalCard({
    required this.icon,
    required this.name,
    required this.saved,
    required this.target,
    required this.status,
    required this.note,
    this.by,
    this.behindSchedule = false,
    this.onTap,
    this.focusNode,
    this.autofocus = false,
    super.key,
  });

  /// The goal's glyph.
  final IconData icon;

  /// The goal's name.
  final String name;

  /// What is saved so far.
  final num saved;

  /// What the goal is saving for; 0 when none is set.
  final num target;

  /// When it is due or will be reached (by May 2027).
  final String? by;

  /// The goal's standing, in its pill (On track).
  final String status;

  /// Whether the goal is behind, its pill in the ink rather than the green.
  final bool behindSchedule;

  /// A line on how the goal is going.
  final String note;

  /// Opens the goal.
  final VoidCallback? onTap;

  /// The control's focus; null keeps one of its own. The caller disposes
  /// the node it gives.
  final FocusNode? focusNode;

  /// Whether it takes focus when it first appears.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    final wide = LedgerLayout.isWide(context);
    final percent = LedgerFormat.percent(saved, target);
    final pill = LedgerPill(
      status,
      tone: behindSchedule ? LedgerPillTone.plain : LedgerPillTone.success,
      size: LedgerPillSize.small,
    );
    final words = Text(note, style: t.bodySmall.colored(t.textSecondary));
    final body = _GoalBody(
      icon: icon,
      name: name,
      saved: saved,
      target: target,
      by: by,
    );
    final Widget card = wide
        ? Padding(
            padding: const EdgeInsets.symmetric(vertical: 22),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 44,
              children: [
                Expanded(child: body),
                SizedBox(
                  width: 264,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 8,
                      children: [pill, words],
                    ),
                  ),
                ),
              ],
            ),
          )
        : Padding(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                body,
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 10,
                  children: [
                    pill,
                    Expanded(child: words),
                  ],
                ),
              ],
            ),
          );
    return LedgerPressable(
      focusNode: focusNode,
      autofocus: autofocus,
      onTap: onTap,
      role: LedgerPressRole.link,
      label: [name, '$percent%', ?by, status].join(', '),
      child: card,
    );
  }
}

/// A category's month (`.cat`): its name on the leader to what it spent, the
/// gauge under them (its budget at 250 of 300, the month's [pace] across it),
/// then its [subtitle] and [trailingSubtitle]; over its budget the name, the
/// amount and the end note vermilion. On the desktop one line: the name over
/// its note in a 236 column, the gauge, the amount in 104. One link to the
/// category.
///
/// ```dart
/// LedgerCategoryLine(name: 'Dining out', spent: 286.40, budget: 250, pace: 28 / 31, subtitle: 'Budget \$250', trailingSubtitle: 'Over by \$36.40', onTap: () {})
/// ```
class LedgerCategoryLine extends StatelessWidget {
  /// A category named [name]: what it [spent] of its [budget].
  const LedgerCategoryLine({
    required this.name,
    required this.spent,
    required this.budget,
    this.pace,
    this.subtitle,
    this.trailingSubtitle,
    this.onTap,
    this.focusNode,
    this.autofocus = false,
    super.key,
  });

  /// The category's name.
  final String name;

  /// What the category spent this month.
  final num spent;

  /// The category's budget for the month.
  final num budget;

  /// How far through the month it is, 0 to 1, marked on the gauge.
  final double? pace;

  /// The line under the gauge's start (Budget $250).
  final String? subtitle;

  /// The line under the gauge's end (Over by $36.40).
  final String? trailingSubtitle;

  /// Opens the category.
  final VoidCallback? onTap;

  /// The control's focus; null keeps one of its own. The caller disposes
  /// the node it gives.
  final FocusNode? focusNode;

  /// Whether it takes focus when it first appears.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    final wide = LedgerLayout.isWide(context);
    final over = spent > budget;
    final title = Text(
      name,
      maxLines: 1,
      softWrap: false,
      overflow: TextOverflow.ellipsis,
      style: t.rowTitle.colored(over ? t.over : t.textPrimary),
    );
    final amount = LedgerAmount(
      spent,
      tone: over ? LedgerTone.over : LedgerTone.plain,
      textAlign: TextAlign.right,
    );
    final gauge = LedgerGauge(
      ratio: (spent / budget).toDouble(),
      budgetAt: 250 / 300,
      pace: pace,
      semanticLabel: '$name spent',
    );
    final base = t.bodySmall;
    final words = [
      if (subtitle case final s?) Text(s, style: base),
      if (trailingSubtitle case final e?)
        Text(e, style: base.colored(over ? t.over : t.textTertiary)),
    ];
    final Widget line;
    if (wide) {
      line = Padding(
        padding: const EdgeInsets.symmetric(vertical: 13),
        child: Row(
          spacing: 28,
          children: [
            SizedBox(
              width: 236,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  title,
                  const SizedBox(height: 2),
                  // One line; at a large text size the second turns under.
                  Wrap(spacing: 12, children: words),
                ],
              ),
            ),
            Expanded(child: gauge),
            SizedBox(width: 104, child: amount),
          ],
        ),
      );
    } else {
      line = Padding(
        padding: const EdgeInsets.only(top: 15, bottom: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LedgerLeaderLine(start: title, end: amount),
            const SizedBox(height: 10),
            gauge,
            const SizedBox(height: 6),
            // At its ends, in one face (so on one baseline); at a large
            // text size the end words turn under.
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              spacing: 12,
              children: words,
            ),
          ],
        ),
      );
    }
    return LedgerPressable(
      focusNode: focusNode,
      autofocus: autofocus,
      onTap: onTap,
      role: LedgerPressRole.link,
      label: [
        name,
        LedgerFormat.money(spent),
        ?subtitle,
        ?trailingSubtitle,
      ].join(', '),
      child: line,
    );
  }
}
