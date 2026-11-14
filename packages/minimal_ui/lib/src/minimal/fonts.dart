/// Where Minimal's faces come from: the `minimal_ui` package bundles Geist
/// and Geist Mono, and [minimalFontPackage] names the package they load
/// from.
library;

import 'package:flutter/services.dart';

/// The package that bundles Minimal's faces and its sign-in marks, or null
/// when the app does. Every Minimal text style passes it as
/// `TextStyle.package`, and a sign-in mark looks under its assets.
// ignore: unnecessary_nullable_for_final_variable_declarations, the package's build names it.
const String? minimalFontPackage = 'minimal_ui';

/// [family] under the name Flutter registers it by: `Geist` when the app
/// bundles it, `packages/minimal_ui/Geist` from the package. A test that
/// loads the faces itself loads them under this name.
///
/// ```dart
/// final loader = FontLoader(minimalFontFamily('Geist'))..addFont(bytes);
/// await loader.load();
/// ```
String minimalFontFamily(String family) => minimalFontPackage == null
    ? family
    : 'packages/$minimalFontPackage/$family';

/// The faces Minimal bundles, by family, each file's name under
/// `assets/fonts/`.
const Map<String, List<String>> _faces = {
  'Geist': ['Geist-400', 'Geist-500', 'Geist-600'],
  'GeistMono': ['GeistMono-400', 'GeistMono-500', 'GeistMono-600'],
};

/// Loads the faces Minimal bundles, so the first frame is set in them. Await
/// it before `runApp`: on the web a bundled face otherwise arrives after the
/// first frames, which flash in a fallback face. An app that names its own
/// faces (`MinimalTypeface.app`) loads those itself, the same way, with a
/// `FontLoader`.
///
/// ```dart
/// Future<void> main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///   await minimalLoadFonts();
///   runApp(const MyApp());
/// }
/// ```
Future<void> minimalLoadFonts() => Future.wait([
  for (final MapEntry(key: family, value: files) in _faces.entries)
    _loader(family, files).load(),
]);

FontLoader _loader(String family, List<String> files) {
  final loader = FontLoader(minimalFontFamily(family));
  for (final file in files) {
    loader.addFont(
      rootBundle.load(
        minimalFontPackage == null
            ? 'assets/fonts/$file.ttf'
            : 'packages/$minimalFontPackage/assets/fonts/$file.ttf',
      ),
    );
  }
  return loader;
}
