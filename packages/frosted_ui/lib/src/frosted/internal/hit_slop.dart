import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../theme.dart';

/// Takes taps over at least a [target] square centred on its child while
/// laying out at the child's own size: a 32 point disc keeps the place the
/// source gives it in a band and still answers the touch target round it
/// (48 under a finger, 44 under a pointer: `FrostedBreakpoints.hitTargetOf`).
///
/// Where the child marks its face with a [FrostedSlopFace] (a
/// `FrostedPressable` marks its own), the control itself spans the target,
/// as Material pads its targets: its node, the box a screen reader outlines
/// and Flutter's tap-target guidelines measure, is the whole square, with
/// the face drawn at its own size in the middle. The slop still lays out at
/// the face's size, so nothing round it moves; the square overhangs it.
/// Without a marked face only the hit test reaches round it.
///
/// Hit testing reaches a child only through its parent's bounds, so the
/// slop reaches as far as the room round the child does. Plumbing of the
/// components; pages never place one.
class FrostedHitSlop extends StatefulWidget {
  /// Creates a [FrostedHitSlop].
  const FrostedHitSlop({required this.child, this.target, super.key});

  /// The control the target stands round.
  final Widget child;

  /// The touch target's least side; null for the platform's floor.
  final double? target;

  @override
  State<FrostedHitSlop> createState() => _FrostedHitSlopState();
}

class _FrostedHitSlopState extends State<FrostedHitSlop> {
  final _SlopLink _link = _SlopLink();

  @override
  Widget build(BuildContext context) => _SlopScope(
    link: _link,
    child: _SlopBox(
      link: _link,
      target: widget.target ?? FrostedBreakpoints.hitTargetOf(context),
      child: widget.child,
    ),
  );
}

/// The face of the control a [FrostedHitSlop] stands round: under a slop,
/// the box that spans the target with [child] centred in it at the size the
/// slop's own room gives it; anywhere else, [child] as it is. A face inside
/// it marks nothing more.
class FrostedSlopFace extends StatelessWidget {
  /// Creates a [FrostedSlopFace].
  const FrostedSlopFace({required this.child, super.key});

  /// The face as drawn.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final link = context.dependOnInheritedWidgetOfExactType<_SlopScope>()?.link;
    if (link == null) return child;
    return _SlopFaceBox(
      link: link,
      child: _SlopScope(link: null, child: child),
    );
  }
}

/// A text field's one node, named [label], spread over the touch target
/// round [child] (the field's line): the editable's words, flags and
/// actions gather in a node as tall as the target, centred on the line, as
/// Material's padded field gives one. Nothing round it moves. Plumbing of
/// the components.
class FrostedFieldTarget extends StatelessWidget {
  /// Creates a [FrostedFieldTarget].
  const FrostedFieldTarget({required this.child, this.label, super.key});

  /// The field's line, its editable inside.
  final Widget child;

  /// The field's name.
  final String? label;

  @override
  Widget build(BuildContext context) => FrostedHitSlop(
    child: Semantics(
      container: true,
      label: label,
      child: FrostedSlopFace(child: child),
    ),
  );
}

/// What a slop and the face it stands round tell each other in layout.
class _SlopLink {
  _RenderSlopBox? slop;
  _RenderSlopFace? _face;

  /// The slop's own constraints, which the face lays out under.
  BoxConstraints? faceConstraints;

  /// The target's least side.
  double target = 0;

  _RenderSlopFace? get face => _face;
  set face(_RenderSlopFace? value) {
    if (identical(_face, value)) return;
    _face = value;
    // A face built during layout (under a LayoutBuilder) finds its slop laid
    // out already or about to be; anywhere else the slop lays out again.
    final box = slop;
    if (box != null && box.attached && !box.owner!.debugDoingLayout) {
      box.markNeedsLayout();
    }
  }
}

class _SlopScope extends InheritedWidget {
  const _SlopScope({required this.link, required super.child});

  final _SlopLink? link;

  @override
  bool updateShouldNotify(_SlopScope oldWidget) => oldWidget.link != link;
}

class _SlopBox extends SingleChildRenderObjectWidget {
  const _SlopBox({required this.link, required this.target, super.child});

  final _SlopLink link;
  final double target;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderSlopBox(link, target);

  @override
  void updateRenderObject(BuildContext context, _RenderSlopBox renderObject) {
    renderObject.target = target;
  }
}

class _RenderSlopBox extends RenderShiftedBox {
  _RenderSlopBox(this._link, this._target) : super(null) {
    _link.slop = this;
  }

  final _SlopLink _link;

  double _target;
  set target(double value) {
    if (value == _target) return;
    _target = value;
    markNeedsLayout();
  }

  /// The marked face, while it is in this slop's tree.
  _RenderSlopFace? get _face {
    final face = _link.face;
    return face != null && face.attached ? face : null;
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final face = _face?.child;
    final measured = face ?? child;
    if (measured == null) return constraints.smallest;
    return constraints.constrain(measured.getDryLayout(constraints));
  }

  @override
  void performLayout() {
    final child = this.child;
    if (child == null) {
      size = constraints.smallest;
      return;
    }
    final data = child.parentData! as BoxParentData;
    final face = _face;
    if (face == null) {
      _link.faceConstraints = null;
      child.layout(constraints, parentUsesSize: true);
      size = constraints.constrain(child.size);
      data.offset = Offset.zero;
      return;
    }
    // The control may grow to the target round its face (never tight, so a
    // face that changes size still lays the slop out again).
    _link
      ..faceConstraints = constraints
      ..target = _target;
    child.layout(
      BoxConstraints(
        minWidth: constraints.minWidth,
        minHeight: constraints.minHeight,
        maxWidth: math.max(constraints.maxWidth, _target),
        maxHeight: math.max(constraints.maxHeight, _target),
      ),
      parentUsesSize: true,
    );
    size = constraints.constrain(face.faceSize);
    // The face stands where it would without the target round it.
    final at = MatrixUtils.transformPoint(
      face.child!.getTransformTo(child),
      Offset.zero,
    );
    data.offset = -at;
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    final child = this.child;
    if (child == null) return false;
    if (!size.contains(position) && _onNeighbour(this, position)) return false;
    if (_face != null) {
      final data = child.parentData! as BoxParentData;
      if (!(data.offset & child.size).contains(position)) return false;
      if (hitTestChildren(result, position: position)) {
        result.add(BoxHitTestEntry(this, position));
        return true;
      }
      return false;
    }
    final dx = math.max(0.0, (_target - size.width) / 2);
    final dy = math.max(0.0, (_target - size.height) / 2);
    final reach = Rect.fromLTRB(-dx, -dy, size.width + dx, size.height + dy);
    if (!reach.contains(position)) return false;
    // Brought inside the child, whose own test checks its size.
    final inside = Offset(
      position.dx.clamp(0.0, math.max(0.0, size.width - 0.5)),
      position.dy.clamp(0.0, math.max(0.0, size.height - 0.5)),
    );
    if (hitTestChildren(result, position: inside)) {
      result.add(BoxHitTestEntry(this, position));
      return true;
    }
    return false;
  }
}

/// Whether [position], in the reach round [box], lies on a neighbour in the
/// same run: a stack of small controls laid edge to edge, where a press on
/// one must never go to the next.
bool _onNeighbour(RenderBox box, Offset position) {
  final own = box.parentData;
  if (own is! ContainerBoxParentData<RenderBox>) return false;
  final at = own.offset + position;
  for (final other in [own.previousSibling, own.nextSibling]) {
    if (other == null || !other.hasSize) continue;
    final data = other.parentData! as BoxParentData;
    if ((data.offset & other.size).contains(at)) return true;
  }
  return false;
}

/// Stands at [height], the strip a control draws, while [child], the
/// control with its targets, lays out as tall as it asks and stands centred
/// on it: the targets (48 under a finger) overhang the strip above and
/// below, and nothing round it moves. Material pads a small control's
/// targets the same way but grows the layout. A press in the overhang
/// reaches the child unless a neighbour in the same run lies there, and
/// only as far as the room round it does. Plumbing of the components (a
/// toggle strip, a menu bar, a split button); pages never place one.
class FrostedOverhang extends SingleChildRenderObjectWidget {
  /// Creates a [FrostedOverhang].
  const FrostedOverhang({
    required this.height,
    required super.child,
    super.key,
  });

  /// The height the strip is drawn at and lays out at.
  final double height;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderOverhang(height);

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    (renderObject as _RenderOverhang).height = height;
  }
}

class _RenderOverhang extends RenderShiftedBox {
  _RenderOverhang(this._height) : super(null);

  double _height;
  set height(double value) {
    if (value == _height) return;
    _height = value;
    markNeedsLayout();
  }

  BoxConstraints _inner(BoxConstraints c) =>
      BoxConstraints(minWidth: c.minWidth, maxWidth: c.maxWidth);

  @override
  double computeMinIntrinsicHeight(double width) => _height;

  @override
  double computeMaxIntrinsicHeight(double width) => _height;

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final child = this.child;
    final width = child == null
        ? 0.0
        : child.getDryLayout(_inner(constraints)).width;
    return constraints.constrain(Size(width, _height));
  }

  @override
  void performLayout() {
    final child = this.child;
    if (child == null) {
      size = constraints.constrain(Size(0, _height));
      return;
    }
    child.layout(_inner(constraints), parentUsesSize: true);
    size = constraints.constrain(Size(child.size.width, _height));
    (child.parentData! as BoxParentData).offset = Alignment.center.alongOffset(
      size - child.size as Offset,
    );
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    final child = this.child;
    if (child == null) return false;
    final data = child.parentData! as BoxParentData;
    if (!(data.offset & child.size).contains(position)) return false;
    if (!size.contains(position) && _onNeighbour(this, position)) return false;
    if (hitTestChildren(result, position: position)) {
      result.add(BoxHitTestEntry(this, position));
      return true;
    }
    return false;
  }
}

class _SlopFaceBox extends SingleChildRenderObjectWidget {
  const _SlopFaceBox({required this.link, super.child});

  final _SlopLink link;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderSlopFace(link);

  @override
  void updateRenderObject(BuildContext context, _RenderSlopFace renderObject) {
    renderObject.link = link;
  }
}

class _RenderSlopFace extends RenderShiftedBox {
  _RenderSlopFace(this._link) : super(null);

  _SlopLink _link;
  set link(_SlopLink value) {
    if (identical(value, _link)) return;
    if (attached && identical(_link.face, this)) _link.face = null;
    _link = value;
    if (attached) _link.face = this;
    markNeedsLayout();
  }

  /// The face's own size, as its slop lays out at.
  Size faceSize = Size.zero;

  bool get _reaching =>
      identical(_link.face, this) && _link.faceConstraints != null;

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _link.face = this;
  }

  @override
  void detach() {
    if (identical(_link.face, this)) _link.face = null;
    super.detach();
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final child = this.child;
    if (child == null) return constraints.smallest;
    final face = child.getDryLayout(_link.faceConstraints ?? constraints);
    if (!_reaching) return constraints.constrain(face);
    return constraints.constrain(_reach(face));
  }

  Size _reach(Size face) => Size(
    math.max(face.width, _link.target),
    math.max(face.height, _link.target),
  );

  @override
  void performLayout() {
    final child = this.child;
    if (child == null) {
      size = constraints.smallest;
      faceSize = Size.copy(size);
      return;
    }
    final data = child.parentData! as BoxParentData;
    if (!_reaching) {
      child.layout(constraints, parentUsesSize: true);
      size = constraints.constrain(child.size);
      faceSize = Size.copy(size);
      data.offset = Offset.zero;
      return;
    }
    child.layout(_link.faceConstraints!, parentUsesSize: true);
    // A copy: the slop two boxes up lays out at it, and a child's own size
    // is its parent's alone to hold (the debug check says so). Any change of
    // it reaches the slop through the unbroken parentUsesSize chain between.
    faceSize = Size.copy(child.size);
    size = constraints.constrain(_reach(faceSize));
    data.offset = Alignment.center.alongOffset(size - faceSize as Offset);
  }

  // The whole square answers, the room round the face too.
  @override
  bool hitTestSelf(Offset position) => _reaching;
}
