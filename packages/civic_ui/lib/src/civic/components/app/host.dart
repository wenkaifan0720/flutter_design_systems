import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart' show PageTransitionsTheme, Theme;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';
import 'package:ui_core/host.dart';

import '../../theme.dart';
import '../toast/toast.dart';
import 'routes.dart';

/// Civic over a whole app: the theme for the brightness in force ([theme]
/// by day, [darkTheme] by night), the page's ground, words and glyphs, the
/// status bar's polarity, Civic's page change on every platform
/// ([CivicPageTransitions]) and a [CivicToaster] for `CivicToast.show`. A
/// change of theme (day to night, another palette) blends over 200 ms, as
/// Material's `AnimatedTheme` does. It never clamps the text scale: a
/// reader at 200% gets 200%, and Civic's parts grow to hold it.
///
/// Mount it once, above the app's Navigator, so every page, dialog and menu
/// stands inside it. Behaviour (scrolling, selection, the way back) follows
/// the platform, or inside a preview frame the frame's.
///
/// ```dart
/// MaterialApp.router(
///   routerConfig: router,
///   builder: (context, child) => CivicHost(child: child!),
/// )
/// ```
class CivicHost extends StatelessWidget {
  /// Civic over [child].
  const CivicHost({
    super.key,
    required this.child,
    this.theme,
    this.darkTheme,
    this.palette,
    this.brightness,
  });

  /// The app.
  final Widget child;

  /// The theme by day; null is Civic's own.
  final CivicThemeData? theme;

  /// The theme by night; null is Civic's own.
  final CivicThemeData? darkTheme;

  /// The palette by day and by night where [theme] or [darkTheme] is null:
  /// one of [CivicThemeData.palettes], the app's stored choice; null is
  /// Civic's blue.
  final RawNamedPalette? palette;

  /// Pins the appearance; null follows the platform, or a preview frame.
  final Brightness? brightness;

  // Civic's own palettes' themes, made once; an app's own palette's are
  // made as it is given.
  static final Map<(RawNamedPalette?, Brightness), CivicThemeData> _made = {};

  static CivicThemeData _themeFor(
    RawNamedPalette? palette,
    Brightness brightness,
  ) {
    CivicThemeData make() => brightness == Brightness.dark
        ? CivicThemeData.dark(palette: palette)
        : CivicThemeData.light(palette: palette);
    final own = palette == null || CivicThemeData.palettes.contains(palette);
    return own ? _made.putIfAbsent((palette, brightness), make) : make();
  }

  @override
  Widget build(BuildContext context) {
    final frame = PreviewFrame.maybeOf(context);
    final wanted =
        brightness ??
        frame?.brightness ??
        MediaQuery.platformBrightnessOf(context);
    final t = wanted == Brightness.dark
        ? darkTheme ?? _themeFor(palette, Brightness.dark)
        : theme ?? _themeFor(palette, Brightness.light);
    // The platform the app's own Material theme behaves as.
    final platform = Theme.of(context).platform;
    return AnimatedCivicTheme(
      data: t,
      child: CivicToaster(
        child: AnnotatedRegion<SystemUiOverlayStyle>(
          value: t.isDark
              ? SystemUiOverlayStyle.light
              : SystemUiOverlayStyle.dark,
          // The ground blends with the theme.
          child: _Ground(
            // Read under CivicTheme: the Material theme Civic puts there (a
            // text field's caret, selection and handles in Civic's colours),
            // not the app's from round the host.
            child: Builder(
              builder: (context) => Theme(
                data: Theme.of(context).copyWith(
                  // Civic's page change, on every platform.
                  pageTransitionsTheme: const PageTransitionsTheme(
                    builders: civicPageTransitions,
                  ),
                  // In a preview, the frame's platform is the one behaved as.
                  platform: frame?.platform.targetPlatform ?? platform,
                ),
                child: child,
              ),
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
        EnumProperty<Brightness>('brightness', brightness, defaultValue: null),
      );
  }
}

// The page's ground in the theme in force, as it blends.
class _Ground extends StatelessWidget {
  const _Ground({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) =>
      ColoredBox(color: context.civicTheme.background, child: child);
}
