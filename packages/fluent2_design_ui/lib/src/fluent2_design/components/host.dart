import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:ui_core/host.dart';

import '../theme.dart';

/// The one mount of Fluent 2 in a host app. Picks the theme for the
/// brightness in force and puts it in scope with a [Fluent2Theme] (which
/// gives the platform primitives beneath the thin Material `ThemeData` they
/// read and sets Fluent's `body1` as the default text style), paints the
/// page's ground behind the app, carries status-bar polarity, and clamps the
/// text scale at [maxTextScale] so a large accessibility size grows rows
/// rather than breaking them. Every render host mounts it once above its
/// Navigator: the app in its router builder, a page preview in its own.
///
/// The host follows the ambient platform for behaviour (scroll physics,
/// text selection, back gestures) and never pins one; inside a preview
/// frame it follows the frame's register.
///
/// ```dart
/// MaterialApp.router(builder: (context, child) => Fluent2Host(child: child!))
/// ```
class Fluent2Host extends StatelessWidget {
  /// Mounts Fluent 2 over [child].
  const Fluent2Host({
    required this.child,
    this.light,
    this.darkData,
    this.brightness,
    super.key,
  });

  /// The light theme; null is the default preset's.
  final Fluent2ThemeData? light;

  /// The dark theme; null is the default preset's.
  final Fluent2ThemeData? darkData;

  /// Pins the appearance; null follows the platform (or the preview frame).
  final Brightness? brightness;

  /// The app under the host: its navigator and pages.
  final Widget child;

  /// The largest text scale a Fluent 2 page lays out at: twice the size,
  /// the 200% a reader may ask for (WCAG 1.4.4).
  static const double maxTextScale = 2.0;

  /// The app's own root navigator, where Fluent 2 raises what covers the
  /// whole app (a sheet, a dialog, a menu, a toast): the outermost Navigator
  /// between [context] and the host above it. A render host that nests the
  /// app under a navigator of its own (a preview frame) stays outside, so
  /// what the app mounts above its navigator (its provider scope, its
  /// router) reaches the route. With no navigator below the host (a page
  /// preview), the nearest one.
  ///
  /// ```dart
  /// Fluent2Host.navigatorOf(context).push(route)
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
  static SystemUiOverlayStyle systemBarsOf(Fluent2ThemeData theme) =>
      theme.isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark;

  @override
  Widget build(BuildContext context) {
    final wanted =
        brightness ??
        PreviewFrame.maybeOf(context)?.brightness ??
        MediaQuery.platformBrightnessOf(context);
    final darkTheme =
        darkData ??
        Fluent2ThemeData.preset(
          Fluent2ThemeData.presets.first,
          Brightness.dark,
        );
    final t = wanted == Brightness.dark
        ? darkTheme
        : light ??
              Fluent2ThemeData.preset(
                Fluent2ThemeData.presets.first,
                Brightness.light,
              );
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: maxTextScale,
      // Day to night (and a new preset) eases over Fluent's durationNormal,
      // every token at once; a cut under Reduce Motion.
      child: AnimatedFluent2Theme(
        data: t,
        darkData: darkTheme,
        duration: Fluent2Motion.of(context, Fluent2Motion.normal),
        curve: Fluent2Motion.easyEase,
        child: AnnotatedRegion<SystemUiOverlayStyle>(
          value: systemBarsOf(t),
          child: Builder(
            builder: (context) => ColoredBox(
              color: context.fluent2Theme.background,
              child: _HostMark(child: child),
            ),
          ),
        ),
      ),
    );
  }
}

/// Where the app below a [Fluent2Host] begins: [Fluent2Host.navigatorOf]
/// looks for navigators up to here and no further.
class _HostMark extends StatelessWidget {
  const _HostMark({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}

/// Stands [child] on the media ground: the host's dark tokens under a
/// light status bar, for chrome drawn over a full-bleed photograph or
/// video (the shell's bar on a media tab). Nothing in it blurs.
///
/// ```dart
/// Fluent2MediaGround(child: bar)
/// ```
class Fluent2MediaGround extends StatelessWidget {
  /// Stands [child] on the media ground.
  const Fluent2MediaGround({required this.child, super.key});

  /// The chrome drawn over the media.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final dark = Fluent2Theme.darkOf(context);
    return Fluent2Theme(
      data: dark,
      darkData: dark,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: child,
      ),
    );
  }
}
