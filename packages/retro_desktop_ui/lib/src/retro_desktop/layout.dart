// Layout: the 12-column grid and a column whose rows take up the slack. Cards in a row share a height and their lists
// grow, so no card ends in a hole. Neither needs IntrinsicHeight, and neither crashes under a scroll view.
import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'theme.dart';
import 'chrome_metrics.dart';

/// The least a control reaches to a finger on a phone, each way.
const retroDesktopReach = RetroDesktopChromeMetrics.touchTarget;

/// A control's reach: on a phone at least [retroDesktopReach] by [retroDesktopReach] to a finger, its drawing unchanged at
/// [alignment] in it (the middle, unless the drawing must keep an edge where it was), as a padded tap target is on a touch
/// screen; on a desk, at least 44 logical pixels high, and as wide as the drawing, so a face starts where its column does:
/// the reach past its sides is only pressed, never laid out, and gives way to another control's face. A control [inside]
/// another's face (a field's eye or clear button) is only pressed past its drawing both ways on a desk, so it never makes
/// the field taller. A press anywhere in the reach lands on the drawing. The width a stretching parent gives passes
/// through, so a control that fills its row still does. Not exported: the controls wear it themselves.
///
/// ```dart
/// RetroDesktopReach(child: const Text('Reachable control'))
/// ```
class RetroDesktopReach extends SingleChildRenderObjectWidget {
  /// Creates a [RetroDesktopReach].
  const RetroDesktopReach({
    super.key,
    this.alignment = Alignment.center,
    this.inside = false,
    super.child,
  });

  /// Where the content sits within its available space.
  final AlignmentGeometry alignment;

  /// Whether the control stands inside another's face: on a desk its reach is only pressed, down as well as across.
  final bool inside;

  /// The minimum extent in logical pixels.
  static double least(BuildContext context) =>
      RetroDesktopChromeMetrics.targetOf(context);

  /// Whether the reach is laid out across as well as down: on a touch screen, where Flutter's tap-target guidelines read
  /// a target by its box (as a padded Material target is); on a desk the face keeps its own width.
  static bool padsAcross(BuildContext context) =>
      least(context) >= RetroDesktopChromeMetrics.touchTarget;
  @override
  RenderRetroDesktopReach createRenderObject(BuildContext context) =>
      RenderRetroDesktopReach(
        least(context),
        alignment.resolve(Directionality.maybeOf(context)),
        padsAcross(context),
        inside,
      );
  @override
  void updateRenderObject(
    BuildContext context,
    RenderRetroDesktopReach renderObject,
  ) => renderObject
    ..least = least(context)
    ..across = padsAcross(context)
    ..inside = inside
    ..alignment = alignment.resolve(Directionality.maybeOf(context));
}

/// Render object used by the corresponding desktop layout widget.
class RenderRetroDesktopReach extends RenderShiftedBox {
  /// Creates a [RenderRetroDesktopReach].
  RenderRetroDesktopReach(
    this._least,
    this._alignment, [
    this._across = true,
    this._inside = false,
  ]) : super(null);
  double _least;
  set least(double v) {
    if (v == _least) return;
    _least = v;
    markNeedsLayout();
  }

  bool _across;
  set across(bool v) {
    if (v == _across) return;
    _across = v;
    markNeedsLayout();
  }

  bool _inside;
  set inside(bool v) {
    if (v == _inside) return;
    _inside = v;
    markNeedsLayout();
  }

  Alignment _alignment;
  set alignment(Alignment v) {
    if (v == _alignment) return;
    _alignment = v;
    markNeedsLayout();
  }

  // Every reach on screen: a press in one's reach past its face gives way to another's face there.
  static final Set<RenderRetroDesktopReach> _all = {};

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _all.add(this);
  }

  @override
  void detach() {
    _all.remove(this);
    super.detach();
  }

  // What is laid out: across only on a touch screen; down unless the control stands inside another's face on a desk.
  double get _leastAcross => _across ? _least : 0;
  double get _leastDown => _inside && !_across ? 0 : _least;

  BoxConstraints _inner(BoxConstraints c) => c.copyWith(minHeight: 0);
  Size _outer(BoxConstraints c, Size inner) => c.constrain(
    Size(
      math.max(inner.width, _leastAcross),
      math.max(inner.height, _leastDown),
    ),
  );

  @override
  double computeMinIntrinsicWidth(double height) =>
      math.max(super.computeMinIntrinsicWidth(height), _leastAcross);
  @override
  double computeMaxIntrinsicWidth(double height) =>
      math.max(super.computeMaxIntrinsicWidth(height), _leastAcross);
  @override
  double computeMinIntrinsicHeight(double width) =>
      math.max(super.computeMinIntrinsicHeight(width), _leastDown);
  @override
  double computeMaxIntrinsicHeight(double width) =>
      math.max(super.computeMaxIntrinsicHeight(width), _leastDown);

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final kid = child;
    if (kid == null) {
      return constraints.constrain(Size(_leastAcross, _leastDown));
    }
    return _outer(constraints, kid.getDryLayout(_inner(constraints)));
  }

  @override
  void performLayout() {
    final kid = child;
    if (kid == null) {
      size = constraints.constrain(Size(_leastAcross, _leastDown));
      return;
    }
    kid.layout(_inner(constraints), parentUsesSize: true);
    size = _outer(constraints, kid.size);
    final at = _alignment.alongOffset(size - kid.size as Offset);
    (kid.parentData! as BoxParentData).offset = Offset(
      at.dx.roundToDouble(),
      at.dy.roundToDouble(),
    );
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    final kid = child;
    if (kid == null || !kid.hasSize || kid.size.isEmpty) return false;
    final at = (kid.parentData! as BoxParentData).offset;
    // Anywhere in the reach presses the drawing: the nearest point on it.
    final on = Offset(
      position.dx.clamp(at.dx, at.dx + kid.size.width - .01),
      position.dy.clamp(at.dy, at.dy + kid.size.height - .01),
    );
    return result.addWithPaintOffset(
      offset: at,
      position: on,
      hitTest: (result, p) => kid.hitTest(result, position: p),
    );
  }

  // On a desk the reach past a narrow face is pressed, not laid out: a press up to half the shortfall from [_least]
  // beyond either side (and, inside another's face, above or below) lands on the face, unless another control's face is
  // there. A parent's box still bounds what reaches this (a face on its column's edge reaches inward only).
  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (size.contains(position)) {
      return super.hitTest(result, position: position);
    }
    if (_across) return false;
    final across = math.max(0.0, (_least - size.width) / 2);
    final down = _inside ? math.max(0.0, (_least - size.height) / 2) : 0.0;
    if (position.dx < -across ||
        position.dx >= size.width + across ||
        position.dy < -down ||
        position.dy >= size.height + down ||
        _onAnotherFace(position) ||
        !hitTestChildren(result, position: position)) {
      return false;
    }
    result.add(BoxHitTestEntry(this, position));
    return true;
  }

  // Whether [position] lies on another control's face: one that neither holds this one nor is held by it (a field's
  // reach holds its eye's).
  bool _onAnotherFace(Offset position) {
    final at = localToGlobal(position);
    final around = <RenderObject>{};
    for (RenderObject? up = parent; up != null; up = up.parent) {
      around.add(up);
    }
    for (final other in _all) {
      if (identical(other, this) ||
          !other.attached ||
          !other.hasSize ||
          around.contains(other)) {
        continue;
      }
      final face = MatrixUtils.transformRect(
        other.getTransformTo(null),
        Offset.zero & other.size,
      );
      if (!face.contains(at)) continue;
      var held = false;
      for (RenderObject? up = other.parent; up != null; up = up.parent) {
        if (identical(up, this)) {
          held = true;
          break;
        }
      }
      if (!held) return true;
    }
    return false;
  }
}

/// A part with its own size keeps it, whatever its parent asks. A stretching Column or Row hands tight constraints, which a
/// SizedBox can't refuse: a paint that reads its declared size and a `Center` that reads the real width come apart. Here the
/// part stands at [alignment] in the room (the start edge unless it is centred by design: left in LTR, mirrored in RTL) and,
/// if the room is smaller than the part, scales down whole. Give one side, or none, for a part whose other side follows its
/// content.
Widget retroDesktopOwnSize({
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
/// RetroDesktopFill(maxWidth: 480, child: const Text('Readable content'))
/// ```
class RetroDesktopFill extends SingleChildRenderObjectWidget {
  /// Creates a [RetroDesktopFill].
  const RetroDesktopFill({
    super.key,
    required this.maxWidth,
    this.aspect,
    this.loneWidth = 240,
    required Widget super.child,
  });

  /// The maximum width in logical pixels.
  final double maxWidth;

  /// The width-to-height ratio of the content.
  final double? aspect;

  /// The width used when the parent does not bound this part.
  final double loneWidth;
  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderRetroDesktopFill(maxWidth, aspect, loneWidth);
  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    (renderObject as _RenderRetroDesktopFill)
      ..limit = maxWidth
      ..aspect = aspect
      ..lone = loneWidth;
  }
}

class _RenderRetroDesktopFill extends RenderAligningShiftedBox {
  _RenderRetroDesktopFill(this._limit, this._aspect, this._lone)
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

/// Marks a child of a `RetroDesktopColumn` as taking a share of the slack (CSS `flex: 1`).
class RetroDesktopGrow extends ParentDataWidget<_RetroDesktopColumnData> {
  /// Creates a [RetroDesktopGrow].
  const RetroDesktopGrow({
    super.key,
    this.most,
    this.fills = false,
    required super.child,
  });

  /// How much past its own height it may grow. What it won't take stays open under the last child.
  final double? most;

  /// Whether the child has no height of its own to measure, as a list that
  /// scrolls itself: it takes only its share (CSS `min-height: 0`).
  final bool fills;
  @override
  void applyParentData(RenderObject renderObject) {
    final d = renderObject.parentData as _RetroDesktopColumnData;
    if (!d.grow || d.most != most || d.fills != fills) {
      d.grow = true;
      d.most = most;
      d.fills = fills;
      renderObject.parent?.markNeedsLayout();
    }
  }

  @override
  Type get debugTypicalAncestorWidgetClass => RetroDesktopColumn;
}

class _RetroDesktopColumnData extends ContainerBoxParentData<RenderBox> {
  bool grow = false;
  bool fills = false;
  double? most;
}

/// A column that is safe everywhere. Children stretch to its width. Under a bounded height (a card in a `RetroDesktopRow` on a
/// desktop) the `RetroDesktopGrow` children share the slack evenly, floored at their own height; under a scroll view they just
/// take their own height. Use it in place of Column + Expanded inside any card.
///
/// ```dart
/// RetroDesktopColumn(gap: 12, children: const [Text('First'), Text('Second')])
/// ```
class RetroDesktopColumn extends MultiChildRenderObjectWidget {
  /// Creates a [RetroDesktopColumn].
  const RetroDesktopColumn({
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

  /// The color of the connecting spine.
  final Color? spineColor;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      RenderRetroDesktopColumn(
        gap,
        spineX,
        spineColor,
        Directionality.of(context),
      );
  @override
  void updateRenderObject(
    BuildContext context,
    RenderRetroDesktopColumn renderObject,
  ) {
    renderObject
      ..gap = gap
      ..spineX = spineX
      ..spineColor = spineColor
      ..dir = Directionality.of(context);
  }
}

/// Render object used by the corresponding desktop layout widget.
class RenderRetroDesktopColumn extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _RetroDesktopColumnData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _RetroDesktopColumnData> {
  /// Creates a [RenderRetroDesktopColumn].
  RenderRetroDesktopColumn(
    this._gap,
    this._spineX,
    this._spineColor,
    this._dir,
  );
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
    if (child.parentData is! _RetroDesktopColumnData) {
      child.parentData = _RetroDesktopColumnData();
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
      final fills =
          (c.parentData as _RetroDesktopColumnData).fills &&
          constraints.hasBoundedHeight;
      c.layout(
        fills ? BoxConstraints.tightFor(width: w, height: 0) : natural,
        parentUsesSize: true,
      );
      hs[c] = c.size.height;
      total += c.size.height;
    }
    var height = total;
    final target = constraints.hasBoundedHeight
        ? constraints.maxHeight
        : math.max(total, constraints.minHeight);
    final growers = [
      for (var c = firstChild; c != null; c = childAfter(c))
        if ((c.parentData as _RetroDesktopColumnData).grow) c,
    ];
    if (target > total && growers.isNotEmpty) {
      height = target;
      // CSS flex: 1 with min-height auto: an even share, floored at each child's own height.
      var room = target - _gaps();
      for (var c = firstChild; c != null; c = childAfter(c)) {
        if (!(c.parentData as _RetroDesktopColumnData).grow) room -= hs[c]!;
      }
      final open = [...growers];
      var settled = false;
      while (!settled && open.isNotEmpty) {
        settled = true;
        final share = room / open.length;
        for (final c in [...open]) {
          final most = (c.parentData as _RetroDesktopColumnData).most;
          final limit = most == null ? double.infinity : hs[c]! + most;
          if (hs[c]! > share) {
            room -= hs[c]!;
            open.remove(c);
            settled = false;
          } else if (share > limit) {
            room -= limit;
            open.remove(c);
            settled = false;
            c.layout(
              BoxConstraints.tightFor(width: w, height: limit),
              parentUsesSize: true,
            );
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
      (c.parentData as _RetroDesktopColumnData).offset = Offset(
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

  @override
  void paint(PaintingContext context, Offset offset) {
    if (_spineX != null && _spineColor != null && firstChild != null) {
      final first = firstChild!, last = lastChild!;
      final y0 =
          (first.parentData as _RetroDesktopColumnData).offset.dy +
          first.size.height / 2;
      final y1 =
          (last.parentData as _RetroDesktopColumnData).offset.dy +
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
/// then given the row's height, so a card can hold anything, and `RetroDesktopGrow` lists inside take up the slack.
///
/// ```dart
/// RetroDesktopEqualRow(flex: const [1, 1], gap: 12, children: const [Text('Left'), Text('Right')])
/// ```
class RetroDesktopEqualRow extends MultiChildRenderObjectWidget {
  /// Creates a [RetroDesktopEqualRow].
  const RetroDesktopEqualRow({
    super.key,
    required this.flex,
    this.gap = 0,
    this.columns,
    super.children,
  });

  /// The relative share of remaining layout space.
  final List<int> flex;

  /// Space between adjacent items in logical pixels.
  final double gap;

  /// When set, `flex` counts columns of a grid of that many columns, so a span also takes the gutters it crosses.
  final int? columns;
  @override
  RenderObject createRenderObject(BuildContext context) =>
      RenderRetroDesktopEqualRow(
        flex,
        gap,
        Directionality.of(context),
        columns,
      );
  @override
  void updateRenderObject(
    BuildContext context,
    RenderRetroDesktopEqualRow renderObject,
  ) {
    renderObject
      ..flex = flex
      ..gap = gap
      ..columns = columns
      ..dir = Directionality.of(context);
  }
}

class _EqualRowData extends ContainerBoxParentData<RenderBox> {}

/// Render object used by the corresponding desktop layout widget.
class RenderRetroDesktopEqualRow extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _EqualRowData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _EqualRowData> {
  /// Creates a [RenderRetroDesktopEqualRow].
  RenderRetroDesktopEqualRow(this._flex, this._gap, this._dir, this._columns);
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

/// A row on the 12-column grid inside a window: `RetroDesktopRow(spans: [7, 5], children: [a, b])`. From 1024 wide its children
/// sit side by side and share a height. Below that they stack, 12 between. A page's windows are placed by `RetroDesktopDesktop`.
///
/// ```dart
/// RetroDesktopRow(spans: const [1, 2], children: const [Text('Label'), Text('Value')])
/// ```
class RetroDesktopRow extends StatelessWidget {
  /// Creates a [RetroDesktopRow].
  const RetroDesktopRow({
    super.key,
    required this.spans,
    required this.children,
  });

  /// Relative column spans in display order.
  final List<int> spans;

  /// The child widgets in reading order.
  final List<Widget> children;
  @override
  Widget build(BuildContext context) {
    if (!RetroDesktopTheme.of(context).desk) {
      return RetroDesktopColumn(gap: 12, children: children);
    }
    return RetroDesktopEqualRow(
      flex: spans,
      gap: 12,
      columns: 12,
      children: children,
    );
  }
}

/// The alignment choices for a fitted row.
enum RetroDesktopFitAlign {
  /// Centers content on the cross axis.
  center,

  /// Aligns text on its baseline.
  baseline,

  /// Aligns content to the bottom edge.
  bottom,
}

/// A row that can't overflow, and works inside a plain `Row`. One child, `fill`, takes what is left; the others keep
/// their natural width, measured last to first, each leaving at least `fillMin` (or `fillShare` of the row) for it.
/// `shrink` makes the row only as wide as its content, for a mark and a label.
///
/// ```dart
/// RetroDesktopFitRow(fill: 0, children: const [Text('A growing title'), Text('Detail')])
/// ```
class RetroDesktopFitRow extends MultiChildRenderObjectWidget {
  /// Creates a [RetroDesktopFitRow].
  const RetroDesktopFitRow({
    super.key,
    required this.fill,
    this.gap = 8,
    this.align = RetroDesktopFitAlign.center,
    this.shrink = false,
    this.fillMin = 0,
    this.fillShare = 0,
    super.children,
  });

  /// The index of the child that takes remaining width.
  final int fill;

  /// Space between adjacent items in logical pixels.
  final double gap;

  /// The minimum width reserved for the filling child.
  final double fillMin;

  /// The fraction of width reserved for the filling child.
  final double fillShare;

  /// How the content aligns along its row.
  final RetroDesktopFitAlign align;

  /// Whether layout may shrink this item to fit.
  final bool shrink;
  @override
  RenderObject createRenderObject(BuildContext context) =>
      RenderRetroDesktopFitRow(this, Directionality.of(context));
  @override
  void updateRenderObject(
    BuildContext context,
    RenderRetroDesktopFitRow renderObject,
  ) {
    renderObject
      .._w = this
      .._dir = Directionality.of(context)
      ..markNeedsLayout();
  }
}

class _FitRowData extends ContainerBoxParentData<RenderBox> {}

/// Render object used by the corresponding desktop layout widget.
class RenderRetroDesktopFitRow extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _FitRowData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _FitRowData> {
  /// Creates a [RenderRetroDesktopFitRow].
  RenderRetroDesktopFitRow(this._w, this._dir);
  RetroDesktopFitRow _w;
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
      if (_w.align == RetroDesktopFitAlign.baseline) {
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
      _w.align == RetroDesktopFitAlign.baseline ? above + below : tallest,
    );
    var x = 0.0;
    for (var i = 0; i < kids.length; i++) {
      final kh = kids[i].size.height;
      final y = switch (_w.align) {
        RetroDesktopFitAlign.center => (h - kh) / 2,
        RetroDesktopFitAlign.bottom => h - kh,
        RetroDesktopFitAlign.baseline => above - ascents[i],
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
/// RetroDesktopAutoRow(children: const [Text('First'), Text('Second')])
/// ```
class RetroDesktopAutoRow extends MultiChildRenderObjectWidget {
  /// Creates a [RetroDesktopAutoRow].
  const RetroDesktopAutoRow({super.key, this.gap = 14, super.children});

  /// Space between adjacent items in logical pixels.
  final double gap;
  @override
  RenderObject createRenderObject(BuildContext context) =>
      RenderRetroDesktopAutoRow(gap, Directionality.of(context));
  @override
  void updateRenderObject(
    BuildContext context,
    RenderRetroDesktopAutoRow renderObject,
  ) {
    renderObject
      .._gap = gap
      .._dir = Directionality.of(context)
      ..markNeedsLayout();
  }
}

class _AutoRowData extends ContainerBoxParentData<RenderBox> {}

/// Render object used by the corresponding desktop layout widget.
class RenderRetroDesktopAutoRow extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _AutoRowData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _AutoRowData> {
  /// Creates a [RenderRetroDesktopAutoRow].
  RenderRetroDesktopAutoRow(this._gap, this._dir);
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
/// RetroDesktopGridOf(columns: 2, children: const [Text('First'), Text('Second')])
/// ```
class RetroDesktopGridOf extends StatelessWidget {
  /// Creates a [RetroDesktopGridOf].
  const RetroDesktopGridOf({
    super.key,
    required this.columns,
    required this.children,
    this.gap = 8,
    this.runGap,
  });

  /// The columns displayed in order.
  final int columns;

  /// Space between adjacent items in logical pixels.
  final double gap;

  /// Space between wrapped runs in logical pixels.
  final double? runGap;

  /// The child widgets in reading order.
  final List<Widget> children;
  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i += columns) {
      final part = children.sublist(i, math.min(i + columns, children.length));
      rows.add(
        RetroDesktopEqualRow(
          flex: List.filled(columns, 1),
          gap: gap,
          children: [
            ...part,
            for (var k = part.length; k < columns; k++) const SizedBox.shrink(),
          ],
        ),
      );
    }
    return RetroDesktopColumn(gap: runGap ?? gap, children: rows);
  }
}

/// Start and end on one baseline, pushed apart; if they don't fit on a line, end drops under start. CSS flex-wrap with
/// baseline alignment, which Wrap can't do.
///
/// ```dart
/// RetroDesktopSplit(start: const Text('Main content'), end: const Text('Details'))
/// ```
class RetroDesktopSplit extends MultiChildRenderObjectWidget {
  /// Creates a [RetroDesktopSplit].
  RetroDesktopSplit({
    super.key,
    required Widget start,
    required Widget end,
    this.gap = 14,
    this.runGap = 0,
    this.bottoms = false,
  }) : super(children: [start, end]);

  /// Space between adjacent items in logical pixels.
  final double gap;

  /// Space between wrapped runs in logical pixels.
  final double runGap;

  /// Line up the bottoms of the two instead of their baselines.
  final bool bottoms;
  @override
  RenderObject createRenderObject(BuildContext context) =>
      RenderRetroDesktopSplit(gap, runGap, Directionality.of(context), bottoms);
  @override
  void updateRenderObject(
    BuildContext context,
    RenderRetroDesktopSplit renderObject,
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

/// Render object used by the corresponding desktop layout widget.
class RenderRetroDesktopSplit extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _SplitData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _SplitData> {
  /// Creates a [RenderRetroDesktopSplit].
  RenderRetroDesktopSplit(this._gap, this._runGap, this._dir, this._bottoms);
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
/// RetroDesktopBalancedText('A carefully balanced heading', style: RetroDesktopTheme.of(context).type.head)
/// ```
class RetroDesktopBalancedText extends StatelessWidget {
  /// Creates a [RetroDesktopBalancedText].
  const RetroDesktopBalancedText(
    this.text, {
    super.key,
    required this.style,
    this.textAlign = TextAlign.start,
  });

  /// The text displayed by this part.
  final String text;

  /// Overrides this part's component theme; unresolved slots keep their themed values.
  final TextStyle style;

  /// How text is aligned within its available width.
  final TextAlign textAlign;
  @override
  Widget build(BuildContext context) {
    // Measured at the reader's text size (measured at the plain size, twice the text broke "keeping" into "keepin"
    // over "g"), its longest word whole on a line.
    return retroDesktopWholeWords(
      text,
      style,
      LayoutBuilder(
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
          return Align(
            alignment: AlignmentDirectional.centerStart,
            widthFactor: 1,
            heightFactor: 1,
            child: SizedBox(
              width: math.min(hi.ceilToDouble() + 1, c.maxWidth),
              child: Text(text, style: style, textAlign: textAlign),
            ),
          );
        },
      ),
    );
  }
}

/// The width of the widest word of [text] in [style] at the reader's [textScaler]: below it, Flutter breaks a word in
/// two.
double retroDesktopWidestWord(
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
      textScaler: textScaler,
      maxLines: 1,
    )..layout();
    if (tp.width > widest) widest = tp.width;
    tp.dispose();
  }
  return widest;
}

/// Internal, not exported: [child] with the reader's text scale brought down just enough that the longest word of
/// [text] in [style] stands on one line in the width it gets, so a heading never breaks inside a word (twice the text
/// size on a phone broke "changes?" into "ch" over "anges?"). A word that fits leaves the reader's scale alone.
Widget retroDesktopWholeWords(String text, TextStyle style, Widget child) =>
    LayoutBuilder(
      builder: (context, box) {
        if (!box.hasBoundedWidth) return child;
        final scaler = MediaQuery.textScalerOf(context);
        if (retroDesktopWidestWord(text, style, textScaler: scaler) <=
            box.maxWidth) {
          return child;
        }
        final plain = retroDesktopWidestWord(text, style);
        if (plain <= 0) return child;
        return MediaQuery.withClampedTextScaling(
          maxScaleFactor: math.max(1.0, box.maxWidth / plain - .01),
          child: child,
        );
      },
    );

/// An object beside its words: a fob, a medal, a vault, a small chart or picture. The object keeps its size up to
/// [maxObject] of the width; the words take the rest. If the words would get under [minWords], they go under the
/// object instead, so a column never crushes to a letter a line. Never write this as a `Row` with an `Expanded`.
///
/// ```dart
/// RetroDesktopBeside(object: const Icon(RetroDesktopGlyphs.folder), child: const RetroDesktopDescriptionList([RetroDesktopFact('Holds', '1.4 GB')]))
/// ```
class RetroDesktopBeside extends MultiChildRenderObjectWidget {
  /// Creates a [RetroDesktopBeside].
  RetroDesktopBeside({
    super.key,
    required Widget object,
    required Widget child,
    this.gap = 16,
    this.minWords = 140,
    this.maxObject = .42,
    this.objectAtEnd = false,
  }) : super(children: [object, child]);

  /// Space between adjacent items in logical pixels.
  final double gap;

  /// The minimum width reserved for readable words.
  final double minWords;

  /// The maximum width reserved for the object beside the words.
  final double maxObject;

  /// The object after the words, not before them.
  final bool objectAtEnd;
  @override
  RenderObject createRenderObject(BuildContext context) =>
      RenderRetroDesktopBeside(
        gap,
        minWords,
        maxObject,
        objectAtEnd,
        Directionality.of(context),
      );
  @override
  void updateRenderObject(
    BuildContext context,
    RenderRetroDesktopBeside renderObject,
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

/// Render object used by the corresponding desktop layout widget.
class RenderRetroDesktopBeside extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _BesideData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _BesideData> {
  /// Creates a [RenderRetroDesktopBeside].
  RenderRetroDesktopBeside(
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

/// A part that stands on a window's own edge and draws its own inset: a window gives it no padding.
abstract class RetroDesktopFlush {}

/// The screen width from which a button, a select, a stepper and a segmented
/// control keep to the width of what they show: below it a phone's block
/// button spans its column; from it up a control spanning a column reads as a
/// banner.
const double retroDesktopHugFrom = 600;

/// From [retroDesktopHugFrom] up, the widest room a button fills (a form
/// grid's cell, an action sheet's column); in a wider one it keeps to its
/// words.
const double retroDesktopHugMost = 320;

/// Whether controls keep to their content on [context]'s screen.
bool retroDesktopHugs(BuildContext context) =>
    (MediaQuery.maybeSizeOf(context)?.width ?? 0) >= retroDesktopHugFrom;

/// Fills finite horizontal room below [retroDesktopHugFrom], and from it up a
/// room at most [retroDesktopHugMost] wide; in a wider room from
/// [retroDesktopHugFrom] up, and in an unbounded row, the face takes its
/// content's width at the room's leading edge, and a press anywhere in the
/// room still reaches it (a walkthrough presses a button's box at its
/// middle). With [always] the face takes its content's width at every width
/// and in any room (a quiet button, whose words stand on the column's edge).
/// Internal button layout; hidden from the public barrel.
Widget retroDesktopButtonFill({required Widget child, bool always = false}) =>
    _ButtonWidth(always: always, child: child);

// Fill finite room without a LayoutBuilder, so a parent may also ask for
// intrinsic width. In an unbounded row the face takes its content width.
class _ButtonWidth extends SingleChildRenderObjectWidget {
  const _ButtonWidth({required this.always, required super.child});
  final bool always;
  @override
  RenderObject createRenderObject(BuildContext context) => _RenderButtonWidth(
    retroDesktopHugs(context),
    Directionality.maybeOf(context) ?? TextDirection.ltr,
  ).._always = always;
  @override
  void updateRenderObject(
    BuildContext context,
    _RenderButtonWidth renderObject,
  ) => renderObject
    ..hug = retroDesktopHugs(context)
    ..always = always
    ..direction = Directionality.maybeOf(context) ?? TextDirection.ltr;
}

class _RenderButtonWidth extends RenderShiftedBox {
  _RenderButtonWidth(this._hug, this._direction) : super(null);

  bool _hug;
  set hug(bool v) {
    if (v == _hug) return;
    _hug = v;
    markNeedsLayout();
  }

  bool _always = false;
  set always(bool v) {
    if (v == _always) return;
    _always = v;
    markNeedsLayout();
  }

  TextDirection _direction;
  set direction(TextDirection v) {
    if (v == _direction) return;
    _direction = v;
    markNeedsLayout();
  }

  BoxConstraints _inner(BoxConstraints box) {
    if (!box.hasBoundedWidth) return box;
    if (!_always && (!_hug || box.maxWidth <= retroDesktopHugMost + .5)) {
      return box.tighten(width: box.maxWidth);
    }
    final own = child!.getMaxIntrinsicWidth(
      box.hasBoundedHeight ? box.maxHeight : double.infinity,
    );
    final width = own.clamp(0.0, box.maxWidth);
    return BoxConstraints(
      minWidth: width,
      maxWidth: width,
      minHeight: box.minHeight,
      maxHeight: box.maxHeight,
    );
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) =>
      constraints.constrain(child!.getDryLayout(_inner(constraints)));

  @override
  void performLayout() {
    final kid = child!;
    kid.layout(_inner(constraints), parentUsesSize: true);
    size = constraints.constrain(kid.size);
    final room = size.width - kid.size.width;
    (kid.parentData! as BoxParentData).offset = Offset(
      _direction == TextDirection.rtl ? room : 0,
      ((size.height - kid.size.height) / 2).roundToDouble(),
    );
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    final kid = child;
    if (kid == null || !kid.hasSize || kid.size.isEmpty) return false;
    final at = (kid.parentData! as BoxParentData).offset;
    final on = Offset(
      position.dx.clamp(at.dx, at.dx + kid.size.width - .01),
      position.dy.clamp(at.dy, at.dy + kid.size.height - .01),
    );
    return result.addWithPaintOffset(
      offset: at,
      position: on,
      hitTest: (result, p) => kid.hitTest(result, position: p),
    );
  }
}
