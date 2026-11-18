/// Where Gloss's face comes from. The `gloss_ui` package bundles Plus Jakarta
/// Sans and sets [glossFontPackage] to its own name; a host app that bundles
/// the face itself leaves it null.
library;

import 'package:flutter/services.dart';

/// The package that bundles Gloss's face, or null when the app does. Every
/// Gloss text style passes it as `TextStyle.package`.
// ignore: unnecessary_nullable_for_final_variable_declarations, the package's build names it.
const String? glossFontPackage = 'gloss_ui';

/// Gloss's one typeface: Plus Jakarta Sans, a friendly modern grotesk with a
/// variable weight axis (200 to 800).
const String glossFontFamily = 'PlusJakartaSans';

/// Plus Jakarta Sans's capitals as a fraction of its size (its OS/2 cap
/// height, 745, over its 1000 units per em): what `DesignCapCenter` centres a
/// label by.
const double glossCapHeightFactor = 0.745;

/// [family] under the name Flutter registers it by: `PlusJakartaSans` when
/// the app bundles it, `packages/gloss_ui/PlusJakartaSans` from the package.
/// A test that loads the face itself loads it under this name.
///
/// ```dart
/// final loader = FontLoader(glossRegisteredFamily(glossFontFamily)) ..addFont(rootBundle.load('assets/fonts/PlusJakartaSans.ttf')); await loader.load();
/// ```
String glossRegisteredFamily(String family) =>
    glossFontPackage == null ? family : 'packages/$glossFontPackage/$family';

/// Loads the face Gloss bundles, so the first frame is set in it. Await it
/// before `runApp`: on the web a bundled face otherwise arrives after the
/// first frames, which flash in a fallback face.
///
/// ```dart
/// Future<void> main() async {WidgetsFlutterBinding.ensureInitialized(); await glossLoadFonts(); runApp(const Placeholder());}
/// ```
Future<void> glossLoadFonts() {
  final loader = FontLoader(glossRegisteredFamily(glossFontFamily))
    ..addFont(
      rootBundle.load(
        glossFontPackage == null
            ? 'assets/fonts/PlusJakartaSans.ttf'
            : 'packages/$glossFontPackage/assets/fonts/PlusJakartaSans.ttf',
      ),
    );
  return loader.load();
}
