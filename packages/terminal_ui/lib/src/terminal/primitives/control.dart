/// What every Terminal control shares: a target of whole cells at the
/// look's floor, and the press and focus that move in springs.
library;

import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../grid.dart';
import '../theme.dart';
import 'box.dart';
import 'spring.dart';

/// Lays a control's face out at the look's tap floor, rounded up to whole
/// cells and lines, so a target padded to the floor still ends on the
/// lattice: two lines for a finger, one for a pointer.
class TermTapTarget extends StatelessWidget {
  /// [child] at the floor, placed by [alignment].
  const TermTapTarget({
    super.key,
    this.alignment = AlignmentDirectional.center,
    required this.child,
  });

  /// Where the face stands in its target.
  final AlignmentGeometry alignment;

  /// The face.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final grid = context.termGrid;
    final floor = RawTapTargets.of(context).floorOn();
    return TapTargetPadding(
      minSize: grid.ceil(floor),
      alignment: alignment,
      child: child,
    );
  }
}

/// Builds a face with how far its press and its keyboard focus have come,
/// each 0 to 1 on Terminal's springs: a press fills in quickly, the
/// cursor comes with a short glide (cut under Reduce Motion).
class TermStateSprings extends StatelessWidget {
  /// Springs for [pressed] and [focused].
  const TermStateSprings({
    super.key,
    required this.pressed,
    required this.focused,
    required this.builder,
  });

  /// Whether the control is held down.
  final bool pressed;

  /// Whether the keyboard's focus is on it.
  final bool focused;

  /// Builds the face with the press (`press`) and the focus (`focus`).
  final Widget Function(BuildContext context, double press, double focus)
  builder;

  @override
  Widget build(BuildContext context) => TermSpring(
    target: pressed ? 1 : 0,
    token: TermMotion.press,
    builder: (context, press, _) => TermSpring(
      target: focused ? 1 : 0,
      token: TermMotion.move,
      spatial: true,
      focus: true,
      builder: (context, focus, _) => builder(context, press, focus),
    ),
  );
}

/// One line's stroke at [grid]: the theme's width grown with the words.
double termStrokeWidth(TermThemeData theme, TermGrid grid) =>
    theme.strokeWidth * grid.fontSize / theme.grid.fontSize;

/// The words' colour as the keyboard's focus comes ([focus], 0 to 1): from
/// [rest] towards the ink words take on the cursor's accent, or on a part
/// the cursor hollows ([hollow]: one in inverse video already, its fill
/// cleared) towards the accent on the ground.
Color termCursorInk(
  TermThemeData theme,
  Color rest,
  double focus, {
  bool hollow = false,
}) => Color.lerp(
  rest,
  hollow ? theme.accent : theme.onAccent,
  focus.clamp(0, 1),
)!;

/// The keyboard's focus as Terminal marks it, on cells with no brackets of
/// their own: the cursor ([TermCursorPainter]), a block of the accent over
/// [child]'s cells with a pair of brackets cut out of its end cells, the
/// words in [inkOf]. [hollow] for cells in inverse video already: the
/// cursor takes their end cells, and their fill is the part's to clear.
class TermCursorCells extends StatelessWidget {
  /// [child]'s cells under the cursor by [focus].
  const TermCursorCells({
    super.key,
    required this.focus,
    this.hollow = false,
    required this.child,
  });

  /// How far the keyboard's focus has come, 0 to 1.
  final double focus;

  /// Whether the cells are in inverse video already.
  final bool hollow;

  /// The cells.
  final Widget child;

  /// The words' colour at [rest] under the cursor, [focus] of the way in.
  static Color inkOf(
    BuildContext context,
    Color rest,
    double focus, {
    bool hollow = false,
  }) => termCursorInk(TermTheme.of(context), rest, focus, hollow: hollow);

  @override
  Widget build(BuildContext context) {
    final theme = TermTheme.of(context);
    final grid = context.termGrid;
    return CustomPaint(
      painter: focus <= 0
          ? null
          : TermCursorPainter(
              grid: grid,
              amount: focus,
              color: theme.accent,
              knockout: theme.onAccent,
              stroke: termStrokeWidth(theme, grid),
              hollow: hollow,
            ),
      child: child,
    );
  }
}

/// The keyboard's focus on words with no cells of their own round them (a
/// link, a heading, a crumb): the cursor, a block of the accent behind
/// [child] reaching [reach] cells past it on either side (into the spaces
/// round it), the words in [termCursorInk]. A press fills the words alone,
/// so the two never read as one.
class TermCursorSpan extends StatelessWidget {
  /// [child] under the cursor by [focus].
  const TermCursorSpan({
    super.key,
    required this.focus,
    this.reach = 0.5,
    required this.child,
  });

  /// How far the keyboard's focus has come, 0 to 1.
  final double focus;

  /// How far past the words the block reaches, in cells.
  final double reach;

  /// The words.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // The same tree at rest and under the cursor, so the words keep their
    // state as it comes and goes.
    return CustomPaint(
      painter: focus <= 0
          ? null
          : _SpanCursor(
              amount: focus,
              color: TermTheme.of(context).accent,
              reach: context.termGrid.cellWidth * reach,
            ),
      child: child,
    );
  }
}

class _SpanCursor extends CustomPainter {
  const _SpanCursor({
    required this.amount,
    required this.color,
    required this.reach,
  });

  final double amount;
  final Color color;
  final double reach;

  @override
  void paint(Canvas canvas, Size size) {
    final a = amount.clamp(0.0, 1.0);
    if (a <= 0) return;
    canvas.drawRect(
      Rect.fromLTRB(-reach, 0, size.width + reach, size.height),
      Paint()..color = color.withValues(alpha: color.a * a),
    );
  }

  @override
  bool shouldRepaint(_SpanCursor old) =>
      old.amount != amount || old.color != color || old.reach != reach;
}
