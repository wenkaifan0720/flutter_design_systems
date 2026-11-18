/// Appliance's host: [ApplianceHost], mounted once over an app's navigator.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/host.dart';

import 'overlays.dart';
import 'theme.dart';

/// The app's host, mounted once over its navigator (`WidgetsApp.builder`):
/// Appliance's theme for the brightness asked for (the platform's when
/// null), moving between day and night on the lamp's spring, and its
/// toasts.
///
/// ```dart
/// MaterialApp(builder: (context, child) => ApplianceHost(child: child!))
/// ```
class ApplianceHost extends StatelessWidget {
  /// Appliance over [child].
  const ApplianceHost({
    super.key,
    required this.child,
    this.light,
    this.dark,
    this.brightness,
  });

  /// The app.
  final Widget child;

  /// The theme by day; [ApplianceThemeData.light] when null.
  final ApplianceThemeData? light;

  /// The theme by night; [ApplianceThemeData.dark] when null.
  final ApplianceThemeData? dark;

  /// Day or night; a preview frame's, else the platform's, when null.
  final Brightness? brightness;

  @override
  Widget build(BuildContext context) {
    final wanted =
        brightness ??
        PreviewFrame.maybeOf(context)?.brightness ??
        MediaQuery.platformBrightnessOf(context);
    final data = wanted == Brightness.dark
        ? dark ?? ApplianceThemeData.dark()
        : light ?? ApplianceThemeData.light();
    return AnimatedApplianceTheme(
      data: data,
      child: ApplianceToaster(child: child),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      DiagnosticsProperty<Brightness>(
        'brightness',
        brightness,
        defaultValue: null,
      ),
    );
  }
}
