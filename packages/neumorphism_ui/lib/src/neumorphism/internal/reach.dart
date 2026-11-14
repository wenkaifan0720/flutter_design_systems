// A control's reach: the platform's least target round a face the density draws smaller, as Material pads its inputs
// (MaterialTapTargetSize.padded). The face keeps the density's height; the box, a press and the spoken node take the
// target's.
import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Lays [child], the drawn face, at least [height] tall and centred in it. A press in the margin off the face lands on
/// the face's middle line at the press's own x, so it reaches what stands there (a cell, a field's line).
class NeumorphicReach extends SingleChildRenderObjectWidget {
  /// Gives [child] a reach [height] tall.
  const NeumorphicReach({super.key, required this.height, super.child});

  /// The least height of the reach: the platform's target.
  final double height;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderReach(height);

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) =>
      (renderObject as _RenderReach).height = height;
}

class _RenderReach extends RenderShiftedBox {
  _RenderReach(this._height) : super(null);

  double _height;
  set height(double value) {
    if (value == _height) return;
    _height = value;
    markNeedsLayout();
  }

  @override
  double computeMinIntrinsicWidth(double height) =>
      child?.getMinIntrinsicWidth(height) ?? 0;

  @override
  double computeMaxIntrinsicWidth(double height) =>
      child?.getMaxIntrinsicWidth(height) ?? 0;

  @override
  double computeMinIntrinsicHeight(double width) =>
      math.max(child?.getMinIntrinsicHeight(width) ?? 0, _height);

  @override
  double computeMaxIntrinsicHeight(double width) =>
      math.max(child?.getMaxIntrinsicHeight(width) ?? 0, _height);

  // The face takes the width it is given and its own height.
  BoxConstraints _inner(BoxConstraints c) => c.copyWith(minHeight: 0);

  Size _sized(BoxConstraints c, Size face) =>
      c.constrain(Size(face.width, math.max(face.height, _height)));

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final child = this.child;
    if (child == null) return constraints.constrain(Size(0, _height));
    return _sized(constraints, child.getDryLayout(_inner(constraints)));
  }

  @override
  double? computeDryBaseline(
    BoxConstraints constraints,
    TextBaseline baseline,
  ) {
    final child = this.child;
    if (child == null) return null;
    final inner = _inner(constraints);
    final at = child.getDryBaseline(inner, baseline);
    if (at == null) return null;
    final face = child.getDryLayout(inner);
    return at + (_sized(constraints, face).height - face.height) / 2;
  }

  @override
  void performLayout() {
    final child = this.child;
    if (child == null) {
      size = constraints.constrain(Size(0, _height));
      return;
    }
    child.layout(_inner(constraints), parentUsesSize: true);
    size = _sized(constraints, child.size);
    (child.parentData! as BoxParentData).offset = Offset(
      (size.width - child.size.width) / 2,
      (size.height - child.size.height) / 2,
    );
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (super.hitTest(result, position: position)) return true;
    final child = this.child;
    if (child == null || !size.contains(position)) return false;
    final at = (child.parentData! as BoxParentData).offset;
    if ((at & child.size).contains(position)) return false;
    final point = Offset(
      (position.dx - at.dx).clamp(0.0, child.size.width),
      child.size.height / 2,
    );
    return result.addWithRawTransform(
      transform: MatrixUtils.forceToPoint(point),
      position: point,
      hitTest: (result, _) => child.hitTest(result, position: point),
    );
  }
}

/// A part of a face, [child], whose target reaches past it up and down: the box keeps the part's own size (it stands
/// in its face's band), and its one spoken node and its presses take [height], centred on it. A chip's cross is a
/// 48 target in a 32 band, never a key raised over the chip.
class NeumorphicTallTarget extends SingleChildRenderObjectWidget {
  /// Speaks and hit-tests [child] at least [height] tall.
  const NeumorphicTallTarget({super.key, required this.height, super.child});

  /// The least height of the target: the platform's.
  final double height;
  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderTallTarget(height);
  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) =>
      (renderObject as _RenderTallTarget).height = height;
}

class _RenderTallTarget extends RenderProxyBox {
  _RenderTallTarget(this._height);
  double _height;
  set height(double value) {
    if (value == _height) return;
    _height = value;
    markNeedsSemanticsUpdate();
  }

  Rect get _reach {
    final over = math.max(0.0, _height - size.height) / 2;
    return Rect.fromLTRB(0, -over, size.width, size.height + over);
  }

  @override
  Rect get semanticBounds => _reach;
  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);
    config
      ..isSemanticBoundary = true
      ..isMergingSemanticsOfDescendants = true;
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (!_reach.contains(position)) return false;
    // A press above or below the part lands on its middle line at the press's own x.
    final inside = (Offset.zero & size).contains(position);
    final point = inside ? position : Offset(position.dx, size.height / 2);
    final child = this.child;
    final hit =
        child != null &&
        (inside
            ? child.hitTest(result, position: point)
            : result.addWithRawTransform(
                transform: MatrixUtils.forceToPoint(point),
                position: point,
                hitTest: (result, _) => child.hitTest(result, position: point),
              ));
    if (hit) {
      result.add(BoxHitTestEntry(this, position));
      return true;
    }
    return false;
  }
}

/// The root of a control whose face stands on its box's edge ([NeumorphicFaceEdge], [child]): the control's one spoken
/// node, merged from what it holds and as wide as its target ([slop] past each side of the face), and its press reach.
/// Handed a whole width (a stretched column), it keeps the face at its start, as a row's own box does.
class NeumorphicEdgeTarget extends SingleChildRenderObjectWidget {
  /// Speaks and hit-tests [child]'s target, [slop] past each side of its face.
  const NeumorphicEdgeTarget({super.key, required this.slop, super.child});

  /// How far the target reaches past the face on each side.
  final double slop;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderEdgeTarget(
    math.max(0, slop),
    Directionality.maybeOf(context) ?? TextDirection.ltr,
  );

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) =>
      (renderObject as _RenderEdgeTarget)
        ..slop = math.max(0, slop)
        ..direction = Directionality.maybeOf(context) ?? TextDirection.ltr;
}

class _RenderEdgeTarget extends RenderShiftedBox {
  _RenderEdgeTarget(this._slop, this._direction) : super(null);

  double _slop;
  set slop(double value) {
    if (value == _slop) return;
    _slop = value;
    markNeedsLayout();
  }

  TextDirection _direction;
  set direction(TextDirection value) {
    if (value == _direction) return;
    _direction = value;
    markNeedsLayout();
  }

  Offset _at(Size box, Size child) => Offset(
    _direction == TextDirection.rtl ? box.width - child.width : 0,
    (box.height - child.height) / 2,
  );

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final child = this.child;
    if (child == null) return constraints.smallest;
    return constraints.constrain(child.getDryLayout(constraints.loosen()));
  }

  @override
  double? computeDryBaseline(
    BoxConstraints constraints,
    TextBaseline baseline,
  ) {
    final child = this.child;
    if (child == null) return null;
    final inner = constraints.loosen();
    final line = child.getDryBaseline(inner, baseline);
    if (line == null) return null;
    final size = child.getDryLayout(inner);
    return line + _at(constraints.constrain(size), size).dy;
  }

  @override
  void performLayout() {
    final child = this.child;
    if (child == null) {
      size = constraints.smallest;
      return;
    }
    child.layout(constraints.loosen(), parentUsesSize: true);
    size = constraints.constrain(child.size);
    (child.parentData! as BoxParentData).offset = _at(size, child.size);
  }

  /// The target: the face's box, [_slop] past each side, the box's height.
  Rect get _reach {
    final child = this.child;
    if (child == null) return Offset.zero & size;
    final at = (child.parentData! as BoxParentData).offset;
    return Rect.fromLTWH(
      at.dx - _slop,
      0,
      child.size.width + 2 * _slop,
      size.height,
    );
  }

  @override
  Rect get semanticBounds => _reach;

  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);
    config
      ..isSemanticBoundary = true
      ..isMergingSemanticsOfDescendants = true;
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (!size.contains(position) && !_reach.contains(position)) return false;
    if (hitTestChildren(result, position: position)) {
      result.add(BoxHitTestEntry(this, position));
      return true;
    }
    return false;
  }
}

/// Lays [child], a face centred in its target, with the target's side margins ([slop] each) outside the box: the box
/// is the face's width, so the face's first drawn pixel is the box's edge and stands on the column's keyline (design6
/// P: a minimum target pads outward and is only hit-tested, never shifting the face). The margins are still the
/// target's: hit-tested here, and spoken by the face's own node, which keeps its whole target. Up and down nothing
/// changes; a row keeps one centre.
class NeumorphicFaceEdge extends SingleChildRenderObjectWidget {
  /// Puts [child]'s face on the box's edges, [slop] of its target past each side.
  const NeumorphicFaceEdge({super.key, required this.slop, super.child});

  /// How far the target reaches past the face on each side.
  final double slop;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderFaceEdge(math.max(0, slop));

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) =>
      (renderObject as _RenderFaceEdge).slop = math.max(0, slop);
}

class _RenderFaceEdge extends RenderShiftedBox {
  _RenderFaceEdge(this._slop) : super(null);

  double _slop;
  set slop(double value) {
    if (value == _slop) return;
    _slop = value;
    markNeedsLayout();
  }

  double get _both => 2 * _slop;

  BoxConstraints _inner(BoxConstraints c) => BoxConstraints(
    minWidth: c.minWidth + _both,
    maxWidth: c.maxWidth + _both,
    minHeight: c.minHeight,
    maxHeight: c.maxHeight,
  );

  @override
  double computeMinIntrinsicWidth(double height) =>
      math.max(0, (child?.getMinIntrinsicWidth(height) ?? 0) - _both);

  @override
  double computeMaxIntrinsicWidth(double height) =>
      math.max(0, (child?.getMaxIntrinsicWidth(height) ?? 0) - _both);

  @override
  double computeMinIntrinsicHeight(double width) =>
      child?.getMinIntrinsicHeight(width + _both) ?? 0;

  @override
  double computeMaxIntrinsicHeight(double width) =>
      child?.getMaxIntrinsicHeight(width + _both) ?? 0;

  Size _sized(BoxConstraints c, Size target) =>
      c.constrain(Size(math.max(0, target.width - _both), target.height));

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final child = this.child;
    if (child == null) return constraints.smallest;
    return _sized(constraints, child.getDryLayout(_inner(constraints)));
  }

  @override
  double? computeDryBaseline(
    BoxConstraints constraints,
    TextBaseline baseline,
  ) => child?.getDryBaseline(_inner(constraints), baseline);

  @override
  void performLayout() {
    final child = this.child;
    if (child == null) {
      size = constraints.smallest;
      return;
    }
    child.layout(_inner(constraints), parentUsesSize: true);
    size = _sized(constraints, child.size);
    (child.parentData! as BoxParentData).offset = Offset(
      -_slop,
      (size.height - child.size.height) / 2,
    );
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    final reach = Rect.fromLTRB(-_slop, 0, size.width + _slop, size.height);
    if (!reach.contains(position)) return false;
    if (hitTestChildren(result, position: position)) {
      result.add(BoxHitTestEntry(this, position));
      return true;
    }
    return false;
  }
}

/// A row of keys whose outer faces stand on its ends ([NeumorphicFaceEdge] faces, a number field's): laid out as an
/// [Align] at the start, one line tall, and a press up to [slop] past either end of the row lands on that end at the
/// press's own height, so it reaches the key standing there. It speaks as its child.
class NeumorphicSideReach extends SingleChildRenderObjectWidget {
  /// Reaches [slop] past each end of [child].
  const NeumorphicSideReach({super.key, required this.slop, super.child});

  /// How far a press past either end of the row still reaches it.
  final double slop;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderSideReach(
    math.max(0, slop),
    Directionality.maybeOf(context) ?? TextDirection.ltr,
  );

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) =>
      (renderObject as _RenderSideReach)
        ..slop = math.max(0, slop)
        ..textDirection = Directionality.maybeOf(context) ?? TextDirection.ltr;
}

class _RenderSideReach extends RenderPositionedBox {
  _RenderSideReach(this.slop, TextDirection direction)
    : super(
        alignment: AlignmentDirectional.centerStart,
        heightFactor: 1,
        textDirection: direction,
      );

  double slop;

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    final child = this.child;
    if (child == null || slop == 0) {
      return super.hitTest(result, position: position);
    }
    final at = (child.parentData! as BoxParentData).offset;
    final row = at & child.size;
    if (row.contains(position) ||
        position.dy < row.top ||
        position.dy >= row.bottom ||
        position.dx < row.left - slop ||
        position.dx >= row.right + slop) {
      return super.hitTest(result, position: position);
    }
    final end = Offset(
      position.dx.clamp(row.left, row.right - .001),
      position.dy,
    );
    final hit = result.addWithPaintOffset(
      offset: at,
      position: end,
      hitTest: (result, local) => child.hitTest(result, position: local),
    );
    if (hit) result.add(BoxHitTestEntry(this, position));
    return hit;
  }
}
