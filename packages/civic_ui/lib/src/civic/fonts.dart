/// Where Civic's faces come from. The `civic_ui` package bundles Atkinson
/// Hyperlegible Next and Mono and Noto Sans Arabic, and sets
/// [civicFontPackage] to its own name; a host app that bundles the faces
/// itself leaves it null.
library;

import 'package:flutter/services.dart';

/// The package that bundles Civic's faces, or null when the app does. Every
/// Civic text style passes it as `TextStyle.package`.
// ignore: unnecessary_nullable_for_final_variable_declarations, the package's build names it.
const String? civicFontPackage = 'civic_ui';

/// [family] under the name Flutter registers it by: `AtkinsonNext` when the
/// app bundles it, `packages/civic_ui/AtkinsonNext` from the package. A test
/// that loads the faces itself loads them under this name.
///
/// ```dart
/// final loader = FontLoader(civicFontFamily('AtkinsonNext'))..addFont(bytes);
/// await loader.load();
/// ```
String civicFontFamily(String family) =>
    civicFontPackage == null ? family : 'packages/$civicFontPackage/$family';

/// The faces Civic bundles, by family, each file's name under
/// `assets/fonts/`.
const Map<String, List<String>> _faces = {
  'AtkinsonNext': [
    'AtkinsonNext-400',
    'AtkinsonNext-400Italic',
    'AtkinsonNext-700',
  ],
  'AtkinsonMono': ['AtkinsonMono-400', 'AtkinsonMono-700'],
  'NotoSansArabic': ['NotoSansArabic-400', 'NotoSansArabic-700'],
};

/// Loads the faces Civic bundles, so the first frame is set in them. Await
/// it before `runApp`: on the web a bundled face otherwise arrives after the
/// first frames, which flash in a fallback face.
///
/// ```dart
/// Future<void> main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///   await civicLoadFonts();
///   runApp(const MyApp());
/// }
/// ```
Future<void> civicLoadFonts() => Future.wait([
  for (final MapEntry(key: family, value: files) in _faces.entries)
    _loader(family, files).load(),
]);

FontLoader _loader(String family, List<String> files) {
  final loader = FontLoader(civicFontFamily(family));
  for (final file in files) {
    loader.addFont(
      rootBundle.load(
        civicFontPackage == null
            ? 'assets/fonts/$file.ttf'
            : 'packages/$civicFontPackage/assets/fonts/$file.ttf',
      ),
    );
  }
  return loader;
}
