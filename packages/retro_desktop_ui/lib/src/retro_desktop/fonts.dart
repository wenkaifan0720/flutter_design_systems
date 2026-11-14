/// Where Retro Desktop's faces come from. The `retro_desktop_ui` package bundles Jersey and Atkinson and names them
/// by its own package ([retroDesktopFontPackage]), so an app needs no font setup of its own.
library;

import 'package:flutter/services.dart';

/// The package that bundles Retro Desktop's faces, or null when the app does. The typeface resolves bundled families to Flutter's package-qualified font names; app fonts remain unqualified.
// ignore: unnecessary_nullable_for_final_variable_declarations, the package's build names it.
const String? retroDesktopFontPackage = 'retro_desktop_ui';

/// [family] under the name Flutter registers it by: `AtkinsonNext` when the app bundles it, `packages/retro_desktop_ui/AtkinsonNext` from the
/// package. A test that loads the faces itself loads them under this name.
///
/// ```dart
/// final loader = FontLoader(retroDesktopFontFamily('AtkinsonNext'))..addFont(bytes);
/// await loader.load();
/// ```
String retroDesktopFontFamily(String family) =>
    retroDesktopFontPackage == null || !_faces.containsKey(family)
    ? family
    : 'packages/$retroDesktopFontPackage/$family';

/// The faces Retro Desktop bundles, by family, each file's name under `assets/fonts/`.
const Map<String, List<String>> _faces = {
  'Jersey15': ['Jersey15-OneFace'],
  'AtkinsonNext': [
    'AtkinsonNext-400',
    'AtkinsonNext-400Italic',
    'AtkinsonNext-600',
    'AtkinsonNext-700',
  ],
  'AtkinsonMono': ['AtkinsonMono-400', 'AtkinsonMono-600', 'AtkinsonMono-700'],
};

/// Loads the faces Retro Desktop bundles, and its icon face, so the first frame is set in them. Await it before `runApp`:
/// on the web a bundled face otherwise arrives after the first frames, which flash in a fallback face. Each file is
/// fetched up to three times and a face that still fails is skipped, never thrown: the engine itself never retries a
/// face, so one dropped request on a slow or busy server would otherwise leave every icon an empty box until the page
/// reloads. An app that names its own faces (`RetroDesktopTypeface`) loads those itself, the same way, with a
/// `FontLoader`.
///
/// ```dart
/// void main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///   await retroDesktopLoadFonts();
///   runApp(const MyApp());
/// }
/// ```
Future<void> retroDesktopLoadFonts() async {
  await Future.wait([
    for (final MapEntry(key: family, value: files) in _faces.entries)
      _load(retroDesktopFontFamily(family), [
        for (final file in files)
          retroDesktopFontPackage == null
              ? 'assets/fonts/$file.ttf'
              : 'packages/$retroDesktopFontPackage/assets/fonts/$file.ttf',
      ]),
    _load(_iconFamily, const [_iconAsset]),
  ]);
}

/// The glyphs' face, as Flutter registers it from its package.
const String _iconFamily = 'packages/lucide_icons_flutter/Lucide';
const String _iconAsset = 'packages/lucide_icons_flutter/assets/lucide.ttf';

Future<void> _load(String family, List<String> assets) async {
  final loader = FontLoader(family);
  for (final asset in assets) {
    loader.addFont(_fetch(asset));
  }
  try {
    await loader.load();
  } on Object {
    // A face that can't be fetched keeps the engine's own attempt.
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
