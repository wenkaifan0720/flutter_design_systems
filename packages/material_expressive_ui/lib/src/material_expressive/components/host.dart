/// The host: the theme scope, the thin Material `ThemeData` primitives
/// read, the ground, the text and icon defaults and Android's edge-to-edge
/// system bars, mounted once around the app (CONTRACT §4.2 `ExpressiveHost`;
/// Compose's `MaterialExpressiveTheme`). Chrome, no vocabulary role.
/// Owner: w1-host.
///
/// It pins no platform (CONTRACT §5): the thin `ThemeData`'s platform is
/// the ambient one, a preview frame's register inside one, so scroll
/// physics, text handles, page transitions and haptics follow the
/// platform while everything drawn stays Material. It sets no text-scale
/// clamp: text scales as the platform asks, as in Compose.
library;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:ui_core/host.dart';

import '../color.dart';
import '../internal/tokens/behavior.g.dart';
import '../motion.dart';
import '../theme.dart';
import '../type.dart';

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
    this.light,
    this.dark,
    this.brightness,
    super.key,
  });

  /// What the host stands the theme over: the app.
  final Widget child;

  /// The light theme; null wears the default preset's.
  final ExpressiveThemeData? light;

  /// The dark theme; null wears the default preset's.
  final ExpressiveThemeData? dark;

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
      fontFamily: ExpressiveTextTheme.family,
      scaffoldBackgroundColor: c.surface,
      canvasColor: c.surface,
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
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
    final dark =
        widget.dark ??
        ExpressiveThemeData.preset(
          ExpressiveThemeData.defaultPreset,
          Brightness.dark,
        );
    final theme = wanted == Brightness.dark
        ? dark
        : widget.light ??
              ExpressiveThemeData.preset(
                ExpressiveThemeData.defaultPreset,
                Brightness.light,
              );
    // Behaviour follows the platform (CONTRACT §5): never pinned, and a
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
        child: widget.child,
      ),
    );
  }
}
