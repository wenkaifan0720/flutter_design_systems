import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme.dart';
import 'paint.dart';

/// The surface shared by select and combobox lists: the field's own
/// material, square on its 2 pt edge in the field's ink, so the list reads
/// as the field's, opened, not a card floating over the page.
class CivicOptionSurface extends StatelessWidget {
  /// Clips [child] to the inside of the list's edge.
  const CivicOptionSurface({super.key, required this.child});

  /// The scrolling list of options.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = context.civicTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: t.background,
        border: Border.all(color: t.border, width: CivicMetrics.edge),
      ),
      child: Padding(
        padding: const EdgeInsets.all(CivicMetrics.edge),
        child: ClipRect(child: child),
      ),
    );
  }
}

/// One option of a list a field opens (a select's, a combobox's), in
/// Civic's own material, each state its own and none read as another:
///
/// * chosen: the words bold and ticked, standing on the inset rule in the
///   action colour, as the side navigation marks the current place, so the
///   answer is seen at a glance and never only by its tick;
/// * a pointer over it: the row greys between the list's edges (a press a
///   step deeper), a fill and never a line, so it reads as no divider and no
///   second answer;
/// * the keyboard's: the yellow plate over the ink bar, the look's focus.
///   On the plate the chosen option keeps its bold words and tick, and its
///   inset rule gives way: an ink rule at the plate's start read as a gap at
///   the list's edge by night and a second, heavier edge by day.
///
/// Plumbing; pages never place one.
class CivicListOption extends StatelessWidget {
  /// The option saying [label].
  const CivicListOption({
    super.key,
    required this.label,
    required this.chosen,
    this.hovered = false,
    this.pressed = false,
    this.focused = false,
    this.enabled = true,
  });

  /// What it says.
  final String label;

  /// Whether it is the answer chosen.
  final bool chosen;

  /// Whether a pointer is over it.
  final bool hovered;

  /// Whether a press is held on it.
  final bool pressed;

  /// Whether the keyboard has reached it.
  final bool focused;

  /// Whether it can be chosen.
  final bool enabled;

  /// The tick's room, kept by every option so the words never move.
  static const double tick = 24;

  @override
  Widget build(BuildContext context) {
    final t = context.civicTheme;
    final text = context.civicText;
    final ink = !enabled
        ? t.textDisabled
        : focused
        ? t.onFocus
        : t.textPrimary;
    final touched = enabled && !focused && (hovered || pressed);
    return CustomPaint(
      painter: CivicFacePainter(
        fill: touched
            ? Color.lerp(t.surface, t.rule, pressed ? 0.8 : 0.5)!
            : t.background,
        edgeColor: t.onFocus,
        edgeHeight: 0,
        press: 0,
        focus: focused ? 1 : 0,
        focusColor: t.focus,
        barColor: t.focusBar,
      ),
      foregroundPainter: chosen && !focused
          ? _ChosenRule(color: t.action, direction: Directionality.of(context))
          : null,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: CivicMetrics.controlHeight,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: CivicSpacing.s12,
            vertical: CivicSpacing.s8,
          ),
          child: Row(
            spacing: CivicSpacing.s8,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: (chosen ? text.label : text.body).copyWith(color: ink),
                ),
              ),
              if (chosen)
                Icon(LucideIcons.check, size: tick, color: ink)
              else
                const SizedBox(width: tick),
            ],
          ),
        ),
      ),
    );
  }
}

/// The chosen option's inset rule, down its start.
class _ChosenRule extends CustomPainter {
  _ChosenRule({required this.color, required this.direction});

  final Color color;
  final TextDirection direction;

  @override
  void paint(Canvas canvas, Size size) {
    const w = CivicMetrics.insetRule;
    final x = direction == TextDirection.rtl ? size.width - w : 0.0;
    canvas.drawRect(
      Rect.fromLTWH(x, 0, w, size.height),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(_ChosenRule old) =>
      old.color != color || old.direction != direction;
}
