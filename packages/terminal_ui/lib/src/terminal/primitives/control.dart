/// What every Terminal control shares: a target of whole cells at the
/// look's floor, and the press and focus that move in springs.
library;

import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../grid.dart';
import '../theme.dart';
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
    final floor = DesignTapTargets.of(context).floorOn();
    return DesignTapTarget(
      minSize: grid.ceil(floor),
      alignment: alignment,
      child: child,
    );
  }
}

/// Builds a face with how far its press and its keyboard focus have come,
/// each 0 to 1 on Terminal's springs: a press fills in quickly, focus
/// doubles the line with a short glide.
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

  /// Builds the face with the press ([press]) and the focus ([focus]).
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
      builder: (context, focus, _) => builder(context, press, focus),
    ),
  );
}

/// One line's stroke at [grid]: the theme's width grown with the words.
double termStroke(TermThemeData theme, TermGrid grid) =>
    theme.strokeWidth * grid.fontSize / theme.grid.fontSize;
