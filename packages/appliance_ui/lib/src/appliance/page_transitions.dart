/// Appliance's page change: a faceplate sliding home along its track. The
/// new page runs in a short way from the end side, its leading parting line
/// casting a soft shade over the page it covers, and stops dead at its
/// detent; the page beneath slides back a little and dims. A pop runs it
/// back out.
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import 'material.dart';

/// Appliance's page change, as a widgets-level [PageTransitionsBuilder], so
/// one map ([appliancePageTransitions]) fits the `PageTransitionsTheme` of
/// Flutter's material library and of the one the look is built on.
///
/// ```dart
/// ThemeData(pageTransitionsTheme: const PageTransitionsTheme(builders: appliancePageTransitions))
/// ```
class AppliancePageTransitionsBuilder extends PageTransitionsBuilder {
  /// Appliance's page change.
  const AppliancePageTransitionsBuilder();

  /// How far a page runs in: a short slide, as a faceplate seats.
  static const double travel = 48;

  /// How far the page beneath slides back.
  static const double recede = 16;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 340);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 280);

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => _PageSlide(
    animation: animation,
    secondaryAnimation: secondaryAnimation,
    rises: route.fullscreenDialog,
    child: child,
  );
}

/// Appliance's page change on every platform, with iOS's swipe back from the
/// screen's leading edge round it there (ui_core's
/// [DesignSwipeBackPageTransitionsBuilder]). [ApplianceTheme] lays it in the
/// Material theme it builds; an app on Flutter's own `MaterialApp` puts it in
/// its `ThemeData`, which its `MaterialPageRoute` reads.
///
/// ```dart
/// MaterialApp(theme: ThemeData(pageTransitionsTheme: const PageTransitionsTheme(builders: appliancePageTransitions)), home: const Home())
/// ```
const Map<TargetPlatform, PageTransitionsBuilder> appliancePageTransitions = {
  TargetPlatform.android: AppliancePageTransitionsBuilder(),
  TargetPlatform.fuchsia: AppliancePageTransitionsBuilder(),
  // iOS's swipe back from the screen's edge, round Appliance's slide.
  TargetPlatform.iOS: DesignSwipeBackPageTransitionsBuilder(
    AppliancePageTransitionsBuilder(),
  ),
  TargetPlatform.linux: AppliancePageTransitionsBuilder(),
  TargetPlatform.macOS: AppliancePageTransitionsBuilder(),
  TargetPlatform.windows: AppliancePageTransitionsBuilder(),
};

/// A critically damped spring's travel (ζ = 1) over a transition's time:
/// fast away, settling dead on its detent with no overshoot.
class _SpringCurve extends Curve {
  const _SpringCurve(this.omega);

  /// The spring's natural frequency times the transition's duration.
  final double omega;

  double _x(double t) => 1 - (1 + omega * t) * math.exp(-omega * t);

  @override
  double transformInternal(double t) => _x(t) / _x(1);
}

class _PageSlide extends StatefulWidget {
  const _PageSlide({
    required this.animation,
    required this.secondaryAnimation,
    required this.rises,
    required this.child,
  });

  final Animation<double> animation;
  final Animation<double> secondaryAnimation;
  final bool rises;
  final Widget child;

  @override
  State<_PageSlide> createState() => _PageSlideState();
}

class _PageSlideState extends State<_PageSlide> {
  // √600 rad/s over 0.34 s: a lid's spring, settled by the end.
  static const _curve = _SpringCurve(8.3);

  late CurvedAnimation _in = _curved(widget.animation);
  late CurvedAnimation _under = _curved(widget.secondaryAnimation);

  CurvedAnimation _curved(Animation<double> parent) => CurvedAnimation(
    parent: parent,
    curve: _curve,
    reverseCurve: _curve.flipped,
  );

  @override
  void didUpdateWidget(_PageSlide old) {
    super.didUpdateWidget(old);
    if (old.animation != widget.animation) {
      _in.dispose();
      _in = _curved(widget.animation);
    }
    if (old.secondaryAnimation != widget.secondaryAnimation) {
      _under.dispose();
      _under = _curved(widget.secondaryAnimation);
    }
  }

  @override
  void dispose() {
    _in.dispose();
    _under.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final end = Directionality.of(context) == TextDirection.rtl ? -1.0 : 1.0;
    return AnimatedBuilder(
      animation: Listenable.merge([_in, _under]),
      child: widget.child,
      builder: (context, child) {
        final arrive = _in.value;
        final under = _under.value;
        // Solid within the first part of its run, so the page beneath never
        // shows through the words.
        final opacity = still ? arrive : (arrive / 0.35).clamp(0.0, 1.0);
        if (still) return Opacity(opacity: opacity, child: child);
        const travel = AppliancePageTransitionsBuilder.travel;
        final left = travel * (1 - arrive);
        final back = AppliancePageTransitionsBuilder.recede * under;
        final offset = widget.rises
            ? Offset(0, left)
            : Offset(end * (left - back), 0);
        Widget page = Transform.translate(offset: offset, child: child);
        if (under > 0) {
          // The page beneath dims as the new faceplate covers it.
          page = Stack(
            fit: StackFit.passthrough,
            children: [
              page,
              Positioned.fill(
                child: IgnorePointer(
                  child: ColoredBox(
                    color: Color.fromRGBO(30, 24, 18, 0.10 * under),
                  ),
                ),
              ),
            ],
          );
        }
        return Opacity(opacity: opacity, child: page);
      },
    );
  }
}

/// The router's page for a route pushed off a place: on the housing, with
/// Appliance's page change (and iOS's swipe back there).
///
/// ```dart
/// Navigator(pages: const [AppliancePage<void>(key: ValueKey('order'), child: OrderPage())], onDidRemovePage: (page) {})
/// ```
class AppliancePage<T> extends Page<T> {
  /// A page of [child].
  const AppliancePage({required this.child, super.key, super.name});

  /// The page.
  final Widget child;

  @override
  Route<T> createRoute(BuildContext context) => _AppliancePageRoute<T>(this);
}

class _AppliancePageRoute<T> extends PageRoute<T> {
  _AppliancePageRoute(AppliancePage<T> page) : super(settings: page);

  PageTransitionsBuilder get _builder =>
      appliancePageTransitions[defaultTargetPlatform] ??
      const AppliancePageTransitionsBuilder();

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => _builder.transitionDuration;

  @override
  Duration get reverseTransitionDuration => _builder.reverseTransitionDuration;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) => ApplianceHousing(child: (settings as AppliancePage<T>).child);

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => _builder.buildTransitions<T>(
    this,
    context,
    animation,
    secondaryAnimation,
    child,
  );
}
