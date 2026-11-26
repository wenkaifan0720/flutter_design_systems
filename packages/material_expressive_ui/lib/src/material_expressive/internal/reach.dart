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
/// while its words and control stay on the column's edges; a stepper's touch
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

  /// A screen reader outlines the box itself: the reach past it is paint
  /// and, where the parent passes it on, touch, but a parent as narrow as
  /// this box (a padded page) stops taps at its edge.
  @override
  Rect? describeSemanticsClip(RenderObject? child) => Offset.zero & size;
}

/// A field's line in a taller slot: its child (one line of text) centred
/// on the slot's middle at its start edge, and a tap anywhere in the slot
/// taken by the line, at the nearest spot on it, as a tap anywhere on
/// Flutter's decorated `TextField` places the caret. The slot is [height]
/// tall, else at least [minHeight]; it fills the width it is given unless
/// [fillWidth] is false.
class ExpressiveLineReach extends SingleChildRenderObjectWidget {
  /// A slot whose taps reach [child].
  const ExpressiveLineReach({
    this.height,
    this.minHeight = 0,
    this.fillWidth = true,
    super.child,
    super.key,
  });

  /// The slot's height, or null for the child's, at least [minHeight].
  final double? height;

  /// The least height of the slot.
  final double minHeight;

  /// Whether the slot takes the whole width it is given.
  final bool fillWidth;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderLineReach(
    height,
    minHeight,
    fillWidth,
    Directionality.of(context),
  );

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    (renderObject as _RenderLineReach)
      ..height = height
      ..minHeight = minHeight
      ..fillWidth = fillWidth
      ..textDirection = Directionality.of(context);
  }
}

class _RenderLineReach extends RenderShiftedBox {
  _RenderLineReach(
    this._height,
    this._minHeight,
    this._fillWidth,
    this._textDirection,
  ) : super(null);

  double? _height;
  set height(double? value) {
    if (value == _height) return;
    _height = value;
    markNeedsLayout();
  }

  double _minHeight;
  set minHeight(double value) {
    if (value == _minHeight) return;
    _minHeight = value;
    markNeedsLayout();
  }

  bool _fillWidth;
  set fillWidth(bool value) {
    if (value == _fillWidth) return;
    _fillWidth = value;
    markNeedsLayout();
  }

  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    if (value == _textDirection) return;
    _textDirection = value;
    markNeedsLayout();
  }

  BoxConstraints _childConstraints(BoxConstraints c) {
    final height = _height;
    return BoxConstraints(
      maxWidth: c.maxWidth,
      maxHeight: height == null ? c.maxHeight : math.min(height, c.maxHeight),
    );
  }

  Size _sizeFor(BoxConstraints c, Size child) {
    final width = _fillWidth && c.hasBoundedWidth ? c.maxWidth : child.width;
    final height = _height ?? math.max(child.height, _minHeight);
    return c.constrain(Size(width, height));
  }

  @override
  double computeMinIntrinsicWidth(double height) =>
      child?.getMinIntrinsicWidth(height) ?? 0;

  @override
  double computeMaxIntrinsicWidth(double height) =>
      child?.getMaxIntrinsicWidth(height) ?? 0;

  @override
  double computeMinIntrinsicHeight(double width) =>
      _height ?? math.max(child?.getMinIntrinsicHeight(width) ?? 0, _minHeight);

  @override
  double computeMaxIntrinsicHeight(double width) =>
      _height ?? math.max(child?.getMaxIntrinsicHeight(width) ?? 0, _minHeight);

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final child = this.child;
    if (child == null) return _sizeFor(constraints, Size.zero);
    return _sizeFor(
      constraints,
      child.getDryLayout(_childConstraints(constraints)),
    );
  }

  @override
  double? computeDryBaseline(
    BoxConstraints constraints,
    TextBaseline baseline,
  ) {
    final child = this.child;
    if (child == null) return null;
    final inner = _childConstraints(constraints);
    final childSize = child.getDryLayout(inner);
    final size = _sizeFor(constraints, childSize);
    final base = child.getDryBaseline(inner, baseline);
    return base == null ? null : base + (size.height - childSize.height) / 2;
  }

  @override
  void performLayout() {
    final child = this.child;
    if (child == null) {
      size = _sizeFor(constraints, Size.zero);
      return;
    }
    child.layout(_childConstraints(constraints), parentUsesSize: true);
    size = _sizeFor(constraints, child.size);
    final dx = _textDirection == TextDirection.ltr
        ? 0.0
        : size.width - child.size.width;
    (child.parentData! as BoxParentData).offset = Offset(
      dx,
      (size.height - child.size.height) / 2,
    );
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    final child = this.child;
    if (child == null || !size.contains(position)) return false;
    final offset = (child.parentData! as BoxParentData).offset;
    final line = offset & child.size;
    bool hitAt(Offset at) => result.addWithPaintOffset(
      offset: offset,
      position: at,
      hitTest: (result, local) => child.hitTest(result, position: local),
    );
    // The tap's own spot when the line takes it there; else the line's
    // middle at the nearest point across (its words may sit shifted in the
    // line's box, centred by their capitals, so its edges may miss them).
    final hit =
        (line.contains(position) && hitAt(position)) ||
        hitAt(
          Offset(
            position.dx.clamp(line.left, math.max(line.left, line.right - 1)),
            line.center.dy,
          ),
        );
    if (hit) result.add(BoxHitTestEntry(this, position));
    return hit;
  }
}
