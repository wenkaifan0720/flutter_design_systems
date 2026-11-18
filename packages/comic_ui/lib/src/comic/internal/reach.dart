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

/// Stands [child] [margin] outward on each side and takes no room for it: the room a press keeps round a face with no
/// surface at rest (a radio row's sides, a quiet button's start) is painted only (its wash and ring), while the face
/// starts on its column's edge. A tap and a screen reader reach the box it takes, never the room: the area a tap
/// reaches is the box a screen reader outlines. With [inwardWhenHeld], a parent holding it at a set width (a stretching column) keeps the room inside,
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

  // A screen reader outlines the box this takes, as a tap reaches it; the room outside is drawn only.
  @override
  Rect? describeSemanticsClip(RenderObject? child) => Offset.zero & size;
}

/// Keeps a focus ring inside its clipping ancestor by shortening the corner marks.
class RingInClip extends InheritedWidget {
  /// Creates a [RingInClip].
  const RingInClip({super.key, required super.child});

  /// Whether [context] stands inside a [RingInClip].
  static bool of(BuildContext context) =>
      context.getInheritedWidgetOfExactType<RingInClip>() != null;

  @override
  bool updateShouldNotify(RingInClip oldWidget) => false;
}
