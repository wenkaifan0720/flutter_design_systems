import 'package:flutter/widgets.dart';

import '../../theme.dart';
import '../marks/marks.dart';
import '../money/money.dart';
import '../pressable/pressable.dart';

/// A notification's row (`.note-row`): its glyph, its [title] on the dot
/// leader to [when] (the time today, else the date) and its [body] under
/// it, the title free to wrap. An [unread] one stands on the green wash
/// fading across (14 by 12 inside, 6 round), its glyph green, its title
/// semibold and tagged, its time green. One link, read as its title (and
/// unread).
///
/// ```dart
/// LedgerNoteRow(icon: LucideIcons.receipt, title: 'Rent is due in 4 days', body: '\$1,150.00 to Linden Court Apartments on Nov 1.', when: '9:00 AM', unread: true, onTap: () {})
/// ```
class LedgerNoteRow extends StatelessWidget {
  /// A notification titled [title], from [when], saying [body].
  const LedgerNoteRow({
    required this.icon,
    required this.title,
    required this.body,
    required this.when,
    this.unread = false,
    this.unreadTag = 'New',
    this.unreadLabel = 'unread',
    this.onTap,
    this.focusNode,
    this.autofocus = false,
    super.key,
  });

  /// The notification's glyph.
  final IconData icon;

  /// What happened.
  final String title;

  /// More of it, under the title.
  final String body;

  /// The time today, else the date.
  final String when;

  /// Whether the owner has not seen it yet.
  final bool unread;

  /// The tag after an unread title's words (New).
  final String unreadTag;

  /// What a screen reader says after an unread title.
  final String unreadLabel;

  /// Opens what the notification is about.
  final VoidCallback? onTap;

  /// The control's focus; null keeps one of its own. The caller disposes
  /// the node it gives.
  final FocusNode? focusNode;

  /// Whether it takes focus when it first appears.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    final name = Text.rich(
      TextSpan(
        text: title,
        children: [
          if (unread)
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Padding(
                padding: const EdgeInsetsDirectional.only(start: 8),
                child: LedgerTag(unreadTag, tone: LedgerTagTone.unread),
              ),
            ),
        ],
      ),
      style: unread ? t.rowTitle.semibold : t.rowTitle,
    );
    final time = Text(
      when.toUpperCase(),
      softWrap: false,
      style: t.meta
          .line(20)
          .copyWith(
            fontWeight: unread ? FontWeight.w500 : FontWeight.w400,
            color: unread ? t.accent : t.textTertiary,
          ),
    );
    final row = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 14,
      children: [
        LedgerGlyph(
          icon,
          tone: unread ? LedgerGlyphTone.moneyIn : LedgerGlyphTone.plain,
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LedgerLeaderLine(start: name, end: time),
              const SizedBox(height: 3),
              Text(body, style: t.bodySmall),
            ],
          ),
        ),
      ],
    );
    return LedgerPressable(
      focusNode: focusNode,
      autofocus: autofocus,
      onTap: onTap,
      role: LedgerPressRole.link,
      label: unread ? '$title, $unreadLabel' : title,
      child: unread
          ? Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(t.smallRadius),
                gradient: LinearGradient(
                  colors: [
                    t.accentSubtle.withValues(alpha: .85),
                    t.accentSubtle.withValues(alpha: .25),
                  ],
                ),
              ),
              child: row,
            )
          : Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: row,
            ),
    );
  }
}

/// What an act does, one line of it (`.effect`): a glyph (the ink's ring
/// for what stops), its [title] in the semibold over its words in the
/// second ink at 14; 12 above and below.
///
/// ```dart
/// LedgerEffect(icon: LucideIcons.ban, title: 'Declined', text: 'New purchases and cash withdrawals.', blocking: true)
/// ```
class LedgerEffect extends StatelessWidget {
  /// One thing an act does: [title] and its [text].
  const LedgerEffect({
    required this.icon,
    required this.title,
    required this.text,
    this.blocking = false,
    super.key,
  });

  /// The effect's glyph.
  final IconData icon;

  /// What it does, in the semibold.
  final String title;

  /// More of it, in the second ink.
  final String text;

  /// Ringed in the ink: something it stops.
  final bool blocking;

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    final words = t.body.sized(14).line(20).colored(t.textSecondary);
    return MergeSemantics(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 14,
          children: [
            LedgerGlyph(
              icon,
              tone: blocking ? LedgerGlyphTone.inked : LedgerGlyphTone.plain,
              size: LedgerGlyphSize.dense,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: words.semibold.colored(t.textPrimary)),
                  Text(text, style: words),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// What an act does, all of it (`.effects`): its [LedgerEffect]s one under
/// another, a hairline between each and the next (`.effect`'s rule, none
/// under the last); 6 under what leads it. A freeze dialog's body under
/// its lead, and the frozen card's notice ([ruled]: a hairline above the
/// effects, under the 6, as `.frozen-banner .effects` has it).
///
/// ```dart
/// LedgerEffects(children: [LedgerEffect(icon: LucideIcons.ban, title: 'Declined', text: 'New purchases and cash withdrawals.', blocking: true), LedgerEffect(icon: LucideIcons.check, title: 'Still goes through', text: 'Autopay on Nov 12, refunds and payments.')])
/// ```
class LedgerEffects extends StatelessWidget {
  /// The effects of an act, [children], one under another.
  const LedgerEffects({required this.children, this.ruled = false, super.key});

  /// The effects, in order.
  final List<LedgerEffect> children;

  /// Whether a hairline stands above the first effect, under the 6.
  final bool ruled;

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    return Padding(
      // `.effects`: margin-top 6px.
      padding: const EdgeInsets.only(top: 6),
      child: Container(
        decoration: ruled
            ? BoxDecoration(
                border: Border(top: BorderSide(color: t.hairline)),
              )
            : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < children.length; i++)
              // `.effect`: border-bottom 1px solid var(--rule-2), under its
              // room (a Container insets by the rule, as CSS's border does);
              // `.effect:last-child`: none.
              Container(
                decoration: BoxDecoration(
                  border: i == children.length - 1
                      ? null
                      : Border(bottom: BorderSide(color: t.hairline)),
                ),
                child: children[i],
              ),
          ],
        ),
      ),
    );
  }
}
