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
@immutable
class NeumorphicStyleOf {
  /// The [layers] read at [states].
  const NeumorphicStyleOf(this.layers, this.states);

  /// The styles, first wins.
  final List<NeumorphicStyle?> layers;

  /// The part's states.
  final Set<WidgetState> states;

  T? _first<T>(WidgetStateProperty<T?>? Function(NeumorphicStyle s) slot) =>
      NeumorphicStyle.first(layers, slot, states);

  /// The face.
  Color? get fill => _first((s) => s.fill);

  /// The words and icons.
  Color? get foreground => _first((s) => s.foreground);

  /// The rim's colour.
  Color? get edge => _first((s) => s.edge);

  /// The whole rim.
  BorderSide? get side => _first((s) => s.side);

  /// The outline.
  OutlinedBorder? get shape => _first((s) => s.shape);

  /// The room inside, resolved for [direction].
  EdgeInsets? padding(TextDirection direction) =>
      _first((s) => s.padding)?.resolve(direction);

  /// The least size of the face.
  Size? get minimumSize => _first((s) => s.minimumSize);

  /// The words' style.
  TextStyle? get textStyle => _first((s) => s.textStyle);

  /// An icon's size.
  double? get iconSize => _first((s) => s.iconSize);

  /// The same layers at other [states].
  NeumorphicStyleOf at(Set<WidgetState> states) =>
      NeumorphicStyleOf(layers, states);

  /// The shape for any states, as the press reads it for its ring and wash; [fallback] when no layer gives one.
  WidgetStateProperty<OutlinedBorder?> shapes(OutlinedBorder? fallback) =>
      WidgetStateProperty.resolveWith((states) => at(states).shape ?? fallback);

  /// The overlay for any states, as the press reads it.
  WidgetStateProperty<Color?>? get overlay =>
      layers.any((l) => l?.overlay != null)
      ? WidgetStateProperty.resolveWith(
          (states) => NeumorphicStyle.first(layers, (s) => s.overlay, states),
        )
      : null;
}

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
