/// Appliance's host: [ApplianceHost], mounted once over an app's navigator.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart' show RawNamedPalette;
import 'package:ui_core/host.dart';

import 'overlays.dart';
import 'theme.dart';

/// The app's host, mounted once over its navigator (`WidgetsApp.builder`):
/// Appliance's theme in [palette] for the brightness asked for (the
/// platform's when null), moving between day and night, and from one
/// palette to the next, on the lamp's spring, and its toasts.
///
/// ```dart
/// MaterialApp(builder: (context, child) => ApplianceHost(palette: ApplianceThemeData.palettes[1], child: child!))
/// ```
class ApplianceHost extends StatelessWidget {
  /// Appliance over [child].
  const ApplianceHost({
    super.key,
    required this.child,
    this.palette,
    this.light,
    this.dark,
    this.brightness,
  });

  /// The app.
  final Widget child;

  /// The palette both brightnesses are built from, one of
  /// [ApplianceThemeData.palettes]; null takes the first, `warm`.
  final RawNamedPalette? palette;

  /// The theme by day; null builds [palette]'s.
  final ApplianceThemeData? light;

  /// The theme by night; null builds [palette]'s.
  final ApplianceThemeData? dark;

  /// Day or night; a preview frame's, else the platform's, when null.
  final Brightness? brightness;

  @override
  Widget build(BuildContext context) {
    final wanted =
        brightness ??
        PreviewFrame.maybeOf(context)?.brightness ??
        MediaQuery.platformBrightnessOf(context);
    final data =
        (wanted == Brightness.dark ? dark : light) ??
        ApplianceThemeData.preset(
          (palette ?? ApplianceThemeData.palettes.first).id,
          wanted,
        );
    return AnimatedApplianceTheme(
      data: data,
      child: ApplianceToaster(child: child),
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
        DiagnosticsProperty<Brightness>(
          'brightness',
          brightness,
          defaultValue: null,
        ),
      );
  }
}
