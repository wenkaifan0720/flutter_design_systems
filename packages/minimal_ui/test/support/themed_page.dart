import 'package:material_ui/material_ui.dart';
import 'package:minimal_ui/minimal_ui.dart';

/// Minimal's standard preset by day.
final MinimalThemeData dayTheme = MinimalThemeData.preset(
  'standard',
  Brightness.light,
);

/// Minimal's standard preset by night.
final MinimalThemeData nightTheme = MinimalThemeData.preset(
  'standard',
  Brightness.dark,
);

/// [child] on a full-bleed page [width] wide in [theme].
Widget themedPage(
  Widget child, {
  double width = 390,
  MinimalThemeData? theme,
}) => MaterialApp(
  builder: (context, navigator) => MinimalHost(
    light: theme ?? dayTheme,
    dark: nightTheme,
    brightness: Brightness.light,
    child: navigator!,
  ),
  home: MinimalScaffold(
    padding: EdgeInsets.zero,
    body: Align(
      alignment: AlignmentDirectional.topStart,
      child: SizedBox(width: width, child: child),
    ),
  ),
);
