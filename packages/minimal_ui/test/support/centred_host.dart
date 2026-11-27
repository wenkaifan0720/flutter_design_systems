import 'package:material_ui/material_ui.dart';
import 'package:minimal_ui/minimal_ui.dart';

/// [child] centred on a page under a MinimalHost at [brightness]. The host
/// stands above the Navigator, as an app mounts it, so overlays (a dialog, a
/// toast) read the same tokens as the page.
Widget centredHost(Widget child, {Brightness brightness = Brightness.light}) =>
    MaterialApp(
      builder: (context, navigator) => MinimalHost(
        light: MinimalThemeData.preset('standard', Brightness.light),
        dark: MinimalThemeData.preset('standard', Brightness.dark),
        brightness: brightness,
        child: navigator!,
      ),
      home: Scaffold(body: Center(child: child)),
    );
