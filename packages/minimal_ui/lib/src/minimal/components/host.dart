import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import '../chrome_metrics.dart';
import '../theme.dart';
import 'toast.dart';

/// The one mount of Minimal in a host app. Picks the theme for the
/// brightness in force, installs it with a [MinimalTheme] (the dark theme
/// riding along for media grounds, its page transitions on every
/// platform), paints the ground, hosts the toasts ([MinimalToaster]),
/// carries status-bar polarity, and clamps text scaling at
/// [MinimalChromeMetrics.maxTextScale] (200%), the largest size its parts
/// are laid out for. Every render host mounts it once
/// above its Navigator: the app in its router builder, a page preview in
/// its own.
///
/// ```dart
/// MaterialApp.router(routerConfig: router, builder: (context, child) => MinimalHost(light: MinimalThemeData.preset('standard', Brightness.light), dark: MinimalThemeData.preset('standard', Brightness.dark), child: child!))
/// ```
class MinimalHost extends StatelessWidget {
  /// Installs the theme for [brightness] (the platform's when null) above
  /// [child].
  const MinimalHost({
    required this.light,
    required this.dark,
    required this.child,
    this.brightness,
    super.key,
  });

  /// The theme in the light appearance.
  final MinimalThemeData light;

  /// The theme in the dark appearance.
  final MinimalThemeData dark;

  /// Pins the appearance; null follows the platform.
  final Brightness? brightness;

  /// The app: its navigator, as `MaterialApp.builder` hands it.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final brightness =
        this.brightness ?? MediaQuery.platformBrightnessOf(context);
    final t = brightness == Brightness.dark ? dark : light;
    // Day to night (and a preset's change) blends, in Minimal's slow fade;
    // with reduced motion it switches at once.
    return AnimatedMinimalTheme(
      data: t,
      darkData: dark,
      curve: MinimalMotion.out,
      duration: context.minimalStill ? Duration.zero : MinimalMotion.slow,
      // Status-bar discipline rides the host (it spans the full screen, so
      // the annotated region always covers the bar).
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: brightness == Brightness.dark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        child: MediaQuery.withClampedTextScaling(
          maxScaleFactor: MinimalChromeMetrics.maxTextScale,
          // The ground reads the blending theme, so it fades with it.
          child: Builder(
            builder: (context) => ColoredBox(
              color: context.minimalTheme.background,
              child: MinimalToaster(child: child),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<MinimalThemeData>('light', light))
      ..add(DiagnosticsProperty<MinimalThemeData>('dark', dark))
      ..add(
        EnumProperty<Brightness>('brightness', brightness, defaultValue: null),
      );
  }
}
