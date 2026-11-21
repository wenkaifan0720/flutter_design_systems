/// Small marks on a line: a tag naming what something is, a chip that
/// filters, and a badge that counts.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../internal/pointer.dart';
import '../primitives/box.dart';
import '../primitives/control.dart';
import '../style.dart';
import '../theme.dart';
import '../localizations.dart';
import 'feedback.dart';

/// A tag: [label] on a ground tinted by [tone], a cell either side, as a
/// terminal prints a label in colour: ` prod `. With [onDeleted] a `×`
/// after the words takes it away.
///
/// ```dart
/// TermTag(label: 'production', tone: TermTone.warning)
/// ```
class TermTag extends StatelessWidget {
  /// A tag saying [label].
  const TermTag({
    super.key,
    required this.label,
    this.tone = TermTone.neutral,
    this.onDeleted,
    this.focused = false,
    this.style,
  });

  /// Overrides, over the theme's [TermThemeData.tagStyle]: `fill` (the
  /// ground) and `foreground` (the words).
  final TermStyle? style;

  /// Its words.
  final String label;

  /// Its tint: neutral is the rule's.
  final TermTone tone;

  /// Takes it away; null for a tag that stays.
  final VoidCallback? onDeleted;

  /// Whether the keyboard is on it (in a tag input): drawn in inverse
  /// accent.
  final bool focused;

  @override
  Widget build(BuildContext context) {
    final theme = TermTheme.of(context);
    final grid = context.termGrid;
    final cw = grid.cellWidth;
    final own = TermStyleOf(
      [style, theme.tagStyle],
      {if (focused) WidgetState.focused},
    );
    final ink =
        own.foreground ??
        (tone == TermTone.neutral ? theme.foreground : tone.colorIn(theme));
    final ground = focused
        ? theme.accent
        : own.fill ??
              Color.alphaBlend(
                (tone == TermTone.neutral ? theme.rule : ink).withValues(
                  alpha: tone == TermTone.neutral ? 0.45 : 0.18,
                ),
                theme.background,
              );
    final words = focused ? theme.onAccent : ink;
    final tag = ColoredBox(
      color: ground,
      child: SizedBox(
        height: grid.lineHeight,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(width: cw),
            Text(label, style: theme.textStyle.copyWith(color: words)),
            if (onDeleted == null) SizedBox(width: cw),
          ],
        ),
      ),
    );
    if (onDeleted == null) {
      return Semantics(container: true, label: label, child: tag);
    }
    // The × is the tag's last two cells; what a tap reaches is the floor
    // (a pointer's line, a finger's two), grown past the tag's end and above
    // and below it, the tag itself one line in the middle.
    final remove = TermTapTarget(
      alignment: AlignmentDirectional.centerStart,
      child: RawButton(
        onPressed: onDeleted,
        semanticLabel: TermLocalizations.of(context).removeLabel(label),
        mouseCursor: SystemMouseCursors.click,
        builder: (context, states, _) => TermStateSprings(
          pressed: states.contains(WidgetState.pressed),
          focused: states.contains(WidgetState.focused),
          builder: (context, press, focus) {
            // A press: the two cells in inverse video of the words' ink.
            // The keyboard's focus: the cursor, the accent over them.
            final pressed = press > 0.5;
            final cursor = pressed ? 0.0 : focus;
            return ColoredBox(
              color: pressed
                  ? words
                  : Color.lerp(ground, theme.accent, cursor)!,
              child: SizedBox(
                width: grid.cols(2),
                height: grid.lineHeight,
                child: Center(
                  child: Text(
                    '×',
                    style: theme.textStyle.copyWith(
                      color: pressed
                          ? ground
                          : termCursorInk(theme, words, cursor),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
    return Semantics(
      container: true,
      label: label,
      child: Row(mainAxisSize: MainAxisSize.min, children: [tag, remove]),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('label', label))
      ..add(
        EnumProperty<TermTone>('tone', tone, defaultValue: TermTone.neutral),
      )
      ..add(FlagProperty('focused', value: focused, ifTrue: 'focused'));
  }
}

/// A chip that filters: [label] in round brackets, `( failed )`, chosen in
/// inverse video with a `✓` in the cells kept for it, so choosing moves
/// nothing. The keyboard's focus is the cursor over it, its brackets cut
/// out (on a chosen chip, hollow); under the pointer the brackets take the
/// accent.
///
/// ```dart
/// TermChip(
///   label: 'failed',
///   selected: onlyFailed,
///   onSelected: (v) => setState(() => onlyFailed = v),
/// )
/// ```
class TermChip extends StatelessWidget {
  /// A filter chip saying [label].
  const TermChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
    this.style,
  });

  /// Overrides, over the theme's [TermThemeData.chipStyle]: `fill` (the
  /// chosen inverse), `foreground` (the words) and `edge` (the round
  /// brackets).
  final TermStyle? style;

  /// Its words.
  final String label;

  /// Whether it is chosen.
  final bool selected;

  /// Called with the new choice; null disables it.
  final ValueChanged<bool>? onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = TermTheme.of(context);
    final grid = context.termGrid;
    final enabled = onSelected != null;
    return TermTapTarget(
      child: RawButton(
        onPressed: enabled ? () => onSelected!(!selected) : null,
        selected: selected,
        checked: selected,
        semanticLabel: label,
        excludeSemantics: true,
        mouseCursor: enabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        builder: (context, states, _) => TermStateSprings(
          pressed: states.contains(WidgetState.pressed),
          focused: states.contains(WidgetState.focused),
          builder: (context, press, focus) {
            final own = TermStyleOf([style, theme.chipStyle], states);
            final rest = own.foreground ?? theme.foreground;
            final words = !enabled
                ? theme.rule
                : termCursorInk(
                    theme,
                    selected
                        ? theme.background
                        : Color.lerp(rest, theme.background, press)!,
                    focus,
                    hollow: selected,
                  );
            return CustomPaint(
              painter: TermBracketPainter(
                grid: grid,
                color: !enabled
                    ? theme.rule.withValues(alpha: 0.6)
                    : own.edge ?? termHoverInk(theme, theme.rule, states),
                stroke: termStroke(theme, grid),
                shape: TermBracketShape.round,
                fill: enabled ? own.fill ?? rest : theme.rule,
                fillAmount: selected ? 1 : press,
                cursor: enabled ? focus : 0,
                cursorColor: theme.accent,
                knockout: theme.onAccent,
                hollow: selected,
              ),
              child: SizedBox(
                height: grid.lineHeight,
                child: Padding(
                  padding: EdgeInsetsDirectional.symmetric(
                    horizontal: grid.cellWidth,
                  ),
                  child: Text(
                    '${selected ? '✓' : ' '} $label ',
                    maxLines: 1,
                    softWrap: false,
                    style: theme.textStyle.copyWith(color: words),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('label', label))
      ..add(FlagProperty('selected', value: selected, ifTrue: 'selected'));
  }
}

/// A badge that counts: the number in bold on a block of [tone]'s ink, a
/// cell either side, ` 3 `; past [max] it says `99+`. A screen reader
/// hears the count and [semanticLabel].
///
/// ```dart
/// Row(children: [Text('failed'), TermBadge(count: 3, semanticLabel: 'failed runs')])
/// ```
class TermBadge extends StatelessWidget {
  /// A badge showing [count].
  const TermBadge({
    super.key,
    required this.count,
    this.tone = TermTone.info,
    this.max = 99,
    this.semanticLabel,
    this.style,
  });

  /// Overrides, over the theme's [TermThemeData.badgeStyle]: `fill` (the
  /// block) and `foreground` (the number).
  final TermStyle? style;

  /// The number.
  final int count;

  /// Its ink.
  final TermTone tone;

  /// The most it writes out.
  final int max;

  /// What it counts.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = TermTheme.of(context);
    final grid = context.termGrid;
    final own = TermStyleOf([style, theme.badgeStyle], const {});
    final ink =
        own.fill ??
        (tone == TermTone.neutral ? theme.dim : tone.colorIn(theme));
    final text = count > max ? '$max+' : '$count';
    return Semantics(
      label: semanticLabel == null ? '$count' : '$count $semanticLabel',
      excludeSemantics: true,
      child: ColoredBox(
        color: ink,
        child: SizedBox(
          height: grid.lineHeight,
          child: Padding(
            padding: EdgeInsetsDirectional.symmetric(
              horizontal: grid.cellWidth,
            ),
            child: Center(
              widthFactor: 1,
              child: Text(
                text,
                style: theme.boldStyle.copyWith(
                  color: own.foreground ?? theme.background,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IntProperty('count', count))
      ..add(EnumProperty<TermTone>('tone', tone, defaultValue: TermTone.info));
  }
}
