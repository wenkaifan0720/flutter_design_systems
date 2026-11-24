/// Where Keycap's face comes from. The `keycap_ui` package bundles Rubik and
/// sets [keycapFontPackage] to its own name; a host app that bundles the face
/// itself leaves it null.
library;

import 'package:flutter/services.dart';

/// The package that bundles Keycap's face, or null when the app does. Every
/// Keycap text style passes it as `TextStyle.package`.
// ignore: unnecessary_nullable_for_final_variable_declarations, the package's build names it.
const String? keycapFontPackage = 'keycap_ui';

/// Keycap's one typeface: Rubik, a sans whose slightly rounded corners read
/// like a legend moulded into a cap, and which still sets body copy. Its
/// Latin, Arabic, Hebrew and Cyrillic are bundled in Regular, Medium and
/// SemiBold.
const String keycapFontFamily = 'Rubik';

/// Rubik's capitals as a fraction of its size (its OS/2 cap height, 700, over
/// its 1000 units per em): what `RawCapCenter` centres a legend by.
const double keycapCapHeightFactor = 0.7;

const Map<int, String> _weights = {
  400: 'Rubik-Regular.ttf',
  500: 'Rubik-Medium.ttf',
  600: 'Rubik-SemiBold.ttf',
};

/// [family] under the name Flutter registers it by: `Rubik` when the app
/// bundles it, `packages/keycap_ui/Rubik` from the package. A test that loads
/// the face itself loads it under this name.
///
/// ```dart
/// final loader = FontLoader(keycapRegisteredFamily(keycapFontFamily));
/// ```
String keycapRegisteredFamily(String family) =>
    keycapFontPackage == null ? family : 'packages/$keycapFontPackage/$family';

/// Loads the face Keycap bundles, so the first frame is set in it. Await it
/// before `runApp`: on the web a bundled face otherwise arrives after the
/// first frames, which flash in a fallback face.
///
/// ```dart
/// Future<void> main() async {WidgetsFlutterBinding.ensureInitialized(); await keycapLoadFonts(); runApp(const MyApp());}
/// ```
Future<void> keycapLoadFonts() {
  final loader = FontLoader(keycapRegisteredFamily(keycapFontFamily));
  for (final file in _weights.values) {
    loader.addFont(
      rootBundle.load(
        keycapFontPackage == null
            ? 'assets/fonts/$file'
            : 'packages/$keycapFontPackage/assets/fonts/$file',
      ),
    );
  }
  return loader.load();
}
