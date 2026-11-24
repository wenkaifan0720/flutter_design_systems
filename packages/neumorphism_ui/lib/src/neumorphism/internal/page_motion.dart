// The look's page change, on every platform: a page pushed over another fades up from the wall with a short travel
// from the reading end, the page under it holding still; a pop is the same change run back. No platform's own
// (Cupertino's full-width slide, the zoom) reaches a screen in this look: the theme's Material bridge and the router's
// pages both draw this one. A switch between top-level places (a side bar, a tab bar, a rail) is no route: it changes
// in place. On iOS, ui_core's swipe back stands round it: a finger from the leading edge takes the page back.
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ui_core/ui_core.dart';

import '../theme.dart';

/// How far a pushed page travels as it fades in, in logical pixels: a step, the same on a phone and a desktop.
const double neumorphicPageTravel = 16;

/// The page change for [animation] (a route's own, 0 to 1 as it is pushed, 1 to 0 as it is popped) over [child], as
/// the theme's motion at [context] has it: still under Reduce Motion.
Widget neumorphicPageTransition(
  BuildContext context,
  Animation<double> animation,
  Widget child,
) => _PageStep(animation: animation, child: child);

/// The step and the fade, eased on the theme's curves: in on its enter curve, back on its exit. One widget whatever the
/// motion, so a page never remounts when Reduce Motion is turned on under it.
class _PageStep extends StatefulWidget {
  const _PageStep({required this.animation, required this.child});

  final Animation<double> animation;
  final Widget child;

  @override
  State<_PageStep> createState() => _PageStepState();
}

class _PageStepState extends State<_PageStep> {
  CurvedAnimation? _eased;
  (Curve, Curve)? _curves;

  void _ease() {
    final motion = NeumorphicMotion.of(context);
    final curves = (motion.enter, motion.exit);
    if (_eased != null &&
        _curves == curves &&
        identical(_eased!.parent, widget.animation)) {
      return;
    }
    _eased?.dispose();
    _curves = curves;
    _eased = CurvedAnimation(
      parent: widget.animation,
      curve: curves.$1,
      reverseCurve: curves.$2,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _ease();
  }

  @override
  void didUpdateWidget(_PageStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    _ease();
  }

  @override
  void dispose() {
    _eased?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final still = NeumorphicMotion.of(context).travel == Duration.zero;
    final toward = Directionality.of(context) == TextDirection.rtl ? -1 : 1;
    final eased = _eased!;
    return FadeTransition(
      opacity: still ? kAlwaysCompleteAnimation : eased,
      child: AnimatedBuilder(
        animation: eased,
        // A translation, not a slide by the page's share: the step is the same at 390 and at 1920.
        builder: (context, child) => Transform.translate(
          offset: Offset(
            still ? 0 : (1 - eased.value) * neumorphicPageTravel * toward,
            0,
          ),
          child: child,
        ),
        child: widget.child,
      ),
    );
  }
}

/// [neumorphicPageTransition] for a [PageRoute] the app pushes (a `MaterialPageRoute`), at the theme's [motion]: a
/// push takes its travel, a pop its leave.
class NeumorphicPageMotion extends PageTransitionsBuilder {
  /// The page change at [motion]'s timing.
  const NeumorphicPageMotion([this.motion = const NeumorphicMotion()]);

  /// The timing the change takes.
  final NeumorphicMotion motion;

  @override
  Duration get transitionDuration => motion.travel;

  @override
  Duration get reverseTransitionDuration => motion.leave;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => neumorphicPageTransition(context, animation, child);
}

/// The look's page change for every platform Flutter runs on, for a `PageTransitionsTheme` of either Material, a
/// push taking [travel] and a pop [leave] (the change's curves are the theme's at the page). On iOS it keeps the swipe
/// back from the screen's leading edge (ui_core's `rawSwipeBack`). It takes the two durations rather than a
/// [NeumorphicMotion], so an app's own copy of the theme, with a timing type of its own, still reaches it.
Map<TargetPlatform, PageTransitionsBuilder> neumorphicPageTransitionBuilders({
  required Duration travel,
  required Duration leave,
}) {
  final motion = NeumorphicMotion(travel: travel, leave: leave);
  return rawSwipeBack({
    for (final platform in TargetPlatform.values)
      platform: NeumorphicPageMotion(motion),
  });
}

/// The look's page change for a route of its own on this device's platform: on iOS with the swipe back round it.
PageTransitionsBuilder neumorphicPageMotionHere(NeumorphicMotion motion) =>
    defaultTargetPlatform == TargetPlatform.iOS
    ? SwipeBackPageTransitionsBuilder(NeumorphicPageMotion(motion))
    : NeumorphicPageMotion(motion);

/// The stiffness (k) of a critically damped spring that comes within 2% of rest in [settle], as the look's timed move
/// of that length did (ω = 6 / [settle], k = ω²): ui_core's routes move on springs, the look's motion keeps durations,
/// so a theme that slows its moves slows its routes too. Under Reduce Motion ui_core's routes fade on their own.
double neumorphicRouteStiffness(Duration settle) {
  final seconds = settle.inMicroseconds / Duration.microsecondsPerSecond;
  final omega = 6 / (seconds < .001 ? .001 : seconds);
  return omega * omega;
}
