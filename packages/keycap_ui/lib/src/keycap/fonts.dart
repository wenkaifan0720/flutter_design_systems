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

/// Loads the face Keycap bundles and Lucide's glyphs, which its parts draw
/// with (a select's chevron, a field's clear key, a toast's mark), so the
/// first frame is set in them. Await it before `runApp`: on the web a font
/// otherwise arrives after the first frames, which flash in a fallback face
/// and draw every icon as an empty box. Each file is fetched up to three
/// times, and one that still fails is skipped, never thrown: the engine then
/// loads it as it would have.
///
/// ```dart
/// Future<void> main() async {WidgetsFlutterBinding.ensureInitialized(); await keycapLoadFonts(); runApp(const MyApp());}
/// ```
Future<void> keycapLoadFonts() async {
  await Future.wait([
    _load(keycapRegisteredFamily(keycapFontFamily), [
      for (final file in _weights.values)
        keycapFontPackage == null
            ? 'assets/fonts/$file'
            : 'packages/$keycapFontPackage/assets/fonts/$file',
    ]),
    _load(_iconFamily, const [_iconAsset]),
  ]);
}

// Lucide's glyphs, as Flutter registers them from their package.
const String _iconFamily = 'packages/lucide_icons_flutter/Lucide';
const String _iconAsset = 'packages/lucide_icons_flutter/assets/lucide.ttf';

Future<void> _load(String family, List<String> assets) async {
  try {
    final loader = FontLoader(family);
    for (final asset in assets) {
      loader.addFont(_fetch(asset));
    }
    await loader.load();
  } on Object {
    // A font that can't be fetched keeps the engine's own attempt.
  }
}

Future<ByteData> _fetch(String asset) async {
  for (var attempt = 1; ; attempt++) {
    try {
      return await rootBundle.load(asset);
    } on Object {
      if (attempt == 3) rethrow;
      await Future<void>.delayed(Duration(milliseconds: 250 * attempt));
    }
  }
}
