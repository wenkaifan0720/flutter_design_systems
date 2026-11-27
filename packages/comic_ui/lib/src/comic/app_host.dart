// The app's one mount above its navigator: Comic's theme by day and by night, its print run, the page's ground, the
// text defaults and the app's toaster. In the main library, so an app needs nothing past it.
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart' show RawNamedPalette;
import 'package:ui_core/host.dart' show PreviewFrame;

import 'press.dart' show comicStateCurve;
import 'raised.dart' show ComicAppToaster;
import 'theme.dart';

/// The app's host, mounted once around the navigator: Comic's theme by day and by night (the platform's, or
/// [brightness]), [palette]'s print run, the page's ground, the text defaults and the app's one toaster. A new
/// appearance or palette moves: every colour of the page lerps to it. A snack bar or a toast raised anywhere under it
/// (`showComicSnackBar`, `showComicToast`) stands in its toaster, above the navigator: it stays in sight when the app's
/// place changes, and stands above the shell's tab bar, a page's footer and the keyboard.
///
/// ```dart
/// MaterialApp(builder: (context, child) => ComicHost(palette: ComicThemeData.palettes[1], child: child!), home: const Text('Home'))
/// ```
class ComicHost extends StatelessWidget {
  /// Creates a [ComicHost].
  const ComicHost({
    super.key,
    this.palette,
    this.light,
    this.dark,
    this.brightness,
    required this.child,
  });

  /// The print run both appearances are built from, one of [ComicThemeData.palettes]; null takes the first, offset.
  final RawNamedPalette? palette;

  /// The theme by day and by night; null builds [palette]'s.
  final ComicThemeData? light, dark;

  /// The requested light or dark appearance.
  final Brightness? brightness;

  /// Content placed inside this widget.
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final wanted =
        brightness ??
        PreviewFrame.maybeOf(context)?.brightness ??
        MediaQuery.platformBrightnessOf(context);
    final theme =
        (wanted == Brightness.dark ? dark : light) ??
        ComicThemeData(palette: palette, brightness: wanted);
    // Day to night (and one preset to another) moves: every colour of the page lerps to the new palette.
    return AnimatedComicTheme(
      data: theme,
      duration: ComicMotion.of(context).raise,
      curve: comicStateCurve,
      child: Builder(
        builder: (context) {
          final t = ComicTheme.of(context);
          return ColoredBox(
            color: t.colors.background,
            child: DefaultTextStyle(
              style: t.type.body,
              child: IconTheme(
                data: IconThemeData(color: t.colors.text, size: 22),
                child: ComicAppToaster(child: child),
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
        DiagnosticsProperty<ComicThemeData>('light', light, defaultValue: null),
      )
      ..add(
        DiagnosticsProperty<ComicThemeData>('dark', dark, defaultValue: null),
      )
      ..add(
        EnumProperty<Brightness>('brightness', brightness, defaultValue: null),
      );
  }
}
