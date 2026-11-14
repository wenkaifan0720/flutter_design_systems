import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Gives a clipping child (a scroll view) [reach] of room past every edge of
/// the line it stands in: the child is laid out [reach] larger on each side
/// than the room this is given and drawn [reach] out past this box's edges,
/// while this box stands at the child's size less that reach. The child pads
/// its content by [reach], so the content stands where it would without
/// this; what the content throws past its line (a chosen plate's lift and
/// rim, a focus ring) then falls inside the child's clip instead of being
/// cut at the line. (Not `FrostedOverhang`, which lets a control's targets
/// reach past its strip.) Plumbing of the components (a tab strip).
class FrostedBleed extends SingleChildRenderObjectWidget {
  /// Gives [child] [reach] of room past every edge.
  const FrostedBleed({required this.reach, super.child, super.key});

  /// How far past each edge the child is laid out and drawn.
  final double reach;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderBleed(reach);

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    (renderObject as _RenderBleed).reach = reach;
  }
}

class _RenderBleed extends RenderShiftedBox {
  _RenderBleed(this._reach) : super(null);

  double _reach;
  set reach(double value) {
    if (value == _reach) return;
    _reach = value;
    markNeedsLayout();
  }

  BoxConstraints _grown(BoxConstraints c) {
    final grow = 2 * _reach;
    return BoxConstraints(
      minWidth: c.minWidth + grow,
      maxWidth: c.maxWidth + grow,
      minHeight: c.minHeight + grow,
      maxHeight: c.maxHeight + grow,
    );
  }

  Size _less(BoxConstraints c, Size grown) => c.constrain(
    Size(
      math.max(0, grown.width - 2 * _reach),
      math.max(0, grown.height - 2 * _reach),
    ),
  );

  double _inner(double extent) => extent + 2 * _reach;

  double _outer(double extent) => math.max(0, extent - 2 * _reach);

  @override
  double computeMinIntrinsicWidth(double height) =>
      _outer(child?.getMinIntrinsicWidth(_inner(height)) ?? 0);

  @override
  double computeMaxIntrinsicWidth(double height) =>
      _outer(child?.getMaxIntrinsicWidth(_inner(height)) ?? 0);

  @override
  double computeMinIntrinsicHeight(double width) =>
      _outer(child?.getMinIntrinsicHeight(_inner(width)) ?? 0);

  @override
  double computeMaxIntrinsicHeight(double width) =>
      _outer(child?.getMaxIntrinsicHeight(_inner(width)) ?? 0);

  @override
  Size computeDryLayout(covariant BoxConstraints constraints) {
    final box = child;
    if (box == null) return constraints.smallest;
    return _less(constraints, box.getDryLayout(_grown(constraints)));
  }

  @override
  void performLayout() {
    final box = child;
    if (box == null) {
      size = constraints.smallest;
      return;
    }
    box.layout(_grown(constraints), parentUsesSize: true);
    (box.parentData! as BoxParentData).offset = Offset(-_reach, -_reach);
    size = _less(constraints, box.size);
  }
}
