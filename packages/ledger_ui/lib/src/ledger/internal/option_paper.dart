import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme.dart';
import 'cap_center.dart';
import 'face.dart';

/// The raised paper a suggestion list stands on, as the select's: the
/// surface in the rule, the small radius, the menu's shadow. Plumbing of
/// the combobox and the tag input.
Widget ledgerOptionPaper(BuildContext context, Widget list) {
  final t = context.ledgerTheme;
  return DecoratedBox(
    decoration: BoxDecoration(
      color: t.surface,
      borderRadius: BorderRadius.circular(t.smallRadius),
      border: Border.all(color: t.border),
      boxShadow: t.menuShadow,
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(t.smallRadius),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: LedgerSpacing.s4),
        child: list,
      ),
    ),
  );
}

/// One suggestion on the paper, 48 tall: its words in the medium, a
/// hairline over it after the first. The one that is the value stands on
/// the menu's paper, its words semibold, the green tick at its end; the
/// pointer's or the keyboard's marks run under its words alone
/// ([LedgerOptionWords]).
class LedgerOptionRow extends StatelessWidget {
  /// A suggestion worded [label] for [states].
  const LedgerOptionRow({
    required this.label,
    required this.states,
    this.note,
    super.key,
  });

  /// Its words.
  final String label;

  /// The note at its end, in the mono (a balance, a count).
  final String? note;

  /// Highlighted (focused), hovered, pressed, selected.
  final Set<WidgetState> states;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('label', label))
      ..add(StringProperty('note', note, defaultValue: null))
      ..add(IterableProperty<WidgetState>('states', states));
  }

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    final words = t.rowTitle.copyWith(
      leadingDistribution: TextLeadingDistribution.even,
    );
    final chosen = states.contains(WidgetState.selected);
    return LedgerFace(
      style: LedgerFaceStyle(
        ink: t.textPrimary,
        ground: BoxDecoration(color: chosen ? t.menuSelected : null),
      ),
      builder: (context, s, _) => Container(
        constraints: BoxConstraints(minHeight: t.density.height(_row)),
        padding: const EdgeInsets.symmetric(horizontal: _pad),
        decoration: s.ground,
        child: Row(
          spacing: _gap,
          children: [
            Expanded(
              child: ledgerCapCenter(
                words,
                LedgerOptionWords(
                  label,
                  states: states,
                  style: words.colored(t.textPrimary),
                  maxLines: 2,
                ),
              ),
            ),
            if (note case final n?)
              Text(n.toUpperCase(), style: t.meta.colored(t.textTertiary)),
            if (chosen)
              Icon(LucideIcons.check, size: _glyph, color: t.accent)
            else
              const SizedBox(width: _glyph),
          ],
        ),
      ),
    );
  }

  static const double _row = 48;
  static const double _pad = LedgerSpacing.s16;
  static const double _glyph = 18;
  static const double _gap = LedgerSpacing.s12;
}

/// An option's words in an open list (a select's, a menu's, a combobox's or
/// a tag field's), marked for its [states] on its own row: semibold when
/// it is the chosen one (its row on the menu's paper, the green tick at
/// its end); under a pointer or a finger they take the ink underline, as a
/// frameless act's words do; while the keyboard is on the option they
/// stand on the accountant's double rule, Ledger's focus. Both marks run
/// under the words alone, inside their row, so neither reads as a rule
/// between options or as a second choice, and each comes and goes in
/// Ledger's one motion. Plumbing of the lists.
class LedgerOptionWords extends StatelessWidget {
  /// [label] marked for [states].
  const LedgerOptionWords(
    this.label, {
    required this.states,
    required this.style,
    this.maxLines = 1,
    super.key,
  });

  /// The words.
  final String label;

  /// Highlighted (focused, the keyboard's), hovered, pressed, selected.
  final Set<WidgetState> states;

  /// The words' style, in their ink.
  final TextStyle style;

  /// The most lines the words take before they end in an ellipsis; null
  /// lets them wrap whole.
  final int? maxLines;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('label', label))
      ..add(IterableProperty<WidgetState>('states', states))
      ..add(IntProperty('maxLines', maxLines));
  }

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    final ink = style.color ?? t.textPrimary;
    final focused = states.contains(WidgetState.focused);
    final marked =
        focused ||
        states.contains(WidgetState.hovered) ||
        states.contains(WidgetState.pressed);
    final words = states.contains(WidgetState.selected)
        ? style.semibold
        : style;
    return LedgerFace(
      style: LedgerFaceStyle(ink: ink, rule: marked ? ink : null),
      builder: (context, s, _) => Text(
        label,
        maxLines: maxLines,
        overflow: maxLines == null ? null : TextOverflow.ellipsis,
        style: words.copyWith(
          color: s.ink,
          decoration: s.rule == null ? null : TextDecoration.underline,
          decorationColor: s.rule,
          decorationStyle: focused
              ? TextDecorationStyle.double
              : TextDecorationStyle.solid,
        ),
      ),
    );
  }
}

/// The paper's line when nothing matches: the words in the third ink.
class LedgerNoOption extends StatelessWidget {
  /// The line worded [label].
  const LedgerNoOption(this.label, {super.key});

  /// What it says.
  final String label;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('label', label));
  }

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: LedgerSpacing.s16,
        vertical: LedgerSpacing.s12,
      ),
      child: Text(label, style: t.bodySmall.colored(t.textTertiary)),
    );
  }
}
