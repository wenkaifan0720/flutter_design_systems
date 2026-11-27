/// A part's corner on Gloss's steps.
library;

import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../theme.dart';

/// The corner of [step] in [theme]; with [at], a part's corner at Gloss's own
/// [step], kept in proportion as an app's theme makes the step rounder or
/// squarer: a table's tick (6 beside a socket's 7), a row's plate in its
/// well (10 in a well of 16).
double glossCorner(GlossThemeData theme, RawCorner step, [double? at]) {
  final r = theme.shapeScheme.corners.radius(step);
  if (at == null) return r;
  return r * at / GlossThemeData.defaultShapeScheme.corners.radius(step);
}

/// A corner of a face's [GlossFace.corners] that reaches half the face's
/// shorter side, as the face is laid out: a [RawCorner.full] step.
const double glossFullCorner = 1e6;

/// The corners [layered] gives a part whose own corners are [own], in a
/// face's own frame (start on the left: a face's painter turns right to
/// left), or null when it gives none and the part keeps its own.
///
/// A style's `shape` wins as given, outside Gloss's limits, as Material's
/// ButtonStyle.shape does: a rounded rectangle, a stadium or a circle (Gloss
/// draws round fillets; another kind of border is not drawn). Else its
/// `corners` name a step per corner over [own], held to
/// [GlossThemeData.shapeLimits] and drawn in [theme]'s scale.
BorderRadius? glossCornersOf(
  GlossThemeData theme,
  RawStyleOf layered,
  RawCorner own,
  TextDirection direction,
) {
  final shape = layered.shape;
  if (shape != null) return _radiiOf(shape, direction);
  final override = layered.corners;
  if (override == null) return null;
  final held = GlossThemeData.shapeLimits.clampCorners(
    override,
    base: RawCorners.all(own),
    look: 'Gloss',
  );
  final scale = theme.shapeScheme.corners;
  Radius at(RawCorner? step) => switch (step ?? RawCorner.none) {
    RawCorner.none => Radius.zero,
    RawCorner.full => const Radius.circular(glossFullCorner),
    final s => Radius.circular(scale.radius(s)),
  };
  return BorderRadius.only(
    topLeft: at(held.topStart),
    topRight: at(held.topEnd),
    bottomLeft: at(held.bottomStart),
    bottomRight: at(held.bottomEnd),
  );
}

/// [radii] drawn [by] further in, each corner concentric with its own (a
/// square one stays square): a plate inside a part whose corners an app
/// gave, or null when it gave none.
BorderRadius? glossCornersInset(BorderRadius? radii, double by) {
  if (radii == null) return null;
  Radius less(Radius r) => r == Radius.zero
      ? r
      : Radius.elliptical(
          r.x >= glossFullCorner ? r.x : (r.x - by).clamp(0, double.infinity),
          r.y >= glossFullCorner ? r.y : (r.y - by).clamp(0, double.infinity),
        );
  return BorderRadius.only(
    topLeft: less(radii.topLeft),
    topRight: less(radii.topRight),
    bottomLeft: less(radii.bottomLeft),
    bottomRight: less(radii.bottomRight),
  );
}

/// A key's corners in a row of keys whose outer corners are [outer] (a
/// face's own frame): its start corners [outer]'s when it [starts] the row,
/// its end corners when it [ends] it, the rest [own], so the joins between
/// keys stay as Gloss draws them.
BorderRadius glossEndCorners(
  BorderRadius outer,
  Radius own, {
  required bool starts,
  required bool ends,
}) => BorderRadius.only(
  topLeft: starts ? outer.topLeft : own,
  bottomLeft: starts ? outer.bottomLeft : own,
  topRight: ends ? outer.topRight : own,
  bottomRight: ends ? outer.bottomRight : own,
);

// [shape]'s corners in a face's own frame, start on the left, or null for a
// border Gloss doesn't draw. A physical radius (left, right) keeps its side:
// right to left it is turned back, since the painter turns the face.
BorderRadius? _radiiOf(ShapeBorder shape, TextDirection direction) {
  const full = BorderRadius.all(Radius.circular(glossFullCorner));
  final BorderRadiusGeometry? radii = switch (shape) {
    StadiumBorder() || CircleBorder() => full,
    RawCornerBorder(full: true) => full,
    RawCornerBorder(:final borderRadius) => borderRadius,
    RoundedRectangleBorder(:final borderRadius) => borderRadius,
    _ => null,
  };
  if (radii == null) return null;
  if (radii is BorderRadius) {
    if (direction == TextDirection.ltr) return radii;
    return BorderRadius.only(
      topLeft: radii.topRight,
      topRight: radii.topLeft,
      bottomLeft: radii.bottomRight,
      bottomRight: radii.bottomLeft,
    );
  }
  return radii.resolve(TextDirection.ltr);
}

/// A fill's corners in a groove whose inside corners are [inner] (a face's
/// own frame, start on the left), the fill [height] tall and [gap] short of
/// the groove's end: its start corners the groove's; its tip round by its
/// height while it stands short of the end, easing into the groove's end
/// corners over the last [height] of the run, so a fill takes an app's end
/// corners only where it meets them. Null (the part's own corners) stays
/// null.
BorderRadius? glossFillCorners(BorderRadius? inner, double height, double gap) {
  if (inner == null) return null;
  final half = height / 2;
  final own = Radius.circular(half);
  final reach = (1 - gap / math.max(1.0, height)).clamp(0.0, 1.0);
  Radius tip(Radius r) =>
      Radius.lerp(own, Radius.circular(math.min(r.x, half)), reach)!;
  return inner.copyWith(
    topRight: tip(inner.topRight),
    bottomRight: tip(inner.bottomRight),
  );
}

/// [rect] with [corners], none past half the shorter side (a full corner
/// reaches it), as a face is drawn with them.
RRect glossCornersOutline(Rect rect, BorderRadius corners) {
  final most = rect.shortestSide / 2;
  Radius held(Radius r) => Radius.elliptical(
    r.x.clamp(0, most).toDouble(),
    r.y.clamp(0, most).toDouble(),
  );
  return RRect.fromRectAndCorners(
    rect,
    topLeft: held(corners.topLeft),
    topRight: held(corners.topRight),
    bottomLeft: held(corners.bottomLeft),
    bottomRight: held(corners.bottomRight),
  );
}

/// Clips to [radii] (a face's own frame, start on the left) as a face is
/// drawn with them: right to left turned, a full corner half the shorter
/// side. What a part holds (a card's picture) stays inside its corners.
class GlossCornerClipper extends CustomClipper<RRect> {
  /// A clip to [radii], laid in [direction].
  GlossCornerClipper(this.radii, this.direction);

  /// The corners, start on the left.
  final BorderRadius radii;

  /// Which way the part reads: right to left, start is on the right.
  final TextDirection direction;

  @override
  RRect getClip(Size size) {
    final r = direction == TextDirection.ltr
        ? radii
        : BorderRadius.only(
            topLeft: radii.topRight,
            topRight: radii.topLeft,
            bottomLeft: radii.bottomRight,
            bottomRight: radii.bottomLeft,
          );
    return glossCornersOutline(Offset.zero & size, r);
  }

  @override
  bool shouldReclip(GlossCornerClipper oldClipper) =>
      oldClipper.radii != radii || oldClipper.direction != direction;
}
