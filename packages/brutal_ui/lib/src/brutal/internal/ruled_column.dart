import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// A full-width column with [gap] between each two children that take room,
/// and, given a [rule] colour, that gap inked as a rule: a child that draws
/// nothing (a `SizedBox.shrink` an app leaves where a row is hidden) adds no
/// gap and no doubled rule. A list group's rows and a sheet's foot stand in
/// one.
class BrutalRuledColumn extends MultiChildRenderObjectWidget {
  /// Stacks [children] with [gap] between those that take room.
  const BrutalRuledColumn({
    super.key,
    required this.gap,
    this.rule,
    required super.children,
  });

  /// The space between two children that take room.
  final double gap;

  /// The gap's ink; null leaves it empty.
  final Color? rule;

  @override
  RenderBrutalRuledColumn createRenderObject(BuildContext context) =>
      RenderBrutalRuledColumn(gap: gap, rule: rule);

  @override
  void updateRenderObject(
    BuildContext context,
    RenderBrutalRuledColumn renderObject,
  ) {
    renderObject
      ..gap = gap
      ..rule = rule;
  }
}

/// The parent data of a [BrutalRuledColumn]'s children.
class BrutalRuledColumnParentData extends ContainerBoxParentData<RenderBox> {}

/// Lays a [BrutalRuledColumn].
class RenderBrutalRuledColumn extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, BrutalRuledColumnParentData>,
        RenderBoxContainerDefaultsMixin<
          RenderBox,
          BrutalRuledColumnParentData
        > {
  /// A column with [gap] between its children that take room.
  RenderBrutalRuledColumn({required double gap, Color? rule})
    : _space = gap,
      _ink = rule;

  double _space;
  set gap(double value) {
    if (value == _space) return;
    _space = value;
    markNeedsLayout();
  }

  Color? _ink;
  set rule(Color? value) {
    if (value == _ink) return;
    _ink = value;
    markNeedsPaint();
  }

  /// Where each rule starts, down from the top.
  final List<double> _inkAt = [];

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! BrutalRuledColumnParentData) {
      child.parentData = BrutalRuledColumnParentData();
    }
  }

  Iterable<RenderBox> get _children sync* {
    var child = firstChild;
    while (child != null) {
      yield child;
      child = childAfter(child);
    }
  }

  double _width(BoxConstraints constraints) {
    if (constraints.hasBoundedWidth) return constraints.maxWidth;
    var widest = 0.0;
    for (final child in _children) {
      widest = math.max(widest, child.getMaxIntrinsicWidth(double.infinity));
    }
    return constraints.constrainWidth(widest);
  }

  /// Stacks [heights], a gap between the ones that take room.
  double _stack(Iterable<double> heights) {
    var total = 0.0;
    var any = false;
    for (final height in heights) {
      if (height <= 0) continue;
      if (any) total += _space;
      total += height;
      any = true;
    }
    return total;
  }

  @override
  Size computeDryLayout(covariant BoxConstraints constraints) {
    final width = _width(constraints);
    final inner = BoxConstraints.tightFor(width: width);
    return constraints.constrain(
      Size(width, _stack(_children.map((c) => c.getDryLayout(inner).height))),
    );
  }

  @override
  void performLayout() {
    final width = _width(constraints);
    final inner = BoxConstraints.tightFor(width: width);
    _inkAt.clear();
    var y = 0.0;
    var any = false;
    for (final child in _children) {
      child.layout(inner, parentUsesSize: true);
      final data = child.parentData! as BrutalRuledColumnParentData;
      if (child.size.height > 0) {
        if (any) {
          _inkAt.add(y);
          y += _space;
        }
        any = true;
      }
      data.offset = Offset(0, y);
      y += child.size.height;
    }
    size = constraints.constrain(Size(width, y));
  }

  @override
  double computeMinIntrinsicWidth(double height) => _children.fold(
    0.0,
    (w, c) => math.max(w, c.getMinIntrinsicWidth(double.infinity)),
  );

  @override
  double computeMaxIntrinsicWidth(double height) => _children.fold(
    0.0,
    (w, c) => math.max(w, c.getMaxIntrinsicWidth(double.infinity)),
  );

  @override
  double computeMinIntrinsicHeight(double width) =>
      _stack(_children.map((c) => c.getMinIntrinsicHeight(width)));

  @override
  double computeMaxIntrinsicHeight(double width) =>
      _stack(_children.map((c) => c.getMaxIntrinsicHeight(width)));

  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) =>
      defaultComputeDistanceToFirstActualBaseline(baseline);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);

  @override
  void paint(PaintingContext context, Offset offset) {
    defaultPaint(context, offset);
    final rule = _ink;
    if (rule == null || _space <= 0) return;
    final paint = Paint()..color = rule;
    for (final y in _inkAt) {
      context.canvas.drawRect(
        Rect.fromLTWH(offset.dx, offset.dy + y, size.width, _space),
        paint,
      );
    }
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DoubleProperty('gap', _space))
      ..add(ColorProperty('rule', _ink, defaultValue: null));
  }
}
