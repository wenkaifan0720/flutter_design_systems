/// Where Frosted's faces come from: Bricolage Grotesque and DM Sans. The
/// `frosted_ui` package bundles both and sets [frostedFontPackage] to its own
/// name; a host app that bundles the faces itself leaves it null.
library;

import 'package:flutter/services.dart';

/// The package that bundles Frosted's faces, or null when the app does.
/// Every Frosted text style passes it as `TextStyle.package`.
// ignore: unnecessary_nullable_for_final_variable_declarations, the package's build names it.
const String? frostedFontPackage = 'frosted_ui';

/// [family] under the name Flutter registers it by: `DMSans` when the app
/// bundles it, `packages/frosted_ui/DMSans` from the package. A test that
/// loads the faces itself loads them under this name.
///
/// ```dart
/// final loader = FontLoader(frostedFontFamily('DMSans'))..addFont(bytes);
/// await loader.load();
/// ```
String frostedFontFamily(String family) => frostedFontPackage == null
    ? family
    : 'packages/$frostedFontPackage/$family';

/// The faces Frosted bundles, by family, each file's name under
/// `assets/fonts/`: both are variable faces, one file each.
const Map<String, List<String>> _faces = {
  'BricolageGrotesque': ['BricolageGrotesque-Variable'],
  'DMSans': ['DMSans-Variable'],
};

/// Loads the faces Frosted bundles, so the first frame is set in them. Await
/// it before `runApp`: on the web a bundled face otherwise arrives after the
/// first frames, which flash in a fallback face. An app that names its own
/// faces (`FrostedTypeface.app`) loads those itself, the same way, with a
/// `FontLoader`.
///
/// ```dart
/// Future<void> main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///   await frostedLoadFonts();
///   runApp(const MyApp());
/// }
/// ```
Future<void> frostedLoadFonts() => Future.wait([
  for (final MapEntry(key: family, value: files) in _faces.entries)
    _loader(family, files).load(),
]);

FontLoader _loader(String family, List<String> files) {
  final loader = FontLoader(frostedFontFamily(family));
  for (final file in files) {
    loader.addFont(
      rootBundle.load(
        frostedFontPackage == null
            ? 'assets/fonts/$file.ttf'
            : 'packages/$frostedFontPackage/assets/fonts/$file.ttf',
      ),
    );
  }
  return loader;
}
