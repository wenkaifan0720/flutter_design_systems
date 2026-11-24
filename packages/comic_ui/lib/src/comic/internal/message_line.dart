import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// An announcement's words and its actions, laid as a Material SnackBar lays its message and action.
///
/// The actions stand at the end of the words' line while the words fit beside them on one line, or while the actions
/// take no more than [actionOverflowThreshold] of the width (the words then wrap beside them). Past that the actions
/// stand on a line of their own under the words, [runGap] below them, as wide as the words. On the words' line the
/// two stand [gap] apart, centred on each other.
class ComicMessageLine extends MultiChildRenderObjectWidget {
  /// Lays out [message] and [actions].
  ComicMessageLine({
    super.key,
    required Widget message,
    required Widget actions,
    this.gap = 0,
    this.runGap = 0,
    this.actionOverflowThreshold = .25,
  }) : assert(actionOverflowThreshold >= 0 && actionOverflowThreshold <= 1),
       super(children: [message, actions]);

  /// The room between the words and the actions on one line.
  final double gap;

  /// The room between the words and the actions under them.
  final double runGap;

  /// The share of the width the actions may take and still stand on the words' line when the words wrap.
  final double actionOverflowThreshold;

  @override
  RenderComicMessageLine createRenderObject(BuildContext context) =>
      RenderComicMessageLine(
        gap,
        runGap,
        actionOverflowThreshold,
        Directionality.of(context),
      );

  @override
  void updateRenderObject(
    BuildContext context,
    RenderComicMessageLine renderObject,
  ) => renderObject
    ..gap = gap
    ..runGap = runGap
    ..actionOverflowThreshold = actionOverflowThreshold
    ..textDirection = Directionality.of(context);
}

/// The parent data of a [RenderComicMessageLine]'s two children.
class ComicMessageLineParentData extends ContainerBoxParentData<RenderBox> {}

/// The render object of [ComicMessageLine].
class RenderComicMessageLine extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, ComicMessageLineParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, ComicMessageLineParentData> {
  /// Lays out an announcement's words and actions: [gap] apart on one line, [runGap] apart one under the other.
  RenderComicMessageLine(
    this._gap,
    this._runGap,
    this._actionOverflowThreshold,
    this._textDirection,
  );

  double _gap;
  set gap(double value) {
    if (value == _gap) return;
    _gap = value;
    markNeedsLayout();
  }

  double _runGap;
  set runGap(double value) {
    if (value == _runGap) return;
    _runGap = value;
    markNeedsLayout();
  }

  double _actionOverflowThreshold;
  set actionOverflowThreshold(double value) {
    if (value == _actionOverflowThreshold) return;
    _actionOverflowThreshold = value;
    markNeedsLayout();
  }

  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    if (value == _textDirection) return;
    _textDirection = value;
    markNeedsLayout();
  }

  RenderBox get _message => firstChild!;
  RenderBox get _actions => lastChild!;

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! ComicMessageLineParentData) {
      child.parentData = ComicMessageLineParentData();
    }
  }

  // Whether the actions, [actions] wide, stand on the words' line in [width].
  bool _oneLine(double width, double actions) {
    if (!width.isFinite) return true;
    if (actions > width) return false;
    final words = _message.getMaxIntrinsicWidth(double.infinity);
    return words + _gap + actions <= width ||
        actions <= width * _actionOverflowThreshold;
  }

  Size _layout(
    BoxConstraints constraints,
    ChildLayouter layoutChild, {
    bool place = false,
  }) {
    final width = constraints.maxWidth;
    final actions = layoutChild(_actions, BoxConstraints(maxWidth: width));
    if (_oneLine(width, actions.width)) {
      final message = layoutChild(
        _message,
        BoxConstraints(
          maxWidth: width.isFinite
              ? math.max(0, width - _gap - actions.width)
              : double.infinity,
        ),
      );
      final height = math.max(message.height, actions.height);
      final size = constraints.constrain(
        Size(
          width.isFinite ? width : message.width + _gap + actions.width,
          height,
        ),
      );
      if (place) {
        final rtl = _textDirection == TextDirection.rtl;
        _at(
          _message,
          Offset(
            rtl ? size.width - message.width : 0,
            (height - message.height) / 2,
          ),
        );
        _at(
          _actions,
          Offset(
            rtl ? 0 : size.width - actions.width,
            (height - actions.height) / 2,
          ),
        );
      }
      return size;
    }
    final message = layoutChild(
      _message,
      BoxConstraints.tightFor(width: width),
    );
    final under = layoutChild(_actions, BoxConstraints.tightFor(width: width));
    if (place) {
      _at(_message, Offset.zero);
      _at(_actions, Offset(0, message.height + _runGap));
    }
    return constraints.constrain(
      Size(width, message.height + _runGap + under.height),
    );
  }

  void _at(RenderBox child, Offset offset) =>
      (child.parentData! as ComicMessageLineParentData).offset = offset;

  @override
  Size computeDryLayout(BoxConstraints constraints) =>
      _layout(constraints, ChildLayoutHelper.dryLayoutChild);

  @override
  void performLayout() {
    size = _layout(constraints, ChildLayoutHelper.layoutChild, place: true);
  }

  @override
  double computeMinIntrinsicWidth(double height) => math.max(
    _message.getMinIntrinsicWidth(height),
    _actions.getMinIntrinsicWidth(height),
  );

  @override
  double computeMaxIntrinsicWidth(double height) =>
      _message.getMaxIntrinsicWidth(height) +
      _gap +
      _actions.getMaxIntrinsicWidth(height);

  double _height(double width, double Function(RenderBox, double) of) {
    final actions = math.min(
      _actions.getMaxIntrinsicWidth(double.infinity),
      width,
    );
    if (_oneLine(width, actions)) {
      return math.max(
        of(
          _message,
          width.isFinite ? math.max(0, width - _gap - actions) : width,
        ),
        of(_actions, actions),
      );
    }
    return of(_message, width) + _runGap + of(_actions, width);
  }

  @override
  double computeMinIntrinsicHeight(double width) =>
      _height(width, (child, w) => child.getMinIntrinsicHeight(w));

  @override
  double computeMaxIntrinsicHeight(double width) =>
      _height(width, (child, w) => child.getMaxIntrinsicHeight(w));

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
