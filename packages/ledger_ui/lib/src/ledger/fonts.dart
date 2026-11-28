/// Where Ledger's faces come from. The `ledger_ui` package bundles Inter
/// Tight, Instrument Serif and IBM Plex Mono and sets [ledgerFontPackage] to
/// its own name; a host app that bundles the faces itself leaves it null.
library;

import 'package:flutter/services.dart';

/// The package that bundles Ledger's faces, or null when the app does. Every
/// Ledger text style passes it as `TextStyle.package`.
// ignore: unnecessary_nullable_for_final_variable_declarations, the package's build names it.
const String? ledgerFontPackage = 'ledger_ui';

/// [family] under the name Flutter registers it by: `PlexMono` when the app
/// bundles it, `packages/ledger_ui/PlexMono` from the package. A test that
/// loads the faces itself loads them under this name.
///
/// ```dart
/// final loader = FontLoader(ledgerFontFamily('PlexMono'))..addFont(bytes);
/// await loader.load();
/// ```
String ledgerFontFamily(String family) =>
    ledgerFontPackage == null ? family : 'packages/$ledgerFontPackage/$family';

/// The faces Ledger bundles, by family, each file's name under
/// `assets/fonts/`.
const Map<String, List<String>> _faces = {
  'InterTight': ['InterTight-Variable'],
  'InstrumentSerif': ['InstrumentSerif-Regular', 'InstrumentSerif-Italic'],
  'PlexMono': ['PlexMono-Regular', 'PlexMono-Medium'],
};

/// Loads the faces Ledger bundles and the Lucide icon font its parts draw
/// their glyphs from, so the first frame is set in them. Await it before
/// `runApp`: on the web a bundled font otherwise arrives after the first
/// frames, which flash in a fallback face, and a glyph shows as an empty box.
///
/// ```dart
/// Future<void> main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///   await ledgerLoadFonts();
///   runApp(const MyApp());
/// }
/// ```
Future<void> ledgerLoadFonts() => Future.wait([
  for (final MapEntry(key: family, value: files) in _faces.entries)
    _loader(family, files).load(),
  // The family `LucideIcons` names, as Flutter registers a package's font.
  (FontLoader('packages/lucide_icons_flutter/Lucide')..addFont(
        rootBundle.load('packages/lucide_icons_flutter/assets/lucide.ttf'),
      ))
      .load(),
]);

FontLoader _loader(String family, List<String> files) {
  final loader = FontLoader(ledgerFontFamily(family));
  for (final file in files) {
    loader.addFont(
      rootBundle.load(
        ledgerFontPackage == null
            ? 'assets/fonts/$file.ttf'
            : 'packages/$ledgerFontPackage/assets/fonts/$file.ttf',
      ),
    );
  }
  return loader;
}
