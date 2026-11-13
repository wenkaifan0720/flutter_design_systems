/// A surface anchored to a widget, headless: popovers, hover cards and menu
/// anchors. Placement beside the anchor that flips to the side with room
/// and shifts to stay on screen (right to left aware), outside taps and
/// Escape to close, focus moved in on open and returned on close, arrow
/// keys through a menu, hover intent with delays. The look paints the
/// anchor and the surface.
///
/// Built on the widgets layer's [RawMenuAnchor] and [MenuController], so a
/// surface nested in another closes with it and a menubar's menus share one
/// group.
library;

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'motion.dart';

/// Which side of the anchor a surface sits on. [start] and [end] follow the
/// text direction.
enum DesignOverlaySide {
  /// Under the anchor.
  below,

  /// Over the anchor.
  above,

  /// Before the anchor in reading order (left in left-to-right text).
  start,

  /// After the anchor in reading order.
  end;

  /// The side across the anchor.
  DesignOverlaySide get opposite => switch (this) {
    below => above,
    above => below,
    start => end,
    end => start,
  };

  /// Whether the surface sits above or below.
  bool get isVertical => this == below || this == above;
}

/// How a surface lines up with its anchor along the side it sits on.
enum DesignOverlayAlign {
  /// Their start edges line up (left edges in left-to-right text; top edges
  /// beside the anchor).
  start,

  /// Their centres line up.
  center,

  /// Their end edges line up.
  end,
}

/// What opens an anchored surface.
enum DesignOverlayTrigger {
  /// The anchor's press toggles it ([DesignOverlayAnchor.toggle]): a popover
  /// or a menu.
  press,

  /// A pointer resting on the anchor, keyboard focus on it, or a long press:
  /// a hover card.
  hover,

  /// Only its controller.
  manual,
}

/// Where a surface goes relative to its anchor.
@immutable
class DesignOverlayPlacement {
  /// A placement on [side], lined up by [align].
  const DesignOverlayPlacement({
    this.side = DesignOverlaySide.below,
    this.align = DesignOverlayAlign.start,
    this.gap = 4,
    this.margin = 8,
    this.flip = true,
    this.preferredExtent = 200,
    this.matchAnchorWidth = true,
  });

  /// The side it prefers.
  final DesignOverlaySide side;

  /// How it lines up along that side.
  final DesignOverlayAlign align;

  /// Space between anchor and surface.
  final double gap;

  /// The least space between the surface and the screen's edge (beyond the
  /// safe area).
  final double margin;

  /// Whether it may move to the opposite side when its own lacks room.
  final bool flip;

  /// The room it wants on its side before it flips: it flips when its side
  /// has less than this and the opposite side has more.
  final double preferredExtent;

  /// Whether, above or below the anchor, it is at least as wide as the
  /// anchor: a list opened from a field (a select's, a combobox's, a menu
  /// from a form field) is, and with [align] at [DesignOverlayAlign.start]
  /// it starts on the anchor's leading edge. On by default; a popover that
  /// keeps its own width under a wide anchor (a calendar under a date
  /// field) turns it off. Beside the anchor it has no effect.
  final bool matchAnchorWidth;
}

/// The anchor, as [DesignAnchoredOverlay.anchorBuilder] gets it.
@immutable
class DesignOverlayAnchor {
  /// The anchor of an overlay driven by [controller].
  const DesignOverlayAnchor({
    required this.controller,
    required this.isOpen,
    required this.open,
    required this.close,
    required this.toggle,
  });

  /// The overlay's controller: what [open], [close] and [toggle] call.
  final MenuController controller;

  /// Whether the surface shows: give it to the anchor's `expanded`
  /// semantics.
  final bool isOpen;

  /// Opens it.
  final VoidCallback open;

  /// Closes it.
  final VoidCallback close;

  /// Opens it when closed, closes it when open: the anchor's press.
  final VoidCallback toggle;
}

/// What [DesignAnchoredOverlay.overlayBuilder] paints the surface from.
@immutable
class DesignOverlayInfo {
  /// Info for a surface on [side] of [anchorRect].
  const DesignOverlayInfo({
    required this.side,
    required this.anchorRect,
    required this.maxSize,
    required this.animation,
    required this.close,
  });

  /// The side it sits on, after any flip: where an arrow points from, the
  /// edge a grow animation starts at.
  final DesignOverlaySide side;

  /// The anchor's rectangle in the overlay.
  final Rect anchorRect;

  /// The most room it has on that side; a long surface scrolls within it.
  final Size maxSize;

  /// 0 to 1 as it opens, 1 to 0 as it closes, on a spring (critically damped
  /// under Reduce Motion). An underdamped spring passes 1 before it rests:
  /// clamp it before an `Opacity`, which asserts outside 0 to 1, and let it
  /// overshoot only in a scale or a move.
  final Animation<double> animation;

  /// Closes it, focus going back to where it was: for an item's press.
  final VoidCallback close;
}

/// Paints the anchor.
typedef DesignOverlayAnchorBuilder = Widget Function(
  BuildContext context,
  DesignOverlayAnchor anchor,
);

/// Paints the surface.
typedef DesignOverlaySurfaceBuilder = Widget Function(
  BuildContext context,
  DesignOverlayInfo info,
);

/// The side a surface takes: [placement]'s own, unless it has less room
/// than [DesignOverlayPlacement.preferredExtent] and the opposite side has
/// more. [bounds] is the overlay less its margins and safe area.
DesignOverlaySide _resolveSide(
  Rect anchor,
  Rect bounds,
  DesignOverlayPlacement placement,
  TextDirection textDirection,
) {
  final side = placement.side;
  if (!placement.flip) return side;
  final gap = placement.gap;
  final room = _room(anchor, bounds, side, gap, textDirection);
  final other = _room(anchor, bounds, side.opposite, gap, textDirection);
  return room < placement.preferredExtent && other > room
      ? side.opposite
      : side;
}

// The room on [side] of [anchor] inside [bounds], along the side's axis.
double _room(
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

/// Where a surface of [size] goes on [side] of [anchor], lined up by
/// [align] and shifted to stay inside [bounds].
Offset _placeOverlay({
  required Rect anchor,
  required Rect bounds,
  required Size size,
  required DesignOverlaySide side,
  required DesignOverlayAlign align,
  required double gap,
  required TextDirection textDirection,
}) {
  final ltr = textDirection == TextDirection.ltr;
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
  } else {
    final onLeft = (side == DesignOverlaySide.start) == ltr;
    x = onLeft ? anchor.left - gap - size.width : anchor.right + gap;
    y = switch (align) {
      DesignOverlayAlign.start => anchor.top,
      DesignOverlayAlign.center => anchor.center.dy - size.height / 2,
      DesignOverlayAlign.end => anchor.bottom - size.height,
    };
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

class _PlacementDelegate extends SingleChildLayoutDelegate {
  _PlacementDelegate({
    required this.anchor,
    required this.bounds,
    required this.side,
    required this.placement,
    required this.textDirection,
    required this.maxSize,
  });

  final Rect anchor;
  final Rect bounds;
  final DesignOverlaySide side;
  final DesignOverlayPlacement placement;
  final TextDirection textDirection;
  final Size maxSize;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    final minWidth = placement.matchAnchorWidth && side.isVertical
        ? anchor.width.clamp(0.0, maxSize.width)
        : 0.0;
    return BoxConstraints(
      minWidth: minWidth,
      maxWidth: maxSize.width,
      maxHeight: maxSize.height,
    );
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) => _placeOverlay(
    anchor: anchor,
    bounds: bounds,
    size: childSize,
    side: side,
    align: placement.align,
    gap: placement.gap,
    textDirection: textDirection,
  );

  @override
  bool shouldRelayout(_PlacementDelegate old) =>
      anchor != old.anchor ||
      bounds != old.bounds ||
      side != old.side ||
      placement != old.placement ||
      textDirection != old.textDirection ||
      maxSize != old.maxSize;
}

/// Hover intent: open after the pointer rests, close after it leaves, so a
/// surface does not flash as a pointer crosses its anchor and a pointer can
/// travel from the anchor into the surface. Defaults follow Radix's hover
/// card: 700 ms to open, 300 ms to close.
class _HoverIntent extends ChangeNotifier {
  /// Intent with these delays.
  _HoverIntent({
    this.openDelay = const Duration(milliseconds: 700),
    this.closeDelay = const Duration(milliseconds: 300),
  });

  /// How long a pointer rests before it opens.
  final Duration openDelay;

  /// How long after the pointer leaves before it closes.
  final Duration closeDelay;

  Timer? _timer;
  bool _open = false;

  /// Whether it wants the surface open.
  bool get isOpen => _open;

  /// A pointer entered the anchor or the surface (or focus came to the
  /// anchor): both count, so the pointer can cross from one to the other.
  void enter() {
    _timer?.cancel();
    if (_open) return;
    _timer = Timer(openDelay, () => _set(true));
  }

  /// The pointer left the anchor or the surface.
  void exit() {
    _timer?.cancel();
    if (!_open) return;
    _timer = Timer(closeDelay, () => _set(false));
  }

  /// Opens now: a long press on touch.
  void openNow() {
    _timer?.cancel();
    _set(true);
  }

  /// Closes now: Escape, or a tap elsewhere.
  void closeNow() {
    _timer?.cancel();
    _set(false);
  }

  void _set(bool value) {
    if (_open == value) return;
    _open = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

class _FirstIntent extends Intent {
  const _FirstIntent();
}

class _LastIntent extends Intent {
  const _LastIntent();
}

// Never enabled: an arrow on a menu's anchor is left to the anchor's
// ancestors (a menubar, a toolbar's roving focus) instead of RawMenuAnchor
// moving focus by geometry.
class _LeaveArrows extends Action<DirectionalFocusIntent> {
  @override
  bool isEnabled(DirectionalFocusIntent intent) => false;

  @override
  Object? invoke(DirectionalFocusIntent intent) => null;
}

/// A surface anchored to [anchorBuilder]'s widget: a popover
/// ([DesignOverlayTrigger.press], [focusOnOpen]), a hover card
/// ([DesignOverlayTrigger.hover]) or a menu ([arrowKeyNavigation] on).
///
/// On open, focus moves to the surface's first focusable widget (when
/// [focusOnOpen]) and Tab stays inside it; Escape or a tap outside closes
/// it, and focus goes back to where it was (the anchor). The surface takes
/// the side with room ([DesignOverlayPlacement]) and [DesignOverlayInfo.side]
/// says which.
///
/// ```dart
/// DesignAnchoredOverlay(anchorBuilder: (context, anchor) => GestureDetector(onTap: anchor.toggle, child: const Text('More')), overlayBuilder: (context, info) => const Text('Details'))
/// ```
class DesignAnchoredOverlay extends StatefulWidget {
  /// A surface anchored to [anchorBuilder]'s widget.
  const DesignAnchoredOverlay({
    super.key,
    required this.anchorBuilder,
    required this.overlayBuilder,
    this.controller,
    this.trigger = DesignOverlayTrigger.press,
    this.placement = const DesignOverlayPlacement(),
    this.focusOnOpen = true,
    this.arrowKeyNavigation = false,
    this.semanticLabel,
    this.onOpenChanged,
    this.hoverOpenDelay = const Duration(milliseconds: 700),
    this.hoverCloseDelay = const Duration(milliseconds: 300),
    this.consumeOutsideTaps = false,
    this.useRootOverlay = false,
    this.dampingRatio = 1,
    this.stiffness = 1400,
  });

  /// Paints the anchor; a press trigger calls [DesignOverlayAnchor.toggle].
  final DesignOverlayAnchorBuilder anchorBuilder;

  /// Paints the surface.
  final DesignOverlaySurfaceBuilder overlayBuilder;

  /// Opens and closes it from outside; one is made when null.
  final MenuController? controller;

  /// What opens it.
  final DesignOverlayTrigger trigger;

  /// Where it goes.
  final DesignOverlayPlacement placement;

  /// Whether focus moves into the surface when it opens (a popover, a menu)
  /// and Tab stays inside it. A hover card leaves focus on its anchor.
  final bool focusOnOpen;

  /// Whether Up and Down move focus through the surface's items, wrapping,
  /// and Home and End go to the first and last: a menu. The arrows on the
  /// anchor are then the anchor's own and its ancestors' (a menubar moves
  /// along on them), never a move by geometry.
  final bool arrowKeyNavigation;

  /// What a screen reader calls the surface.
  final String? semanticLabel;

  /// Called when it opens (true) or closes (false).
  final ValueChanged<bool>? onOpenChanged;

  /// A hover card's wait before it opens.
  final Duration hoverOpenDelay;

  /// A hover card's wait before it closes once the pointer leaves.
  final Duration hoverCloseDelay;

  /// Whether a tap outside that closes it goes no further.
  final bool consumeOutsideTaps;

  /// Whether it shows in the root overlay rather than the nearest.
  final bool useRootOverlay;

  /// The presence spring's damping ratio (ζ).
  final double dampingRatio;

  /// The presence spring's stiffness (k).
  final double stiffness;

  @override
  State<DesignAnchoredOverlay> createState() => _DesignAnchoredOverlayState();
}

class _DesignAnchoredOverlayState extends State<DesignAnchoredOverlay>
    with SingleTickerProviderStateMixin {
  MenuController? _own;
  late final AnimationController _presence = AnimationController.unbounded(
    vsync: this,
  );
  late final FocusScopeNode _scope = FocusScopeNode(
    debugLabel: 'DesignAnchoredOverlay',
  );
  _HoverIntent? _intent;
  FocusNode? _returnTo;
  bool _open = false;

  MenuController get _controller =>
      widget.controller ?? (_own ??= MenuController());

  @override
  void initState() {
    super.initState();
    _syncIntent();
  }

  @override
  void didUpdateWidget(DesignAnchoredOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.trigger != widget.trigger ||
        oldWidget.hoverOpenDelay != widget.hoverOpenDelay ||
        oldWidget.hoverCloseDelay != widget.hoverCloseDelay) {
      _syncIntent();
    }
  }

  void _syncIntent() {
    _intent?.removeListener(_hoverChanged);
    _intent?.dispose();
    _intent = null;
    if (widget.trigger == DesignOverlayTrigger.hover) {
      _intent = _HoverIntent(
        openDelay: widget.hoverOpenDelay,
        closeDelay: widget.hoverCloseDelay,
      )..addListener(_hoverChanged);
    }
  }

  void _hoverChanged() {
    final intent = _intent!;
    if (intent.isOpen && !_controller.isOpen) {
      _controller.open();
    } else if (!intent.isOpen && _controller.isOpen) {
      _controller.close();
    }
  }

  @override
  void dispose() {
    _intent?.removeListener(_hoverChanged);
    _intent?.dispose();
    _presence.dispose();
    _scope.dispose();
    super.dispose();
  }

  SpringDescription get _spring => DesignMotionPolicy.of(context)
      .spatial(dampingRatio: widget.dampingRatio, stiffness: widget.stiffness);

  void _onOpenRequested(Offset? position, VoidCallback showOverlay) {
    final current = FocusManager.instance.primaryFocus;
    if (current != null && !_scope.hasFocus && !_scope.hasPrimaryFocus) {
      _returnTo = current;
    }
    showOverlay();
    _presence.springTo(1, _spring);
  }

  void _onOpen() {
    if (!_open) {
      _open = true;
      widget.onOpenChanged?.call(true);
    }
    if (widget.focusOnOpen) {
      // The surface mounts in this frame; focus it once it has.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_controller.isOpen) return;
        _focusEdge(first: true);
      });
    }
  }

  void _onCloseRequested(VoidCallback hideOverlay) {
    // A menu that opens asks all its group's menus to close, itself among
    // them, before it shows: that request is not a close.
    if (!_controller.isOpen) return;
    _restoreFocus();
    _intent?.closeNow();
    if (!_presence.isAnimating && _presence.value <= 0) {
      hideOverlay();
      return;
    }
    _presence.springTo(0, _spring).whenComplete(() {
      if (mounted && _presence.value <= 0.001) hideOverlay();
    });
  }

  void _onClose() {
    _presence.value = 0;
    if (_open) {
      _open = false;
      widget.onOpenChanged?.call(false);
    }
  }

  void _restoreFocus() {
    final target = _returnTo;
    _returnTo = null;
    final primary = FocusManager.instance.primaryFocus;
    final inside = _scope.hasFocus || primary == null;
    if (!inside) return;
    if (target != null && target.context != null && target.canRequestFocus) {
      target.requestFocus();
    } else {
      _scope.unfocus();
    }
  }

  void _focusEdge({required bool first}) {
    final nodes = _scope.traversalDescendants
        .where((n) => n.canRequestFocus && !n.skipTraversal)
        .toList();
    if (nodes.isEmpty) {
      _scope.requestFocus();
      return;
    }
    (first ? nodes.first : nodes.last).requestFocus();
  }

  void _close() => _controller.close();

  Widget _surface(BuildContext context, RawMenuOverlayInfo raw) {
    final direction = Directionality.of(context);
    final padding = MediaQuery.paddingOf(context);
    final m = widget.placement.margin;
    final overlay = Offset.zero & raw.overlaySize;
    final bounds = Rect.fromLTRB(
      overlay.left + padding.left + m,
      overlay.top + padding.top + m,
      overlay.right - padding.right - m,
      overlay.bottom - padding.bottom - m,
    );
    final anchor = raw.anchorRect;
    final side = _resolveSide(anchor, bounds, widget.placement, direction);
    final room = _room(anchor, bounds, side, widget.placement.gap, direction);
    final maxSize = side.isVertical
        ? Size(bounds.width.clamp(0.0, double.infinity), room)
        : Size(room, bounds.height.clamp(0.0, double.infinity));
    final info = DesignOverlayInfo(
      side: side,
      anchorRect: anchor,
      maxSize: maxSize,
      animation: _presence,
      close: _close,
    );
    Widget surface = Semantics(
      container: true,
      explicitChildNodes: true,
      label: widget.semanticLabel,
      child: widget.overlayBuilder(context, info),
    );
    surface = FocusScope(
      node: _scope,
      skipTraversal: true,
      canRequestFocus: widget.focusOnOpen || widget.arrowKeyNavigation,
      child: FocusTraversalGroup(child: surface),
    );
    // Above the scope, so a key from the scope itself bubbles through them.
    final shortcuts = <ShortcutActivator, Intent>{
      const SingleActivator(LogicalKeyboardKey.escape): const DismissIntent(),
      if (widget.arrowKeyNavigation) ...{
        const SingleActivator(LogicalKeyboardKey.arrowDown):
            const NextFocusIntent(),
        const SingleActivator(LogicalKeyboardKey.arrowUp):
            const PreviousFocusIntent(),
        const SingleActivator(LogicalKeyboardKey.home): const _FirstIntent(),
        const SingleActivator(LogicalKeyboardKey.end): const _LastIntent(),
      },
    };
    surface = Shortcuts(
      shortcuts: shortcuts,
      child: Actions(
        actions: {
          DismissIntent: CallbackAction<DismissIntent>(
            onInvoke: (_) => _close(),
          ),
          _FirstIntent: CallbackAction<_FirstIntent>(
            onInvoke: (_) => _focusEdge(first: true),
          ),
          _LastIntent: CallbackAction<_LastIntent>(
            onInvoke: (_) => _focusEdge(first: false),
          ),
        },
        child: surface,
      ),
    );
    final intent = _intent;
    if (intent != null) {
      surface = MouseRegion(
        hitTestBehavior: HitTestBehavior.deferToChild,
        onEnter: (_) => intent.enter(),
        onExit: (_) => intent.exit(),
        child: surface,
      );
    }
    surface = TapRegion(
      groupId: raw.tapRegionGroupId,
      consumeOutsideTaps: widget.consumeOutsideTaps,
      onTapOutside: (_) => _close(),
      child: surface,
    );
    return ConstrainedBox(
      constraints: BoxConstraints.loose(raw.overlaySize),
      child: CustomSingleChildLayout(
        delegate: _PlacementDelegate(
          anchor: anchor,
          bounds: bounds,
          side: side,
          placement: widget.placement,
          textDirection: direction,
          maxSize: maxSize,
        ),
        // Its own layer: a surface over the page repaints on its own, and
        // the alignment checks read its pixels.
        child: RepaintBoundary(child: surface),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RawMenuAnchor(
      controller: _controller,
      consumeOutsideTaps: widget.consumeOutsideTaps,
      useRootOverlay: widget.useRootOverlay,
      onOpenRequested: _onOpenRequested,
      onCloseRequested: _onCloseRequested,
      onOpen: _onOpen,
      onClose: _onClose,
      overlayBuilder: _surface,
      builder: (context, controller, _) {
        void toggle() =>
            controller.isOpen ? controller.close() : controller.open();
        Widget anchor = widget.anchorBuilder(
          context,
          DesignOverlayAnchor(
            controller: controller,
            isOpen: controller.isOpen,
            open: controller.open,
            close: controller.close,
            toggle: toggle,
          ),
        );
        if (widget.arrowKeyNavigation) {
          anchor = Actions(
            actions: {DirectionalFocusIntent: _LeaveArrows()},
            child: anchor,
          );
        }
        final intent = _intent;
        if (intent != null) {
          anchor = MouseRegion(
            onEnter: (_) => intent.enter(),
            onExit: (_) => intent.exit(),
            child: Focus(
              canRequestFocus: false,
              skipTraversal: true,
              includeSemantics: false,
              onFocusChange: (focused) {
                // A keyboard's focus shows the card; a tap's does not.
                final keyboard =
                    FocusManager.instance.highlightMode ==
                    FocusHighlightMode.traditional;
                if (focused && keyboard) {
                  intent.enter();
                } else if (!focused) {
                  intent.closeNow();
                }
              },
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                excludeFromSemantics: true,
                onLongPress: intent.openNow,
                child: anchor,
              ),
            ),
          );
        }
        return anchor;
      },
    );
  }
}
