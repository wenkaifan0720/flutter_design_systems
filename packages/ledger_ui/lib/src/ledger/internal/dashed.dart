import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// A dashed outline 1 wide inside a rounded box, as Chrome draws CSS's
/// `border: 1px dashed` in the captures: dashes of 3 about 2 apart round
/// the corners, the gap fitted so the dashes go evenly round. A ghost
/// tile's, a new goal's and a preview's edge. Plumbing of the components.
class LedgerDashedOutline extends CustomPainter {
  /// A dashed outline with corners of [radius], in [color].
  const LedgerDashedOutline({
    required this.radius,
    required this.color,
    this.dash = 3,
    this.gap = 2,
  });

  /// The box's corners.
  final BorderRadius radius;

  /// The dashes' colour.
  final Color color;

  /// Each dash's length.
  final double dash;

  /// The gap between dashes, before it is fitted.
  final double gap;

  @override
  void paint(Canvas canvas, Size size) {
    final box = radius.toRRect(Offset.zero & size).deflate(0.5);
    final path = Path()..addRRect(box);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = color;
    for (final metric in path.computeMetrics()) {
      // As many dashes as leave the gap nearest [gap], spaced evenly.
      final n = math.max(1, (metric.length / (dash + gap)).round());
      final step = metric.length / n;
      for (var i = 0; i < n; i++) {
        canvas.drawPath(metric.extractPath(i * step, i * step + dash), paint);
      }
    }
  }

  @override
  bool shouldRepaint(LedgerDashedOutline old) =>
      old.radius != radius || old.color != color;
}
