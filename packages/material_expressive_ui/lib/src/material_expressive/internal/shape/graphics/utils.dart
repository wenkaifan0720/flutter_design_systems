part of 'graphics.dart';

// These epsilon values are used internally to determine when two points are
// the same, within some reasonable roundoff error. The distance epsilon is
// smaller, with the intention that the roundoff should not be larger than a
// pixel on any reasonable sized display.
/// The distance below which two points count as one.
const _distanceEpsilon = 1e-4;

/// The angle, in radians, below which two directions count as one.
const _angleEpsilon = 1e-6;

// This epsilon is based on the observation that people tend to see e.g.
// collinearity much more relaxed than what is mathematically correct. This
// effect is heightened on smaller displays. Use this epsilon for operations
// that allow higher tolerances.

/// A full turn in radians.
const _twoPi = math.pi * 2;

/// The distance of (x, y) from the origin.
double _distance(double x, double y) => math.sqrt(x * x + y * y);

/// The square of the distance of (x, y) from the origin.
double _distanceSquared(double x, double y) => x * x + y * y;

/// Returns unit vector representing the direction to this point from (0, 0).
ExpressivePoint _directionVector(double x, double y) {
  final d = _distance(x, y);
  assert(d > 0, 'Required distance greater than zero.');
  return ExpressivePoint(x / d, y / d);
}

/// The unit vector pointing at [angleRadians].
ExpressivePoint _directionVectorFromAngle(double angleRadians) =>
    ExpressivePoint(math.cos(angleRadians), math.sin(angleRadians));

/// The point [radius] from [center] at [angleRadians].
ExpressivePoint _radialToCartesian(
  double radius,
  double angleRadians, [
  ExpressivePoint center = ExpressivePoint.zero,
]) => _directionVectorFromAngle(angleRadians) * radius + center;

/// [x] multiplied by itself.
double _square(double x) => x * x;

/// The angle of (x, y) from the positive x axis, in [0, 2π) (graphics-shapes
/// 1.0.1 `angle`).
double _angle(double x, double y) => (math.atan2(y, x) + _twoPi) % _twoPi;

/// Linearly interpolates between [start] and [stop] with [fraction] fraction
/// between them.
double _lerp(double start, double stop, double fraction) {
  return start * (1 - fraction) + stop * fraction;
}

/// Similar to num % mod, but ensures the result is always positive.
///
/// For example: 4 % 3 = positiveModulo(4, 3) = 1, but: -4 % 3 = -1
/// positiveModulo(-4, 3) = 2.
double _positiveModulo(double num, double mod) => (num % mod + mod) % mod;

/// Approximates whether corner at this vertex is concave or convex, based on
/// the relationship of the prev->curr/curr->next vectors.
bool _convex(
  ExpressivePoint previous,
  ExpressivePoint current,
  ExpressivePoint next,
) {
  // TODO: b/369320447 - This is a fast, but not reliable calculation.
  return (current - previous).clockwise(next - current);
}

/// Does a ternary search in [v0..v1] to find the parameter that minimizes the
/// given function.
/// Stops when the search space size is reduced below the given tolerance.
///
// NTS: Does it make sense to split the function f in 2, one to generate a
// candidate, of a custom type T (i.e. (Float) -> T), and one to evaluate it
// ( (T) -> Float )?
double _findMinimum(
  double v0,
  double v1,
  double Function(double) f, {
  double tolerance = 1e-3,
}) {
  var a = v0;
  var b = v1;

  while (b - a > tolerance) {
    final c1 = (2 * a + b) / 3;
    final c2 = (2 * b + a) / 3;

    if (f(c1) < f(c2)) {
      b = c2;
    } else {
      a = c1;
    }
  }

  return (a + b) / 2;
}

/// Bounds on a double, as Kotlin's `coerceAtLeast` and `coerceIn`.
extension _DoubleCoerceExtensions on double {
  /// This value, or [minimumValue] when it is lower.
  double coerceAtLeast(double minimumValue) =>
      this < minimumValue ? minimumValue : this;

  /// This value limited to [minimumValue] and [maximumValue].
  double coerceIn(double minimumValue, double maximumValue) {
    if (this < minimumValue) return minimumValue;
    if (this > maximumValue) return maximumValue;
    return this;
  }
}
