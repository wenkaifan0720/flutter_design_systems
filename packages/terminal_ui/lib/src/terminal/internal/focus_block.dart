/// The keyboard's focus on a tab, a window or a rail item: the block a
/// list's row shows in its gutter, so one mark says where the keys are.
library;

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// A block half a cell wide down the start edge, in [color], growing in as
/// [amount] goes to 1.
class TermFocusBlockPainter extends CustomPainter {
  /// A block of [amount] (0 to 1) at the start of a [direction] box.
  const TermFocusBlockPainter({
    required this.amount,
    required this.color,
    required this.cellWidth,
    required this.direction,
  });

  /// How far it has grown in: 0 none, 1 half a cell.
  final double amount;

  /// Its ink.
  final Color color;

  /// The grid's cell width.
  final double cellWidth;

  /// Which edge is the start.
  final TextDirection direction;

  @override
  void paint(Canvas canvas, Size size) {
    final a = amount.clamp(0.0, 1.0);
    if (a <= 0) return;
    canvas.drawRect(
      termFocusBlock(size, a, cellWidth, direction),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(TermFocusBlockPainter old) =>
      old.amount != amount ||
      old.color != color ||
      old.cellWidth != cellWidth ||
      old.direction != direction;
}

/// Where the focus block stands in a row [size] big, [amount] grown in: half
/// a cell wide at the row's start, a quarter cell off its top and bottom, so
/// a block on the row next to a chosen one's bar stays a mark of its own
/// rather than an arm of the bar.
Rect termFocusBlock(
  Size size,
  double amount,
  double cellWidth,
  TextDirection direction,
) {
  final w = cellWidth * 0.5 * amount.clamp(0.0, 1.0);
  final inset = math.min(cellWidth / 4, size.height / 4);
  final x = direction == TextDirection.ltr ? 0.0 : size.width - w;
  return Rect.fromLTWH(x, inset, w, size.height - inset * 2);
}
