import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:ui_core/ui_core.dart';
import 'package:ui_core/host.dart';

import '../theme.dart';
import 'toast.dart';

/// Fluent 2's one mount in an app, over its navigator: the theme for the
/// appearance in force, the ground, the toasts, the tap targets and the
/// status bar's ink.
///
/// It builds the theme of [palette] by day and by night (or takes [light]
/// and [dark] as given). It sets both at [density] when one is given. It
/// changes both as [customize] says (the palette with the app's own
/// corners or typeface). It follows the platform's appearance unless
/// [brightness] pins one, and eases to a new appearance or palette over
/// Fluent's durationNormal (at once with reduced motion). It puts the theme
/// in scope with a [Fluent2Theme], paints the page's ground, hosts the
/// toasts ([Fluent2Toaster]), declares Fluent's tap targets (40 at a finger,
/// 24 at a pointer), sets the status bar's ink, and holds text scaling at
/// [maxTextScale] (200%), the largest size its parts are laid out for.
///
/// The host follows the platform for behaviour (scroll physics, text
/// selection, back gestures) and never pins one.
///
/// ```dart
/// MaterialApp(builder: (context, child) => Fluent2Host(palette: Fluent2ThemeData.palettes[1], child: child!), home: const HomePage())
/// ```
class Fluent2Host extends StatelessWidget {
  /// Mounts Fluent 2 over [child].
  const Fluent2Host({
    required this.child,
    this.palette,
    this.light,
    this.dark,
    this.brightness,
    this.density,
    this.customize,
    super.key,
  });

  /// The palette both appearances are built from, one of
  /// [Fluent2ThemeData.palettes]; null takes the first, `lapis`.
  final RawNamedPalette? palette;

  /// The theme by day; null builds [palette]'s.
  final Fluent2ThemeData? light;

  /// The theme by night; null builds [palette]'s.
  final Fluent2ThemeData? dark;

  /// Pins the appearance; null follows the platform.
  final Brightness? brightness;

  /// How compact the controls stand, by day and by night alike, whatever
  /// the window's width; null keeps each theme's own (a palette's is
  /// [Fluent2Density.standard]). [customize] sees the theme at this
  /// density.
  ///
  /// ```dart
  /// Fluent2Host(palette: Fluent2ThemeData.palettes[1], density: Fluent2Density.compact, child: child!)
  /// ```
  final Fluent2Density? density;

  /// Changes both appearances' themes, as built from [palette] (or taken
  /// from [light] and [dark]): their density, their corners, their
  /// typeface. A change of palette or appearance still eases across.
  ///
  /// ```dart
  /// Fluent2Host(palette: Fluent2ThemeData.palettes[1], customize: (theme) => theme.copyWith(density: Fluent2Density.compact), child: child!)
  /// ```
  final Fluent2ThemeData Function(Fluent2ThemeData theme)? customize;

  /// The app: its navigator, as `MaterialApp.builder` hands it.
  final Widget child;

  /// The largest text scale a Fluent 2 page lays out at: twice the size,
  /// the 200% a reader may ask for (WCAG 1.4.4).
  static const double maxTextScale = 2.0;

  /// The app's own root navigator, where Fluent 2 raises what covers the
  /// whole app (a sheet, a dialog, a menu, a toast): the outermost Navigator
  /// between [context] and the host above it. A render host that nests the
  /// app under a navigator of its own (a preview frame) stays outside, so
  /// what the app mounts above its navigator (its provider scope, its
  /// router) reaches the route. With no navigator below the host (a page
  /// preview), the nearest one.
  ///
  /// ```dart
  /// Fluent2Host.navigatorOf(context).push(route)
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
  static SystemUiOverlayStyle systemBarsOf(Fluent2ThemeData theme) =>
      theme.isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark;

  @override
  Widget build(BuildContext context) {
    final wanted =
        brightness ??
        PreviewFrame.maybeOf(context)?.brightness ??
        MediaQuery.platformBrightnessOf(context);
    final id = (palette ?? Fluent2ThemeData.palettes.first).id;
    final changes = customize ?? (Fluent2ThemeData t) => t;
    final density = this.density;
    Fluent2ThemeData shaped(Fluent2ThemeData theme) =>
        changes(density == null ? theme : theme.copyWith(density: density));
    final darkTheme = shaped(
      dark ?? Fluent2ThemeData.preset(id, Brightness.dark),
    );
    final t = wanted == Brightness.dark
        ? darkTheme
        : shaped(light ?? Fluent2ThemeData.preset(id, Brightness.light));
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: maxTextScale,
      // Day to night (and a new preset) eases over Fluent's durationNormal,
      // every token at once; a cut under Reduce Motion.
      child: AnimatedFluent2Theme(
        data: t,
        darkData: darkTheme,
        duration: Fluent2Motion.of(context, Fluent2Motion.normal),
        curve: Fluent2Motion.easyEase,
        child: AnnotatedRegion<SystemUiOverlayStyle>(
          value: systemBarsOf(t),
          // Fluent's tap targets: ui_core's floors, 40 where a finger
          // reaches the controls (Fluent2Layout.hitTargetOf), WCAG's 24 for a
          // pointer; each control lays out at least that big
          // (TapTargetPadding).
          child: RawTapTargetScope(
            targets: RawTapTargets(
              input: Fluent2Layout.padded(context)
                  ? RawInput.touch
                  : RawInput.pointer,
            ),
            child: Builder(
              builder: (context) => ColoredBox(
                color: context.fluent2Theme.background,
                child: Fluent2Toaster(child: _HostMark(child: child)),
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
        DiagnosticsProperty<Fluent2ThemeData>(
          'light',
          light,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<Fluent2ThemeData>('dark', dark, defaultValue: null),
      )
      ..add(
        EnumProperty<Brightness>('brightness', brightness, defaultValue: null),
      )
      ..add(
        DiagnosticsProperty<Fluent2Density>(
          'density',
          density,
          defaultValue: null,
        ),
      )
      ..add(
        ObjectFlagProperty<Fluent2ThemeData Function(Fluent2ThemeData)>.has(
          'customize',
          customize,
        ),
      );
  }
}

/// Where the app below a [Fluent2Host] begins: [Fluent2Host.navigatorOf]
/// looks for navigators up to here and no further.
class _HostMark extends StatelessWidget {
  const _HostMark({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}

/// Stands [child] on the media ground: the host's dark tokens under a
/// light status bar, for chrome drawn over a full-bleed photograph or
/// video (the shell's bar on a media tab). Nothing in it blurs.
///
/// ```dart
/// Fluent2MediaGround(child: bar)
/// ```
class Fluent2MediaGround extends StatelessWidget {
  /// Stands [child] on the media ground.
  const Fluent2MediaGround({required this.child, super.key});

  /// The chrome drawn over the media.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final dark = Fluent2Theme.darkOf(context);
    return Fluent2Theme(
      data: dark,
      darkData: dark,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: child,
      ),
    );
  }
}
