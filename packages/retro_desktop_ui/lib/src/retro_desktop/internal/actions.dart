// A window's buttons (an alert's, a sheet's): in one row at the trailing end while they fit, as the period's alert
// boxes stood them. When they don't (long words on a phone, the reader's large text), one column at the trailing end,
// each button as wide as the widest, the default one (the last, in reading order) on top: never a row and a stray
// below it, never a staircase of different widths. A destructive action that is not the default stands apart at the
// row's start, as the period's alerts set Don't Save: at least 24 from the others, never a press away from Cancel.
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show precisionErrorTolerance;
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// A window's buttons, [spacing] apart across a row and down a column.
/// Internal: hidden from the public barrel.
class RetroDesktopActionBar extends StatelessWidget {
  /// Creates a [RetroDesktopActionBar].
  const RetroDesktopActionBar({
    super.key,
    required this.spacing,
    required this.children,
    this.apart,
  });

  /// The room between two buttons, across a row and down a column.
  final double spacing;

  /// The index of the button that stands apart at the row's start (the destructive one), or null.
  final int? apart;

  /// The buttons, in reading order, the default one last.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => _InActionBar(
    child: _ActionBar(
      spacing: spacing,
      apart: apart,
      textDirection: Directionality.of(context),
      children: children,
    ),
  );
}

/// Whether [context] stands in a [RetroDesktopActionBar]: a button there keeps to its words in the row, and takes the
/// column's width when the bar stacks the buttons.
bool retroDesktopInActionBar(BuildContext context) =>
    context.getInheritedWidgetOfExactType<_InActionBar>() != null;

class _InActionBar extends InheritedWidget {
  const _InActionBar({required super.child});

  @override
  bool updateShouldNotify(_InActionBar oldWidget) => false;
}

class _ActionBar extends MultiChildRenderObjectWidget {
  const _ActionBar({
    required this.spacing,
    required this.apart,
    required this.textDirection,
    required super.children,
  });

  final double spacing;
  final int? apart;
  final TextDirection textDirection;

  @override
  _RenderActionBar createRenderObject(BuildContext context) =>
      _RenderActionBar(spacing, apart, textDirection);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderActionBar renderObject,
  ) => renderObject
    ..spacing = spacing
    ..apart = apart
    ..textDirection = textDirection;
}

class _ActionBarParentData extends ContainerBoxParentData<RenderBox> {}

class _RenderActionBar extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _ActionBarParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _ActionBarParentData> {
  _RenderActionBar(this._spacing, this._apart, this._textDirection);

  // The least room between the button apart and the others (the period's alerts kept Don't Save 24 away).
  static const _apartGap = 24.0;

  double _spacing;
  set spacing(double value) {
    if (value == _spacing) return;
    _spacing = value;
    markNeedsLayout();
  }

  int? _apart;
  set apart(int? value) {
    if (value == _apart) return;
    _apart = value;
    markNeedsLayout();
  }

  // The room a button apart adds to the row, when one stands apart among others.
  double _apartExtra(int count) {
    final a = _apart;
    return a != null && a >= 0 && a < count && count > 1
        ? math.max(0.0, _apartGap - _spacing)
        : 0.0;
  }

  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    if (value == _textDirection) return;
    _textDirection = value;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _ActionBarParentData) {
      child.parentData = _ActionBarParentData();
    }
  }

  List<RenderBox> get _buttons => [
    for (RenderBox? b = firstChild; b != null; b = childAfter(b)) b,
  ];

  // The row's length: the buttons' widths and the room between them, added up as a Wrap does.
  double _row(Iterable<double> widths) {
    var row = 0.0;
    for (final (i, w) in widths.indexed) {
      row += i == 0 ? w : _spacing + w;
    }
    return row;
  }

  @override
  double computeMinIntrinsicWidth(double height) => _buttons.fold(
    0.0,
    (widest, b) => math.max(widest, b.getMinIntrinsicWidth(double.infinity)),
  );

  @override
  double computeMaxIntrinsicWidth(double height) {
    final buttons = _buttons;
    return _row(buttons.map((b) => b.getMaxIntrinsicWidth(double.infinity))) +
        _apartExtra(buttons.length);
  }

  @override
  double computeMinIntrinsicHeight(double width) =>
      _height(width, (b, w) => b.getMinIntrinsicHeight(w));

  @override
  double computeMaxIntrinsicHeight(double width) =>
      _height(width, (b, w) => b.getMaxIntrinsicHeight(w));

  double _height(double width, double Function(RenderBox, double) measure) {
    final buttons = _buttons;
    final widths = [
      for (final b in buttons) b.getMaxIntrinsicWidth(double.infinity),
    ];
    if (_row(widths) <= width) {
      return buttons.fold(
        0.0,
        (tallest, b) => math.max(tallest, measure(b, double.infinity)),
      );
    }
    final column = math.min(width, widths.fold(0.0, math.max));
    return _row(buttons.map((b) => measure(b, column)));
  }

  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) =>
      defaultComputeDistanceToHighestActualBaseline(baseline);

  @override
  Size computeDryLayout(BoxConstraints constraints) =>
      _layout(constraints, (b, c) => b.getDryLayout(c), place: false);

  @override
  void performLayout() {
    size = _layout(constraints, (b, c) {
      b.layout(c, parentUsesSize: true);
      return b.size;
    }, place: true);
  }

  Size _layout(
    BoxConstraints constraints,
    Size Function(RenderBox, BoxConstraints) lay, {
    required bool place,
  }) {
    final buttons = _buttons;
    if (buttons.isEmpty) return constraints.smallest;
    final rtl = _textDirection == TextDirection.rtl;
    // Each button at its own size first, as a Wrap measures it.
    final own = [
      for (final b in buttons)
        lay(b, BoxConstraints(maxWidth: constraints.maxWidth)),
    ];
    final row = _row(own.map((s) => s.width));
    if (row - constraints.maxWidth <= precisionErrorTolerance) {
      // One row at the trailing end, the buttons' tops on one line: where the Wrap stood them, to the same sums
      // (right to left, from the last at the left edge). The button apart, when the row has room for its gap, stands
      // at the start.
      final extra = _apartExtra(buttons.length);
      final split =
          extra > 0 &&
          row + extra - constraints.maxWidth <= precisionErrorTolerance;
      final tallest = own.fold(0.0, (h, s) => math.max(h, s.height));
      final size = constraints.constrain(
        Size(split ? row + extra : row, tallest),
      );
      if (place) {
        final rest = [
          for (final (i, b) in buttons.indexed)
            if (!split || i != _apart) (i, b),
        ];
        final restRow = _row(rest.map((e) => own[e.$1].width));
        var x = rtl ? 0.0 : math.max(0.0, size.width - restRow);
        for (final (i, b) in rtl ? rest.reversed : rest) {
          (b.parentData! as _ActionBarParentData).offset = Offset(x, 0);
          x += own[i].width + _spacing;
        }
        if (split) {
          final a = _apart!;
          (buttons[a].parentData! as _ActionBarParentData).offset = Offset(
            rtl ? size.width - own[a].width : 0,
            0,
          );
        }
      }
      return size;
    }
    // One column at the trailing end, each button as wide as the widest, the last on top. A row that doesn't fit
    // had a finite room to miss.
    final outer = constraints.maxWidth;
    final column = math.min(
      outer,
      own.fold(0.0, (widest, s) => math.max(widest, s.width)),
    );
    var y = 0.0;
    for (final b in buttons.reversed) {
      final s = lay(b, BoxConstraints.tightFor(width: column));
      if (place) {
        (b.parentData! as _ActionBarParentData).offset = Offset(
          rtl ? 0 : outer - column,
          y,
        );
      }
      y += s.height + _spacing;
    }
    return constraints.constrain(Size(outer, y - _spacing));
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);

  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);
}
