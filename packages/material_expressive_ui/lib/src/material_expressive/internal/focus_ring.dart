/// The focus ring's outline, shared by every part that draws one: an
/// `ExpressivePressable` under keyboard focus, and the slider's handle,
/// which is no pressable.
library;

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../shape.dart';
import '../styling.dart';

/// Strokes the focus ring, [thickness] wide in [color], round [shape] laid
/// on [rect]: [offset] out from its edge (the stroke's centre that plus
/// half the stroke), concentric with a rounded rectangle
/// (each corner's radius grown by the same, a square corner kept square),
/// the shape's own outline grown outward otherwise.
///
/// [inward] (rows stacked flush, as Material's web list items do) draws it
/// inside [rect] instead, its outer edge on the part's edge and its corners
/// the part's less half the stroke: a ring a neighbour painted after it
/// can never cover. An inward ring lies on the face, so where the face is
/// filled [gap] puts an opaque band of [offset] in that colour (the
/// surface) between the ring and the rest of the face, concentric, as the
/// outward ring's offset leaves one: a ring the fill matches (a selected
/// segment in `primary` reads as `secondary` does) still shows.
void expressivePaintFocusRing(
  Canvas canvas,
  Rect rect,
  OutlinedBorder shape, {
  required Color color,
  required double thickness,
  required double offset,
  TextDirection? textDirection,
  bool inward = false,
  Color? gap,
}) {
  if (inward && gap != null) {
    _strokeAround(
      canvas,
      rect,
      shape,
      out: -thickness - offset / 2,
      width: offset,
      color: gap,
      textDirection: textDirection,
    );
  }
  _strokeAround(
    canvas,
    rect,
    shape,
    out: inward ? -thickness / 2 : offset + thickness / 2,
    width: thickness,
    color: color,
    textDirection: textDirection,
  );
}

/// Strokes [width] in [color] concentric with [shape] on [rect], its
/// centre [out] from the edge (negative: inside).
void _strokeAround(
  Canvas canvas,
  Rect rect,
  OutlinedBorder shape, {
  required double out,
  required double width,
  required Color color,
  TextDirection? textDirection,
}) {
  final paint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..color = color
    ..isAntiAlias = true;
  while (shape is ExpressiveContentBorder) {
    shape = shape.outline;
  }
  final corners = switch (shape) {
    ExpressiveCornerBorder() =>
      shape.radiiOn(rect, textDirection).toRRect(rect),
    RoundedRectangleBorder(:final borderRadius) =>
      borderRadius.resolve(textDirection).toRRect(rect).scaleRadii(),
    _ => null,
  };
  if (corners != null) {
    Radius grow(Radius c) => c == Radius.zero
        ? Radius.zero
        : Radius.elliptical(math.max(0, c.x + out), math.max(0, c.y + out));
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        rect.inflate(out),
        topLeft: grow(corners.tlRadius),
        topRight: grow(corners.trRadius),
        bottomRight: grow(corners.brRadius),
        bottomLeft: grow(corners.blRadius),
      ),
      paint,
    );
    return;
  }
  canvas.drawPath(
    shape.getOuterPath(rect.inflate(out), textDirection: textDirection),
    paint,
  );
}
