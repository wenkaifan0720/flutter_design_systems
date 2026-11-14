// How the rows of one group (ComicListSection) take their fill and press marks: as an open menu's rows do, inset a
// few pixels inside the group's rim with the group's corner less that inset, so a lit row is concentric with the
// group, its first and last rows with the group's own corners. A row reaches past the group's padding to that inset
// while its words keep the padding, and the rules next to a lit row (pressed or chosen) stand aside.
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Which rows of a group are lit, so the rules beside them stand aside. A rule reads the lit rows' places as it
/// paints, after every row has its place, and repaints when a row lights or goes out.
class RowLights extends ChangeNotifier {
  RenderBox? _anchor;
  final Set<RenderBox> _lit = {};
  bool _disposed = false;

  /// Marks [row] lit or not.
  void mark(RenderBox row, bool lit) {
    final changed = lit ? _lit.add(row) : _lit.remove(row);
    if (changed && !_disposed) notifyListeners();
  }

  /// [box]'s vertical span in the group, or null when it is not inside the group.
  (double, double)? spanOf(RenderBox box) {
    final anchor = _anchor;
    if (anchor == null || !anchor.attached || !box.attached || !box.hasSize) {
      return null;
    }
    final rect = MatrixUtils.transformRect(
      box.getTransformTo(anchor),
      Offset.zero & box.size,
    );
    return (rect.top, rect.bottom);
  }

  /// Whether a rule spanning [top] to [bottom] touches a lit row's edge.
  bool touches(double top, double bottom) {
    for (final row in _lit) {
      final span = spanOf(row);
      if (span == null) continue;
      if ((bottom - span.$1).abs() < 1 || (top - span.$2).abs() < 1) {
        return true;
      }
    }
    return false;
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

/// Hands the rows of one group the outline their fill takes, how far they reach past the group's padding on each
/// side, and the group's [RowLights].
class RowFrame extends InheritedWidget {
  /// Scopes [shape] over [child].
  const RowFrame({
    super.key,
    required this.shape,
    this.reach = EdgeInsets.zero,
    this.lights,
    required super.child,
  });

  /// Leaves [child] out of the group's frame: a row inside another row's layout keeps its own.
  const RowFrame.off({super.key, required super.child})
    : shape = null,
      reach = EdgeInsets.zero,
      lights = null;

  /// The outline a row's fill, wash and ring take; null outside a group.
  final OutlinedBorder? shape;

  /// How far a row reaches past the group's padding, left and right; its words keep the padding.
  final EdgeInsets reach;

  /// The group's lit rows.
  final RowLights? lights;

  static RowFrame? _of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<RowFrame>();

  /// The nearest group's row outline, or null outside a group.
  static OutlinedBorder? maybeOf(BuildContext context) => _of(context)?.shape;

  /// How far a row reaches past the nearest group's padding.
  static EdgeInsets reachOf(BuildContext context) =>
      _of(context)?.reach ?? EdgeInsets.zero;

  /// The nearest group's lit rows.
  static RowLights? lightsOf(BuildContext context) => _of(context)?.lights;

  /// What a group's first row adds above itself and its last row below, the group's padding less its rows' inset:
  /// zero for the rows between.
  static EdgeInsets endsOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_RowEnds>()?.ends ??
      EdgeInsets.zero;

  @override
  bool updateShouldNotify(RowFrame old) =>
      shape != old.shape || reach != old.reach || lights != old.lights;
}

/// A group's rows, one under another at the full width, taking presses in the [reach] past their own edges.
class RowGroup extends StatefulWidget {
  /// Creates a group of [children] whose fills take [shape].
  const RowGroup({
    super.key,
    required this.shape,
    required this.reach,
    this.ends = EdgeInsets.zero,
    required this.children,
  });

  /// What the first row adds above itself and the last below.
  final EdgeInsets ends;

  /// The outline a row's fill takes.
  final OutlinedBorder shape;

  /// How far a row reaches past the group's padding.
  final EdgeInsets reach;

  /// Rows in reading order.
  final List<Widget> children;

  @override
  State<RowGroup> createState() => _RowGroupState();
}

class _RowGroupState extends State<RowGroup> {
  final _lights = RowLights();

  @override
  void dispose() {
    _lights.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RowFrame(
    shape: widget.shape,
    reach: widget.reach,
    lights: _lights,
    child: _RowColumn(
      lights: _lights,
      reach: widget.reach,
      children: [
        for (final (i, child) in widget.children.indexed)
          _RowEnds(
            ends: EdgeInsets.only(
              top: i == 0 ? widget.ends.top : 0,
              bottom: i == widget.children.length - 1 ? widget.ends.bottom : 0,
            ),
            // The first and last keep the group's padding; a row among them reaches into it.
            child: Builder(
              builder: (context) =>
                  Padding(padding: RowFrame.endsOf(context), child: child),
            ),
          ),
      ],
    ),
  );
}

class _RowEnds extends InheritedWidget {
  const _RowEnds({required this.ends, required super.child});
  final EdgeInsets ends;
  @override
  bool updateShouldNotify(_RowEnds old) => ends != old.ends;
}

class _RowColumn extends MultiChildRenderObjectWidget {
  const _RowColumn({required this.lights, required this.reach, super.children});
  final RowLights lights;
  final EdgeInsets reach;

  @override
  _RenderRowColumn createRenderObject(BuildContext context) =>
      _RenderRowColumn(lights, reach);

  @override
  void updateRenderObject(BuildContext context, _RenderRowColumn renderObject) {
    renderObject
      ..lights = lights
      ..reach = reach;
  }
}

class _RowColumnData extends ContainerBoxParentData<RenderBox> {}

class _RenderRowColumn extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _RowColumnData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _RowColumnData> {
  _RenderRowColumn(this._lights, this._reach);
  RowLights _lights;
  set lights(RowLights value) {
    if (value == _lights) return;
    _lights._anchor = null;
    _lights = value;
    if (attached) _lights._anchor = this;
  }

  EdgeInsets _reach;
  set reach(EdgeInsets value) {
    if (value == _reach) return;
    _reach = value;
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _lights._anchor = this;
  }

  @override
  void detach() {
    if (_lights._anchor == this) _lights._anchor = null;
    super.detach();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _RowColumnData) {
      child.parentData = _RowColumnData();
    }
  }

  // Each row takes the group's whole width and its own height, as a stretched column's do.
  BoxConstraints _inner(BoxConstraints c) => c.hasBoundedWidth
      ? BoxConstraints.tightFor(width: c.maxWidth)
      : const BoxConstraints();

  @override
  double computeMinIntrinsicWidth(double height) {
    var most = 0.0;
    for (var child = firstChild; child != null; child = childAfter(child)) {
      final w = child.getMinIntrinsicWidth(double.infinity);
      if (w > most) most = w;
    }
    return most;
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    var most = 0.0;
    for (var child = firstChild; child != null; child = childAfter(child)) {
      final w = child.getMaxIntrinsicWidth(double.infinity);
      if (w > most) most = w;
    }
    return most;
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    var sum = 0.0;
    for (var child = firstChild; child != null; child = childAfter(child)) {
      sum += child.getMinIntrinsicHeight(width);
    }
    return sum;
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    var sum = 0.0;
    for (var child = firstChild; child != null; child = childAfter(child)) {
      sum += child.getMaxIntrinsicHeight(width);
    }
    return sum;
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final inner = _inner(constraints);
    var height = 0.0, width = 0.0;
    for (var child = firstChild; child != null; child = childAfter(child)) {
      final size = child.getDryLayout(inner);
      height += size.height;
      if (size.width > width) width = size.width;
    }
    return constraints.constrain(Size(width, height));
  }

  @override
  void performLayout() {
    final inner = _inner(constraints);
    var y = 0.0, width = 0.0;
    for (var child = firstChild; child != null; child = childAfter(child)) {
      child.layout(inner, parentUsesSize: true);
      (child.parentData! as _RowColumnData).offset = Offset(0, y);
      y += child.size.height;
      if (child.size.width > width) width = child.size.width;
    }
    size = constraints.constrain(Size(width, y));
  }

  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) =>
      defaultComputeDistanceToFirstActualBaseline(baseline);

  // A row's press reaches past the group's padding: so does the group's.
  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    final reach = Rect.fromLTRB(
      -_reach.left,
      0,
      size.width + _reach.right,
      size.height,
    );
    if (!reach.contains(position)) return false;
    if (hitTestChildren(result, position: position) || hitTestSelf(position)) {
      result.add(BoxHitTestEntry(this, position));
      return true;
    }
    return false;
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);

  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);
}

/// A row that reaches [reach] past its own edges, left and right, in what it draws and the presses it takes; it lays
/// out as wide as its slot.
class RowReach extends SingleChildRenderObjectWidget {
  /// Lets [child] reach [reach] past the row's edges.
  const RowReach({super.key, required this.reach, required super.child});

  /// How far past each edge.
  final EdgeInsets reach;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      RenderRowReach(reach);

  @override
  void updateRenderObject(BuildContext context, RenderRowReach renderObject) {
    renderObject.reach = reach;
  }
}

/// The render object of [RowReach].
class RenderRowReach extends RenderShiftedBox {
  /// Lets its child reach [reach] past its edges.
  RenderRowReach(this._reach) : super(null);
  EdgeInsets _reach;

  /// How far past each edge.
  set reach(EdgeInsets value) {
    if (value == _reach) return;
    _reach = value;
    markNeedsLayout();
  }

  double get _wide => _reach.left + _reach.right;
  double get _tall => _reach.top + _reach.bottom;

  BoxConstraints _grown(BoxConstraints c) => BoxConstraints(
    minWidth: c.minWidth + _wide,
    maxWidth: c.hasBoundedWidth ? c.maxWidth + _wide : double.infinity,
    minHeight: c.minHeight + _tall,
    maxHeight: c.hasBoundedHeight ? c.maxHeight + _tall : double.infinity,
  );

  @override
  double computeMinIntrinsicWidth(double height) =>
      ((child?.getMinIntrinsicWidth(height) ?? 0) - _wide).clamp(
        0,
        double.infinity,
      );
  @override
  double computeMaxIntrinsicWidth(double height) =>
      ((child?.getMaxIntrinsicWidth(height) ?? 0) - _wide).clamp(
        0,
        double.infinity,
      );
  @override
  double computeMinIntrinsicHeight(double width) =>
      ((child?.getMinIntrinsicHeight(width + _wide) ?? 0) - _tall).clamp(
        0,
        double.infinity,
      );
  @override
  double computeMaxIntrinsicHeight(double width) =>
      ((child?.getMaxIntrinsicHeight(width + _wide) ?? 0) - _tall).clamp(
        0,
        double.infinity,
      );

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final child = this.child;
    if (child == null) return constraints.smallest;
    final size = child.getDryLayout(_grown(constraints));
    return constraints.constrain(Size(size.width - _wide, size.height - _tall));
  }

  @override
  void performLayout() {
    final child = this.child;
    if (child == null) {
      size = constraints.smallest;
      return;
    }
    child.layout(_grown(constraints), parentUsesSize: true);
    (child.parentData! as BoxParentData).offset = Offset(
      -_reach.left,
      -_reach.top,
    );
    size = constraints.constrain(
      Size(child.size.width - _wide, child.size.height - _tall),
    );
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    final reach = Rect.fromLTRB(
      -_reach.left,
      -_reach.top,
      size.width + _reach.right,
      size.height + _reach.bottom,
    );
    if (!reach.contains(position)) return false;
    if (hitTestChildren(result, position: position) || hitTestSelf(position)) {
      result.add(BoxHitTestEntry(this, position));
      return true;
    }
    return false;
  }
}

/// Marks a group's row lit while [lit], so the rules beside it stand aside.
class RowLit extends SingleChildRenderObjectWidget {
  /// Marks [child] lit in [lights] while [lit].
  const RowLit({
    super.key,
    required this.lights,
    required this.lit,
    required super.child,
  });

  /// The group's lit rows.
  final RowLights lights;

  /// Whether the row is lit.
  final bool lit;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      RenderRowLit(lights, lit);

  @override
  void updateRenderObject(BuildContext context, RenderRowLit renderObject) {
    renderObject
      ..lights = lights
      ..lit = lit;
  }
}

/// The render object of [RowLit].
class RenderRowLit extends RenderProxyBox {
  /// Marks its row lit in [lights] while [lit].
  RenderRowLit(this._lights, this._lit);
  RowLights _lights;

  // The whole row, as the group lays it out: the nearest [RowReach] around this, whose edges meet the rules.
  RenderBox get _row {
    for (var node = parent; node != null; node = node.parent) {
      if (node is RenderRowReach) return node;
    }
    return this;
  }

  RenderBox? _marked;

  void _mark() {
    final row = attached && _lit ? _row : null;
    if (_marked != null && _marked != row) _lights.mark(_marked!, false);
    if (row != null) _lights.mark(row, true);
    _marked = row;
  }

  /// The group's lit rows.
  set lights(RowLights value) {
    if (value == _lights) return;
    if (_marked != null) _lights.mark(_marked!, false);
    _marked = null;
    _lights = value;
    _mark();
  }

  bool _lit;

  /// Whether the row is lit.
  set lit(bool value) {
    if (value == _lit) return;
    _lit = value;
    _mark();
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _mark();
  }

  @override
  void detach() {
    if (_marked != null) _lights.mark(_marked!, false);
    _marked = null;
    super.detach();
  }
}
