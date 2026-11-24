import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../theme.dart';
import 'paint.dart';
import 'spring.dart';
import 'underline.dart';

/// A link's words in [states]: underlined in the action colour (in the
/// words' own ink when [quiet]); a pointer over them thickens the line and
/// deepens the colour, a press takes them the rest of the way to the ink,
/// and a keyboard focus lays them on the yellow plate over the ink bar. A
/// link's painting without its pressable, for a part whose whole face is
/// the target (a card's title). Plumbing; pages never place one.
class CivicLinkFace extends StatelessWidget {
  /// [child]'s words drawn as a link in [states].
  const CivicLinkFace({
    super.key,
    required this.states,
    required this.child,
    this.quiet = false,
    this.textStyle,
    this.style,
  });

  /// The pressable's states.
  final Set<WidgetState> states;

  /// The words.
  final Widget child;

  /// Whether the words keep their own ink rather than the action colour.
  final bool quiet;

  /// The words' style, over the body's; its colour, when it has one, is
  /// the ink at rest.
  final TextStyle? textStyle;

  /// Overrides over [CivicThemeData.linkStyle].
  final CivicStyle? style;

  @override
  Widget build(BuildContext context) {
    final t = context.civicTheme;
    final so = RawStyleOf([style, t.linkStyle], states);
    final base = context.civicText.body.merge(so.textStyle).merge(textStyle);
    final disabled = states.contains(WidgetState.disabled);
    // A colour in [textStyle] is the link's ink at rest.
    final ink = disabled
        ? t.textDisabled
        : textStyle?.color ??
              so.foreground ??
              (quiet ? t.textPrimary : t.action);
    // A pointer over it thickens the line under the words and deepens
    // their colour; a press takes them the rest of the way to the ink, as
    // a link held down does on a public service's page.
    final held = states.contains(WidgetState.pressed) ? 1.0 : 0.0;
    Color deep(double amount) =>
        Color.lerp(ink, t.textPrimary, 0.45 * amount + 0.55 * held)!;
    final touched =
        states.contains(WidgetState.pressed) ||
        states.contains(WidgetState.hovered);
    return CivicSpringValue(
      value: touched ? 1 : 0,
      spring: CivicMotion.press,
      builder: (context, press, _) => CivicSpringValue(
        value: states.contains(WidgetState.focused) ? 1 : 0,
        spring: CivicMotion.focus,
        effects: true,
        builder: (context, focus, _) => CustomPaint(
          painter: CivicFacePainter(
            fill: t.focus.withValues(alpha: 0),
            edgeColor: t.onFocus,
            edgeHeight: 0,
            press: 0,
            focus: focus,
            focusColor: t.focus,
            barColor: t.focusBar,
            outset: CivicMetrics.edge,
          ),
          child: Padding(
            padding: const EdgeInsets.only(bottom: CivicMetrics.bar),
            child: IconTheme.merge(
              data: IconThemeData(
                color: Color.lerp(deep(press), t.onFocus, focus),
              ),
              child: CivicUnderlined(
                style: base.copyWith(
                  color: Color.lerp(deep(press), t.onFocus, focus),
                  decoration: disabled
                      ? TextDecoration.none
                      : TextDecoration.underline,
                  decorationColor: Color.lerp(
                    deep(press),
                    t.onFocus.withValues(alpha: 0),
                    focus,
                  ),
                  decorationThickness: 1.2 + 1.8 * press,
                ),
                // Words over two lines are as wide as their longest.
                child: DefaultTextStyle.merge(
                  textWidthBasis: TextWidthBasis.longestLine,
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
