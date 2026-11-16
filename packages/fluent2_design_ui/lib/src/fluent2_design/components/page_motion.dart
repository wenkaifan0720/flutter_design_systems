import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../theme.dart';

/// Fluent 2's page motion on each platform, as [Fluent2Theme] sets it in the
/// Material theme it builds: [Fluent2PageTransitionsBuilder] on every
/// platform, on iOS inside ui_core's [DesignSwipeBackPageTransitionsBuilder],
/// so a page there still pops with a swipe from the screen's leading edge,
/// following the finger. A map of widgets-level builders, so either Material's
/// `PageTransitionsTheme` takes it: an app on Flutter's own `MaterialApp`
/// pushes Flutter's `MaterialPageRoute`, which reads the app's theme rather
/// than the look's, so the app puts this map in its own `ThemeData` and its
/// routes move as the look's do.
///
/// ```dart
/// MaterialApp(theme: ThemeData(pageTransitionsTheme: const PageTransitionsTheme(builders: fluent2PageTransitions)), home: home)
/// ```
const Map<TargetPlatform, PageTransitionsBuilder> fluent2PageTransitions = {
  TargetPlatform.android: Fluent2PageTransitionsBuilder(),
  TargetPlatform.fuchsia: Fluent2PageTransitionsBuilder(),
  // iOS's swipe back from the screen's edge, round Fluent's push.
  TargetPlatform.iOS: DesignSwipeBackPageTransitionsBuilder(
    Fluent2PageTransitionsBuilder(),
  ),
  TargetPlatform.linux: Fluent2PageTransitionsBuilder(),
  TargetPlatform.macOS: Fluent2PageTransitionsBuilder(),
  TargetPlatform.windows: Fluent2PageTransitionsBuilder(),
};

/// Fluent 2's page motion, which a [Fluent2Theme] sets for every platform
/// (on iOS with the swipe back round it, [fluent2PageTransitions]), so the
/// page routes that read the look's theme move this way: a
/// `Fluent2Page`, a sheet's page. A route that reads the app widget's own
/// theme instead (a `MaterialPageRoute` under the app's `MaterialApp`)
/// moves this way once that theme carries [fluent2PageTransitions].
///
/// A page pushed in comes in over the page it leaves, which holds still:
/// it rises from transparent as it travels [Fluent2PageTransition.travel]
/// (20) from the reading end, or up from below for a full-screen dialog, on
/// Fluent's `durationGentle` (250 ms) and `curveDecelerateMid`. Popped, it
/// runs the same way back on `durationNormal` (200 ms), accelerating out.
/// A switch between a shell's roots (its nav pane, tab bar or rail) is no
/// push and does not move. With reduced motion asked for, each way is a cut.
///
/// A map of an app's own names it per platform, and on iOS wraps it in
/// ui_core's [DesignSwipeBackPageTransitionsBuilder] to keep the edge swipe.
///
/// ```dart
/// PageTransitionsTheme(builders: {TargetPlatform.android: Fluent2PageTransitionsBuilder(), TargetPlatform.iOS: DesignSwipeBackPageTransitionsBuilder(Fluent2PageTransitionsBuilder())})
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
