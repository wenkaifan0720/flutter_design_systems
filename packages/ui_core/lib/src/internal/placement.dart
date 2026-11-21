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
/// `RawPopoverPadding`), less [margin].
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

/// The side a surface takes: [placement]'s own, unless that side can't hold
/// what the surface needs and the opposite side has more room. It needs its
/// own [extent] along the side's axis (its height above or below), when
/// known, or [RawPopoverPlacement.preferredExtent], whichever is less: a
/// short list that fits under its field stays there, and a long one stays
/// while its side holds the preferred extent, shrinking to the room and
/// scrolling inside. [bounds] is [designOverlayBounds].
RawPopoverSide designResolveSide(
  Rect anchor,
  Rect bounds,
  RawPopoverPlacement placement,
  TextDirection textDirection, {
  double? extent,
}) {
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
  final needs = extent == null
      ? placement.preferredExtent
      : math.min(extent, placement.preferredExtent);
  return room < needs && other > room ? side.opposite : side;
}

/// The side whose room is the larger: where a surface is measured, as it
/// is laid out there when it flips.
RawPopoverSide designRoomierSide(
  Rect anchor,
  Rect bounds,
  RawPopoverSide side,
  double gap,
  TextDirection direction,
) {
  final room = designOverlayRoom(anchor, bounds, side, gap, direction);
  final other = designOverlayRoom(
    anchor,
    bounds,
    side.opposite,
    gap,
    direction,
  );
  return other > room ? side.opposite : side;
}

/// The room on [side] of [anchor] inside [bounds], along the side's axis.
double designOverlayRoom(
  Rect anchor,
  Rect bounds,
  RawPopoverSide side,
  double gap,
  TextDirection direction,
) {
  final left = direction == TextDirection.ltr;
  return switch (side) {
    RawPopoverSide.below => bounds.bottom - anchor.bottom - gap,
    RawPopoverSide.above => anchor.top - bounds.top - gap,
    RawPopoverSide.start =>
      left
          ? anchor.left - bounds.left - gap
          : bounds.right - anchor.right - gap,
    RawPopoverSide.end =>
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
  RawPopoverSide side,
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
  required RawPopoverSide side,
  required RawPopoverAlign align,
  required double gap,
  required TextDirection textDirection,
  bool flipAlignment = true,
}) {
  final ltr = textDirection == TextDirection.ltr;
  final point = anchor.size == Size.zero;
  double x;
  double y;
  if (side.isVertical) {
    y = side == RawPopoverSide.below
        ? anchor.bottom + gap
        : anchor.top - gap - size.height;
    final startX = ltr ? anchor.left : anchor.right - size.width;
    final endX = ltr ? anchor.right - size.width : anchor.left;
    x = switch (align) {
      RawPopoverAlign.start => startX,
      RawPopoverAlign.center => anchor.center.dx - size.width / 2,
      RawPopoverAlign.end => endX,
    };
    if ((point || flipAlignment) && align != RawPopoverAlign.center) {
      final fits = x >= bounds.left && x + size.width <= bounds.right;
      final other = x == startX ? endX : startX;
      if (!fits && other >= bounds.left && other + size.width <= bounds.right) {
        x = other;
      }
    }
  } else {
    final onLeft = (side == RawPopoverSide.start) == ltr;
    x = onLeft ? anchor.left - gap - size.width : anchor.right + gap;
    y = switch (align) {
      RawPopoverAlign.start => anchor.top,
      RawPopoverAlign.center => anchor.center.dy - size.height / 2,
      RawPopoverAlign.end => anchor.bottom - size.height,
    };
    if (point && align != RawPopoverAlign.center) {
      final fits = y >= bounds.top && y + size.height <= bounds.bottom;
      final other = align == RawPopoverAlign.start
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
/// [RawPopoverInfo.surfaceRect]'s value.
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
  final RawPopoverSide side;

  /// Its placement.
  final RawPopoverPlacement placement;

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
      flipAlignment:
          placement.flip &&
          placement.matchAnchorWidth &&
          placement.align == RawPopoverAlign.start,
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

/// Told a surface's own extent along its side's axis, as measured in the
/// larger of the rooms on its two sides, and whether [layout]'s side is
/// wrong for it ([designResolveSide] with that extent picks the other).
typedef DesignExtentCallback = void Function(double extent, bool wrongSide);

/// Lays a surface out round its anchor by [layout], as a
/// [CustomSingleChildLayout] would, measuring it first: laid out in the
/// larger of the rooms on its two sides, its extent is what it needs, and
/// [onExtent] is told it. A surface on the wrong side for that extent is not
/// painted or hit until it is built again with it.
class DesignOverlayPlace extends SingleChildRenderObjectWidget {
  /// Places [child] by [layout].
  const DesignOverlayPlace({
    super.key,
    required this.layout,
    this.onExtent,
    super.child,
  });

  /// Where the surface goes.
  final DesignOverlayLayout layout;

  /// Told the surface's extent at each layout.
  final DesignExtentCallback? onExtent;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderOverlayPlace(layout, onExtent);

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    (renderObject as _RenderOverlayPlace)
      ..placement = layout
      ..onExtent = onExtent;
  }
}

class _RenderOverlayPlace extends RenderShiftedBox {
  _RenderOverlayPlace(this._layout, this.onExtent) : super(null);

  DesignOverlayLayout _layout;
  set placement(DesignOverlayLayout value) {
    if (identical(value, _layout)) return;
    final relayout = value.shouldRelayout(_layout);
    _layout = value;
    if (relayout) markNeedsLayout();
  }

  DesignExtentCallback? onExtent;

  // Laid out on the wrong side for its extent: built again next frame.
  bool _wrongSide = false;

  static double _extentOf(Size size, RawPopoverSide side) =>
      side.isVertical ? size.height : size.width;

  @override
  void performLayout() {
    size = constraints.biggest;
    final child = this.child;
    if (child == null) return;
    final layout = _layout;
    final placement = layout.placement;
    double? extent;
    if (placement.flip) {
      final roomier = designRoomierSide(
        layout.anchor,
        layout.bounds,
        layout.side,
        placement.gap,
        layout.textDirection,
      );
      if (roomier != layout.side) {
        final measure = DesignOverlayLayout(
          anchor: layout.anchor,
          bounds: layout.bounds,
          side: roomier,
          placement: placement,
          textDirection: layout.textDirection,
          maxSize: designOverlayMaxSize(
            layout.anchor,
            layout.bounds,
            roomier,
            placement.gap,
            layout.textDirection,
          ),
        );
        child.layout(
          measure.getConstraintsForChild(constraints),
          parentUsesSize: true,
        );
        extent = _extentOf(child.size, roomier);
      }
    }
    child.layout(
      layout.getConstraintsForChild(constraints),
      parentUsesSize: true,
    );
    if (placement.flip) {
      // On the larger side, the layout itself measured it.
      extent ??= _extentOf(child.size, layout.side);
      final side = designResolveSide(
        layout.anchor,
        layout.bounds,
        placement,
        layout.textDirection,
        extent: extent,
      );
      _wrongSide = side != layout.side;
      onExtent?.call(extent, _wrongSide);
    } else {
      _wrongSide = false;
    }
    (child.parentData! as BoxParentData).offset = layout.getPositionForChild(
      size,
      child.size,
    );
  }

  @override
  Size computeDryLayout(covariant BoxConstraints constraints) =>
      constraints.biggest;

  @override
  void paint(PaintingContext context, Offset offset) {
    if (!_wrongSide) super.paint(context, offset);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      !_wrongSide && super.hitTestChildren(result, position: position);
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
