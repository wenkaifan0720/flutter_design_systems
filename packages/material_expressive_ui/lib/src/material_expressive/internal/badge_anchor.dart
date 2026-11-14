/// The badge's anchor layout (Compose's `BadgedBox`): [ExpressiveBadgeAnchor],
/// which `ExpressiveBadge(child:)` and the navigation items and tabs stand
/// their badges with.
library;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'tokens/badge_tokens.g.dart';
import 'tokens/behavior.g.dart';

/// Stands any [badge] widget on the top end corner of [child] (Compose
/// `BadgedBox`), for a part whose badge slot takes a widget (a navigation
/// item, a tab); an app badges a child with `ExpressiveBadge(child:)`:
/// the box is [child]'s size; a dot stands 6dp in from the end edge and
/// 6dp down from the top, a count badge 12dp in and 14dp down from its
/// bottom — over the edge, as Material draws it. The badge paints over the
/// child and is not hit-tested (it is decoration; the child keeps the
/// target).
class ExpressiveBadgeAnchor extends StatelessWidget {
  /// A [badge] stood on the top end corner of [child].
  const ExpressiveBadgeAnchor({
    required this.badge,
    required this.child,
    super.key,
  });

  /// The badge: an [ExpressiveBadge], usually. Null draws [child] alone.
  final Widget? badge;

  /// The anchor: an icon, usually.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final badge = this.badge;
    if (badge == null) return child;
    return _BadgedBoxLayout(
      children: <Widget>[
        child,
        IgnorePointer(child: badge),
      ],
    );
  }
}

class _BadgedBoxLayout extends MultiChildRenderObjectWidget {
  const _BadgedBoxLayout({required super.children});

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderBadgedBox(textDirection: Directionality.of(context));

  @override
  void updateRenderObject(BuildContext context, _RenderBadgedBox renderObject) {
    renderObject.textDirection = Directionality.of(context);
  }
}

class _BadgedBoxParentData extends ContainerBoxParentData<RenderBox> {}

class _RenderBadgedBox extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _BadgedBoxParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _BadgedBoxParentData> {
  _RenderBadgedBox({required this._textDirection});

  TextDirection _textDirection;

  set textDirection(TextDirection value) {
    if (value == _textDirection) return;
    _textDirection = value;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _BadgedBoxParentData) {
      child.parentData = _BadgedBoxParentData();
    }
  }

  RenderBox get _anchor => firstChild!;

  RenderBox get _badge => lastChild!;

  @override
  double computeMinIntrinsicWidth(double height) =>
      _anchor.getMinIntrinsicWidth(height);

  @override
  double computeMaxIntrinsicWidth(double height) =>
      _anchor.getMaxIntrinsicWidth(height);

  @override
  double computeMinIntrinsicHeight(double width) =>
      _anchor.getMinIntrinsicHeight(width);

  @override
  double computeMaxIntrinsicHeight(double width) =>
      _anchor.getMaxIntrinsicHeight(width);

  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) =>
      _anchor.getDistanceToActualBaseline(baseline);

  @override
  Size computeDryLayout(BoxConstraints constraints) =>
      _anchor.getDryLayout(constraints);

  @override
  void performLayout() {
    // BadgedBox: the badge loosely (no min height), the anchor with the
    // box's own constraints; the box is the anchor's size.
    _badge.layout(constraints.copyWith(minHeight: 0), parentUsesSize: true);
    _anchor.layout(constraints, parentUsesSize: true);
    size = _anchor.size;
    (_anchor.parentData! as BoxParentData).offset = Offset.zero;
    final badge = _badge.size;
    final hasContent = badge.width > BadgeTokens.size;
    final horizontal = hasContent
        ? BadgeBehavior.contentHorizontalOffset
        : BadgeBehavior.dotOffset;
    final vertical = hasContent
        ? BadgeBehavior.contentVerticalOffset
        : BadgeBehavior.dotOffset;
    final start = size.width - horizontal;
    final x = switch (_textDirection) {
      TextDirection.ltr => start,
      TextDirection.rtl => size.width - start - badge.width,
    };
    (_badge.parentData! as BoxParentData).offset = Offset(
      x,
      -badge.height + vertical,
    );
  }

  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      _anchor.hitTest(
        result,
        position: position - (_anchor.parentData! as BoxParentData).offset,
      );
}
