import 'package:material_ui/material_ui.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:minimal_ui/minimal_host.dart';

/// [child] on a page that scrolls, 18 px in, under a MinimalHost that stands
/// above the Navigator, as an app mounts it, so overlays (a menu, a
/// calendar, a sheet) read the same tokens as the page.
Widget scrollingHost(Widget child) => MaterialApp(
  builder: (context, navigator) => MinimalHost(
    light: MinimalThemeData.preset('standard', Brightness.light),
    dark: MinimalThemeData.preset('standard', Brightness.dark),
    brightness: Brightness.light,
    child: navigator!,
  ),
  home: Scaffold(
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: child,
    ),
  ),
);
