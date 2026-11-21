/// Studio's page change: a page slides in a short way on its rails from the
/// end side as a module slides into a rack, and the page it covers dims, as a
/// display going to standby. Going back is the reverse. iOS's swipe back from
/// the leading edge stays round it.
library;

import 'package:material_ui/material_ui.dart';
import 'package:ui_core/ui_core.dart';

import 'internal/curved.dart';

/// Studio's page change, for a `PageTransitionsTheme` (Flutter's material
/// library's or the one Studio is built on: it is a widgets-level builder).
/// An app's own theme gives it [studioPageTransitions].
///
/// ```dart
/// ThemeData(pageTransitionsTheme: const PageTransitionsTheme(builders: studioPageTransitions))
/// ```
class StudioPageTransitionsBuilder extends PageTransitionsBuilder {
  /// Studio's page change.
  const StudioPageTransitionsBuilder();

  /// How far a page slides on its rails: a short way, never across the
  /// screen.
  static const double travel = 40;

  /// How far the covered page dims.
  static const double dimming = 0.22;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 300);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 240);

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => _StudioPageChange(
    animation: animation,
    secondary: secondaryAnimation,
    rises: route.fullscreenDialog,
    child: child,
  );
}

class _StudioPageChange extends StatelessWidget {
  const _StudioPageChange({
    required this.animation,
    required this.secondary,
    required this.rises,
    required this.child,
  });

  final Animation<double> animation;
  final Animation<double> secondary;
  final bool rises;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    // The rails: fast off the mark, settling without a bounce.
    final slide = studioCurved(
      animation,
      Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    final appear = studioCurved(
      animation,
      const Interval(0, 0.55, curve: Curves.easeOut),
      reverseCurve: const Interval(0.3, 1, curve: Curves.easeIn),
    );
    return AnimatedBuilder(
      animation: Listenable.merge([animation, secondary]),
      child: child,
      builder: (context, child) {
        final away = 1 - slide.value;
        final offset = rises
            ? Offset(0, StudioPageTransitionsBuilder.travel * away)
            : Offset(
                (rtl ? -1 : 1) * StudioPageTransitionsBuilder.travel * away,
                0,
              );
        final dim =
            Curves.easeOut.transform(secondary.value) *
            StudioPageTransitionsBuilder.dimming;
        return Opacity(
          opacity: appear.value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: offset,
            child: dim == 0
                ? child
                : Stack(
                    fit: StackFit.passthrough,
                    children: [
                      child!,
                      Positioned.fill(
                        child: IgnorePointer(
                          child: ColoredBox(
                            color: Color.fromRGBO(0, 0, 0, dim),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }
}

/// Studio's page change on every platform, with iOS's swipe back from the
/// screen's leading edge round it there (ui_core's
/// [SwipeBackPageTransitionsBuilder]): the builders for a
/// `PageTransitionsTheme`, Flutter's material library's or the one Studio is
/// built on.
///
/// ```dart
/// MaterialApp(theme: ThemeData(pageTransitionsTheme: const PageTransitionsTheme(builders: studioPageTransitions)), home: const Home())
/// ```
const Map<TargetPlatform, PageTransitionsBuilder> studioPageTransitions = {
  TargetPlatform.android: StudioPageTransitionsBuilder(),
  TargetPlatform.fuchsia: StudioPageTransitionsBuilder(),
  // iOS's swipe back from the screen's edge, round Studio's push.
  TargetPlatform.iOS: SwipeBackPageTransitionsBuilder(
    StudioPageTransitionsBuilder(),
  ),
  TargetPlatform.linux: StudioPageTransitionsBuilder(),
  TargetPlatform.macOS: StudioPageTransitionsBuilder(),
  TargetPlatform.windows: StudioPageTransitionsBuilder(),
};
