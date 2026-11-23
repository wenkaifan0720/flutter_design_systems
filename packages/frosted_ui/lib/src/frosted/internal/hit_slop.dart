import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../theme.dart';

/// Lays [child] out at least a [target] square, as Material pads its
/// targets (ui_core's [TapTargetPadding]): a 32 point disc stands in a 48
/// square under a finger (44 under a pointer:
/// `FrostedBreakpoints.hitTargetOf`). Placed inside the control's node and
/// its gesture (a `FrostedPressable` places its own round its face), the
/// control's layout, the area a tap reaches and the box a screen reader
/// outlines are one, and a neighbour stands past the target rather than
/// inside it. The square is laid out: what stands round it makes room.
///
/// The face stands where the nearest [FrostedTargetSide] says, else at
/// [alignment], else centred: on a keyline (a bare check at a column's
/// start, a field's trailing key at its end) the face stays on the line
/// and the target grows away from it, mirrored right to left. Plumbing of
/// the components; pages never place one.
class FrostedHitSlop extends StatelessWidget {
  /// Creates a [FrostedHitSlop].
  const FrostedHitSlop({
    required this.child,
    this.target,
    this.alignment,
    super.key,
  });

  /// The control the target stands round.
  final Widget child;

  /// The touch target's least side; null for the platform's floor.
  final double? target;

  /// Where the face stands in the target when no [FrostedTargetSide] says;
  /// null centres it.
  final AlignmentDirectional? alignment;

  @override
  Widget build(BuildContext context) => TapTargetPadding(
    minSize: Size.square(target ?? FrostedBreakpoints.hitTargetOf(context)),
    alignment:
        FrostedTargetSide.maybeOf(context) ??
        alignment ??
        AlignmentDirectional.center,
    child: child,
  );
}

/// Where the faces of the controls under it stand in their touch targets
/// ([FrostedHitSlop]): [AlignmentDirectional.centerStart] keeps a face on
/// the start keyline and grows its target toward the end,
/// [AlignmentDirectional.centerEnd] the reverse (a field's trailing key, a
/// settings row's switch). It reaches every control under it, so it
/// stands round the one control at the keyline. Plumbing of the
/// components.
class FrostedTargetSide extends InheritedWidget {
  /// Stands the faces under [child] at [alignment].
  const FrostedTargetSide({
    required this.alignment,
    required super.child,
    super.key,
  });

  /// Where a face stands in its target.
  final AlignmentDirectional alignment;

  /// The nearest side's alignment, or null.
  static AlignmentDirectional? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<FrostedTargetSide>()?.alignment;

  @override
  bool updateShouldNotify(FrostedTargetSide oldWidget) =>
      alignment != oldWidget.alignment;
}

/// A text field's line, spread over the height of its well (the nearest
/// [FrostedFieldRoom] round it): a tap anywhere from the well's top to its
/// bottom, over the line's width, reaches the editable (at the nearest
/// point of its line, as Material's padded field takes it), and the
/// field's one node, named [label], spans the same box, so the box a
/// screen reader outlines is the box a tap reaches. The editable's words,
/// flags and actions gather in that node. Nothing lays out differently.
/// Without a room round it the line answers over its own box. Inside a
/// field that names it (ui_core's `RawInputDecorator`, [ownNode] false) the
/// line makes no node: the editable joins the field's, which spans the
/// well and carries its name, help and error. Plumbing of the components.
class FrostedFieldTarget extends SingleChildRenderObjectWidget {
  /// Creates a [FrostedFieldTarget].
  const FrostedFieldTarget({
    required Widget child,
    this.label,
    this.ownNode = true,
    super.key,
  }) : super(child: child);

  /// The field's name.
  final String? label;

  /// Whether the line makes the field's node; false where a field round it
  /// makes it.
  final bool ownNode;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderFieldLine(label, Directionality.maybeOf(context), ownNode);

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    (renderObject as _RenderFieldLine)
      ..label = label
      ..textDirection = Directionality.maybeOf(context)
      ..ownNode = ownNode;
  }
}

/// The box a text field's line spans ([FrostedFieldTarget]): the row inside
/// the field's well, from its top to its bottom. A tap in it that reaches
/// nothing else (over or under a line that stands centred in a shorter
/// cell, which hit testing would not enter) goes to the line, at its
/// middle, so no box between the room and the line need stand as tall as
/// the room. Plumbing of the components.
class FrostedFieldRoom extends SingleChildRenderObjectWidget {
  /// Creates a [FrostedFieldRoom].
  const FrostedFieldRoom({required Widget child, super.key})
    : super(child: child);

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderFieldRoom();
}

class _RenderFieldRoom extends RenderProxyBox {
  // The line in this room: the first one under it, not in a room of its own.
  _RenderFieldLine? _line() {
    _RenderFieldLine? found;
    void visit(RenderObject child) {
      if (found != null || child is _RenderFieldRoom) return;
      if (child is _RenderFieldLine) {
        found = child;
        return;
      }
      child.visitChildren(visit);
    }

    visitChildren(visit);
    return found;
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (super.hitTest(result, position: position)) return true;
    if (!size.contains(position)) return false;
    final line = _line();
    if (line == null || !line.hasSize || !line.attached) return false;
    final toLine = line.getTransformTo(this);
    if (toLine.invert() == 0) return false;
    final at = MatrixUtils.transformPoint(toLine, position);
    final onLine = Offset(
      at.dx.clamp(0.0, math.max(0.0, line.size.width - 0.5)),
      line.size.height / 2,
    );
    return result.addWithRawTransform(
      transform: toLine,
      position: position,
      hitTest: (result, _) => line.hitTest(result, position: onLine),
    );
  }
}

/// Stands [child] in a lane at least [height] tall (the touch target: 48
/// under a finger, 44 under a pointer), the child centred in it, and
/// answers a tap in the lane above or below the child as one at the child's
/// middle row, as Material redirects a padded chip's margin: a remove key
/// in a 28 tag answers over the lane's whole height, its node spanning it
/// too ([FrostedLaneKey]). The lane is laid out: what stands round it makes
/// room. Plumbing of the components (a tag, an input chip).
class FrostedTargetLane extends StatelessWidget {
  /// Stands [child] in its lane.
  const FrostedTargetLane({required this.child, this.height, super.key});

  /// What stands in the lane.
  final Widget child;

  /// The lane's least height; the platform's touch target when null.
  final double? height;

  @override
  Widget build(BuildContext context) => _Lane(
    child: ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: height ?? FrostedBreakpoints.hitTargetOf(context),
      ),
      child: Center(widthFactor: 1, heightFactor: 1, child: child),
    ),
  );
}

class _Lane extends SingleChildRenderObjectWidget {
  const _Lane({required super.child});

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderLane();
}

class _RenderLane extends RenderProxyBox {
  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (super.hitTest(result, position: position)) return true;
    if (!size.contains(position)) return false;
    return super.hitTest(
      result,
      position: Offset(position.dx, size.height / 2),
    );
  }
}

/// A key in a [FrostedTargetLane] (a tag's remove key): its node spans the
/// lane's height over the key's own width, so the box a screen reader
/// outlines is the box a tap reaches (the lane takes a tap above or below
/// the tag onto its middle row). The key's own node is gathered into it.
/// Without a lane round it the key answers over its own box. Plumbing of
/// the components.
class FrostedLaneKey extends SingleChildRenderObjectWidget {
  /// Creates a [FrostedLaneKey].
  const FrostedLaneKey({required Widget child, super.key})
    : super(child: child);

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderLaneKey();
}

class _RenderLaneKey extends RenderProxyBox {
  _RenderLane? get _lane {
    for (var node = parent; node != null; node = node.parent) {
      if (node is _RenderLane) return node;
    }
    return null;
  }

  /// The key's width from the lane's top to its bottom, in this box's units
  /// (its own box where it stands in no lane).
  Rect get _reach {
    final own = Offset.zero & size;
    final lane = _lane;
    if (lane == null || !lane.hasSize) return own;
    final toLane = getTransformTo(lane);
    if (toLane.invert() == 0) return own;
    final box = MatrixUtils.transformRect(toLane, Offset.zero & lane.size);
    return Rect.fromLTRB(
      0,
      math.min(0, box.top),
      size.width,
      math.max(size.height, box.bottom),
    );
  }

  Rect? _reported;

  @override
  Rect get semanticBounds => _reach;

  @override
  void paint(PaintingContext context, Offset offset) {
    // The lane can change height without this key laying out again: the
    // node follows it.
    final reach = _reach;
    if (_reported != reach) {
      _reported = reach;
      markNeedsSemanticsUpdate();
    }
    super.paint(context, offset);
  }

  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);
    config
      ..isSemanticBoundary = true
      ..isMergingSemanticsOfDescendants = true;
  }
}

class _RenderFieldLine extends RenderProxyBox {
  _RenderFieldLine(this._label, this._textDirection, this._ownNode);

  bool _ownNode;
  set ownNode(bool value) {
    if (value == _ownNode) return;
    _ownNode = value;
    markNeedsSemanticsUpdate();
  }

  String? _label;
  set label(String? value) {
    if (value == _label) return;
    _label = value;
    markNeedsSemanticsUpdate();
  }

  TextDirection? _textDirection;
  set textDirection(TextDirection? value) {
    if (value == _textDirection) return;
    _textDirection = value;
    markNeedsSemanticsUpdate();
  }

  _RenderFieldRoom? get _room {
    for (var node = parent; node != null; node = node.parent) {
      if (node is _RenderFieldRoom) return node;
    }
    return null;
  }

  /// The line's width from the room's top to its bottom, in this box's
  /// units (its own box where it stands in no room).
  Rect get _reach {
    final own = Offset.zero & size;
    final room = _room;
    if (room == null || !room.hasSize) return own;
    final toRoom = getTransformTo(room);
    if (toRoom.invert() == 0) return own;
    final box = MatrixUtils.transformRect(toRoom, Offset.zero & room.size);
    return Rect.fromLTRB(
      0,
      math.min(0, box.top),
      size.width,
      math.max(size.height, box.bottom),
    );
  }

  Rect? _reported;

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (!hasSize || !_reach.contains(position)) return false;
    // Brought onto the line, whose own test checks its size: over or under
    // it, onto its middle (what draws the line may stand a pixel or two off
    // its box, centred on its capitals).
    final inside = Offset(
      position.dx.clamp(0.0, math.max(0.0, size.width - 0.5)),
      position.dy >= 0 && position.dy < size.height
          ? position.dy
          : size.height / 2,
    );
    // Inside the line's box but past the editable in it (a line centred on
    // its capitals stands taller than the editable it holds): onto the
    // line's middle too.
    if (hitTestChildren(result, position: inside) ||
        (inside.dy != size.height / 2 &&
            hitTestChildren(
              result,
              position: Offset(inside.dx, size.height / 2),
            ))) {
      result.add(BoxHitTestEntry(this, position));
      return true;
    }
    return false;
  }

  @override
  Rect get semanticBounds => _reach;

  @override
  void paint(PaintingContext context, Offset offset) {
    // The room can change height without this line laying out again (a
    // trailing part coming): the node follows it.
    final reach = _reach;
    if (_reported != reach) {
      _reported = reach;
      markNeedsSemanticsUpdate();
    }
    super.paint(context, offset);
  }

  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);
    if (!_ownNode) return;
    config.isSemanticBoundary = true;
    final label = _label;
    if (label != null && label.isNotEmpty) {
      config
        ..label = label
        ..textDirection = _textDirection;
    }
  }
}

/// Its controls stand at a finger's floor on every platform
/// ([FrostedBreakpoints.touchHitTarget]), as a text entry's well does: an
/// entry (a composer) keeps one size under a finger and a pointer. Plumbing
/// of the components.
class FrostedTouchTargets extends StatelessWidget {
  /// Creates a [FrostedTouchTargets].
  const FrostedTouchTargets({required this.child, super.key});

  /// The entry.
  final Widget child;

  @override
  Widget build(BuildContext context) => DesignTapTargetScope(
    targets: (DesignTapTargets.maybeOf(context) ?? FrostedBreakpoints.targets)
        .copyWith(input: DesignInput.touch),
    child: child,
  );
}
