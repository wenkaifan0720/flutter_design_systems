import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:ui_core/host.dart';

import '../theme.dart';

/// The one mount of Ledger. Picks the theme for the brightness in force,
/// publishes it as a [LedgerTheme], gives the platform primitives
/// beneath the thin Material `ThemeData` they read, paints the ground behind
/// the app, sets the body type as the default text style, carries status-bar
/// polarity, and lets the reader's text size reach [maxTextScale] (200%):
/// rows grow and wrap to it, and past it a page stands at 200% rather than
/// break. Day to night (or
/// one theme to another) the paper and the ink fade across in
/// [LedgerMotion.slow] ([AnimatedLedgerTheme]); with reduced motion on they
/// change at once. Every render host
/// mounts it once above its Navigator: the app in its router builder, a page
/// preview in its own.
///
/// The host follows the ambient platform for behaviour (scroll physics, text
/// selection, back gestures) and never pins one; inside a preview frame it
/// follows the frame's register.
///
/// ```dart
/// MaterialApp.router(builder: (context, child) => LedgerHost(child: child!))
/// ```
class LedgerHost extends StatelessWidget {
  /// Mounts Ledger over [child].
  const LedgerHost({
    required this.child,
    this.light,
    this.dark,
    this.brightness,
    super.key,
  });

  /// The light theme; null is the default preset's.
  final LedgerThemeData? light;

  /// The dark theme; null is the default preset's.
  final LedgerThemeData? dark;

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

  @override
  Widget build(BuildContext context) {
    final wanted =
        brightness ??
        PreviewFrame.maybeOf(context)?.brightness ??
        MediaQuery.platformBrightnessOf(context);
    final darkTheme =
        dark ??
        LedgerThemeData.preset(LedgerThemeData.presets.first, Brightness.dark);
    final t = wanted == Brightness.dark
        ? darkTheme
        : light ??
              LedgerThemeData.preset(
                LedgerThemeData.presets.first,
                Brightness.light,
              );
    final platform = PreviewFrame.targetPlatformOf(context);
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: maxTextScale,
      child: AnimatedLedgerTheme(
        data: t,
        dark: darkTheme,
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
                      child: _HostMark(child: child),
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
      dark: dark,
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
    );
