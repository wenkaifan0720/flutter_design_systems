/// How one screen gives way to the next: the screen clears at once and the
/// new one comes up where it will stay, in a very short fade, as a terminal
/// clears and redraws. Nothing slides in from elsewhere.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../theme.dart';

/// The platform builders for Terminal page transitions. A route fades in
/// on push and cuts back on pop. On iOS it also supports swiping back
/// from the leading edge.
///
/// Set this map on the app's `PageTransitionsTheme` so routes pushed by
/// its navigator use Terminal's transitions.
///
/// ```dart
/// MaterialApp(
///   theme: ThemeData(
///     pageTransitionsTheme: const PageTransitionsTheme(
///       builders: termPageTransitions,
///     ),
///   ),
///   builder: (context, child) =>
///       TermTheme(data: TermThemeData.dark(), child: child!),
///   home: const Home(),
/// )
/// ```
const Map<TargetPlatform, PageTransitionsBuilder> termPageTransitions = {
  TargetPlatform.android: TermPageTransitionsBuilder(),
  TargetPlatform.fuchsia: TermPageTransitionsBuilder(),
  // iOS's swipe back from the screen's edge, round Terminal's change.
  TargetPlatform.iOS: SwipeBackPageTransitionsBuilder(
    TermPageTransitionsBuilder(),
  ),
  TargetPlatform.linux: TermPageTransitionsBuilder(),
  TargetPlatform.macOS: TermPageTransitionsBuilder(),
  TargetPlatform.windows: TermPageTransitionsBuilder(),
};

/// Terminal's screen change, for a `PageTransitionsTheme`: the screen
/// clears to the theme's background at once, the new one's content fades up
/// in place over [TermMotion.screen], and going back is a cut. Under Reduce
/// Motion both are cuts.
///
/// [termPageTransitions] gives it for every platform, the map an app puts
/// in its own theme.
class TermPageTransitionsBuilder extends PageTransitionsBuilder {
  /// Terminal's screen change.
  const TermPageTransitionsBuilder();

  @override
  Duration get transitionDuration => TermMotion.screen;

  @override
  Duration get reverseTransitionDuration => Duration.zero;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => _TermScreenChange(
    animation: animation,
    secondaryAnimation: secondaryAnimation,
    child: child,
  );
}

/// A full screen pushed with Terminal's screen change
/// ([TermPageTransitionsBuilder]), whatever the app's theme says; on iOS a
/// swipe from the leading edge takes it back ([termPageTransitions]).
///
/// ```dart
/// Navigator.of(context).push(
///   TermPageRoute<void>(builder: (context) => const RunPage()),
/// );
/// ```
class TermPageRoute<T> extends PageRoute<T> {
  /// A screen built by [builder].
  TermPageRoute({
    required this.builder,
    super.settings,
    this.maintainState = true,
    super.fullscreenDialog,
  });

  /// Builds the screen.
  final WidgetBuilder builder;

  @override
  final bool maintainState;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  Duration get transitionDuration =>
      const TermPageTransitionsBuilder().transitionDuration;

  @override
  Duration get reverseTransitionDuration =>
      const TermPageTransitionsBuilder().reverseTransitionDuration;

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
  ) =>
      (termPageTransitions[defaultTargetPlatform] ??
              const TermPageTransitionsBuilder())
          .buildTransitions(
            this,
            context,
            animation,
            secondaryAnimation,
            child,
          );

  @override
  String get debugLabel => '${super.debugLabel}(${settings.name})';
}

class _TermScreenChange extends StatelessWidget {
  const _TermScreenChange({
    required this.animation,
    required this.secondaryAnimation,
    required this.child,
  });

  final Animation<double> animation;
  final Animation<double> secondaryAnimation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final still = rawReduceMotionOf(context);
    // The screen clears before the new one is drawn: its ground is solid
    // from the first frame, so the screen it covers never shows through,
    // whatever route that one is.
    final ground = TermTheme.maybeOf(context)?.background;
    final change = AnimatedBuilder(
      animation: Listenable.merge([animation, secondaryAnimation]),
      builder: (context, child) {
        // Covered by the next screen: gone at once, so the two never show
        // through each other.
        final covered = switch (secondaryAnimation.status) {
          AnimationStatus.forward || AnimationStatus.completed => true,
          AnimationStatus.reverse || AnimationStatus.dismissed => false,
        };
        final shown = covered
            ? 0.0
            : still || animation.status == AnimationStatus.completed
            ? 1.0
            : Curves.easeOut.transform(animation.value.clamp(0.0, 1.0));
        // Always the same wrapper, so the screen's state is never rebuilt.
        return Opacity(opacity: shown, child: child);
      },
      child: child,
    );
    return ground == null ? change : ColoredBox(color: ground, child: change);
  }
}
