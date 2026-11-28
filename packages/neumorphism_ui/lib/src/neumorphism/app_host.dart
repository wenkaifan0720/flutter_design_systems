import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';
import 'package:ui_core/host.dart';

import 'knobs.dart' show NeumorphicDensity;
import 'overlays.dart' show NeumorphicToaster;
import 'theme.dart';

/// The one mount of Neumorphism in an app, above its Navigator: picks the
/// theme for the brightness in force (the platform's, or [brightness]) from
/// [palette], publishes it as a [NeumorphicTheme] (a change of brightness or
/// palette eases through [AnimatedNeumorphicTheme]), paints the wall behind
/// the app, gives words and icons the look's ink and holds the toasts
/// ([showNeumorphicToast]) over the app.
///
/// ```dart
/// MaterialApp(
///   builder: (context, child) => NeumorphicHost(child: child!),
///   home: const BooksPage(),
/// )
/// ```
///
/// ```dart
/// MaterialApp(builder: (context, child) => NeumorphicHost(palette: NeumorphicThemeData.palettes[1], child: child!), home: const Text('Home'))
/// ```
class NeumorphicHost extends StatelessWidget {
  /// The look round [child]: [theme] or [darkTheme] as the appearance in force asks, either left out being [palette]'s
  /// in that appearance. [density] and [shapeScheme], when given, stand over both. The window's width changes none of
  /// them: the parts follow the width themselves.
  const NeumorphicHost({
    required this.child,
    this.palette,
    this.theme,
    this.darkTheme,
    this.brightness,
    this.density,
    this.shapeScheme,
    super.key,
  });

  /// The palette both appearances are built from, one of
  /// [NeumorphicThemeData.palettes] (the app's stored choice, say); null is
  /// the first, porcelain. A change of palette eases from the old colours to
  /// the new.
  final RawNamedPalette? palette;

  /// The light theme; null is [palette]'s.
  final NeumorphicThemeData? theme;

  /// The dark theme; null is [palette]'s night.
  final NeumorphicThemeData? darkTheme;

  /// Pins the appearance; null follows the platform (or a preview's frame).
  final Brightness? brightness;

  /// How tight the controls stand, by day and by night; null keeps the theme's own (the platform's: compact with a
  /// pointer, standard on touch).
  final NeumorphicDensity? density;

  /// The corners and the depth, by day and by night; null keeps the theme's own. The theme holds it to the look's
  /// bands ([NeumorphicThemeData.shapeLimits]).
  final RawShapeScheme? shapeScheme;

  /// The app.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final wanted =
        brightness ??
        PreviewFrame.maybeOf(context)?.brightness ??
        MediaQuery.platformBrightnessOf(context);
    final id = (palette ?? NeumorphicThemeData.palettes.first).id;
    final chosen = wanted == Brightness.dark
        ? darkTheme ?? NeumorphicThemeData.preset(id, Brightness.dark)
        : theme ?? NeumorphicThemeData.preset(id, Brightness.light);
    // The host's knobs stand over the theme in force, whichever it is.
    final data = density == null && shapeScheme == null
        ? chosen
        : chosen.copyWith(density: density, shapeScheme: shapeScheme);
    // Day to night, or one palette to another, eases over a route's travel;
    // a cut under Reduce Motion.
    return AnimatedNeumorphicTheme(
      data: data,
      duration: rawReduceMotionOf(context) ? Duration.zero : data.motion.travel,
      curve: data.motion.standard,
      child: Builder(
        builder: (context) {
          final t = NeumorphicTheme.of(context);
          return ColoredBox(
            color: t.colors.ground,
            child: DefaultTextStyle(
              style: t.textTheme.body,
              child: IconTheme(
                data: IconThemeData(color: t.colors.ink, size: 22),
                child: NeumorphicToaster(child: child),
              ),
            ),
          );
        },
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
        DiagnosticsProperty<NeumorphicThemeData>(
          'theme',
          theme,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<NeumorphicThemeData>(
          'darkTheme',
          darkTheme,
          defaultValue: null,
        ),
      )
      ..add(
        EnumProperty<Brightness>('brightness', brightness, defaultValue: null),
      )
      ..add(
        DiagnosticsProperty<NeumorphicDensity>(
          'density',
          density,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<RawShapeScheme>(
          'shapeScheme',
          shapeScheme,
          defaultValue: null,
        ),
      );
  }
}
