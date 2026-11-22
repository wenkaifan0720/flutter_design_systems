/// The mark of a floating list's keyboard row.
library;

import 'package:flutter/widgets.dart';

import '../theme.dart';

/// Marks the keyboard's row of a floating list (a menu's, a select's, a
/// combobox's) with a rule round it, inside its edges, in [color]. A cell
/// between shared rules takes a bar along its foot; a list's rows share no
/// rules, and that bar on its last row reads as the panel's own rule doubled.
class BrutalKeyedRowPainter extends CustomPainter {
  /// A rule round the row in [color].
  BrutalKeyedRowPainter(this.color);

  /// The colour of the rule.
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final box = (Offset.zero & size).deflate(BrutalMetrics.focusGap);
    if (box.isEmpty) return;
    final w = BrutalMetrics.focusWidth.clamp(0.0, box.shortestSide / 2);
    final paint = Paint()..color = color;
    canvas
      ..drawRect(
        Rect.fromLTRB(box.left, box.top, box.right, box.top + w),
        paint,
      )
      ..drawRect(
        Rect.fromLTRB(box.left, box.bottom - w, box.right, box.bottom),
        paint,
      )
      ..drawRect(
        Rect.fromLTRB(box.left, box.top + w, box.left + w, box.bottom - w),
        paint,
      )
      ..drawRect(
        Rect.fromLTRB(box.right - w, box.top + w, box.right, box.bottom - w),
        paint,
      );
  }

  @override
  bool shouldRepaint(BrutalKeyedRowPainter old) => old.color != color;
}
