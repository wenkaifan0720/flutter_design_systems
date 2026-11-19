import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme.dart';
import 'paint.dart';
import 'spring.dart';

/// The face a choice wears (a toggle, a segment, a chip, a day): Civic's
/// button material with its state read from [states]. Chosen, it is solid
/// in the action colour with its words in the face's own colour and a
/// tick before them, so the choice reads without colour; not chosen, the
/// action's tint with its words in the action colour. A pointer over it
/// deepens it, a press sinks it onto its solid edge (or, with no edge,
/// deepens it a step more), a keyboard focus floods it yellow over the ink
/// bar; a face that cannot be used greys. Plumbing of the choice parts.
class CivicChoiceFace extends StatelessWidget {
  /// A choice's face.
  const CivicChoiceFace({
    super.key,
    required this.states,
    required this.child,
    this.styles = const [],
    this.edge = true,
    this.tick = true,
    this.radius = CivicMetrics.corner,
    this.padding,
    this.minHeight = CivicMetrics.controlHeight,
    this.textStyle,
    this.leading,
    this.alignment = AlignmentDirectional.center,
  });

  /// The face's states: selected, hovered, pressed, focused, disabled.
  final Set<WidgetState> states;

  /// The words.
  final Widget child;

  /// The styles it reads, first first; fill, foreground and edge by state,
  /// padding and textStyle.
  final List<DesignStyle?> styles;

  /// Whether it stands on a solid edge a press sinks onto (a toggle's, a
  /// segment's); a chip's and a day's faces have none.
  final bool edge;

  /// Whether a chosen face shows a tick before its words.
  final bool tick;

  /// Its corners.
  final double radius;

  /// Room round the words; null: 16 across, 8 over and under.
  final EdgeInsetsGeometry? padding;

  /// Its least height, the edge included.
  final double minHeight;

  /// Its words' style; null: the button's.
  final TextStyle? textStyle;

  /// A glyph before the words (after the tick).
  final Widget? leading;

  /// Where the words stand on the face.
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    final t = context.civicTheme;
    final so = DesignStyleOf(styles, states);
    final selected = states.contains(WidgetState.selected);
    final disabled = states.contains(WidgetState.disabled);
    final (restFill, restInk, restEdge) = disabled
        ? (t.disabledFill, t.textDisabled, t.rule)
        : selected
        ? (t.action, t.onAction, t.actionEdge)
        : (t.secondaryFill, t.onSecondary, t.secondaryEdge);
    final fill = so.fill ?? restFill;
    final ink = so.foreground ?? restInk;
    final under = so.edge ?? restEdge;
    final hovered = !disabled && states.contains(WidgetState.hovered);
    final pressed = !disabled && states.contains(WidgetState.pressed);
    final focused = states.contains(WidgetState.focused);
    final edgeHeight = edge ? CivicMetrics.bar : 0.0;
    final words = (textStyle ?? context.civicText.button).merge(so.textStyle);
    return CivicSpringValue(
      value: pressed ? 2 : (hovered ? 1 : 0),
      spring: CivicMotion.press,
      effects: true,
      builder: (context, touch, _) => CivicSpringValue(
        value: pressed && edge ? 1 : 0,
        spring: CivicMotion.press,
        builder: (context, press, _) => CivicSpringValue(
          value: focused ? 1 : 0,
          spring: CivicMotion.focus,
          effects: true,
          builder: (context, focus, _) {
            // A pointer deepens the face as a button's: a solid one a clear
            // step darker (by night, lighter), a tint a step toward its
            // edge; a press with no edge to sink onto deepens it again.
            final over = selected
                ? (t.isDark
                      ? Color.lerp(fill, const Color(0xFFFFFFFF), 0.25)!
                      : Color.lerp(fill, const Color(0xFF000000), 0.35)!)
                : Color.lerp(fill, under, 0.45)!;
            final deeper = selected ? over : Color.lerp(fill, under, 0.8)!;
            final face = disabled
                ? fill
                : touch <= 1
                ? Color.lerp(fill, over, touch.clamp(0, 1))!
                : Color.lerp(over, edge ? over : deeper, touch - 1)!;
            final fg = Color.lerp(ink, t.onFocus, focus)!;
            final room =
                CivicSpacing.s8 *
                MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.5);
            final content = Row(
              mainAxisSize: MainAxisSize.min,
              spacing: CivicSpacing.s8,
              children: [
                if (selected && tick)
                  Icon(
                    LucideIcons.check,
                    size: 20,
                    color: fg,
                    applyTextScaling: true,
                  ),
                if (leading case final leading?)
                  IconTheme.merge(
                    data: IconThemeData(color: fg, size: 20),
                    child: leading,
                  ),
                Flexible(
                  child: DesignCapCenter(
                    capHeightFactor: context.civicText.capHeight,
                    child: IconTheme.merge(
                      data: IconThemeData(color: fg, size: 22),
                      child: DefaultTextStyle(
                        style: words.copyWith(color: fg),
                        textAlign: TextAlign.center,
                        child: child,
                      ),
                    ),
                  ),
                ),
              ],
            );
            return CustomPaint(
              painter: CivicFacePainter(
                fill: face,
                edgeColor: disabled ? t.rule : under,
                edgeHeight: edgeHeight,
                press: press,
                focus: focus,
                focusColor: t.focus,
                barColor: t.focusBar,
                radius: radius,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: minHeight),
                child: Padding(
                  padding: EdgeInsets.only(
                    top: edgeHeight * press,
                    bottom: edgeHeight * (1 - press),
                  ),
                  child: Padding(
                    padding:
                        so.padding(Directionality.of(context)) ??
                        padding?.resolve(Directionality.of(context)) ??
                        EdgeInsets.symmetric(
                          horizontal: CivicSpacing.s16,
                          vertical: room,
                        ),
                    child: Align(
                      alignment: alignment,
                      widthFactor: 1,
                      heightFactor: 1,
                      child: content,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
