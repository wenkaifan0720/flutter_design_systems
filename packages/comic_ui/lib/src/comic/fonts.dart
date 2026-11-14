/// Where Comic's faces come from. An app the host builds bundles Bangers and ShantellSans itself; the `comic_ui` package bundles them in the
/// package, and its build sets [comicFontPackage] to its own name, which is the one line in which the package differs
/// from this source.
library;

import 'package:flutter/services.dart';

/// The package that bundles Comic's faces, or null when the app does. Every Comic text style passes it as
/// `TextStyle.package`.
// ignore: unnecessary_nullable_for_final_variable_declarations, the package's build names it.
const String? comicFontPackage = 'comic_ui';

/// [family] under the name Flutter registers it by: `ShantellSans` when the app bundles it, `packages/comic_ui/ShantellSans` from the
/// package. A test that loads the faces itself loads them under this name.
///
/// ```dart
/// final loader = FontLoader(comicFontFamily('ShantellSans'))..addFont(bytes);
/// await loader.load();
/// ```
String comicFontFamily(String family) =>
    comicFontPackage == null ? family : 'packages/$comicFontPackage/$family';

/// The faces Comic bundles, by family, each file's name under `assets/fonts/`.
const Map<String, List<String>> _faces = {
  'Bangers': ['Bangers-Regular'],
  'ShantellSans': [
    'ShantellSans-400',
    'ShantellSans-500',
    'ShantellSans-600',
    'ShantellSans-700',
    'ShantellSans-800',
  ],
};

/// Loads the faces Comic bundles, so the first frame is set in them. Await it before `runApp`: on the web a bundled
/// face otherwise arrives after the first frames, which flash in a fallback face. An app that names its own faces
/// (`ComicTypeface.app`) loads those itself, the same way, with a `FontLoader`.
///
/// ```dart
/// Future<void> main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///   await comicLoadFonts();
///   runApp(const MyApp());
/// }
/// ```
Future<void> comicLoadFonts() => Future.wait([
  for (final MapEntry(key: family, value: files) in _faces.entries)
    _loader(family, files).load(),
]);

FontLoader _loader(String family, List<String> files) {
  final loader = FontLoader(comicFontFamily(family));
  for (final file in files) {
    loader.addFont(
      rootBundle.load(
        comicFontPackage == null
            ? 'assets/fonts/$file.ttf'
            : 'packages/$comicFontPackage/assets/fonts/$file.ttf',
      ),
    );
  }
  return loader;
}
