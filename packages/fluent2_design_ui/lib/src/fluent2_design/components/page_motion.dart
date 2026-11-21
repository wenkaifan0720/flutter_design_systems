import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../theme.dart';

/// The Fluent route transitions for each platform. Supply this map to your
/// app's `PageTransitionsTheme` so Material page routes use Fluent motion.
/// On iOS the transition also follows the leading-edge swipe-back gesture.
///
/// ```dart
/// MaterialApp(theme: ThemeData(pageTransitionsTheme: const PageTransitionsTheme(builders: fluent2PageTransitions)), home: home)
/// ```
const Map<TargetPlatform, PageTransitionsBuilder> fluent2PageTransitions = {
  TargetPlatform.android: Fluent2PageTransitionsBuilder(),
  TargetPlatform.fuchsia: Fluent2PageTransitionsBuilder(),
  // iOS's swipe back from the screen's edge, round Fluent's push.
  TargetPlatform.iOS: SwipeBackPageTransitionsBuilder(
    Fluent2PageTransitionsBuilder(),
  ),
  TargetPlatform.linux: Fluent2PageTransitionsBuilder(),
  TargetPlatform.macOS: Fluent2PageTransitionsBuilder(),
  TargetPlatform.windows: Fluent2PageTransitionsBuilder(),
};

/// Builds the Fluent transition for a pushed or popped page. The incoming
/// page fades in and travels 20 logical pixels from the trailing edge.
/// A full-screen dialog rises from below. The underlying page stays still.
/// Pushes take 250 ms and pops take 200 ms. With reduced motion enabled,
/// the route switches immediately.
///
/// [fluent2PageTransitions] installs this builder on each platform and
/// preserves the iOS swipe-back gesture.
///
/// ```dart
/// PageTransitionsTheme(builders: {TargetPlatform.android: Fluent2PageTransitionsBuilder(), TargetPlatform.iOS: SwipeBackPageTransitionsBuilder(Fluent2PageTransitionsBuilder())})
/// ```
class Fluent2PageTransitionsBuilder extends PageTransitionsBuilder {
  /// Fluent 2's page motion.
  const Fluent2PageTransitionsBuilder();

  @override
  Duration get transitionDuration => Fluent2Motion.gentle;

  @override
  Duration get reverseTransitionDuration => Fluent2Motion.normal;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => Fluent2PageTransition(
    animation: animation,
    rises: route.fullscreenDialog,
    child: child,
  );
}

/// A page coming in as Fluent 2 moves one ([Fluent2PageTransitionsBuilder]),
/// for a route an app builds itself: [child] rises from transparent as it
/// travels [travel] from the reading end (up from below with [rises]) while
/// [animation] runs forward, and back the same way while it runs in reverse.
/// The page under it holds still. With reduced motion asked for, it shows
/// as the push starts and is gone as the pop starts.
///
/// ```dart
/// PageRouteBuilder<void>(transitionDuration: Fluent2Motion.gentle, reverseTransitionDuration: Fluent2Motion.normal, pageBuilder: (context, animation, secondary) => const FilePage(), transitionsBuilder: (context, animation, secondary, child) => Fluent2PageTransition(animation: animation, child: child))
/// ```
class Fluent2PageTransition extends StatelessWidget {
  /// [child] moved by [animation].
  const Fluent2PageTransition({
    required this.animation,
    required this.child,
    this.rises = false,
    super.key,
  });

  /// How far a page travels, in logical pixels: Fluent's slide.
  static const double travel = 20;

  /// The route's own animation, 0 (out) to 1 (in).
  final Animation<double> animation;

  /// Whether the page comes up from below (a full-screen dialog) rather
  /// than in from the reading end.
  final bool rises;

  /// The page.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!Fluent2Motion.on(context)) {
      return AnimatedBuilder(
        animation: animation,
        builder: (context, page) => Opacity(
          opacity: switch (animation.status) {
            AnimationStatus.forward || AnimationStatus.completed => 1,
            AnimationStatus.reverse || AnimationStatus.dismissed => 0,
          },
          child: page,
        ),
        child: child,
      );
    }
    // In t, so it decelerates in and, run back, accelerates out
    // (decelerateMid run backwards is accelerateMid).
    final progress = animation.drive(
      CurveTween(curve: Fluent2Motion.decelerateMid),
    );
    final from = rises
        ? const Offset(0, travel)
        : Offset(
            Directionality.of(context) == TextDirection.rtl ? -travel : travel,
            0,
          );
    return AnimatedBuilder(
      animation: progress,
      builder: (context, page) =>
          Transform.translate(offset: from * (1 - progress.value), child: page),
      child: FadeTransition(opacity: progress, child: child),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<Animation<double>>('animation', animation))
      ..add(FlagProperty('rises', value: rises, ifTrue: 'rises'));
  }
}
