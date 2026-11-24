/// Where Brutal's face comes from. The `brutal_ui` package bundles Space
/// Grotesk and sets [brutalFontPackage] to its own name; a host app that
/// bundles the face itself leaves it null.
library;

import 'package:flutter/services.dart';

/// The package that bundles Brutal's face, or null when the app does. Every
/// Brutal text style passes it as `TextStyle.package`.
// ignore: unnecessary_nullable_for_final_variable_declarations, the package's build names it.
const String? brutalFontPackage = 'brutal_ui';

/// Brutal's one typeface: Space Grotesk, a plain grotesk with a variable
/// weight axis (300 to 700).
const String brutalFontFamily = 'SpaceGrotesk';

/// Space Grotesk's capitals as a fraction of its size (its OS/2 cap height,
/// 700, over its 1000 units per em): what `RawCapCenter` centres a label by.
const double brutalCapHeightFactor = 0.7;

/// [family] under the name Flutter registers it by: `SpaceGrotesk` when the
/// app bundles it, `packages/brutal_ui/SpaceGrotesk` from the package. A test
/// that loads the face itself loads it under this name.
///
/// ```dart
/// final loader = FontLoader(brutalRegisteredFamily(brutalFontFamily)) ..addFont(rootBundle.load('assets/fonts/SpaceGrotesk.ttf')); await loader.load();
/// ```
String brutalRegisteredFamily(String family) =>
    brutalFontPackage == null ? family : 'packages/$brutalFontPackage/$family';

/// Loads the face Brutal bundles, so the first frame is set in it. Await it
/// before `runApp`: on the web a bundled face otherwise arrives after the
/// first frames, which flash in a fallback face.
///
/// ```dart
/// Future<void> main() async {WidgetsFlutterBinding.ensureInitialized(); await brutalLoadFonts(); runApp(const MyApp());}
/// ```
Future<void> brutalLoadFonts() {
  final loader = FontLoader(brutalRegisteredFamily(brutalFontFamily))
    ..addFont(
      rootBundle.load(
        brutalFontPackage == null
            ? 'assets/fonts/SpaceGrotesk.ttf'
            : 'packages/$brutalFontPackage/assets/fonts/SpaceGrotesk.ttf',
      ),
    );
  return loader.load();
}
