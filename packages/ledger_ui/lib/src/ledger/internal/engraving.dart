import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import 'hatch.dart';

/// The source's engraving primitives, drawn on a canvas in the
/// source's own units: every stroke width, dash and opacity is the one its
/// SVG writes. Plumbing of the engravings.

/// `art.hatch_rect`: strokes at [angle] degrees rising to the right,
/// [spacing] apart across x, clipped exactly to the box [x0], [y0], [x1],
/// [y1] (gauges, bars, a card's chip). A box thinner than .4 is left bare.
Path ledgerHatchRect(
  double x0,
  double y0,
  double x1,
  double y1,
  double spacing, {
  double angle = 60,
}) {
  final path = Path();
  if (x1 - x0 < .4 || y1 - y0 < .4) return path;
  final a = angle * math.pi / 180;
  final k = 1 / math.tan(a);
  final h = y1 - y0;
  var c = x0 - h * k - spacing;
  while (c <= x1 + spacing) {
    var px = c, py = y1, qx = c + h * k, qy = y0;
    final at = c;
    double atX(double x) => y1 - (x - at) / k;
    if (px < x0) {
      px = x0;
      py = atX(x0);
    }
    if (qx > x1) {
      qx = x1;
      qy = atX(x1);
    }
    if (qx - px > .3 && py > qy) {
      path
        ..moveTo(px, py)
        ..lineTo(qx, qy);
    }
    c += spacing;
  }
  return path;
}

/// `art.interp`: the polyline through [points] as a function of x, null
/// outside its span.
double? Function(double x) ledgerInterp(List<Offset> points) {
  final xs = [for (final p in points) p.dx];
  return (x) {
    if (x < xs.first - 1e-9 || x > xs.last + 1e-9) return null;
    // The first segment holding x, as the source walks them: one before
    // the first point at or past x.
    var lo = 0, hi = xs.length;
    while (lo < hi) {
      final mid = (lo + hi) >> 1;
      if (xs[mid] < x) {
        lo = mid + 1;
      } else {
        hi = mid;
      }
    }
    final i = math.max(0, lo - 1);
    if (i + 1 >= points.length) return points.last.dy;
    final a = points[i], b = points[i + 1];
    if (x < a.dx || x > b.dx) return points.last.dy;
    if (b.dx == a.dx) return a.dy;
    return a.dy + (b.dy - a.dy) * (x - a.dx) / (b.dx - a.dx);
  };
}

/// [color] at [opacity] of its own alpha (an SVG `stroke-opacity`).
Color ledgerInk(Color color, double opacity) =>
    color.withValues(alpha: color.a * opacity);

/// A stroke of [color] [width] wide.
Paint ledgerStroke(Color color, double width) => Paint()
  ..style = PaintingStyle.stroke
  ..strokeWidth = width
  ..color = color;

/// `art.fade`: the hatch's ink fading from [a0] of [color] at [y0] to [a1]
/// at [y1] (a userSpaceOnUse linear gradient).
Shader ledgerFade(
  Color color,
  double y0,
  double y1, {
  double a0 = .62,
  double a1 = .10,
}) => ui.Gradient.linear(Offset(0, y0), Offset(0, y1), [
  ledgerInk(color, a0),
  ledgerInk(color, a1),
]);

/// `art.dotted`: a grid line at [y] from [x0] to [x1], dashes of 1 every 4,.
/// 8 wide, the ink at .28.
void ledgerDotted(
  Canvas canvas,
  double y,
  double x0,
  double x1,
  Color color, {
  double opacity = .28,
}) {
  final paint = ledgerStroke(ledgerInk(color, opacity), .8);
  for (var x = x0; x < x1; x += 4) {
    canvas.drawLine(Offset(x, y), Offset(math.min(x + 1, x1), y), paint);
  }
}

/// `art.double_rule`: a rule .9 wide at [y] and a .5 one [gap] above it.
void ledgerDoubleRule(
  Canvas canvas,
  double y,
  double x0,
  double x1,
  Color color, {
  double gap = 3,
}) {
  canvas
    ..drawLine(Offset(x0, y), Offset(x1, y), ledgerStroke(color, .9))
    ..drawLine(
      Offset(x0, y - gap),
      Offset(x1, y - gap),
      ledgerStroke(color, .5),
    );
}

/// `art.engraved_area`'s two hatches under the line through [points]: the
/// fill (45°, [spacing] apart, 2.2 under the line, inked by the fade) and,
/// with [band], the engraver's shadow under the line (135°, 1.15 times as
/// far apart, 13 deep). Heavy: computed once per size and kept.
({Path fill, Path? band}) ledgerEngravedArea(
  List<Offset> points,
  double top,
  double yb,
  double spacing, {
  bool band = true,
  double? x0,
  double? x1,
}) {
  final fn = ledgerInterp(points);
  final from = x0 ?? points.first.dx;
  final to = x1 ?? points.last.dx;
  final fill = ledgerHatch(
    (x, y) {
      final v = fn(x);
      return v != null && y >= v + 2.2;
    },
    from,
    top,
    to,
    yb,
    spacing,
  );
  final shadow = band
      ? ledgerHatch(
          (x, y) {
            final v = fn(x);
            return v != null && v + 2.2 <= y && y <= math.min(v + 13, yb);
          },
          from,
          top,
          to,
          yb,
          spacing * 1.15,
          angle: 135 - 0.001,
        )
      : null;
  return (fill: fill, band: shadow);
}

/// Paints [area]: the fill in [fade] at [width], the band in [color] at .45
/// and .8 of the width.
void ledgerPaintArea(
  Canvas canvas,
  ({Path fill, Path? band}) area,
  Shader fade,
  Color color,
  double width,
) {
  canvas.drawPath(
    area.fill,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..shader = fade,
  );
  if (area.band case final band?) {
    canvas.drawPath(band, ledgerStroke(ledgerInk(color, .45), width * .8));
  }
}

/// The polyline through [points].
Path ledgerPolyline(List<Offset> points) {
  final path = Path()..moveTo(points.first.dx, points.first.dy);
  for (final p in points.skip(1)) {
    path.lineTo(p.dx, p.dy);
  }
  return path;
}

/// [path] cut into an SVG dash [pattern] (on, off, ...), the pattern running
/// on along the whole path from its start.
Path ledgerDashed(Path path, List<double> pattern) {
  final out = Path();
  for (final metric in path.computeMetrics()) {
    var d = 0.0;
    var i = 0;
    while (d < metric.length) {
      final len = pattern[i % pattern.length];
      if (i.isEven) {
        out.addPath(
          metric.extractPath(d, math.min(d + len, metric.length)),
          Offset.zero,
        );
      }
      d += len;
      i++;
    }
  }
  return out;
}

/// `art.inked_line`: the line through [points] over a paper knock-out
/// [knock] wide (so the hatching stops short of it), [width] wide, round
/// joined and capped, dashed by [dash] when given.
void ledgerInkedLine(
  Canvas canvas,
  List<Offset> points,
  Color color,
  Color paper, {
  double width = 1.5,
  double knock = 5,
  List<double>? dash,
}) {
  final line = ledgerPolyline(points);
  canvas.drawPath(
    line,
    ledgerStroke(paper, knock)..strokeJoin = StrokeJoin.round,
  );
  canvas.drawPath(
    dash == null ? line : ledgerDashed(line, dash),
    ledgerStroke(color, width)
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round,
  );
}

/// `art.ring`: a ring of [color] [width] wide round a [fill] disc.
void ledgerRing(
  Canvas canvas,
  Offset at,
  Color color,
  Color fill, {
  double radius = 2.4,
  double width = 1.1,
}) {
  canvas
    ..drawCircle(at, radius, Paint()..color = fill)
    ..drawCircle(at, radius, ledgerStroke(color, width));
}

/// `art.now_mark`: today's point, a disc of [color] ringed in the [paper],
/// with its halo at 9.
void ledgerNowMark(
  Canvas canvas,
  Offset at,
  Color color,
  Color paper, {
  bool halo = true,
}) {
  if (halo) canvas.drawCircle(at, 9, ledgerStroke(ledgerInk(color, .45), .8));
  canvas
    ..drawCircle(at, 4.2, Paint()..color = color)
    ..drawCircle(at, 4.2, ledgerStroke(paper, 1.5));
}

/// A vertical dotted drop (`stroke-dasharray="1.5 2.5"`) from [from] to
/// [to].
void ledgerDrop(
  Canvas canvas,
  Offset from,
  Offset to,
  Color color, {
  double width = 1,
}) => canvas.drawPath(
  ledgerDashed(
    Path()
      ..moveTo(from.dx, from.dy)
      ..lineTo(to.dx, to.dy),
    const [1.5, 2.5],
  ),
  ledgerStroke(color, width),
);

/// `art.ruler_ticks`: a tick under the baseline [yb] for each day [from]..
/// [days], long (7, .9 wide) where the ruler's labels stand (the month's
/// start, the 8th, 15th and 22nd, [today] and the last day), else 3.5 and
/// .6. A line's day ends at [x] of it (0 the month's start); a bar chart
/// gives its bars' centres from day 1.
void ledgerRulerTicks(
  Canvas canvas,
  double Function(int day) x,
  double yb,
  int days,
  int today,
  Color ink, {
  Set<int>? long,
  int from = 0,
  double longTick = 7,
  double shortTick = 3.5,
  double longWidth = .9,
  double shortWidth = .6,
}) {
  final marks = long ?? {from, 8, 15, 22, today, days};
  for (var day = from; day <= days; day++) {
    final isLong = marks.contains(day);
    canvas.drawLine(
      Offset(x(day), yb),
      Offset(x(day), yb + (isLong ? longTick : shortTick)),
      ledgerStroke(ink, isLong ? longWidth : shortWidth),
    );
  }
}

/// The days ahead of [x0], shaded faintly (the ink at .035).
void ledgerAhead(Canvas canvas, Rect box, Color ink) =>
    canvas.drawRect(box, Paint()..color = ledgerInk(ink, .035));
