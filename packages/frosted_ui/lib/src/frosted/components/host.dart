import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:ui_core/host.dart';

import '../internal/toaster.dart';
import '../theme.dart';
import 'toast.dart';

/// The one mount of Frosted in an app: picks the theme for the brightness
/// in force and publishes it as a [FrostedTheme] (which installs what the
/// platform's widgets under it read; a change of brightness or theme eases
/// through [AnimatedFrostedTheme]), paints the ground behind the app,
/// carries status-bar polarity, holds the toasts ([FrostedToast.show]) over
/// the app, and clamps the text scale at [maxTextScale] so a large
/// accessibility size grows rows rather than breaking them. Every render host
/// mounts it once above its Navigator: the app in its router builder, a page
/// preview in its own.
///
/// The host follows the ambient platform for behaviour (scroll physics, text
/// selection, back gestures) and never pins one; inside a preview frame it
/// follows the frame's register.
///
/// ```dart
/// MaterialApp.router(builder: (context, child) => FrostedHost(child: child!))
/// ```
class FrostedHost extends StatelessWidget {
  /// Creates a [FrostedHost].
  const FrostedHost({
    required this.child,
    this.light,
    this.dark,
    this.brightness,
    super.key,
  });

  /// The light theme; null is the default preset's.
  final FrostedThemeData? light;

  /// The dark theme; null is the default preset's.
  final FrostedThemeData? dark;

  /// Pins the appearance; null follows the platform (or the preview frame).
  final Brightness? brightness;

  /// The app.
  final Widget child;

  /// The largest text scale a Frosted page lays out at: 200%, as WCAG's
  /// resize-text criterion asks; a larger accessibility size lays out at
  /// this.
  static const double maxTextScale = 2;

  /// The app's own root navigator, where Frosted raises what covers the
  /// whole app (a sheet, a dialog, a menu, a toast): the outermost Navigator
  /// between [context] and the host above it. A render host that nests the
  /// app under a navigator of its own (a preview frame) stays outside, so
  /// what the app mounts above its navigator (its provider scope, its router)
  /// reaches the route. With no navigator below the host (a page preview),
  /// the nearest one.
  ///
  /// ```dart
  /// FrostedHost.navigatorOf(context).push(route)
  /// ```
  static NavigatorState navigatorOf(BuildContext context) {
    NavigatorState? outermost;
    if (context is StatefulElement && context.state is NavigatorState) {
      outermost = context.state as NavigatorState;
    }
    context.visitAncestorElements((element) {
      if (element.widget is _HostMark) return false;
      if (element is StatefulElement && element.state is NavigatorState) {
        outermost = element.state as NavigatorState;
      }
      return true;
    });
    return outermost ?? Navigator.of(context);
  }

  /// The status bar's polarity over [theme]'s ground.
  static SystemUiOverlayStyle systemBarsOf(FrostedThemeData theme) =>
      theme.isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark;

  @override
  Widget build(BuildContext context) {
    final wanted =
        brightness ??
        PreviewFrame.maybeOf(context)?.brightness ??
        MediaQuery.platformBrightnessOf(context);
    final darkTheme =
        dark ??
        light?.darkTwin ??
        FrostedThemeData.preset(
          FrostedThemeData.presets.first,
          Brightness.dark,
        );
    final t = wanted == Brightness.dark
        ? darkTheme
        : light ??
              FrostedThemeData.preset(
                FrostedThemeData.presets.first,
                Brightness.light,
              );
    final motion = FrostedMotion.of(context);
    final app = FrostedToaster(child: _HostMark(child: child));
    // Day to night (or one theme to another) eases through
    // FrostedThemeData.lerp over the look's base timing; a cut under Reduce
    // Motion.
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: maxTextScale,
      child: AnimatedFrostedTheme(
        data: t,
        darkData: darkTheme,
        duration: motion.base,
        curve: motion.curve,
        child: AnnotatedRegion<SystemUiOverlayStyle>(
          value: systemBarsOf(t),
          child: Builder(
            builder: (context) {
              final now = context.frostedTheme;
              return ColoredBox(
                color: now.colorScheme.background,
                // Words anywhere under the host, a page's own or a part's,
                // start from the look's body in the page ink: never the
                // app's debug style (MaterialApp's red with its yellow
                // underline).
                child: DefaultTextStyle(
                  style: now.textTheme.titleMedium.copyWith(
                    color: now.colorScheme.textPrimary,
                    decoration: TextDecoration.none,
                  ),
                  child: app,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Where the app below a [FrostedHost] begins: [FrostedHost.navigatorOf]
/// looks for navigators up to here and no further.
class _HostMark extends StatelessWidget {
  const _HostMark({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}

/// Stands [child] on the media ground: the host's dark tokens under a light
/// status bar, for chrome drawn over a full-bleed photograph or video (the
/// shell's bar on a media tab). Nothing in it blurs.
///
/// ```dart
/// FrostedMediaGround(child: FrostedAppBar(title: 'Clips'))
/// ```
class FrostedMediaGround extends StatelessWidget {
  /// Creates a [FrostedMediaGround].
  const FrostedMediaGround({required this.child, super.key});

  /// What stands on the media ground.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final dark = FrostedTheme.darkOf(context);
    return FrostedTheme(
      data: dark,
      darkData: dark,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: child,
      ),
    );
  }
}
