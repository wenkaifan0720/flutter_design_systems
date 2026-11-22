import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:minimal_ui/minimal_host.dart';

/// Minimal's standard preset by day.
final MinimalThemeData lightTheme = MinimalThemeData.preset(
  'standard',
  Brightness.light,
);

/// [child] centred on a page with 18 px round it, under a MinimalHost that
/// stands above the Navigator, as an app mounts it.
Widget displayHost(Widget child) => MaterialApp(
  builder: (context, navigator) => MinimalHost(
    light: lightTheme,
    dark: MinimalThemeData.preset('standard', Brightness.dark),
    brightness: Brightness.light,
    child: navigator!,
  ),
  home: Scaffold(
    body: Center(
      child: Padding(padding: const EdgeInsets.all(18), child: child),
    ),
  ),
);

/// The colour [text] is set in.
Color? colorOf(WidgetTester tester, String text) =>
    tester.widget<Text>(find.text(text)).style?.color;
