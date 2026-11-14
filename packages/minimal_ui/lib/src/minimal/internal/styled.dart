import 'package:flutter/widgets.dart';

import '../component_themes.dart';
import '../shapes.dart';

/// The states a part resolves its style for.
Set<WidgetState> minimalStates({
  bool enabled = true,
  bool pressed = false,
  bool hovered = false,
  bool focused = false,
  bool selected = false,
  bool error = false,
}) => <WidgetState>{
  if (!enabled) WidgetState.disabled,
  if (pressed) WidgetState.pressed,
  if (hovered) WidgetState.hovered,
  if (focused) WidgetState.focused,
  if (selected) WidgetState.selected,
  if (error) WidgetState.error,
};

/// One part's style layers (its own `style:` first, then its component
/// theme) read for one set of states. Every getter is null where no layer
/// says, and the part goes on to the knob and its own default.
@immutable
class MinimalStyleOf {
  /// The value of each property across [layers] in [states].
  const MinimalStyleOf(this.layers, this.states);

  /// The layers, the strongest first.
  final List<MinimalStyle?> layers;

  /// The part's states.
  final Set<WidgetState> states;

  /// The first layer's fill in these states.
  Color? get fill => MinimalStyle.first(layers, (s) => s.fill, states);

  /// The first layer's ink.
  Color? get foreground =>
      MinimalStyle.first(layers, (s) => s.foreground, states);

  /// The first layer's edge colour.
  Color? get edge => MinimalStyle.first(layers, (s) => s.edge, states);

  /// The first layer's state wash.
  Color? get overlay => MinimalStyle.first(layers, (s) => s.overlay, states);

  /// The first layer's whole border side.
  BorderSide? get side => MinimalStyle.first(layers, (s) => s.side, states);

  /// The first layer's outline.
  OutlinedBorder? get shape =>
      MinimalStyle.first(layers, (s) => s.shape, states);

  /// The first layer's padding.
  EdgeInsetsGeometry? get padding =>
      MinimalStyle.first(layers, (s) => s.padding, states);

  /// The first layer's least size.
  Size? get minimumSize =>
      MinimalStyle.first(layers, (s) => s.minimumSize, states);

  /// The first layer's text style.
  TextStyle? get textStyle =>
      MinimalStyle.first(layers, (s) => s.textStyle, states);

  /// The first layer's glyph size.
  double? get iconSize => MinimalStyle.first(layers, (s) => s.iconSize, states);

  /// The rim: a [side] wins; else an [edge] (or the part's [own] colour) at
  /// [width]; none when neither says a colour.
  BorderSide rim(Color? own, double width) {
    final whole = side;
    if (whole != null) return whole;
    final colour = edge ?? own;
    return colour == null
        ? BorderSide.none
        : BorderSide(color: colour, width: width);
  }

  /// The words' style: the look's [own], with a layer's text style merged
  /// over it and [colour] last.
  TextStyle text(TextStyle own, Color colour) {
    final layered = textStyle;
    return (layered == null ? own : own.merge(layered)).copyWith(color: colour);
  }

  /// The wash and the outline of every layer as one style, each state
  /// falling through the layers as the part's own slots do: what its
  /// `MinimalPressable` reads. Null when no layer is set.
  MinimalStyle? get press {
    if (layers.every((l) => l == null)) return null;
    return MinimalStyle(
      overlay: WidgetStateProperty.resolveWith(
        (s) => MinimalStyle.first(layers, (l) => l.overlay, s),
      ),
      shape: WidgetStateProperty.resolveWith(
        (s) => MinimalStyle.first(layers, (l) => l.shape, s),
      ),
    );
  }
}

/// [layers] as one style, every slot falling through them state by state
/// as a part's own reading does: for a part that hands its style on to
/// another (a list section to its card). Null when no layer is set.
MinimalStyle? minimalLayered(List<MinimalStyle?> layers) {
  final set = [for (final l in layers) ?l];
  if (set.isEmpty) return null;
  if (set.length == 1) return set.single;
  WidgetStateProperty<T?> each<T>(
    WidgetStateProperty<T?>? Function(MinimalStyle s) slot,
  ) => WidgetStateProperty.resolveWith((s) => MinimalStyle.first(set, slot, s));
  return MinimalStyle(
    fill: each((s) => s.fill),
    foreground: each((s) => s.foreground),
    edge: each((s) => s.edge),
    overlay: each((s) => s.overlay),
    side: each((s) => s.side),
    shape: each((s) => s.shape),
    padding: each((s) => s.padding),
    minimumSize: each((s) => s.minimumSize),
    textStyle: each((s) => s.textStyle),
    iconSize: each((s) => s.iconSize),
  );
}

/// What a framed part paints on [shape]: its [fill], its rim ([side]) and
/// [shadows]. A rounded rectangle paints as a [BoxDecoration], the look's
/// own path pixel for pixel; any other outline as a [ShapeDecoration].
/// A [side] that is [BorderSide.none] keeps the shape's own.
Decoration minimalFrame(
  OutlinedBorder shape, {
  Color? fill,
  BorderSide side = BorderSide.none,
  List<BoxShadow>? shadows,
}) {
  final rim = side == BorderSide.none ? shape.side : side;
  if (shape is RoundedRectangleBorder) {
    return BoxDecoration(
      color: fill,
      borderRadius: shape.borderRadius,
      border: rim == BorderSide.none ? null : Border.fromBorderSide(rim),
      boxShadow: shadows,
    );
  }
  return ShapeDecoration(
    color: fill,
    shape: shape.copyWith(side: rim),
    shadows: shadows,
  );
}

/// [shape] grown or shrunk by [factor] (a 20 px check on a 16 px scale):
/// its corners and rim; as given at 1, or when it does not scale to an
/// outline.
OutlinedBorder minimalScaled(OutlinedBorder shape, double factor) {
  if (factor == 1) return shape;
  final scaled = shape.scale(factor);
  return scaled is OutlinedBorder ? scaled : shape;
}

/// Cell [index] of [count] laid edge to edge along [axis] inside [frame],
/// [inset] px within it: the first cell keeps the frame's start (or top)
/// corners, the last its end (or bottom) corners, each shrunk by [inset] so
/// the two outlines stay concentric, and every corner that faces a
/// neighbour is square. The frame's kind carries over (a bevel's cut, a
/// squircle's curve); a capsule's ends stay round.
OutlinedBorder minimalCell(
  OutlinedBorder frame, {
  required int index,
  required int count,
  double inset = 0,
  Axis axis = Axis.horizontal,
}) {
  final whole = MinimalShapes.radiusOf(frame);
  final r = Radius.circular(
    whole >= MinimalShapes.fullRadius
        ? MinimalShapes.fullRadius
        : (whole - inset).clamp(0.0, double.infinity),
  );
  final first = index == 0;
  final last = index == count - 1;
  final BorderRadiusGeometry radius = axis == Axis.horizontal
      ? BorderRadiusDirectional.horizontal(
          start: first ? r : Radius.zero,
          end: last ? r : Radius.zero,
        )
      : BorderRadius.vertical(
          top: first ? r : Radius.zero,
          bottom: last ? r : Radius.zero,
        );
  return switch (frame) {
    final BeveledRectangleBorder s => s.copyWith(borderRadius: radius),
    final ContinuousRectangleBorder s => s.copyWith(borderRadius: radius),
    final RoundedSuperellipseBorder s => s.copyWith(borderRadius: radius),
    _ => RoundedRectangleBorder(borderRadius: radius),
  };
}

/// [child] clipped to [shape]: a rounded rectangle by its radii, any other
/// outline by its path.
Widget minimalClip(OutlinedBorder shape, {required Widget child}) =>
    switch (shape) {
      RoundedRectangleBorder(:final borderRadius) => ClipRRect(
        borderRadius: borderRadius,
        child: child,
      ),
      _ => Builder(
        builder: (context) => ClipPath(
          clipper: ShapeBorderClipper(
            shape: shape,
            textDirection: Directionality.maybeOf(context),
          ),
          child: child,
        ),
      ),
    };
