/// [KeycapHost]: Keycap installed in one widget, by day or by night.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart' show RawNamedPalette;
import 'package:ui_core/host.dart';

import 'overlays.dart';
import 'theme.dart';

/// Keycap for [child] in the room's light: [theme] by day, [darkTheme] by night
/// (the platform's, a preview frame's, or [brightness] when given), each
/// left out [palette]'s colourway, moving between them on a calm spring,
/// with a [KeycapToaster] over it. Put it in an app's `builder:`.
///
/// ```dart
/// MaterialApp(builder: (context, child) => KeycapHost(palette: KeycapThemeData.palettes[2], child: child!))
/// ```
class KeycapHost extends StatelessWidget {
  /// Keycap for [child].
  const KeycapHost({
    super.key,
    required this.child,
    this.palette,
    this.theme,
    this.darkTheme,
    this.brightness,
  });

  /// The app.
  final Widget child;

  /// The colourway both brightnesses are built from, one of
  /// [KeycapThemeData.palettes]; null: the first, classic.
  final RawNamedPalette? palette;

  /// The theme by day; [palette]'s colourway by day when null.
  final KeycapThemeData? theme;

  /// The theme by night; [palette]'s colourway by night when null.
  final KeycapThemeData? darkTheme;

  /// Day or night, whatever the platform says; by the platform when null.
  final Brightness? brightness;

  @override
  Widget build(BuildContext context) {
    final wanted =
        brightness ??
        PreviewFrame.maybeOf(context)?.brightness ??
        MediaQuery.platformBrightnessOf(context);
    final data =
        (wanted == Brightness.dark ? darkTheme : theme) ??
        KeycapThemeData.preset(
          palette?.id ?? KeycapThemeData.presets.first,
          wanted,
        );
    return AnimatedKeycapTheme(
      data: data,
      child: KeycapToaster(child: child),
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
