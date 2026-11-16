/// Where Terminal's face comes from. The `terminal_ui` package bundles
/// JetBrains Mono NL (and Liberation Mono, its fallback for Hebrew) and sets
/// [termFontPackage] to its own name; a host app that bundles the faces
/// itself leaves it null.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// The package that bundles Terminal's faces, or null when the app does.
/// Every Terminal text style passes it as `TextStyle.package`.
// ignore: unnecessary_nullable_for_final_variable_declarations, the package's build names it.
const String? termFontPackage = 'terminal_ui';

/// The family every word is set in: JetBrains Mono NL, a monospace whose
/// advance (600/1000 em) is the width of one cell of the grid.
const String termFontFamily = 'JetBrainsMono';

/// The family a script JetBrains Mono lacks falls back to: Liberation Mono,
/// whose Hebrew keeps the same 600/1000 em advance, so a right-to-left word
/// takes the same cells.
const String termFallbackFontFamily = 'LiberationMono';

/// A monospace face and its advance, which travel together: the advance
/// (one character's width, as a fraction of the font size) is the width of
/// a cell of the grid, so a face can only be set with its own.
///
/// [TermFace.jetBrainsMono] is Terminal's (bundled). An app with a brand
/// monospace bundles it and names it here; a proportional face can't be
/// one, since its words would not stand in cells.
///
/// ```dart
/// const plex = TermFace(family: 'IBMPlexMono', advance: 0.6);
/// final theme = TermThemeData.dark(face: plex);
/// ```
@immutable
class TermFace with Diagnosticable {
  /// The monospace [family], each character [advance] em wide.
  const TermFace({
    required this.family,
    required this.advance,
    this.package,
    this.fallback = const [],
  }) : assert(
         advance >= 0.45 && advance <= 0.75,
         'A TermFace is a monospace face: its advance (one character, as a '
         'fraction of the size) is 0.45 to 0.75 em; a cell narrower or wider '
         'is not a terminal cell.',
       );

  /// JetBrains Mono NL, Terminal's own (600/1000 em), with Liberation Mono
  /// for the Hebrew it lacks; the `terminal_ui` package bundles both.
  static const jetBrainsMono = TermFace(
    family: termFontFamily,
    advance: 0.6,
    package: termFontPackage,
    fallback: [termFallbackFontFamily],
  );

  /// The family, as the app registers it.
  final String family;

  /// One character's width, as a fraction of the font size.
  final double advance;

  /// The package that bundles it, or null when the app does.
  final String? package;

  /// Families a character the face lacks falls back to, in order: each
  /// should share its advance.
  final List<String> fallback;

  @override
  bool operator ==(Object other) =>
      other is TermFace &&
      other.family == family &&
      other.advance == advance &&
      other.package == package &&
      listEquals(other.fallback, fallback);

  @override
  int get hashCode =>
      Object.hash(family, advance, package, Object.hashAll(fallback));

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('family', family))
      ..add(DoubleProperty('advance', advance))
      ..add(StringProperty('package', package, defaultValue: null))
      ..add(IterableProperty<String>('fallback', fallback));
  }
}

/// [family] under the name Flutter registers it by: `JetBrainsMono` when the
/// app bundles it, `packages/terminal_ui/JetBrainsMono` from the package. A
/// test that loads the faces itself loads them under this name.
///
/// ```dart
/// final loader = FontLoader(termRegisteredFamily(termFontFamily))
///   ..addFont(bytes);
/// await loader.load();
/// ```
String termRegisteredFamily(String family) =>
    termFontPackage == null ? family : 'packages/$termFontPackage/$family';

/// The faces Terminal bundles, by family, each file's name under
/// `assets/fonts/`.
const Map<String, List<String>> _faces = {
  termFontFamily: ['JetBrainsMonoNL-Regular', 'JetBrainsMonoNL-Bold'],
  termFallbackFontFamily: ['LiberationMono-Regular', 'LiberationMono-Bold'],
};

/// Loads the faces Terminal bundles, so the first frame is set in them.
/// Await it before `runApp`: on the web a bundled face otherwise arrives
/// after the first frames, which flash in a fallback face and off the grid.
///
/// ```dart
/// Future<void> main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///   await termLoadFonts();
///   runApp(const MyApp());
/// }
/// ```
Future<void> termLoadFonts() => Future.wait([
  for (final MapEntry(key: family, value: files) in _faces.entries)
    _loader(family, files).load(),
]);

FontLoader _loader(String family, List<String> files) {
  final loader = FontLoader(termRegisteredFamily(family));
  for (final file in files) {
    loader.addFont(
      rootBundle.load(
        termFontPackage == null
            ? 'assets/fonts/$file.ttf'
            : 'packages/$termFontPackage/assets/fonts/$file.ttf',
      ),
    );
  }
  return loader;
}
