/// Where an anchored surface goes: the room round its anchor, the side it
/// takes, where it lands once its size is known, and the bounds it keeps to
/// (the screen less its safe area, the on-screen keyboard, a look's own
/// chrome and a margin). Shared by the anchored overlay, the context menu and
/// the tooltip. Inside ui_core; not exported.
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../anchored_overlay.dart';

/// The rectangle in an overlay of [overlaySize] a surface keeps to: the
/// overlay less, on each side, the larger of the view's padding and its
/// insets (the on-screen keyboard), less [padding] (a look's own chrome,
/// `DesignOverlayPadding`), less [margin].
///
/// [view] is the overlay's own media query, not the anchor's: a page's
/// scaffold may have taken the keyboard's inset or the status bar's padding
/// out of what its body (and so the anchor) sees.
Rect designOverlayBounds({
  required Size overlaySize,
  required MediaQueryData? view,
  required EdgeInsets padding,
  required double margin,
}) {
  final safe = view?.padding ?? EdgeInsets.zero;
  final insets = view?.viewInsets ?? EdgeInsets.zero;
  final left = math.max(safe.left, insets.left) + padding.left + margin;
  final top = math.max(safe.top, insets.top) + padding.top + margin;
  final right = math.max(safe.right, insets.right) + padding.right + margin;
  final bottom = math.max(safe.bottom, insets.bottom) + padding.bottom + margin;
  return Rect.fromLTRB(
    left,
    top,
    math.max(left, overlaySize.width - right),
    math.max(top, overlaySize.height - bottom),
  );
}

/// The side a surface takes: [placement]'s own, unless it has less room
/// than [DesignOverlayPlacement.preferredExtent] and the opposite side has
/// more. [bounds] is [designOverlayBounds].
DesignOverlaySide designResolveSide(
  Rect anchor,
  Rect bounds,
  DesignOverlayPlacement placement,
  TextDirection textDirection,
) {
  final side = placement.side;
  if (!placement.flip) return side;
  final gap = placement.gap;
  final room = designOverlayRoom(anchor, bounds, side, gap, textDirection);
  final other = designOverlayRoom(
    anchor,
    bounds,
    side.opposite,
    gap,
    textDirection,
  );
  return room < placement.preferredExtent && other > room
      ? side.opposite
      : side;
}

/// The room on [side] of [anchor] inside [bounds], along the side's axis.
double designOverlayRoom(
  Rect anchor,
  Rect bounds,
  DesignOverlaySide side,
  double gap,
  TextDirection direction,
) {
  final left = direction == TextDirection.ltr;
  return switch (side) {
    DesignOverlaySide.below => bounds.bottom - anchor.bottom - gap,
    DesignOverlaySide.above => anchor.top - bounds.top - gap,
    DesignOverlaySide.start =>
      left
          ? anchor.left - bounds.left - gap
          : bounds.right - anchor.right - gap,
    DesignOverlaySide.end =>
      left
          ? bounds.right - anchor.right - gap
          : anchor.left - bounds.left - gap,
  }.clamp(0.0, double.infinity);
}

/// The most room a surface on [side] of [anchor] has: the room on that side
/// along its axis, the bounds across it.
Size designOverlayMaxSize(
  Rect anchor,
  Rect bounds,
  DesignOverlaySide side,
  double gap,
  TextDirection direction,
) {
  final room = designOverlayRoom(anchor, bounds, side, gap, direction);
  return side.isVertical ? Size(bounds.width, room) : Size(room, bounds.height);
}

/// Where a surface of [size] goes on [side] of [anchor], lined up by
/// [align] and shifted to stay inside [bounds].
///
/// A vertical menu that would cross the screen edge aligns its opposite
/// edge with the anchor when it fits there and [flipAlignment] allows it.
/// A context menu tries the other side of its pointer before shifting.
Offset designPlaceOverlay({
  required Rect anchor,
  required Rect bounds,
  required Size size,
  required DesignOverlaySide side,
  required DesignOverlayAlign align,
  required double gap,
  required TextDirection textDirection,
  bool flipAlignment = true,
}) {
  final ltr = textDirection == TextDirection.ltr;
  final point = anchor.size == Size.zero;
  double x;
  double y;
  if (side.isVertical) {
    y = side == DesignOverlaySide.below
        ? anchor.bottom + gap
        : anchor.top - gap - size.height;
    final startX = ltr ? anchor.left : anchor.right - size.width;
    final endX = ltr ? anchor.right - size.width : anchor.left;
    x = switch (align) {
      DesignOverlayAlign.start => startX,
      DesignOverlayAlign.center => anchor.center.dx - size.width / 2,
      DesignOverlayAlign.end => endX,
    };
    if ((point || flipAlignment) && align != DesignOverlayAlign.center) {
      final fits = x >= bounds.left && x + size.width <= bounds.right;
      final other = x == startX ? endX : startX;
      if (!fits && other >= bounds.left && other + size.width <= bounds.right) {
        x = other;
      }
    }
  } else {
    final onLeft = (side == DesignOverlaySide.start) == ltr;
    x = onLeft ? anchor.left - gap - size.width : anchor.right + gap;
    y = switch (align) {
      DesignOverlayAlign.start => anchor.top,
      DesignOverlayAlign.center => anchor.center.dy - size.height / 2,
      DesignOverlayAlign.end => anchor.bottom - size.height,
    };
    if (point && align != DesignOverlayAlign.center) {
      final fits = y >= bounds.top && y + size.height <= bounds.bottom;
      final other = align == DesignOverlayAlign.start
          ? anchor.bottom - size.height
          : anchor.top;
      if (!fits &&
          other >= bounds.top &&
          other + size.height <= bounds.bottom) {
        y = other;
      }
    }
  }
  // Shift to stay on screen; a surface larger than the bounds keeps its
  // start edge on screen.
  final maxX = bounds.right - size.width;
  final maxY = bounds.bottom - size.height;
  x = maxX < bounds.left
      ? (ltr ? bounds.left : maxX)
      : x.clamp(bounds.left, maxX);
  y = maxY < bounds.top ? bounds.top : y.clamp(bounds.top, maxY);
  return Offset(x, y);
}

/// Where a surface was placed, told to its listeners as it is laid out:
/// [DesignOverlayInfo.surfaceRect]'s value.
class DesignSurfaceRect extends ChangeNotifier
    implements ValueListenable<Rect?> {
  Rect? _value;

  @override
  Rect? get value => _value;

  /// Sets the rectangle, telling the listeners when it moved.
  set value(Rect? rect) {
    if (rect == _value) return;
    _value = rect;
    notifyListeners();
  }
}

/// A surface's place round its anchor, as a [CustomSingleChildLayout]'s
/// delegate: its constraints (the room on its side; a list from a field at
/// least the field's width and at most its cap) and its offset, told to
/// [placed] as it lands.
class DesignOverlayLayout extends SingleChildLayoutDelegate {
  /// The layout of a surface on [side] of [anchor] within [bounds].
  DesignOverlayLayout({
    required this.anchor,
    required this.bounds,
    required this.side,
    required this.placement,
    required this.textDirection,
    required this.maxSize,
    this.placed,
  });

  /// The anchor's rectangle (a point for a surface opened at one).
  final Rect anchor;

  /// What the surface keeps to.
  final Rect bounds;

  /// The side it takes.
  final DesignOverlaySide side;

  /// Its placement.
  final DesignOverlayPlacement placement;

  /// The reading direction.
  final TextDirection textDirection;

  /// The most room it has.
  final Size maxSize;

  /// Told where the surface lands.
  final DesignSurfaceRect? placed;

  /// Whether it is a list from a field: as wide as the anchor at least.
  bool get matchesAnchor => placement.matchAnchorWidth && side.isVertical;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    if (!matchesAnchor) {
      return BoxConstraints(maxWidth: maxSize.width, maxHeight: maxSize.height);
    }
    // A list from a field: the field's width, wider only to its cap
    // (DesignListWidth picks within), never past the room on screen.
    final least = anchor.width.clamp(0.0, maxSize.width);
    final most = math
        .max(anchor.width, placement.maxWidth)
        .clamp(least, maxSize.width);
    return BoxConstraints(
      minWidth: least,
      maxWidth: most,
      maxHeight: maxSize.height,
    );
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final offset = designPlaceOverlay(
      flipAlignment: placement.flip && placement.matchAnchorWidth,
      anchor: anchor,
      bounds: bounds,
      size: childSize,
      side: side,
      align: placement.align,
      gap: placement.gap,
      textDirection: textDirection,
    );
    placed?.value = offset & childSize;
    return offset;
  }

  @override
  bool shouldRelayout(DesignOverlayLayout oldDelegate) =>
      anchor != oldDelegate.anchor ||
      bounds != oldDelegate.bounds ||
      side != oldDelegate.side ||
      placement != oldDelegate.placement ||
      textDirection != oldDelegate.textDirection ||
      maxSize != oldDelegate.maxSize ||
      placed != oldDelegate.placed;
}

/// Its child as wide as the child's widest line (its intrinsic width) within
/// the width it is given: a list from a field, the field's width at least
/// and its cap at most, from its first frame. A child that can't say its
/// width ahead (a viewport: a lazy `ListView`, a `CustomScrollView`; a
/// `LayoutBuilder`) takes the least.
class DesignListWidth extends SingleChildRenderObjectWidget {
  /// Sizes [child] to its widest line.
  const DesignListWidth({super.key, required Widget super.child});

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderListWidth();
}

class _RenderListWidth extends RenderProxyBox {
  // The width within [constraints] for [child]: its widest line, else the
  // least.
  static double _widthFor(RenderBox child, BoxConstraints constraints) {
    if (constraints.hasTightWidth) return constraints.minWidth;
    double? natural;
    if (_saysItsWidth(child)) {
      try {
        natural = child.getMaxIntrinsicWidth(constraints.maxHeight);
      } on Object {
        natural = null;
      }
    }
    return constraints.constrainWidth(
      natural == null || !natural.isFinite ? constraints.minWidth : natural,
    );
  }

  // Whether nothing under [node] is a viewport, which answers its intrinsic
  // width with 0 (and asserts in a debug build) rather than its items'.
  static bool _saysItsWidth(RenderObject node) {
    var says = true;
    void visit(RenderObject child) {
      if (!says) return;
      if (child is RenderViewportBase) {
        says = false;
        return;
      }
      child.visitChildren(visit);
    }

    node.visitChildren(visit);
    return says && node is! RenderViewportBase;
  }

  @override
  void performLayout() {
    final child = this.child;
    if (child == null) {
      size = constraints.smallest;
      return;
    }
    final width = _widthFor(child, constraints);
    child.layout(constraints.tighten(width: width), parentUsesSize: true);
    size = constraints.constrain(child.size);
  }

  @override
  Size computeDryLayout(covariant BoxConstraints constraints) {
    final child = this.child;
    if (child == null) return constraints.smallest;
    final width = _widthFor(child, constraints);
    return constraints.constrain(
      child.getDryLayout(constraints.tighten(width: width)),
    );
  }
}
