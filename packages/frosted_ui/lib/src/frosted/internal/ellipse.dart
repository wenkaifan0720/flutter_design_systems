import 'package:flutter/widgets.dart';

/// Stretches a [RadialGradient] of `radius: 1` into a CSS ellipse: one
/// [rx] of the box's width across and [ry] of its height down, round the
/// point [cx], [cy] (fractions of the box) that the gradient's `center`
/// names too. CSS sizes a radial's ellipse by the box's sides; Flutter
/// draws a circle of the shortest side, so this scales that circle round its
/// centre.
class FrostedEllipse extends GradientTransform {
  /// Creates a [FrostedEllipse].
  const FrostedEllipse({
    required this.rx,
    required this.ry,
    required this.cx,
    required this.cy,
  });

  /// How far the ellipse reaches across, a fraction of the box's width.
  final double rx;

  /// How far the ellipse reaches down, a fraction of the box's height.
  final double ry;

  /// The centre across, a fraction of the width.
  final double cx;

  /// The centre down, a fraction of the height.
  final double cy;

  /// The gradient centre this ellipse is drawn round, as an [Alignment].
  Alignment get center => Alignment(cx * 2 - 1, cy * 2 - 1);

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) {
    final r = bounds.shortestSide;
    if (r <= 0) return Matrix4.identity();
    final x = bounds.left + bounds.width * cx;
    final y = bounds.top + bounds.height * cy;
    return Matrix4.translationValues(x, y, 0)
      ..multiply(
        Matrix4.diagonal3Values(
          rx * bounds.width / r,
          ry * bounds.height / r,
          1,
        ),
      )
      ..multiply(Matrix4.translationValues(-x, -y, 0));
  }
}
