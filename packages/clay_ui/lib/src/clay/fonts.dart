/// Where Clay's face comes from. The `clay_ui` package bundles Rubik and sets
/// [clayFontPackage] to its own name; a host app that bundles the face itself
/// leaves it null.
library;

import 'dart:ui' show FontVariation, FontWeight;

import 'package:flutter/services.dart';

/// The package that bundles Clay's face, or null when the app does. Every
/// Clay text style passes it as `TextStyle.package`.
// ignore: unnecessary_nullable_for_final_variable_declarations, the package's build names it.
const String? clayFontPackage = 'clay_ui';

/// Clay's typeface: Rubik, a sans with slightly rounded corners, set on its
/// variable weight axis (300 to 900). It speaks Latin, Cyrillic and Hebrew.
const String clayFontFamily = 'Rubik';

/// Rubik's capitals as a fraction of its size (its OS/2 cap height, 700, over
/// its 1000 units per em): what `RawCapCenter` centres a label by.
const double clayCapHeightFactor = 0.70;

/// [family] under the name Flutter registers it by: `Rubik` when the app
/// bundles it, `packages/clay_ui/Rubik` from the package. A test that loads
/// the face itself loads it under this name.
///
/// ```dart
/// final loader = FontLoader(clayRegisteredFamily(clayFontFamily));
/// ```
String clayRegisteredFamily(String family) =>
    clayFontPackage == null ? family : 'packages/$clayFontPackage/$family';

/// The variable-axis setting for [weight]: Rubik is one variable file, so a
/// style sets its `wght` axis as well as its `fontWeight`, and every renderer
/// draws the same weight.
///
/// ```dart
/// TextStyle(fontWeight: FontWeight.w600, fontVariations: clayWeight(FontWeight.w600))
/// ```
List<FontVariation> clayWeight(FontWeight weight) => [
  FontVariation.weight(weight.value.toDouble().clamp(300, 900)),
];

/// Loads the face Clay bundles and the Lucide icon font its parts draw their
/// glyphs from, so the first frame is set in them. Await it before
/// `runApp`: on the web a bundled font otherwise arrives after the first
/// frames, which flash in a fallback face, and a glyph shows as an empty box.
///
/// ```dart
/// Future<void> main() async {WidgetsFlutterBinding.ensureInitialized(); await clayLoadFonts(); runApp(const Placeholder());}
/// ```
Future<void> clayLoadFonts() {
  final face = FontLoader(clayRegisteredFamily(clayFontFamily))
    ..addFont(
      rootBundle.load(
        clayFontPackage == null
            ? 'assets/fonts/Rubik.ttf'
            : 'packages/$clayFontPackage/assets/fonts/Rubik.ttf',
      ),
    );
  // The family `LucideIcons` names, as Flutter registers a package's font.
  final icons = FontLoader('packages/lucide_icons_flutter/Lucide')
    ..addFont(
      rootBundle.load('packages/lucide_icons_flutter/assets/lucide.ttf'),
    );
  return Future.wait([face.load(), icons.load()]);
}
