// One of many small equal choices (a day of a month, an hour, a year, a swatch): a figure on its holder's own surface,
// with no face of its own. A pointer resting on it raises a soft bump under it, a press sinks it, and only the chosen one
// is a well. Thirty raised keys would be a keyboard, each shadow running into the next one's light.
import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../component_themes.dart';
import '../frames.dart';
import '../theme.dart';

/// [child] (a figure) on its holder's surface, under a soft bump while [hovered] and a shallow well while [pressed] or
/// [chosen]. The bump and the well are cut by [shape].
class NeumorphicDayFace extends StatelessWidget {
  /// A figure with no face of its own until it is pointed at, pressed or chosen.
  const NeumorphicDayFace({
    super.key,
    required this.shape,
    required this.hovered,
    required this.pressed,
    this.chosen = false,
    this.style,
    this.themeStyle,
    this.states = const {},
    required this.child,
  });

  /// The bump's and the well's outline.
  final OutlinedBorder shape;

  /// Whether a pointer rests on it.
  final bool hovered;

  /// Whether it is held down.
  final bool pressed;

  /// Whether it is the chosen one: a well under its figure.
  final bool chosen;

  /// The part's own style and its component theme, for the well's face.
  final NeumorphicStyle? style, themeStyle;

  /// The part's states, for the well's face.
  final Set<WidgetState> states;

  /// The figure.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final motion = NeumorphicMotion.of(context);
    final flat = NeumorphicFlatScope.of(context);
    final figure = KeyedSubtree(key: const ValueKey('figure'), child: child);
    return TweenAnimationBuilder<double>(
      tween: Tween(end: hovered && !pressed && !chosen ? 1 : 0),
      duration: motion.state,
      curve: motion.standard,
      builder: (context, lift, _) => Stack(
        fit: StackFit.expand,
        children: [
          if (pressed || chosen)
            NeumorphicSurface(
              key: const ValueKey('well'),
              style: style,
              themeStyle: themeStyle,
              shape: shape,
              states: states,
              cast: NeumorphicSurfaceLevel.groove,
              outlined: true,
              child: const SizedBox.expand(),
            )
          else if (lift > 0)
            // A soft bump: the part's relief at a little over half, rising with the pointer.
            NeumorphicFlatScope(
              key: const ValueKey('bump'),
              flat: flat,
              relief: math.min(1, lift * .55),
              child: NeumorphicSurface(
                shape: shape,
                cast: NeumorphicSurfaceLevel.part,
                outlined: true,
                child: const SizedBox.expand(),
              ),
            ),
          figure,
        ],
      ),
    );
  }
}
