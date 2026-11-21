// A dialog's or a sheet's keys: side by side at the end while they fit, as an OverflowBar lays them. When they don't
// (long words on a phone, the reader's large text), stacked, each as wide as the slab, the main key (the last) on top:
// never a staircase of keys at their own widths.
import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// A slab's keys, 12 apart side by side and 8 apart stacked.
/// Internal: hidden from the public barrel.
class NeumorphicActionBar extends StatelessWidget {
  /// Creates a [NeumorphicActionBar].
  const NeumorphicActionBar({super.key, required this.children});

  /// The keys, in reading order, the main one last.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => _InActionBar(
    child: _ActionBar(
      textDirection: Directionality.of(context),
      children: children,
    ),
  );
}

/// Whether [context] stands in a [NeumorphicActionBar]: a key there keeps to its words side by side, and takes the
/// slab's width when the bar stacks the keys.
bool neumorphicInActionBar(BuildContext context) =>
    context.getInheritedWidgetOfExactType<_InActionBar>() != null;

class _InActionBar extends InheritedWidget {
  const _InActionBar({required super.child});

  @override
  bool updateShouldNotify(_InActionBar oldWidget) => false;
}

const double _spacing = 12;
const double _overflowSpacing = 8;

class _ActionBar extends MultiChildRenderObjectWidget {
  const _ActionBar({required this.textDirection, required super.children});

  final TextDirection textDirection;

  @override
  _RenderActionBar createRenderObject(BuildContext context) =>
      _RenderActionBar(textDirection);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderActionBar renderObject,
  ) => renderObject.textDirection = textDirection;
}

class _ActionBarParentData extends ContainerBoxParentData<RenderBox> {}

class _RenderActionBar extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _ActionBarParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _ActionBarParentData> {
  _RenderActionBar(this._textDirection);

  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    if (value == _textDirection) return;
    _textDirection = value;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _ActionBarParentData) {
      child.parentData = _ActionBarParentData();
    }
  }

  List<RenderBox> get _keys => [
    for (RenderBox? k = firstChild; k != null; k = childAfter(k)) k,
  ];

  double get _gaps => _spacing * math.max(0, childCount - 1);

  // The intrinsic sizes are an OverflowBar's: a stacked key is as tall at the slab's width as it is asked to be.
  @override
  double computeMinIntrinsicWidth(double height) =>
      _keys.fold(
        0.0,
        (sum, k) => sum + k.getMinIntrinsicWidth(double.infinity),
      ) +
      _gaps;

  @override
  double computeMaxIntrinsicWidth(double height) =>
      _keys.fold(
        0.0,
        (sum, k) => sum + k.getMaxIntrinsicWidth(double.infinity),
      ) +
      _gaps;

  @override
  double computeMinIntrinsicHeight(double width) =>
      _height(width, (k, w) => k.getMinIntrinsicHeight(w));

  @override
  double computeMaxIntrinsicHeight(double width) =>
      _height(width, (k, w) => k.getMaxIntrinsicHeight(w));

  double _height(double width, double Function(RenderBox, double) measure) {
    final keys = _keys;
    if (keys.isEmpty) return 0;
    if (computeMinIntrinsicWidth(double.infinity) > width) {
      return keys.fold(0.0, (sum, k) => sum + measure(k, width)) +
          _overflowSpacing * (keys.length - 1);
    }
    return keys.fold(0.0, (tallest, k) => math.max(tallest, measure(k, width)));
  }

  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) =>
      defaultComputeDistanceToHighestActualBaseline(baseline);

  @override
  Size computeDryLayout(BoxConstraints constraints) =>
      _layout(constraints, (k, c) => k.getDryLayout(c), place: false);

  @override
  void performLayout() {
    size = _layout(constraints, (k, c) {
      k.layout(c, parentUsesSize: true);
      return k.size;
    }, place: true);
  }

  Size _layout(
    BoxConstraints constraints,
    Size Function(RenderBox, BoxConstraints) lay, {
    required bool place,
  }) {
    final keys = _keys;
    if (keys.isEmpty) return constraints.smallest;
    final rtl = _textDirection == TextDirection.rtl;
    final loose = constraints.loosen();
    final own = [for (final k in keys) lay(k, loose)];
    final row = own.fold(0.0, (sum, s) => sum + s.width) + _gaps;
    if (row <= constraints.maxWidth) {
      // Side by side at the end, centred on the tallest: where the OverflowBar stood them.
      final tallest = own.fold(0.0, (h, s) => math.max(h, s.height));
      final size = constraints.constrain(Size(constraints.maxWidth, tallest));
      if (place) {
        // The OverflowBar's sums: right to left, from the first key's place at the end of the row.
        var x = rtl ? row - own.first.width : size.width - row;
        for (final (i, k) in keys.indexed) {
          if (rtl && i > 0) x -= own[i].width + _spacing;
          (k.parentData! as _ActionBarParentData).offset = Offset(
            x,
            (tallest - own[i].height) / 2,
          );
          if (!rtl) x += own[i].width + _spacing;
        }
      }
      return size;
    }
    // Stacked, each as wide as the slab, the main key (the last) on top. A row that doesn't fit had a finite room.
    final width = constraints.maxWidth;
    var y = 0.0;
    for (final k in keys.reversed) {
      final s = lay(k, loose.tighten(width: width));
      if (place) (k.parentData! as _ActionBarParentData).offset = Offset(0, y);
      y += s.height + _overflowSpacing;
    }
    return constraints.constrain(Size(width, y - _overflowSpacing));
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);

  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);
}
