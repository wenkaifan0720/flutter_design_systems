/// A side sheet, headless: a modal route whose panel slides in from the
/// start or end edge, under a barrier. Focus moves into it and back to the
/// opener when it closes; Escape, a barrier tap and a drag toward its edge
/// close it; under Reduce Motion it fades instead of sliding.
library;

import 'package:flutter/widgets.dart';

import 'localizations.dart';

/// Which edge a [DesignSideSheetRoute] comes from.
enum DesignSheetEdge {
  /// The reading start (left in English, right in Arabic).
  start,

  /// The reading end.
  end,
}

/// What a side sheet's panel gets to paint with.
@immutable
class DesignSheetInfo {
  /// The sheet's info; the route makes it.
  const DesignSheetInfo({
    required this.side,
    required this.animation,
    required this.dragging,
    required this.close,
  });

  /// The side it is on, resolved for the text direction
  /// ([AxisDirection.left] or [AxisDirection.right]).
  final AxisDirection side;

  /// Its presence, 0 (gone) to 1 (open), for a look's own fades.
  final Animation<double> animation;

  /// Whether a finger is dragging it.
  final bool dragging;

  /// Closes it (its close button).
  final VoidCallback close;
}

/// A modal side sheet. Push it with `Navigator.push`; its panel is
/// [builder]'s, sized to [width] (at most the screen less [minGap]) and the
/// full height.
///
/// It opens and closes eased. A drag moves it with the finger from where it
/// is drawn, and let go, it settles from there (back open, or closed past a
/// third of its width or on a fling), so no frame jumps.
///
/// ```dart
/// DesignSideSheetRoute<void>(builder: (context, sheet) => const SizedBox(width: 320))
/// ```
class DesignSideSheetRoute<T> extends PopupRoute<T> {
  /// A sheet whose panel [builder] paints.
  DesignSideSheetRoute({
    required this.builder,
    this.edge = DesignSheetEdge.end,
    this.width = 360,
    this.minGap = 56,
    Color barrierColor = const Color(0x66000000),
    String? barrierLabel,
    bool barrierDismissible = true,
    this.dragToClose = true,
    this.semanticLabel,
    Duration transitionDuration = const Duration(milliseconds: 300),
    super.settings,
  }) : _scrim = barrierColor,
       _givenBarrierLabel = barrierLabel,
       _dismissOnBarrier = barrierDismissible,
       _transition = transitionDuration;

  /// Paints the panel.
  final Widget Function(BuildContext context, DesignSheetInfo sheet) builder;

  /// The edge it comes from.
  final DesignSheetEdge edge;

  /// The panel's width.
  final double width;

  /// The least room left beside it on a narrow screen.
  final double minGap;

  /// Whether a drag toward its edge closes it.
  final bool dragToClose;

  /// What a screen reader calls it.
  final String? semanticLabel;

  final Color _scrim;
  final bool _dismissOnBarrier;
  final Duration _transition;
  final ValueNotifier<double?> _drag = ValueNotifier(null);

  // Whether the panel is where the route's animation says, unchanged (a
  // finger's drag, and the settle after it), rather than eased.
  bool _linear = false;
  CurvedAnimation? _eased;

  final String? _givenBarrierLabel;

  /// What a screen reader calls the barrier; null:
  /// [DesignLocalizations.sideSheetBarrierLabel].
  @override
  String? get barrierLabel {
    final context = navigator?.context;
    return _givenBarrierLabel ??
        (context == null
            ? null
            : DesignLocalizations.of(context).sideSheetBarrierLabel);
  }

  @override
  Color? get barrierColor => _scrim;

  @override
  bool get barrierDismissible => _dismissOnBarrier;

  @override
  Duration get transitionDuration => _transition;

  @override
  void install() {
    super.install();
    controller!.addStatusListener(_settled);
  }

  // A settle after a drag has ended: eased again from here, where eased
  // and unchanged agree (open or gone).
  void _settled(AnimationStatus status) {
    if (_drag.value == null && !status.isAnimating) _linear = false;
  }

  @override
  void dispose() {
    _eased?.dispose();
    _drag.dispose();
    super.dispose();
  }

  void _dragStart() {
    // The finger takes the panel from where it is drawn, even part way
    // through opening.
    final eased = _eased;
    if (!_linear && eased != null) controller!.value = eased.value;
    _linear = true;
    _drag.value = 0;
    navigator?.didStartUserGesture();
  }

  // [delta]: the drag toward the edge, in sheet widths.
  void _dragUpdate(double delta) {
    final c = controller!;
    c.value -= delta;
    _drag.value = 1 - c.value;
  }

  // [fling]: the speed toward the edge, in sheet widths a second.
  void _dragEnd(double fling, {bool settle = false}) {
    // A pointer that never became a drag (a tap on the sheet's content)
    // ends in a cancel: nothing moved and no user gesture was started.
    if (_drag.value == null) return;
    _drag.value = null;
    final close =
        !settle && (fling > 1 || (fling > -1 && controller!.value < 2 / 3));
    final c = controller!;
    // It settles from where it was let go, over the whole transition, slowing
    // as it arrives.
    if (close) {
      navigator?.pop();
      if (c.status == AnimationStatus.reverse) {
        c.animateBack(0, duration: _transition, curve: Curves.easeOutCubic);
      }
    } else {
      c.animateTo(1, duration: _transition, curve: Curves.easeOutCubic);
    }
    navigator?.didStopUserGesture();
  }

  double _panelWidth(BuildContext context) {
    final screen = MediaQuery.sizeOf(context).width;
    return width.clamp(0.0, (screen - minGap).clamp(0.0, screen));
  }

  AxisDirection _side(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final left = (edge == DesignSheetEdge.start) != rtl;
    return left ? AxisDirection.left : AxisDirection.right;
  }

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    final side = _side(context);
    final w = _panelWidth(context);
    return Align(
      alignment: side == AxisDirection.left
          ? Alignment.centerLeft
          : Alignment.centerRight,
      child: SizedBox(
        width: w,
        height: double.infinity,
        child: Semantics(
          scopesRoute: true,
          namesRoute: true,
          explicitChildNodes: true,
          label: semanticLabel,
          child: _DragToClose(
            route: this,
            enabled: dragToClose,
            side: side,
            width: w,
            child: ValueListenableBuilder<double?>(
              valueListenable: _drag,
              builder: (context, drag, _) => builder(
                context,
                DesignSheetInfo(
                  side: side,
                  animation: animation,
                  dragging: drag != null,
                  close: () => Navigator.of(context).maybePop(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return FadeTransition(opacity: animation, child: child);
    }
    // The page is the screen's width; the panel moves its own, so a finger
    // and the panel move together.
    final screen = MediaQuery.sizeOf(context).width;
    final panel = screen == 0 ? 1.0 : _panelWidth(context) / screen;
    final from = (_side(context) == AxisDirection.left ? -1.0 : 1.0) * panel;
    final eased = _eased ??= CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    return SlideTransition(
      position: Tween(
        begin: Offset(from, 0),
        end: Offset.zero,
      ).animate(_SheetPlace(this, eased)),
      child: child,
    );
  }
}

// Where the panel is drawn, 0 (gone) to 1 (open): eased while the route
// opens or closes on its own, the route's own value from a drag's start
// until the settle after it ends.
class _SheetPlace extends Animation<double>
    with AnimationWithParentMixin<double> {
  _SheetPlace(this.route, this.eased);

  final DesignSideSheetRoute<Object?> route;
  final CurvedAnimation eased;

  @override
  Animation<double> get parent => eased.parent;

  @override
  double get value => route._linear ? parent.value : eased.value;
}

// A drag toward the sheet's edge moves it with the finger; past a third of
// its width or a fling, it closes, else it goes back.
class _DragToClose extends StatelessWidget {
  const _DragToClose({
    required this.route,
    required this.enabled,
    required this.side,
    required this.width,
    required this.child,
  });

  final DesignSideSheetRoute<Object?> route;
  final bool enabled;
  final AxisDirection side;
  final double width;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;
    final sign = side == AxisDirection.left ? -1.0 : 1.0;
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragStart: (_) => route._dragStart(),
      onHorizontalDragUpdate: (d) =>
          route._dragUpdate(d.primaryDelta! * sign / width),
      onHorizontalDragEnd: (d) =>
          route._dragEnd(d.primaryVelocity! * sign / width),
      onHorizontalDragCancel: () => route._dragEnd(0, settle: true),
      child: child,
    );
  }
}
