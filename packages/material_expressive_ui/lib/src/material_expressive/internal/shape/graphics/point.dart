part of 'graphics.dart';

/// A function that moves the point (x, y) to a new point.
typedef ExpressivePointTransformer = (double, double) Function(
  double x,
  double y,
);

/// A point, or a vector, in two dimensions.
@immutable
class ExpressivePoint {
  /// The point (0, 0).
  static const zero = ExpressivePoint(0, 0);

  /// A point at ([x], [y]).
  const ExpressivePoint(this.x, this.y);

  /// The x coordinate.
  final double x;

  /// The y coordinate.
  final double y;

  /// A copy of this point.
  ExpressivePoint copy() => ExpressivePoint(x, y);

  /// This point turned a quarter turn about the origin.
  ExpressivePoint rotate90() => ExpressivePoint(-y, x);

  /// This point turned by [degrees] about [center].
  ExpressivePoint rotate(
    double degrees, {
    ExpressivePoint center = ExpressivePoint.zero,
  }) {
    final radians = degrees * math.pi / 180;
    final off = this - center;
    final cos = math.cos(radians);
    final sin = math.sin(radians);
    return ExpressivePoint(
          off.x * cos - off.y * sin,
          off.x * sin + off.y * cos,
        ) +
        center;
  }

  /// This point moved by [dx] along x and [dy] along y.
  ExpressivePoint translate(double dx, double dy) =>
      ExpressivePoint(x + dx, y + dy);

  /// This point with x multiplied by [sx] and y by [sy].
  ExpressivePoint scale(double sx, double sy) =>
      ExpressivePoint(x * sx, y * sy);

  /// The angle of this vector from the x axis, in degrees.
  double get angleDegrees => angleRadians * 180 / math.pi;

  /// The angle of this point from the positive x axis, in radians.
  double get angleRadians => math.atan2(y, x);

  /// The magnitude of the [ExpressivePoint], which is the distance of this point from
  /// (0, 0).
  ///
  /// If you need this value to compare it to another [ExpressivePoint]'s distance,
  /// consider using [getDistanceSquared] instead, since it is cheaper to
  /// compute.
  double getDistance() => math.sqrt(x * x + y * y);

  /// The square of the magnitude (which is the distance of this point from
  /// (0, 0)) of the [ExpressivePoint].
  ///
  /// This is cheaper than computing the [getDistance] itself.
  double getDistanceSquared() => x * x + y * y;

  /// The dot product of this point and [other].
  double dotProduct(ExpressivePoint other) => x * other.x + y * other.y;

  /// The dot product of this point and the point ([otherX], [otherY]).
  double dotProductXY(double otherX, double otherY) => x * otherX + y * otherY;

  /// Compute the Z coordinate of the cross product of two vectors, to check
  /// if the second vector is going clockwise ( > 0 ) or counterclockwise
  /// (< 0) compared with the first one. It could also be 0, if the vectors
  /// are co-linear.
  bool clockwise(ExpressivePoint other) => (x * other.y - y * other.x) > 0;

  /// This point divided by its distance from the origin.
  ExpressivePoint getDirection() {
    final d = getDistance();
    assert(d > 0, "Can't get the direction of a 0-length vector");
    return this / d;
  }

  /// Unary negation operator.
  ///
  /// Returns a [ExpressivePoint] with the coordinates negated.
  ///
  /// If the [ExpressivePoint] represents an arrow on a plane, this operator returns the
  /// same arrow but pointing in the reverse direction.
  ExpressivePoint operator -() => ExpressivePoint(-x, -y);

  /// Binary subtraction operator.
  ///
  /// Returns a Point whose [x] value is the left-hand-side operand's [x]
  /// minus the right-hand-side operand's [x] and whose [y] value is the
  /// left-hand-side operand's [y] minus the right-hand-side operand's [y].
  ExpressivePoint operator -(ExpressivePoint operand) =>
      ExpressivePoint(x - operand.x, y - operand.y);

  /// Binary addition operator.
  ///
  /// Returns a Point whose [x] value is the sum of the [x] values of the two
  /// operands, and whose [y] value is the sum of the [y] values of the two
  /// operands.
  ExpressivePoint operator +(ExpressivePoint operand) =>
      ExpressivePoint(x + operand.x, y + operand.y);

  /// Multiplication operator.
  ///
  /// Returns a Point whose coordinates are the coordinates of the
  /// left-hand-side operand (a [ExpressivePoint]) multiplied by the scalar
  /// right-hand-side operand (a [double]).
  ExpressivePoint operator *(double operand) =>
      ExpressivePoint(x * operand, y * operand);

  /// Division operator.
  ///
  /// Returns a Point whose coordinates are the coordinates of the
  /// left-hand-side operand (a [ExpressivePoint]) divided by the scalar
  /// right-hand-side operand (a [double]).
  ExpressivePoint operator /(double operand) =>
      ExpressivePoint(x / operand, y / operand);

  /// Modulo (remainder) operator.
  ///
  /// Returns a Point whose coordinates are the remainder of dividing the
  /// coordinates of the left-hand-side operand (a [ExpressivePoint]) by the scalar
  /// right-hand-side operand (a [double]).
  ExpressivePoint operator %(double operand) =>
      ExpressivePoint(x % operand, y % operand);

  /// The point [f] moves this point to.
  ExpressivePoint transformed(ExpressivePointTransformer f) {
    final result = f(x, y);
    return ExpressivePoint(result.$1, result.$2);
  }

  @override
  String toString() => 'Point($x, $y)';

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) {
      return true;
    }

    if (other is! ExpressivePoint) {
      return false;
    }

    return other.x == x && other.y == y;
  }

  @override
  int get hashCode => Object.hashAll([x, y]);
}

/// Linearly interpolate between two Points.
///
/// The [fraction] argument represents position on the timeline,
/// with 0.0 meaning that the interpolation has not started, returning
/// [start] (or something equivalent to [start]), 1.0 meaning that the
/// interpolation has finished, returning [stop] (or something equivalent to
/// [stop]), and values in between meaning that the interpolation is at the
/// relevant point on the timeline between [start] and [stop]. The
/// interpolation can be extrapolated beyond 0.0 and 1.0, so negative values
/// and values greater than 1.0 are valid (and can easily be generated by
/// curves).
ExpressivePoint _interpolate(
  ExpressivePoint start,
  ExpressivePoint stop,
  double fraction,
) {
  return ExpressivePoint(
    _lerp(start.x, stop.x, fraction),
    _lerp(start.y, stop.y, fraction),
  );
}
