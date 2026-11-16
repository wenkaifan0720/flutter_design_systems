import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Lays [child] out as it asks, but takes [top] and [bottom] less room than
/// it: the child stands over its neighbours by them, and answers a tap on
/// the whole of itself. For a link whose tap target is taller than its
/// words, so the words keep the page's rhythm and the target its height.
/// Plumbing; pages never place one.
class CivicOverhang extends SingleChildRenderObjectWidget {
  /// [child], overhanging by [top] over and [bottom] under.
  const CivicOverhang({
    super.key,
    this.top = 0,
    this.bottom = 0,
    required Widget super.child,
  }) : assert(top >= 0 && bottom >= 0);

  /// What the child stands over the room above it by.
  final double top;

  /// What the child stands over the room below it by.
  final double bottom;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderOverhang(top, bottom);

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    (renderObject as _RenderOverhang)
      ..top = top
      ..bottom = bottom;
  }
}

class _RenderOverhang extends RenderProxyBox {
  _RenderOverhang(this._top, this._bottom);

  double _top;
  set top(double value) {
    if (value == _top) return;
    _top = value;
    markNeedsLayout();
  }

  double _bottom;
  set bottom(double value) {
    if (value == _bottom) return;
    _bottom = value;
    markNeedsLayout();
  }

  Offset get _shift => Offset(0, -_top);

  @override
  void performLayout() {
    final c = child!;
    c.layout(
      BoxConstraints(
        minWidth: constraints.minWidth,
        maxWidth: constraints.maxWidth,
      ),
      parentUsesSize: true,
    );
    size = constraints.constrain(
      Size(c.size.width, math.max(0, c.size.height - _top - _bottom)),
    );
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final c = child!.getDryLayout(
      BoxConstraints(
        minWidth: constraints.minWidth,
        maxWidth: constraints.maxWidth,
      ),
    );
    return constraints.constrain(
      Size(c.width, math.max(0, c.height - _top - _bottom)),
    );
  }

  @override
  double computeMinIntrinsicHeight(double width) =>
      math.max(0, super.computeMinIntrinsicHeight(width) - _top - _bottom);

  @override
  double computeMaxIntrinsicHeight(double width) =>
      math.max(0, super.computeMaxIntrinsicHeight(width) - _top - _bottom);

  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) {
    final b = child!.getDistanceToActualBaseline(baseline);
    return b == null ? null : b - _top;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    context.paintChild(child!, offset + _shift);
  }

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) {
    transform.translateByDouble(_shift.dx, _shift.dy, 0, 1);
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    // The child's whole target answers, past this box's own edges.
    if (hitTestChildren(result, position: position)) {
      result.add(BoxHitTestEntry(this, position));
      return true;
    }
    return false;
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      result.addWithPaintOffset(
        offset: _shift,
        position: position,
        hitTest: (result, transformed) =>
            child!.hitTest(result, position: transformed),
      );
}
