/// iOS's swipe back from a screen's leading edge, kept round a look's own
/// page transitions, and the page and route that play a look's transition
/// with it. The swipe lives in Cupertino's page transition, which a look's
/// push of its own drops; this puts it back on the widgets layer, round any
/// [PageTransitionsBuilder].
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

import 'internal/gesture_focus.dart';
import 'motion.dart';

/// [builders] with the entries for [platforms] (iOS, by default) wrapped in
/// [SwipeBackPageTransitionsBuilder], so a page there pops with a
/// swipe from the screen's leading edge and otherwise plays the look's push.
///
/// ```dart
/// rawSwipeBack({TargetPlatform.iOS: const FadeUpwardsPageTransitionsBuilder()})
/// ```
Map<TargetPlatform, PageTransitionsBuilder> rawSwipeBack(
  Map<TargetPlatform, PageTransitionsBuilder> builders, {
  Set<TargetPlatform> platforms = const {TargetPlatform.iOS},
}) => {
  for (final MapEntry(:key, :value) in builders.entries)
    key: platforms.contains(key) && value is! SwipeBackPageTransitionsBuilder
        ? SwipeBackPageTransitionsBuilder(value)
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
/// A route takes one swipe however often its transition is wrapped (one of
/// these round another, or a builder that hands the route to one round its
/// own): the outermost plays it. A page in a navigator of its own keeps
/// its own swipe, which pops that navigator's page first.
///
/// ```dart
/// const SwipeBackPageTransitionsBuilder(FadeUpwardsPageTransitionsBuilder())
/// ```
class SwipeBackPageTransitionsBuilder extends PageTransitionsBuilder {
  /// [builder] with the swipe back round it.
  const SwipeBackPageTransitionsBuilder(this.builder);

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
      other is SwipeBackPageTransitionsBuilder && other.builder == builder;

  @override
  int get hashCode => Object.hash(SwipeBackPageTransitionsBuilder, builder);
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
    // A swipe back round this route's transition already: it plays the
    // swipe, and this one adds no second recognizer, no edge and no slide.
    final outer = context.getInheritedWidgetOfExactType<_SwipeBackRoute>();
    if (outer != null && identical(outer.route, widget.route)) {
      return widget.child;
    }
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
    final stack = Stack(
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
    return _SwipeBackRoute(route: widget.route, child: stack);
  }
}

// The route a swipe back plays round, for one nested inside it to see.
class _SwipeBackRoute extends InheritedWidget {
  const _SwipeBackRoute({required this.route, required super.child});

  final PageRoute<Object?> route;

  @override
  bool updateShouldNotify(_SwipeBackRoute oldWidget) =>
      !identical(route, oldWidget.route);
}

/// A page of a look's own screens in a [Navigator]'s page list (a router's
/// page builder), as Material's `MaterialPage` is a Material app's: its
/// route plays [transitionsBuilder], the look's page transition, with iOS's
/// swipe back round it on iOS only, and fades under Reduce Motion.
///
/// - **The transition.** [transitionsBuilder] is the look's bare page
///   transition; its durations are the route's. A look's
///   [PageTransitionsBuilder] is what it would put in a
///   `PageTransitionsTheme`.
/// - **Swipe back.** On iOS the route wraps the transition in a
///   [SwipeBackPageTransitionsBuilder], once: a builder that is one already
///   is played as it is. Elsewhere the transition is played as given.
/// - **Reduce Motion.** While the reader asks for reduced motion
///   (`rawReduceMotionOf`), the page fades in and out on the route's
///   animation in place of the look's transition; on iOS the swipe back
///   stays.
/// - **The page it holds now.** The route reads this page as the navigator
///   holds it: a router that gives the same key a new page (a new [child])
///   rebuilds the screen in place, its state kept.
/// - **Semantics.** The page is a route's scope to a screen reader, its
///   children's nodes its own, as a Material page's.
///
/// A route the next page plays over is one it can transition to: a page
/// pushed over it plays its secondary animation, a [fullscreenDialog] page
/// does not, as on iOS a sheet does not move the page under it.
///
/// ```dart
/// Navigator(pages: const [RawPage<void>(transitionsBuilder: FadeUpwardsPageTransitionsBuilder(), child: Text('Recipes'))], onDidRemovePage: (page) {})
/// ```
///
/// See also:
///
///  * [RawPageRoute], the same route pushed with `Navigator.push`.
class RawPage<T> extends Page<T> {
  /// A page showing [child], played in by [transitionsBuilder].
  const RawPage({
    required this.child,
    required this.transitionsBuilder,
    this.maintainState = true,
    this.fullscreenDialog = false,
    this.allowSnapshotting = true,
    super.key,
    super.canPop,
    super.onPopInvoked,
    super.name,
    super.arguments,
    super.restorationId,
  });

  /// The screen.
  final Widget child;

  /// The look's page transition, bare: the route adds iOS's swipe back on
  /// iOS.
  final PageTransitionsBuilder transitionsBuilder;

  /// Whether the route keeps its screen's state while another covers it
  /// ([ModalRoute.maintainState]). Defaults to true.
  final bool maintainState;

  /// Whether the page is a full-screen dialog: it takes no swipe back, and
  /// the page under it does not move as it comes in
  /// ([PageRoute.fullscreenDialog]). Defaults to false.
  final bool fullscreenDialog;

  /// Whether the route may be drawn from a snapshot while it transitions
  /// ([ModalRoute.allowSnapshotting]). Defaults to true.
  final bool allowSnapshotting;

  @override
  Route<T> createRoute(BuildContext context) => _PageBasedRawPageRoute<T>(this);
}

/// A route that plays a look's page transition, with iOS's swipe back round
/// it on iOS only, and a fade under Reduce Motion: [RawPage]'s, pushed with
/// `Navigator.push`, as `MaterialPageRoute` is `MaterialPage`'s.
///
/// ```dart
/// RawPageRoute<void>(transitionsBuilder: const FadeUpwardsPageTransitionsBuilder(), builder: (context) => const Text('Recipe'))
/// ```
class RawPageRoute<T> extends PageRoute<T> with _RawPageTransitions<T> {
  /// A route whose screen [builder] builds, played in by
  /// [transitionsBuilder].
  RawPageRoute({
    required this.builder,
    required this.transitionsBuilder,
    this.maintainState = true,
    super.settings,
    super.fullscreenDialog,
    super.allowSnapshotting,
    super.requestFocus,
    super.barrierDismissible,
  });

  /// Builds the screen.
  final WidgetBuilder builder;

  /// The look's page transition, bare: the route adds iOS's swipe back on
  /// iOS.
  @override
  final PageTransitionsBuilder transitionsBuilder;

  @override
  final bool maintainState;

  @override
  Widget _content(BuildContext context) => builder(context);

  @override
  String get debugLabel => '${super.debugLabel}(${settings.name})';
}

// RawPage's route: it reads the page it holds now.
class _PageBasedRawPageRoute<T> extends PageRoute<T>
    with _RawPageTransitions<T> {
  _PageBasedRawPageRoute(RawPage<T> page)
    : super(settings: page, allowSnapshotting: page.allowSnapshotting);

  RawPage<T> get _page => settings as RawPage<T>;

  @override
  PageTransitionsBuilder get transitionsBuilder => _page.transitionsBuilder;

  @override
  bool get maintainState => _page.maintainState;

  @override
  bool get fullscreenDialog => _page.fullscreenDialog;

  @override
  Widget _content(BuildContext context) => _page.child;

  @override
  String get debugLabel => '${super.debugLabel}(${_page.name})';
}

// What RawPage's route and RawPageRoute share: the look's transition, with
// the swipe back on iOS and a fade under Reduce Motion.
mixin _RawPageTransitions<T> on PageRoute<T> {
  PageTransitionsBuilder get transitionsBuilder;

  Widget _content(BuildContext context);

  @override
  Duration get transitionDuration => transitionsBuilder.transitionDuration;

  @override
  Duration get reverseTransitionDuration =>
      transitionsBuilder.reverseTransitionDuration;

  @override
  DelegatedTransitionBuilder? get delegatedTransition =>
      transitionsBuilder.delegatedTransition;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  bool canTransitionTo(TransitionRoute<dynamic> nextRoute) =>
      nextRoute is PageRoute && !nextRoute.fullscreenDialog;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) => Semantics(
    scopesRoute: true,
    explicitChildNodes: true,
    child: _content(context),
  );

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final given = transitionsBuilder;
    final swipe = given is SwipeBackPageTransitionsBuilder;
    final bare = swipe ? given.builder : given;
    final PageTransitionsBuilder played = rawReduceMotionOf(context)
        ? const _FadePageTransitionsBuilder()
        : bare;
    final onIOS = defaultTargetPlatform == TargetPlatform.iOS;
    return (onIOS || swipe ? SwipeBackPageTransitionsBuilder(played) : played)
        .buildTransitions<T>(
          this,
          context,
          animation,
          secondaryAnimation,
          child,
        );
  }
}

// Reduce Motion's page transition: a fade on the route's animation.
class _FadePageTransitionsBuilder extends PageTransitionsBuilder {
  const _FadePageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => FadeTransition(opacity: animation, child: child);
}
