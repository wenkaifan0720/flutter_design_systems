import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// A dialog's foot: its actions side by side in equal cells, a rule between
/// them; when one's words would not fit its cell (or [stacked] asks), one
/// above another, full width, a rule between, the last at the foot.
class BrutalDialogFoot extends MultiChildRenderObjectWidget {
  /// A foot of [children], each [cellHeight] tall.
  const BrutalDialogFoot({
    super.key,
    required this.cellHeight,
    required this.ruleWidth,
    required this.rule,
    this.stacked = false,
    required super.children,
  });

  /// Each cell's height.
  final double cellHeight;

  /// The rule's weight between two cells.
  final double ruleWidth;

  /// The rule's ink.
  final Color rule;

  /// Whether the cells stand one above another whatever their words.
  final bool stacked;

  @override
  RenderBrutalDialogFoot createRenderObject(BuildContext context) =>
      RenderBrutalDialogFoot(
        cellHeight: cellHeight,
        ruleWidth: ruleWidth,
        rule: rule,
        stacked: stacked,
        textDirection: Directionality.of(context),
      );

  @override
  void updateRenderObject(
    BuildContext context,
    RenderBrutalDialogFoot renderObject,
  ) {
    renderObject
      ..cellHeight = cellHeight
      ..ruleWidth = ruleWidth
      ..rule = rule
      ..stacked = stacked
      ..textDirection = Directionality.of(context);
  }
}

/// The parent data of a [BrutalDialogFoot]'s cells.
class BrutalDialogFootParentData extends ContainerBoxParentData<RenderBox> {}

/// Lays a [BrutalDialogFoot].
class RenderBrutalDialogFoot extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, BrutalDialogFootParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, BrutalDialogFootParentData> {
  /// A foot of cells [cellHeight] tall.
  RenderBrutalDialogFoot({
    required double cellHeight,
    required double ruleWidth,
    required Color rule,
    required bool stacked,
    required TextDirection textDirection,
  }) : _cell = cellHeight,
       _weight = ruleWidth,
       _ink = rule,
       _alwaysStacked = stacked,
       _direction = textDirection;

  double _cell;
  set cellHeight(double value) {
    if (value == _cell) return;
    _cell = value;
    markNeedsLayout();
  }

  double _weight;
  set ruleWidth(double value) {
    if (value == _weight) return;
    _weight = value;
    markNeedsLayout();
  }

  Color _ink;
  set rule(Color value) {
    if (value == _ink) return;
    _ink = value;
    markNeedsPaint();
  }

  bool _alwaysStacked;
  set stacked(bool value) {
    if (value == _alwaysStacked) return;
    _alwaysStacked = value;
    markNeedsLayout();
  }

  TextDirection _direction;
  set textDirection(TextDirection value) {
    if (value == _direction) return;
    _direction = value;
    markNeedsLayout();
  }

  /// Whether the last layout stood the cells one above another.
  bool _laidStacked = false;

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! BrutalDialogFootParentData) {
      child.parentData = BrutalDialogFootParentData();
    }
  }

  List<RenderBox> get _cells {
    final cells = <RenderBox>[];
    var child = firstChild;
    while (child != null) {
      cells.add(child);
      child = childAfter(child);
    }
    return cells;
  }

  double _share(double width, int n) =>
      n == 0 ? 0 : (width - (n - 1) * _weight) / n;

  bool _stacks(double width) {
    if (_alwaysStacked) return true;
    final cells = _cells;
    final share = _share(width, cells.length);
    return cells.any((c) => c.getMaxIntrinsicWidth(_cell) > share + 0.5);
  }

  double _height(int n, bool stacks) => n == 0
      ? 0
      : stacks
      ? n * _cell + (n - 1) * _weight
      : _cell;

  double _widthOf(BoxConstraints constraints) => constraints.hasBoundedWidth
      ? constraints.maxWidth
      : constraints.constrainWidth(computeMaxIntrinsicWidth(_cell));

  @override
  Size computeDryLayout(covariant BoxConstraints constraints) {
    final width = _widthOf(constraints);
    return constraints.constrain(
      Size(width, _height(_cells.length, _stacks(width))),
    );
  }

  @override
  void performLayout() {
    final width = _widthOf(constraints);
    final cells = _cells;
    final stacks = _stacks(width);
    _laidStacked = stacks;
    if (stacks) {
      var y = 0.0;
      for (final cell in cells) {
        cell.layout(
          BoxConstraints.tightFor(width: width, height: _cell),
          parentUsesSize: true,
        );
        (cell.parentData! as BrutalDialogFootParentData).offset = Offset(0, y);
        y += _cell + _weight;
      }
    } else {
      final share = _share(width, cells.length);
      final rtl = _direction == TextDirection.rtl;
      for (final (i, cell) in cells.indexed) {
        cell.layout(
          BoxConstraints.tightFor(width: share, height: _cell),
          parentUsesSize: true,
        );
        final x = i * (share + _weight);
        (cell.parentData! as BrutalDialogFootParentData).offset = Offset(
          rtl ? width - x - share : x,
          0,
        );
      }
    }
    size = constraints.constrain(Size(width, _height(cells.length, stacks)));
  }

  @override
  double computeMinIntrinsicWidth(double height) =>
      _cells.fold(0.0, (w, c) => math.max(w, c.getMinIntrinsicWidth(_cell)));

  @override
  double computeMaxIntrinsicWidth(double height) {
    final cells = _cells;
    final widest = cells.fold(
      0.0,
      (w, c) => math.max(w, c.getMaxIntrinsicWidth(_cell)),
    );
    return cells.isEmpty
        ? 0
        : widest * cells.length + (cells.length - 1) * _weight;
  }

  @override
  double computeMinIntrinsicHeight(double width) =>
      _height(_cells.length, width.isFinite ? _stacks(width) : false);

  @override
  double computeMaxIntrinsicHeight(double width) =>
      computeMinIntrinsicHeight(width);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);

  @override
  void paint(PaintingContext context, Offset offset) {
    defaultPaint(context, offset);
    final cells = _cells;
    final paint = Paint()..color = _ink;
    for (var i = 1; i < cells.length; i++) {
      final at = (cells[i].parentData! as BrutalDialogFootParentData).offset;
      final Rect line;
      if (_laidStacked) {
        line = Rect.fromLTWH(
          offset.dx,
          offset.dy + at.dy - _weight,
          size.width,
          _weight,
        );
      } else {
        final rtl = _direction == TextDirection.rtl;
        line = Rect.fromLTWH(
          offset.dx + (rtl ? at.dx + cells[i].size.width : at.dx - _weight),
          offset.dy,
          _weight,
          size.height,
        );
      }
      context.canvas.drawRect(line, paint);
    }
  }
}
