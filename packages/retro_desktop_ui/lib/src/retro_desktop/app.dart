/// [RetroDesktopHost]: Retro Desktop installed in one widget, by day or by night, in one of its palettes.
library;

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ui_core/ui_core.dart' show RawNamedPalette;
import 'package:ui_core/host.dart';

import 'raised.dart' show RetroDesktopToaster;
import 'theme.dart';

/// The app's one mount, around its navigator (an app's `builder:`): Retro Desktop's theme for the room's light,
/// [light] by day and [dark] by night (the platform's, a preview frame's, or [brightness] when given), each left out
/// [palette]'s colours; the desk's colour under the pages; and the toaster, so a notice stands over the app, above its
/// strip. A change of appearance or palette is at once, as every Retro Desktop change of state is; an app that wants
/// it to cross-fade gives a [duration] (at once under Reduce Motion all the same).
///
/// ```dart
/// MaterialApp(builder: (context, child) => RetroDesktopHost(palette: RetroDesktopThemeData.palettes[1], child: child!), home: const Text('Shelf'))
/// ```
class RetroDesktopHost extends StatelessWidget {
  /// Retro Desktop for [child].
  const RetroDesktopHost({
    super.key,
    this.palette,
    this.light,
    this.dark,
    this.brightness,
    this.duration = Duration.zero,
    required this.child,
  });

  /// The palette both appearances are built from, one of [RetroDesktopThemeData.palettes]; null: the first, classic.
  final RawNamedPalette? palette;

  /// The theme by day; [palette]'s by day when null.
  final RetroDesktopThemeData? light;

  /// The theme by night; [palette]'s by night when null.
  final RetroDesktopThemeData? dark;

  /// Day or night, whatever the platform says; by the platform when null.
  final Brightness? brightness;

  /// The app.
  final Widget child;

  /// How long a change of appearance or palette takes; at once by default.
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final wanted =
        brightness ??
        PreviewFrame.maybeOf(context)?.brightness ??
        MediaQuery.platformBrightnessOf(context);
    final theme =
        (wanted == Brightness.dark ? dark : light) ??
        RetroDesktopThemeData.preset(
          palette?.id ?? RetroDesktopThemeData.presets.first,
          wanted,
        );
    return Theme(
      data: Theme.of(context)
          .copyWith(platform: PreviewFrame.targetPlatformOf(context)),
      child: AnimatedRetroDesktopTheme(
        data: theme,
        duration: duration,
        child: Builder(
          builder: (context) => ColoredBox(
            color: RetroDesktopTheme.of(context).colors.desktop,
            // The look's notices stand over the app, above its bars (showRetroDesktopSnackBar).
            child: RetroDesktopToaster(child: child),
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
        DiagnosticsProperty<RetroDesktopThemeData>(
          'light',
          light,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<RetroDesktopThemeData>(
          'dark',
          dark,
          defaultValue: null,
        ),
      )
      ..add(
        EnumProperty<Brightness>('brightness', brightness, defaultValue: null),
      )
      ..add(
        DiagnosticsProperty<Duration>(
          'duration',
          duration,
          defaultValue: Duration.zero,
        ),
      );
  }
}
