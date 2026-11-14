/// A box narrower than its child, the child reaching past its edges and
/// taking hits there: what stands on a keyline is the drawn thing, while
/// its touch area hangs outside it.
library;

import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Lays its child out [start] and [end] wider than itself, reaching past
/// its own edges by them (mirrored right to left), and takes hits there:
/// a flush row's highlight and touch area run into the column's margin
/// while its words and control stay on the column's edges; a stepper's 48dp
/// targets past its end circles, the circles on the row's keyline.
class ExpressiveReach extends SingleChildRenderObjectWidget {
  /// A box reaching [start] and [end] past its edges.
  const ExpressiveReach({
    required this.start,
    required this.end,
    super.child,
    super.key,
  });

  /// How far the child reaches past the start edge.
  final double start;

  /// How far the child reaches past the end edge.
  final double end;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderReach(start, end, Directionality.of(context));

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    (renderObject as _RenderReach)
      ..start = start
      ..end = end
      ..textDirection = Directionality.of(context);
  }
}

class _RenderReach extends RenderShiftedBox {
  _RenderReach(this._start, this._end, this._textDirection) : super(null);

  double _start;
  set start(double value) {
    if (value == _start) return;
    _start = value;
    markNeedsLayout();
  }

  double _end;
  set end(double value) {
    if (value == _end) return;
    _end = value;
    markNeedsLayout();
  }

  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    if (value == _textDirection) return;
    _textDirection = value;
    markNeedsLayout();
  }

  double get _left => _textDirection == TextDirection.ltr ? _start : _end;
  double get _right => _textDirection == TextDirection.ltr ? _end : _start;
  double get _extra => _start + _end;

  BoxConstraints _childConstraints(BoxConstraints constraints) =>
      constraints.hasBoundedWidth
      ? constraints.copyWith(
          minWidth: constraints.minWidth + _extra,
          maxWidth: constraints.maxWidth + _extra,
        )
      : constraints;

  @override
  double computeMinIntrinsicWidth(double height) =>
      math.max(0, (child?.getMinIntrinsicWidth(height) ?? 0) - _extra);

  @override
  double computeMaxIntrinsicWidth(double height) =>
      math.max(0, (child?.getMaxIntrinsicWidth(height) ?? 0) - _extra);

  @override
  double computeMinIntrinsicHeight(double width) =>
      child?.getMinIntrinsicHeight(width + _extra) ?? 0;

  @override
  double computeMaxIntrinsicHeight(double width) =>
      child?.getMaxIntrinsicHeight(width + _extra) ?? 0;

  @override
  Size computeDryLayout(covariant BoxConstraints constraints) {
    final size = child?.getDryLayout(_childConstraints(constraints));
    if (size == null) return constraints.smallest;
    return constraints.constrain(
      Size(math.max(0, size.width - _extra), size.height),
    );
  }

  @override
  void performLayout() {
    final child = this.child;
    if (child == null) {
      size = constraints.smallest;
      return;
    }
    child.layout(_childConstraints(constraints), parentUsesSize: true);
    size = constraints.constrain(
      Size(math.max(0, child.size.width - _extra), child.size.height),
    );
    (child.parentData! as BoxParentData).offset = Offset(-_left, 0);
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    final reach = Rect.fromLTRB(-_left, 0, size.width + _right, size.height);
    if (!reach.contains(position)) return false;
    if (hitTestChildren(result, position: position) || hitTestSelf(position)) {
      result.add(BoxHitTestEntry(this, position));
      return true;
    }
    return false;
  }
}
