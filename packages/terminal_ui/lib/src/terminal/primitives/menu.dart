/// The faces several controls share: a menu's row and its reveal, a pair
/// of brackets one line tall round a row of cells, and the faces drawn in
/// them.
library;

import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../internal/menu_marks.dart';
import '../style.dart';
import '../theme.dart';
import 'box.dart';
import 'control.dart';

/// A menu's row: [label] (and [trailing], a key or a count, dim at the
/// end). The chosen row ([checked], or [WidgetState.selected] in [states])
/// stands in inverse video, as a press does; under the pointer the row's
/// words take the accent, and where the keys are the cursor stands on it
/// ([TermCursorCells]: the row in the accent, a pair of brackets cut out
/// of its end cells; on the chosen row, hollow), so neither reads as a
/// second choice. In an open menu ([TermMenuMarks] round it) one row is
/// current: the keys' row, which the pointer moves as it moves onto a row,
/// shown once the keys or the pointer have moved in a menu the pointer
/// opened. In the rule's ink when disabled. One line for a pointer, two
/// for a finger.
class TermMenuRow extends StatelessWidget {
  /// A row saying [label] in [states].
  const TermMenuRow({
    super.key,
    required this.label,
    required this.states,
    this.trailing,
    this.checked,
    this.danger = false,
    this.style,
  });

  /// Overrides, over the theme's [TermThemeData.menuStyle]: `fill` (the
  /// chosen or pressed row's bar) and `foreground` (the words at rest).
  final TermStyle? style;

  /// The words.
  final String label;

  /// Its states: selected or pressed fill it, focused or hovered mark it.
  final Set<WidgetState> states;

  /// Dim words at the end: a key, a count.
  final String? trailing;

  /// For a choice, whether it is the one chosen (in inverse video, `•`
  /// before it); null for an action.
  final bool? checked;

  /// Whether it destroys something: in the danger ink.
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final theme = TermTheme.of(context);
    final disabled = states.contains(WidgetState.disabled);
    final chosen =
        !disabled && (checked == true || states.contains(WidgetState.selected));
    final pressed = !disabled && states.contains(WidgetState.pressed);
    // The chosen row, and a row being pressed: the bar.
    final lit = chosen || pressed;
    // Where the keys or the pointer are: the accent, never a bar of its own;
    // the keys add the cursor, so the pointer's row and the keys' never read
    // as one mark. Under the pointer, the chosen row's bar takes the accent.
    // In a menu the pointer moves the keys' row, so the one current row is
    // the keys', once shown.
    // The pointer's row has the focus too, though a finger's press (it
    // opened the menu) left the focus unshown.
    final marks = TermMenuMarks.shownOf(context);
    final focus = marks == null ? null : Focus.maybeOf(context);
    final keys =
        !disabled &&
        (marks ?? true) &&
        (states.contains(WidgetState.focused) ||
            (states.contains(WidgetState.hovered) &&
                focus != null &&
                focus is! FocusScopeNode &&
                focus.hasPrimaryFocus));
    final pointer =
        !disabled &&
        (marks == null ? states.contains(WidgetState.hovered) : keys);
    final here = keys || pointer;
    final own = TermStyleOf([style, theme.menuStyle], states);
    final ink = danger ? theme.danger : own.foreground ?? theme.foreground;
    // A press shows as the press, the cursor stepping aside for it. The
    // cursor jumps from row to row as a terminal's does: a glide would
    // leave two rows lit as it moves, and a menu has one current row.
    final row = Builder(
      builder: (context) {
        final cursor = keys && !pressed ? 1.0 : 0.0;
        final hollow = chosen;
        Color onCursor(Color rest) =>
            termCursorInk(theme, rest, cursor, hollow: hollow);
        final words = disabled
            ? theme.rule
            : lit
            ? onCursor(theme.background)
            : onCursor(here && !danger ? theme.accent : ink);
        final bar = !lit
            ? const Color(0x00000000)
            : pointer && !danger && !keys
            ? theme.accent
            : own.fill ?? ink;
        return ColoredBox(
          color: hollow ? bar.withValues(alpha: bar.a * (1 - cursor)) : bar,
          child: TermCursorCells(
            focus: cursor,
            hollow: hollow,
            child: _rowCells(context, words, lit, onCursor),
          ),
        );
      },
    );
    if (marks == null || disabled) return row;
    return MouseRegion(
      // A move, not a row coming up under a resting pointer.
      onHover: (_) {
        final node = Focus.maybeOf(context);
        if (node != null && node is! FocusScopeNode && !node.hasPrimaryFocus) {
          node.requestFocus();
        }
        TermMenuMarks.show(context);
      },
      child: row,
    );
  }

  Widget _rowCells(
    BuildContext context,
    Color words,
    bool lit,
    Color Function(Color rest) onCursor,
  ) {
    final theme = TermTheme.of(context);
    final grid = context.termGrid;
    final cw = grid.cellWidth;
    final touch = DesignTapTargets.of(context).inputOn() == DesignInput.touch;
    return SizedBox(
      height: grid.lineHeight * (touch ? 2 : 1),
      child: Padding(
        padding: EdgeInsetsDirectional.symmetric(horizontal: cw),
        child: Row(
          children: [
            if (checked != null)
              SizedBox(
                width: grid.cols(2),
                child: ExcludeSemantics(
                  child: Text(
                    checked! ? '•' : ' ',
                    style: theme.textStyle.copyWith(color: words),
                  ),
                ),
              ),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
                style: theme.textStyle.copyWith(color: words),
              ),
            ),
            if (trailing != null) ...[
              SizedBox(width: grid.cols(2)),
              ExcludeSemantics(
                child: Text(
                  trailing!,
                  style: theme.textStyle.copyWith(
                    color: onCursor(lit ? theme.background : theme.dim),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A menu opening from its anchor: revealed from the anchor's side, the
/// menu itself never moving, as wide as it is from its first frame and the
/// same tree once open.
class TermMenuReveal extends StatelessWidget {
  /// Reveals [child] by [info]'s presence.
  const TermMenuReveal({super.key, required this.info, required this.child});

  /// The overlay's place and presence.
  final DesignOverlayInfo info;

  /// The menu.
  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: info.animation,
    builder: (context, child) {
      // A spring only nears 1: within a hair of it, the menu is open.
      final v = info.animation.value;
      final t = v >= 0.995 ? 1.0 : v.clamp(0.0, 1.0);
      return ClipRect(
        clipBehavior: t >= 1 ? Clip.none : Clip.hardEdge,
        child: Align(
          alignment: info.side == DesignOverlaySide.above
              ? AlignmentDirectional.bottomStart
              : AlignmentDirectional.topStart,
          widthFactor: 1,
          heightFactor: t,
          child: child,
        ),
      );
    },
    child: ConstrainedBox(
      constraints: BoxConstraints(maxHeight: info.maxSize.height),
      child: child,
    ),
  );
}

/// A pair of brackets one line tall round [child], in the rule's ink, at
/// its middle line however tall the targets inside make it. Under the
/// keyboard's [focus] the cursor stands on the brackets' cells, the
/// brackets cut out of it.
class TermBracketBand extends StatelessWidget {
  /// Brackets round [child].
  const TermBracketBand({
    super.key,
    required this.child,
    this.focus = 0,
    this.edge,
  });

  /// The brackets' ink at rest; null: the rule's.
  final Color? edge;

  /// What sits in the brackets.
  final Widget child;

  /// How far the keyboard's focus has come, 0 to 1.
  final double focus;

  @override
  Widget build(BuildContext context) {
    final theme = TermTheme.of(context);
    final grid = context.termGrid;
    return Stack(
      children: [
        Positioned.fill(
          child: Center(
            child: SizedBox(
              height: grid.lineHeight,
              width: double.infinity,
              child: CustomPaint(
                painter: TermBracketPainter(
                  grid: grid,
                  color: edge ?? theme.rule,
                  stroke: termStroke(theme, grid),
                  cursor: focus,
                  cursorColor: theme.accent,
                  knockout: theme.onAccent,
                  hollow: true,
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsetsDirectional.symmetric(horizontal: grid.cellWidth),
          child: child,
        ),
      ],
    );
  }
}

/// One choice's cells inside brackets: [label] a cell either side, in
/// inverse video when [on], the press filling in, the keyboard's focus the
/// cursor on its cells ([TermCursorCells]; on a chosen one, hollow: its end
/// cells in the accent, its fill cleared, its words in the accent).
class TermCellFace extends StatelessWidget {
  /// A face saying [label].
  const TermCellFace({
    super.key,
    required this.label,
    required this.on,
    required this.enabled,
    required this.press,
    required this.focus,
    this.padCols = 1,
    this.fill,
    this.foreground,
  });

  /// The chosen fill; null: the words' ink (inverse video).
  final Color? fill;

  /// The words at rest; null: the theme's.
  final Color? foreground;

  /// The words.
  final String label;

  /// Whether it is chosen.
  final bool on;

  /// Whether it can be pressed.
  final bool enabled;

  /// How far a press has come, 0 to 1.
  final double press;

  /// How far the keyboard's focus has come, 0 to 1.
  final double focus;

  /// The cells either side of the words.
  final int padCols;

  @override
  Widget build(BuildContext context) {
    final theme = TermTheme.of(context);
    final grid = context.termGrid;
    final ink = fill ?? theme.foreground;
    final rest = foreground ?? theme.foreground;
    final cursor = enabled ? focus : 0.0;
    final ground = !enabled
        ? (on ? theme.rule.withValues(alpha: 0.4) : null)
        : on
        ? ink.withValues(alpha: ink.a * (1 - cursor))
        : press > 0
        ? rest.withValues(alpha: 0.3 * press)
        : null;
    final words = !enabled
        ? theme.rule
        : termCursorInk(
            theme,
            on ? theme.background : rest,
            cursor,
            hollow: on,
          );
    return ColoredBox(
      color: ground ?? const Color(0x00000000),
      child: TermCursorCells(
        focus: cursor,
        hollow: on,
        child: SizedBox(
          height: grid.lineHeight,
          child: Padding(
            padding: EdgeInsetsDirectional.symmetric(
              horizontal: grid.cols(padCols),
            ),
            child: Center(
              widthFactor: 1,
              child: Text(
                label,
                maxLines: 1,
                softWrap: false,
                style: theme.textStyle.copyWith(color: words),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A button's face: [label] in brackets one line tall, [padCols] either
/// side, filled in the accent when [filled], the press filling in, the
/// keyboard's focus the cursor over it, its brackets cut out (hollow when
/// [filled]).
class TermBracketFace extends StatelessWidget {
  /// A face saying [label].
  const TermBracketFace({
    super.key,
    required this.label,
    required this.enabled,
    required this.press,
    required this.focus,
    this.filled = false,
    this.padCols = 2,
    this.danger = false,
    this.fill,
    this.foreground,
    this.edge,
    this.textStyle,
  });

  /// The fill between the brackets; null: the look's.
  final Color? fill;

  /// The words; null: the look's.
  final Color? foreground;

  /// The brackets; null: the look's.
  final Color? edge;

  /// The words' colour and weight.
  final TextStyle? textStyle;

  /// The words in the brackets.
  final String label;

  /// Whether it can be pressed.
  final bool enabled;

  /// How far a press has come, 0 to 1.
  final double press;

  /// How far the keyboard's focus has come, 0 to 1.
  final double focus;

  /// Whether it is filled in the accent.
  final bool filled;

  /// The cells between a bracket and the words.
  final int padCols;

  /// Whether it destroys something: the danger ink.
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final theme = TermTheme.of(context);
    final grid = context.termGrid;
    final ink = danger ? theme.danger : theme.accent;
    final Color words;
    final Color brackets;
    final Color? ground;
    final double amount;
    if (!enabled) {
      words = theme.rule;
      brackets = theme.rule.withValues(alpha: 0.6);
      ground = filled ? theme.rule.withValues(alpha: 0.35) : null;
      amount = 1;
    } else if (filled) {
      ground = Color.lerp(fill ?? ink, theme.foreground, press * 0.4);
      amount = 1;
      words = termCursorInk(
        theme,
        foreground ?? theme.onAccent,
        focus,
        hollow: true,
      );
      brackets = edge ?? fill ?? ink;
    } else {
      final base = danger ? theme.danger : theme.foreground;
      ground = fill ?? base;
      amount = press;
      words = termCursorInk(
        theme,
        Color.lerp(foreground ?? base, theme.background, press)!,
        focus,
      );
      brackets = edge ?? theme.rule;
    }
    return CustomPaint(
      painter: TermBracketPainter(
        grid: grid,
        color: brackets,
        stroke: termStroke(theme, grid),
        fill: ground,
        fillAmount: amount,
        cursor: enabled ? focus : 0,
        cursorColor: theme.accent,
        knockout: theme.onAccent,
        hollow: filled,
      ),
      child: SizedBox(
        height: grid.lineHeight,
        child: Padding(
          padding: EdgeInsetsDirectional.symmetric(
            horizontal: grid.cols(padCols),
          ),
          child: Center(
            widthFactor: 1,
            child: Text(
              label,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
              style: theme.textStyle.merge(textStyle).copyWith(color: words),
            ),
          ),
        ),
      ),
    );
  }
}
