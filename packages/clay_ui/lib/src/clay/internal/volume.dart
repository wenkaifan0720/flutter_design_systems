/// Clay's volume for a shape of any outline (a donut's piece, a ring's band,
/// an area under a line, a dent), as `ClaySurface` draws a rounded one: a
/// soft light inside its top-leading edge, a soft shade inside its
/// bottom-trailing edge, one soft shadow straight down in its own hue; or,
/// pressed in, a well: the shade at the top-leading edge, the light at the
/// bottom-trailing.
library;

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../theme.dart';

/// A soft band of [color] inside [shape]'s top-leading edges ([start]) or
/// its bottom-trailing edges: the ground round the shape moved [offset] away
/// from that edge, blurred by [blur], kept inside the shape. [mirrored]
/// flips leading for right to left.
void clayPaintInset(
  Canvas canvas,
  Path shape, {
  required bool start,
  required double offset,
  required double blur,
  required Color color,
  bool mirrored = false,
}) {
  if (color.a <= 0) return;
  final x = mirrored ? -offset : offset;
  final away = start ? Offset(x, offset) : Offset(-x, -offset);
  final bounds = shape.getBounds();
  final band = Path()
    ..fillType = PathFillType.evenOdd
    ..addRect(bounds.inflate(4 * blur + offset.abs() + 4))
    ..addPath(shape, away);
  canvas
    ..save()
    ..clipPath(shape)
    ..drawPath(
      band,
      Paint()
        ..color = color
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur),
    )
    ..restore();
}

/// How wide a shape's inner light and shade run, from its thickness [side]
/// (as `ClaySurface`'s: 9%, 2 to 8).
double clayInnerFor(double side) => (side * 0.09).clamp(2.0, 8.0);

/// The one soft shadow [shape], raised in [color], casts straight down, in
/// its own hue, at Clay's raised level ([lift] 0 to 1 raises it toward the
/// pointer: softer and further). [side] is its thickness.
void clayPaintDrop(
  Canvas canvas,
  Path shape, {
  required ClayColors colors,
  required Color color,
  required double side,
  double lift = 0,
}) {
  final c = colors;
  final night = c.brightness == Brightness.dark;
  final shade = c.shadeOf(color);
  final k = ((side / 48).clamp(0.5, 1.5) * 4).roundToDouble() / 4;
  double soft(double s) => math.min(s * k, math.max(2.0, side / 6));
  final blur = soft(9) + (soft(16) - soft(9)) * 0.2 * lift;
  final opacity = night ? 0.62 : (color == c.clay ? 0.26 : 0.34);
  canvas.drawPath(
    shape.shift(Offset(0, blur / 2)),
    Paint()
      ..color = shade.withValues(alpha: shade.a * opacity)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur),
  );
}

/// [shape] as a raised volume of [color]: its body, the light inside its
/// top-leading edge and the shade inside its bottom-trailing edge, both in
/// its own hue's light and shade. [side] is its thickness. Its shadow is
/// [clayPaintDrop]'s, painted first.
void clayPaintVolume(
  Canvas canvas,
  Path shape, {
  required ClayColors colors,
  required Color color,
  required double side,
  bool mirrored = false,
}) {
  final c = colors;
  final night = c.brightness == Brightness.dark;
  final shade = c.shadeOf(color);
  canvas.drawPath(shape, Paint()..color = color);
  final inner = clayInnerFor(side);
  clayPaintInset(
    canvas,
    shape,
    start: true,
    offset: inner,
    blur: inner * 1.1,
    color: c.light.withValues(alpha: c.light.a * (night ? 0.16 : 0.85)),
    mirrored: mirrored,
  );
  clayPaintInset(
    canvas,
    shape,
    start: false,
    offset: inner * 1.1,
    blur: inner * 1.25,
    color: shade.withValues(
      alpha: shade.a * (night ? 0.55 : (color == c.clay ? 0.20 : 0.32)),
    ),
    mirrored: mirrored,
  );
}

/// [shape] as a well pressed into the ground (`ClayFace.well`'s): the well's
/// colour, the shade inside its top-leading edge, the light inside its
/// bottom-trailing edge. [side] is its thickness.
void clayPaintWell(
  Canvas canvas,
  Path shape, {
  required ClayColors colors,
  required double side,
  Color? color,
  bool mirrored = false,
}) {
  final c = colors;
  final night = c.brightness == Brightness.dark;
  final shade = color == null ? c.groundShade : c.shadeOf(color);
  canvas.drawPath(shape, Paint()..color = color ?? c.well);
  final inner = clayInnerFor(side);
  clayPaintInset(
    canvas,
    shape,
    start: true,
    offset: inner * 0.8,
    blur: inner * 0.9,
    color: shade.withValues(alpha: shade.a * (night ? 0.75 : 0.22)),
    mirrored: mirrored,
  );
  clayPaintInset(
    canvas,
    shape,
    start: false,
    offset: inner,
    blur: inner * 1.1,
    color: c.light.withValues(alpha: c.light.a * (night ? 0.06 : 0.75)),
    mirrored: mirrored,
  );
}
