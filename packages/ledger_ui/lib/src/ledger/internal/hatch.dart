import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// The source's engraved hatching (`art.hatch`): parallel strokes at
/// [angle] degrees rising to the right, [spacing] apart measured across x,
/// kept where [inside] holds within the box [x0], [y0], [x1], [y1] (walked
/// in steps of [step]; a run shorter than .6 is dropped). The same walk, so
/// a stroke starts and ends where the source's does. Plumbing of the
/// engravings.
Path ledgerHatch(
  bool Function(double x, double y) inside,
  double x0,
  double y0,
  double x1,
  double y1,
  double spacing, {
  double angle = 45,
  double step = 0.2,
}) {
  final a = angle * math.pi / 180;
  final dx = math.cos(a);
  final dy = -math.sin(a);
  final h = y1 - y0;
  final span = h / math.tan(a);
  var c = x0 - math.max(0.0, span) - spacing;
  final end = x1 - math.min(0.0, span) + spacing;
  final length = h / math.sin(a);
  final n = (length / step).floor() + 1;
  final path = Path();
  void segment(Offset from, Offset to) {
    if ((to - from).distance > 0.6) {
      path
        ..moveTo(from.dx, from.dy)
        ..lineTo(to.dx, to.dy);
    }
  }

  while (c <= end) {
    Offset? run;
    var wasIn = false;
    for (var k = 0; k <= n; k++) {
      final t = k * step;
      final x = c + dx * t;
      final y = y1 + dy * t;
      final ok = x0 <= x && x <= x1 && y0 <= y && y <= y1 && inside(x, y);
      if (ok && !wasIn) run = Offset(x, y);
      if (!ok && wasIn && run != null) {
        segment(run, Offset(c + dx * (t - step), y1 + dy * (t - step)));
        run = null;
      }
      wasIn = ok;
    }
    if (wasIn && run != null) {
      segment(run, Offset(c + dx * (n * step), y1 + dy * (n * step)));
    }
    c += spacing;
  }
  return path;
}
