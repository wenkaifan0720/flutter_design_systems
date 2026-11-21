/// The pieces of clay a Clay donut is moulded from, laid out honestly: a
/// small gap of the ground between each, ends rounded with continuous
/// corners, and each piece's area its share of the ring's clay, so neither
/// the gaps nor the round ends change how big a share looks.
library;

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// One piece of a donut: where it runs, clockwise from [start] for [sweep]
/// radians (both [Canvas.drawArc]'s: 0 at three o'clock), and the corner
/// radius at its outer and inner edge (the same at both its ends). A corner
/// radius of 0 is a square end.
@immutable
class ClaySliceShape {
  /// A piece.
  const ClaySliceShape({
    required this.start,
    required this.sweep,
    required this.outerCorner,
    required this.innerCorner,
  });

  /// Where it starts.
  final double start;

  /// How far it runs, clockwise; 0 to 2π.
  final double sweep;

  /// Its corners' radius on the outer edge.
  final double outerCorner;

  /// Its corners' radius on the inner edge.
  final double innerCorner;

  /// Its middle.
  double get mid => start + sweep / 2;

  /// Whether it is the whole ring: no ends.
  bool get whole => sweep >= 2 * math.pi - 1e-6;

  /// Its outline round [centre], between [outer] and [inner].
  Path path(Offset centre, double outer, double inner) {
    Offset at(double angle, double radius) =>
        centre + Offset(math.cos(angle), math.sin(angle)) * radius;
    if (whole) {
      return Path()
        ..fillType = PathFillType.evenOdd
        ..addOval(Rect.fromCircle(center: centre, radius: outer))
        ..addOval(Rect.fromCircle(center: centre, radius: inner));
    }
    final a0 = start;
    final a1 = start + sweep;
    final ro = outerCorner;
    final ri = inner > 0 ? innerCorner : 0.0;
    // Each corner is a circle touching the radial edge and the rim.
    final dOut = ro > 0 ? math.asin(ro / (outer - ro)) : 0.0;
    final dIn = ri > 0 ? math.asin(ri / (inner + ri)) : 0.0;
    final edgeOut = ro > 0 ? (outer - ro) * math.cos(dOut) : outer;
    final edgeIn = ri > 0 ? (inner + ri) * math.cos(dIn) : inner;
    final outerRect = Rect.fromCircle(center: centre, radius: outer);
    final innerRect = Rect.fromCircle(center: centre, radius: inner);
    final path = Path()
      ..moveTo(at(a0, edgeIn).dx, at(a0, edgeIn).dy)
      ..lineTo(at(a0, edgeOut).dx, at(a0, edgeOut).dy);
    if (ro > 0) {
      path.arcToPoint(at(a0 + dOut, outer), radius: Radius.circular(ro));
    }
    path.arcTo(outerRect, a0 + dOut, sweep - 2 * dOut, false);
    if (ro > 0) {
      path.arcToPoint(at(a1, edgeOut), radius: Radius.circular(ro));
    }
    path.lineTo(at(a1, edgeIn).dx, at(a1, edgeIn).dy);
    if (inner > 0) {
      if (ri > 0) {
        path.arcToPoint(at(a1 - dIn, inner), radius: Radius.circular(ri));
      }
      path.arcTo(innerRect, a1 - dIn, -(sweep - 2 * dIn), false);
      if (ri > 0) {
        path.arcToPoint(at(a0, edgeIn), radius: Radius.circular(ri));
      }
    }
    return path..close();
  }

  /// Its area, between [outer] and [inner].
  double area(double outer, double inner) {
    final ring = (outer * outer - inner * inner) / 2;
    if (whole) return 2 * math.pi * ring;
    return sweep * ring -
        2 * claySliceCornerLoss(outer, inner, outerCorner, innerCorner);
  }

  /// This piece mirrored left for right, about twelve o'clock.
  ClaySliceShape mirrored() => ClaySliceShape(
    start: math.pi - start - sweep,
    sweep: sweep,
    outerCorner: outerCorner,
    innerCorner: innerCorner,
  );

  @override
  bool operator ==(Object other) =>
      other is ClaySliceShape &&
      other.start == start &&
      other.sweep == sweep &&
      other.outerCorner == outerCorner &&
      other.innerCorner == innerCorner;

  @override
  int get hashCode => Object.hash(start, sweep, outerCorner, innerCorner);

  @override
  String toString() =>
      'ClaySliceShape(${start.toStringAsFixed(4)}, '
      '${sweep.toStringAsFixed(4)}, ${outerCorner.toStringAsFixed(2)}, '
      '${innerCorner.toStringAsFixed(2)})';
}

/// The clay one end of a piece loses to its round corners: the outer corner
/// of radius [outerCorner] on the rim of radius [outer], the inner one of
/// [innerCorner] on the rim of radius [inner]. Exact, for corners that touch
/// a radial edge and a circle.
double claySliceCornerLoss(
  double outer,
  double inner,
  double outerCorner,
  double innerCorner,
) {
  var loss = 0.0;
  final ro = outerCorner;
  if (ro > 0) {
    final d = math.asin(ro / (outer - ro));
    loss +=
        d * outer * outer / 2 -
        ro * (outer - ro) * math.cos(d) / 2 -
        (math.pi / 2 + d) * ro * ro / 2;
  }
  final ri = innerCorner;
  if (ri > 0 && inner > 0) {
    final d = math.asin(ri / (inner + ri));
    loss +=
        ri * (inner + ri) * math.cos(d) / 2 -
        d * inner * inner / 2 -
        (math.pi / 2 - d) * ri * ri / 2;
  }
  return loss;
}

/// The smallest piece whose ends round: one whose edge, on [rim], runs no
/// further than a corner's radius [corner] keeps square ends; its corners
/// grow from there and are whole once the edge runs three radii.
double claySliceCorner(double sweep, double rim, double corner) {
  if (corner <= 0 || rim <= 0) return 0;
  final run = sweep * rim;
  return corner * ((run - corner) / (2 * corner)).clamp(0.0, 1.0);
}

/// The pieces of a donut of [values] (each 0 or more), clockwise from twelve
/// o'clock (counter-clockwise when [mirrored], for right to left), between
/// [outer] and [inner].
///
/// A gap of the ground [gap] wide (at the ring's middle) parts each piece
/// from the next, and each piece's corners round to [corner] (at most a
/// third of the ring's width). Each piece's area is its value's share of
/// all the clay, exactly: a piece's own gaps and round corners are paid for
/// by all the pieces together, so a 9% piece is 9% of the clay.
///
/// Every number moves continuously with the values, so a piece that grows,
/// shrinks, appears or goes never jumps: a piece's gaps narrow and its
/// corners square as it shrinks to nothing, and as one piece comes to hold
/// everything its gaps and corners close into a whole ring. A value of 0 is
/// no piece (null).
List<ClaySliceShape?> claySliceShapes(
  List<double> values, {
  required double outer,
  required double inner,
  double gap = 4,
  double? corner,
  bool mirrored = false,
}) {
  final v = [for (final x in values) x.isFinite ? math.max(0.0, x) : 0.0];
  final total = v.fold(0.0, (a, b) => a + b);
  if (total <= 0 || outer <= inner) return List.filled(v.length, null);
  const tau = 2 * math.pi;
  final band = outer - inner;
  final maxCorner = math.min(corner ?? band * 0.3, band / 3);
  final ring = (outer * outer - inner * inner) / 2;
  // The gap as an angle at the ring's middle.
  final g = gap / ((outer + inner) / 2);
  final shares = [for (final x in v) x / total];
  // How much of a gap and a round end each piece has: none as it shrinks to
  // nothing, none as it comes to hold the whole ring.
  double ramp(double x) => x.clamp(0.0, 1.0);
  final open = [
    for (final s in shares)
      g <= 0 ? 0.0 : ramp(s * tau / (2 * g)) * ramp((1 - s) * tau / (2 * g)),
  ];
  final halves = [for (final o in open) g / 2 * o];
  final gaps = halves.fold(0.0, (a, h) => a + 2 * h);
  final corners = <(double, double)>[];
  final losses = <double>[];
  for (final s in shares) {
    final rough = s * (tau - gaps);
    final closing = ramp((1 - s) * tau / (2 * math.max(g, 1e-9)));
    var ro = claySliceCorner(rough, outer, maxCorner) * closing;
    var ri = inner > 0
        ? claySliceCorner(rough, inner, maxCorner) * closing
        : 0.0;
    // Never more than the piece can hold.
    final half = math.sin(math.min(rough / 2, math.pi / 2));
    ro = math.min(ro, outer * half / (1 + half));
    if (half < 1) ri = math.min(ri, inner * half / (1 - half));
    corners.add((ro, ri));
    losses.add(2 * claySliceCornerLoss(outer, inner, ro, ri));
  }
  final clay = ring * (tau - gaps) - losses.fold(0.0, (a, b) => a + b);
  final shapes = <ClaySliceShape?>[];
  var at = -math.pi / 2;
  for (final (i, s) in shares.indexed) {
    final sweep = (s * clay + losses[i]) / ring;
    at += halves[i];
    if (s <= 0 || sweep <= 1e-9) {
      shapes.add(null);
    } else {
      final shape = ClaySliceShape(
        start: at,
        sweep: math.min(sweep, tau),
        outerCorner: corners[i].$1,
        innerCorner: corners[i].$2,
      );
      shapes.add(mirrored ? shape.mirrored() : shape);
    }
    at += sweep + halves[i];
  }
  return shapes;
}
