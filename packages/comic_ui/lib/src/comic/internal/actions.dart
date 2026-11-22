// A dialog's actions: side by side at its end while they fit, as an OverflowBar lays them. When they don't (long words
// on a phone, the reader's large text), stacked, each as wide as the dialog, the confirming one (the last) on top:
// one column at one width, never a ragged stack of buttons at their own widths.
import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../knobs.dart' show ComicSpace;

/// A dialog's actions, [ComicSpace.close] apart side by side and stacked.
/// Internal: hidden from the public barrel.
class ComicActionBar extends MultiChildRenderObjectWidget {
  /// Creates a [ComicActionBar] of [children], in reading order, the confirming one last.
  const ComicActionBar({super.key, required super.children});

  @override
  RenderComicActionBar createRenderObject(BuildContext context) =>
      RenderComicActionBar(Directionality.of(context));

  @override
  void updateRenderObject(
    BuildContext context,
    RenderComicActionBar renderObject,
  ) => renderObject.textDirection = Directionality.of(context);
}

class _ActionBarParentData extends ContainerBoxParentData<RenderBox> {}

const double _spacing = ComicSpace.close;

/// Lays out a [ComicActionBar].
class RenderComicActionBar extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _ActionBarParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _ActionBarParentData> {
  /// Creates a [RenderComicActionBar] in [textDirection].
  RenderComicActionBar(this._textDirection);

  TextDirection _textDirection;

  /// The direction the row runs in: its end is where the actions stand.
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

  List<RenderBox> get _actions => [
    for (RenderBox? a = firstChild; a != null; a = childAfter(a)) a,
  ];

  double get _gaps => _spacing * math.max(0, childCount - 1);

  // The intrinsic sizes are an OverflowBar's: a stacked action is as tall at the dialog's width as it asks to be.
  @override
  double computeMinIntrinsicWidth(double height) =>
      _actions.fold(
        0.0,
        (sum, a) => sum + a.getMinIntrinsicWidth(double.infinity),
      ) +
      _gaps;

  @override
  double computeMaxIntrinsicWidth(double height) =>
      _actions.fold(
        0.0,
        (sum, a) => sum + a.getMaxIntrinsicWidth(double.infinity),
      ) +
      _gaps;

  @override
  double computeMinIntrinsicHeight(double width) =>
      _height(width, (a, w) => a.getMinIntrinsicHeight(w));

  @override
  double computeMaxIntrinsicHeight(double width) =>
      _height(width, (a, w) => a.getMaxIntrinsicHeight(w));

  double _height(double width, double Function(RenderBox, double) measure) {
    final actions = _actions;
    if (actions.isEmpty) return 0;
    if (computeMinIntrinsicWidth(double.infinity) > width) {
      return actions.fold(0.0, (sum, a) => sum + measure(a, width)) + _gaps;
    }
    return actions.fold(0.0, (most, a) => math.max(most, measure(a, width)));
  }

  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) =>
      defaultComputeDistanceToHighestActualBaseline(baseline);

  @override
  Size computeDryLayout(BoxConstraints constraints) =>
      _layout(constraints, (a, c) => a.getDryLayout(c), place: false);

  @override
  void performLayout() {
    size = _layout(constraints, (a, c) {
      a.layout(c, parentUsesSize: true);
      return a.size;
    }, place: true);
  }

  Size _layout(
    BoxConstraints constraints,
    Size Function(RenderBox, BoxConstraints) lay, {
    required bool place,
  }) {
    final actions = _actions;
    if (actions.isEmpty) return constraints.smallest;
    final rtl = _textDirection == TextDirection.rtl;
    final loose = constraints.loosen();
    final own = [for (final a in actions) lay(a, loose)];
    final row = own.fold(0.0, (sum, s) => sum + s.width) + _gaps;
    if (row <= constraints.maxWidth) {
      // Side by side at the end, centred on the tallest: where the OverflowBar stood them.
      final tallest = own.fold(0.0, (h, s) => math.max(h, s.height));
      final size = constraints.constrain(Size(constraints.maxWidth, tallest));
      if (place) {
        var x = rtl ? row - own.first.width : size.width - row;
        for (final (i, a) in actions.indexed) {
          if (rtl && i > 0) x -= own[i].width + _spacing;
          (a.parentData! as _ActionBarParentData).offset = Offset(
            x,
            (tallest - own[i].height) / 2,
          );
          if (!rtl) x += own[i].width + _spacing;
        }
      }
      return size;
    }
    // Stacked, each as wide as the dialog, the confirming one (the last) on top. A row that doesn't fit had room.
    final width = constraints.maxWidth;
    var y = 0.0;
    for (final a in actions.reversed) {
      final s = lay(a, loose.tighten(width: width));
      if (place) (a.parentData! as _ActionBarParentData).offset = Offset(0, y);
      y += s.height + _spacing;
    }
    return constraints.constrain(Size(width, y - _spacing));
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);

  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);
}
