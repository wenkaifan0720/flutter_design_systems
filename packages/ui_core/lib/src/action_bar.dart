/// A dialog's or a sheet's actions, laid out the same in every look: side by
/// side while they fit, else one column of one width with the confirming
/// action on top.
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// A row of actions that stacks when it does not fit: a dialog's or a
/// sheet's actions, laid out the same in every look. The look styles each
/// action (its rank, its destructive tone); the bar draws nothing.
///
/// Side by side while every action fits at its own width, [spacing] apart
/// and placed by [alignment] (at the end of the row by default), or sharing
/// the row equally when [expanded]. The row runs in the reader's direction:
/// right to left, the first action stands at the right. When they do not fit
/// (long words, a phone, large text), they stack in one column, every action
/// as wide as the bar and [overflowSpacing] apart, the last given (the
/// confirming action) on top and the first (the dismissive one) at the foot,
/// as Material and iOS stack them. Never two on a line and one under them.
///
/// Whether they fit is read from each action's widest content (its max
/// intrinsic width), so an action the look widens once stacked does not
/// keep the bar stacked, and the bar stacks as the text grows: words that
/// fit at 1x stack at 2x.
///
/// Give the actions in reading order, the dismissive one first and the
/// confirming one last, as Material's `AlertDialog` takes them. Each keeps
/// its own semantics node and focus; a screen reader and the Tab key read
/// them as they stand (the stack top down).
///
/// ```dart
/// RawActionBar(children: [Text('Cancel'), Text('Discard'), Text('Save changes')])
/// ```
class RawActionBar extends MultiChildRenderObjectWidget {
  /// A bar of [children], in reading order: the dismissive one first, the
  /// confirming one last.
  const RawActionBar({
    super.key,
    this.spacing = 8,
    this.overflowSpacing = 8,
    this.alignment = MainAxisAlignment.end,
    this.expanded = false,
    this.onStackedChanged,
    super.children,
  }) : assert(spacing >= 0 && overflowSpacing >= 0);

  /// The gap between actions side by side. Defaults to 8.
  final double spacing;

  /// The gap between stacked actions. Defaults to 8.
  final double overflowSpacing;

  /// Where actions side by side stand in the row, in the reader's direction.
  /// Defaults to [MainAxisAlignment.end], as Material's dialogs set theirs.
  /// Not read when [expanded], nor once they stack.
  final MainAxisAlignment alignment;

  /// Whether actions side by side share the row's width equally, as a
  /// phone's dialog spreads its two keys. They stack once the widest no
  /// longer fits its share. Defaults to false.
  final bool expanded;

  /// Called after a layout that stacks the actions, or lays them side by
  /// side again (and after the first layout, when it stacks them): a look
  /// that draws a stacked bar apart builds again with it.
  final ValueChanged<bool>? onStackedChanged;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderActionBar(
    spacing: spacing,
    overflowSpacing: overflowSpacing,
    alignment: alignment,
    expanded: expanded,
    onStackedChanged: onStackedChanged,
    textDirection: Directionality.of(context),
  );

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    (renderObject as _RenderActionBar)
      ..spacing = spacing
      ..overflowSpacing = overflowSpacing
      ..alignment = alignment
      ..expanded = expanded
      ..onStackedChanged = onStackedChanged
      ..textDirection = Directionality.of(context);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DoubleProperty('spacing', spacing, defaultValue: 8))
      ..add(DoubleProperty('overflowSpacing', overflowSpacing, defaultValue: 8))
      ..add(
        EnumProperty<MainAxisAlignment>(
          'alignment',
          alignment,
          defaultValue: MainAxisAlignment.end,
        ),
      )
      ..add(
        FlagProperty(
          'expanded',
          value: expanded,
          ifTrue: 'expanded',
          defaultValue: false,
        ),
      )
      ..add(
        ObjectFlagProperty<ValueChanged<bool>>.has(
          'onStackedChanged',
          onStackedChanged,
        ),
      );
  }
}

class _ActionBarParentData extends ContainerBoxParentData<RenderBox> {}

class _RenderActionBar extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _ActionBarParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _ActionBarParentData> {
  _RenderActionBar({
    required this._spacing,
    required this._overflowSpacing,
    required this._alignment,
    required this._expanded,
    required this.onStackedChanged,
    required this._textDirection,
  });

  double _spacing;
  set spacing(double value) {
    if (value == _spacing) return;
    _spacing = value;
    markNeedsLayout();
  }

  double _overflowSpacing;
  set overflowSpacing(double value) {
    if (value == _overflowSpacing) return;
    _overflowSpacing = value;
    markNeedsLayout();
  }

  MainAxisAlignment _alignment;
  set alignment(MainAxisAlignment value) {
    if (value == _alignment) return;
    _alignment = value;
    markNeedsLayout();
  }

  bool _expanded;
  set expanded(bool value) {
    if (value == _expanded) return;
    _expanded = value;
    markNeedsLayout();
  }

  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    if (value == _textDirection) return;
    _textDirection = value;
    markNeedsLayout();
  }

  ValueChanged<bool>? onStackedChanged;
  bool? _reported;

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _ActionBarParentData) {
      child.parentData = _ActionBarParentData();
    }
  }

  List<RenderBox> get _children => getChildrenAsList();

  double _gaps(int count, double gap) => gap * math.max(0, count - 1);

  // The width side by side: each action's widest content (or the widest
  // one's, every share being as wide) and the gaps.
  double get _rowWidth {
    final children = _children;
    if (children.isEmpty) return 0;
    var sum = 0.0;
    var widest = 0.0;
    for (final c in children) {
      final w = c.getMaxIntrinsicWidth(double.infinity);
      sum += w;
      widest = math.max(widest, w);
    }
    return (_expanded ? widest * children.length : sum) +
        _gaps(children.length, _spacing);
  }

  // The width a stack takes with no width given: the widest action's.
  double get _columnWidth => _children.fold(
    0.0,
    (w, c) => math.max(w, c.getMaxIntrinsicWidth(double.infinity)),
  );

  @override
  double computeMinIntrinsicWidth(double height) => _children.fold(
    0.0,
    (w, c) => math.max(w, c.getMinIntrinsicWidth(double.infinity)),
  );

  @override
  double computeMaxIntrinsicWidth(double height) => _rowWidth;

  @override
  double computeMinIntrinsicHeight(double width) => _height(width);

  @override
  double computeMaxIntrinsicHeight(double width) => _height(width);

  double _height(double width) {
    final children = _children;
    if (children.isEmpty) return 0;
    if (_rowWidth <= width) {
      return children.fold(
        0.0,
        (h, c) => math.max(h, c.getMaxIntrinsicHeight(double.infinity)),
      );
    }
    final column = width.isFinite ? width : _columnWidth;
    return children.fold(0.0, (h, c) => h + c.getMaxIntrinsicHeight(column)) +
        _gaps(children.length, _overflowSpacing);
  }

  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) =>
      defaultComputeDistanceToHighestActualBaseline(baseline);

  @override
  Size computeDryLayout(BoxConstraints constraints) =>
      _layout(constraints, dry: true);

  @override
  void performLayout() {
    size = _layout(constraints, dry: false);
  }

  Size _layout(BoxConstraints constraints, {required bool dry}) {
    final children = _children;
    if (children.isEmpty) return constraints.smallest;
    final room = constraints.maxWidth;
    final row = _rowWidth;
    final stacked = row > room + precisionErrorTolerance;
    Size lay(RenderBox c, BoxConstraints given) => dry
        ? c.getDryLayout(given)
        : (c..layout(given, parentUsesSize: true)).size;
    final rtl = _textDirection == TextDirection.rtl;
    Size size;
    if (!stacked) {
      final width = room.isFinite ? room : row;
      final share = _expanded
          ? (width - _gaps(children.length, _spacing)) / children.length
          : null;
      final sizes = [
        for (final c in children)
          lay(
            c,
            share != null
                ? BoxConstraints.tightFor(width: share)
                : BoxConstraints(
                    maxWidth: c.getMaxIntrinsicWidth(double.infinity),
                  ),
          ),
      ];
      final height = sizes.fold(0.0, (h, s) => math.max(h, s.height));
      size = constraints.constrain(Size(width, height));
      if (!dry) {
        final used =
            sizes.fold(0.0, (w, s) => w + s.width) +
            _gaps(children.length, _spacing);
        final free = math.max(0.0, size.width - used);
        final n = children.length;
        // From the start edge: where the first action goes and the gap
        // between neighbours.
        final (lead, between) = share != null
            ? (0.0, _spacing)
            : switch (_alignment) {
                MainAxisAlignment.start => (0.0, _spacing),
                MainAxisAlignment.end => (free, _spacing),
                MainAxisAlignment.center => (free / 2, _spacing),
                MainAxisAlignment.spaceBetween =>
                  n > 1 ? (0.0, _spacing + free / (n - 1)) : (0.0, _spacing),
                MainAxisAlignment.spaceAround => (
                  free / n / 2,
                  _spacing + free / n,
                ),
                MainAxisAlignment.spaceEvenly => (
                  free / (n + 1),
                  _spacing + free / (n + 1),
                ),
              };
        var along = lead;
        for (final (i, c) in children.indexed) {
          final s = sizes[i];
          (c.parentData! as _ActionBarParentData).offset = Offset(
            rtl ? size.width - along - s.width : along,
            (size.height - s.height) / 2,
          );
          along += s.width + between;
        }
      }
    } else {
      final width = room.isFinite ? room : _columnWidth;
      final tight = BoxConstraints.tightFor(width: width);
      // The last on top, each as wide as the bar.
      var y = 0.0;
      for (final c in children.reversed) {
        final s = lay(c, tight);
        if (!dry) {
          (c.parentData! as _ActionBarParentData).offset = Offset(0, y);
        }
        y += s.height + _overflowSpacing;
      }
      size = constraints.constrain(Size(width, y - _overflowSpacing));
    }
    // The first layout side by side is the default, and not told.
    if (!dry && _reported != stacked) {
      final first = _reported == null;
      _reported = stacked;
      final report = onStackedChanged;
      if (report != null && (stacked || !first)) {
        // Told after the frame: the look may build again, now knowing.
        SchedulerBinding.instance.addPostFrameCallback((_) => report(stacked));
      }
    }
    return size;
  }

  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);
}
