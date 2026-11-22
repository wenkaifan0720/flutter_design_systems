import 'package:material_ui/material_ui.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:minimal_ui/minimal_host.dart';

/// [child] centred on a page with 18 px round it, under a MinimalHost in
/// [preset] that stands above the Navigator, at [brightness], read
/// [direction], at text scale [scale].
Widget chartHost(
  Widget child, {
  Brightness brightness = Brightness.light,
  TextDirection direction = TextDirection.ltr,
  double scale = 1,
  String preset = 'standard',
}) => MaterialApp(
  builder: (context, navigator) => MinimalHost(
    light: MinimalThemeData.preset(preset, Brightness.light),
    dark: MinimalThemeData.preset(preset, Brightness.dark),
    brightness: brightness,
    child: MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: TextScaler.linear(scale)),
      child: Directionality(textDirection: direction, child: navigator!),
    ),
  ),
  home: Scaffold(
    body: Center(
      child: Padding(padding: const EdgeInsets.all(18), child: child),
    ),
  ),
);

/// The WCAG contrast ratio between [a] and [b].
double contrastRatio(Color a, Color b) {
  final x = a.computeLuminance() + 0.05;
  final y = b.computeLuminance() + 0.05;
  return x > y ? x / y : y / x;
}
