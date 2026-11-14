// How a styled part reads its style and draws its shape: the layers in order, and a shape that animates to each new
// one, as a Material 3 button's does when a state changes it.
import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'component_themes.dart';
import 'theme.dart';

/// The concentric shape inside [shape], with each corner reduced by [inset].
/// Circles and capsules remain circles and capsules in their smaller bounds.
///
/// ```dart
/// comicInsetShape(theme.shapes.medium, 3)
/// ```
OutlinedBorder comicInsetShape(OutlinedBorder shape, double inset) {
  if (shape is RoundedRectangleBorder) {
    Radius corner(Radius r) =>
        Radius.elliptical(math.max(0, r.x - inset), math.max(0, r.y - inset));
    final radius = shape.borderRadius.resolve(TextDirection.ltr);
    return shape.copyWith(
      borderRadius: shape.borderRadius is BorderRadiusDirectional
          ? BorderRadiusDirectional.only(
              topStart: corner(radius.topLeft),
              topEnd: corner(radius.topRight),
              bottomStart: corner(radius.bottomLeft),
              bottomEnd: corner(radius.bottomRight),
            )
          : BorderRadius.only(
              topLeft: corner(radius.topLeft),
              topRight: corner(radius.topRight),
              bottomLeft: corner(radius.bottomLeft),
              bottomRight: corner(radius.bottomRight),
            ),
    );
  }
  return shape;
}

/// [shape] with no corner above [most]: a rounded rectangle's corners are
/// reduced by the same inset, so the result stays concentric with [shape];
/// other shapes are returned as they are.
///
/// ```dart
/// comicCappedShape(theme.shapes.small, 7)
/// ```
OutlinedBorder comicCappedShape(OutlinedBorder shape, double most) {
  if (shape is! RoundedRectangleBorder) return shape;
  final r = shape.borderRadius.resolve(TextDirection.ltr);
  final largest = [
    r.topLeft.x,
    r.topRight.x,
    r.bottomLeft.x,
    r.bottomRight.x,
  ].reduce(math.max);
  return largest <= most ? shape : comicInsetShape(shape, largest - most);
}

/// The concentric shape [gap] outside [shape], for a focus ring: each rounded corner grows by [gap], a square corner
/// stays square, and circles and capsules stay circles and capsules in their larger bounds.
///
/// ```dart
/// comicOutsetShape(theme.shapes.small, theme.focus.gap)
/// ```
OutlinedBorder comicOutsetShape(OutlinedBorder shape, double gap) {
  if (shape is RoundedRectangleBorder) {
    Radius corner(Radius r) =>
        Radius.elliptical(r.x <= 0 ? 0 : r.x + gap, r.y <= 0 ? 0 : r.y + gap);
    final radius = shape.borderRadius.resolve(TextDirection.ltr);
    return shape.copyWith(
      borderRadius: shape.borderRadius is BorderRadiusDirectional
          ? BorderRadiusDirectional.only(
              topStart: corner(radius.topLeft),
              topEnd: corner(radius.topRight),
              bottomStart: corner(radius.bottomLeft),
              bottomEnd: corner(radius.bottomRight),
            )
          : BorderRadius.only(
              topLeft: corner(radius.topLeft),
              topRight: corner(radius.topRight),
              bottomLeft: corner(radius.bottomLeft),
              bottomRight: corner(radius.bottomRight),
            ),
    );
  }
  return shape;
}

/// Builds [builder] with [shape], easing to each new shape over the motion's state duration (a cut under Reduce
/// Motion). Flutter interpolates the border and its corner sizes. A null shape builds at once with
/// null: the part draws its own.
///
/// ```dart
/// AnimatedComicShape(
///   shape: pressed ? const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8))) : const RoundedRectangleBorder(),
///   builder: (context, shape) => DecoratedBox(
///     decoration: ShapeDecoration(color: fill, shape: shape!),
///   ),
/// )
/// ```
class AnimatedComicShape extends StatelessWidget {
  /// Eases to [shape] whenever it changes.
  const AnimatedComicShape({
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
    final shape = this.shape;
    if (shape == null) return builder(context, null);
    final motion = ComicMotion.of(context);
    return TweenAnimationBuilder<ShapeBorder?>(
      tween: _ShapeTween(end: shape),
      duration: motion.state,
      curve: motion.standard,
      builder: (context, now, _) =>
          builder(context, now is OutlinedBorder ? now : shape),
    );
  }
}

// Material's ShapeBorderTween, without Material.
class _ShapeTween extends Tween<ShapeBorder?> {
  _ShapeTween({super.end});

  @override
  ShapeBorder? lerp(double t) => ShapeBorder.lerp(begin, end, t);
}

/// A styled part's layers for its states: its own `style:`, then its component theme. Each getter is the first layer's
/// value for the states, or null, so the part goes on to the theme-wide knobs and its own default.
///
/// ```dart
/// final look = ComicStyleOf([style, ComicTheme.of(context).chipTheme], states);
/// final fill = look.fill ?? colors.card;
/// ```
@immutable
class ComicStyleOf {
  /// The [layers] read at [states].
  const ComicStyleOf(this.layers, this.states);

  /// The styles, first wins.
  final List<ComicStyle?> layers;

  /// The part's states.
  final Set<WidgetState> states;

  T? _first<T>(WidgetStateProperty<T?>? Function(ComicStyle s) slot) =>
      ComicStyle.first(layers, slot, states);

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

  /// Freezes resolved values so a grouped control can pass its states to an inner mark.
  ///
  /// ```dart
  /// ComicCheckbox(label: 'Keep issue', value: true, style: look.freeze())
  /// ```
  ComicStyle freeze() {
    WidgetStateProperty<T?>? fixed<T>(T? value) =>
        value == null ? null : WidgetStatePropertyAll(value);
    return ComicStyle(
      fill: fixed(fill),
      foreground: fixed(foreground),
      edge: fixed(edge),
      overlay: fixed(ComicStyle.first(layers, (s) => s.overlay, states)),
      side: fixed(side),
      shape: fixed(shape),
      padding: fixed(_first((s) => s.padding)),
      minimumSize: fixed(minimumSize),
      textStyle: fixed(textStyle),
      iconSize: fixed(iconSize),
    );
  }

  /// The same layers at other [states].
  ComicStyleOf at(Set<WidgetState> states) => ComicStyleOf(layers, states);

  /// The shape for any states, as the press reads it for its ring and wash; [fallback] when no layer gives one.
  WidgetStateProperty<OutlinedBorder?> shapes(OutlinedBorder? fallback) =>
      WidgetStateProperty.resolveWith((states) => at(states).shape ?? fallback);

  /// The overlay for any states, as the press reads it.
  WidgetStateProperty<Color?>? get overlay =>
      layers.any((l) => l?.overlay != null)
      ? WidgetStateProperty.resolveWith(
          (states) => ComicStyle.first(layers, (s) => s.overlay, states),
        )
      : null;
}

/// The rim a styled part draws: [side] when set, else [edge] (or [fallback]) at the theme's regular stroke.
///
/// ```dart
/// final look = ComicStyleOf([style, theme.cardTheme], const {});
/// final rim = comicRim(theme, look, theme.colors.outline);
/// ```
BorderSide comicRim(
  ComicThemeData theme,
  ComicStyleOf look,
  Color fallback, [
  double own = 2.5,
]) =>
    look.side ??
    BorderSide(color: look.edge ?? fallback, width: theme.rim(own));

/// Extra inset that keeps a rectangular content box clear of a rounded corner.
/// Border dimensions reserve its stroke; this reserves the curved corner area.
/// For a circle or capsule, pass the smaller side of its content bounds.
double comicCornerInset(
  OutlinedBorder? shape,
  TextDirection direction, {
  double? shortestSide,
}) {
  double radius = 0;
  if (shape is RoundedRectangleBorder) {
    final r = shape.borderRadius.resolve(direction);
    radius = [
      r.topLeft.x,
      r.topLeft.y,
      r.topRight.x,
      r.topRight.y,
      r.bottomLeft.x,
      r.bottomLeft.y,
      r.bottomRight.x,
      r.bottomRight.y,
    ].reduce(math.max);
    if (shortestSide != null) radius = math.min(radius, shortestSide / 2);
  } else if (shape is CircleBorder || shape is StadiumBorder) {
    radius = (shortestSide ?? 0) / 2;
  }
  return radius * (1 - math.sqrt(.5));
}
