/// [KeycapHost]: Keycap installed in one widget, by day or by night.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/host.dart';

import 'overlays.dart';
import 'theme.dart';

/// Keycap for [child] in the room's light: [light] by day, [dark] by night
/// (the platform's, a preview frame's, or [brightness] when given), moving
/// between them on a calm spring, with a [KeycapToaster] over it. Put it in
/// an app's `builder:`.
///
/// ```dart
/// MaterialApp(builder: (context, child) => KeycapHost(child: child!))
/// ```
class KeycapHost extends StatelessWidget {
  /// Keycap for [child].
  const KeycapHost({
    super.key,
    required this.child,
    this.light,
    this.dark,
    this.brightness,
  });

  /// The app.
  final Widget child;

  /// The theme by day; [KeycapThemeData.light] when null.
  final KeycapThemeData? light;

  /// The theme by night; [KeycapThemeData.dark] when null.
  final KeycapThemeData? dark;

  /// Day or night, whatever the platform says; by the platform when null.
  final Brightness? brightness;

  @override
  Widget build(BuildContext context) {
    final wanted =
        brightness ??
        PreviewFrame.maybeOf(context)?.brightness ??
        MediaQuery.platformBrightnessOf(context);
    final data = wanted == Brightness.dark
        ? dark ?? KeycapThemeData.dark()
        : light ?? KeycapThemeData.light();
    return AnimatedKeycapTheme(
      data: data,
      child: KeycapToaster(child: child),
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
