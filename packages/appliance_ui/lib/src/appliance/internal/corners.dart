/// A part's own corners in Appliance: the radii a style's `shape` names,
/// and the corners a style gives a part made of several keys (a toolbar
/// strip, a toggle group, a selector, a split key) on its outer frame only.
library;

import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../material.dart';
import '../theme.dart';

/// The radii [shape] gives a face, or null for a border Appliance doesn't draw:
/// a rounded rectangle's, a stadium's or a circle's (half the shorter side).
BorderRadiusGeometry? applianceRadiiOf(ShapeBorder? shape) => switch (shape) {
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
/// [ApplianceThemeData.shapeLimits] and drawn in [theme]'s scale.
BorderRadiusDirectional? applianceOuterCorners(
  ApplianceThemeData theme,
  RawStyleOf frame,
  double radius,
  TextDirection direction,
) {
  final radii = applianceRadiiOf(frame.shape);
  if (radii != null) return _directional(radii, direction);
  final corners = frame.corners;
  if (corners == null) return null;
  final face = ApplianceFace(
    top: const Color(0x00000000),
    bottom: const Color(0x00000000),
    radius: BorderRadius.circular(radius),
    corners: corners,
  ).resolveCorners(theme, direction);
  return _directional(face.borderRadius!, direction);
}

/// A key's corners in a part whose outer corners are [outer]: its start
/// corners [outer]'s, drawn [inset] further in, when it [starts] the part,
/// its end corners when it [ends] it, the rest [own], so the joins between
/// keys stay as Appliance draws them. A square corner stays square.
BorderRadiusDirectional applianceKeyCorners(
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

/// A block sliding along a strip of [count] cells whose outer corners are
/// [outer], standing at [at] (0 the first cell, `count - 1` the last): its
/// corners [own], easing to [outer]'s drawn [inset] further in as it comes
/// to either end, so it stands concentric with the strip there and never
/// snaps. Each corner is held to [most], half the block's shorter side.
BorderRadiusDirectional applianceSlidingCorners(
  BorderRadiusDirectional outer,
  double own, {
  required double inset,
  required double at,
  required int count,
  required double most,
}) {
  final toStart = (1 - at).clamp(0.0, 1.0);
  final toEnd = (at - (count - 2)).clamp(0.0, 1.0);
  double held(double r) => r.clamp(0.0, math.max(0.0, most));
  final mine = Radius.circular(held(own));
  Radius toward(Radius r, double t) => Radius.lerp(
    mine,
    Radius.elliptical(held(r.x - inset), held(r.y - inset)),
    t,
  )!;
  return BorderRadiusDirectional.only(
    topStart: toward(outer.topStart, toStart),
    bottomStart: toward(outer.bottomStart, toStart),
    topEnd: toward(outer.topEnd, toEnd),
    bottomEnd: toward(outer.bottomEnd, toEnd),
  );
}

/// The clip of what a well holds [inset] in from its edge (a picture, a
/// carousel's slides, a colour area) when an app gave the well [outer]:
/// concentric with them, [inner] standing for the well's own; null when it
/// gave none, and the part clips at its own [inner].
CustomClipper<RRect>? applianceWindowClip(
  BorderRadiusDirectional? outer,
  double inner, {
  required double inset,
  required TextDirection direction,
}) => outer == null
    ? null
    : ApplianceCornerClipper(
        applianceKeyCorners(
          outer,
          inner,
          inset: inset,
          starts: true,
          ends: true,
        ),
        direction,
      );

/// [face] with [look]'s corners: the steps its `corners` name, or the
/// radii its `shape` gives. A part whose style colours the face its own
/// way takes only the corners from it.
ApplianceFace applianceCornersOn(ApplianceFace face, RawStyleOf look) =>
    face.copyWith(
      corners: look.corners,
      borderRadius: applianceRadiiOf(look.shape),
    );

/// [radii] as a face draws them: a corner past half the shorter side stands
/// at the half. A part's shadow, cast by the corners an app gave it, and its
/// [side] (a tag's rule) drawn round them.
class ApplianceCornerShape extends ShapeBorder {
  /// A shape with [radii].
  const ApplianceCornerShape(this.radii, {this.side = BorderSide.none});

  /// The corners.
  final BorderRadiusGeometry radii;

  /// The line drawn round it, inside its edge; none by default.
  final BorderSide side;

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(side.strokeInset);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      Path()..addRRect(applianceCornerRect(rect, radii, textDirection));

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) =>
      Path()..addRRect(applianceCornerRect(rect, radii, textDirection));

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (side.style == BorderStyle.none || side.width == 0) return;
    canvas.drawRRect(
      applianceCornerRect(rect, radii, textDirection).deflate(side.width / 2),
      side.toPaint(),
    );
  }

  @override
  ShapeBorder scale(double t) =>
      ApplianceCornerShape(radii * t, side: side.scale(t));

  @override
  bool operator ==(Object other) =>
      other is ApplianceCornerShape &&
      other.radii == radii &&
      other.side == side;

  @override
  int get hashCode => Object.hash(radii, side);
}

/// [rect] with [radii] laid in [direction], each corner at most half the
/// shorter side.
RRect applianceCornerRect(
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
Decoration applianceShadowed({
  required BorderRadiusGeometry? radii,
  required BorderRadiusGeometry own,
  Color? color,
  required List<BoxShadow> shadows,
}) => radii == null
    ? BoxDecoration(color: color, borderRadius: own, boxShadow: shadows)
    : ShapeDecoration(
        color: color,
        shape: ApplianceCornerShape(radii),
        shadows: shadows,
      );

/// Clips to [radii] as a face is drawn with them: a corner past half the
/// shorter side stands at the half. What a part holds (a dialog's body, a
/// list on its glass) stays inside the corners an app gave it.
class ApplianceCornerClipper extends CustomClipper<RRect> {
  /// A clip to [radii], laid in [direction].
  ApplianceCornerClipper(this.radii, this.direction);

  /// The corners.
  final BorderRadiusGeometry radii;

  /// Which way the part reads.
  final TextDirection direction;

  @override
  RRect getClip(Size size) =>
      applianceCornerRect(Offset.zero & size, radii, direction);

  @override
  bool shouldReclip(ApplianceCornerClipper oldClipper) =>
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
