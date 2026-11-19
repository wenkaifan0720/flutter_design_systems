import 'package:material_ui/material_ui.dart';
import 'package:ui_core/ui_core.dart';

import '../chrome_metrics.dart';
import '../theme.dart';

/// Page transitions shared by [MinimalPage], [MinimalFadeRoute] and
/// [minimalPageTransitions]. Durations come from [MinimalChromeMetrics].
/// Reduced motion presents the destination in place.

/// Minimal's push for every platform, for a `PageTransitionsTheme`: a page
/// fades in over [MinimalChromeMetrics.pushSlide] and a pop reverses it, where
/// the platform's own would slide or zoom it in.
///
/// [MinimalTheme] puts it in the Material theme it builds. An app on
/// Flutter's own `MaterialApp` puts it in its `ThemeData` too, since a
/// `MaterialPageRoute` plays the push its own Material's theme names:
///
/// ```dart
/// MaterialApp(
///   theme: ThemeData(
///     pageTransitionsTheme: const PageTransitionsTheme(
///       builders: minimalPageTransitions,
///     ),
///   ),
///   builder: (context, child) =>
///       MinimalTheme(data: MinimalThemeData.standard(), child: child!),
///   home: const InboxPage(),
/// )
/// ```
const Map<TargetPlatform, PageTransitionsBuilder> minimalPageTransitions = {
  TargetPlatform.android: MinimalPageTransitions(),
  TargetPlatform.fuchsia: MinimalPageTransitions(),
  // iOS's swipe back from the screen's leading edge, round Minimal's push.
  TargetPlatform.iOS: DesignSwipeBackPageTransitionsBuilder(
    MinimalPageTransitions(),
  ),
  TargetPlatform.linux: MinimalPageTransitions(),
  TargetPlatform.macOS: MinimalPageTransitions(),
  TargetPlatform.windows: MinimalPageTransitions(),
};

/// Minimal's push, as a [PageTransitionsBuilder]: the incoming page fades
/// in over [MinimalChromeMetrics.push] while travelling
/// [MinimalChromeMetrics.pushSlide] from the trailing side, and leaves the
/// same way over [MinimalChromeMetrics.pop]. The page underneath stays
/// exactly where it is — no parallax, no dim. [minimalPageTransitions] maps
/// it to every platform.
///
/// Minimal's push replaces the platform's, and with it iOS's swipe back from
/// the screen's edge: iOS's entry in [minimalPageTransitions] wraps it in
/// ui_core's [DesignSwipeBackPageTransitionsBuilder], which puts the swipe
/// back round it.
class MinimalPageTransitions extends PageTransitionsBuilder {
  /// Minimal's push and pop.
  const MinimalPageTransitions();

  @override
  Duration get transitionDuration =>
      MinimalMotion.animate ? MinimalChromeMetrics.push : Duration.zero;

  @override
  Duration get reverseTransitionDuration =>
      MinimalMotion.animate ? MinimalChromeMetrics.pop : Duration.zero;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // Under the platform's reduce-motion setting the page simply stands.
    if (context.minimalStill) return child;
    // A driven tween, not a CurvedAnimation: nothing to dispose, so a
    // rebuilt transition leaks nothing.
    final eased = animation.drive(CurveTween(curve: MinimalMotion.out));
    final width = MediaQuery.sizeOf(context).width;
    final shift = width == 0 ? 0.0 : MinimalChromeMetrics.pushSlide / width;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return FadeTransition(
      opacity: eased,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: Offset(rtl ? -shift : shift, 0),
          end: Offset.zero,
        ).animate(eased),
        child: child,
      ),
    );
  }
}

/// A destination that cross-fades in over the page it covers — the peer
/// register: no slide, the outgoing page staying exactly where it is
/// beneath. A switched view (a workspace, a filter's saved page) rather
/// than a step deeper. Timings are [MinimalChromeMetrics.fadeIn] and
/// [MinimalChromeMetrics.fadeOut].
///
/// ```dart
/// Navigator.of(context).push(MinimalFadeRoute<void>(builder: (_) => const InboxPage()))
/// ```
class MinimalFadeRoute<T> extends PageRoute<T> {
  /// A route that cross-fades to the page [builder] makes.
  MinimalFadeRoute({required this.builder, super.settings});

  /// Builds the page.
  final WidgetBuilder builder;

  @override
  Duration get transitionDuration =>
      MinimalMotion.animate ? MinimalChromeMetrics.fadeIn : Duration.zero;

  @override
  Duration get reverseTransitionDuration =>
      MinimalMotion.animate ? MinimalChromeMetrics.fadeOut : Duration.zero;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  bool get barrierDismissible => false;

  @override
  bool get maintainState => true;

  @override
  bool get opaque => true;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) => Semantics(
    scopesRoute: true,
    explicitChildNodes: true,
    child: builder(context),
  );

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => context.minimalStill
      ? child
      : FadeTransition(
          opacity: animation.drive(CurveTween(curve: MinimalMotion.out)),
          child: child,
        );
}
