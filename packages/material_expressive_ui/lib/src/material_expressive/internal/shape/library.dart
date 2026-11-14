/// The helpers `MaterialShapes.kt` builds its shapes with — `customPolygon`
/// and its `doRepeat`, `PointNRound`, and the `Matrix` rotations and scales
/// its `.transformed(...)` calls apply — which the generated
/// `library_shapes.g.dart` names, and the per-shape caches `shape.dart`
/// reads: each library shape normalized once (Compose's `MaterialShapes`
/// getters cache the same way) and its unit path.
///
/// Owner: w1-shape. Internal.
library;

import 'dart:math' as math;
import 'dart:ui';

import 'graphics/graphics.dart';
import 'library_shapes.g.dart';

/// One vertex of a custom polygon and its rounding (Compose's private
/// `PointNRound`).
class ExpressivePointNRound {
  /// A vertex at ([x], [y]) with the given [rounding].
  const ExpressivePointNRound(
    this.x,
    this.y, [
    this.rounding = ExpressiveCornerRounding.unrounded,
  ]);

  /// The x coordinate of the vertex.
  final double x;

  /// The y coordinate of the vertex.
  final double y;

  /// The rounding at the vertex.
  final ExpressiveCornerRounding rounding;
}

double _angleDegrees(double x, double y) => math.atan2(y, x) * 180 / math.pi;

double _toRadians(double degrees) => degrees / 360 * 2 * math.pi;

/// `MaterialShapes.customPolygon`: [points] repeated [reps] times around
/// ([centerX], [centerY]) — or, [mirroring], `2 × reps` times, every other
/// section mirrored — as a polygon centred there (`doRepeat`).
ExpressiveRoundedPolygon expressiveCustomPolygon({
  required int reps,
  required double centerX,
  required double centerY,
  required bool mirroring,
  required List<ExpressivePointNRound> points,
}) {
  final vertices = <double>[];
  final rounding = <ExpressiveCornerRounding>[];
  void add(double x, double y, ExpressiveCornerRounding r) {
    vertices
      ..add(x)
      ..add(y);
    rounding.add(r);
  }

  if (mirroring) {
    final angles = [
      for (final p in points) _angleDegrees(p.x - centerX, p.y - centerY),
    ];
    final distances = [
      for (final p in points)
        math.sqrt(
          (p.x - centerX) * (p.x - centerX) + (p.y - centerY) * (p.y - centerY),
        ),
    ];
    final actualReps = reps * 2;
    final sectionAngle = 360 / actualReps;
    for (var it = 0; it < actualReps; it++) {
      for (var index = 0; index < points.length; index++) {
        final i = it.isEven ? index : points.length - 1 - index;
        if (i > 0 || it.isEven) {
          final a = _toRadians(
            sectionAngle * it +
                (it.isEven
                    ? angles[i]
                    : sectionAngle - angles[i] + 2 * angles[0]),
          );
          add(
            math.cos(a) * distances[i] + centerX,
            math.sin(a) * distances[i] + centerY,
            points[i].rounding,
          );
        }
      }
    }
  } else {
    final np = points.length;
    for (var it = 0; it < np * reps; it++) {
      final p = points[it % np];
      final a = _toRadians((it ~/ np) * 360 / reps);
      final ox = p.x - centerX;
      final oy = p.y - centerY;
      add(
        ox * math.cos(a) - oy * math.sin(a) + centerX,
        ox * math.sin(a) + oy * math.cos(a) + centerY,
        p.rounding,
      );
    }
  }
  return ExpressiveRoundedPolygon.fromVertices(
    vertices,
    perVertexRounding: rounding,
    centerX: centerX,
    centerY: centerY,
  );
}

/// [polygon] through Compose's `Matrix().apply { rotateZ(degrees) }`.
ExpressiveRoundedPolygon expressiveRotated(
  ExpressiveRoundedPolygon polygon,
  double degrees,
) {
  final r = degrees * math.pi / 180;
  final s = math.sin(r);
  final c = math.cos(r);
  return polygon.transformed((x, y) => (c * x - s * y, s * x + c * y));
}

/// [polygon] through Compose's `Matrix().apply { scale(x, y) }`.
ExpressiveRoundedPolygon expressiveScaled(
  ExpressiveRoundedPolygon polygon,
  double x,
  double y,
) => polygon.transformed((px, py) => (px * x, py * y));

final List<ExpressiveRoundedPolygon?> _polygons =
    List<ExpressiveRoundedPolygon?>.filled(
      ExpressiveMaterialShape.values.length,
      null,
    );

final List<Path?> _unitPaths = List<Path?>.filled(
  ExpressiveMaterialShape.values.length,
  null,
);

/// [shape] normalized into the unit square, built once: what Compose's
/// `MaterialShapes.<Name>` returns.
ExpressiveRoundedPolygon expressiveLibraryPolygon(
  ExpressiveMaterialShape shape,
) => _polygons[shape.index] ??= expressiveLibraryShape(shape).normalized();

/// [shape]'s outline in the unit square, built once (Compose's
/// `RoundedPolygon.toPath`, start angle 0). Never mutated: callers
/// transform a copy.
Path expressiveLibraryUnitPath(ExpressiveMaterialShape shape) =>
    _unitPaths[shape.index] ??= expressiveCubicsPath(
      expressiveLibraryPolygon(shape).cubics,
    );

/// [cubics] as one closed path (Compose's `pathFromCubics`).
Path expressiveCubicsPath(List<ExpressiveShapeCubic> cubics) {
  final path = Path();
  for (var i = 0; i < cubics.length; i++) {
    final c = cubics[i];
    if (i == 0) path.moveTo(c.anchor0X, c.anchor0Y);
    path.cubicTo(
      c.control0X,
      c.control0Y,
      c.control1X,
      c.control1Y,
      c.anchor1X,
      c.anchor1Y,
    );
  }
  return path..close();
}
