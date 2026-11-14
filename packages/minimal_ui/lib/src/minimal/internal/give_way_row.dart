// A row of joined cells (a button group's actions, a toggle group's
// toggles) that keeps each cell at its natural width where they fit and,
// where they do not (large text, a phone's column), gives way in
// proportion to those widths, so the words ellipsize instead of the row
// overflowing. Unlike a LayoutBuilder it answers intrinsic sizes, so a
// group still sits in an IntrinsicWidth or a toolbar that measures. Not
// exported: the parts call it, pages never do.
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show setEquals;
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// [children] start to end at their natural widths, or narrower in
/// proportion when the row's width cannot hold them; the children at
/// [fixed] indices (a hairline, a gap) never give way. With [stretch] every
/// child takes the row's full height; else each is centred in it.
///
/// A [grow] child (a field between its add-ons) takes the room the others
/// leave in a bounded row, and never less than [growMin]: the others give
/// way first.
class MinimalGiveWayRow extends MultiChildRenderObjectWidget {
  /// A row of [children].
  const MinimalGiveWayRow({
    super.key,
    required super.children,
    this.fixed = const <int>{},
    this.stretch = false,
    this.grow,
    this.growMin = 0,
  });

  /// The indices of the children that keep their width.
  final Set<int> fixed;

  /// Whether every child takes the row's full height.
  final bool stretch;

  /// The index of the child that takes the row's spare width.
  final int? grow;

  /// The narrowest the [grow] child gets.
  final double growMin;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderGiveWayRow(
    fixed: fixed,
    stretch: stretch,
    grow: grow,
    growMin: growMin,
    textDirection: Directionality.of(context),
  );

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    (renderObject as _RenderGiveWayRow)
      ..fixed = fixed
      ..stretch = stretch
      ..grow = grow
      ..growMin = growMin
      ..textDirection = Directionality.of(context);
  }
}

class _GiveWayParentData extends ContainerBoxParentData<RenderBox> {}

class _RenderGiveWayRow extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _GiveWayParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _GiveWayParentData> {
  _RenderGiveWayRow({
    required this._fixed,
    required this._stretch,
    required this._grow,
    required this._growMin,
    required this._textDirection,
  });

  int? _grow;
  set grow(int? value) {
    if (value == _grow) return;
    _grow = value;
    markNeedsLayout();
  }

  double _growMin;
  set growMin(double value) {
    if (value == _growMin) return;
    _growMin = value;
    markNeedsLayout();
  }

  Set<int> _fixed;
  set fixed(Set<int> value) {
    if (setEquals(value, _fixed)) return;
    _fixed = value;
    markNeedsLayout();
  }

  bool _stretch;
  set stretch(bool value) {
    if (value == _stretch) return;
    _stretch = value;
    markNeedsLayout();
  }

  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    if (value == _textDirection) return;
    _textDirection = value;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _GiveWayParentData) {
      child.parentData = _GiveWayParentData();
    }
  }

  List<RenderBox> get _children => getChildrenAsList();

  /// Each child's width in [maxWidth]: its natural width, or that width
  /// scaled down with the others' where they do not fit; the [_grow] child
  /// takes what is left.
  List<double> _widths(double maxWidth, double height) {
    final kids = _children;
    final natural = [
      for (final child in kids) child.getMaxIntrinsicWidth(height),
    ];
    final g = _grow;
    final growing = g != null && g < kids.length && maxWidth.isFinite;
    if (growing) natural[g] = _growMin;
    final total = natural.fold(0.0, (a, b) => a + b);
    if (!maxWidth.isFinite || total <= maxWidth) {
      if (growing) natural[g] += maxWidth - total;
      return natural;
    }
    bool keeps(int i) => _fixed.contains(i) || (growing && i == g);
    var kept = 0.0;
    for (var i = 0; i < kids.length; i++) {
      if (keeps(i)) kept += natural[i];
    }
    final room = math.max(0.0, maxWidth - kept);
    final giving = total - kept;
    final scale = giving <= 0 ? 0.0 : room / giving;
    return [
      for (var i = 0; i < kids.length; i++)
        keeps(i) ? natural[i] : (natural[i] * scale).floorToDouble(),
    ];
  }

  BoxConstraints _cellConstraints(double width, BoxConstraints constraints) =>
      _stretch && constraints.maxHeight.isFinite
      ? BoxConstraints.tightFor(width: width, height: constraints.maxHeight)
      : BoxConstraints(
          minWidth: width,
          maxWidth: width,
          maxHeight: constraints.maxHeight,
        );

  Size _measure(BoxConstraints constraints, {required bool dry}) {
    final kids = _children;
    final probe = constraints.maxHeight.isFinite
        ? constraints.maxHeight
        : double.infinity;
    final widths = _widths(constraints.maxWidth, probe);
    var width = 0.0;
    var height = 0.0;
    for (var i = 0; i < kids.length; i++) {
      final box = _cellConstraints(widths[i], constraints);
      final size = dry
          ? kids[i].getDryLayout(box)
          : (kids[i]..layout(box, parentUsesSize: true)).size;
      width += size.width;
      height = math.max(height, size.height);
    }
    if (_stretch && constraints.maxHeight.isFinite) {
      height = constraints.maxHeight;
    }
    return constraints.constrain(Size(width, height));
  }

  @override
  Size computeDryLayout(covariant BoxConstraints constraints) =>
      _measure(constraints, dry: true);

  @override
  void performLayout() {
    size = _measure(constraints, dry: false);
    final rtl = _textDirection == TextDirection.rtl;
    var x = rtl ? size.width : 0.0;
    for (final child in _children) {
      final w = child.size.width;
      final y = (size.height - child.size.height) / 2;
      (child.parentData! as _GiveWayParentData).offset = Offset(
        rtl ? x - w : x,
        y,
      );
      x = rtl ? x - w : x + w;
    }
  }

  @override
  double computeMinIntrinsicWidth(double height) =>
      _children.fold(0.0, (a, c) => a + c.getMinIntrinsicWidth(height));

  @override
  double computeMaxIntrinsicWidth(double height) =>
      _children.fold(0.0, (a, c) => a + c.getMaxIntrinsicWidth(height));

  @override
  double computeMinIntrinsicHeight(double width) => _children.fold(
    0.0,
    (a, c) => math.max(a, c.getMinIntrinsicHeight(double.infinity)),
  );

  @override
  double computeMaxIntrinsicHeight(double width) => _children.fold(
    0.0,
    (a, c) => math.max(a, c.getMaxIntrinsicHeight(double.infinity)),
  );

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);

  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);
}
