import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Gives a clipping child (a scroll view) [reach] of room past the top and
/// bottom of the line it stands in, and [across] (else [reach]) past its
/// start and end: the child is laid out that much larger on each side than
/// the room this is given and drawn that far out past this box's edges,
/// while this box stands at the child's size less that reach. The child pads
/// its content by the same, so the content stands where it would without
/// this; what the content throws past its line (a chosen plate's lift and
/// rim, a focus ring) then falls inside the child's clip instead of being
/// cut at the line, and a strip given the page's gutter as [across] runs on
/// to the screen's edges, clipping there.
///
/// Hit testing stops at a box's edge, so a part scrolled out past this box
/// takes a tap only through the nearest [FrostedBleedRoom] round it (every
/// `FrostedScaffold` page is one): what is drawn there is tappable there.
/// Plumbing of the components (a tab strip, the chip strip).
class FrostedBleed extends SingleChildRenderObjectWidget {
  /// Gives [child] [reach] of room past every edge, or [across] past its
  /// start and end.
  const FrostedBleed({
    required this.reach,
    this.across,
    super.child,
    super.key,
  });

  /// How far past the top and bottom (and, without [across], the start and
  /// end) the child is laid out and drawn.
  final double reach;

  /// How far past the start and end the child is laid out and drawn; null
  /// is [reach].
  final double? across;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderBleed(reach, across ?? reach);

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    (renderObject as _RenderBleed)
      ..reach = reach
      ..across = across ?? reach;
  }
}

class _RenderBleed extends RenderShiftedBox {
  _RenderBleed(this._reach, this._across) : super(null);

  double _reach;
  set reach(double value) {
    if (value == _reach) return;
    _reach = value;
    markNeedsLayout();
  }

  double _across;
  set across(double value) {
    if (value == _across) return;
    _across = value;
    markNeedsLayout();
  }

  _RenderBleedRoom? _room;

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    for (var node = parent; node != null; node = node.parent) {
      if (node is _RenderBleedRoom) {
        _room = node.._bleeds.add(this);
        break;
      }
    }
  }

  @override
  void detach() {
    _room?._bleeds.remove(this);
    _room = null;
    super.detach();
  }

  /// What the child spans, in this box's units: this box and the reach
  /// round it.
  Rect get _drawn => Rect.fromLTRB(
    -_across,
    -_reach,
    size.width + _across,
    size.height + _reach,
  );

  /// Hit tests the child at [position], in this box's units, past this
  /// box's own edges too (the room round it asks only there).
  bool _hitTestReach(BoxHitTestResult result, Offset position) {
    final box = child;
    if (box == null || !hasSize || !_drawn.contains(position)) return false;
    return result.addWithPaintOffset(
      offset: (box.parentData! as BoxParentData).offset,
      position: position,
      hitTest: (result, at) => box.hitTest(result, position: at),
    );
  }

  BoxConstraints _grown(BoxConstraints c) => BoxConstraints(
    minWidth: c.minWidth + 2 * _across,
    maxWidth: c.maxWidth + 2 * _across,
    minHeight: c.minHeight + 2 * _reach,
    maxHeight: c.maxHeight + 2 * _reach,
  );

  Size _less(BoxConstraints c, Size grown) => c.constrain(
    Size(
      math.max(0, grown.width - 2 * _across),
      math.max(0, grown.height - 2 * _reach),
    ),
  );

  @override
  double computeMinIntrinsicWidth(double height) => math.max(
    0,
    (child?.getMinIntrinsicWidth(height + 2 * _reach) ?? 0) - 2 * _across,
  );

  @override
  double computeMaxIntrinsicWidth(double height) => math.max(
    0,
    (child?.getMaxIntrinsicWidth(height + 2 * _reach) ?? 0) - 2 * _across,
  );

  @override
  double computeMinIntrinsicHeight(double width) => math.max(
    0,
    (child?.getMinIntrinsicHeight(width + 2 * _across) ?? 0) - 2 * _reach,
  );

  @override
  double computeMaxIntrinsicHeight(double width) => math.max(
    0,
    (child?.getMaxIntrinsicHeight(width + 2 * _across) ?? 0) - 2 * _reach,
  );

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
    (box.parentData! as BoxParentData).offset = Offset(-_across, -_reach);
    size = _less(constraints, box.size);
  }
}

/// The box a page's strips run on past their lines in (the page with its
/// gutters): a tap in it that reaches nothing else, over a part of a
/// [FrostedBleed]'s child drawn past its line (a chip scrolled out under the
/// gutter), goes to that part, so what is drawn there takes a tap there, as
/// a strip spanning the screen edge to edge would. Plumbing of the
/// components (`FrostedScaffold`).
class FrostedBleedRoom extends SingleChildRenderObjectWidget {
  /// Creates a [FrostedBleedRoom].
  const FrostedBleedRoom({required Widget child, super.key})
    : super(child: child);

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderBleedRoom();
}

class _RenderBleedRoom extends RenderProxyBox {
  final Set<_RenderBleed> _bleeds = {};

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    if (super.hitTestChildren(result, position: position)) return true;
    for (final bleed in _bleeds) {
      if (!bleed.attached || !bleed.hasSize) continue;
      final toBleed = bleed.getTransformTo(this);
      if (toBleed.invert() == 0) continue;
      final at = MatrixUtils.transformPoint(toBleed, position);
      if ((Offset.zero & bleed.size).contains(at)) continue;
      if (result.addWithRawTransform(
        transform: toBleed,
        position: position,
        hitTest: (result, at) => bleed._hitTestReach(result, at),
      )) {
        return true;
      }
    }
    return false;
  }
}
