/// A part's own corners in Studio: the radii a style's `shape` names, and
/// the corners a style gives a part made of several keys (a key row, a
/// toggle bank, a segmented button, a split key) on its outer frame only.
library;

import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../surface.dart';
import '../theme.dart';

/// The radii [shape] gives a face, or null for a border Studio doesn't draw:
/// a rounded rectangle's, a stadium's or a circle's (half the shorter side).
BorderRadiusGeometry? studioRadiiOf(ShapeBorder? shape) => switch (shape) {
  StadiumBorder() || CircleBorder() => _full,
  RawCornerBorder(full: true) => _full,
  RawCornerBorder(:final borderRadius) => borderRadius,
  RoundedRectangleBorder(:final borderRadius) => borderRadius,
  ContinuousRectangleBorder(:final borderRadius) => borderRadius,
  _ => null,
};

const _full = BorderRadius.all(Radius.circular(double.infinity));

/// The outer corners [frame] gives a part made of several keys whose own
/// corner is [radius], start and end as it reads in [direction], or null
/// when it gives none and the part keeps its own.
///
/// A `shape` wins as given; else `corners` name a step per corner, held to
/// [StudioThemeData.shapeLimits] and drawn in [theme]'s scale.
BorderRadiusDirectional? studioOuterCorners(
  StudioThemeData theme,
  RawStyleOf frame,
  double radius,
  TextDirection direction,
) {
  final radii = studioRadiiOf(frame.shape);
  if (radii != null) return _directional(radii, direction);
  final corners = frame.corners;
  if (corners == null) return null;
  final face = StudioFace(
    fill: const Color(0x00000000),
    fillLow: const Color(0x00000000),
    depth: StudioDepth.level,
    radius: radius,
    corners: corners,
  ).resolveCorners(theme);
  return _directional(face.borderRadius!, direction);
}

/// A key's corners in a part whose outer corners are [outer]: its start
/// corners [outer]'s, drawn [inset] further in, when it [starts] the part,
/// its end corners when it [ends] it, the rest [own], so the joins between
/// keys stay as Studio draws them. A square corner stays square.
BorderRadiusDirectional studioKeyCorners(
  BorderRadiusDirectional outer,
  double own, {
  required double inset,
  required bool starts,
  required bool ends,
}) {
  Radius less(Radius r) => Radius.elliptical(
    (r.x - inset).clamp(0, double.infinity),
    (r.y - inset).clamp(0, double.infinity),
  );
  final mine = Radius.circular(own);
  return BorderRadiusDirectional.only(
    topStart: starts ? less(outer.topStart) : mine,
    bottomStart: starts ? less(outer.bottomStart) : mine,
    topEnd: ends ? less(outer.topEnd) : mine,
    bottomEnd: ends ? less(outer.bottomEnd) : mine,
  );
}

/// [radii] as a face draws them: a corner past half the shorter side stands
/// at the half. A part's shadow, cast by the corners an app gave it.
class StudioCornerShape extends ShapeBorder {
  /// A shape with [radii].
  const StudioCornerShape(this.radii);

  /// The corners.
  final BorderRadiusGeometry radii;

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      Path()..addRRect(studioCornerRect(rect, radii, textDirection));

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) =>
      Path()..addRRect(studioCornerRect(rect, radii, textDirection));

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {}

  @override
  ShapeBorder scale(double t) => StudioCornerShape(radii * t);

  @override
  bool operator ==(Object other) =>
      other is StudioCornerShape && other.radii == radii;

  @override
  int get hashCode => radii.hashCode;
}

/// [rect] with [radii] laid in [direction], each corner at most half the
/// shorter side.
RRect studioCornerRect(
  Rect rect,
  BorderRadiusGeometry radii,
  TextDirection? direction,
) {
  final r = radii.resolve(direction ?? TextDirection.ltr);
  final most = rect.shortestSide / 2;
  Radius held(Radius c) =>
      Radius.elliptical(c.x.clamp(0, most), c.y.clamp(0, most));
  return RRect.fromRectAndCorners(
    rect,
    topLeft: held(r.topLeft),
    topRight: held(r.topRight),
    bottomLeft: held(r.bottomLeft),
    bottomRight: held(r.bottomRight),
  );
}

/// A part's shadow (and [color]) under its corners: [own], or [radii] when
/// an app gave the part its own.
Decoration studioShadowed({
  required BorderRadiusGeometry? radii,
  required BorderRadiusGeometry own,
  Color? color,
  required List<BoxShadow> shadows,
}) => radii == null
    ? BoxDecoration(color: color, borderRadius: own, boxShadow: shadows)
    : ShapeDecoration(
        color: color,
        shape: StudioCornerShape(radii),
        shadows: shadows,
      );

/// Clips to [radii] as a face is drawn with them: a corner past half the
/// shorter side stands at the half. What a part holds (a dialog's body, a
/// list on its glass) stays inside the corners an app gave it.
class StudioCornerClipper extends CustomClipper<RRect> {
  /// A clip to [radii], laid in [direction].
  StudioCornerClipper(this.radii, this.direction);

  /// The corners.
  final BorderRadiusGeometry radii;

  /// Which way the part reads.
  final TextDirection direction;

  @override
  RRect getClip(Size size) =>
      studioCornerRect(Offset.zero & size, radii, direction);

  @override
  bool shouldReclip(StudioCornerClipper oldClipper) =>
      oldClipper.radii != radii || oldClipper.direction != direction;
}

BorderRadiusDirectional _directional(
  BorderRadiusGeometry radii,
  TextDirection direction,
) {
  if (radii is BorderRadiusDirectional) return radii;
  final r = radii.resolve(direction);
  final ltr = direction == TextDirection.ltr;
  return BorderRadiusDirectional.only(
    topStart: ltr ? r.topLeft : r.topRight,
    topEnd: ltr ? r.topRight : r.topLeft,
    bottomStart: ltr ? r.bottomLeft : r.bottomRight,
    bottomEnd: ltr ? r.bottomRight : r.bottomLeft,
  );
}
