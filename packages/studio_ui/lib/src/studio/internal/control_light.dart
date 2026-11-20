import 'package:flutter/widgets.dart';

import '../surface.dart';
import '../theme.dart';

/// Intensity of the pilot light for the control's current state.
double studioControlLight(Set<WidgetState> states) {
  if (states.contains(WidgetState.disabled)) return 0;
  if (states.contains(WidgetState.focused)) return 0.72;
  return states.contains(WidgetState.hovered) ? 0.14 : 0;
}

/// The rim light of a part whose lamp is already [lit], on focus: a brighter
/// lamp would barely show, so the part's rim glows at full strength, as a
/// focused latched key's does by day. Clear when the part is unfocused,
/// disabled or its lamp is out.
Color studioLitFocus(
  StudioColors c,
  Set<WidgetState> states, {
  required bool lit,
}) =>
    lit &&
        states.contains(WidgetState.focused) &&
        !states.contains(WidgetState.disabled)
    ? c.focusRing
    : c.focusRing.withValues(alpha: 0);

/// Brightens the lens without changing its latched state or its housing.
class StudioControlLamp extends StatelessWidget {
  /// A pilot lens showing the latched value and current input state.
  const StudioControlLamp({
    super.key,
    required this.on,
    required this.states,
    this.color,
    this.size = StudioMetrics.lampSize,
  });

  /// Whether the indicator is latched on.
  final bool on;

  /// The interaction states of the surrounding control.
  final Set<WidgetState> states;

  /// The lens colour, or the theme signal when omitted.
  final Color? color;

  /// The diameter of the lens in logical pixels.
  final double size;

  @override
  Widget build(BuildContext context) {
    final amount = studioControlLight(states);
    final light = color ?? StudioTheme.of(context).colors.indicator;
    return Stack(
      children: [
        StudioLamp(on: on, color: light, size: size),
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
