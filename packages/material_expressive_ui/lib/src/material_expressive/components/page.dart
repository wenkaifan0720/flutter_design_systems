/// Navigator pages with platform transitions and back gestures.
library;

import 'dart:ui' show lerpDouble;

import 'package:cupertino_ui/cupertino_ui.dart'
    show CupertinoPageTransition, CupertinoRouteTransitionMixin;
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart' show Theme;
import 'package:flutter/services.dart' show PredictiveBackEvent, SwipeEdge;
import 'package:flutter/widgets.dart';

import '../internal/gesture_focus.dart';
import '../motion.dart';
import '../theme.dart';
import 'overlays.dart' show ExpressiveBackHandleRoute;
import 'page_transitions.dart';

/// The go_router [Page] for a route pushed off a root, keyed by go_router's
/// page key. The page's chrome is derived, never authored: a screen inside
/// reads the pushed register (`RoutePresentation.of`) from the route's place.
///
/// On Android the push is fade-forwards and the back gesture predictive; on
/// iOS the push is the Cupertino slide and the back gesture the edge swipe;
/// everywhere else (macOS, Windows, Linux, the web) the push is
/// fade-forwards.
class ExpressivePage<T> extends Page<T> {
  /// A page showing [child].
  const ExpressivePage({
    required this.child,
    super.key,
    super.name,
    super.arguments,
    super.restorationId,
  });

  /// The page.
  final Widget child;

  /// The fade-forwards push and pop clock (every platform but iOS): AOSP's
  /// activity transition, 450 ms (`activity_open_enter.xml` and its three
  /// siblings, android-37.2).
  static const Duration fadeForwardsDuration = Duration(milliseconds: 450);

  /// The iOS push and pop clock: the Cupertino page slide, 500 ms
  /// (`CupertinoRouteTransitionMixin.kTransitionDuration`).
  static const Duration cupertinoDuration =
      CupertinoRouteTransitionMixin.kTransitionDuration;

  /// Compose's `PredictiveBack.transform` (material3
  /// `internal/BackHandler.kt`): `CubicBezierEasing(0.1f, 0.1f, 0f, 1f)`,
  /// a back gesture's progress as the page, a sheet or a search bar follows
  /// it. A progress mapping, not a clock; the one copy page, sheet and app
  /// bar share.
  static const Curve predictiveBackEasing = Cubic(0.1, 0.1, 0, 1);

  @override
  Route<T> createRoute(BuildContext context) =>
      _ExpressivePageRoute<T>(page: this, platform: Theme.of(context).platform);
}

/// Whether [platform] pushes with the Cupertino slide: iOS alone. On macOS
/// (the web on a Mac included) the slide carried a page across the whole
/// window; every platform but iOS pushes with fade-forwards.
bool _slides(TargetPlatform platform) => platform == TargetPlatform.iOS;

/// The look's push and pop for a page route it does not build itself (a
/// `MaterialPageRoute`, go_router's `MaterialPage`): the fade-forwards an
/// [ExpressivePage] pushes with, on its clock
/// ([ExpressivePage.fadeForwardsDuration]): the page travels 96dp and fades
/// in while the page beneath travels 96dp the other way; the pop is the
/// reverse. [expressivePageTransitions] names it for macOS, Windows,
/// Linux and Fuchsia.
class ExpressivePageTransitionsBuilder extends PageTransitionsBuilder {
  /// The look's push and pop.
  const ExpressivePageTransitionsBuilder();

  @override
  Duration get transitionDuration => ExpressivePage.fadeForwardsDuration;

  @override
  DelegatedTransitionBuilder? get delegatedTransition =>
      _delegatedPageTransition;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => _FadeForwardsBeneath(
    animation: secondaryAnimation,
    child: _FadeForwardsIn(animation: animation, child: child),
  );
}

/// The route an [ExpressivePage] stands for.
class _ExpressivePageRoute<T> extends PageRoute<T>
    with ExpressivePredictiveBackRoute<T>, ExpressiveBackHandleRoute<T> {
  _ExpressivePageRoute({
    required ExpressivePage<T> page,
    required this._platform,
  }) : super(settings: page);

  /// The platform the route last built under: its clock, and whether it
  /// claims the system's predictive back gesture.
  TargetPlatform _platform;

  ExpressivePage<T> get _page => settings as ExpressivePage<T>;

  @override
  TargetPlatform get predictiveBackPlatform => _platform;

  @override
  Duration get transitionDuration => _slides(_platform)
      ? ExpressivePage.cupertinoDuration
      : ExpressivePage.fadeForwardsDuration;

  @override
  Duration get reverseTransitionDuration => transitionDuration;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  DelegatedTransitionBuilder? get delegatedTransition =>
      _delegatedPageTransition;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) => Semantics(
    scopesRoute: true,
    explicitChildNodes: true,
    child: ColoredBox(
      color: context.expressiveTheme.colors.surface,
      // The page the route stands for now: go_router hands the route a new
      // page (same key, new child) when its state changes.
      child: SizedBox.expand(child: _page.child),
    ),
  );

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    _platform = Theme.of(context).platform;
    if (_slides(_platform)) {
      return CupertinoRouteTransitionMixin.buildPageTransitions<T>(
        this,
        context,
        animation,
        secondaryAnimation,
        child,
      );
    }
    return _FadeForwardsBeneath(
      animation: secondaryAnimation,
      child: ExpressivePredictiveBackTransition(
        route: this,
        animation: animation,
        child: child,
      ),
    );
  }
}

/// A page route whose system back gesture is Android's predictive back
///: [ExpressivePage]'s route and the full-screen dialog
/// ([ExpressiveSheetPage] with `drawer`) share it. The route builds its
/// page inside an [ExpressivePredictiveBackTransition], which draws the
/// gesture's frame; the route claims the gesture, follows it and settles
/// it by spring.
///
/// A route claims the gesture only while it is the page on screen: the
/// current route of a navigator that is itself on stage. Under go_router's
/// `StatefulShellRoute` every branch keeps its navigator mounted, off stage
/// with its tickers off, so each branch's top page is current in its own
/// navigator; the binding asks every observer, so without the stage check
/// a hidden branch's page would pop with the visible one.
mixin ExpressivePredictiveBackRoute<T> on PageRoute<T> {
  late final _BackGestureObserver _observer = _BackGestureObserver(this);
  final GestureFocus _gestureFocus = GestureFocus();

  /// The predictive back gesture in flight: the event it started with and
  /// the latest; null outside one.
  PredictiveBackEvent? _startEvent;
  PredictiveBackEvent? _currentEvent;

  /// The gesture's progress when it committed; null until it does.
  double? _committedAt;

  /// The platform whose back the route follows: never iOS, whose back is
  /// the edge swipe.
  TargetPlatform get predictiveBackPlatform =>
      Theme.of(navigator!.context).platform;

  @override
  void install() {
    super.install();
    WidgetsBinding.instance.addObserver(_observer);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(_observer);
    super.dispose();
  }

  /// Claims the system's back gesture (Android): only the page on screen,
  /// and never on iOS, whose page slides.
  bool _claim(PredictiveBackEvent event) {
    final navigator = this.navigator;
    if (navigator == null ||
        event.isButtonEvent ||
        !isCurrent ||
        !popGestureEnabled ||
        _slides(predictiveBackPlatform) ||
        !_onStage(navigator)) {
      return false;
    }
    _startEvent = _currentEvent = event;
    _committedAt = null;
    // The gesture takes the focus out of the route; cancelled, the route
    // has it back.
    _gestureFocus.hold(this);
    handleStartBackGesture(progress: 1 - event.progress);
    return true;
  }

  void _follow(PredictiveBackEvent event) {
    _currentEvent = event;
    handleUpdateBackGestureProgress(progress: 1 - event.progress);
  }

  @override
  void handleCancelBackGesture() => _settle(pop: false);

  @override
  void handleCommitBackGesture() => _settle(pop: true);

  /// Ends the gesture by spring: back onto the page on a cancel, off it on
  /// a commit (the navigator pops, and the spring carries the pop).
  void _settle({required bool pop}) {
    final navigator = this.navigator;
    final controller = this.controller;
    if (navigator == null || controller == null) return;
    final spring = ExpressiveMotion.of(navigator.context).defaultSpatial;
    void done() {
      _startEvent = _currentEvent = null;
      navigator.didStopUserGesture();
    }

    if (pop) {
      _committedAt = _currentEvent?.progress ?? 1 - controller.value;
      if (isCurrent) navigator.pop();
      // A gesture released at its full progress has already arrived: the
      // pop finished inline.
      if (!controller.isAnimating) return done();
      controller
          .animateBackWith(
            rawSpringSimulation(spring, from: controller.value, to: 0),
          )
          .whenCompleteOrCancel(done);
    } else {
      if (controller.isCompleted) return done();
      controller
          .animateWith(
            rawSpringSimulation(spring, from: controller.value, to: 1),
          )
          .whenCompleteOrCancel(done);
    }
  }
}

/// Whether [navigator] is the one on screen: nothing above it holds it off
/// stage or stops its tickers (a `StatefulShellRoute`'s inactive branch, an
/// overlay entry under an opaque route), and every route that encloses it
/// is the current route of its own navigator (a nested navigator under a
/// sheet on the root navigator).
bool _onStage(NavigatorState navigator) {
  var shown = true;
  navigator.context.visitAncestorElements((element) {
    final widget = element.widget;
    if ((widget is Offstage && widget.offstage) ||
        (widget is TickerMode && !widget.enabled)) {
      shown = false;
    }
    return shown;
  });
  if (!shown) return false;
  for (
    ModalRoute<Object?>? enclosing = ModalRoute.of(navigator.context);
    enclosing != null;
    enclosing = enclosing.navigator == null
        ? null
        : ModalRoute.of(enclosing.navigator!.context)
  ) {
    if (!enclosing.isCurrent) return false;
  }
  return true;
}

/// Hands the system's predictive back events to its route. (A route cannot
/// be the observer itself: [TransitionRoute]'s own back-gesture methods
/// share the observer's names.)
class _BackGestureObserver with WidgetsBindingObserver {
  _BackGestureObserver(this.route);

  final ExpressivePredictiveBackRoute<dynamic> route;

  @override
  bool handleStartBackGesture(PredictiveBackEvent backEvent) =>
      route._claim(backEvent);

  @override
  void handleUpdateBackGestureProgress(PredictiveBackEvent backEvent) =>
      route._follow(backEvent);

  @override
  void handleCancelBackGesture() => route.handleCancelBackGesture();

  @override
  void handleCommitBackGesture() => route.handleCommitBackGesture();
}

/// What a page does beneath the page pushed over it, offered to the route
/// below. One function for every page, so two Expressive pages share it and
/// the page beneath runs its own secondary transition.
Widget? _delegatedPageTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  bool allowSnapshotting,
  Widget? child,
) => _slides(Theme.of(context).platform)
    ? CupertinoPageTransition.delegatedTransition(
        context,
        animation,
        secondaryAnimation,
        allowSnapshotting,
        child,
      )
    : _FadeForwardsBeneath(
        animation: secondaryAnimation,
        child: child ?? const SizedBox.shrink(),
      );

// AOSP's activity transition (android-37.2, data/res/anim/
// activity_{open,close}_{enter,exit}.xml): the platform-owned push
//.

/// How far a page travels: `android:fromXDelta="96dp"`.
const _kTravel = 96.0;

/// The transition's length in ms: `android:duration="450"`.
const _kClock = 450.0;

/// The fades' length in ms: `android:duration="83"`.
const _kFade = 83.0;

/// When the open fade starts (`activity_open_enter`), in ms:
/// `android:startOffset="50"`.
const _kOpenFadeStart = 50.0;

/// When the close fade starts (`activity_close_exit`), in ms:
/// `android:startOffset="35"`.
const _kCloseFadeStart = 35.0;

/// `@interpolator/fast_out_extra_slow_in` (`M 0,0 C 0.05, 0, 0.133333,
/// 0.06, 0.166666, 0.4 C 0.208333, 0.82, 0.25, 1, 1, 1`), which Flutter's
/// `easeInOutCubicEmphasized` states point for point.
const Curve _kTravelCurve = Curves.easeInOutCubicEmphasized;

/// The open fade on the route's clock (forward).
const Curve _kFadeIn = Interval(
  _kOpenFadeStart / _kClock,
  (_kOpenFadeStart + _kFade) / _kClock,
);

/// The close fade on the route's clock, read backwards (reverse): the page
/// is gone [_kCloseFadeStart] + [_kFade] ms into a 450 ms pop.
const Curve _kFadeOut = Interval(
  1 - (_kCloseFadeStart + _kFade) / _kClock,
  1 - _kCloseFadeStart / _kClock,
);

// The predictive back motion spec (Android design guidance, "Predictive
// back › Motion specs"; the same constants as Flutter's
// PredictiveBackPageTransitionsBuilder).

/// The page's scale at the gesture's full progress.
const _kBackMinScale = 0.9;

/// The page shifts at most `extent / _kBackDivision - _kBackMargin`.
const _kBackDivision = 20.0;
const _kBackMargin = 8.0;

/// The display's corner radius when the platform publishes none (Flutter's
/// fallback, flutter/flutter#97349).
const _kBackDeviceCorner = 32.0;

/// The page's frame at a predictive back gesture's [progress] (0 to 1) on a
/// screen of [size], swiped from [edge], the finger having moved vertically
/// from [startY] to [touchY]: its scale about its centre, then its offset,
/// and the corner it rounds to when the display publishes none. The spec is
/// cited in this file's header.
@visibleForTesting
({double scale, Offset offset, double corner}) predictiveBackGeometry({
  required Size size,
  required double progress,
  SwipeEdge edge = SwipeEdge.left,
  double startY = 0,
  double touchY = 0,
}) {
  final eased = ExpressivePage.predictiveBackEasing.transform(
    progress.clamp(0.0, 1.0),
  );
  final xMax = size.width / _kBackDivision - _kBackMargin;
  final yMax = size.height / _kBackDivision - _kBackMargin;
  final rawY = touchY - startY;
  // Flutter's vertical follow, eyeballed on a Pixel 9 running Android 16.
  final y = size.height <= 0
      ? 0.0
      : (Curves.easeOut.transform((rawY.abs() / size.height).clamp(0.0, 1.0)) *
                rawY.sign *
                yMax)
            .clamp(-yMax, yMax);
  return (
    scale: lerpDouble(1, _kBackMinScale, eased)!,
    offset: Offset(xMax * eased * (edge == SwipeEdge.left ? 1 : -1), y),
    corner: _kBackDeviceCorner * eased,
  );
}

/// A page's own push and pop on Android, and its frame while the system's
/// predictive back gesture runs: one widget tree either way, so the page
/// keeps its state when a gesture starts. [ExpressivePage]'s route pushes
/// by fade-forwards; with [rise] the page rises from the bottom edge
/// instead (the full-screen dialog, whose route drives [animation] on its
/// springs). The [route] claims and settles the gesture.
class ExpressivePredictiveBackTransition extends StatefulWidget {
  /// A transition of [child] on [route], driven by [animation].
  const ExpressivePredictiveBackTransition({
    required this.route,
    required this.animation,
    required this.child,
    this.rise = false,
    super.key,
  });

  /// The route the transition belongs to.
  final ExpressivePredictiveBackRoute<dynamic> route;

  /// The route's own animation.
  final Animation<double> animation;

  /// Whether the page rises from the bottom edge (1 − [animation] of its
  /// height) rather than fade-forwards.
  final bool rise;

  /// The page the transition moves.
  final Widget child;

  @override
  State<ExpressivePredictiveBackTransition> createState() =>
      _PredictiveBackTransitionState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(
        DiagnosticsProperty<ExpressivePredictiveBackRoute<dynamic>>(
          'route',
          route,
        ),
      )
      ..add(DiagnosticsProperty<Animation<double>>('animation', animation))
      ..add(FlagProperty('rise', value: rise, ifTrue: 'rise'));
  }
}

class _PredictiveBackTransitionState
    extends State<ExpressivePredictiveBackTransition> {
  late CurvedAnimation _travel;
  late CurvedAnimation _fade;

  @override
  void initState() {
    super.initState();
    _curve();
  }

  @override
  void didUpdateWidget(ExpressivePredictiveBackTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animation != widget.animation) {
      _travel.dispose();
      _fade.dispose();
      _curve();
    }
  }

  void _curve() {
    _travel = CurvedAnimation(
      parent: widget.animation,
      curve: _kTravelCurve,
      reverseCurve: _kTravelCurve.flipped,
    );
    _fade = CurvedAnimation(
      parent: widget.animation,
      curve: _kFadeIn,
      reverseCurve: _kFadeOut,
    );
  }

  @override
  void dispose() {
    _travel.dispose();
    _fade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.animation,
    builder: (context, child) {
      final route = widget.route;
      final value = widget.animation.value;
      final sign = Directionality.of(context) == TextDirection.ltr ? 1 : -1;
      final rise = widget.rise;
      var offset = rise
          ? Offset.zero
          : Offset(_kTravel * (1 - _travel.value) * sign, 0);
      var lift = rise ? Offset(0, 1 - value) : Offset.zero;
      var scale = 1.0;
      var opacity = rise ? 1.0 : _fade.value;
      BorderRadius? corners;
      final gesture = route.popGestureInProgress && route._startEvent != null;
      if (gesture) {
        // The predictive back frame at the gesture's progress (the route's
        // value read backwards); after a commit, the frame the gesture
        // left, fading out as the spring carries the pop.
        final committed = route._committedAt;
        final geometry = predictiveBackGeometry(
          size: MediaQuery.sizeOf(context),
          progress: committed ?? 1 - value,
          edge: route._currentEvent?.swipeEdge ?? SwipeEdge.left,
          startY: route._startEvent?.touchOffset?.dy ?? 0,
          touchY: route._currentEvent?.touchOffset?.dy ?? 0,
        );
        offset = geometry.offset;
        lift = Offset.zero;
        scale = geometry.scale;
        opacity = committed == null || committed >= 1
            ? 1
            : (value / (1 - committed)).clamp(0.0, 1.0);
        corners =
            MediaQuery.maybeDisplayCornerRadiiOf(context) ??
            BorderRadius.all(Radius.circular(geometry.corner));
      }
      return IgnorePointer(
        // A page on its way out, or under the finger, takes no taps.
        ignoring: gesture || widget.animation.status == AnimationStatus.reverse,
        child: Transform.translate(
          offset: offset,
          child: Transform.scale(
            scale: scale,
            child: Opacity(
              opacity: opacity,
              child: ClipRRect(
                borderRadius: corners ?? BorderRadius.zero,
                clipBehavior: corners == null ? Clip.none : Clip.antiAlias,
                child: FractionalTranslation(translation: lift, child: child),
              ),
            ),
          ),
        ),
      );
    },
    child: widget.child,
  );
}

/// A page route's own page in a fade-forwards push and pop, for a route
/// that is not an [ExpressivePage] (whose page moves in an
/// [ExpressivePredictiveBackTransition]): it travels 96dp and fades in
/// (`activity_open_enter`), and back out on the pop (`activity_close_exit`).
class _FadeForwardsIn extends StatefulWidget {
  const _FadeForwardsIn({required this.animation, required this.child});

  final Animation<double> animation;
  final Widget child;

  @override
  State<_FadeForwardsIn> createState() => _FadeForwardsInState();
}

class _FadeForwardsInState extends State<_FadeForwardsIn> {
  late CurvedAnimation _travel;
  late CurvedAnimation _fade;

  @override
  void initState() {
    super.initState();
    _curve();
  }

  void _curve() {
    _travel = CurvedAnimation(
      parent: widget.animation,
      curve: _kTravelCurve,
      reverseCurve: _kTravelCurve.flipped,
    );
    _fade = CurvedAnimation(
      parent: widget.animation,
      curve: _kFadeIn,
      reverseCurve: _kFadeOut,
    );
  }

  @override
  void didUpdateWidget(_FadeForwardsIn oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animation != widget.animation) {
      _travel.dispose();
      _fade.dispose();
      _curve();
    }
  }

  @override
  void dispose() {
    _travel.dispose();
    _fade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.animation,
    builder: (context, child) {
      final sign = Directionality.of(context) == TextDirection.ltr ? 1 : -1;
      return IgnorePointer(
        // A page on its way out takes no taps.
        ignoring: widget.animation.status == AnimationStatus.reverse,
        child: Transform.translate(
          offset: Offset(_kTravel * (1 - _travel.value) * sign, 0),
          child: Opacity(opacity: _fade.value, child: child),
        ),
      );
    },
    child: widget.child,
  );
}

/// The page beneath a fade-forwards push: it travels 96dp against the push
/// at full opacity (`activity_open_exit`), and home again on the pop
/// (`activity_close_enter`).
class _FadeForwardsBeneath extends StatefulWidget {
  const _FadeForwardsBeneath({required this.animation, required this.child});

  final Animation<double> animation;
  final Widget child;

  @override
  State<_FadeForwardsBeneath> createState() => _FadeForwardsBeneathState();
}

class _FadeForwardsBeneathState extends State<_FadeForwardsBeneath> {
  late CurvedAnimation _travel = _curve();

  CurvedAnimation _curve() => CurvedAnimation(
    parent: widget.animation,
    curve: _kTravelCurve,
    reverseCurve: _kTravelCurve.flipped,
  );

  @override
  void didUpdateWidget(_FadeForwardsBeneath oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animation != widget.animation) {
      _travel.dispose();
      _travel = _curve();
    }
  }

  @override
  void dispose() {
    _travel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _travel,
    builder: (context, child) {
      final sign = Directionality.of(context) == TextDirection.ltr ? 1 : -1;
      return Transform.translate(
        offset: Offset(-_kTravel * _travel.value * sign, 0),
        child: child,
      );
    },
    child: widget.child,
  );
}
