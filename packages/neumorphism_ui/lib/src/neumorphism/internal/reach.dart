// A face's reach: the platform's least target round a face the density draws shorter, as Material pads its inputs
// (MaterialTapTargetSize.padded). The face keeps the density's height; the box, a press and the spoken node take the
// target's. A control that stands at its target across too is laid out on ui_core's DesignTapTarget.
import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Lays [child], the drawn face, at least [height] tall and centred in it. A press in the margin off the face, or on
/// the face where nothing answers it (its rim), lands on the face's middle line at the press's own x, at least [inset]
/// in from its sides, so it reaches what stands there (a cell, a field's line, a chip's words or its cross).
class NeumorphicReach extends SingleChildRenderObjectWidget {
  /// Gives [child] a reach [height] tall.
  const NeumorphicReach({
    super.key,
    required this.height,
    this.inset = 0,
    super.child,
  }) : assert(height >= 0 && inset >= 0);

  /// The least height of the reach: the platform's target.
  final double height;

  /// How far in from the face's sides a press there is taken: past the face's rim, onto what it holds.
  final double inset;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderReach(height, inset);

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) =>
      (renderObject as _RenderReach)
        ..height = height
        ..inset = inset;
}

class _RenderReach extends RenderShiftedBox {
  _RenderReach(this._height, this.inset) : super(null);

  double _height;
  set height(double value) {
    if (value == _height) return;
    _height = value;
    markNeedsLayout();
  }

  double inset;

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
    final child = this.child;
    if (child == null || !size.contains(position)) {
      return super.hitTest(result, position: position);
    }
    final at = (child.parentData! as BoxParentData).offset;
    final onFace = (at & child.size).contains(position);
    // A press on something on the face that answers presses is its own.
    if (onFace) {
      final probe = BoxHitTestResult();
      if (super.hitTest(probe, position: position) &&
          probe.path.any((e) => e.target is RenderPointerListener)) {
        return super.hitTest(result, position: position);
      }
    }
    final w = child.size.width;
    final side = math.min(inset, w / 2);
    final point = Offset(
      (position.dx - at.dx).clamp(side, w - side),
      child.size.height / 2,
    );
    final reached = result.addWithRawTransform(
      transform: MatrixUtils.forceToPoint(point),
      position: point,
      hitTest: (result, _) => child.hitTest(result, position: point),
    );
    return reached || (onFace && super.hitTest(result, position: position));
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

/// The root of a control that keeps its own size ([child], laid out at its target): its one spoken node, merged from
/// what it holds and outlined at the control's own box, never the room round it. Handed a whole width (a stretched
/// column), it keeps the control at its start, as a row's own box does.
class NeumorphicOwnRoot extends SingleChildRenderObjectWidget {
  /// Roots [child], a control at its own size.
  const NeumorphicOwnRoot({super.key, super.child});

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderOwnRoot(Directionality.maybeOf(context) ?? TextDirection.ltr);

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) =>
      (renderObject as _RenderOwnRoot).direction =
          Directionality.maybeOf(context) ?? TextDirection.ltr;
}

class _RenderOwnRoot extends RenderShiftedBox {
  _RenderOwnRoot(this._direction) : super(null);

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

  @override
  Rect get semanticBounds {
    final child = this.child;
    if (child == null) return Offset.zero & size;
    return (child.parentData! as BoxParentData).offset & child.size;
  }

  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);
    config
      ..isSemanticBoundary = true
      ..isMergingSemanticsOfDescendants = true;
  }
}

/// Where a control laid out at its target stands its face (DesignTapTarget's alignment): on the start keyline unless
/// set, since a control starts on the column's edge with its drawn face, never its target; a slot at a
/// row's end ([AlignmentDirectional.centerEnd]: a page head's trailing key, a stepper's last key) or inside a box
/// ([AlignmentDirectional.center]: a field's own keys) sets its own. The target grows away from the face.
class NeumorphicFacePlace extends InheritedWidget {
  /// Stands the faces under [child] by [alignment].
  const NeumorphicFacePlace({
    super.key,
    required this.alignment,
    required super.child,
  });

  /// Where a face stands in its target.
  final AlignmentDirectional alignment;

  /// The nearest place set round [context], or null.
  static AlignmentDirectional? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<NeumorphicFacePlace>()
      ?.alignment;

  /// The nearest place set round [context]; the start keyline when none is.
  static AlignmentDirectional of(BuildContext context) =>
      maybeOf(context) ?? AlignmentDirectional.centerStart;

  @override
  bool updateShouldNotify(NeumorphicFacePlace oldWidget) =>
      alignment != oldWidget.alignment;
}

/// [key], a round key that ends its row (a sheet's close key, the next month, the next page), with its face on the
/// row's end keyline.
Widget neumorphicAtEnd(Widget key) =>
    NeumorphicFacePlace(alignment: AlignmentDirectional.centerEnd, child: key);
