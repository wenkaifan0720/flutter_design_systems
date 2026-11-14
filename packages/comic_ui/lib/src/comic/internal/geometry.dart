// The drawing helpers parts share. Angles are degrees, counter-clockwise from +x with y up, as on a dial.
import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// A point at radius [r] and angle [a] in degrees around ([cx], [cy]).
Offset polar(double cx, double cy, double r, double a) {
  final t = a * math.pi / 180;
  return Offset(cx + r * math.cos(t), cy - r * math.sin(t));
}

/// Connects [pts] in order and closes the contour when [close] is true.
Path polyPath(Iterable<Offset> pts, {bool close = true}) {
  final p = Path();
  var first = true;
  for (final o in pts) {
    first ? p.moveTo(o.dx, o.dy) : p.lineTo(o.dx, o.dy);
    first = false;
  }
  if (close) p.close();
  return p;
}

/// A stroke paint using [color] and the logical-pixel [width].
Paint strokePaint(Color color, double width) => Paint()
  ..style = PaintingStyle.stroke
  ..strokeWidth = width
  ..color = color;

/// A solid fill paint using [color].
Paint fillPaint(Color color) => Paint()
  ..style = PaintingStyle.fill
  ..color = color;

/// A small repeatable random: a burst's jags and a seed's pick don't change between runs or devices.
class ComicRand {
  /// Creates a [ComicRand].
  ComicRand(int seed) : _s = (seed * 2654435761 + 12345) & 0x7FFFFFFF;
  int _s;

  /// The next repeatable pseudo-random value in the half-open range 0 to 1.
  double next() {
    _s = (_s * 1103515245 + 12345) & 0x7FFFFFFF;
    return _s / 0x7FFFFFFF;
  }

  /// A repeatable pseudo-random value between [a] and [b].
  double range(double a, double b) => a + (b - a) * next();
}

/// The points of a jagged star in a box [w] by [h]: every other point out on the rim, every other in at [inner].
List<Offset> burstPoints(
  double w,
  double h, {
  int spikes = 14,
  int seed = 3,
  double inner = .72,
  double jitter = .09,
  double pad = 4,
}) {
  final r = ComicRand(seed);
  final cx = w / 2, cy = h / 2, rx = w / 2 - pad, ry = h / 2 - pad;
  return [
    for (var i = 0; i < 2 * spikes; i++)
      () {
        final a = -math.pi / 2 + math.pi * i / spikes + r.range(-.05, .05);
        final f = i.isEven
            ? 1 - r.range(0, jitter)
            : inner + r.range(-jitter, jitter) * .6;
        return Offset(cx + rx * f * math.cos(a), cy + ry * f * math.sin(a));
      }(),
  ];
}
