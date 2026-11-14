// Neumorphism's drawing helpers. Angles are degrees clockwise from 12 o'clock, as on a dial. Gradients and shadows take the
// CSS's own numbers, so a part reads as its concept: a CSS blur B is a Gaussian of sigma B / 2.
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import '../shapes.dart';
import '../theme.dart';

/// A point on a circle, [deg] clockwise from 12 o'clock.
Offset neumorphicDialPoint(double cx, double cy, double r, double deg) {
  final a = deg * math.pi / 180;
  return Offset(cx + r * math.sin(a), cy - r * math.cos(a));
}

/// An arc from [d0] to [d1], clockwise from 12 o'clock.
Path neumorphicDialArc(double cx, double cy, double r, double d0, double d1) {
  final rect = Rect.fromCircle(center: Offset(cx, cy), radius: r);
  final start = (d0 - 90) * math.pi / 180;
  return Path()..addArc(rect, start, (d1 - d0) * math.pi / 180);
}

/// CSS's `linear-gradient(<deg>, ...)` across [box].
ui.Gradient cssLinear(
  Rect box,
  double deg,
  List<Color> colors, [
  List<double>? stops,
]) {
  final a = deg * math.pi / 180;
  final dx = math.sin(a), dy = -math.cos(a);
  final half = (box.width * dx.abs() + box.height * dy.abs()) / 2;
  final mid = box.center;
  return ui.Gradient.linear(
    mid - Offset(dx * half, dy * half),
    mid + Offset(dx * half, dy * half),
    colors,
    stops,
  );
}

/// CSS's `radial-gradient(circle at x y, ...)`, reaching its farthest corner.
ui.Gradient cssRadial(
  Rect box,
  double x,
  double y,
  List<Color> colors, [
  List<double>? stops,
]) {
  final c = Offset(box.left + x * box.width, box.top + y * box.height);
  final far = [
    box.topLeft,
    box.topRight,
    box.bottomLeft,
    box.bottomRight,
  ].map((o) => (o - c).distance).reduce(math.max);
  return ui.Gradient.radial(c, far, colors, stops);
}

/// An antialiased stroke, with round joins and optionally round caps.
Paint neumorphicStrokePaint(Color color, double width, {bool round = true}) =>
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = round ? StrokeCap.round : StrokeCap.butt
      ..strokeJoin = StrokeJoin.round
      ..color = color
      ..isAntiAlias = true;

/// An antialiased solid fill.
Paint neumorphicFillPaint(Color color) => Paint()
  ..style = PaintingStyle.fill
  ..color = color
  ..isAntiAlias = true;

/// Joins [pts] with straight segments, closing the last segment by default.
Path neumorphicPolyPath(Iterable<Offset> pts, {bool close = true}) {
  final p = Path();
  var first = true;
  for (final o in pts) {
    first ? p.moveTo(o.dx, o.dy) : p.lineTo(o.dx, o.dy);
    first = false;
  }
  if (close) p.close();
  return p;
}

/// A dashed copy of a straight-sided or curved [path].
Path neumorphicDashed(Path path, double on, double off) {
  final out = Path();
  for (final m in path.computeMetrics()) {
    var d = 0.0;
    while (d < m.length) {
      out.addPath(m.extractPath(d, math.min(d + on, m.length)), Offset.zero);
      d += on + off;
    }
  }
  return out;
}

/// A monotone cubic through [pts], so a curve never overshoots a reading (Fritsch and Carlson).
Path neumorphicMonotonePath(List<Offset> pts) {
  final p = Path();
  if (pts.isEmpty) return p;
  p.moveTo(pts.first.dx, pts.first.dy);
  final n = pts.length;
  if (n < 3) {
    for (final o in pts.skip(1)) {
      p.lineTo(o.dx, o.dy);
    }
    return p;
  }
  final d = [
    for (var i = 0; i < n - 1; i++)
      (pts[i + 1].dy - pts[i].dy) / math.max(pts[i + 1].dx - pts[i].dx, .0001),
  ];
  final m = List<double>.filled(n, 0);
  m[0] = d.first;
  m[n - 1] = d.last;
  for (var i = 1; i < n - 1; i++) {
    m[i] = d[i - 1] * d[i] <= 0 ? 0 : (d[i - 1] + d[i]) / 2;
  }
  for (var i = 0; i < n - 1; i++) {
    if (d[i] == 0) {
      m[i] = m[i + 1] = 0;
      continue;
    }
    final a = m[i] / d[i], b = m[i + 1] / d[i];
    final s = a * a + b * b;
    if (s > 9) {
      final t = 3 / math.sqrt(s);
      m[i] = t * a * d[i];
      m[i + 1] = t * b * d[i];
    }
  }
  for (var i = 0; i < n - 1; i++) {
    final h = pts[i + 1].dx - pts[i].dx;
    p.cubicTo(
      pts[i].dx + h / 3,
      pts[i].dy + m[i] * h / 3,
      pts[i + 1].dx - h / 3,
      pts[i + 1].dy - m[i + 1] * h / 3,
      pts[i + 1].dx,
      pts[i + 1].dy,
    );
  }
  return p;
}

/// A theme's pill becomes its rounded content frame when its words need more
/// than one line. Explicit widget styles remain the caller's shape choice.
OutlinedBorder? neumorphicInlineRoleShape(
  BuildContext context, {
  required OutlinedBorder? shape,
  required String text,
  required TextStyle textStyle,
  required double width,
  required EdgeInsets padding,
  double beside = 0,
}) {
  if (shape is! NeumorphicStadiumBorder || !width.isFinite) return shape;
  final measure = TextPainter(
    text: TextSpan(text: text, style: textStyle),
    textDirection: Directionality.of(context),
    textScaler: MediaQuery.textScalerOf(context),
  )..layout();
  final needed =
      measure.width +
      padding.horizontal +
      beside +
      shape.dimensions.resolve(Directionality.of(context)).horizontal;
  final wraps = measure.computeLineMetrics().length > 1 || needed > width;
  measure.dispose();
  return wraps ? const NeumorphicRoundedBorder() : shape;
}

/// [padding] less a one-line face's [cut] (its shape's cut-in) at the top and bottom. The two are distances from the
/// same edge, so the line clears the larger of them, not their sum: a 36 pill holds its 20 line instead of standing
/// 50 high. Sideways they still add, as the cut-in is where a stadium's ends round off and the padding is the air after.
EdgeInsets neumorphicClearOfCut(EdgeInsets padding, EdgeInsets cut) =>
    EdgeInsets.fromLTRB(
      padding.left,
      math.max(0.0, padding.top - cut.top),
      padding.right,
      math.max(0.0, padding.bottom - cut.bottom),
    );

/// The corner at [b] between [a] and [c], rounded by the look's least corner (law 8): where the round leaves the line
/// from [a], its middle, where it meets the line to [c], and its radius (less where the lines are too short for it).
({Offset start, Offset mid, Offset end, double radius}) neumorphicCorner(
  Offset a,
  Offset b,
  Offset c,
) {
  final u = (a - b) / (a - b).distance, v = (c - b) / (c - b).distance;
  final half = math.acos((u.dx * v.dx + u.dy * v.dy).clamp(-1.0, 1.0)) / 2;
  final reach = math.min(
    NeumorphicRadii.least / math.tan(half),
    math.min((a - b).distance, (c - b).distance) / 2,
  );
  final radius = reach * math.tan(half);
  final w = (u + v) / (u + v).distance;
  final centre = b + w * (radius / math.sin(half));
  return (
    start: b + u * reach,
    mid: centre - w * radius,
    end: b + v * reach,
    radius: radius,
  );
}

/// A polygon (or with [close] false, a line) through [pts], every corner rounded as [neumorphicCorner] rounds it.
Path neumorphicRoundedPath(List<Offset> pts, {bool close = true}) {
  final n = pts.length;
  final path = Path();
  for (var i = 0; i < n; i++) {
    final b = pts[i];
    if (!close && (i == 0 || i == n - 1)) {
      if (i == 0) {
        path.moveTo(b.dx, b.dy);
      } else {
        path.lineTo(b.dx, b.dy);
      }
      continue;
    }
    final a = pts[(i - 1 + n) % n], c = pts[(i + 1) % n];
    final round = neumorphicCorner(a, b, c);
    if (i == 0) {
      path.moveTo(round.start.dx, round.start.dy);
    } else {
      path.lineTo(round.start.dx, round.start.dy);
    }
    // Travelling a, b, c: a turn to the right is clockwise on the screen.
    final u = a - b, v = c - b;
    path.arcToPoint(
      round.end,
      radius: Radius.circular(round.radius),
      clockwise: u.dx * v.dy - u.dy * v.dx < 0,
    );
  }
  if (close) path.close();
  return path;
}
