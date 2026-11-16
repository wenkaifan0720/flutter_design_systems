/// Holds a part to whole cells: its child is offered whole cells and whole
/// lines, and it takes whole cells and whole lines whatever the child
/// takes, so the next part starts on the lattice too.
library;

import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../grid.dart';

/// Snaps [child] to the [grid]: offered at most whole cells and lines, and
/// as big as the whole cells and lines it covers, its start-top corner on
/// the lattice. With [fill], it takes all the whole cells across that its
/// constraints allow.
class TermSnap extends SingleChildRenderObjectWidget {
  /// [child] on whole cells of [grid].
  const TermSnap({
    super.key,
    required this.grid,
    this.fill = false,
    super.child,
  });

  /// The lattice.
  final TermGrid grid;

  /// Whether it takes every whole cell across that it may.
  final bool fill;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderTermSnap(
    grid,
    fill,
    Directionality.maybeOf(context) ?? TextDirection.ltr,
  );

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) =>
      (renderObject as _RenderTermSnap)
        ..grid = grid
        ..fill = fill
        ..textDirection = Directionality.maybeOf(context) ?? TextDirection.ltr;
}

class _RenderTermSnap extends RenderShiftedBox {
  _RenderTermSnap(this._grid, this._fill, this._textDirection) : super(null);

  TermGrid _grid;
  set grid(TermGrid value) {
    if (value == _grid) return;
    _grid = value;
    markNeedsLayout();
  }

  bool _fill;
  set fill(bool value) {
    if (value == _fill) return;
    _fill = value;
    markNeedsLayout();
  }

  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    if (value == _textDirection) return;
    _textDirection = value;
    markNeedsLayout();
  }

  double _floorW(double w) => w.isFinite ? _grid.cols(_grid.colsIn(w)) : w;
  double _floorH(double h) => h.isFinite ? _grid.lines(_grid.linesIn(h)) : h;

  BoxConstraints _inner(BoxConstraints c) {
    final maxW = math.max(c.minWidth, _floorW(c.maxWidth));
    final maxH = math.max(c.minHeight, _floorH(c.maxHeight));
    final minW = _fill && maxW.isFinite ? maxW : math.min(c.minWidth, maxW);
    return BoxConstraints(
      minWidth: minW,
      maxWidth: maxW,
      minHeight: math.min(c.minHeight, maxH),
      maxHeight: maxH,
    );
  }

  Size _sizeFor(BoxConstraints c, Size child) => c.constrain(
    Size(_grid.ceilToCols(child.width), _grid.ceilToLines(child.height)),
  );

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final c = child;
    if (c == null) return constraints.smallest;
    return _sizeFor(constraints, c.getDryLayout(_inner(constraints)));
  }

  @override
  void performLayout() {
    final c = child;
    if (c == null) {
      size = constraints.smallest;
      return;
    }
    c.layout(_inner(constraints), parentUsesSize: true);
    size = _sizeFor(constraints, c.size);
    final dx = _textDirection == TextDirection.rtl
        ? size.width - c.size.width
        : 0.0;
    (c.parentData! as BoxParentData).offset = Offset(dx, 0);
  }

  @override
  double computeMinIntrinsicWidth(double height) =>
      _grid.ceilToCols(super.computeMinIntrinsicWidth(height));

  @override
  double computeMaxIntrinsicWidth(double height) =>
      _grid.ceilToCols(super.computeMaxIntrinsicWidth(height));

  @override
  double computeMinIntrinsicHeight(double width) =>
      _grid.ceilToLines(super.computeMinIntrinsicHeight(width));

  @override
  double computeMaxIntrinsicHeight(double width) =>
      _grid.ceilToLines(super.computeMaxIntrinsicHeight(width));
}
