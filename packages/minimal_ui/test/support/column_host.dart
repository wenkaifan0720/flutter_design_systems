import 'package:material_ui/material_ui.dart';
import 'package:minimal_ui/minimal_ui.dart';

/// Minimal's standard preset by day.
final MinimalThemeData lightTheme = MinimalThemeData.preset(
  'standard',
  Brightness.light,
);

/// [child] 390 px wide at the top of a page, under a MinimalHost in [theme]
/// (the standard preset when null) that stands above the Navigator, as an
/// app mounts it; [disableAnimations] turns motion off.
Widget columnHost(
  Widget child, {
  bool disableAnimations = false,
  MinimalThemeData? theme,
}) => MaterialApp(
  builder: (context, navigator) => MinimalHost(
    light: theme ?? lightTheme,
    dark: MinimalThemeData.preset('standard', Brightness.dark),
    brightness: Brightness.light,
    child: MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(disableAnimations: disableAnimations),
      child: navigator!,
    ),
  ),
  home: Scaffold(
    body: Align(
      alignment: Alignment.topCenter,
      child: SizedBox(width: 390, child: child),
    ),
  ),
);
