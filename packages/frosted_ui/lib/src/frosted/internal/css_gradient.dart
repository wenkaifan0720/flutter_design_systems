import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Turns a [LinearGradient] drawn left to right (its default `begin` and
/// `end`) into CSS's `linear-gradient(<deg>)` on any box: the gradient line
/// through the box's centre at [degrees] clockwise from straight up, as
/// long as the box needs for its corners to reach the first and last stops.
/// Plumbing of the components.
class FrostedCssAngle extends GradientTransform {
  /// Creates a [FrostedCssAngle].
  const FrostedCssAngle(this.degrees);

  /// The angle, as CSS gives it (0 points up, clockwise).
  final double degrees;

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) {
    final a = degrees * math.pi / 180;
    final w = bounds.width;
    final h = bounds.height;
    if (w <= 0) return Matrix4.identity();
    final length = (w * math.sin(a)).abs() + (h * math.cos(a)).abs();
    final c = bounds.center;
    final theta = math.atan2(-math.cos(a), math.sin(a));
    final k = length / w;
    return Matrix4.translationValues(c.dx, c.dy, 0)
      ..multiply(Matrix4.rotationZ(theta))
      ..multiply(Matrix4.diagonal3Values(k, k, 1))
      ..multiply(Matrix4.translationValues(-c.dx, -c.dy, 0));
  }
}

/// A gradient's [colors] at their [stops] (spread evenly when null) recast
/// so Flutter's mix between them follows CSS's: CSS mixes two stops with
/// their alpha premultiplied, Flutter mixes them straight, so between a
/// faint stop and a bright one of another colour Flutter's mix runs toward
/// the bright colour too soon (a beam lit from faint violet to a category's
/// hue turns blue early). Each span whose two ends differ in alpha is cut in
/// [steps], every cut at CSS's colour; a span of one alpha is left whole.
/// Plumbing of the components.
({List<Color> colors, List<double> stops}) frostedCssStops(
  List<Color> colors, {
  List<double>? stops,
  int steps = 8,
}) {
  final n = colors.length;
  final at = stops ?? [for (var i = 0; i < n; i++) n < 2 ? 0.0 : i / (n - 1)];
  final mixed = <Color>[colors.first];
  final cuts = <double>[at.first];
  for (var i = 1; i < n; i++) {
    final a = colors[i - 1];
    final b = colors[i];
    final parts = a.a == b.a ? 1 : steps;
    for (var k = 1; k <= parts; k++) {
      final f = k / parts;
      mixed.add(k == parts ? b : _premultipliedMix(a, b, f));
      cuts.add(at[i - 1] + (at[i] - at[i - 1]) * f);
    }
  }
  return (colors: mixed, stops: cuts);
}

/// CSS's mix of [a] and [b] at [f]: each channel weighted by its alpha.
Color _premultipliedMix(Color a, Color b, double f) {
  final alpha = a.a + (b.a - a.a) * f;
  if (alpha <= 0) return b.withValues(alpha: 0);
  double channel(double x, double y) =>
      (x * a.a + (y * b.a - x * a.a) * f) / alpha;
  return Color.from(
    alpha: alpha,
    red: channel(a.r, b.r),
    green: channel(a.g, b.g),
    blue: channel(a.b, b.b),
  );
}
