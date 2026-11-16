import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../theme.dart';
import 'paint.dart';
import 'spring.dart';

/// What an option's box shows.
enum CivicMark {
  /// Nothing: unchecked.
  none,

  /// A tick: checked.
  tick,

  /// A bar: some of a group checked.
  dash,

  /// A dot: the chosen radio.
  dot,
}

/// One option of a group, a checkbox's or a radio's: the 40-point box (or
/// circle) at the start, the words beside it with the first line on the
/// box's middle, a hint under the words. The whole row is the target.
/// Plumbing of [CivicCheckbox] and [CivicRadio]; pages never place one.
class CivicOptionRow extends StatelessWidget {
  /// An option.
  const CivicOptionRow({
    super.key,
    required this.mark,
    required this.round,
    required this.onPressed,
    this.styles = const [],
    this.labelText,
    this.helperText,
    this.focusNode,
    this.autofocus = false,
    this.checked,
    this.inMutuallyExclusiveGroup = false,
    this.isError = false,
  });

  /// What the box shows.
  final CivicMark mark;

  /// Whether the box is a circle (a radio).
  final bool round;

  /// Called on a press; null disables it.
  final VoidCallback? onPressed;

  /// The styles it reads, first first: the part's `style:`, then its
  /// theme's. It reads fill (the box), foreground (the mark and the words),
  /// edge (the box's edge) and textStyle (the words).
  final List<CivicStyle?> styles;

  /// The words; null stands the box alone (its caller names it).
  final String? labelText;

  /// A hint under the words.
  final String? helperText;

  /// {@macro civic.focusNode}
  final FocusNode? focusNode;

  /// {@macro civic.autofocus}
  final bool autofocus;

  /// Whether a screen reader hears it checked; null for mixed.
  final bool? checked;

  /// Whether it is one of a group only one of which is chosen.
  final bool inMutuallyExclusiveGroup;

  /// Whether its group shows an error.
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final t = context.civicTheme;
    final text = context.civicText;
    final words = text.body;
    final line = (words.fontSize ?? 19) * (words.height ?? 1.45);
    final scaled = MediaQuery.textScalerOf(context).scale(line);
    // The first line's middle on the box's: the words drop by what is left,
    // or, at a large text size, the box by what the line has over it.
    final drop = math.max(0.0, (CivicMetrics.box - scaled) / 2);
    final boxDrop = math.max(0.0, (scaled - CivicMetrics.box) / 2);
    final label = labelText;
    final helper = helperText;
    return DesignPressable(
      onPressed: onPressed,
      focusNode: focusNode,
      autofocus: autofocus,
      button: false,
      checked: checked ?? false,
      mixed: checked == null,
      inMutuallyExclusiveGroup: inMutuallyExclusiveGroup,
      semanticLabel: label,
      semanticHint: helper,
      excludeSemantics: true,
      mouseCursor: onPressed == null
          ? SystemMouseCursors.basic
          : SystemMouseCursors.click,
      builder: (context, states, _) {
        final so = DesignStyleOf(styles, states);
        final disabled = states.contains(WidgetState.disabled);
        final focused = states.contains(WidgetState.focused);
        // A pointer over it rings the box in the rule's grey, a press a
        // shade deeper: the box answers before it is ticked.
        final touch = disabled
            ? 0.0
            : states.contains(WidgetState.pressed)
            ? 2.0
            : states.contains(WidgetState.hovered)
            ? 1.0
            : 0.0;
        final ink =
            so.foreground ?? (disabled ? t.textDisabled : t.textPrimary);
        final box = CivicSpringValue(
          value: touch,
          spring: CivicMotion.press,
          effects: true,
          builder: (context, halo, _) => CivicSpringValue(
            value: focused ? 1 : 0,
            spring: CivicMotion.focus,
            effects: true,
            builder: (context, focus, _) => CustomPaint(
              painter: _HaloPainter(
                color: halo <= 1
                    ? t.rule.withValues(alpha: t.rule.a * halo.clamp(0, 1))
                    : Color.lerp(t.rule, t.textSecondary, 0.35 * (halo - 1))!,
                hidden: focus,
                round: round,
              ),
              child: CivicSpringValue(
                value: mark == CivicMark.none ? 0 : 1,
                spring: CivicMotion.press,
                effects: true,
                builder: (context, on, _) => CustomPaint(
                  size: const Size.square(CivicMetrics.box),
                  painter: CivicWellPainter(
                    fill: so.fill ?? (disabled ? t.disabledFill : t.background),
                    edgeColor: so.edge ?? (disabled ? t.rule : t.border),
                    focus: focus,
                    focusColor: t.focus,
                    focusEdgeColor: t.border,
                    circle: round,
                  ),
                  foregroundPainter: _MarkPainter(
                    mark: mark,
                    amount: on,
                    color: ink,
                    direction: Directionality.of(context),
                  ),
                ),
              ),
            ),
          ),
        );
        final card = _OnCard.of(context);
        return ColoredBox(
          // On a card the whole row answers a pointer, as an app's row does.
          color: card && !disabled && touch > 0
              ? Color.lerp(
                  t.surface,
                  t.rule,
                  0.3 * (touch - 1).clamp(0.0, 1.0),
                )!
              : const Color(0x00000000),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: card ? 56 : CivicMetrics.controlHeight,
            ),
            child: Padding(
              padding: card
                  ? const EdgeInsets.symmetric(
                      horizontal: CivicSpacing.s16,
                      vertical: CivicSpacing.s8,
                    )
                  : const EdgeInsets.symmetric(vertical: CivicSpacing.s4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: label == null
                    ? MainAxisSize.min
                    : MainAxisSize.max,
                children: [
                  if (label == null)
                    box
                  else
                    Padding(
                      padding: EdgeInsets.only(top: boxDrop),
                      child: box,
                    ),
                  if (label != null) ...[
                    const SizedBox(width: CivicSpacing.s12),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(top: drop),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              label,
                              style: words
                                  .merge(so.textStyle)
                                  .copyWith(color: ink),
                            ),
                            if (helper != null)
                              Padding(
                                padding: const EdgeInsets.only(
                                  top: CivicSpacing.s4,
                                ),
                                child: Text(helper, style: text.caption),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Options (radios, checkboxes) as an app sets them: each a row on one card,
/// white on the page's ground, hairlines between, the whole row pressed.
class CivicOptionCard extends StatelessWidget {
  /// A card of [children], each an option.
  const CivicOptionCard({super.key, required this.children});

  /// The options.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final t = context.civicTheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(CivicMetrics.cardCorner),
      child: ColoredBox(
        color: t.background,
        child: _OnCard(
          child: CivicCardScope(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final (i, child) in children.indexed) ...[
                  if (i > 0)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(
                        start: CivicSpacing.s16,
                      ),
                      child: SizedBox(
                        height: 1,
                        child: ColoredBox(color: t.hairline),
                      ),
                    ),
                  child,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Marks what stands on a card already (a [CivicListGroup], a
/// [CivicOptionCard], a summary card), so a part that stands its own card in
/// an app (a radio group, a fieldset of checkboxes, a summary list) stands
/// no second one inside it.
class CivicCardScope extends InheritedWidget {
  /// [child] stands on a card.
  const CivicCardScope({super.key, required super.child});

  /// Whether [context] stands on a card.
  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<CivicCardScope>() != null;

  /// Whether a part at [context] stands its own card: in an app
  /// ([CivicLayout.isApp]), not on a card already.
  static bool cards(BuildContext context) =>
      CivicLayout.isApp(MediaQuery.sizeOf(context).width) && !of(context);

  @override
  bool updateShouldNotify(CivicCardScope oldWidget) => false;
}

class _OnCard extends InheritedWidget {
  const _OnCard({required super.child});

  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_OnCard>() != null;

  @override
  bool updateShouldNotify(_OnCard oldWidget) => false;
}

class _MarkPainter extends CustomPainter {
  _MarkPainter({
    required this.mark,
    required this.amount,
    required this.color,
    required this.direction,
  });

  final CivicMark mark;
  final double amount;
  final Color color;
  final TextDirection direction;

  @override
  void paint(Canvas canvas, Size size) {
    final a = amount.clamp(0.0, 1.0);
    if (a <= 0 || mark == CivicMark.none) return;
    final c = size.center(Offset.zero);
    final paint = Paint()..color = color;
    switch (mark) {
      case CivicMark.none:
        return;
      case CivicMark.dot:
        canvas.drawCircle(c, 10 * a, paint);
      case CivicMark.dash:
        canvas.drawRect(
          Rect.fromCenter(center: c, width: 20 * a, height: 5),
          paint,
        );
      case CivicMark.tick:
        // A tick of two square-ended strokes, drawn in as it arrives. It
        // reads the same way in either direction (a tick is not words).
        final stroke = Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5
          ..strokeCap = StrokeCap.square
          ..strokeJoin = StrokeJoin.miter;
        final p0 = c + const Offset(-10, 0);
        final p1 = c + const Offset(-3, 7);
        final p2 = c + const Offset(11, -8);
        final path = Path()..moveTo(p0.dx, p0.dy);
        final first = (p1 - p0).distance;
        final second = (p2 - p1).distance;
        final drawn = (first + second) * a;
        if (drawn <= first) {
          final q = Offset.lerp(p0, p1, drawn / first)!;
          path.lineTo(q.dx, q.dy);
        } else {
          path.lineTo(p1.dx, p1.dy);
          final q = Offset.lerp(p1, p2, (drawn - first) / second)!;
          path.lineTo(q.dx, q.dy);
        }
        canvas.drawPath(path, stroke);
    }
  }

  @override
  bool shouldRepaint(_MarkPainter old) =>
      old.mark != mark ||
      old.amount != amount ||
      old.color != color ||
      old.direction != direction;
}

/// The ring round a box a pointer is over or a press is on: 8 points wide,
/// outside the box, behind it; gone while the focus's own ring shows.
class _HaloPainter extends CustomPainter {
  _HaloPainter({
    required this.color,
    required this.hidden,
    required this.round,
  });

  final Color color;
  final double hidden;
  final bool round;

  static const double _width = 8;

  @override
  void paint(Canvas canvas, Size size) {
    final c = color.withValues(alpha: color.a * (1 - hidden.clamp(0.0, 1.0)));
    if (c.a <= 0) return;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _width
      ..color = c;
    final ring = (Offset.zero & size).inflate(_width / 2);
    if (round) {
      canvas.drawOval(ring, paint);
    } else {
      canvas.drawRect(ring, paint);
    }
  }

  @override
  bool shouldRepaint(_HaloPainter old) =>
      old.color != color || old.hidden != hidden || old.round != round;
}
