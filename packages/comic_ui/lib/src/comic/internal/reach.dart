// A mark drawn inside a row that is itself the target (a check row's box) takes no reach of its own: the row already
// stands at least a target tall and takes the press, so the box's face starts on the row's leading keyline instead of
// half a reach in (keylines: "a checkbox starts 22 px in; the leading keyline is 14 px in").
import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Marks [child] as drawn inside a row that takes the press; `ComicTapTarget.targetOf` reads it as no reach.
class RowMark extends InheritedWidget {
  /// Creates a [RowMark].
  const RowMark({super.key, required super.child});

  /// Whether [context] is inside a [RowMark].
  static bool inRow(BuildContext context) =>
      context.getInheritedWidgetOfExactType<RowMark>() != null;

  @override
  bool updateShouldNotify(RowMark oldWidget) => false;
}

/// Marks [child] as a press's drawn face: the press is as wide as it, and its least target's sides pad outward beside
/// it, hit-tested and read by a screen reader only, so a face starts on its column's edge. A part whose face stands
/// inside a box of its own (a tick's mark in its target) marks the mark; the deepest mark down the press's chain of
/// single children is the face.
class ComicPressFace extends SingleChildRenderObjectWidget {
  /// Creates a [ComicPressFace].
  const ComicPressFace({super.key, required super.child});

  @override
  RenderComicPressFace createRenderObject(BuildContext context) =>
      RenderComicPressFace();
}

/// The render box of a [ComicPressFace].
class RenderComicPressFace extends RenderProxyBox {
  /// The size the face last took: the press lays itself out at it, and an ancestor other than the parent may not read
  /// [size] during layout.
  Size get laidOut => _laidOut;
  Size _laidOut = Size.zero;

  @override
  void performLayout() {
    super.performLayout();
    _laidOut = Size.copy(size);
  }
}

/// Stands [child] [margin] outward on each side and takes no room for it: the room a press keeps round a face with no
/// surface at rest (a radio row's, a quiet button's start, a trail's first link) is painted (its wash and ring),
/// hit-tested where the boxes round it let a touch reach and read by a screen reader where it stands, while the face
/// starts on its column's edge. Where a neighbour's own box stands in the margin, a touch there is the
/// neighbour's. With [inwardWhenHeld], a parent holding it at a set width (a stretching column) keeps the room inside,
/// so a stretched button's words stay centred in the room it is given.
class ComicOutward extends SingleChildRenderObjectWidget {
  /// Creates a [ComicOutward].
  const ComicOutward({
    super.key,
    required this.margin,
    this.inwardWhenHeld = false,
    required super.child,
  });

  /// How far [child] stands out on each side.
  final EdgeInsetsGeometry margin;

  /// Whether a set width keeps the side margins inside.
  final bool inwardWhenHeld;

  @override
  RenderComicOutward createRenderObject(BuildContext context) =>
      RenderComicOutward(margin.resolve(Directionality.of(context)))
        ..inwardWhenHeld = inwardWhenHeld;

  @override
  void updateRenderObject(
    BuildContext context,
    RenderComicOutward renderObject,
  ) => renderObject
    ..margin = margin.resolve(Directionality.of(context))
    ..inwardWhenHeld = inwardWhenHeld;
}

/// The render box of a [ComicOutward].
class RenderComicOutward extends RenderShiftedBox {
  /// Creates a [RenderComicOutward].
  RenderComicOutward(this._margin) : super(null);

  /// How far the child stands out on each side.
  EdgeInsets get margin => _margin;
  EdgeInsets _margin;
  set margin(EdgeInsets value) {
    if (value == _margin) return;
    _margin = value;
    markNeedsLayout();
  }

  /// Whether a set width keeps the side margins inside.
  bool get inwardWhenHeld => _inwardWhenHeld;
  bool _inwardWhenHeld = false;
  set inwardWhenHeld(bool value) {
    if (value == _inwardWhenHeld) return;
    _inwardWhenHeld = value;
    markNeedsLayout();
  }

  // The margins standing out under [c]: the side ones stay inside a set width with [inwardWhenHeld].
  EdgeInsets _out(BoxConstraints c) => _inwardWhenHeld && c.hasTightWidth
      ? EdgeInsets.only(top: _margin.top, bottom: _margin.bottom)
      : _margin;

  BoxConstraints _grown(BoxConstraints c) {
    final m = _out(c);
    return BoxConstraints(
      minWidth: c.minWidth + m.horizontal,
      maxWidth: c.maxWidth + m.horizontal,
      minHeight: c.minHeight + m.vertical,
      maxHeight: c.maxHeight + m.vertical,
    );
  }

  Size _less(Size s, BoxConstraints c) {
    final m = _out(c);
    return Size(
      math.max(0, s.width - m.horizontal),
      math.max(0, s.height - m.vertical),
    );
  }

  @override
  double computeMinIntrinsicWidth(double height) => math.max(
    0,
    (child?.getMinIntrinsicWidth(height + _margin.vertical) ?? 0) -
        _margin.horizontal,
  );

  @override
  double computeMaxIntrinsicWidth(double height) => math.max(
    0,
    (child?.getMaxIntrinsicWidth(height + _margin.vertical) ?? 0) -
        _margin.horizontal,
  );

  @override
  double computeMinIntrinsicHeight(double width) => math.max(
    0,
    (child?.getMinIntrinsicHeight(width + _margin.horizontal) ?? 0) -
        _margin.vertical,
  );

  @override
  double computeMaxIntrinsicHeight(double width) => math.max(
    0,
    (child?.getMaxIntrinsicHeight(width + _margin.horizontal) ?? 0) -
        _margin.vertical,
  );

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final child = this.child;
    if (child == null) return constraints.smallest;
    return constraints.constrain(
      _less(child.getDryLayout(_grown(constraints)), constraints),
    );
  }

  @override
  double? computeDryBaseline(
    BoxConstraints constraints,
    TextBaseline baseline,
  ) {
    final at = child?.getDryBaseline(_grown(constraints), baseline);
    return at == null ? null : at - _out(constraints).top;
  }

  @override
  void performLayout() {
    final child = this.child;
    if (child == null) {
      size = constraints.smallest;
      return;
    }
    final m = _out(constraints);
    child.layout(_grown(constraints), parentUsesSize: true);
    size = constraints.constrain(_less(child.size, constraints));
    (child.parentData! as BoxParentData).offset = Offset(-m.left, -m.top);
  }

  // Whether a box beside this one, in a parent of several, holds [position]: its own box comes before this margin.
  bool _neighbourAt(Offset position) {
    final parent = this.parent;
    if (parent
        is! ContainerRenderObjectMixin<
          RenderBox,
          ContainerBoxParentData<RenderBox>
        >) {
      return false;
    }
    final at = position + (parentData! as BoxParentData).offset;
    for (
      RenderBox? box = parent.firstChild;
      box != null;
      box = (box.parentData! as ContainerBoxParentData<RenderBox>).nextSibling
    ) {
      if (box == this) continue;
      if (((box.parentData! as BoxParentData).offset & box.size).contains(at)) {
        return true;
      }
    }
    return false;
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    final child = this.child;
    if (child == null) return false;
    final offset = (child.parentData! as BoxParentData).offset;
    if (!size.contains(position) &&
        (!(offset & child.size).contains(position) || _neighbourAt(position))) {
      return false;
    }
    if (hitTestChildren(result, position: position) || hitTestSelf(position)) {
      result.add(BoxHitTestEntry(this, position));
      return true;
    }
    return false;
  }
}
