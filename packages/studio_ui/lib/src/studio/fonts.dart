/// Where Studio's faces come from. The `studio_ui` package bundles them
/// and sets [studioFontPackage] to its own name; a host app that bundles the
/// faces itself leaves it null.
library;

import 'package:flutter/services.dart';

/// The package that bundles Studio's face, or null when the app does. Every
/// Studio text style passes it as `TextStyle.package`.
// ignore: unnecessary_nullable_for_final_variable_declarations, the package's build names it.
const String? studioFontPackage = 'studio_ui';

/// Studio's primary typeface: Barlow, the plain grotesque of instrument legends,
/// in four weights (400 to 700), with tabular figures for readouts.
const String studioFontFamily = 'Barlow';

/// Barlow's capitals as a fraction of its size (its OS/2 cap height, 700,
/// over its 1000 units per em): what `RawCapCenter` centres a label by.
const double studioCapHeightFactor = 0.7;

const List<(String, int)> _faces = [
  ('Barlow-Regular.ttf', 400),
  ('Barlow-Medium.ttf', 500),
  ('Barlow-SemiBold.ttf', 600),
  ('Barlow-Bold.ttf', 700),
];

/// [family] under the name Flutter registers it by: `Barlow` when the app
/// bundles it, `packages/studio_ui/Barlow` from the package. A test that
/// loads the face itself loads it under this name.
///
/// ```dart
/// final loader = FontLoader(studioRegisteredFamily(studioFontFamily));
/// ```
String studioRegisteredFamily(String family) =>
    studioFontPackage == null ? family : 'packages/$studioFontPackage/$family';

/// Loads Barlow and the Arabic chart face for the first frame. Await it
/// before `runApp`: on the web a bundled face otherwise arrives after the
/// first frames, which flash in a fallback face.
///
/// ```dart
/// Future<void> main() async {WidgetsFlutterBinding.ensureInitialized(); await studioLoadFonts(); runApp(const MyApp());}
/// ```
Future<void> studioLoadFonts() async {
  final assets = studioFontPackage == null
      ? 'assets/fonts'
      : 'packages/$studioFontPackage/assets/fonts';
  final loader = FontLoader(studioRegisteredFamily(studioFontFamily));
  for (final (file, _) in _faces) {
    loader.addFont(rootBundle.load('$assets/$file'));
  }
  final arabic = FontLoader(studioRegisteredFamily('NotoSansArabic'))
    ..addFont(rootBundle.load('$assets/NotoSansArabic-400.ttf'));
  await Future.wait([loader.load(), arabic.load()]);
}
