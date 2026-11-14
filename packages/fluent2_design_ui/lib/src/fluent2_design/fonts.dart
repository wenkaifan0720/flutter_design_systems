/// Where Fluent 2's faces come from. An app built from this source bundles
/// Selawik and the icon faces itself; the `fluent2_design_ui` package bundles them in the package, and its
/// build sets [fluent2FontPackage] to its own name, which is the one line in
/// which the package differs from this source.
library;

import 'package:flutter/services.dart';

/// The package that bundles Fluent 2's faces, or null when the app does. Every
/// Fluent 2 text style and glyph passes it (`TextStyle.package`,
/// `IconData.fontPackage`).
// ignore: unnecessary_nullable_for_final_variable_declarations, the package's build names it.
const String? fluent2FontPackage = 'fluent2_design_ui';

/// [family] under the name Flutter registers it by: `Selawik` when the app
/// bundles it, `packages/fluent2_design_ui/Selawik` from the package. A test that
/// loads the faces itself loads them under this name.
///
/// ```dart
/// final loader = FontLoader(fluent2FontFamily('Selawik'))..addFont(bytes);
/// await loader.load();
/// ```
String fluent2FontFamily(String family) => fluent2FontPackage == null
    ? family
    : 'packages/$fluent2FontPackage/$family';

/// The faces Fluent 2 bundles, by family, each file's name under
/// `assets/fonts/`.
const Map<String, List<String>> _faces = {
  'Selawik': ['Selawik-Regular', 'Selawik-Semibold', 'Selawik-Bold'],
  'Fluent2Icons': ['Fluent2Icons-Regular'],
  'Fluent2IconsFilled': ['Fluent2Icons-Filled'],
};

/// Loads the faces Fluent 2 bundles, so the first frame is set in them. Await
/// it before `runApp`: on the web a bundled face otherwise arrives after the
/// first frames, which flash in a fallback face and draw the glyphs as empty
/// boxes.
///
/// ```dart
/// Future<void> main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///   await fluent2LoadFonts();
///   runApp(const MyApp());
/// }
/// ```
Future<void> fluent2LoadFonts() => Future.wait([
  for (final MapEntry(key: family, value: files) in _faces.entries)
    _loader(family, files).load(),
]);

FontLoader _loader(String family, List<String> files) {
  final loader = FontLoader(fluent2FontFamily(family));
  for (final file in files) {
    loader.addFont(
      rootBundle.load(
        fluent2FontPackage == null
            ? 'assets/fonts/$file.ttf'
            : 'packages/$fluent2FontPackage/assets/fonts/$file.ttf',
      ),
    );
  }
  return loader;
}
