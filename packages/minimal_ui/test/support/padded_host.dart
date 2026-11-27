import 'package:material_ui/material_ui.dart';
import 'package:minimal_ui/minimal_ui.dart';

/// [child] centred on a page with 24 px round it, under a MinimalHost at
/// [density] that stands above the Navigator, as an app mounts it.
Widget paddedHost(Widget child, {MinimalDensity? density}) => MaterialApp(
  builder: (context, navigator) => MinimalHost(
    light: MinimalThemeData.preset(
      'standard',
      Brightness.light,
    ).copyWith(density: density),
    dark: MinimalThemeData.preset(
      'standard',
      Brightness.dark,
    ).copyWith(density: density),
    brightness: Brightness.light,
    child: navigator!,
  ),
  home: Scaffold(
    body: Center(
      child: Padding(padding: const EdgeInsets.all(24), child: child),
    ),
  ),
);
