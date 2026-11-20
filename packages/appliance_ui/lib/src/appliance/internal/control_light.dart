import 'package:flutter/widgets.dart';

import '../material.dart';
import '../theme.dart';

/// Intensity of the pilot light for the control's current state.
double applianceControlLight(Set<WidgetState> states) {
  if (states.contains(WidgetState.disabled)) return 0;
  if (states.contains(WidgetState.focused)) return 0.78;
  return states.contains(WidgetState.hovered) ? 0.14 : 0;
}

/// The focus backlight of a part whose lamp is already [lit]: a brighter
/// lamp would barely show, so the part's own bezel lights from inside.
/// Clear when the part is unfocused, disabled or its lamp is out.
Color applianceLitFocus(
  ApplianceColors c,
  Set<WidgetState> states, {
  required bool lit,
}) =>
    lit &&
        states.contains(WidgetState.focused) &&
        !states.contains(WidgetState.disabled)
    ? c.focus
    : c.focus.withValues(alpha: 0);

/// Brightens the lens without changing its latched state or its housing.
class ApplianceControlLamp extends StatelessWidget {
  /// A pilot lens showing the latched value and current input state.
  const ApplianceControlLamp({
    super.key,
    required this.lit,
    required this.states,
    this.color,
    this.size = ApplianceMetrics.lampSize,
  });

  /// Whether the indicator is latched on.
  final bool lit;

  /// The interaction states of the surrounding control.
  final Set<WidgetState> states;

  /// The lens colour, or the theme signal when omitted.
  final Color? color;

  /// The diameter of the lens in logical pixels.
  final double size;

  @override
  Widget build(BuildContext context) {
    final amount = applianceControlLight(states);
    final light = color ?? ApplianceTheme.of(context).colors.signal;
    return Stack(
      children: [
        ApplianceLamp(lit: lit, color: light, size: size),
        if (amount > 0)
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Color.lerp(
                      light,
                      const Color(0xFFFFFFFF),
                      0.65,
                    )!.withValues(alpha: amount),
                    light.withValues(alpha: amount * 0.45),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
