import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Lays [children] side by side, each as wide as the widest needs ([equal])
/// or as its words, with [spacing] between, while that fits the width. Where
/// equal shares do not fit but every child's own words do, they stay one
/// row, each its words and a share of what is left. Where one row does not
/// fit (a phone, large text, long words), they wrap into the fewest rows
/// that do, balanced (four as 2 + 2, never 3 + 1), each row the whole width;
/// where none do, they stack, one to a row. So a row of choices never clips
/// or squeezes a word.
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

  /// Whether the last layout put the children on more than one row.
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

  double _ownNeed(Iterable<double> needs) => needs.isEmpty
      ? 0
      : needs.fold<double>(0, (a, b) => a + b) + _spacing * (needs.length - 1);

  // How the children stand at [maxW]: the rows, each a run of children and
  // whether its children share it equally. One row while it fits: equal
  // shares where they fit, else each its own words and a share of what is
  // left over (three short answers stay one row on a phone). Else the fewest
  // rows that fit, balanced (four as 2 + 2, five as 3 + 2, never 3 + 1),
  // each the whole width; else a stack, one to a row.
  List<(List<int>, bool)> _plan(List<double> needs, double maxW) {
    final n = needs.length;
    final all = [for (var i = 0; i < n; i++) i];
    if (_rowNeed(needs) <= maxW) return [(all, _equal)];
    if (_equal && _ownNeed(needs) <= maxW) return [(all, false)];
    for (var rows = 2; rows < n; rows++) {
      final runs = <List<int>>[];
      var at = 0;
      for (var r = 0; r < rows; r++) {
        final count = n ~/ rows + (r < n % rows ? 1 : 0);
        runs.add(all.sublist(at, at + count));
        at += count;
      }
      bool fitsEqual(List<int> run) =>
          _rowNeed([for (final i in run) needs[i]]) <= maxW;
      bool fitsOwn(List<int> run) =>
          _ownNeed([for (final i in run) needs[i]]) <= maxW;
      if (runs.every((run) => fitsEqual(run) || fitsOwn(run))) {
        return [for (final run in runs) (run, _equal && fitsEqual(run))];
      }
    }
    return [
      for (final i in all) ([i], true),
    ];
  }

  // The width of each child of [run] in a row [width] wide.
  List<double> _widths(
    List<int> run,
    bool equal,
    List<double> needs,
    double width,
  ) {
    final gaps = _spacing * (run.length - 1);
    if (equal) return List.filled(run.length, (width - gaps) / run.length);
    final spare =
        (width - _ownNeed([for (final i in run) needs[i]])) / run.length;
    return [for (final i in run) needs[i] + spare];
  }

  // The width the rows take: a single row its need (or all of [maxW] where
  // it stretches), wrapped rows all of it.
  double _width(List<(List<int>, bool)> plan, List<double> needs, double maxW) {
    if (plan.length == 1) {
      final (run, equal) = plan.single;
      final need = equal
          ? _rowNeed([for (final i in run) needs[i]])
          : _ownNeed([for (final i in run) needs[i]]);
      return _stretch && maxW.isFinite ? maxW : need;
    }
    return maxW.isFinite ? maxW : _rowNeed(needs);
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
    final plan = _plan(needs, width);
    final total = _width(plan, needs, width);
    var height = 0.0;
    for (final (run, equal) in plan) {
      final widths = _widths(run, equal, needs, total);
      var tallest = 0.0;
      for (var j = 0; j < run.length; j++) {
        tallest = math.max(tallest, h(kids[run[j]], widths[j]));
      }
      height += tallest;
    }
    return height + _spacing * (plan.length - 1);
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
    final maxW = constraints.maxWidth;
    final plan = _plan(needs, maxW);
    if (!dry) _stacked = plan.length > 1;
    final width = _width(plan, needs, maxW);
    var y = 0.0;
    for (final (run, equal) in plan) {
      final widths = _widths(run, equal, needs, width);
      var height = 0.0;
      final sizes = <Size>[];
      for (var j = 0; j < run.length; j++) {
        final c = BoxConstraints(minWidth: widths[j], maxWidth: widths[j]);
        final kid = kids[run[j]];
        final s = dry
            ? kid.getDryLayout(c)
            : (kid..layout(c, parentUsesSize: true)).size;
        sizes.add(s);
        height = math.max(height, s.height);
      }
      if (!dry) {
        // Every child of a row stands as tall as its tallest, so faces line
        // up.
        var x = 0.0;
        for (var j = 0; j < run.length; j++) {
          final kid = kids[run[j]];
          if (sizes[j].height < height) {
            kid.layout(
              BoxConstraints.tightFor(width: widths[j], height: height),
              parentUsesSize: true,
            );
          }
          final w = widths[j];
          // Right to left, a row starts at the box's right edge, however
          // much wider than the row the box is held.
          final dx = _direction == TextDirection.rtl ? width - x - w : x;
          (kid.parentData! as CivicFitRowParentData).offset = Offset(dx, y);
          x += w + _spacing;
        }
      }
      y += height + _spacing;
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
