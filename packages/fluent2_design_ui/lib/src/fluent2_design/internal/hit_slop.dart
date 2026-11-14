import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../theme.dart';

/// Lets a choice control's room hang outside its keyline: a checkbox, radio
/// or switch keeps Fluent's 8 of room round its indicator,
/// which holds the focus ring, and is moved back by those 8 toward the start,
/// so the indicator's ink, the label above a switch included, starts where a
/// field and a title in the same column start. Paint and hits move together;
/// the part lays out at its own size. Plumbing of the components; pages
/// never place one.
class Fluent2HangRoom extends StatelessWidget {
  /// [child] moved toward the start by Fluent's 8.
  const Fluent2HangRoom({required this.child, super.key});

  /// The control.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.maybeOf(context) == TextDirection.rtl;
    return Transform.translate(
      offset: Offset(rtl ? Fluent2Spacing.s : -Fluent2Spacing.s, 0),
      transformHitTests: true,
      child: child,
    );
  }
}

/// Takes taps over at least a [target] square centred on its child while
/// laying out at the child's own size: a 32 point button keeps its compact
/// place in a toolbar and still answers the touch target round it (48
/// where a touch reaches it, 44 elsewhere: `Fluent2Layout.hitTargetOf`),
/// whatever the theme's density. Hit testing reaches a child only through
/// its parent's bounds, so the slop reaches as far as the room round the
/// child does. Plumbing of the components; pages never place one.
class Fluent2HitSlop extends SingleChildRenderObjectWidget {
  /// Takes taps over at least a [target] square round [child].
  const Fluent2HitSlop({required super.child, this.target, super.key});

  /// The touch target's least side; null takes the platform's.
  final double? target;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderHitSlop(target ?? Fluent2Layout.hitTargetOf(context));

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    (renderObject as _RenderHitSlop).target =
        target ?? Fluent2Layout.hitTargetOf(context);
  }
}

class _RenderHitSlop extends RenderProxyBox {
  _RenderHitSlop(this._target);

  double _target;
  set target(double value) => _target = value;

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
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

/// Material's padded tap target (its `_InputPadding`), for a press where a
/// touch reaches it: the face is laid out under the constraints the press
/// was given, as if nothing stood around it, and the target grows round it
/// to [minSize] as far as those constraints let it, the face at
/// [alignment] (centred unless two parts stand joined, each face against
/// the other). A touch in the margin reaches the face's centre. Standing inside the
/// press's own semantics node, it makes that node as large as the target.
/// Plumbing of [Fluent2Layout.padded] presses; pages never place one.
class Fluent2TapTarget extends SingleChildRenderObjectWidget {
  /// Grows [child]'s target to [minSize].
  const Fluent2TapTarget({
    required this.minSize,
    required super.child,
    this.alignment = AlignmentDirectional.center,
    super.key,
  });

  /// The least size the target grows to.
  final Size minSize;

  /// Where the face stands in the target.
  final AlignmentGeometry alignment;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderTapTarget(
    minSize,
    alignment.resolve(Directionality.maybeOf(context) ?? TextDirection.ltr),
  );

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) =>
      (renderObject as _RenderTapTarget)
        ..minSize = minSize
        ..alignment = alignment.resolve(
          Directionality.maybeOf(context) ?? TextDirection.ltr,
        );
}

class _RenderTapTarget extends RenderShiftedBox {
  _RenderTapTarget(this._minSize, this._alignment) : super(null);

  Size get minSize => _minSize;
  Size _minSize;
  set minSize(Size value) {
    if (_minSize == value) return;
    _minSize = value;
    markNeedsLayout();
  }

  Alignment get alignment => _alignment;
  Alignment _alignment;
  set alignment(Alignment value) {
    if (_alignment == value) return;
    _alignment = value;
    markNeedsLayout();
  }

  @override
  double computeMinIntrinsicWidth(double height) =>
      math.max(child?.getMinIntrinsicWidth(height) ?? 0, minSize.width);

  @override
  double computeMinIntrinsicHeight(double width) =>
      math.max(child?.getMinIntrinsicHeight(width) ?? 0, minSize.height);

  @override
  double computeMaxIntrinsicWidth(double height) =>
      math.max(child?.getMaxIntrinsicWidth(height) ?? 0, minSize.width);

  @override
  double computeMaxIntrinsicHeight(double width) =>
      math.max(child?.getMaxIntrinsicHeight(width) ?? 0, minSize.height);

  Size _sized(BoxConstraints constraints, Size face) => constraints.constrain(
    Size(
      math.max(face.width, minSize.width),
      math.max(face.height, minSize.height),
    ),
  );

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final child = this.child;
    if (child == null) return Size.zero;
    return _sized(constraints, child.getDryLayout(constraints));
  }

  @override
  double? computeDryBaseline(
    BoxConstraints constraints,
    TextBaseline baseline,
  ) {
    final child = this.child;
    if (child == null) return null;
    final at = child.getDryBaseline(constraints, baseline);
    if (at == null) return null;
    final face = child.getDryLayout(constraints);
    return at +
        alignment.alongOffset(_sized(constraints, face) - face as Offset).dy;
  }

  @override
  void performLayout() {
    final child = this.child;
    if (child == null) {
      size = Size.zero;
      return;
    }
    child.layout(constraints, parentUsesSize: true);
    size = _sized(constraints, child.size);
    (child.parentData! as BoxParentData).offset = alignment.alongOffset(
      size - child.size as Offset,
    );
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (super.hitTest(result, position: position)) return true;
    final child = this.child;
    if (child == null || !size.contains(position)) return false;
    final centre = child.size.center(Offset.zero);
    return result.addWithRawTransform(
      transform: MatrixUtils.forceToPoint(centre),
      position: centre,
      hitTest: (result, position) => child.hitTest(result, position: centre),
    );
  }
}
