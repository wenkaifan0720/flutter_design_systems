import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:ui_core/ui_core.dart';

import '../theme.dart';

/// Frosted's push for every platform, as a `PageTransitionsTheme` takes it:
/// a map of widgets-level builders, so it fits the theme of either Material.
///
/// [FrostedTheme] puts it in the Material theme it builds, which a
/// `FrostedPage` and the routes of an app on `material_ui` read. An app on
/// Flutter's own `MaterialApp` reads its theme from above Frosted, where
/// Frosted cannot set it: put the map in that `ThemeData`, and its
/// `MaterialPageRoute`s and router pages move as Frosted's do.
///
/// ```dart
/// MaterialApp(
///   theme: ThemeData(
///     pageTransitionsTheme: const PageTransitionsTheme(
///       builders: frostedPageTransitions,
///     ),
///   ),
///   builder: (context, child) =>
///       FrostedTheme(data: FrostedThemeData.opal(), child: child!),
///   home: home,
/// )
/// ```
///
/// On iOS the motion stands inside ui_core's
/// [SwipeBackPageTransitionsBuilder], so a drag from the leading edge
/// still takes a page back, as on every iOS screen.
const Map<TargetPlatform, PageTransitionsBuilder> frostedPageTransitions =
    <TargetPlatform, PageTransitionsBuilder>{
      TargetPlatform.android: FrostedPageMotion(),
      TargetPlatform.fuchsia: FrostedPageMotion(),
      // iOS's swipe back from the leading edge, round Frosted's push.
      TargetPlatform.iOS: SwipeBackPageTransitionsBuilder(FrostedPageMotion()),
      TargetPlatform.linux: FrostedPageMotion(),
      TargetPlatform.macOS: FrostedPageMotion(),
      TargetPlatform.windows: FrostedPageMotion(),
    };

/// Frosted's page motion: the builder [frostedPageTransitions] gives every
/// platform.
///
/// A page pushed over another is a pane laid on it: it clears in from
/// nothing as it settles [travel] toward the end (the way the words run),
/// over [duration], eased out; the page under it stands still and whole, so
/// nothing flies and no blank field ever shows. A pop is the reverse, the
/// pane lifting off the way it came. A full-screen dialog settles the same
/// [travel] up from below. Under Reduce Motion it is a cut. It takes no
/// drag of its own: on iOS [frostedPageTransitions] stands it inside ui_core's
/// [SwipeBackPageTransitionsBuilder], whose drag from the leading edge
/// pulls the page off under the finger, as the platform's own pages do.
class FrostedPageMotion extends PageTransitionsBuilder {
  /// Frosted's page motion.
  const FrostedPageMotion();

  /// How far a page travels as it comes and goes: a small settling, never
  /// a flight across the window.
  static const double travel = 24;

  /// How long a page takes to come.
  static const Duration duration = Duration(milliseconds: 300);

  /// How long a page takes to go.
  static const Duration reverseDuration = Duration(milliseconds: 250);

  @override
  Duration get transitionDuration => duration;

  @override
  Duration get reverseTransitionDuration => reverseDuration;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return _PageSettle(
      animation: animation,
      rise: route.fullscreenDialog,
      child: child,
    );
  }
}

/// The page settling in (or lifting off): its opacity and its offset from
/// [animation], eased. (While iOS's edge drag holds the page, ui_core's
/// swipe hands this a finished animation and moves the page itself.)
class _PageSettle extends StatelessWidget {
  const _PageSettle({
    required this.animation,
    required this.rise,
    required this.child,
  });

  final Animation<double> animation;
  final bool rise;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final moves = FrostedMotion.of(context).moves;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final t = animation.value;
        if (t >= 1) return child!;
        // Under Reduce Motion a page comes and goes as a cut.
        if (!moves) return child!;
        final eased = Curves.easeOutCubic.transform(t);
        final shift = (1 - eased) * FrostedPageMotion.travel;
        return Opacity(
          opacity: Curves.easeOut.transform(math.min(1, t / .6)),
          child: Transform.translate(
            offset: rise ? Offset(0, shift) : Offset(rtl ? -shift : shift, 0),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
