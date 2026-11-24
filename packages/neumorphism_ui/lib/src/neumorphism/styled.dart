// How a styled part reads its style and draws its shape: the layers in order, and a shape that animates to each new
// one, as a Material 3 button's does when a state changes it.
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'component_themes.dart';
import 'theme.dart';

/// States supplied by the closest pressable to the face it paints. A nested
/// control supplies its own set, so an inner action never inherits a parent's
/// press. Components add their own selected, disabled or error state.
///
/// ```dart
/// final states = NeumorphicStatesScope.of(context);
/// ```
class NeumorphicStatesScope extends InheritedWidget {
  /// Provides [states] to the control's descendants.
  const NeumorphicStatesScope({
    super.key,
    required this.states,
    required super.child,
  });

  /// The closest pressable's states.
  final Set<WidgetState> states;

  /// The current states, or none outside a pressable.
  static Set<WidgetState> of(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<NeumorphicStatesScope>()
          ?.states ??
      const {};

  @override
  bool updateShouldNotify(NeumorphicStatesScope oldWidget) =>
      !setEquals(states, oldWidget.states);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IterableProperty<WidgetState>('states', states));
  }
}

/// Builds [builder] with [shape], easing to each new shape over the motion's state duration (a cut under Reduce
/// Motion). Neumorphism's shapes morph into each other; other shapes snap at the middle. A null shape builds at once with
/// null: the part draws its own.
///
/// ```dart
/// AnimatedNeumorphicShape(
///   shape: pressed ? const NeumorphicStadiumBorder() : const NeumorphicRoundedBorder(),
///   builder: (context, shape) => DecoratedBox(
///     decoration: ShapeDecoration(color: fill, shape: shape!),
///   ),
/// )
/// ```
class AnimatedNeumorphicShape extends StatelessWidget {
  /// Eases to [shape] whenever it changes.
  const AnimatedNeumorphicShape({
    super.key,
    required this.shape,
    required this.builder,
  });

  /// The shape to ease to.
  final OutlinedBorder? shape;

  /// What draws the shape, given the shape at this frame.
  final Widget Function(BuildContext context, OutlinedBorder? shape) builder;

  @override
  Widget build(BuildContext context) {
    final motion = NeumorphicMotion.of(context);
    return RepaintBoundary(
      child: _ShapeAnimation(
        shape: shape,
        builder: builder,
        duration: motion.state,
        curve: motion.standard,
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(
        DiagnosticsProperty<OutlinedBorder>('shape', shape, defaultValue: null),
      )
      ..add(
        ObjectFlagProperty<
          Widget Function(BuildContext context, OutlinedBorder? shape)
        >.has('builder', builder),
      );
  }
}

class _ShapeAnimation extends ImplicitlyAnimatedWidget {
  const _ShapeAnimation({
    required this.shape,
    required this.builder,
    required super.duration,
    required super.curve,
  });

  final OutlinedBorder? shape;
  final Widget Function(BuildContext, OutlinedBorder?) builder;

  @override
  AnimatedWidgetBaseState<_ShapeAnimation> createState() =>
      _ShapeAnimationState();
}

class _ShapeAnimationState extends AnimatedWidgetBaseState<_ShapeAnimation> {
  _ShapeTween? _shape;

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _shape = visitor(
      _shape,
      widget.shape,
      (dynamic value) => _ShapeTween(begin: value as ShapeBorder),
    ) as _ShapeTween?;
  }

  @override
  Widget build(BuildContext context) {
    final now = _shape?.evaluate(animation);
    // Keep the same builder position for natural and custom shapes. Inserting
    // or removing an animation wrapper would reset a caller's stateful content.
    return widget.builder(context, now is OutlinedBorder ? now : widget.shape);
  }
}

// Material's ShapeBorderTween, without Material.
class _ShapeTween extends Tween<ShapeBorder?> {
  _ShapeTween({super.begin});

  @override
  ShapeBorder? lerp(double t) => ShapeBorder.lerp(begin, end, t);
}

/// A styled part's layers for its states: its own `style:`, then its component theme. Each getter is the first layer's
/// value for the states, or null, so the part goes on to the theme-wide knobs and its own default.
///
/// ```dart
/// final look = NeumorphicStyleOf([style, NeumorphicTheme.of(context).chipTheme], states);
/// final fill = look.fill ?? colors.faceStart;
/// ```
///
/// It is ui_core's [RawStyleOf] under the look's name; [RawStyleOf.freeze] holds one set of states as a
/// style.
typedef NeumorphicStyleOf = RawStyleOf;

/// An explicit styled rim or the high-contrast outline; otherwise none, and the relief draws the edge.
///
/// ```dart
/// final look = NeumorphicStyleOf([style, theme.cardTheme], const {});
/// final rim = neumorphicRim(theme, look, theme.colors.edge);
/// ```
BorderSide neumorphicRim(
  NeumorphicThemeData theme,
  NeumorphicStyleOf look,
  Color fallback, [
  double own = 1,
]) =>
    look.side ??
    (look.edge != null || theme.highContrast
        ? BorderSide(color: look.edge ?? fallback, width: own)
        : BorderSide.none);
