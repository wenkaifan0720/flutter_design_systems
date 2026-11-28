import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../theme.dart';
import 'feedback.dart';

/// Terminal over a whole app, its one mount: the theme for the brightness
/// in force ([theme] by day, [darkTheme] by night, or a [palette]'s),
/// published as a [TermTheme] (the grid, the words, the page motion, the
/// tap floor); the screen painted behind the app, the status bar's polarity,
/// and the toasts ([TermToaster]) for [TermToaster.show]. Day to night, or
/// one palette to another, the screen blends across in 200 ms
/// ([AnimatedTermTheme]); under Reduce Motion it cuts.
///
/// Which theme: by day [theme], or, when it is null,
/// `TermThemeData.fromPalette(palette, Brightness.light)`; by night
/// [darkTheme], or `TermThemeData.fromPalette(palette, Brightness.dark)`.
/// A given [theme] or [darkTheme] is used whole: [palette] doesn't change
/// it. Day or night is [brightness], or the platform's when it is null. The
/// window's width plays no part: the grid is the theme's
/// [TermThemeData.grid] grown by the reader's text scale, and the tap floor
/// follows the pointer (two lines for a finger, one for a mouse), on a phone
/// as at a desk. Terminal has no density knob: a denser or roomier screen is
/// another [TermThemeData.grid].
///
/// Mount it once in the app's `builder`, above its Navigator, so every
/// page, dialog and menu stands inside it. Load the bundled faces with
/// [termLoadFonts] before the first frame. A bare [TermTheme] gives a
/// subtree the theme alone: no toasts, no screen, no fade.
///
/// ```dart
/// MaterialApp(
///   builder: (context, child) => TermHost(brightness: appearance, child: child!),
///   home: const HomePage(),
/// )
/// ```
class TermHost extends StatelessWidget {
  /// Mounts Terminal over [child].
  const TermHost({
    required this.child,
    this.theme,
    this.darkTheme,
    this.palette,
    this.brightness,
    super.key,
  });

  /// The light theme; null is the [palette]'s by day.
  final TermThemeData? theme;

  /// The dark theme; null is the [palette]'s by night.
  final TermThemeData? darkTheme;

  /// The palette by day and by night where [theme] or [darkTheme] is null:
  /// one of [TermThemeData.palettes] (the app's stored choice) or the app's
  /// own ([TermThemeData.fromPalette]); null is Standard.
  final RawNamedPalette? palette;

  /// Pins the appearance; null follows the platform.
  final Brightness? brightness;

  /// The app.
  final Widget child;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(
        DiagnosticsProperty<TermThemeData>('theme', theme, defaultValue: null),
      )
      ..add(
        DiagnosticsProperty<TermThemeData>(
          'darkTheme',
          darkTheme,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<RawNamedPalette>(
          'palette',
          palette,
          defaultValue: null,
        ),
      )
      ..add(
        EnumProperty<Brightness>('brightness', brightness, defaultValue: null),
      );
  }

  @override
  Widget build(BuildContext context) {
    final wanted = brightness ?? MediaQuery.platformBrightnessOf(context);
    final chosen = palette ?? TermThemeData.palettes.first;
    final data = wanted == Brightness.dark
        ? darkTheme ?? TermThemeData.fromPalette(chosen, Brightness.dark)
        : theme ?? TermThemeData.fromPalette(chosen, Brightness.light);
    return AnimatedTermTheme(
      data: data,
      child: Builder(
        builder: (context) {
          final now = TermTheme.of(context);
          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: data.brightness == Brightness.dark
                ? SystemUiOverlayStyle.light
                : SystemUiOverlayStyle.dark,
            child: ColoredBox(
              color: now.background,
              // Toasts stand over the app, above its navigator.
              child: TermToaster(child: child),
            ),
          );
        },
      ),
    );
  }
}
