import 'package:material_ui/material_ui.dart';
import 'package:minimal_ui/minimal_ui.dart';

/// [child] at the top left of a page [width] wide, under a MinimalHost.
Widget pageApp(Widget child, {double width = 390}) => MaterialApp(
  builder: (context, child) => MinimalHost(
    light: MinimalThemeData.preset('standard', Brightness.light),
    dark: MinimalThemeData.preset('standard', Brightness.dark),
    brightness: Brightness.light,
    child: child!,
  ),
  home: MinimalScaffold(
    padding: EdgeInsets.zero,
    body: Align(
      alignment: Alignment.topLeft,
      child: SizedBox(width: width, child: child),
    ),
  ),
);

/// [child] under a larger text scale.
Widget scaled(Widget child, [double scale = 1.3]) => Builder(
  builder: (context) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
    child: child,
  ),
);
