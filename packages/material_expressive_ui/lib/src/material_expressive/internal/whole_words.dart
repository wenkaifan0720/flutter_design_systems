/// A label that breaks only between its words. Internal: the look wraps a
/// narrow slot's label (a navigation bar item's, a tab's) once, here.
library;

import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// [child], a label, laid out as given while its longest word fits the
/// width; when that word is wider (large text in a narrow slot), the whole
/// label prints smaller, just enough for the word to fit, rather than
/// breaking the word across lines. Its other words still wrap between them.
///
/// Under an [ExpressiveWholeWordsGroup], the labels print at one size: each
/// takes the scale the group's widest word needs.
class ExpressiveWholeWords extends SingleChildRenderObjectWidget {
  /// Keeps [child]'s words whole.
  const ExpressiveWholeWords({required Widget super.child, super.key});

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderWholeWords(_WholeWordsScope.of(context));

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) =>
      (renderObject as _RenderWholeWords).group = _WholeWordsScope.of(context);
}

/// The labels of a row of equal slots (a fixed tab row's tabs, a bar's or a
/// rail's items): one long word shrinks every label by the same scale, so
/// the row's words stay one size.
class ExpressiveWholeWordsGroup extends StatefulWidget {
  /// Groups the [ExpressiveWholeWords] under [child].
  const ExpressiveWholeWordsGroup({required this.child, super.key});

  /// The row.
  final Widget child;

  @override
  State<ExpressiveWholeWordsGroup> createState() => _WholeWordsGroupState();
}

class _WholeWordsGroupState extends State<ExpressiveWholeWordsGroup> {
  final Set<_RenderWholeWords> _members = <_RenderWholeWords>{};

  @override
  Widget build(BuildContext context) =>
      _WholeWordsScope(members: _members, child: widget.child);
}

class _WholeWordsScope extends InheritedWidget {
  const _WholeWordsScope({required this.members, required super.child});

  final Set<_RenderWholeWords> members;

  static Set<_RenderWholeWords>? of(BuildContext context) =>
      context.getInheritedWidgetOfExactType<_WholeWordsScope>()?.members;

  @override
  bool updateShouldNotify(_WholeWordsScope oldWidget) => false;
}

class _RenderWholeWords extends RenderProxyBox {
  _RenderWholeWords(this._group);

  double _scale = 1;

  Set<_RenderWholeWords>? _group;

  set group(Set<_RenderWholeWords>? value) {
    if (!identical(value, _group)) {
      if (attached) {
        _group?.remove(this);
        value?.add(this);
      }
      _group = value;
    }
    // A neighbour's label may have changed: its word sets this one's scale.
    if (value != null) markNeedsLayout();
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _group?.add(this);
  }

  @override
  void detach() {
    _group?.remove(this);
    super.detach();
  }

  /// The scale at which the child's longest word fits [constraints] — and,
  /// in a group, every member's (their slots are as wide as this one).
  double _scaleFor(RenderBox child, BoxConstraints constraints) {
    if (!constraints.hasBoundedWidth || constraints.maxWidth <= 0) return 1;
    var word = child.getMinIntrinsicWidth(double.infinity);
    for (final member in _group ?? const <_RenderWholeWords>{}) {
      final label = member.child;
      if (identical(member, this) || label == null) continue;
      word = math.max(word, label.getMinIntrinsicWidth(double.infinity));
    }
    return word > constraints.maxWidth ? constraints.maxWidth / word : 1;
  }

  BoxConstraints _childConstraints(BoxConstraints constraints, double scale) =>
      scale == 1
      ? constraints
      : BoxConstraints(maxWidth: constraints.maxWidth / scale);

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final child = this.child;
    if (child == null) return constraints.smallest;
    final scale = _scaleFor(child, constraints);
    final own = child.getDryLayout(_childConstraints(constraints, scale));
    return constraints.constrain(own * scale);
  }

  @override
  void performLayout() {
    final child = this.child;
    if (child == null) {
      size = constraints.smallest;
      return;
    }
    _scale = _scaleFor(child, constraints);
    child.layout(_childConstraints(constraints, _scale), parentUsesSize: true);
    size = constraints.constrain(child.size * _scale);
  }

  Offset get _childOffset {
    final child = this.child!;
    return Offset(
      (size.width - child.size.width * _scale) / 2,
      (size.height - child.size.height * _scale) / 2,
    );
  }

  Matrix4 get _transform =>
      Matrix4.translationValues(_childOffset.dx, _childOffset.dy, 0)
        ..scaleByDouble(_scale, _scale, 1, 1);

  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) {
    final distance = child?.getDistanceToActualBaseline(baseline);
    return distance == null ? null : _childOffset.dy + distance * _scale;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final child = this.child;
    if (child == null) return;
    if (_scale == 1) {
      context.paintChild(child, offset);
      return;
    }
    layer = context.pushTransform(
      needsCompositing,
      offset,
      _transform,
      (context, offset) => context.paintChild(child, offset),
      oldLayer: layer as TransformLayer?,
    );
  }

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) {
    if (_scale != 1) transform.multiply(_transform);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    final child = this.child;
    if (child == null) return false;
    return result.addWithPaintTransform(
      transform: _scale == 1 ? null : _transform,
      position: position,
      hitTest: (result, position) => child.hitTest(result, position: position),
    );
  }
}
