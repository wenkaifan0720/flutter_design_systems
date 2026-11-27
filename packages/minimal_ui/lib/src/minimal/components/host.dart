import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:ui_core/ui_core.dart';

import '../chrome_metrics.dart';
import '../theme.dart';
import 'toast.dart';

/// Minimal's one mount in an app, over its navigator: the theme for the
/// appearance in force, the ground, the toasts and the status bar's ink.
///
/// It builds the theme of [palette] by day and by night (or takes [light]
/// and [dark] as given), follows the platform's appearance unless
/// [brightness] pins one, and blends to a new appearance or palette in
/// Minimal's slow fade (at once with reduced motion). It installs the theme
/// with a [MinimalTheme] (the night theme riding along for media grounds),
/// paints the ground, hosts the toasts ([MinimalToaster]), sets the status
/// bar's ink, and holds text scaling at [MinimalChromeMetrics.maxTextScale]
/// (200%), the largest size its parts are laid out for.
///
/// ```dart
/// MaterialApp(builder: (context, child) => MinimalHost(palette: MinimalThemeData.palettes[2], child: child!), home: const HomePage())
/// ```
class MinimalHost extends StatelessWidget {
  /// Installs the theme for [brightness] (the platform's when null) above
  /// [child].
  const MinimalHost({
    required this.child,
    this.palette,
    this.light,
    this.dark,
    this.brightness,
    super.key,
  });

  /// The palette both appearances are built from, one of
  /// [MinimalThemeData.palettes]; null takes the first, `standard`.
  final RawNamedPalette? palette;

  /// The theme by day; null builds [palette]'s.
  final MinimalThemeData? light;

  /// The theme by night; null builds [palette]'s.
  final MinimalThemeData? dark;

  /// Pins the appearance; null follows the platform.
  final Brightness? brightness;

  /// The app: its navigator, as `MaterialApp.builder` hands it.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final brightness =
        this.brightness ?? MediaQuery.platformBrightnessOf(context);
    final id = (palette ?? MinimalThemeData.palettes.first).id;
    final dark = this.dark ?? MinimalThemeData.preset(id, Brightness.dark);
    final t = brightness == Brightness.dark
        ? dark
        : light ?? MinimalThemeData.preset(id, Brightness.light);
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
      ..add(
        DiagnosticsProperty<RawNamedPalette>(
          'palette',
          palette,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<MinimalThemeData>(
          'light',
          light,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<MinimalThemeData>('dark', dark, defaultValue: null),
      )
      ..add(
        EnumProperty<Brightness>('brightness', brightness, defaultValue: null),
      );
  }
}
