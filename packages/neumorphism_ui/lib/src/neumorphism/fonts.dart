/// Where Neumorphism's faces come from: Manrope, bundled in the package that [neumorphicFontPackage] names, or by the host
/// app when it names none.
library;

import 'package:flutter/services.dart';

/// The package that bundles Neumorphism's faces, or null when the app does. Every Neumorphism text style passes it as
/// `TextStyle.package`.
// ignore: unnecessary_nullable_for_final_variable_declarations, the package's build names it.
const String? neumorphicFontPackage = 'neumorphism_ui';

/// [family] under the name Flutter registers it by: `Manrope` when the app bundles it, `packages/neumorphism_ui/Manrope` from the
/// package. A test that loads the faces itself loads them under this name.
///
/// ```dart
/// final loader = FontLoader(neumorphicFontFamily('Manrope'))..addFont(bytes);
/// await loader.load();
/// ```
String neumorphicFontFamily(String family) => neumorphicFontPackage == null
    ? family
    : 'packages/$neumorphicFontPackage/$family';

/// The faces Neumorphism bundles, by family, each file's name under `assets/fonts/`.
const Map<String, List<String>> _faces = {
  'Manrope': [
    'Manrope-250',
    'Manrope-300',
    'Manrope-400',
    'Manrope-500',
    'Manrope-600',
    'Manrope-700',
    'Manrope-800',
  ],
};

/// Loads the faces Neumorphism bundles, so the first frame is set in them. Await it before `runApp`: on the web a bundled
/// face otherwise arrives after the first frames, which flash in a fallback face. An app that names its own faces
/// (`NeumorphicTypeface.app`) loads those itself, the same way, with a `FontLoader`.
///
/// ```dart
/// WidgetsFlutterBinding.ensureInitialized();
/// await neumorphicLoadFonts();
/// runApp(const MyApp());
/// ```
Future<void> neumorphicLoadFonts() => Future.wait([
  for (final MapEntry(key: family, value: files) in _faces.entries)
    _loader(family, files).load(),
]);

FontLoader _loader(String family, List<String> files) {
  final loader = FontLoader(neumorphicFontFamily(family));
  for (final file in files) {
    loader.addFont(
      rootBundle.load(
        neumorphicFontPackage == null
            ? 'assets/fonts/$file.ttf'
            : 'packages/$neumorphicFontPackage/assets/fonts/$file.ttf',
      ),
    );
  }
  return loader;
}
