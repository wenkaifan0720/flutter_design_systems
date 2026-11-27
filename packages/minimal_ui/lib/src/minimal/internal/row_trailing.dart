import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Marks a list row's trailing slot. A menu key drawn there
/// (`MinimalMenu.button`'s square) stands ghost: its glyph alone at rest, in
/// the row's quiet ink, as the row's meta and chevron are; its press and
/// hover wash and its focus ring keep the square's shape. The row's own
/// hairlines already frame it, so a square round every row's key would draw
/// a column of boxes down the list. Not exported.
class MinimalRowTrailing extends InheritedWidget {
  /// Marks [child] as a list row's trailing part.
  const MinimalRowTrailing({super.key, required super.child});

  /// Whether [context] stands in a list row's trailing slot.
  static bool inRow(BuildContext context) =>
      context.getInheritedWidgetOfExactType<MinimalRowTrailing>() != null;

  @override
  bool updateShouldNotify(MinimalRowTrailing oldWidget) => false;
}

/// A list row's title and its trailing part on one line: the trailing part
/// at its own width up to [endShare] of the line, on the end keyline, the
/// title taking the rest. A trailing part wider than its share (a long tag)
/// is held to it and ellipsizes, as Material's ListTile holds its trailing
/// to the tile, so the title keeps at least a third of the line. Unlike a LayoutBuilder it
/// answers intrinsic sizes. Not exported.
class MinimalRowLine extends MultiChildRenderObjectWidget {
  /// [title] then [end], [gap] apart.
  MinimalRowLine({
    super.key,
    required Widget title,
    required Widget end,
    required this.gap,
    this.endShare = 2 / 3,
  }) : super(children: [title, end]);

  /// The space between the title and the trailing part.
  final double gap;

  /// The most of the line the trailing part takes.
  final double endShare;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderRowLine(
    gap: gap,
    endShare: endShare,
    textDirection: Directionality.of(context),
  );

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    (renderObject as _RenderRowLine)
      ..gap = gap
      ..endShare = endShare
      ..textDirection = Directionality.of(context);
  }
}

class _RowLineParentData extends ContainerBoxParentData<RenderBox> {}

class _RenderRowLine extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _RowLineParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _RowLineParentData> {
  _RenderRowLine({
    required this._gap,
    required this._endShare,
    required this._textDirection,
  });

  double _gap;
  set gap(double value) {
    if (value == _gap) return;
    _gap = value;
    markNeedsLayout();
  }

  double _endShare;
  set endShare(double value) {
    if (value == _endShare) return;
    _endShare = value;
    markNeedsLayout();
  }

  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    if (value == _textDirection) return;
    _textDirection = value;
    markNeedsLayout();
  }

  RenderBox get _title => firstChild!;
  RenderBox get _end => lastChild!;

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _RowLineParentData) {
      child.parentData = _RowLineParentData();
    }
  }

  /// The most the trailing part takes of a line [width] wide.
  double _endMax(double width) =>
      width.isFinite ? math.max(0, (width - _gap) * _endShare) : width;

  @override
  double computeMinIntrinsicWidth(double height) =>
      _title.getMinIntrinsicWidth(height) +
      _gap +
      _end.getMinIntrinsicWidth(height);

  @override
  double computeMaxIntrinsicWidth(double height) =>
      _title.getMaxIntrinsicWidth(height) +
      _gap +
      _end.getMaxIntrinsicWidth(height);

  double _height(double width, double Function(RenderBox, double) of) {
    final end = math.min(
      _end.getMaxIntrinsicWidth(double.infinity),
      _endMax(width),
    );
    final title = width.isFinite
        ? math.max(0.0, width - _gap - end)
        : double.infinity;
    return math.max(of(_title, title), of(_end, end));
  }

  @override
  double computeMinIntrinsicHeight(double width) =>
      _height(width, (child, w) => child.getMinIntrinsicHeight(w));

  @override
  double computeMaxIntrinsicHeight(double width) =>
      _height(width, (child, w) => child.getMaxIntrinsicHeight(w));

  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) =>
      defaultComputeDistanceToHighestActualBaseline(baseline);

  ({Size end, Size title, Size size}) _measure(
    BoxConstraints constraints,
    Size Function(RenderBox, BoxConstraints) lay,
  ) {
    final width = constraints.maxWidth;
    final end = lay(
      _end,
      BoxConstraints(
        maxWidth: _endMax(width),
        maxHeight: constraints.maxHeight,
      ),
    );
    final titleWidth = width.isFinite
        ? math.max(0.0, width - _gap - end.width)
        : null;
    final title = lay(
      _title,
      titleWidth == null
          ? BoxConstraints(maxHeight: constraints.maxHeight)
          : BoxConstraints.tightFor(width: titleWidth)
                .enforce(BoxConstraints(maxHeight: constraints.maxHeight)),
    );
    final size = constraints.constrain(
      Size(
        width.isFinite ? width : title.width + _gap + end.width,
        math.max(title.height, end.height),
      ),
    );
    return (end: end, title: title, size: size);
  }

  @override
  Size computeDryLayout(covariant BoxConstraints constraints) =>
      _measure(constraints, (child, c) => child.getDryLayout(c)).size;

  @override
  void performLayout() {
    final m = _measure(constraints, (child, c) {
      child.layout(c, parentUsesSize: true);
      return child.size;
    });
    size = m.size;
    final rtl = _textDirection == TextDirection.rtl;
    (_title.parentData! as _RowLineParentData).offset = Offset(
      rtl ? size.width - m.title.width : 0,
      (size.height - m.title.height) / 2,
    );
    (_end.parentData! as _RowLineParentData).offset = Offset(
      rtl ? 0 : size.width - m.end.width,
      (size.height - m.end.height) / 2,
    );
  }

  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);
}

/// Marks a list row's leading slot with the row's [title], so a mark there
/// that only repeats it (an avatar of the title's own name) stays out of the
/// row's spoken name: a screen reader hears "Piranesi", not "Piranesi,
/// Piranesi". Not exported.
class MinimalRowLeading extends InheritedWidget {
  /// Marks [child] as the leading part of a row titled [title].
  const MinimalRowLeading({
    super.key,
    required this.title,
    required super.child,
  });

  /// The row's title.
  final String title;

  /// Whether [name] only repeats the title of the row [context] leads.
  static bool repeatsTitle(BuildContext context, String name) {
    final title = context
        .getInheritedWidgetOfExactType<MinimalRowLeading>()
        ?.title;
    return title != null &&
        title.trim().toLowerCase() == name.trim().toLowerCase();
  }

  @override
  bool updateShouldNotify(MinimalRowLeading oldWidget) =>
      title != oldWidget.title;
}
