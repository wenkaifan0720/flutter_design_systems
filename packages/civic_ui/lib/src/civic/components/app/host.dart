import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart' show PageTransitionsTheme, Theme;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/host.dart';

import '../../theme.dart';
import '../toast/toast.dart';
import 'routes.dart';

/// Civic over a whole app: the theme for the brightness in force ([light]
/// by day, [dark] by night), the page's ground, words and glyphs, the
/// status bar's polarity, Civic's page change on every platform
/// ([CivicPageTransitions]) and a [CivicToaster] for `CivicToast.show`. It
/// never clamps the text scale: a reader at 200% gets 200%, and Civic's
/// parts grow to hold it.
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
    this.light,
    this.dark,
    this.brightness,
  });

  /// The app.
  final Widget child;

  /// The theme by day; null is Civic's own.
  final CivicThemeData? light;

  /// The theme by night; null is Civic's own.
  final CivicThemeData? dark;

  /// Pins the appearance; null follows the platform, or a preview frame.
  final Brightness? brightness;

  static final CivicThemeData _light = CivicThemeData.preset(
    CivicThemeData.presets.first,
    Brightness.light,
  );
  static final CivicThemeData _dark = CivicThemeData.preset(
    CivicThemeData.presets.first,
    Brightness.dark,
  );

  @override
  Widget build(BuildContext context) {
    final frame = PreviewFrame.maybeOf(context);
    final wanted =
        brightness ??
        frame?.brightness ??
        MediaQuery.platformBrightnessOf(context);
    final t = wanted == Brightness.dark ? dark ?? _dark : light ?? _light;
    return CivicTheme(
      data: t,
      child: CivicToaster(
        child: AnnotatedRegion<SystemUiOverlayStyle>(
          value: t.isDark
              ? SystemUiOverlayStyle.light
              : SystemUiOverlayStyle.dark,
          child: ColoredBox(
            color: t.background,
            child: Theme(
              data: Theme.of(context).copyWith(
                // Civic's page change, on every platform.
                pageTransitionsTheme: const PageTransitionsTheme(
                  builders: civicPageTransitions,
                ),
                // In a preview, the frame's platform is the one behaved as.
                platform: frame?.platform.targetPlatform,
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      EnumProperty<Brightness>('brightness', brightness, defaultValue: null),
    );
  }
}
