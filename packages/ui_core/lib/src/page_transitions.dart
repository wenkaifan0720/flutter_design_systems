/// iOS's swipe back from a screen's leading edge, kept round a look's own
/// page transitions. The swipe lives in Cupertino's page transition, which a
/// look's push of its own drops; this puts it back on the widgets layer,
/// round any [PageTransitionsBuilder].
library;

import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

import 'internal/gesture_focus.dart';

/// [builders] with the entries for [platforms] (iOS, by default) wrapped in
/// [DesignSwipeBackPageTransitionsBuilder], so a page there pops with a
/// swipe from the screen's leading edge and otherwise plays the look's push.
///
/// ```dart
/// designSwipeBack({TargetPlatform.iOS: const FadeUpwardsPageTransitionsBuilder()})
/// ```
Map<TargetPlatform, PageTransitionsBuilder> designSwipeBack(
  Map<TargetPlatform, PageTransitionsBuilder> builders, {
  Set<TargetPlatform> platforms = const {TargetPlatform.iOS},
}) => {
  for (final MapEntry(:key, :value) in builders.entries)
    key:
        platforms.contains(key) &&
            value is! DesignSwipeBackPageTransitionsBuilder
        ? DesignSwipeBackPageTransitionsBuilder(value)
        : value,
};

/// [builder]'s page transition with iOS's swipe back from the screen's
/// leading edge round it.
///
/// A finger dragging from the leading edge (20 points, or the safe area's
/// inset when wider) moves the page with it and shows the one under it,
/// shifted a third, as on every iOS screen; let go past half way, or flung
/// that way, the page pops, else it settles back. Meanwhile [builder]'s
/// transition rests, and it plays the look's push and pop as before. A first
/// page, a full-screen dialog and a page that refuses to pop take no swipe.
///
/// ```dart
/// const DesignSwipeBackPageTransitionsBuilder(FadeUpwardsPageTransitionsBuilder())
/// ```
class DesignSwipeBackPageTransitionsBuilder extends PageTransitionsBuilder {
  /// [builder] with the swipe back round it.
  const DesignSwipeBackPageTransitionsBuilder(this.builder);

  /// The look's page transition.
  final PageTransitionsBuilder builder;

  @override
  Duration get transitionDuration => builder.transitionDuration;

  @override
  Duration get reverseTransitionDuration => builder.reverseTransitionDuration;

  @override
  DelegatedTransitionBuilder? get delegatedTransition =>
      builder.delegatedTransition;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // The navigator rebuilds every route's transitions as a swipe starts and
    // ends; while it lasts, the look's transition rests.
    final swiping = route.popGestureInProgress;
    return _SwipeBack<T>(
      route: route,
      animation: animation,
      secondaryAnimation: secondaryAnimation,
      swiping: swiping,
      child: builder.buildTransitions<T>(
        route,
        context,
        swiping ? kAlwaysCompleteAnimation : animation,
        swiping ? kAlwaysDismissedAnimation : secondaryAnimation,
        child,
      ),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is DesignSwipeBackPageTransitionsBuilder &&
      other.builder == builder;

  @override
  int get hashCode =>
      Object.hash(DesignSwipeBackPageTransitionsBuilder, builder);
}

// iOS's: the edge a swipe starts in, a fling's least speed (screen widths a
// second) and a dropped swipe's longest settle.
const double _edge = 20;
const double _fling = 1;
const Duration _settleTime = Duration(milliseconds: 350);

class _SwipeBack<T> extends StatefulWidget {
  const _SwipeBack({
    required this.route,
    required this.animation,
    required this.secondaryAnimation,
    required this.swiping,
    required this.child,
  });

  final PageRoute<T> route;
  final Animation<double> animation;
  final Animation<double> secondaryAnimation;
  final bool swiping;
  final Widget child;

  @override
  State<_SwipeBack<T>> createState() => _SwipeBackState<T>();
}

class _SwipeBackState<T> extends State<_SwipeBack<T>>
    with SingleTickerProviderStateMixin {
  // From where the finger went down: where the page paints nothing at its
  // edge, the route's barrier is hit too and holds the gesture until the
  // drag passes its slop, which a drag from where it was accepted would
  // drop, the page trailing the finger by it.
  late final HorizontalDragGestureRecognizer _drag =
      HorizontalDragGestureRecognizer(debugOwner: this)
        ..dragStartBehavior = DragStartBehavior.down
        ..onStart = _start
        ..onUpdate = _update
        ..onEnd = _end
        ..onCancel = _cancel;
  late final AnimationController _settle = AnimationController(
    vsync: this,
    duration: _settleTime,
  )..addListener(_settled);
  // From this page's swipe starting until the route is told it ended.
  NavigatorState? _gesture;
  // A swipe takes the focus out of the page; left there, it has it back.
  final GestureFocus _gestureFocus = GestureFocus();
  bool _dragging = false;

  PageRoute<T> get _route => widget.route;

  // A drag along the leading edge, in the page's direction: right in a
  // left-to-right layout.
  double _along(double dx) =>
      Directionality.of(context) == TextDirection.rtl ? -dx : dx;

  @override
  void dispose() {
    _drag.dispose();
    _settle.dispose();
    final navigator = _gesture;
    if (navigator != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (navigator.mounted) navigator.didStopUserGesture();
      });
    }
    super.dispose();
  }

  // A first page, a page mid-transition, a full-screen dialog and a page
  // that refuses to pop take no swipe; nor does a page under another.
  bool get _canSwipe =>
      _gesture == null &&
      _route.isCurrent &&
      !_route.fullscreenDialog &&
      _route.popGestureEnabled;

  void _down(PointerDownEvent event) {
    if (_canSwipe) _drag.addPointer(event);
  }

  void _start(DragStartDetails details) {
    if (!_canSwipe) return;
    _gesture = _route.navigator;
    _dragging = true;
    _gestureFocus.hold(_route);
    _route.handleStartBackGesture(progress: _route.animation!.value);
  }

  void _update(DragUpdateDetails details) {
    final width = context.size?.width ?? 0;
    if (!_dragging || width <= 0) return;
    _route.handleUpdateBackGestureProgress(
      progress:
          (_route.animation!.value - _along(details.primaryDelta ?? 0) / width)
              .clamp(0.0, 1.0),
    );
  }

  void _end(DragEndDetails details) {
    if (!_dragging) return;
    _dragging = false;
    final width = context.size?.width ?? 0;
    final speed = width <= 0
        ? 0.0
        : _along(details.velocity.pixelsPerSecond.dx) / width;
    final value = _route.animation!.value;
    _drop(pop: speed.abs() >= _fling ? speed > 0 : value < 0.5, from: value);
  }

  void _cancel() {
    if (!_dragging) return;
    _dragging = false;
    _drop(pop: false, from: _route.animation!.value);
  }

  // Runs the page the rest of the way, off or back, then tells the route:
  // a route told to pop mid-way would play the look's pop from the start.
  void _drop({required bool pop, required double from}) {
    final to = pop ? 0.0 : 1.0;
    _settle
      ..value = from
      ..animateTo(
        to,
        duration: _settleTime * math.max((to - from).abs(), 0.1),
        curve: Curves.fastLinearToSlowEaseIn,
      ).whenCompleteOrCancel(() {
        if (!mounted || _gesture == null) return;
        _gesture = null;
        if (pop) {
          _route.handleCommitBackGesture();
        } else {
          _route.handleCancelBackGesture();
        }
      });
  }

  void _settled() {
    if (_gesture != null && !_dragging) {
      _route.handleUpdateBackGestureProgress(progress: _settle.value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final swiping = widget.swiping;
    // The same widgets swiping or not, so the page keeps its state. While a
    // swipe lasts, the page follows the finger and the one under it moves a
    // third of the way with it, as Cupertino's.
    final page = SlideTransition(
      position: swiping
          ? Tween(
              begin: Offset.zero,
              end: Offset(rtl ? 1 / 3 : -1 / 3, 0),
            ).animate(widget.secondaryAnimation)
          : const AlwaysStoppedAnimation(Offset.zero),
      child: SlideTransition(
        position: swiping
            ? Tween(
                begin: Offset(rtl ? -1 : 1, 0),
                end: Offset.zero,
              ).animate(widget.animation)
            : const AlwaysStoppedAnimation(Offset.zero),
        child: widget.child,
      ),
    );
    final padding = MediaQuery.paddingOf(context);
    return Stack(
      fit: StackFit.passthrough,
      children: [
        page,
        PositionedDirectional(
          start: 0,
          width: math.max(rtl ? padding.right : padding.left, _edge),
          top: 0,
          bottom: 0,
          child: Listener(
            onPointerDown: _down,
            behavior: HitTestBehavior.translucent,
          ),
        ),
      ],
    );
  }
}
