import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

/// The look's push: the new page fades in as it rises 8 px into place, and
/// only fades under Reduce Motion.
class LookPageTransitionsBuilder extends PageTransitionsBuilder {
  /// The look's push.
  const LookPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // A driven animation, not a CurvedAnimation: nothing to dispose.
    final eased = animation.drive(CurveTween(curve: Curves.easeOutCubic));
    final faded = FadeTransition(opacity: eased, child: child);
    if (designReduceMotionOf(context)) return faded;
    return AnimatedBuilder(
      animation: eased,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, 8 * (1 - eased.value)),
        child: child,
      ),
      child: faded,
    );
  }
}

/// The look's push on every platform, for an app's
/// `PageTransitionsTheme(builders: lookPageTransitions)`. On iOS it keeps
/// the swipe back from the screen's leading edge.
const Map<TargetPlatform, PageTransitionsBuilder> lookPageTransitions = {
  TargetPlatform.android: LookPageTransitionsBuilder(),
  TargetPlatform.iOS: SwipeBackPageTransitionsBuilder(
    LookPageTransitionsBuilder(),
  ),
  TargetPlatform.macOS: LookPageTransitionsBuilder(),
  TargetPlatform.windows: LookPageTransitionsBuilder(),
  TargetPlatform.linux: LookPageTransitionsBuilder(),
  TargetPlatform.fuchsia: LookPageTransitionsBuilder(),
};
