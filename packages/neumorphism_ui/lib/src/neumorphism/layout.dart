// Layout: the 12-column grid and a column whose rows take up the slack. Cards in a row share a height and their lists
// grow, so no card ends in a hole. Neither needs IntrinsicHeight, and neither crashes under a scroll view.
import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import 'chrome_metrics.dart';
import 'theme.dart';

/// A part with its own size keeps it, whatever its parent asks. A stretching Column or Row hands tight constraints, which a
/// SizedBox can't refuse: a paint that reads its declared size and a `Center` that reads the real width come apart. Here the
/// part stands at [alignment] in the room (the start edge unless it is centred by design: left in LTR, mirrored in RTL) and,
/// if the room is smaller than the part, scales down whole. Give one side, or none, for a part whose other side follows its
/// content.
Widget neumorphicOwnSize({
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
/// NeumorphicFill(maxWidth: 640, child: Text('A bounded column'))
/// ```
class NeumorphicFill extends SingleChildRenderObjectWidget {
  /// Creates a [NeumorphicFill].
  const NeumorphicFill({
    super.key,
    required this.maxWidth,
    this.aspect,
    this.loneWidth = 240,
    this.alignment = Alignment.topCenter,
    required Widget super.child,
  });

  /// The maximum width allowed for this child.
  final double maxWidth;

  /// An optional width-to-height ratio.
  final double? aspect;

  /// The fallback width when the parent offers no bounded width.
  final double loneWidth;

  /// Where the part stands in a room wider than [maxWidth]: the middle by default (a hero), the start for a part that
  /// follows its heading (a chart).
  final AlignmentGeometry alignment;
  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderNeumorphicFill(
        maxWidth,
        aspect,
        loneWidth,
        alignment,
        Directionality.maybeOf(context),
      );
  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    (renderObject as _RenderNeumorphicFill)
      ..limit = maxWidth
      ..aspect = aspect
      ..lone = loneWidth
      ..alignment = alignment
      ..textDirection = Directionality.maybeOf(context);
  }
}

class _RenderNeumorphicFill extends RenderAligningShiftedBox {
  _RenderNeumorphicFill(
    this._limit,
    this._aspect,
    this._lone,
    AlignmentGeometry alignment,
    TextDirection? textDirection,
  ) : super(alignment: alignment, textDirection: textDirection);
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

/// Marks a child of a `NeumorphicColumn` as taking a share of the slack (CSS `flex: 1`).
///
/// ```dart
/// NeumorphicColumn(children: [NeumorphicGrow(child: Text('Fills spare height'))])
/// ```
class NeumorphicGrow extends ParentDataWidget<_NeumorphicColumnData> {
  /// Creates a [NeumorphicGrow].
  const NeumorphicGrow({super.key, required super.child});
  @override
  void applyParentData(RenderObject renderObject) {
    final d = renderObject.parentData as _NeumorphicColumnData;
    if (!d.grow) {
      d.grow = true;
      renderObject.parent?.markNeedsLayout();
    }
  }

  @override
  Type get debugTypicalAncestorWidgetClass => NeumorphicColumn;
}

class _NeumorphicColumnData extends ContainerBoxParentData<RenderBox> {
  bool grow = false;
}

/// A column that is safe everywhere. Children stretch to its width. Under a bounded height (a card in a `NeumorphicRow` on a
/// desktop) the `NeumorphicGrow` children share the slack evenly, floored at their own height; under a scroll view they just
/// take their own height. Use it in place of Column + Expanded inside any card.
///
/// ```dart
/// NeumorphicColumn(gap: 16, children: [Text('First'), Text('Second')])
/// ```
class NeumorphicColumn extends MultiChildRenderObjectWidget {
  /// Creates a [NeumorphicColumn].
  const NeumorphicColumn({
    super.key,
    super.children,
    this.gap = 0,
    this.spineX,
    this.spineColor,
  });

  /// Space between children.
  final double gap;

  /// If set, a 1 px rule runs from the centre of the first child to the centre of the last, at this x from the start
  /// edge: the shaft through a list of medallions.
  final double? spineX;

  /// The colour of the optional connecting spine.
  final Color? spineColor;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      RenderNeumorphicColumn(
        gap,
        spineX,
        spineColor,
        Directionality.of(context),
      );
  @override
  void updateRenderObject(
    BuildContext context,
    RenderNeumorphicColumn renderObject,
  ) {
    renderObject
      ..gap = gap
      ..spineX = spineX
      ..spineColor = spineColor
      ..dir = Directionality.of(context);
  }
}

/// The render layout used by [NeumorphicColumn].
class RenderNeumorphicColumn extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _NeumorphicColumnData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _NeumorphicColumnData> {
  /// Creates the render layout with its initial configuration.
  RenderNeumorphicColumn(this._gap, this._spineX, this._spineColor, this._dir);
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
    if (child.parentData is! _NeumorphicColumnData) {
      child.parentData = _NeumorphicColumnData();
    }
  }

  double _gaps() => _gap * math.max(childCount - 1, 0);

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
    var h = _gaps();
    for (var c = firstChild; c != null; c = childAfter(c)) {
      h += c.getMinIntrinsicHeight(width);
    }
    return h;
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
    final hs = <RenderBox, double>{};
    var total = _gaps();
    for (var c = firstChild; c != null; c = childAfter(c)) {
      c.layout(natural, parentUsesSize: true);
      hs[c] = c.size.height;
      total += c.size.height;
    }
    var height = total;
    final target = constraints.hasBoundedHeight
        ? constraints.maxHeight
        : math.max(total, constraints.minHeight);
    final growers = [
      for (var c = firstChild; c != null; c = childAfter(c))
        if ((c.parentData as _NeumorphicColumnData).grow) c,
    ];
    if (target > total && growers.isNotEmpty) {
      height = target;
      // CSS flex: 1 with min-height auto: an even share, floored at each child's own height.
      var room = target - _gaps();
      for (var c = firstChild; c != null; c = childAfter(c)) {
        if (!(c.parentData as _NeumorphicColumnData).grow) room -= hs[c]!;
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
    for (var c = firstChild; c != null; c = childAfter(c)) {
      (c.parentData as _NeumorphicColumnData).offset = Offset(
        0,
        y.roundToDouble(),
      );
      y += c.size.height + _gap;
    }
    size = constraints.constrain(Size(w, height.roundToDouble()));
  }

  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) =>
      defaultComputeDistanceToFirstActualBaseline(baseline);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);

  /// A press up to half a target past either side still asks the children: a face on the column's keyline keeps its
  /// target's margin past it ([NeumorphicFaceEdge]), and only a child that reaches there takes the press.
  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (size.contains(position)) {
      return super.hitTest(result, position: position);
    }
    final reach = NeumorphicChromeMetrics.targetSize / 2;
    if (position.dy < 0 ||
        position.dy >= size.height ||
        position.dx < -reach ||
        position.dx >= size.width + reach ||
        !hitTestChildren(result, position: position)) {
      return false;
    }
    result.add(BoxHitTestEntry(this, position));
    return true;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (_spineX != null && _spineColor != null && firstChild != null) {
      final first = firstChild!, last = lastChild!;
      final y0 =
          (first.parentData as _NeumorphicColumnData).offset.dy +
          first.size.height / 2;
      final y1 =
          (last.parentData as _NeumorphicColumnData).offset.dy +
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
/// then given the row's height, so a card can hold anything, and `NeumorphicGrow` lists inside take up the slack.
///
/// ```dart
/// NeumorphicEqualRow(flex: [1, 1], gap: 12, children: [Text('Left'), Text('Right')])
/// ```
class NeumorphicEqualRow extends MultiChildRenderObjectWidget {
  /// Creates a [NeumorphicEqualRow].
  const NeumorphicEqualRow({
    super.key,
    required this.flex,
    this.gap = 0,
    this.columns,
    super.children,
  });

  /// Relative weights used to share the available row width.
  final List<int> flex;

  /// Space between adjacent children, in logical pixels.
  final double gap;

  /// When set, `flex` counts columns of a grid of that many columns, so a span also takes the gutters it crosses.
  final int? columns;
  @override
  RenderObject createRenderObject(BuildContext context) =>
      RenderNeumorphicEqualRow(flex, gap, Directionality.of(context), columns);
  @override
  void updateRenderObject(
    BuildContext context,
    RenderNeumorphicEqualRow renderObject,
  ) {
    renderObject
      ..flex = flex
      ..gap = gap
      ..columns = columns
      ..dir = Directionality.of(context);
  }
}

class _EqualRowData extends ContainerBoxParentData<RenderBox> {}

/// The render layout used by [NeumorphicEqualRow].
class RenderNeumorphicEqualRow extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _EqualRowData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _EqualRowData> {
  /// Creates the render layout with its initial configuration.
  RenderNeumorphicEqualRow(this._flex, this._gap, this._dir, this._columns);
  List<int> _flex;
  double _gap;
  TextDirection _dir;
  int? _columns;
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
      lefts.add(a);
      ws.add(b - a);
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
    for (var c = firstChild; c != null; c = childAfter(c)) {
      final cw = ws[i];
      if (c.size.height != h) {
        c.layout(
          BoxConstraints.tightFor(width: cw, height: h),
          parentUsesSize: true,
        );
      }
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

/// A row on the 12-column grid: `NeumorphicRow(spans: [7, 5], children: [a, b])`. From 1024 wide the sections sit side by side
/// and share a height, with 28 gutters, the air a soft shadow needs. Below that they stack with 28 between. It is the only
/// layout decision a page makes. Spans are shares of the row: [6, 6] and [1, 1] are both halves, and the row is always
/// filled.
///
/// ```dart
/// NeumorphicRow(spans: [8, 4], children: [Text('Main'), Text('Aside')])
/// ```
class NeumorphicRow extends StatelessWidget {
  /// Creates a [NeumorphicRow].
  const NeumorphicRow({super.key, required this.spans, required this.children});

  /// Each child's share of the row, in columns of the 12-column grid when they add up to 12; a child without one takes 1.
  final List<int> spans;

  /// The content widgets, in reading order.
  final List<Widget> children;
  @override
  Widget build(BuildContext context) {
    if (!NeumorphicTheme.of(context).desk) {
      return NeumorphicColumn(gap: 28, children: children);
    }
    final shares = [
      for (var i = 0; i < children.length; i++)
        i < spans.length ? math.max(0, spans[i]) : 1,
    ];
    return NeumorphicEqualRow(
      flex: shares,
      gap: 28,
      // A grid of as many columns as the spans add up to, so a span crosses its gutters and the row is filled.
      columns: math.max(1, shares.fold(0, (a, b) => a + b)),
      // Side by side, each section is a column of its own keylines: a page's halves don't share a row.
      children: [
        for (final child in children)
          DesignKeylineRegion(label: 'column', child: child),
      ],
    );
  }
}

/// How fitted row children align vertically.
enum NeumorphicFitAlign {
  /// Align child centres.
  center,

  /// Align text baselines where available.
  baseline,

  /// Align bottom edges.
  bottom,
}

/// A row that can't overflow, and works inside a plain `Row`. One child, `fill`, takes what is left; the others keep
/// their natural width, measured last to first, each leaving at least `fillMin` (or `fillShare` of the row) for it.
/// `shrink` makes the row only as wide as its content, for a mark and a label.
///
/// ```dart
/// NeumorphicFitRow(fill: 1, children: [Icon(NeumorphicGlyphs.house), Text('The flexible label')])
/// ```
class NeumorphicFitRow extends MultiChildRenderObjectWidget {
  /// Creates a [NeumorphicFitRow].
  const NeumorphicFitRow({
    super.key,
    required this.fill,
    this.gap = 8,
    this.align = NeumorphicFitAlign.center,
    this.shrink = false,
    this.fillMin = 0,
    this.fillShare = 0,
    super.children,
  });

  /// The index of the flexible child.
  final int fill;

  /// Space between adjacent children, in logical pixels.
  final double gap;

  /// The minimum width reserved for the flexible child.
  final double fillMin;

  /// The preferred fraction of width given to the flexible child.
  final double fillShare;

  /// How the children align on the cross axis.
  final NeumorphicFitAlign align;

  /// Whether the row hugs its children when room remains.
  final bool shrink;
  @override
  RenderObject createRenderObject(BuildContext context) =>
      RenderNeumorphicFitRow(this, Directionality.of(context));
  @override
  void updateRenderObject(
    BuildContext context,
    RenderNeumorphicFitRow renderObject,
  ) {
    renderObject
      .._w = this
      .._dir = Directionality.of(context)
      ..markNeedsLayout();
  }
}

class _FitRowData extends ContainerBoxParentData<RenderBox> {}

/// The render layout used by [NeumorphicFitRow].
class RenderNeumorphicFitRow extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _FitRowData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _FitRowData> {
  /// Creates the render layout with its initial configuration.
  RenderNeumorphicFitRow(this._w, this._dir);
  NeumorphicFitRow _w;
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
    final reserve = bounded ? math.max(_w.fillMin, _w.fillShare * total) : 0.0;
    var room = bounded ? total - _gaps() : double.infinity;
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
      if (_w.align == NeumorphicFitAlign.baseline) {
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
      _w.align == NeumorphicFitAlign.baseline ? above + below : tallest,
    );
    var x = 0.0;
    for (var i = 0; i < kids.length; i++) {
      final kh = kids[i].size.height;
      final y = switch (_w.align) {
        NeumorphicFitAlign.center => (h - kh) / 2,
        NeumorphicFitAlign.bottom => h - kh,
        NeumorphicFitAlign.baseline => above - ascents[i],
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
/// NeumorphicAutoRow(children: [Text('First'), Text('Second')])
/// ```
class NeumorphicAutoRow extends MultiChildRenderObjectWidget {
  /// Creates a [NeumorphicAutoRow].
  const NeumorphicAutoRow({super.key, this.gap = 14, super.children});

  /// Space between adjacent children, in logical pixels.
  final double gap;
  @override
  RenderObject createRenderObject(BuildContext context) =>
      RenderNeumorphicAutoRow(gap, Directionality.of(context));
  @override
  void updateRenderObject(
    BuildContext context,
    RenderNeumorphicAutoRow renderObject,
  ) {
    renderObject
      .._gap = gap
      .._dir = Directionality.of(context)
      ..markNeedsLayout();
  }
}

class _AutoRowData extends ContainerBoxParentData<RenderBox> {}

/// The render layout used by [NeumorphicAutoRow].
class RenderNeumorphicAutoRow extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _AutoRowData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _AutoRowData> {
  /// Creates the render layout with its initial configuration.
  RenderNeumorphicAutoRow(this._gap, this._dir);
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
    // Words on their first line's baseline, as a label stands beside its value: centred, a one-line label stood
    // halfway down a value wrapped over five lines. Columns with no words are centred.
    final baselines = [
      for (final kid in kids)
        kid.getDistanceToBaseline(TextBaseline.alphabetic, onlyReal: true),
    ];
    final lined = baselines.every((b) => b != null);
    final top = baselines.fold<double>(0, (a, b) => math.max(a, b ?? 0));
    if (lined) {
      h = 0;
      for (var i = 0; i < kids.length; i++) {
        h = math.max(h, top - baselines[i]! + kids[i].size.height);
      }
    }
    final spare = math.max(0.0, room);
    final between = kids.length > 1 ? spare / (kids.length - 1) + _gap : 0.0;
    var x = 0.0;
    for (var i = 0; i < kids.length; i++) {
      final dx = _dir == TextDirection.ltr ? x : w - x - ws[i];
      (kids[i].parentData as _AutoRowData).offset = Offset(
        dx,
        lined ? top - baselines[i]! : (h - kids[i].size.height) / 2,
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
/// NeumorphicGridOf(columns: 2, children: [Text('First'), Text('Second')])
/// ```
class NeumorphicGridOf extends StatelessWidget {
  /// Creates a [NeumorphicGridOf].
  const NeumorphicGridOf({
    super.key,
    required this.columns,
    required this.children,
    this.gap = 8,
    this.runGap,
  });

  /// The number of columns in the grid.
  final int columns;

  /// Space between adjacent children, in logical pixels.
  final double gap;

  /// Space between wrapped rows, in logical pixels.
  final double? runGap;

  /// The content widgets, in reading order.
  final List<Widget> children;
  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i += columns) {
      final part = children.sublist(i, math.min(i + columns, children.length));
      rows.add(
        NeumorphicEqualRow(
          flex: List.filled(columns, 1),
          gap: gap,
          children: [
            ...part,
            for (var k = part.length; k < columns; k++) const SizedBox.shrink(),
          ],
        ),
      );
    }
    return NeumorphicColumn(gap: runGap ?? gap, children: rows);
  }
}

/// Start and end on one baseline, pushed apart; if they don't fit on a line, end drops under start. CSS flex-wrap with
/// baseline alignment, which Wrap can't do.
///
/// ```dart
/// NeumorphicSplit(start: Text('Title'), end: Text('Details'))
/// ```
class NeumorphicSplit extends MultiChildRenderObjectWidget {
  /// Creates a [NeumorphicSplit].
  NeumorphicSplit({
    super.key,
    required Widget start,
    required Widget end,
    this.gap = 14,
    this.runGap = 0,
    this.bottoms = false,
  }) : super(children: [start, end]);

  /// Space between adjacent children, in logical pixels.
  final double gap;

  /// Space between wrapped rows, in logical pixels.
  final double runGap;

  /// Line up the bottoms of the two instead of their baselines.
  final bool bottoms;
  @override
  RenderObject createRenderObject(BuildContext context) =>
      RenderNeumorphicSplit(gap, runGap, Directionality.of(context), bottoms);
  @override
  void updateRenderObject(
    BuildContext context,
    RenderNeumorphicSplit renderObject,
  ) {
    renderObject
      .._gap = gap
      .._runGap = runGap
      .._bottoms = bottoms
      .._dir = Directionality.of(context)
      ..markNeedsLayout();
  }
}

class _SplitData extends ContainerBoxParentData<RenderBox> {}

/// The render layout used by [NeumorphicSplit].
class RenderNeumorphicSplit extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _SplitData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _SplitData> {
  /// Creates the render layout with its initial configuration.
  RenderNeumorphicSplit(this._gap, this._runGap, this._dir, this._bottoms);
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

/// `text-wrap: balance`: finds the narrowest width that keeps the same number of lines, so no line ends alone.
///
/// ```dart
/// NeumorphicBalancedText('A balanced heading', style: TextStyle(fontSize: 24))
/// ```
class NeumorphicBalancedText extends StatelessWidget {
  /// Creates a [NeumorphicBalancedText].
  const NeumorphicBalancedText(
    this.text, {
    super.key,
    required this.style,
    this.textAlign = TextAlign.center,
  });

  /// The text to display.
  final String text;

  /// The text style used to draw the words.
  final TextStyle style;

  /// The horizontal alignment of the words.
  final TextAlign textAlign;
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final dir = Directionality.of(context);
        // Measured as the Text below draws: in the inherited family and at the text scale. Measured in the bare
        // style (another face, no scale) a heading two lines long measured one, and its last word hung alone.
        final resolved = DefaultTextStyle.of(context).style.merge(style);
        final tp = TextPainter(
          text: TextSpan(text: text, style: resolved),
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
        // The balanced block stands where its words align: centred words in the middle, start words at the start.
        return Align(
          heightFactor: 1,
          alignment: switch (textAlign) {
            TextAlign.center => Alignment.center,
            TextAlign.end => AlignmentDirectional.centerEnd,
            TextAlign.right => Alignment.centerRight,
            TextAlign.left => Alignment.centerLeft,
            _ => AlignmentDirectional.centerStart,
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

/// The width of the widest word of [text] in [style]: below it, Flutter breaks a word in two.
double neumorphicWidestWord(
  String text,
  TextStyle style, {
  TextScaler textScaler = TextScaler.noScaling,
}) {
  var widest = 0.0;
  for (final word in text.split(RegExp(r'[\s/-]+'))) {
    if (word.isEmpty) continue;
    final tp = TextPainter(
      text: TextSpan(text: word, style: style),
      textScaler: textScaler,
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    if (tp.width > widest) widest = tp.width;
    tp.dispose();
  }
  return widest;
}

/// An object beside its words: a fob, a medal, a vault, a small chart or picture. The object keeps its size up to
/// [maxObject] of the width; the words take the rest. If the words would get under [minWords], they go under the
/// object instead, so a column never crushes to a letter a line. Never write this as a `Row` with an `Expanded`.
///
/// ```dart
/// NeumorphicBeside(object: NeumorphicMonogram('AB'), child: NeumorphicKvRow('A word', 'A value', isFirst: true))
/// ```
class NeumorphicBeside extends MultiChildRenderObjectWidget {
  /// Creates a [NeumorphicBeside].
  NeumorphicBeside({
    super.key,
    required Widget object,
    required Widget child,
    this.gap = 16,
    this.minWords = 140,
    this.maxObject = .42,
    this.objectAtEnd = false,
  }) : super(children: [object, child]);

  /// Space between adjacent children, in logical pixels.
  final double gap;

  /// The minimum width reserved for the text column.
  final double minWords;

  /// The maximum fraction of width reserved for the object.
  final double maxObject;

  /// The object after the words, not before them.
  final bool objectAtEnd;
  @override
  RenderObject createRenderObject(BuildContext context) =>
      RenderNeumorphicBeside(
        gap,
        minWords,
        maxObject,
        objectAtEnd,
        Directionality.of(context),
      );
  @override
  void updateRenderObject(
    BuildContext context,
    RenderNeumorphicBeside renderObject,
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

/// The render layout used by [NeumorphicBeside].
class RenderNeumorphicBeside extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _BesideData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _BesideData> {
  /// Creates the render layout with its initial configuration.
  RenderNeumorphicBeside(
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
