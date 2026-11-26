/// Theme and platform services for the Expressive component library.
library;

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:ui_core/host.dart';

import '../color.dart';
import '../internal/snack_host.dart';
import '../internal/tokens/behavior.g.dart';
import '../motion.dart';
import '../theme.dart';
import 'page_transitions.dart' show expressivePageTransitions;

/// The app's host: mounts the Expressive theme in force (light or dark by
/// [brightness], or by the platform's when null) on an
/// [ExpressiveTheme]; under it a thin Material [ThemeData] for the
/// primitives Expressive builds on (ink, text editing and selection,
/// scrolling, page transitions), whose platform is the ambient one; the
/// ground (the `surface` role); the text and icon defaults (Compose's
/// `bodyLarge` in `onSurface`); the text-selection colours (primary, its
/// background at `HostBehavior.textSelectionBackgroundOpacity`); and on
/// Android, edge-to-edge system bars: transparent, their icons contrasting
/// with the ground.
///
/// Mounted once, around the router's Navigator:
/// `MaterialApp.router(builder: (context, child) => ExpressiveHost(child: child!))`.
class ExpressiveHost extends StatefulWidget {
  /// A host mounting the Expressive theme over [child].
  const ExpressiveHost({
    required this.child,
    this.theme,
    this.darkTheme,
    this.highContrastTheme,
    this.highContrastDarkTheme,
    this.brightness,
    super.key,
  });

  /// What the host stands the theme over: the app.
  final Widget child;

  /// The light theme; null wears the default preset's.
  final ExpressiveThemeData? theme;

  /// The dark theme; null wears the default preset's.
  final ExpressiveThemeData? darkTheme;

  /// The light theme while the platform asks for high contrast
  /// (`MediaQuery.highContrastOf`), as `MaterialApp.highContrastTheme`:
  /// null wears [theme], or the default preset at high contrast when
  /// [theme] is null too.
  ///
  /// ```dart
  /// ExpressiveHost(
  ///   theme: ExpressiveThemeData.from(seed: brand),
  ///   highContrastTheme: ExpressiveThemeData.from(
  ///     seed: brand,
  ///     contrastLevel: 1,
  ///   ),
  ///   child: child,
  /// )
  /// ```
  final ExpressiveThemeData? highContrastTheme;

  /// The dark theme while the platform asks for high contrast, as
  /// `MaterialApp.highContrastDarkTheme`: null wears [darkTheme], or the default
  /// preset at high contrast when [darkTheme] is null too.
  final ExpressiveThemeData? highContrastDarkTheme;

  /// The brightness to wear; null follows the platform's.
  final Brightness? brightness;

  /// The thin Material [ThemeData] the primitives read under [theme] on
  /// [platform]: built once per pair, since a [ThemeData] is costly to make.
  static ThemeData _primitivesOf(
    ExpressiveThemeData theme,
    TargetPlatform platform,
  ) {
    if (_primitives.length > _primitivesCap) _primitives.clear();
    return _primitives[(theme, platform)] ??= _buildPrimitives(theme, platform);
  }

  static const int _primitivesCap = 32;

  static final _primitives =
      <(ExpressiveThemeData, TargetPlatform), ThemeData>{};

  static ThemeData _buildPrimitives(
    ExpressiveThemeData theme,
    TargetPlatform platform,
  ) {
    final c = theme.colors;
    return ThemeData(
      brightness: theme.brightness,
      platform: platform,
      colorScheme: _materialColorScheme(c, theme.brightness),
      // The theme's text face, under the name Flutter registers it by
      // (`packages/<package>/<family>` from a package), so Flutter's own
      // widgets (a Material list tile, a tooltip) wear an app's typeface as
      // Expressive's parts do.
      fontFamily: theme.type.bodyLarge.fontFamily,
      // And the faces it falls back to for a script that face lacks.
      fontFamilyFallback: theme.type.bodyLarge.fontFamilyFallback,
      scaffoldBackgroundColor: c.surface,
      canvasColor: c.surface,
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      // An app's own page routes push as an ExpressivePage does, on every
      // platform.
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: expressivePageTransitions,
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: c.primary,
        selectionColor: _selectionOf(c),
        selectionHandleColor: c.primary,
      ),
    );
  }

  /// Flutter's [ColorScheme] with Expressive's roles, for the primitives
  /// that read one (never for drawing a component).
  static ColorScheme _materialColorScheme(
    ExpressiveColorScheme c,
    Brightness brightness,
  ) => ColorScheme(
    brightness: brightness,
    primary: c.primary,
    onPrimary: c.onPrimary,
    primaryContainer: c.primaryContainer,
    onPrimaryContainer: c.onPrimaryContainer,
    primaryFixed: c.primaryFixed,
    primaryFixedDim: c.primaryFixedDim,
    onPrimaryFixed: c.onPrimaryFixed,
    onPrimaryFixedVariant: c.onPrimaryFixedVariant,
    secondary: c.secondary,
    onSecondary: c.onSecondary,
    secondaryContainer: c.secondaryContainer,
    onSecondaryContainer: c.onSecondaryContainer,
    secondaryFixed: c.secondaryFixed,
    secondaryFixedDim: c.secondaryFixedDim,
    onSecondaryFixed: c.onSecondaryFixed,
    onSecondaryFixedVariant: c.onSecondaryFixedVariant,
    tertiary: c.tertiary,
    onTertiary: c.onTertiary,
    tertiaryContainer: c.tertiaryContainer,
    onTertiaryContainer: c.onTertiaryContainer,
    tertiaryFixed: c.tertiaryFixed,
    tertiaryFixedDim: c.tertiaryFixedDim,
    onTertiaryFixed: c.onTertiaryFixed,
    onTertiaryFixedVariant: c.onTertiaryFixedVariant,
    error: c.error,
    onError: c.onError,
    errorContainer: c.errorContainer,
    onErrorContainer: c.onErrorContainer,
    surface: c.surface,
    onSurface: c.onSurface,
    surfaceDim: c.surfaceDim,
    surfaceBright: c.surfaceBright,
    surfaceContainerLowest: c.surfaceContainerLowest,
    surfaceContainerLow: c.surfaceContainerLow,
    surfaceContainer: c.surfaceContainer,
    surfaceContainerHigh: c.surfaceContainerHigh,
    surfaceContainerHighest: c.surfaceContainerHighest,
    onSurfaceVariant: c.onSurfaceVariant,
    outline: c.outline,
    outlineVariant: c.outlineVariant,
    shadow: c.shadow,
    scrim: c.scrim,
    inverseSurface: c.inverseSurface,
    onInverseSurface: c.inverseOnSurface,
    inversePrimary: c.inversePrimary,
    surfaceTint: c.surfaceTint,
  );

  static Color _selectionOf(ExpressiveColorScheme c) =>
      c.primary.withValues(alpha: HostBehavior.textSelectionBackgroundOpacity);

  /// Android's edge-to-edge system bars over [theme]'s ground: transparent,
  /// no contrast scrim, icons dark on a light ground and light on a dark
  /// one.
  static SystemUiOverlayStyle systemBarsOf(ExpressiveThemeData theme) {
    final dark = theme.brightness == Brightness.dark;
    final transparent = theme.colors.surface.withValues(alpha: 0);
    return SystemUiOverlayStyle(
      statusBarColor: transparent,
      statusBarBrightness: theme.brightness,
      statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
      systemNavigationBarColor: transparent,
      systemNavigationBarDividerColor: transparent,
      systemNavigationBarIconBrightness: dark
          ? Brightness.light
          : Brightness.dark,
      systemNavigationBarContrastEnforced: false,
      systemStatusBarContrastEnforced: false,
    );
  }

  /// The theme a media ground wears under the nearest host (design_kit's
  /// `ChromeGround.media`): the host's dark theme, whatever brightness the
  /// app is in; the default preset's dark theme outside any host.
  static ExpressiveThemeData mediaThemeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_ExpressiveHostDark>()?.dark ??
      ExpressiveThemeData.preset(
        ExpressiveThemeData.defaultPreset,
        Brightness.dark,
      );

  @override
  State<ExpressiveHost> createState() => _ExpressiveHostState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(
        DiagnosticsProperty<ExpressiveThemeData?>(
          'theme',
          theme,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<ExpressiveThemeData?>(
          'darkTheme',
          darkTheme,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<ExpressiveThemeData?>(
          'highContrastTheme',
          highContrastTheme,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<ExpressiveThemeData?>(
          'highContrastDarkTheme',
          highContrastDarkTheme,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<Brightness?>(
          'brightness',
          brightness,
          defaultValue: null,
        ),
      );
  }
}

/// The dark theme a host wears, published for [ExpressiveMediaGround].
class _ExpressiveHostDark extends InheritedWidget {
  const _ExpressiveHostDark({required this.dark, required super.child});

  final ExpressiveThemeData dark;

  @override
  bool updateShouldNotify(_ExpressiveHostDark oldWidget) =>
      dark != oldWidget.dark;
}

/// A subtree on a media ground (design_kit's `ChromeGround.media`): the
/// host's dark theme ([ExpressiveHost.mediaThemeOf]), the primitives it
/// reads and its system bars — light icons — whatever brightness the app
/// is in. The shell mounts it around its bar on a media tab and
/// `ExpressiveScaffold` around a page that stands on media, so a feed's bar
/// and a pushed player's back arrow are drawn in the dark scheme.
class ExpressiveMediaGround extends StatelessWidget {
  /// A media ground around [child].
  const ExpressiveMediaGround({required this.child, super.key});

  /// What stands on the media ground.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = ExpressiveHost.mediaThemeOf(context);
    final platform = PreviewFrame.targetPlatformOf(context);
    return ExpressiveTheme(
      data: theme,
      child: Theme(
        data: ExpressiveHost._primitivesOf(theme, platform),
        child: AnnotatedRegion<SystemUiOverlayStyle>(
          value: ExpressiveHost.systemBarsOf(theme),
          child: child,
        ),
      ),
    );
  }
}

class _ExpressiveHostState extends State<ExpressiveHost> {
  /// Whether this host has asked Android for edge-to-edge: once, when it
  /// first runs on Android (never in a preview frame, whose bars are drawn).
  bool _edgeToEdge = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_edgeToEdge &&
        !kIsWeb &&
        PreviewFrame.maybeOf(context) == null &&
        PreviewFrame.targetPlatformOf(context) == TargetPlatform.android) {
      _edgeToEdge = true;
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  @override
  Widget build(BuildContext context) {
    final wanted =
        widget.brightness ??
        MediaQuery.maybePlatformBrightnessOf(context) ??
        Brightness.light;
    // The platform's high contrast picks the high-contrast pair, as
    // MaterialApp does; the default preset has its own, baked.
    final high = MediaQuery.maybeHighContrastOf(context) ?? false;
    ExpressiveThemeData preset(Brightness brightness) =>
        ExpressiveThemeData.preset(
          ExpressiveThemeData.defaultPreset,
          brightness,
          contrastLevel: high ? 1 : 0,
        );
    final dark =
        (high ? widget.highContrastDarkTheme : null) ??
        widget.darkTheme ??
        preset(Brightness.dark);
    final theme = wanted == Brightness.dark
        ? dark
        : (high ? widget.highContrastTheme : null) ??
              widget.theme ??
              preset(Brightness.light);
    // Behaviour follows the platform: never pinned, and a
    // preview frame's register inside one.
    final platform = PreviewFrame.targetPlatformOf(context);
    // Day to night (or a new preset) springs: the whole theme lerps on the
    // default effects spring, as AnimatedExpressiveTheme does, so every
    // colour cross-fades from where it is.
    return _ExpressiveHostDark(
      dark: dark,
      child: ExpressiveSpringTween<ExpressiveThemeData>(
        value: theme,
        motion: ExpressiveMotionKey.defaultEffects,
        lerp: ExpressiveThemeData.lerp,
        builder: (context, theme, child) {
          final c = theme.colors;
          return ExpressiveTheme(
            data: theme,
            child: Theme(
              data: ExpressiveHost._primitivesOf(theme, platform),
              child: AnnotatedRegion<SystemUiOverlayStyle>(
                value: ExpressiveHost.systemBarsOf(theme),
                child: ColoredBox(
                  color: c.surface,
                  child: DefaultSelectionStyle(
                    cursorColor: c.primary,
                    selectionColor: ExpressiveHost._selectionOf(c),
                    child: DefaultTextStyle(
                      style: theme.type.bodyLarge.copyWith(color: c.onSurface),
                      child: IconTheme(
                        data: IconThemeData(color: c.onSurface),
                        child: child!,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
        // The snackbars, under the theme, over the app.
        child: ExpressiveSnackBarHost(child: widget.child),
      ),
    );
  }
}
