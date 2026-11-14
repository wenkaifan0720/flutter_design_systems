// Layout: the 12-column grid and a column whose rows take up the slack. Panels in a tier share a height and their lists
// grow, so no card ends in a hole. Neither needs IntrinsicHeight, and neither crashes under a scroll view.
import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'theme.dart';

/// A part with its own size keeps it, whatever its parent asks. A stretching Column or Row hands tight constraints, which a
/// SizedBox can't refuse: a paint that reads its declared size and a `Center` that reads the real width come apart. Here the
/// part stands at [alignment] in the room (the start edge unless it is centred by design: left in LTR, mirrored in RTL) and,
/// if the room is smaller than the part, scales down whole. Give one side, or none, for a part whose other side follows its
/// content.
Widget comicOwnSize({
  double? width,
  double? height,
  AlignmentGeometry alignment = AlignmentDirectional.topStart,
  required Widget child,
}) {
  final box = SizedBox(width: width, height: height, child: child);
  return width != null && height != null
      ? FittedBox(fit: BoxFit.scaleDown, alignment: alignment, child: box)
      : Align(
          alignment: alignment,
          widthFactor: 1,
          heightFactor: 1,
          child: box,
        );
}

/// A part that fills the width it is given, up to [maxWidth], and past that stands in the middle of the room. With an
/// [aspect] it keeps it whatever it is handed: a stretching Row asks for a height as well, and a bare AspectRatio gives in
/// and distorts the art. A Row with no width to give gets [loneWidth], so the part stands small and leaves the row its words.
///
/// ```dart
/// ComicFill(maxWidth: 400, child: Text('A page-width figure'))
/// ```
class ComicFill extends SingleChildRenderObjectWidget {
  /// Creates a [ComicFill].
  const ComicFill({
    super.key,
    required this.maxWidth,
    this.aspect,
    this.loneWidth = 240,
    required Widget super.child,
  });

  /// The maximum width in logical pixels.
  final double maxWidth;

  /// The width divided by the height of the picture.
  final double? aspect;

  /// The fallback width when the parent supplies no finite width.
  final double loneWidth;
  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderComicFill(maxWidth, aspect, loneWidth);
  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    (renderObject as _RenderComicFill)
      ..limit = maxWidth
      ..aspect = aspect
      ..lone = loneWidth;
  }
}

class _RenderComicFill extends RenderAligningShiftedBox {
  _RenderComicFill(this._limit, this._aspect, this._lone)
    : super(alignment: Alignment.topCenter, textDirection: null);
  double _limit, _lone;
  double? _aspect;
  set limit(double v) {
    if (v == _limit) return;
    _limit = v;
    markNeedsLayout();
  }

  set aspect(double? v) {
    if (v == _aspect) return;
    _aspect = v;
    markNeedsLayout();
  }

  set lone(double v) {
    if (v == _lone) return;
    _lone = v;
    markNeedsLayout();
  }

  BoxConstraints _inner(BoxConstraints c) {
    var w = math.min(c.hasBoundedWidth ? c.maxWidth : _lone, _limit);
    final a = _aspect;
    if (a == null) {
      return BoxConstraints(
        minWidth: w,
        maxWidth: w,
        minHeight: c.minHeight,
        maxHeight: c.maxHeight,
      );
    }
    var h = w / a;
    if (h > c.maxHeight) {
      h = c.maxHeight;
      w = h * a;
    }
    return BoxConstraints.tightFor(width: w, height: h);
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) =>
      constraints.constrain(child!.getDryLayout(_inner(constraints)));

  @override
  double? computeDryBaseline(
    BoxConstraints constraints,
    TextBaseline baseline,
  ) {
    final inner = _inner(constraints);
    final at = child!.getDryBaseline(inner, baseline);
    if (at == null) return null;
    final own = child!.getDryLayout(inner);
    final room = constraints.constrain(own) - own as Offset;
    return at + resolvedAlignment.alongOffset(room).dy;
  }

  @override
  void performLayout() {
    child!.layout(_inner(constraints), parentUsesSize: true);
    size = constraints.constrain(child!.size);
    alignChild();
  }

  double _across(double height, double Function(double) read) {
    final a = _aspect;
    return math.min(
      a != null && height.isFinite ? height * a : read(height),
      _limit,
    );
  }

  double _down(double width, double Function(double) read) {
    final held = math.min(width, _limit);
    final a = _aspect;
    return a != null && held.isFinite ? held / a : read(held);
  }

  @override
  double computeMinIntrinsicWidth(double height) =>
      _across(height, child!.getMinIntrinsicWidth);
  @override
  double computeMaxIntrinsicWidth(double height) =>
      _across(height, child!.getMaxIntrinsicWidth);
  @override
  double computeMinIntrinsicHeight(double width) =>
      _down(width, child!.getMinIntrinsicHeight);
  @override
  double computeMaxIntrinsicHeight(double width) =>
      _down(width, child!.getMaxIntrinsicHeight);
}

/// Marks a child of a `ComicColumn` as taking a share of the slack (CSS `flex: 1`).
///
/// ```dart
/// ComicColumn(children: const [Text('Heading'), ComicGrow(child: Text('Body'))])
/// ```
class ComicGrow extends ParentDataWidget<_ComicColumnData> {
  /// Creates a [ComicGrow].
  const ComicGrow({super.key, required super.child});
  @override
  void applyParentData(RenderObject renderObject) {
    final d = renderObject.parentData as _ComicColumnData;
    if (!d.grow) {
      d.grow = true;
      renderObject.parent?.markNeedsLayout();
    }
  }

  @override
  Type get debugTypicalAncestorWidgetClass => ComicColumn;
}

class _ComicColumnData extends ContainerBoxParentData<RenderBox> {
  bool grow = false;
}

/// A column that is safe everywhere. Children stretch to its width. Under a bounded height (a card in a `ComicRow` on a
/// desktop) the `ComicGrow` children share the requested height, floored at their own height. A single growing body under
/// a loose height ceiling can keep its natural size or expand up to that ceiling; under a scroll view children take
/// their own height. Use it in place of Column + Expanded inside any card.
///
/// ```dart
/// ComicColumn(gap: 12, children: const [Text('Heading'), Text('Body')])
/// ```
class ComicColumn extends MultiChildRenderObjectWidget {
  /// Creates a [ComicColumn].
  const ComicColumn({
    super.key,
    super.children,
    this.gap = 0,
    this.skipEmpty = false,
    this.spineX,
    this.spineColor,
  });

  /// Space between children.
  final double gap;

  /// Empty children add no gap when true. Growers still reserve their share.
  final bool skipEmpty;

  /// If set, a 1 px rule runs from the centre of the first child to the centre of the last, at this x from the start
  /// edge: the shaft through a list of medallions.
  final double? spineX;

  /// The ink used by the page spine.
  final Color? spineColor;

  @override
  RenderObject createRenderObject(BuildContext context) => RenderComicColumn(
    gap,
    spineX,
    spineColor,
    Directionality.of(context),
    skipEmpty,
  );
  @override
  void updateRenderObject(
    BuildContext context,
    RenderComicColumn renderObject,
  ) {
    renderObject
      ..skipEmpty = skipEmpty
      ..gap = gap
      ..spineX = spineX
      ..spineColor = spineColor
      ..dir = Directionality.of(context);
  }
}

/// Lays out and paints the [ComicColumn] widget.
class RenderComicColumn extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _ComicColumnData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _ComicColumnData> {
  /// Creates a [RenderComicColumn].
  RenderComicColumn(
    this._gap,
    this._spineX,
    this._spineColor,
    this._dir,
    this._skipEmpty,
  );
  bool _skipEmpty;
  set skipEmpty(bool value) {
    if (value != _skipEmpty) {
      _skipEmpty = value;
      markNeedsLayout();
    }
  }

  double _gap;
  double? _spineX;
  Color? _spineColor;
  TextDirection _dir;
  set gap(double v) {
    if (v != _gap) {
      _gap = v;
      markNeedsLayout();
    }
  }

  set spineX(double? v) {
    if (v != _spineX) {
      _spineX = v;
      markNeedsPaint();
    }
  }

  set spineColor(Color? v) {
    if (v != _spineColor) {
      _spineColor = v;
      markNeedsPaint();
    }
  }

  set dir(TextDirection v) {
    if (v != _dir) {
      _dir = v;
      markNeedsPaint();
    }
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _ComicColumnData) {
      child.parentData = _ComicColumnData();
    }
  }

  double _gaps([int? count]) => _gap * math.max((count ?? childCount) - 1, 0);

  @override
  double computeMinIntrinsicWidth(double height) {
    var w = 0.0;
    for (var c = firstChild; c != null; c = childAfter(c)) {
      w = math.max(w, c.getMinIntrinsicWidth(double.infinity));
    }
    return w;
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    var w = 0.0;
    for (var c = firstChild; c != null; c = childAfter(c)) {
      w = math.max(w, c.getMaxIntrinsicWidth(double.infinity));
    }
    return w;
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    var h = 0.0, count = 0;
    for (var c = firstChild; c != null; c = childAfter(c)) {
      final height = c.getMinIntrinsicHeight(width);
      h += height;
      if (!_skipEmpty ||
          height > 0 ||
          (c.parentData as _ComicColumnData).grow) {
        count++;
      }
    }
    return h + _gaps(count);
  }

  @override
  double computeMaxIntrinsicHeight(double width) =>
      computeMinIntrinsicHeight(width);

  @override
  void performLayout() {
    final w = constraints.hasBoundedWidth
        ? constraints.maxWidth
        : computeMaxIntrinsicWidth(double.infinity);
    final natural = BoxConstraints(minWidth: w, maxWidth: w);
    final growers = [
      for (var c = firstChild; c != null; c = childAfter(c))
        if ((c.parentData as _ComicColumnData).grow) c,
    ];
    final boundedGrow = constraints.hasBoundedHeight && growers.length == 1
        ? growers.single
        : null;
    final hs = <RenderBox, double>{};
    var total = 0.0;
    var count = 0;
    for (var c = firstChild; c != null; c = childAfter(c)) {
      if (c == boundedGrow) continue;
      c.layout(natural, parentUsesSize: true);
      hs[c] = c.size.height;
      total += c.size.height;
      if (!_skipEmpty ||
          c.size.height > 0 ||
          (c.parentData as _ComicColumnData).grow) {
        count++;
      }
    }
    if (boundedGrow != null) {
      // A panel's body can expand or contain a scroll view. Give it the
      // finite space after the caption, rather than an unbounded probe.
      count++;
      final room = math.max(0.0, constraints.maxHeight - total - _gaps(count));
      boundedGrow.layout(
        BoxConstraints(
          minWidth: w,
          maxWidth: w,
          minHeight: constraints.hasTightHeight ? room : 0,
          maxHeight: room,
        ),
        parentUsesSize: true,
      );
      hs[boundedGrow] = boundedGrow.size.height;
      total += boundedGrow.size.height;
    }
    final gaps = _gaps(count);
    total += gaps;
    var height = total;
    final target = constraints.hasBoundedHeight
        ? constraints.maxHeight
        : math.max(total, constraints.minHeight);
    if (boundedGrow == null && target > total && growers.isNotEmpty) {
      height = target;
      // CSS flex: 1 with min-height auto: an even share, floored at each child's own height.
      var room = target - gaps;
      for (var c = firstChild; c != null; c = childAfter(c)) {
        if (!(c.parentData as _ComicColumnData).grow) room -= hs[c]!;
      }
      final open = [...growers];
      var settled = false;
      while (!settled && open.isNotEmpty) {
        settled = true;
        final share = room / open.length;
        for (final c in [...open]) {
          if (hs[c]! > share) {
            room -= hs[c]!;
            open.remove(c);
            settled = false;
          }
        }
      }
      final share = open.isEmpty ? 0.0 : room / open.length;
      for (final c in open) {
        c.layout(
          BoxConstraints.tightFor(width: w, height: share),
          parentUsesSize: true,
        );
      }
    }
    // Whole pixels, as a browser snaps boxes: a 1 px rule at a fractional y paints as two faint lines.
    var y = 0.0;
    var previous = false;
    for (var c = firstChild; c != null; c = childAfter(c)) {
      final visible =
          !_skipEmpty ||
          c.size.height > 0 ||
          (c.parentData as _ComicColumnData).grow;
      if (visible && previous) y += _gap;
      (c.parentData as _ComicColumnData).offset = Offset(0, y.roundToDouble());
      y += c.size.height;
      if (visible) previous = true;
    }
    size = constraints.constrain(Size(w, height.roundToDouble()));
  }

  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) =>
      defaultComputeDistanceToFirstActualBaseline(baseline);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);

  @override
  void paint(PaintingContext context, Offset offset) {
    if (_spineX != null && _spineColor != null && firstChild != null) {
      final first = firstChild!, last = lastChild!;
      final y0 =
          (first.parentData as _ComicColumnData).offset.dy +
          first.size.height / 2;
      final y1 =
          (last.parentData as _ComicColumnData).offset.dy +
          last.size.height / 2;
      final x = _dir == TextDirection.ltr
          ? _spineX!
          : size.width - _spineX! - 1;
      context.canvas.drawRect(
        Rect.fromLTRB(
          offset.dx + x,
          offset.dy + y0,
          offset.dx + x + 1,
          offset.dy + y1,
        ),
        Paint()..color = _spineColor!,
      );
    }
    defaultPaint(context, offset);
  }
}

/// Children side by side, widths in proportion to `flex`, all as tall as the tallest. Each child is measured first and
/// then given the row's height, so a card can hold anything, and `ComicGrow` lists inside take up the slack.
///
/// ```dart
/// ComicEqualRow(flex: const [1, 1], children: const [Text('One'), Text('Two')])
/// ```
class ComicEqualRow extends MultiChildRenderObjectWidget {
  /// Creates a [ComicEqualRow].
  const ComicEqualRow({
    super.key,
    required this.flex,
    this.gap = 0,
    this.columns,
    this.pull = 0,
    super.children,
  });

  /// Relative shares assigned to children.
  final List<int> flex;

  /// Space between adjacent children in logical pixels.
  final double gap;

  /// When set, `flex` counts columns of a grid of that many columns, so a span also takes the gutters it crosses.
  final int? columns;

  /// How far each child but the first reaches back under its neighbour: a slanted gutter's overlap.
  final double pull;
  @override
  RenderObject createRenderObject(BuildContext context) =>
      RenderComicEqualRow(flex, gap, Directionality.of(context), columns, pull);
  @override
  void updateRenderObject(
    BuildContext context,
    RenderComicEqualRow renderObject,
  ) {
    renderObject
      ..flex = flex
      ..gap = gap
      ..columns = columns
      ..pull = pull
      ..dir = Directionality.of(context);
  }
}

class _EqualRowData extends ContainerBoxParentData<RenderBox> {}

/// Lays out and paints the [ComicEqualRow] widget.
class RenderComicEqualRow extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _EqualRowData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _EqualRowData> {
  /// Creates a [RenderComicEqualRow].
  RenderComicEqualRow(
    this._flex,
    this._gap,
    this._dir,
    this._columns, [
    this._pull = 0,
  ]);
  List<int> _flex;
  double _gap, _pull;
  TextDirection _dir;
  int? _columns;
  set pull(double v) {
    _pull = v;
    markNeedsLayout();
  }

  set columns(int? v) {
    _columns = v;
    markNeedsLayout();
  }

  set flex(List<int> v) {
    _flex = v;
    markNeedsLayout();
  }

  set gap(double v) {
    _gap = v;
    markNeedsLayout();
  }

  set dir(TextDirection v) {
    _dir = v;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _EqualRowData) child.parentData = _EqualRowData();
  }

  List<double> _widths(double total) {
    final n = childCount;
    final cols = _columns;
    if (cols != null) {
      return [
        for (var i = 0; i < n; i++)
          math.max(
            0.0,
            (i < _flex.length ? _flex[i] : 1) * (total + _gap) / cols - _gap,
          ),
      ];
    }
    final sum = _flex.take(n).fold<int>(0, (a, b) => a + b);
    final room = total - _gap * math.max(n - 1, 0);
    return [
      for (var i = 0; i < n; i++)
        room * (i < _flex.length ? _flex[i] : 1) / (sum == 0 ? 1 : sum),
    ];
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    final ws = _widths(width);
    var h = 0.0, i = 0;
    for (var c = firstChild; c != null; c = childAfter(c)) {
      h = math.max(h, c.getMinIntrinsicHeight(ws[i++]));
    }
    return h;
  }

  @override
  double computeMaxIntrinsicHeight(double width) =>
      computeMinIntrinsicHeight(width);

  @override
  double computeMinIntrinsicWidth(double height) {
    var w = _gap * math.max(childCount - 1, 0);
    for (var c = firstChild; c != null; c = childAfter(c)) {
      w += c.getMinIntrinsicWidth(double.infinity);
    }
    return w;
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    var w = _gap * math.max(childCount - 1, 0);
    for (var c = firstChild; c != null; c = childAfter(c)) {
      w += c.getMaxIntrinsicWidth(double.infinity);
    }
    return w;
  }

  @override
  void performLayout() {
    final w = constraints.maxWidth.isFinite
        ? constraints.maxWidth
        : computeMaxIntrinsicWidth(double.infinity);
    final raw = _widths(w);
    // Column edges on whole pixels, as a browser snaps them.
    final lefts = <double>[], ws = <double>[];
    var at = 0.0;
    for (final cw in raw) {
      final a = at.roundToDouble(), b = (at + cw).roundToDouble();
      final back = lefts.isEmpty ? 0.0 : _pull;
      lefts.add(a - back);
      ws.add(b - a + back);
      at += cw + _gap;
    }
    var h = constraints.minHeight, i = 0;
    for (var c = firstChild; c != null; c = childAfter(c)) {
      c.layout(BoxConstraints.tightFor(width: ws[i++]), parentUsesSize: true);
      h = math.max(h, c.size.height);
    }
    h = (h - 1e-6).ceilToDouble(); // up, never down: a child held to less than it measured would overflow
    if (constraints.hasBoundedHeight &&
        constraints.maxHeight > h &&
        constraints.isTight) {
      h = constraints.maxHeight;
    }
    if (constraints.hasBoundedHeight &&
        constraints.minHeight == constraints.maxHeight) {
      h = constraints.maxHeight;
    }
    i = 0;
    // Every column at the row's height, the tallest too: a column laid out loose places its foot where it stopped,
    // a pixel off its neighbours' (a card's tag at 318 beside 319).
    for (var c = firstChild; c != null; c = childAfter(c)) {
      final cw = ws[i];
      c.layout(
        BoxConstraints.tightFor(width: cw, height: h),
        parentUsesSize: true,
      );
      final dx = _dir == TextDirection.ltr ? lefts[i] : w - lefts[i] - cw;
      (c.parentData as _EqualRowData).offset = Offset(dx, 0);
      i++;
    }
    size = constraints.constrain(Size(w, h));
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);

  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);
}

/// A row on the 12-column grid: `ComicRow(spans: [7, 5], children: [a, b])`. From 1024 wide the panels sit side by side and
/// share a height, with 16 gutters. Below that they stack with 10 between. `ComicTier` is the same thing with the comic
/// page's other reflows; use this when every panel holds words.
///
/// ```dart
/// ComicRow(spans: const [6, 6], children: const [Text('Left'), Text('Right')])
/// ```
class ComicRow extends StatelessWidget {
  /// Creates a [ComicRow].
  const ComicRow({super.key, required this.spans, required this.children});

  /// Column shares used by the expanded layout.
  final List<int> spans;

  /// Child widgets in their display order.
  final List<Widget> children;
  @override
  Widget build(BuildContext context) {
    if (!ComicTheme.of(context).desk) {
      return ComicColumn(gap: 10, children: children);
    }
    return ComicEqualRow(flex: spans, gap: 16, columns: 12, children: children);
  }
}

/// Vertical alignment of a fitted row's children.
enum ComicFitAlign {
  /// Aligns the child centers.
  center,

  /// Aligns text baselines.
  baseline,

  /// Aligns the child bottoms.
  bottom,
}

/// A row that can't overflow, and works inside a plain `Row`. One child, `fill`, takes what is left; the others keep
/// their natural width, measured last to first, each leaving at least `fillMin` (or `fillShare` of the row, or the
/// fill's longest word, up to half the row) for it.
/// `shrink` makes the row only as wide as its content, for a mark and a label.
///
/// ```dart
/// ComicFitRow(fill: 1, children: const [Icon(ComicGlyphs.house), Text('A label')])
/// ```
class ComicFitRow extends MultiChildRenderObjectWidget {
  /// Creates a [ComicFitRow].
  const ComicFitRow({
    super.key,
    required this.fill,
    this.gap = 8,
    this.align = ComicFitAlign.center,
    this.shrink = false,
    this.fillMin = 0,
    this.fillShare = 0,
    super.children,
  });

  /// The index of the child that takes the remaining width.
  final int fill;

  /// [gap]: space between adjacent children in logical pixels. [fillMin]: the minimum share reserved for the filling child. [fillShare]: the share of width reserved for the filling child.
  final double gap, fillMin, fillShare;

  /// How the row aligns its children vertically.
  final ComicFitAlign align;

  /// Sizes the row to its children when space permits.
  final bool shrink;
  @override
  RenderObject createRenderObject(BuildContext context) =>
      RenderComicFitRow(this, Directionality.of(context));
  @override
  void updateRenderObject(
    BuildContext context,
    RenderComicFitRow renderObject,
  ) {
    renderObject
      .._w = this
      .._dir = Directionality.of(context)
      ..markNeedsLayout();
  }
}

class _FitRowData extends ContainerBoxParentData<RenderBox> {}

/// Lays out and paints the [ComicFitRow] widget.
class RenderComicFitRow extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _FitRowData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _FitRowData> {
  /// Creates a [RenderComicFitRow].
  RenderComicFitRow(this._w, this._dir);
  ComicFitRow _w;
  TextDirection _dir;
  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _FitRowData) child.parentData = _FitRowData();
  }

  List<RenderBox> get _kids => [
    for (var c = firstChild; c != null; c = childAfter(c)) c,
  ];
  double _gaps() => _w.gap * math.max(childCount - 1, 0);
  @override
  double computeMinIntrinsicWidth(double height) => _kids.fold(
    _gaps(),
    (a, c) => a + c.getMinIntrinsicWidth(double.infinity),
  );
  @override
  double computeMaxIntrinsicWidth(double height) => _kids.fold(
    _gaps(),
    (a, c) => a + c.getMaxIntrinsicWidth(double.infinity),
  );
  @override
  double computeMinIntrinsicHeight(double width) => _kids.fold(
    0.0,
    (a, c) => math.max(a, c.getMinIntrinsicHeight(double.infinity)),
  );
  @override
  double computeMaxIntrinsicHeight(double width) => _kids.fold(
    0.0,
    (a, c) => math.max(a, c.getMaxIntrinsicHeight(double.infinity)),
  );
  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) =>
      defaultComputeDistanceToFirstActualBaseline(baseline);

  @override
  void performLayout() {
    final kids = _kids;
    if (kids.isEmpty) {
      size = constraints.smallest;
      return;
    }
    final bounded = constraints.hasBoundedWidth;
    final total = constraints.maxWidth;
    final fillAt = _w.fill.clamp(0, kids.length - 1);
    var room = bounded ? total - _gaps() : double.infinity;
    // A row that keeps room for the fill keeps at least its longest word (up to half the row), so large text doesn't
    // break the fill's words mid-word.
    final kept = _w.fillMin > 0 || _w.fillShare > 0;
    final reserve = bounded
        ? math.max(
            math.max(_w.fillMin, _w.fillShare * total),
            kept
                ? math.min(
                    kids[fillAt].getMinIntrinsicWidth(double.infinity),
                    room / 2,
                  )
                : 0.0,
          )
        : 0.0;
    final ws = List<double>.filled(kids.length, 0);
    for (var i = kids.length - 1; i >= 0; i--) {
      if (i == fillAt) continue;
      final most = bounded ? math.max(room - reserve, 0.0) : double.infinity;
      kids[i].layout(BoxConstraints(maxWidth: most), parentUsesSize: true);
      ws[i] = kids[i].size.width;
      if (bounded) room -= ws[i];
    }
    final left = bounded ? math.max(room, 0.0) : double.infinity;
    kids[fillAt].layout(
      _w.shrink || !bounded
          ? BoxConstraints(maxWidth: left)
          : BoxConstraints.tightFor(width: left),
      parentUsesSize: true,
    );
    ws[fillAt] = kids[fillAt].size.width;
    final used = ws.fold(0.0, (a, b) => a + b) + _gaps();
    final w = _w.shrink || !bounded ? constraints.constrainWidth(used) : total;
    // Line them up.
    var above = 0.0, below = 0.0, tallest = 0.0;
    final ascents = List<double>.filled(kids.length, 0);
    for (var i = 0; i < kids.length; i++) {
      final h = kids[i].size.height;
      tallest = math.max(tallest, h);
      if (_w.align == ComicFitAlign.baseline) {
        final a =
            kids[i].getDistanceToBaseline(
              TextBaseline.alphabetic,
              onlyReal: true,
            ) ??
            h;
        ascents[i] = a;
        above = math.max(above, a);
        below = math.max(below, h - a);
      }
    }
    final h = constraints.constrainHeight(
      _w.align == ComicFitAlign.baseline ? above + below : tallest,
    );
    var x = 0.0;
    for (var i = 0; i < kids.length; i++) {
      final kh = kids[i].size.height;
      final y = switch (_w.align) {
        ComicFitAlign.center => (h - kh) / 2,
        ComicFitAlign.bottom => h - kh,
        ComicFitAlign.baseline => above - ascents[i],
      };
      (kids[i].parentData as _FitRowData).offset = Offset(
        _dir == TextDirection.ltr ? x : w - x - ws[i],
        y,
      );
      x += ws[i] + _w.gap;
    }
    size = Size(w, h);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);
  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);
}

/// Columns as wide as their content wants, pushed apart. If they don't all fit, each starts at its longest word and
/// shares what is left, up to what it wants: the one that fits stays on one line, the long ones wrap.
///
/// ```dart
/// ComicAutoRow(children: const [Text('One'), Text('Two')])
/// ```
class ComicAutoRow extends MultiChildRenderObjectWidget {
  /// Creates a [ComicAutoRow].
  const ComicAutoRow({super.key, this.gap = 14, super.children});

  /// Space between adjacent children in logical pixels.
  final double gap;
  @override
  RenderObject createRenderObject(BuildContext context) =>
      RenderComicAutoRow(gap, Directionality.of(context));
  @override
  void updateRenderObject(
    BuildContext context,
    RenderComicAutoRow renderObject,
  ) {
    renderObject
      .._gap = gap
      .._dir = Directionality.of(context)
      ..markNeedsLayout();
  }
}

class _AutoRowData extends ContainerBoxParentData<RenderBox> {}

/// Lays out and paints the [ComicAutoRow] widget.
class RenderComicAutoRow extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _AutoRowData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _AutoRowData> {
  /// Creates a [RenderComicAutoRow].
  RenderComicAutoRow(this._gap, this._dir);
  double _gap;
  TextDirection _dir;
  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _AutoRowData) child.parentData = _AutoRowData();
  }

  double _gaps() => _gap * math.max(childCount - 1, 0);
  List<RenderBox> get _kids => [
    for (var c = firstChild; c != null; c = childAfter(c)) c,
  ];
  @override
  double computeMinIntrinsicWidth(double height) => _kids.fold(
    _gaps(),
    (a, c) => a + c.getMinIntrinsicWidth(double.infinity),
  );
  @override
  double computeMaxIntrinsicWidth(double height) => _kids.fold(
    _gaps(),
    (a, c) => a + c.getMaxIntrinsicWidth(double.infinity),
  );
  @override
  double computeMinIntrinsicHeight(double width) =>
      _kids.fold(0.0, (a, c) => math.max(a, c.getMinIntrinsicHeight(width)));
  @override
  double computeMaxIntrinsicHeight(double width) =>
      computeMinIntrinsicHeight(width);

  @override
  void performLayout() {
    final kids = _kids;
    final w = constraints.maxWidth;
    final lo = [
      for (final c in kids)
        c.getMinIntrinsicWidth(double.infinity).ceilToDouble(),
    ];
    final hi = [
      for (var i = 0; i < kids.length; i++)
        math.max(
          lo[i],
          kids[i].getMaxIntrinsicWidth(double.infinity).ceilToDouble(),
        ),
    ];
    final ws = [...lo];
    var room = w - _gaps() - lo.fold(0.0, (a, b) => a + b);
    // Equal shares, each capped at what the column wants.
    while (room > .01) {
      final open = [
        for (var i = 0; i < ws.length; i++)
          if (hi[i] - ws[i] > .01) i,
      ];
      if (open.isEmpty) break;
      final share = room / open.length;
      for (final i in open) {
        final take = math.min(share, hi[i] - ws[i]);
        ws[i] += take;
        room -= take;
      }
    }
    var h = 0.0;
    for (var i = 0; i < kids.length; i++) {
      kids[i].layout(
        BoxConstraints(minWidth: ws[i], maxWidth: ws[i]),
        parentUsesSize: true,
      );
      h = math.max(h, kids[i].size.height);
    }
    final spare = math.max(0.0, room);
    final between = kids.length > 1 ? spare / (kids.length - 1) + _gap : 0.0;
    var x = 0.0;
    for (var i = 0; i < kids.length; i++) {
      final dx = _dir == TextDirection.ltr ? x : w - x - ws[i];
      (kids[i].parentData as _AutoRowData).offset = Offset(
        dx,
        (h - kids[i].size.height) / 2,
      );
      x += ws[i] + between;
    }
    size = constraints.constrain(Size(w, h));
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);
  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);
}

/// A fixed number of equal columns at every width (chips, date chips, stats), each row sharing its height.
///
/// ```dart
/// ComicGridOf(columns: 2, children: const [Text('One'), Text('Two')])
/// ```
class ComicGridOf extends StatelessWidget {
  /// Creates a [ComicGridOf].
  const ComicGridOf({
    super.key,
    required this.columns,
    required this.children,
    this.gap = 8,
    this.runGap,
  });

  /// The number or specification of columns in the layout.
  final int columns;

  /// Space between adjacent children in logical pixels.
  final double gap;

  /// Space between wrapped rows in logical pixels.
  final double? runGap;

  /// Child widgets in their display order.
  final List<Widget> children;
  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i += columns) {
      final part = children.sublist(i, math.min(i + columns, children.length));
      rows.add(
        ComicEqualRow(
          flex: List.filled(columns, 1),
          gap: gap,
          children: [
            ...part,
            for (var k = part.length; k < columns; k++) const SizedBox.shrink(),
          ],
        ),
      );
    }
    return ComicColumn(gap: runGap ?? gap, children: rows);
  }
}

/// Start and end on one baseline, pushed apart; if they don't fit on a line, end drops under start. CSS flex-wrap with
/// baseline alignment, which Wrap can't do.
///
/// ```dart
/// ComicSplit(start: const Text('Heading'), end: const Text('Detail'))
/// ```
class ComicSplit extends MultiChildRenderObjectWidget {
  /// Creates a [ComicSplit].
  ComicSplit({
    super.key,
    required Widget start,
    required Widget end,
    this.gap = 14,
    this.runGap = 0,
    this.bottoms = false,
  }) : super(children: [start, end]);

  /// [gap]: space between adjacent children in logical pixels. [runGap]: space between wrapped rows in logical pixels.
  final double gap, runGap;

  /// Line up the bottoms of the two instead of their baselines.
  final bool bottoms;
  @override
  RenderObject createRenderObject(BuildContext context) =>
      RenderComicSplit(gap, runGap, Directionality.of(context), bottoms);
  @override
  void updateRenderObject(BuildContext context, RenderComicSplit renderObject) {
    renderObject
      .._gap = gap
      .._runGap = runGap
      .._bottoms = bottoms
      .._dir = Directionality.of(context)
      ..markNeedsLayout();
  }
}

class _SplitData extends ContainerBoxParentData<RenderBox> {}

/// Lays out and paints the [ComicSplit] widget.
class RenderComicSplit extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _SplitData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _SplitData> {
  /// Creates a [RenderComicSplit].
  RenderComicSplit(this._gap, this._runGap, this._dir, this._bottoms);
  double _gap, _runGap;
  TextDirection _dir;
  bool _bottoms;
  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _SplitData) child.parentData = _SplitData();
  }

  @override
  double computeMinIntrinsicWidth(double height) => math.max(
    firstChild!.getMinIntrinsicWidth(height),
    lastChild!.getMinIntrinsicWidth(height),
  );
  @override
  double computeMaxIntrinsicWidth(double height) =>
      firstChild!.getMaxIntrinsicWidth(height) +
      _gap +
      lastChild!.getMaxIntrinsicWidth(height);
  @override
  double computeMinIntrinsicHeight(double width) =>
      firstChild!.getMinIntrinsicHeight(width) +
      lastChild!.getMinIntrinsicHeight(width);
  @override
  double computeMaxIntrinsicHeight(double width) =>
      computeMinIntrinsicHeight(width);

  @override
  void performLayout() {
    final w = constraints.maxWidth;
    final a = firstChild!, b = lastChild!;
    final loose = BoxConstraints(maxWidth: w);
    a.layout(loose, parentUsesSize: true);
    b.layout(loose, parentUsesSize: true);
    final ad = a.parentData as _SplitData, bd = b.parentData as _SplitData;
    double h;
    if (a.size.width + _gap + b.size.width <= w) {
      final ab = _bottoms
          ? a.size.height
          : a.getDistanceToBaseline(TextBaseline.alphabetic) ?? a.size.height;
      final bb = _bottoms
          ? b.size.height
          : b.getDistanceToBaseline(TextBaseline.alphabetic) ?? b.size.height;
      final base = math.max(ab, bb);
      final ltr = _dir == TextDirection.ltr;
      ad.offset = Offset(ltr ? 0 : w - a.size.width, base - ab);
      bd.offset = Offset(ltr ? w - b.size.width : 0, base - bb);
      h = math.max(ad.offset.dy + a.size.height, bd.offset.dy + b.size.height);
    } else {
      final ltr = _dir == TextDirection.ltr;
      ad.offset = Offset(ltr ? 0 : w - a.size.width, 0);
      bd.offset = Offset(ltr ? 0 : w - b.size.width, a.size.height + _runGap);
      h = a.size.height + _runGap + b.size.height;
    }
    size = constraints.constrain(Size(w, h));
  }

  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) =>
      defaultComputeDistanceToFirstActualBaseline(baseline);
  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);
  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);
}

/// `text-wrap: balance`: finds the narrowest width that keeps the same number of lines, so no line ends alone. The
/// balanced box stands where [textAlign] says: in the middle by default, at the start for a start-aligned paragraph.
///
/// ```dart
/// ComicBalancedText('A balanced headline', style: ComicTheme.of(context).type.title)
/// ```
class ComicBalancedText extends StatelessWidget {
  /// Creates a [ComicBalancedText].
  const ComicBalancedText(
    this.text, {
    super.key,
    required this.style,
    this.textAlign = TextAlign.center,
  });

  /// The text rendered by this object.
  final String text;

  /// The visual treatment supplied by the caller.
  final TextStyle style;

  /// How text aligns within its line box.
  final TextAlign textAlign;
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final dir = Directionality.of(context);
        final tp = TextPainter(
          text: TextSpan(text: text, style: style),
          textDirection: dir,
          textScaler: MediaQuery.textScalerOf(context),
        )..layout(maxWidth: c.maxWidth);
        final lines = tp.computeLineMetrics().length;
        // Blink stops balancing past six lines; a long paragraph reads better set plainly.
        if (lines > 6) {
          tp.dispose();
          return Text(text, style: style, textAlign: textAlign);
        }
        var lo = 0.0, hi = c.maxWidth;
        for (var i = 0; i < 12 && hi - lo > 1; i++) {
          final mid = (lo + hi) / 2;
          tp.layout(maxWidth: mid);
          if (tp.computeLineMetrics().length > lines) {
            lo = mid;
          } else {
            hi = mid;
          }
        }
        tp.dispose();
        // The balanced box stands where its lines align: a start-aligned paragraph starts at the start, under its
        // title, rather than floating in the middle.
        return Align(
          alignment: switch (textAlign) {
            TextAlign.start ||
            TextAlign.justify => AlignmentDirectional.centerStart,
            TextAlign.end => AlignmentDirectional.centerEnd,
            TextAlign.left => Alignment.centerLeft,
            TextAlign.right => Alignment.centerRight,
            TextAlign.center => Alignment.center,
          },
          child: SizedBox(
            width: math.min(hi.ceilToDouble() + 1, c.maxWidth),
            child: Text(text, style: style, textAlign: textAlign),
          ),
        );
      },
    );
  }
}

/// The width of the widest word of [text] in [style] at [textScaler] (pass the context's, `MediaQuery.textScalerOf`):
/// below it, Flutter breaks a word in two.
double comicWidestWord(
  String text,
  TextStyle style, {
  TextScaler textScaler = TextScaler.noScaling,
}) {
  var widest = 0.0;
  for (final word in text.split(RegExp(r'[\s/-]+'))) {
    if (word.isEmpty) continue;
    final tp = TextPainter(
      text: TextSpan(text: word, style: style),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      textScaler: textScaler,
    )..layout();
    if (tp.width > widest) widest = tp.width;
    tp.dispose();
  }
  return widest;
}

/// An object beside its words: a portrait, a mark, a small chart or picture. The object keeps its size up to
/// [maxObject] of the width; the words take the rest. If the words would get under [minWords], they go under the
/// object instead, so a column never crushes to a letter a line. Never write this as a `Row` with an `Expanded`.
///
/// ```dart
/// ComicBeside(object: ComicPerson(initials: 'AB'), child: ComicKvRow('Issue', '12', isFirst: true))
/// ```
class ComicBeside extends MultiChildRenderObjectWidget {
  /// Creates a [ComicBeside].
  ComicBeside({
    super.key,
    required Widget object,
    required Widget child,
    this.gap = 16,
    this.minWords = 140,
    this.maxObject = .42,
    this.objectAtEnd = false,
  }) : super(children: [object, child]);

  /// [gap]: space between adjacent children in logical pixels. [minWords]: the minimum width kept for the words before reflowing. [maxObject]: the maximum width reserved for the object beside its words.
  final double gap, minWords, maxObject;

  /// The object after the words, not before them.
  final bool objectAtEnd;
  @override
  RenderObject createRenderObject(BuildContext context) => RenderComicBeside(
    gap,
    minWords,
    maxObject,
    objectAtEnd,
    Directionality.of(context),
  );
  @override
  void updateRenderObject(
    BuildContext context,
    RenderComicBeside renderObject,
  ) {
    renderObject
      .._gap = gap
      .._minWords = minWords
      .._maxObject = maxObject
      .._atEnd = objectAtEnd
      .._dir = Directionality.of(context)
      ..markNeedsLayout();
  }
}

class _BesideData extends ContainerBoxParentData<RenderBox> {}

/// Lays out and paints the [ComicBeside] widget.
class RenderComicBeside extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _BesideData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _BesideData> {
  /// Creates a [RenderComicBeside].
  RenderComicBeside(
    this._gap,
    this._minWords,
    this._maxObject,
    this._atEnd,
    this._dir,
  );
  double _gap, _minWords, _maxObject;
  bool _atEnd;
  TextDirection _dir;
  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _BesideData) child.parentData = _BesideData();
  }

  @override
  void performLayout() {
    final w = constraints.hasBoundedWidth ? constraints.maxWidth : 390.0;
    final object = firstChild!, words = lastChild!;
    object.layout(
      BoxConstraints(maxWidth: math.min(240, math.max(88, w * _maxObject))),
      parentUsesSize: true,
    );
    final od = object.parentData as _BesideData;
    final wd = words.parentData as _BesideData;
    final ltr = _dir == TextDirection.ltr;
    final rest = w - object.size.width - _gap;
    if (rest < _minWords) {
      words.layout(BoxConstraints(maxWidth: w), parentUsesSize: true);
      od.offset = Offset(ltr ? 0 : w - object.size.width, 0);
      wd.offset = Offset(
        ltr ? 0 : w - words.size.width,
        object.size.height + 12,
      );
      size = constraints.constrain(
        Size(w, object.size.height + 12 + words.size.height),
      );
      return;
    }
    words.layout(
      BoxConstraints(minWidth: rest, maxWidth: rest),
      parentUsesSize: true,
    );
    final h = math.max(object.size.height, words.size.height);
    final objectFirst = ltr != _atEnd;
    od.offset = Offset(
      objectFirst ? 0 : w - object.size.width,
      (h - object.size.height) / 2,
    );
    wd.offset = Offset(
      objectFirst ? object.size.width + _gap : 0,
      (h - words.size.height) / 2,
    );
    size = constraints.constrain(Size(w, h));
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);
  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);
}
