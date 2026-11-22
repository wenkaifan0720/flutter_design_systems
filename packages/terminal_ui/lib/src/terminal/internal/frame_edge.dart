/// Where a frame's line stands: the step out from a cell's middle to the
/// outer line of a double frame, and the outer edge of a raised pane's
/// doubled frame, where its ground starts and the ground of the field it
/// hangs from starts too.
library;

import 'dart:math' as math;

import '../grid.dart';
import '../primitives/box.dart';

/// The step out from a cell's middle at [centre] to the outer line of a
/// double frame whose lines stand [half] each side of the middle, in
/// [stroke]: a cell's middle is a pixel's middle across and a pixel's edge
/// down (9 by 24), so the same step out from it would leave the sides
/// astride two pixels, at half strength beside a crisp top and bottom. The
/// step is taken to the nearest that lands a line's edge on a pixel's.
double termFrameStep(double centre, double half, double stroke) {
  if (half < 0.01) return 0;
  final off = (centre - stroke / 2) % 1;
  return math.max(0, (half - off).roundToDouble() + off);
}

/// How far in from its box's sides a raised pane's doubled frame, in
/// [stroke] on [grid], has its outer edge.
double termRaisedEdge(TermGrid grid, double stroke) {
  final middle = grid.cellWidth / 2;
  final step = termFrameStep(middle, termDoubleGap(grid, stroke) / 2, stroke);
  return math.max(0, middle - step - stroke / 2);
}
