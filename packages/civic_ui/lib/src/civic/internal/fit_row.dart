import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Lays [children] side by side, each as wide as the widest needs ([equal])
/// or as its words, with [spacing] between, while that fits the width;
/// where it does not (a phone, large text, long words), stacks them, each
/// the whole width. So a row of choices never clips or squeezes a word.
class CivicFitRow extends MultiChildRenderObjectWidget {
  /// A row that stacks when it does not fit.
  const CivicFitRow({
    super.key,
    super.children,
    this.spacing = 0,
    this.equal = true,
    this.stretch = false,
  });

  /// Space between the children, along the row or down the stack.
  final double spacing;

  /// Whether the children share the row's width equally (a segmented
  /// control) or keep their own (a toolbar's toggles).
  final bool equal;

  /// Whether the row fills the width it is given even when it needs less.
  final bool stretch;

  @override
  RenderCivicFitRow createRenderObject(BuildContext context) =>
      RenderCivicFitRow(spacing, equal, stretch, Directionality.of(context));

  @override
  void updateRenderObject(
    BuildContext context,
    RenderCivicFitRow renderObject,
  ) => renderObject
    ..spacing = spacing
    ..equal = equal
    ..stretch = stretch
    ..direction = Directionality.of(context);
}

/// The parent data of a [RenderCivicFitRow]'s children.
class CivicFitRowParentData extends ContainerBoxParentData<RenderBox> {}

/// The render object of [CivicFitRow].
class RenderCivicFitRow extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, CivicFitRowParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, CivicFitRowParentData> {
  /// Lays out a fit row.
  RenderCivicFitRow(this._spacing, this._equal, this._stretch, this._direction);

  double _spacing;
  set spacing(double v) {
    if (v == _spacing) return;
    _spacing = v;
    markNeedsLayout();
  }

  bool _equal;
  set equal(bool v) {
    if (v == _equal) return;
    _equal = v;
    markNeedsLayout();
  }

  bool _stretch;
  set stretch(bool v) {
    if (v == _stretch) return;
    _stretch = v;
    markNeedsLayout();
  }

  TextDirection _direction;
  set direction(TextDirection v) {
    if (v == _direction) return;
    _direction = v;
    markNeedsLayout();
  }

  /// Whether the last layout stacked the children.
  bool get stacked => _stacked;
  bool _stacked = false;

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! CivicFitRowParentData) {
      child.parentData = CivicFitRowParentData();
    }
  }

  List<RenderBox> get _children {
    final out = <RenderBox>[];
    var child = firstChild;
    while (child != null) {
      out.add(child);
      child = childAfter(child);
    }
    return out;
  }

  // The width each child needs in a row: its words whole.
  List<double> _needs(double height) => [
    for (final c in _children) c.getMaxIntrinsicWidth(height),
  ];

  double _rowNeed(List<double> needs) {
    if (needs.isEmpty) return 0;
    final gaps = _spacing * (needs.length - 1);
    return _equal
        ? needs.reduce(math.max) * needs.length + gaps
        : needs.fold<double>(0, (a, b) => a + b) + gaps;
  }

  @override
  double computeMinIntrinsicWidth(double height) => _children.fold<double>(
    0,
    (a, c) => math.max(a, c.getMinIntrinsicWidth(height)),
  );

  @override
  double computeMaxIntrinsicWidth(double height) => _rowNeed(_needs(height));

  @override
  double computeMinIntrinsicHeight(double width) =>
      _heightFor(width, (c, w) => c.getMinIntrinsicHeight(w));

  @override
  double computeMaxIntrinsicHeight(double width) =>
      _heightFor(width, (c, w) => c.getMaxIntrinsicHeight(w));

  double _heightFor(double width, double Function(RenderBox, double) h) {
    final kids = _children;
    if (kids.isEmpty) return 0;
    final needs = _needs(double.infinity);
    if (_rowNeed(needs) <= width) {
      return kids.fold<double>(0, (a, c) => math.max(a, h(c, double.infinity)));
    }
    return kids.fold<double>(0, (a, c) => a + h(c, width)) +
        _spacing * (kids.length - 1);
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) =>
      _layout(constraints, dry: true);

  @override
  void performLayout() => size = _layout(constraints, dry: false);

  Size _layout(BoxConstraints constraints, {required bool dry}) {
    final kids = _children;
    if (kids.isEmpty) return constraints.smallest;
    final needs = _needs(double.infinity);
    final need = _rowNeed(needs);
    final maxW = constraints.maxWidth;
    final fits = need <= maxW;
    if (!dry) _stacked = !fits;
    if (fits) {
      final width = _stretch && maxW.isFinite ? maxW : need;
      final gaps = _spacing * (kids.length - 1);
      final widths = _equal
          ? List.filled(kids.length, (width - gaps) / kids.length)
          : [for (final n in needs) n + (width - need) / kids.length];
      var height = 0.0;
      final sizes = <Size>[];
      for (var i = 0; i < kids.length; i++) {
        final c = BoxConstraints(
          minWidth: widths[i],
          maxWidth: widths[i],
          maxHeight: constraints.maxHeight,
        );
        final s = dry
            ? kids[i].getDryLayout(c)
            : (kids[i]..layout(c, parentUsesSize: true)).size;
        sizes.add(s);
        height = math.max(height, s.height);
      }
      final box = constraints.constrain(Size(width, height));
      if (!dry) {
        // Every child stands as tall as the tallest, so faces line up.
        for (var i = 0; i < kids.length; i++) {
          if (sizes[i].height < height) {
            kids[i].layout(
              BoxConstraints.tightFor(width: widths[i], height: height),
              parentUsesSize: true,
            );
          }
        }
        var x = 0.0;
        for (var i = 0; i < kids.length; i++) {
          final w = widths[i];
          // Right to left, the row starts at the box's right edge, however
          // much wider than the row the box is held.
          final dx = _direction == TextDirection.rtl ? box.width - x - w : x;
          (kids[i].parentData! as CivicFitRowParentData).offset = Offset(dx, 0);
          x += w + _spacing;
        }
      }
      return box;
    }
    final width = maxW.isFinite ? maxW : need;
    var y = 0.0;
    for (final kid in kids) {
      final c = BoxConstraints.tightFor(width: width);
      final s = dry
          ? kid.getDryLayout(c)
          : (kid..layout(c, parentUsesSize: true)).size;
      if (!dry) {
        (kid.parentData! as CivicFitRowParentData).offset = Offset(0, y);
      }
      y += s.height + _spacing;
    }
    return constraints.constrain(Size(width, y - _spacing));
  }

  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);
}
