import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// A small control of a fixed size (a switch, a check) that keeps that size
/// whatever its parent asks: in a column that stretches its children (a
/// sheet's, a form's) it stands at its own size at the line's start and
/// centred across, rather than drawn out to the column's width. Under loose
/// constraints it is [child] as it is. A press goes straight to [child],
/// whose touch target may reach past its face. With [maxWidth] a control
/// that takes all the width it is given (a wide button) takes at most that,
/// standing at [along] in what it is given: -1 its start, 0 its middle, 1
/// its end. Plumbing of the components.
class FrostedOwnSize extends SingleChildRenderObjectWidget {
  /// Creates a [FrostedOwnSize].
  const FrostedOwnSize({
    required super.child,
    this.maxWidth = double.infinity,
    this.along = -1,
    super.key,
  });

  /// The widest [child] is laid out.
  final double maxWidth;

  /// Where [child] stands across what it is given, from -1 (its start) to 1.
  final double along;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderOwnSize(
    Directionality.maybeOf(context) ?? TextDirection.ltr,
    maxWidth,
    along,
  );

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    (renderObject as _RenderOwnSize)
      ..direction = Directionality.maybeOf(context) ?? TextDirection.ltr
      ..maxWidth = maxWidth
      ..along = along;
  }
}

class _RenderOwnSize extends RenderShiftedBox {
  _RenderOwnSize(this._direction, this._maxWidth, this._along) : super(null);

  TextDirection _direction;
  set direction(TextDirection value) {
    if (value == _direction) return;
    _direction = value;
    markNeedsLayout();
  }

  double _maxWidth;
  set maxWidth(double value) {
    if (value == _maxWidth) return;
    _maxWidth = value;
    markNeedsLayout();
  }

  double _along;
  set along(double value) {
    if (value == _along) return;
    _along = value;
    markNeedsLayout();
  }

  BoxConstraints _inner(BoxConstraints c) {
    final loose = c.loosen();
    return loose.maxWidth <= _maxWidth
        ? loose
        : loose.copyWith(maxWidth: _maxWidth);
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final child = this.child;
    if (child == null) return constraints.smallest;
    return constraints.constrain(child.getDryLayout(_inner(constraints)));
  }

  @override
  void performLayout() {
    final child = this.child;
    if (child == null) {
      size = constraints.smallest;
      return;
    }
    child.layout(_inner(constraints), parentUsesSize: true);
    size = constraints.constrain(child.size);
    final dx = size.width - child.size.width;
    final dy = size.height - child.size.height;
    final start = (1 + _along) / 2;
    (child.parentData! as BoxParentData).offset = Offset(
      dx * (_direction == TextDirection.rtl ? 1 - start : start),
      dy / 2,
    );
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    // The child's own test decides: its target may reach past this box,
    // but never onto a neighbour in the same run.
    if (!size.contains(position) && _onNeighbour(position)) return false;
    if (hitTestChildren(result, position: position)) {
      result.add(BoxHitTestEntry(this, position));
      return true;
    }
    return false;
  }

  bool _onNeighbour(Offset position) {
    final own = parentData;
    if (own is! ContainerBoxParentData<RenderBox>) return false;
    final at = own.offset + position;
    for (final other in [own.previousSibling, own.nextSibling]) {
      if (other == null || !other.hasSize) continue;
      final data = other.parentData! as BoxParentData;
      if ((data.offset & other.size).contains(at)) return true;
    }
    return false;
  }
}
