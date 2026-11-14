import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// The acts at a card's foot: each takes an even share of the row, [gap]
/// apart, the first at the reading start. When one act's words would not
/// fit its share (a card narrower than a phone's sheet, the words at twice
/// their size), they stand one above another across the whole width
/// instead, the last (the confirm) on top, or the first when [lastOnTop] is
/// false (a row that leads with its main act): an act is never cut short to
/// an ellipsis. Plumbing of the parts.
class LedgerEvenActs extends MultiChildRenderObjectWidget {
  /// Lays [children] evenly in a row, or stacked when one doesn't fit.
  const LedgerEvenActs({
    required this.gap,
    required super.children,
    this.lastOnTop = true,
    super.key,
  });

  /// The room between two acts, across or down.
  final double gap;

  /// Whether, stacked, the last act stands on top (a confirm after its
  /// cancel) rather than the first.
  final bool lastOnTop;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderEvenActs(gap, Directionality.of(context), lastOnTop);

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    (renderObject as _RenderEvenActs)
      ..gap = gap
      ..textDirection = Directionality.of(context)
      ..lastOnTop = lastOnTop;
  }
}

class _ActParentData extends ContainerBoxParentData<RenderBox> {}

class _RenderEvenActs extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _ActParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _ActParentData> {
  _RenderEvenActs(this._gap, this._textDirection, this._lastOnTop);

  bool _lastOnTop;
  set lastOnTop(bool value) {
    if (value == _lastOnTop) return;
    _lastOnTop = value;
    markNeedsLayout();
  }

  double _gap;
  set gap(double value) {
    if (value == _gap) return;
    _gap = value;
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
    if (child.parentData is! _ActParentData) {
      child.parentData = _ActParentData();
    }
  }

  List<RenderBox> get _acts => getChildrenAsList();

  double _share(double width, int count) =>
      (width - _gap * (count - 1)) / count;

  /// Whether every act's words fit its even share of [width] (half a point
  /// of slack for rounding).
  bool _fits(double width) {
    final acts = _acts;
    if (acts.length < 2) return true;
    if (!width.isFinite) return true;
    final share = _share(width, acts.length);
    return acts.every(
      (act) => act.getMaxIntrinsicWidth(double.infinity) <= share + .5,
    );
  }

  Size _layout(
    BoxConstraints constraints,
    Size Function(RenderBox act, BoxConstraints constraints) lay, {
    required bool place,
  }) {
    final acts = _acts;
    if (acts.isEmpty) return constraints.smallest;
    final width = constraints.maxWidth.isFinite
        ? constraints.maxWidth
        : acts.length *
                  acts
                      .map((a) => a.getMaxIntrinsicWidth(double.infinity))
                      .reduce(math.max) +
              _gap * (acts.length - 1);
    if (_fits(width)) {
      final share = _share(width, acts.length);
      final sizes = [
        for (final act in acts) lay(act, BoxConstraints.tightFor(width: share)),
      ];
      final height = sizes.map((s) => s.height).reduce(math.max);
      if (place) {
        for (var i = 0; i < acts.length; i++) {
          final start = i * (share + _gap);
          final x = _textDirection == TextDirection.ltr
              ? start
              : width - start - share;
          (acts[i].parentData! as _ActParentData).offset = Offset(
            x,
            (height - sizes[i].height) / 2,
          );
        }
      }
      return constraints.constrain(Size(width, height));
    }
    var y = 0.0;
    for (final act in _lastOnTop ? acts.reversed : acts) {
      final size = lay(act, BoxConstraints.tightFor(width: width));
      if (place) (act.parentData! as _ActParentData).offset = Offset(0, y);
      y += size.height + _gap;
    }
    return constraints.constrain(Size(width, y - _gap));
  }

  @override
  void performLayout() {
    size = _layout(constraints, (act, c) {
      act.layout(c, parentUsesSize: true);
      return act.size;
    }, place: true);
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) =>
      _layout(constraints, (act, c) => act.getDryLayout(c), place: false);

  @override
  double computeMinIntrinsicWidth(double height) => _acts.fold(
    0.0,
    (w, act) => math.max(w, act.getMinIntrinsicWidth(height)),
  );

  @override
  double computeMaxIntrinsicWidth(double height) {
    final acts = _acts;
    if (acts.isEmpty) return 0;
    final widest = acts.fold(
      0.0,
      (w, act) => math.max(w, act.getMaxIntrinsicWidth(height)),
    );
    return acts.length * widest + _gap * (acts.length - 1);
  }

  double _height(double width, double Function(RenderBox, double) of) {
    final acts = _acts;
    if (acts.isEmpty) return 0;
    if (_fits(width)) {
      final share = width.isFinite ? _share(width, acts.length) : width;
      return acts.fold(0.0, (h, act) => math.max(h, of(act, share)));
    }
    return acts.fold(0.0, (h, act) => h + of(act, width)) +
        _gap * (acts.length - 1);
  }

  @override
  double computeMinIntrinsicHeight(double width) =>
      _height(width, (act, w) => act.getMinIntrinsicHeight(w));

  @override
  double computeMaxIntrinsicHeight(double width) =>
      _height(width, (act, w) => act.getMaxIntrinsicHeight(w));

  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) =>
      defaultComputeDistanceToHighestActualBaseline(baseline);

  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);
}
