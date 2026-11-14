import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Marks a row's content: the words and controls the row stands at the
/// centre of its minimum height. A [FrostedFlushEnd] above it reads where
/// the last row's content ends. Plumbing of the components.
class FrostedRowContent extends SingleChildRenderObjectWidget {
  /// Creates a [FrostedRowContent].
  const FrostedRowContent({required Widget super.child, super.key});

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderRowContent();
}

class _RenderRowContent extends RenderProxyBox {
  /// The lowest edge of what the row draws, in [ancestor]'s coordinates:
  /// the bottom of whichever of its parts reaches lowest.
  double? bottomIn(RenderObject ancestor) {
    final box = child;
    if (box == null || !box.hasSize) return null;
    double? bottom;
    void reach(RenderObject part) {
      if (part is! RenderBox || !part.hasSize) return;
      final rect = MatrixUtils.transformRect(
        part.getTransformTo(ancestor),
        Offset.zero & part.size,
      );
      bottom = bottom == null ? rect.bottom : math.max(bottom!, rect.bottom);
    }

    box.visitChildren(reach);
    if (bottom == null) reach(box);
    return bottom;
  }
}

/// A card's rows with the room under the last row's content given back:
/// a row keeps its minimum height (its target) with its words at the
/// centre, so the last one leaves a share of it under its words, and the
/// card's padding under them would outgrow its padding over its head
/// (design6 P). Lays out [child] whole, then stands as tall as the last
/// row's content reaches; the share given back still paints and still
/// answers a tap. Plumbing of the components.
class FrostedFlushEnd extends SingleChildRenderObjectWidget {
  /// Creates a [FrostedFlushEnd].
  const FrostedFlushEnd({required Widget super.child, super.key});

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderFlushEnd();
}

class _RenderFlushEnd extends RenderProxyBox {
  @override
  void performLayout() {
    final box = child;
    if (box == null) {
      size = constraints.smallest;
      return;
    }
    // The child (a column of rows, no flex) stands at its own height: a
    // parent that measures this and then stands it at what it measured (a
    // board's grid row) hands back a height without the room given back,
    // which the child still takes.
    box.layout(
      constraints.copyWith(minHeight: 0, maxHeight: double.infinity),
      parentUsesSize: true,
    );
    var slack = _slack(box);
    if (box.size.height - slack > constraints.maxHeight) {
      // Taller than its room even with the room given back: laid out in it,
      // so the child reports its own overflow.
      box.layout(constraints, parentUsesSize: true);
      slack = _slack(box);
    }
    size = constraints.constrain(Size(box.size.width, box.size.height - slack));
  }

  /// The room under the last row's content: [box]'s height below the
  /// lowest edge a row's parts reach.
  double _slack(RenderBox box) {
    double? lowest;
    void find(RenderObject o) {
      if (o is _RenderRowContent) {
        final b = o.bottomIn(this);
        if (b != null) lowest = lowest == null ? b : math.max(lowest!, b);
        return;
      }
      o.visitChildren(find);
    }

    // The rows' parts are laid out by now and do not change here; reading
    // a descendant's size (not only the child's) is allowed only inside a
    // layout callback.
    invokeLayoutCallback<BoxConstraints>((_) => box.visitChildren(find));
    final reach = lowest;
    return reach == null
        ? 0.0
        : (box.size.height - reach).clamp(0.0, box.size.height);
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    final box = child;
    if (box == null || !(Offset.zero & box.size).contains(position)) {
      return false;
    }
    if (hitTestChildren(result, position: position)) {
      result.add(BoxHitTestEntry(this, position));
      return true;
    }
    return false;
  }
}
