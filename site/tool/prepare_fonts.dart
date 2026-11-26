import 'dart:convert';
import 'dart:io';

/// Each deferred look calls its package's public font loader. Letting Flutter
/// also preload its full workspace manifest downloads every look's fonts on
/// the first visit. Keep the shared icon fonts and CanvasKit's default face.
void main(List<String> args) {
  final assets = Directory(args.single);
  const font = 'packages/material_expressive_ui/assets/fonts/RobotoFlex.ttf';
  if (!File.fromUri(assets.uri.resolve(font)).existsSync()) {
    throw StateError('Missing the local default font: $font');
  }
  final manifest = File.fromUri(assets.uri.resolve('FontManifest.json'));
  final families = (jsonDecode(manifest.readAsStringSync()) as List)
      .cast<Map<String, dynamic>>();
  final looks = jsonDecode(
    File.fromUri(Platform.script.resolve('../looks.json')).readAsStringSync(),
  ) as Map<String, dynamic>;
  final prefixes = looks.values
      .map((look) => "packages/${look['package']}/")
      .toList();
  manifest.writeAsStringSync(
    jsonEncode([
      for (final family in families)
        if (family['family'] != 'Roboto' &&
            !prefixes.any((family['family'] as String).startsWith))
          family,
      {
        'family': 'Roboto',
        'fonts': [
          {'asset': font},
        ],
      },
    ]),
  );
}
