import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:ui_core/ui_core.dart';
import 'package:ui_core/host.dart';

import '../page_motion.dart';
import '../theme.dart';
import 'toast.dart';

/// Ledger over a whole app, its one mount: the theme for the brightness in
/// force ([theme] by day, [darkTheme] by night, or a [palette]'s), published
/// as a [LedgerTheme]; the ground painted behind the app, the body type as
/// the default text style, the status bar's polarity, Ledger's page motion
/// for pushed routes, and the toasts ([LedgerToaster]) for
/// `LedgerToast.show`. It lets the reader's text size reach [maxTextScale]
/// (200%): rows grow and wrap to it, and past it a page stands at 200%
/// rather than break. Day to night, or one palette to another, the paper and
/// the ink fade across in [LedgerMotion.slow] ([AnimatedLedgerTheme]); with
/// reduced motion on they change at once.
///
/// Mount it once in the app's `builder`, above its Navigator, so every
/// page, dialog and menu stands inside it. A bare [LedgerTheme] gives a
/// subtree the theme alone: no toasts, no ground, no fade.
///
/// The host follows the ambient platform for behaviour (scroll physics, text
/// selection, back gestures) and never pins one; inside a preview frame it
/// follows the frame's register.
/// ```dart
/// MaterialApp(
///   builder: (context, child) => LedgerHost(brightness: appearance, child: child!),
///   home: const HomePage(),
/// )
/// ```
class LedgerHost extends StatelessWidget {
  /// Mounts Ledger over [child].
  const LedgerHost({
    required this.child,
    this.theme,
    this.darkTheme,
    this.palette,
    this.brightness,
    super.key,
  });

  /// The light theme; null is the default preset's.
  final LedgerThemeData? theme;

  /// The dark theme; null is the default preset's.
  final LedgerThemeData? darkTheme;

  /// The palette by day and by night where [theme] or [darkTheme] is null:
  /// one of [LedgerThemeData.palettes] (the app's stored choice) or the
  /// app's own ([LedgerThemeData.fromPalette]); null is Quire.
  final RawNamedPalette? palette;

  /// Pins the appearance; null follows the platform (or the preview frame).
  final Brightness? brightness;

  /// The app.
  final Widget child;

  /// The largest text scale a Ledger page lays out at: 200%, as WCAG's
  /// resize text asks.
  static const double maxTextScale = 2.0;

  /// The app's own root navigator, where Ledger raises what covers the
  /// whole app (a sheet, a dialog, a menu, a toast): the outermost Navigator
  /// between [context] and the host above it. A render host that nests the
  /// app under a navigator of its own (a preview frame) stays outside, so
  /// what the app mounts above its navigator (its provider scope, its router)
  /// reaches the route. With no navigator below the host (a page preview),
  /// the nearest one.
  ///
  /// ```dart
  /// LedgerHost.navigatorOf(context).push(route)
  /// ```
  static NavigatorState navigatorOf(BuildContext context) {
    NavigatorState? outermost;
    if (context is StatefulElement && context.state is NavigatorState) {
      outermost = context.state as NavigatorState;
    }
    context.visitAncestorElements((element) {
      if (element.widget is _HostMark) return false;
      if (element is StatefulElement && element.state is NavigatorState) {
        outermost = element.state as NavigatorState;
      }
      return true;
    });
    return outermost ?? Navigator.of(context);
  }

  /// The status bar's polarity over [theme]'s ground.
  static SystemUiOverlayStyle systemBarsOf(LedgerThemeData theme) =>
      theme.isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark;

  // LedgerSpacing's steps are every 2 from 2 to 40: the grid it declares.
  static const _grid = RawSpacing(grid: 2);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(
        DiagnosticsProperty<LedgerThemeData>(
          'theme',
          theme,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<LedgerThemeData>(
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
        DiagnosticsProperty<Brightness>(
          'brightness',
          brightness,
          defaultValue: null,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final wanted =
        brightness ??
        PreviewFrame.maybeOf(context)?.brightness ??
        MediaQuery.platformBrightnessOf(context);
    final chosen = palette ?? LedgerThemeData.palettes.first;
    final night =
        darkTheme ?? LedgerThemeData.fromPalette(chosen, Brightness.dark);
    final t = wanted == Brightness.dark
        ? night
        : theme ?? LedgerThemeData.fromPalette(chosen, Brightness.light);
    final platform = PreviewFrame.targetPlatformOf(context);
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: maxTextScale,
      child: AnimatedLedgerTheme(
        data: t,
        darkData: night,
        duration: LedgerMotion.of(context, LedgerMotion.slow),
        curve: LedgerMotion.out,
        // The theme of the moment, on its way from day to night.
        child: Builder(
          builder: (context) {
            final now = context.ledgerTheme;
            return Theme(
              data: _materialThemeFor(now, platform),
              child: AnnotatedRegion<SystemUiOverlayStyle>(
                value: systemBarsOf(t),
                child: ColoredBox(
                  color: now.background,
                  child: DefaultTextStyle(
                    style: now.body,
                    child: IconTheme(
                      data: IconThemeData(color: now.textPrimary, size: 24),
                      // Ledger's parts stand on a 2-pt grid (LedgerSpacing's
                      // steps), declared for ui_core's spacing check.
                      child: RawSpacingScope(
                        spacing: _grid,
                        // Toasts stand over the app, above its navigator.
                        child: LedgerToaster(child: _HostMark(child: child)),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Where the app below a [LedgerHost] begins: [LedgerHost.navigatorOf]
/// looks for navigators up to here and no further.
class _HostMark extends StatelessWidget {
  const _HostMark({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}

/// Stands [child] on the media ground: the host's dark tokens under a light
/// status bar, for chrome drawn over a full-bleed photograph or video (the
/// shell's bar on a media tab). Nothing in it blurs.
class LedgerMediaGround extends StatelessWidget {
  /// Stands [child] on the media ground.
  const LedgerMediaGround({required this.child, super.key});

  /// The chrome drawn over the media.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final dark = LedgerTheme.darkOf(context);
    return LedgerTheme(
      data: dark,
      darkData: dark,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: child,
      ),
    );
  }
}

/// The Material theme per Ledger theme and platform, built once: the host
/// runs again on every navigation (the router's builder). The presets are one
/// instance per id and appearance, so this stays small.
final Map<TargetPlatform, Expando<ThemeData>> _materialThemes = {
  for (final p in TargetPlatform.values) p: Expando<ThemeData>('quire'),
};

ThemeData _materialThemeFor(LedgerThemeData t, TargetPlatform platform) =>
    _materialThemes[platform]![t] ??= _ledgerMaterialTheme(t, platform);

/// The thin Material `ThemeData` the platform primitives under a
/// [LedgerHost] still read: a `Scaffold`'s ground, a `TextField`'s
/// selection tint and cursor, a sheet's route. No token lives here;
/// Ledger components read [LedgerThemeData] through
/// `context.ledgerTheme`.
ThemeData _ledgerMaterialTheme(LedgerThemeData t, TargetPlatform platform) =>
    ThemeData(
      useMaterial3: true,
      brightness: t.brightness,
      platform: platform,
      fontFamily: t.body.fontFamily,
      scaffoldBackgroundColor: t.background,
      splashFactory: NoSplash.splashFactory,
      highlightColor: const Color(0x00000000),
      materialTapTargetSize: MaterialTapTargetSize.padded,
      colorScheme: ColorScheme(
        brightness: t.brightness,
        primary: t.accent,
        onPrimary: t.onAccent,
        secondary: t.surfaceInverse,
        onSecondary: t.textInverse,
        // Material writes its error words in it: the vermilion as words.
        error: t.over,
        onError: t.onDanger,
        surface: t.background,
        onSurface: t.textPrimary,
        outline: t.borderStrong,
        outlineVariant: t.border,
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: t.accent,
        selectionColor: t.accent.withValues(alpha: 0.3),
        selectionHandleColor: t.accent,
      ),
      dividerTheme: DividerThemeData(color: t.hairline, thickness: 1),
      // A page pushed under the host is laid down in Ledger's motion (and on
      // iOS keeps its edge swipe back): this theme stands nearest the
      // navigator, so without the map its routes would fly in on the
      // platform's slide or zoom, a LedgerPage's included.
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: ledgerPageTransitions,
      ),
    );
