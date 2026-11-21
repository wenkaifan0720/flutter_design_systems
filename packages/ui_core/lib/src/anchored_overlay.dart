/// A surface anchored to a widget, headless: popovers, hover cards and menu
/// anchors. Placement beside the anchor (or at a point in it) that flips to
/// the side with room and shifts to stay on screen, clear of the on-screen
/// keyboard (right to left aware), outside taps and Escape to close, focus
/// moved in on open and returned on close, arrow keys through a menu, hover
/// intent with delays. The look paints the anchor and the surface.
///
/// Built on the widgets layer's [RawMenuAnchor] and [MenuController], so a
/// surface nested in another closes with it and a menubar's menus share one
/// group.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'internal/back.dart';
import 'internal/focus_visible.dart';
import 'internal/placement.dart';
import 'internal/quiet_focus.dart';
import 'internal/surface_focus.dart';
import 'motion.dart';

/// Which side of the anchor a surface sits on. [start] and [end] follow the
/// text direction.
enum RawPopoverSide {
  /// Under the anchor.
  below,

  /// Over the anchor.
  above,

  /// Before the anchor in reading order (left in left-to-right text).
  start,

  /// After the anchor in reading order.
  end;

  /// The side across the anchor.
  RawPopoverSide get opposite => switch (this) {
    below => above,
    above => below,
    start => end,
    end => start,
  };

  /// Whether the surface sits above or below.
  bool get isVertical => this == below || this == above;
}

/// How a surface lines up with its anchor along the side it sits on.
enum RawPopoverAlign {
  /// Their start edges line up (left edges in left-to-right text; top edges
  /// beside the anchor).
  start,

  /// Their centres line up.
  center,

  /// Their end edges line up.
  end,
}

/// What opens an anchored surface.
enum RawPopoverTrigger {
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
class RawPopoverPlacement {
  /// A placement on [side], lined up by [align].
  const RawPopoverPlacement({
    this.side = RawPopoverSide.below,
    this.align = RawPopoverAlign.start,
    this.gap = 4,
    this.margin = 8,
    this.flip = true,
    this.preferredExtent = 200,
    this.matchAnchorWidth = true,
    this.maxWidth = 320,
  }) : assert(maxWidth > 0);

  /// The side it prefers.
  final RawPopoverSide side;

  /// How it lines up along that side.
  final RawPopoverAlign align;

  /// Space between anchor and surface.
  final double gap;

  /// The least space between the surface and the screen's edge (beyond the
  /// safe area).
  final double margin;

  /// Whether it may move to the opposite side when its own lacks room.
  /// A leading-aligned menu with [matchAnchorWidth] can also align its
  /// trailing edge with the anchor to fit the screen. A trailing-aligned
  /// menu shifts only as far as the screen margin requires.
  final bool flip;

  /// The room it wants on its side before it flips: it flips when its side
  /// has less than this and the opposite side has more.
  final double preferredExtent;

  /// Whether, above or below the anchor, it is a list opened from a field
  /// (a select's, a combobox's, a menu from a form field): as wide as the
  /// anchor, wider only as far as its widest item needs, up to [maxWidth],
  /// never to the screen; with [align] at [RawPopoverAlign.start] it
  /// starts on the anchor's leading edge. Its width is set before its first
  /// frame, so a reveal inside it (an `Align` or a `SizeTransition` growing
  /// its height) stays under the field from the start. On by default; a
  /// popover that keeps its own width (a calendar under a date field, a
  /// picker) turns it off and sizes itself, its reveals sized to their
  /// child (`widthFactor: 1`) so they never spread to the overlay's width.
  /// Beside the anchor it has no effect.
  ///
  /// The widest item is read from the surface's intrinsic width, as
  /// `IntrinsicWidth` reads it: rows in a `Column` (in a
  /// `SingleChildScrollView` when they may scroll) say their width. A lazy
  /// list (a `ListView`) can't say it before it lays out, so it keeps the
  /// anchor's width.
  final bool matchAnchorWidth;

  /// With [matchAnchorWidth], the widest the surface grows past its anchor
  /// to fit its widest item, in logical pixels; an anchor wider than this
  /// keeps its own width. A long item past it wraps or fades, as the look
  /// draws it.
  final double maxWidth;

  @override
  bool operator ==(Object other) =>
      other is RawPopoverPlacement &&
      other.side == side &&
      other.align == align &&
      other.gap == gap &&
      other.margin == margin &&
      other.flip == flip &&
      other.preferredExtent == preferredExtent &&
      other.matchAnchorWidth == matchAnchorWidth &&
      other.maxWidth == maxWidth;

  @override
  int get hashCode => Object.hash(
    side,
    align,
    gap,
    margin,
    flip,
    preferredExtent,
    matchAnchorWidth,
    maxWidth,
  );
}

/// The anchor, as [RawPopover.anchorBuilder] gets it.
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

  /// Whether the surface is open. It becomes false as dismissal starts,
  /// so the anchor's expanded state follows the active menu.
  final bool isOpen;

  /// Opens it.
  final VoidCallback open;

  /// Closes it.
  final VoidCallback close;

  /// Opens it when closed, closes it when open: the anchor's press.
  final VoidCallback toggle;
}

/// What [RawPopover.overlayBuilder] paints the surface from.
@immutable
class RawPopoverInfo {
  /// Info for a surface on [side] of [anchorRect], opened at [position] when
  /// it opened at a point, whose place is told to [surfaceRect] (none, by
  /// default).
  const RawPopoverInfo({
    required this.side,
    required this.anchorRect,
    required this.maxSize,
    required this.animation,
    required this.close,
    this.position,
    this.surfaceRect = const _NoSurfaceRect(),
  });

  /// The side it sits on, after any flip: where an arrow points from, the
  /// edge a grow animation starts at.
  final RawPopoverSide side;

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

  /// The point it opened at, in the anchor's coordinates, as given to
  /// `MenuController.open(position:)` (a context menu at the pointer); null
  /// when it opened from the anchor. A surface opened at a point draws no
  /// arrow: [side] is the side of the point it took.
  final Offset? position;

  /// The surface's rectangle in the overlay once it is laid out, after any
  /// flip and shift; null before its first layout.
  ///
  /// It is set as the surface is laid out, before it is painted. So a
  /// `CustomPainter` given it as its `repaint` listenable, which reads it in
  /// `paint`, points a tail or an arrow at the anchor from the first frame
  /// and follows the surface as it moves: the anchor's middle in the
  /// surface's own coordinates is `anchorRect.center - surfaceRect.value!
  /// .topLeft` (or [position] less the surface's offset from the anchor, for
  /// a surface opened at a point). A widget that reads it while it builds (a
  /// `ValueListenableBuilder`) is one frame late: paint the tail instead.
  final ValueListenable<Rect?> surfaceRect;
}

// A surface rectangle no one tells: [RawPopoverInfo]'s default.
class _NoSurfaceRect implements ValueListenable<Rect?> {
  const _NoSurfaceRect();

  @override
  Rect? get value => null;

  @override
  void addListener(VoidCallback listener) {}

  @override
  void removeListener(VoidCallback listener) {}
}

/// The edges a surface opened under it keeps clear of, beyond the screen's
/// safe area and the on-screen keyboard: a look's own chrome over its pages,
/// such as a desktop side bar a page's overlay runs under.
///
/// Every [RawPopover] below it (and so every menu, list, popover,
/// context menu and tooltip of ui_core's) keeps its surface inside the
/// overlay less [padding], as it keeps clear of a notch. Put it round the
/// pages the chrome stands over: a side bar 280 wide at the start of the
/// screen, say.
///
/// ```dart
/// RawPopoverPadding(padding: const EdgeInsetsDirectional.only(start: 280), child: const Text('A page beside the side bar'))
/// ```
class RawPopoverPadding extends InheritedWidget {
  /// Keeps the surfaces opened in [child] [padding] clear of the overlay's
  /// edges.
  const RawPopoverPadding({
    super.key,
    required this.padding,
    required super.child,
  });

  /// How far in from each edge of the overlay a surface stays, resolved by
  /// the reading direction where it is directional.
  final EdgeInsetsGeometry padding;

  /// The padding above [context], resolved by its reading direction; none
  /// ([EdgeInsets.zero]) when there is none above it.
  static EdgeInsets of(BuildContext context) {
    final padding = context
        .dependOnInheritedWidgetOfExactType<RawPopoverPadding>()
        ?.padding;
    if (padding == null) return EdgeInsets.zero;
    return padding.resolve(Directionality.maybeOf(context));
  }

  @override
  bool updateShouldNotify(RawPopoverPadding oldWidget) =>
      padding != oldWidget.padding;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<EdgeInsetsGeometry>('padding', padding));
  }
}

/// Paints the anchor.
typedef DesignOverlayAnchorBuilder = Widget Function(
  BuildContext context,
  DesignOverlayAnchor anchor,
);

/// Paints the surface.
typedef RawPopoverOverlayBuilder = Widget Function(
  BuildContext context,
  RawPopoverInfo info,
);

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

// Down (forward) or Up in a menu.
class _StepIntent extends Intent {
  const _StepIntent({required this.forward});

  final bool forward;
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
/// ([RawPopoverTrigger.press], [focusOnOpen]), a hover card
/// ([RawPopoverTrigger.hover]) or a menu ([arrowKeyNavigation] on).
///
/// On open, focus moves into the surface (when [focusOnOpen]) and Tab stays
/// inside it; Escape, a tap outside or Android's back closes it, and focus
/// goes back to where it was (the anchor). The surface takes the side with
/// room ([RawPopoverPlacement]) and [RawPopoverInfo.side] says which;
/// it keeps clear of the screen's safe area, the on-screen keyboard and a
/// [RawPopoverPadding] above it. [RawPopoverInfo.surfaceRect] says
/// where it landed, for a tail or an arrow.
///
/// `controller.open(position: offset)` (an offset in the anchor) opens it at
/// that point, as a context menu opens at the pointer: below the point and
/// from its start in reading order, above it or towards its other end where
/// there is no room. [RawPopoverInfo.position] says so.
///
/// ```dart
/// RawPopover(anchorBuilder: (context, anchor) => GestureDetector(onTap: anchor.toggle, child: const Text('More')), overlayBuilder: (context, info) => const Text('Details'))
/// ```
class RawPopover extends StatefulWidget {
  /// A surface anchored to [anchorBuilder]'s widget.
  const RawPopover({
    super.key,
    required this.anchorBuilder,
    required this.overlayBuilder,
    this.controller,
    this.trigger = RawPopoverTrigger.press,
    this.placement = const RawPopoverPlacement(),
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
  }) : assert(dampingRatio > 0 && stiffness > 0);

  /// Paints the anchor; a press trigger calls [DesignOverlayAnchor.toggle].
  final DesignOverlayAnchorBuilder anchorBuilder;

  /// Paints the surface.
  final RawPopoverOverlayBuilder overlayBuilder;

  /// Opens and closes it from outside, and opens it at a point
  /// (`open(position:)`); null: it makes its own.
  final MenuController? controller;

  /// What opens it.
  final RawPopoverTrigger trigger;

  /// Where it goes.
  final RawPopoverPlacement placement;

  /// Whether focus moves into the surface when it opens (a popover, a menu)
  /// and Tab stays inside it; true by default. A hover card leaves focus on
  /// its anchor.
  ///
  /// It goes to the surface's first focusable widget, except in a menu
  /// ([arrowKeyNavigation]) a pointer opened: there it goes to the surface
  /// itself and no item is lit, as a menu opened with a click shows none;
  /// Down then focuses the first item and Up the last. A menu opened from
  /// the keys, or by a screen reader, starts on its first item.
  final bool focusOnOpen;

  /// Whether Up and Down move focus through the surface's items, wrapping,
  /// and Home and End go to the first and last: a menu; false by default.
  /// The arrows on the anchor are then the anchor's own and its ancestors'
  /// (a menubar moves along on them), never a move by geometry.
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
  State<RawPopover> createState() => _DesignAnchoredOverlayState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(
        ObjectFlagProperty<DesignOverlayAnchorBuilder>.has(
          'anchorBuilder',
          anchorBuilder,
        ),
      )
      ..add(
        ObjectFlagProperty<RawPopoverOverlayBuilder>.has(
          'overlayBuilder',
          overlayBuilder,
        ),
      )
      ..add(
        DiagnosticsProperty<MenuController>(
          'controller',
          controller,
          defaultValue: null,
        ),
      )
      ..add(
        EnumProperty<RawPopoverTrigger>(
          'trigger',
          trigger,
          defaultValue: RawPopoverTrigger.press,
        ),
      )
      ..add(
        DiagnosticsProperty<RawPopoverPlacement>(
          'placement',
          placement,
          defaultValue: const RawPopoverPlacement(),
        ),
      )
      ..add(
        FlagProperty(
          'focusOnOpen',
          value: focusOnOpen,
          ifFalse: 'focusOnOpen: false',
          defaultValue: true,
        ),
      )
      ..add(
        FlagProperty(
          'arrowKeyNavigation',
          value: arrowKeyNavigation,
          ifTrue: 'arrowKeyNavigation',
          defaultValue: false,
        ),
      )
      ..add(StringProperty('semanticLabel', semanticLabel, defaultValue: null))
      ..add(
        ObjectFlagProperty<ValueChanged<bool>>.has(
          'onOpenChanged',
          onOpenChanged,
        ),
      )
      ..add(
        DiagnosticsProperty<Duration>(
          'hoverOpenDelay',
          hoverOpenDelay,
          defaultValue: const Duration(milliseconds: 700),
        ),
      )
      ..add(
        DiagnosticsProperty<Duration>(
          'hoverCloseDelay',
          hoverCloseDelay,
          defaultValue: const Duration(milliseconds: 300),
        ),
      )
      ..add(
        FlagProperty(
          'consumeOutsideTaps',
          value: consumeOutsideTaps,
          ifTrue: 'consumeOutsideTaps',
          defaultValue: false,
        ),
      )
      ..add(
        FlagProperty(
          'useRootOverlay',
          value: useRootOverlay,
          ifTrue: 'useRootOverlay',
          defaultValue: false,
        ),
      )
      ..add(DoubleProperty('dampingRatio', dampingRatio, defaultValue: 1))
      ..add(DoubleProperty('stiffness', stiffness, defaultValue: 1400));
  }
}

class _DesignAnchoredOverlayState extends State<RawPopover>
    with SingleTickerProviderStateMixin {
  MenuController? _own;
  late final AnimationController _presence = AnimationController.unbounded(
    vsync: this,
  );
  late final FocusScopeNode _scope = FocusScopeNode(debugLabel: 'RawPopover');
  // The surface itself, inside [_scope]: a menu a pointer opened holds the
  // keys here, no item lit.
  final FocusNode _surfaceNode = FocusNode(
    debugLabel: 'RawPopover surface',
    skipTraversal: true,
  );
  // Where the surface landed, for the look's tail.
  final DesignSurfaceRect _placed = DesignSurfaceRect();
  // Whether the pointer moved last in the surface, else the keys.
  final ValueNotifier<bool> _byPointer = ValueNotifier(false);
  // The keys of a surface no item holds (a menu's typed letters).
  final ValueNotifier<FocusOnKeyEventCallback?> _surfaceKeys = ValueNotifier(
    null,
  );
  _HoverIntent? _intent;
  FocusNode? _returnTo;
  bool _open = false;
  // Closing: its spring running down. Focus has gone back; nothing in it
  // takes it again.
  bool _closing = false;
  DesignOpenedBy _openedBy = DesignOpenedBy.other;
  // A pointer resting on the anchor (any trigger): a click that arrives as a
  // semantics tap with no press (the web, semantics on) is the pointer's.
  bool _anchorHovered = false;

  // Round the anchor, taking no focus itself: the anchor's own node is the
  // first one in it that can take focus.
  final FocusNode _anchorArea = FocusNode(
    debugLabel: 'RawPopover anchor',
    canRequestFocus: false,
    skipTraversal: true,
  );
  // A pointer pressed on the anchor, until the frame its press ends in: the
  // open it makes is the anchor's, though a tap leaves the focus where it
  // was.
  bool _anchorPressed = false;

  void _anchorReleased() {
    WidgetsBinding.instance
      ..addPostFrameCallback((_) => _anchorPressed = false)
      ..ensureVisualUpdate();
  }

  // Where focus goes when the surface closes: to the anchor, when the anchor
  // opened it (pressed, clicked, or from the keys while focused), even after
  // a tap, as a menu button's menu gives it back; else where it was.
  FocusNode? _returnFor(FocusNode current) {
    if (_anchorArea.hasFocus) return current;
    // A region's (a context menu's): where it was, as a right click there
    // moves no focus.
    if (widget.key is DesignRegionAnchorKey) return current;
    if (_anchorPressed || _openedBy == DesignOpenedBy.pointer) {
      for (final node in _anchorArea.descendants) {
        if (node.canRequestFocus && !node.skipTraversal) return node;
      }
    }
    return current;
  }

  // While the surface is open, the anchor's route holds [_back]: a system
  // back (Android's button or gesture) closes it, innermost first, and the
  // page stays; the next back pops the page.
  late final DesignBackHold _back = DesignBackHold(() {
    if (mounted && _controller.isOpen) _controller.close();
  });
  ModalRoute<Object?>? _route;

  void _holdBack(bool on) => on ? _back.hold(_route) : _back.release();

  MenuController get _controller =>
      widget.controller ?? (_own ??= MenuController());

  @override
  void initState() {
    super.initState();
    _syncIntent();
  }

  // Whether the anchor's route is its navigator's top one; a route pushed
  // over it (an alert, a dialog, a sheet) closes the surface.
  bool _routeCurrent = true;
  // The anchor's route's focus scope, watched while the surface is open: a
  // route pushed on another navigator (an alert on the root navigator, over
  // a page in a nested one) leaves the anchor's route current in its own,
  // but takes the focus out of it.
  FocusNode? _routeScope;
  // Closing because a route covers the anchor: focus is the new route's,
  // never sent back to the anchor under it.
  bool _covered = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _route = ModalRoute.of(context);
    if (_back.isHeld) _holdBack(true);
    final current = ModalRoute.isCurrentOf(context) ?? true;
    final pushedOver = _routeCurrent && !current;
    _routeCurrent = current;
    if (pushedOver) _closeCovered();
  }

  // The scope a route puts round its page, which holds the anchor and the
  // surface (an overlay portal's child is focused where its portal is): of
  // the focus nodes round the anchor, the one its navigator holds.
  FocusNode? _scopeOfRoute() {
    final navigator = Navigator.maybeOf(context)?.focusNode;
    final here = Focus.maybeOf(context, scopeOk: true, createDependency: false);
    if (navigator == null || here == null) return null;
    for (final node in [here, ...here.ancestors]) {
      if (identical(node.parent, navigator)) return node;
    }
    return null;
  }

  bool get _focusLeftRoute {
    final scope = _routeScope;
    final primary = FocusManager.instance.primaryFocus;
    // The app sent to the background parks focus on the root scope.
    if (scope == null ||
        primary == null ||
        primary == FocusManager.instance.rootScope) {
      return false;
    }
    return primary != scope && !primary.ancestors.contains(scope);
  }

  void _focusMoved() {
    if (_controller.isOpen && _focusLeftRoute) _closeCovered();
  }

  void _watchFocus(bool on) {
    FocusManager.instance.removeListener(_focusMoved);
    _routeScope = on ? _scopeOfRoute() : null;
    if (on && _routeScope != null) {
      FocusManager.instance.addListener(_focusMoved);
    }
  }

  // Left open, the surface stays drawn in its own route, under the new
  // one, and keeps the focus. Closed once this frame is built.
  void _closeCovered() {
    if (!_controller.isOpen) return;
    WidgetsBinding.instance
      ..addPostFrameCallback((_) {
        if (!mounted || !_controller.isOpen) return;
        if (_routeCurrent && !_focusLeftRoute) return;
        _covered = true;
        _controller.close();
      })
      ..ensureVisualUpdate();
  }

  @override
  void didUpdateWidget(RawPopover oldWidget) {
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
    if (widget.trigger == RawPopoverTrigger.hover) {
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
    _watchFocus(false);
    _holdBack(false);
    _intent?.removeListener(_hoverChanged);
    _intent?.dispose();
    _presence.dispose();
    _scope.dispose();
    _surfaceNode.dispose();
    _placed.dispose();
    _byPointer.dispose();
    _surfaceKeys.dispose();
    _anchorArea.dispose();
    super.dispose();
  }

  SpringDescription get _spring => DesignMotionPolicy.of(context)
      .spatial(dampingRatio: widget.dampingRatio, stiffness: widget.stiffness);

  void _onOpenRequested(Offset? position, VoidCallback showOverlay) {
    _closing = false;
    _openedBy = designOpenedBy(
      pressed: _anchorPressed,
      hovered: _anchorHovered,
    );
    _byPointer.value = _openedBy == DesignOpenedBy.pointer;
    _placed.value = null;
    final current = FocusManager.instance.primaryFocus;
    if (current != null && !_scope.hasFocus && !_scope.hasPrimaryFocus) {
      _returnTo = _returnFor(current);
    }
    _holdBack(true);
    showOverlay();
    _presence.springTo(1, _spring);
  }

  void _onOpen() {
    if (!_open) {
      _open = true;
      widget.onOpenChanged?.call(true);
    }
    _watchFocus(true);
    _holdBack(true);
    if (widget.focusOnOpen) {
      // The surface mounts in this frame; focus it once it has.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_controller.isOpen) return;
        if (widget.arrowKeyNavigation && _openedBy == DesignOpenedBy.pointer) {
          _focusSurface();
        } else {
          _focusEdge(first: true);
        }
      });
    }
  }

  // The keys on the surface itself, no item lit.
  void _focusSurface() {
    if (_closing || !_controller.isOpen) return;
    if (_surfaceNode.context != null) _surfaceNode.requestFocus();
  }

  // Down or Up in a menu: from the surface itself, to the first or last
  // item; from an item, on to the next or previous, round past the ends.
  void _step({required bool forward}) {
    if (_surfaceNode.hasPrimaryFocus) {
      _focusEdge(first: forward);
      return;
    }
    final primary = FocusManager.instance.primaryFocus;
    forward ? primary?.nextFocus() : primary?.previousFocus();
  }

  void _onCloseRequested(VoidCallback hideOverlay) {
    // A menu that opens asks all its group's menus to close, itself among
    // them, before it shows: that request is not a close.
    if (!_controller.isOpen || _closing) return;
    _closing = true;
    if (_open) {
      setState(() => _open = false);
      widget.onOpenChanged?.call(false);
    }
    // A back while it closes is the page's.
    _holdBack(false);
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
    _closing = false;
    _watchFocus(false);
    _holdBack(false);
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
    if (_covered) {
      // A route over the anchor's has focus, or takes it as it builds.
      _covered = false;
      if (_scope.hasFocus) _scope.unfocus();
      return;
    }
    if (!inside) return;
    if (target != null && target.context != null && target.canRequestFocus) {
      // Given back, not given by the user: a field's list stays closed.
      DesignQuietFocus.restore(target);
    } else {
      _scope.unfocus();
    }
  }

  // Focuses the surface's first or last item and keeps it wholly in view.
  // From Home or End ([run]), a lazy list, which builds only the rows near
  // its view, runs to that end first, so its first or last row is built.
  void _focusEdge({required bool first, bool run = false}) {
    final nodes = _inReadingOrder(
      _scope.traversalDescendants
          .where((n) => n.canRequestFocus && !n.skipTraversal)
          .toList(),
    );
    if (nodes.isEmpty) {
      _scope.requestFocus();
      return;
    }
    final node = first ? nodes.first : nodes.last;
    final context = node.context;
    final position = context == null ? null : _innerScroll(context);
    if (run && position != null && position.hasContentDimensions) {
      final end = first ? position.minScrollExtent : position.maxScrollExtent;
      if (position.pixels != end) {
        position.jumpTo(end);
        WidgetsBinding.instance
          ..addPostFrameCallback((_) {
            if (mounted && _controller.isOpen) _focusEdge(first: first);
          })
          ..ensureVisualUpdate();
        return;
      }
    }
    node.requestFocus();
    final row = context?.findRenderObject();
    if (position == null || row == null || !row.attached) return;
    position
      ..ensureVisible(
        row,
        alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
      ).ignore()
      ..ensureVisible(
        row,
        alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtStart,
      ).ignore();
  }

  // [nodes] as they are read, top to bottom, then from the line's start: a
  // lazy list adds the rows it builds after those it built before, so the
  // order they joined the focus tree in is not where they are.
  List<FocusNode> _inReadingOrder(List<FocusNode> nodes) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    Rect? at(FocusNode node) {
      final box = node.context?.findRenderObject();
      return box is RenderBox && box.attached && box.hasSize ? node.rect : null;
    }

    final placed = [
      for (final (i, node) in nodes.indexed) (i: i, node: node, rect: at(node)),
    ];
    placed.sort((a, b) {
      final ra = a.rect, rb = b.rect;
      if (ra == null || rb == null) return a.i.compareTo(b.i);
      if ((ra.top - rb.top).abs() > 0.5) return ra.top.compareTo(rb.top);
      final along = rtl
          ? rb.right.compareTo(ra.right)
          : ra.left.compareTo(rb.left);
      return along != 0 ? along : a.i.compareTo(b.i);
    });
    return [for (final p in placed) p.node];
  }

  // The list that scrolls [context] inside the surface, if any: never the
  // page's round the anchor, which the surface sees as well (it inherits from
  // where its anchor is).
  ScrollPosition? _innerScroll(BuildContext context) {
    final inner = Scrollable.maybeOf(context);
    final scope = _scope.context;
    final outer = scope == null ? null : Scrollable.maybeOf(scope);
    return inner == null || identical(inner, outer) ? null : inner.position;
  }

  void _close() => _controller.close();

  // The overlay's own view, which the surface keeps clear of: the anchor's
  // may have had the keyboard's inset or the status bar's padding taken out
  // by a page's scaffold round it. A dependency on it, so a keyboard that
  // opens or a window that turns moves an open surface.
  MediaQueryData? _overlayView(BuildContext context) {
    final overlay = Overlay.maybeOf(
      context,
      rootOverlay: widget.useRootOverlay,
    )?.context;
    final view = overlay?.getElementForInheritedWidgetOfExactType<MediaQuery>();
    if (view == null) return MediaQuery.maybeOf(context);
    context.dependOnInheritedElement(view);
    return (view.widget as MediaQuery).data;
  }

  // The surface's keys while it holds them itself (no item lit): Tab goes to
  // the first item (Shift+Tab the last), anything else to [_surfaceKeys].
  KeyEventResult _onSurfaceKey(FocusNode node, KeyEvent event) {
    if (event is! KeyUpEvent) _byPointer.value = false;
    if (!_surfaceNode.hasPrimaryFocus) return KeyEventResult.ignored;
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.tab) {
      _focusEdge(first: !HardwareKeyboard.instance.isShiftPressed);
      return KeyEventResult.handled;
    }
    return _surfaceKeys.value?.call(node, event) ?? KeyEventResult.ignored;
  }

  Widget _surface(BuildContext context, RawMenuOverlayInfo raw) {
    final direction = Directionality.of(context);
    final bounds = designOverlayBounds(
      overlaySize: raw.overlaySize,
      view: _overlayView(context),
      padding: RawPopoverPadding.of(context),
      margin: widget.placement.margin,
    );
    // Opened at a point (a context menu at the pointer): placed round the
    // point, in the anchor's coordinates.
    final position = raw.position;
    final anchor = position == null
        ? raw.anchorRect
        : Rect.fromLTWH(
            raw.anchorRect.left + position.dx,
            raw.anchorRect.top + position.dy,
            0,
            0,
          );
    final gap = widget.placement.gap;
    final side = designResolveSide(anchor, bounds, widget.placement, direction);
    final maxSize = designOverlayMaxSize(anchor, bounds, side, gap, direction);
    final info = RawPopoverInfo(
      side: side,
      anchorRect: raw.anchorRect,
      maxSize: maxSize,
      animation: _presence,
      close: _close,
      position: position,
      surfaceRect: _placed,
    );
    Widget surface = Semantics(
      container: true,
      explicitChildNodes: true,
      label: widget.semanticLabel,
      child: widget.overlayBuilder(context, info),
    );
    surface = DesignSurfaceFocus(
      focusSurface: _focusSurface,
      byPointer: _byPointer,
      onKey: _surfaceKeys,
      child: surface,
    );
    if (widget.arrowKeyNavigation) {
      // The pointer moved: the rows follow it again, not the keys.
      surface = Listener(
        behavior: HitTestBehavior.translucent,
        onPointerHover: (_) => _byPointer.value = true,
        onPointerMove: (_) => _byPointer.value = true,
        onPointerDown: (_) => _byPointer.value = true,
        child: surface,
      );
    }
    surface = FocusScope(
      node: _scope,
      skipTraversal: true,
      canRequestFocus: widget.focusOnOpen || widget.arrowKeyNavigation,
      child: Focus(
        focusNode: _surfaceNode,
        includeSemantics: false,
        onKeyEvent: _onSurfaceKey,
        child: FocusTraversalGroup(child: surface),
      ),
    );
    // Above the scope, so a key from the scope itself bubbles through them.
    final shortcuts = <ShortcutActivator, Intent>{
      const SingleActivator(LogicalKeyboardKey.escape): const DismissIntent(),
      if (widget.arrowKeyNavigation) ...{
        const SingleActivator(LogicalKeyboardKey.arrowDown): const _StepIntent(
          forward: true,
        ),
        const SingleActivator(LogicalKeyboardKey.arrowUp): const _StepIntent(
          forward: false,
        ),
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
            onInvoke: (_) => _focusEdge(first: true, run: true),
          ),
          _LastIntent: CallbackAction<_LastIntent>(
            onInvoke: (_) => _focusEdge(first: false, run: true),
          ),
          _StepIntent: CallbackAction<_StepIntent>(
            onInvoke: (intent) => _step(forward: intent.forward),
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
    final layout = DesignOverlayLayout(
      anchor: anchor,
      bounds: bounds,
      side: side,
      placement: widget.placement,
      textDirection: direction,
      maxSize: maxSize,
      placed: _placed,
    );
    return ConstrainedBox(
      constraints: BoxConstraints.loose(raw.overlaySize),
      child: CustomSingleChildLayout(
        delegate: layout,
        // Its own layer: a surface over the page repaints on its own, and
        // the alignment checks read its pixels. A list from a field is as
        // wide as its widest item within the delegate's least and most.
        child: layout.matchesAnchor
            ? DesignListWidth(child: RepaintBoundary(child: surface))
            : RepaintBoundary(child: surface),
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
        void toggle() => _open ? controller.close() : controller.open();
        Widget anchor = widget.anchorBuilder(
          context,
          DesignOverlayAnchor(
            controller: controller,
            isOpen: _open,
            open: controller.open,
            close: controller.close,
            toggle: toggle,
          ),
        );
        anchor = Listener(
          onPointerDown: (_) => _anchorPressed = true,
          onPointerUp: (_) => _anchorReleased(),
          onPointerCancel: (_) => _anchorReleased(),
          child: MouseRegion(
            onEnter: (_) => _anchorHovered = true,
            onExit: (_) => _anchorHovered = false,
            child: Focus(
              focusNode: _anchorArea,
              includeSemantics: false,
              child: anchor,
            ),
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
                // A keyboard's focus shows the card; a tap's or a click's
                // does not, as for :focus-visible.
                final keyboard = DesignFocusVisible.shown;
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
