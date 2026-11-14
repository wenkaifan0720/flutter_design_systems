/// How a table's columns share its width. MinimalTable and MinimalDataTable
/// lay their columns out by this one plan, and stand on one ground when they
/// scroll sideways ([MinimalTableGround]). Not exported.
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// The plan's measure: the air between two columns where there is room,
/// the least it closes to, and the least a shared column of words is cut to
/// before the table scrolls sideways.
abstract final class MinimalColumnMetrics {
  /// A real gap, so an id and the name after it read as two fields. The gap
  /// after a column of figures or ids always keeps it: 8 px is about one
  /// mono space, and `24 10:00` or `ORD-1042 Ana` would read as one.
  static const double gap = 16;

  /// The gap once room is short, before any column's words are cut; never
  /// after a column of figures.
  static const double tightGap = 8;

  /// The least a shared column's words are cut to at 1×; a table grows it
  /// with the text scale, as the words grow.
  static const double minShared = 72;
}

/// One column as the plan sees it.
@immutable
class MinimalPlanColumn {
  /// A column of its own [width], which gives way down to [least] (what its
  /// content needs) before any other column is cut. With no [least] it
  /// keeps its width.
  const MinimalPlanColumn.fixed(
    double this.width, {
    double? least,
    this.figures = false,
  }) : least = least ?? width,
       want = width,
       flex = 0,
       assert(least == null || least <= width);

  /// A column sharing what the fixed ones leave: it wants [want] (its
  /// widest words), is cut no further than [least], and takes the width
  /// over every column's want by [flex].
  const MinimalPlanColumn.shared({
    required this.want,
    required this.least,
    this.flex = 1,
    this.figures = false,
  }) : width = null,
       assert(least <= want);

  /// Its own width; null for a shared column.
  final double? width;

  /// The least it takes before the table scrolls.
  final double least;

  /// The width its content asks for.
  final double want;

  /// A shared column's weight.
  final int flex;

  /// Whether it prints figures (a quantity, a time, an id, in mono): the gap
  /// after it keeps its full width.
  final bool figures;

  /// Whether it shares what the fixed columns leave.
  bool get shared => width == null;
}

/// A table's columns laid out: each one's width and the gaps between them.
@immutable
class MinimalColumnPlan {
  /// [widths] in column order, [gaps] between them.
  const MinimalColumnPlan(this.widths, this.gaps);

  /// Each column's width.
  final List<double> widths;

  /// The air between each column and the next: one fewer than [widths].
  final List<double> gaps;

  /// The air before column [i], which is not the first.
  double gapBefore(int i) => gaps[i - 1];
}

/// Whether the gap before column [i] of [columns] follows a column of
/// figures or ids, and so never closes.
bool _held(List<MinimalPlanColumn> columns, int i) => columns[i - 1].figures;

/// The narrowest [columns] lay out with nothing cut that must stay whole:
/// each at its least, the tight gap between (the full gap after a column of
/// figures).
double minimalLeastExtent(List<MinimalPlanColumn> columns) {
  var extent = 0.0;
  for (final (i, column) in columns.indexed) {
    if (i > 0) {
      extent += _held(columns, i)
          ? MinimalColumnMetrics.gap
          : MinimalColumnMetrics.tightGap;
    }
    extent += column.least;
  }
  return extent;
}

/// The width [columns] take with every word whole: each at its want (a
/// fixed column at its width), 16 px apart. A table too narrow for its
/// [minimalLeastExtent] scrolls at this width: once it scrolls, cutting a
/// name gains nothing, so nothing is cut.
double minimalWholeExtent(List<MinimalPlanColumn> columns) {
  var extent = math.max(columns.length - 1, 0) * MinimalColumnMetrics.gap;
  for (final column in columns) {
    extent += column.width ?? column.want;
  }
  return extent;
}

/// [columns] laid out across [room], the width of the columns and the gaps
/// between them.
///
/// Where there is room, every fixed column takes its width and every shared
/// one its want, 16 px apart, and the shared columns take what is over by
/// flex. Where room is short, it gives in this order: the fixed columns'
/// air past their content, then the gaps down to 8 (the gap after a column
/// of figures keeps its 16), then the shared columns' words, the widest
/// cut first and none below its least. Below [minimalLeastExtent] the table
/// scrolls, laid out at [minimalWholeExtent].
MinimalColumnPlan minimalPlanColumns(
  List<MinimalPlanColumn> columns,
  double room,
) {
  final gaps = math.max(columns.length - 1, 0);
  // The gaps that may close: all but those after a column of figures.
  var closing = 0;
  for (var i = 1; i < columns.length; i++) {
    if (!_held(columns, i)) closing++;
  }
  var fixed = 0.0;
  var slack = 0.0;
  var wants = 0.0;
  for (final column in columns) {
    if (column.width case final width?) {
      fixed += width;
      slack += width - column.least;
    } else {
      wants += column.want;
    }
  }
  var gap = MinimalColumnMetrics.gap;
  var free = room - fixed - gap * gaps;
  // The fixed columns' air past their content.
  var given = 0.0;
  if (free < wants && slack > 0) {
    given = math.min(wants - free, slack);
    free += given;
  }
  // The gaps that may close, down to the tight one.
  if (free < wants && closing > 0) {
    final close = math.min(
      (wants - free) / closing,
      MinimalColumnMetrics.gap - MinimalColumnMetrics.tightGap,
    );
    gap -= close;
    free += close * closing;
  }
  final shared = _share(columns, free, wants);
  return MinimalColumnPlan(
    [
      for (final (i, column) in columns.indexed)
        if (column.width case final width?)
          slack > 0 ? width - (width - column.least) * given / slack : width
        else
          shared[i]!,
    ],
    [
      for (var i = 1; i < columns.length; i++)
        _held(columns, i) ? MinimalColumnMetrics.gap : gap,
    ],
  );
}

/// What each shared column of [columns] takes of [free]: its want and the
/// rest by flex when [free] covers all their [wants], else one level cut
/// that spares the narrower columns, none under its least.
Map<int, double> _share(
  List<MinimalPlanColumn> columns,
  double free,
  double wants,
) {
  final shared = [
    for (final (i, column) in columns.indexed)
      if (column.shared) (i, column),
  ];
  if (shared.isEmpty) return const {};
  if (free >= wants) {
    final flexes = shared.fold(0, (sum, s) => sum + math.max(s.$2.flex, 1));
    final over = free - wants;
    return {
      for (final (i, column) in shared)
        i: column.want + over * math.max(column.flex, 1) / flexes,
    };
  }
  // Cut every column to one level, weighted by flex: a column under the
  // level keeps its want, none goes under its least.
  double at(double level, MinimalPlanColumn column) =>
      clampDouble(level * math.max(column.flex, 1), column.least, column.want);
  var low = 0.0;
  var high = shared.fold(
    0.0,
    (top, s) => math.max(top, s.$2.want / math.max(s.$2.flex, 1)),
  );
  for (var step = 0; step < 48; step++) {
    final mid = (low + high) / 2;
    final total = shared.fold(0.0, (sum, s) => sum + at(mid, s.$2));
    if (total > free) {
      high = mid;
    } else {
      low = mid;
    }
  }
  return {for (final (i, column) in shared) i: at(low, column)};
}

/// What a table that scrolls sideways stands on: its header's band, a
/// picked row's wash and its rules, drawn across the whole frame the table
/// scrolls in, under the strip. The strip's edge fade masks all it holds,
/// so a band or a rule drawn in the strip would fade with the words and
/// stop short of the frame's edge; drawn here they reach it, and only the
/// words fade. A row on one hands its ground to it through a
/// [MinimalTableGroundRow] and paints none itself.
class MinimalTableGround extends StatefulWidget {
  /// [child], the faded strip, on the table's ground.
  const MinimalTableGround({super.key, required this.child});

  /// The strip: an edge fade round a sideways scroll view.
  final Widget child;

  /// Whether [context] stands on a table's ground: a row there hands its
  /// band, wash and rules to it rather than painting them.
  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_GroundScope>() != null;

  @override
  State<MinimalTableGround> createState() => _MinimalTableGroundState();
}

class _MinimalTableGroundState extends State<MinimalTableGround> {
  // Rows scrolling up and down under a held header move on the ground,
  // which draws them again; a sideways scroll moves nothing it draws.
  bool _scrolled(ScrollNotification n) {
    if (n.metrics.axis == Axis.vertical) {
      context.findRenderObject()?.markNeedsPaint();
    }
    return false;
  }

  @override
  Widget build(BuildContext context) => _Ground(
    child: NotificationListener<ScrollNotification>(
      onNotification: _scrolled,
      child: _GroundScope(child: widget.child),
    ),
  );
}

class _GroundScope extends InheritedWidget {
  const _GroundScope({required super.child});

  @override
  bool updateShouldNotify(_GroundScope oldWidget) => false;
}

class _Ground extends SingleChildRenderObjectWidget {
  const _Ground({super.child});

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderGround();
}

class _RenderGround extends RenderProxyBox {
  /// The rows standing on it, in the order they came.
  final Set<_RenderGroundRow> _rows = <_RenderGroundRow>{};

  // Its own layer, so rows moving under a held header repaint the ground
  // alone.
  @override
  bool get isRepaintBoundary => true;

  void _changed() {
    if (attached) markNeedsPaint();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final frame = offset & size;
    final canvas = context.canvas;
    // A row's height, across the whole frame.
    Rect across(_RenderGroundRow row) {
      final box = MatrixUtils.transformRect(
        row.getTransformTo(this),
        Offset.zero & row.size,
      ).shift(offset);
      return Rect.fromLTRB(frame.left, box.top, frame.right, box.bottom);
    }

    final laid = [
      for (final row in _rows)
        if (row.attached && row.hasSize) row,
    ];
    // The rows stop under the header's band (a held header's rows scroll
    // up under it); the band is drawn last.
    double? under;
    for (final row in laid) {
      if (row._header) {
        final foot = across(row).bottom;
        under = under == null ? foot : math.max(under, foot);
      }
    }
    canvas
      ..save()
      ..clipRect(frame)
      ..save();
    if (under != null) {
      canvas.clipRect(
        Rect.fromLTRB(frame.left, under, frame.right, frame.bottom),
      );
    }
    for (final row in laid) {
      if (!row._header) row._paintOn(canvas, across(row));
    }
    canvas.restore();
    for (final row in laid) {
      if (row._header) row._paintOn(canvas, across(row));
    }
    canvas.restore();
    super.paint(context, offset);
  }
}

/// One row of a table on a [MinimalTableGround]: [fill] across the frame
/// (the header's band, a picked row's wash), [top] and [bottom] rules on
/// its edges, at [opacity] (a faded row's). [header] is the band, drawn over
/// any row scrolled up under it. Off a ground it draws nothing; the row
/// paints its own.
class MinimalTableGroundRow extends SingleChildRenderObjectWidget {
  /// [child]'s ground.
  const MinimalTableGroundRow({
    super.key,
    this.fill,
    this.top = BorderSide.none,
    this.bottom = BorderSide.none,
    this.opacity = 1,
    this.header = false,
    super.child,
  });

  /// The fill across the row; null for none.
  final Color? fill;

  /// The rule on the row's top edge.
  final BorderSide top;

  /// The rule on the row's foot.
  final BorderSide bottom;

  /// The strength it is drawn at.
  final double opacity;

  /// Whether the row is the header's band.
  final bool header;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderGroundRow(
    fill: fill,
    top: top,
    bottom: bottom,
    opacity: opacity,
    header: header,
  );

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    (renderObject as _RenderGroundRow)
      ..fill = fill
      ..top = top
      ..bottom = bottom
      ..opacity = opacity
      ..header = header;
  }
}

class _RenderGroundRow extends RenderProxyBox {
  _RenderGroundRow({
    required this._fill,
    required this._top,
    required this._bottom,
    required this._opacity,
    required this._header,
  });

  /// The ground it stands on, while attached under one.
  _RenderGround? _ground;

  Color? _fill;
  set fill(Color? value) {
    if (value == _fill) return;
    _fill = value;
    _ground?._changed();
  }

  BorderSide _top;
  set top(BorderSide value) {
    if (value == _top) return;
    _top = value;
    _ground?._changed();
  }

  BorderSide _bottom;
  set bottom(BorderSide value) {
    if (value == _bottom) return;
    _bottom = value;
    _ground?._changed();
  }

  double _opacity;
  set opacity(double value) {
    if (value == _opacity) return;
    _opacity = value;
    _ground?._changed();
  }

  bool _header;
  set header(bool value) {
    if (value == _header) return;
    _header = value;
    _ground?._changed();
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    var node = parent;
    while (node != null && node is! _RenderGround) {
      node = node.parent;
    }
    final ground = node is _RenderGround ? node : null;
    ground?._rows.add(this);
    ground?._changed();
    _ground = ground;
  }

  @override
  void detach() {
    final ground = _ground;
    ground?._rows.remove(this);
    ground?._changed();
    _ground = null;
    super.detach();
  }

  @override
  void performLayout() {
    super.performLayout();
    // Laid out again, it may stand elsewhere on the ground.
    _ground?._changed();
  }

  void _paintOn(Canvas canvas, Rect across) {
    Paint ink(Color colour) =>
        Paint()..color = colour.withValues(alpha: colour.a * _opacity);
    final fill = _fill;
    if (fill != null && fill.a > 0) canvas.drawRect(across, ink(fill));
    if (_top.style != BorderStyle.none && _top.width > 0) {
      canvas.drawRect(
        Rect.fromLTWH(across.left, across.top, across.width, _top.width),
        ink(_top.color),
      );
    }
    if (_bottom.style != BorderStyle.none && _bottom.width > 0) {
      canvas.drawRect(
        Rect.fromLTWH(
          across.left,
          across.bottom - _bottom.width,
          across.width,
          _bottom.width,
        ),
        ink(_bottom.color),
      );
    }
  }
}
