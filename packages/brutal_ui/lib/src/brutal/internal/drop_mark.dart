/// The mark that says a field opens a list: a solid triangle pointing down,
/// turned up while the list is open. The select and the combobox both end in
/// it, so the two read as one kind of field.
library;

import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart' show rawReduceMotionOf;

/// A solid triangle 12 by 8, pointing down; [open] turns it up.
class BrutalDropMark extends StatelessWidget {
  /// A mark in [color].
  const BrutalDropMark({super.key, required this.color, this.open = false});

  /// Whether the list is open.
  final bool open;

  /// Its ink.
  final Color color;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(end: open ? 0.5 : 0),
    duration: rawReduceMotionOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 140),
    builder: (context, turns, _) => Transform.rotate(
      angle: turns * 6.283185307179586,
      child: CustomPaint(
        size: const Size(12, 8),
        painter: _TrianglePainter(color),
      ),
    ),
  );
}

class _TrianglePainter extends CustomPainter {
  _TrianglePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      Path()
        ..moveTo(0, 0)
        ..lineTo(size.width / 2, size.height)
        ..lineTo(size.width, 0)
        ..close(),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(_TrianglePainter old) => old.color != color;
}
