// The arrow a tooltip's and a popover's bubble wears, painted on its edge.
import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../components/tooltip/arrow_placement.dart';
import '../theme.dart';

/// Paints a bubble's arrow: a [height] triangle in [fill] on the edge
/// [placement] says (inside the [height] of room left at the top and the
/// foot of [size]), its centre at the placement's offset kept clear of the
/// corners. Plumbing of the tooltip and the popover.
void fluent2PaintArrow(
  Canvas canvas,
  Size size, {
  required Fluent2ArrowPlacement placement,
  required Color fill,
  required double height,
  double corner = Fluent2Radius.medium,
}) {
  final half = height;
  final x = placement.offset
      .clamp(
        corner * 2 + half,
        math.max(corner * 2 + half, size.width - corner * 2 - half),
      )
      .toDouble();
  final path = Path();
  if (placement.isAbove) {
    final y = size.height - height;
    path
      ..moveTo(x - half, y - 1)
      ..lineTo(x + half, y - 1)
      ..lineTo(x, size.height)
      ..close();
  } else {
    path
      ..moveTo(x - half, height + 1)
      ..lineTo(x + half, height + 1)
      ..lineTo(x, 0)
      ..close();
  }
  canvas.drawPath(path, Paint()..color = fill);
}
