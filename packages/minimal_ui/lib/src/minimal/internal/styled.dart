import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../component_themes.dart';
import '../shapes.dart';
import '../theme.dart';

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
/// theme) read for one set of states: ui_core's [RawStyleOf]. Every
/// getter is null where no layer says, and the part goes on to the knob and
/// its own default.
typedef MinimalStyleOf = RawStyleOf;

/// What Minimal's parts read from their layers beyond ui_core's getters.
extension MinimalStyleReading on RawStyleOf {
  /// The first layer's state wash in these states.
  Color? get wash => RawStyle.first(layers, (s) => s.overlay, states);

  /// The first layer's padding, for [context]'s direction.
  EdgeInsets? paddingIn(BuildContext context) =>
      padding(Directionality.of(context));

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
  RawStyle? get press {
    if (layers.every((l) => l == null)) return null;
    return RawStyle(
      overlay: WidgetStateProperty.resolveWith(
        (s) => RawStyle.first(layers, (l) => l.overlay, s),
      ),
      shape: WidgetStateProperty.resolveWith(
        (s) => RawStyle.first(layers, (l) => l.shape, s),
      ),
    );
  }
}

/// What Minimal's parts read of their corners.
extension MinimalCornerReading on RawStyleOf {
  /// The outline a part whose own step is [own] draws: a layer's `shape`
  /// as given (it wins); else a layer's `corners`, each held to Minimal's
  /// steps over the part's own and drawn in [t]'s scale, start and end as
  /// the part reads; else [t]'s own outline at [own].
  OutlinedBorder outline(MinimalThemeData t, RawCorner own) =>
      shape ?? minimalCornersOutline(t, corners, own);

  /// The corners a layer names, held to Minimal's steps over the part's
  /// own [own]; null when a layer's `shape` wins or none names corners
  /// (the part draws its own outline).
  RawCorners? heldCorners(MinimalThemeData t, RawCorner own) =>
      shape != null ? null : minimalHeldCorners(t, corners, own);
}

// A capsule role squares with a square scheme.
RawCorner _ownStep(MinimalThemeData t, RawCorner own) =>
    own == RawCorner.full && t.shapes.square ? RawCorner.none : own;

/// [corners] held to Minimal's steps over a part's own [own]; null when
/// [corners] names none.
RawCorners? minimalHeldCorners(
  MinimalThemeData t,
  RawCorners? corners,
  RawCorner own,
) {
  if (corners == null || corners.isEmpty) return null;
  return MinimalThemeData.shapeLimits.clampCorners(
    corners,
    base: RawCorners.all(_ownStep(t, own)),
    look: 'Minimal',
  );
}

/// The outline a part whose own step is [own] draws for [corners]: its own
/// ([MinimalShapes.at]) when [corners] names none, else each corner at its
/// held step in [t]'s scale.
OutlinedBorder minimalCornersOutline(
  MinimalThemeData t,
  RawCorners? corners,
  RawCorner own,
) {
  final held = minimalHeldCorners(t, corners, own);
  return held == null ? t.shapes.at(own) : t.shapeScheme.corners.borderOf(held);
}

/// Cell [index] of [count] laid edge to edge along [axis] inside a frame
/// whose corners are [held] (a part's own, [MinimalCornerReading.heldCorners]),
/// [inset] px within it: the first cell takes the frame's start (or top)
/// corners, the last its end (or bottom) corners, each shrunk by [inset] so
/// the outlines stay concentric; every corner that faces a neighbour is
/// square.
OutlinedBorder minimalHeldCell(
  MinimalThemeData t,
  RawCorners held, {
  required int index,
  required int count,
  double inset = 0,
  Axis axis = Axis.horizontal,
}) {
  final first = index == 0, last = index == count - 1;
  final cell = axis == Axis.horizontal
      ? RawCorners(
          topStart: first ? held.topStart : null,
          bottomStart: first ? held.bottomStart : null,
          topEnd: last ? held.topEnd : null,
          bottomEnd: last ? held.bottomEnd : null,
        )
      : RawCorners(
          topStart: first ? held.topStart : null,
          topEnd: first ? held.topEnd : null,
          bottomStart: last ? held.bottomStart : null,
          bottomEnd: last ? held.bottomEnd : null,
        );
  final border = t.shapeScheme.corners.borderOf(cell);
  return inset == 0 ? border : border.inset(EdgeInsets.all(inset));
}

/// Key [index] of [count] standing apart inside a frame whose corners are
/// [held] ([MinimalCornerReading.heldCorners]), [inset] px within it (a
/// segmented control's thumb, a menu bar's item): a key at either end takes
/// the frame's corners on that end, every other corner the part's own
/// [own], each shrunk by [inset] so the key stays concentric with the
/// frame.
OutlinedBorder minimalHeldKey(
  MinimalThemeData t,
  RawCorners held,
  RawCorner own, {
  required int index,
  required int count,
  double inset = 0,
}) {
  final first = index == 0, last = index == count - 1;
  final key = RawCorners(
    topStart: first ? held.topStart : own,
    bottomStart: first ? held.bottomStart : own,
    topEnd: last ? held.topEnd : own,
    bottomEnd: last ? held.bottomEnd : own,
  );
  final border = t.shapeScheme.corners.borderOf(key);
  return inset == 0 ? border : border.inset(EdgeInsets.all(inset));
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
    corners: each((s) => s.corners),
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
