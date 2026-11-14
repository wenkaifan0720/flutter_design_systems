/// Where Expressive's faces come from: Roboto Flex, the optional Jost family,
/// and the Material Symbols Rounded subset. The host app bundles them itself; the `material_expressive_ui`
/// package bundles them in the package, and its build sets
/// [expressiveFontPackage] to its own name, which is the one line in which
/// the package differs from this source.
library;

import 'package:flutter/services.dart';

/// The package that bundles Expressive's faces, or null when the app does.
/// Every Expressive text style passes it as `TextStyle.package`, and every
/// [ExpressiveSymbols] glyph as `IconData.fontPackage`.
// ignore: unnecessary_nullable_for_final_variable_declarations, the package's build names it.
const String? expressiveFontPackage = 'material_expressive_ui';

/// [family] under the name Flutter registers it by: `RobotoFlex` when the
/// app bundles it, `packages/material_expressive_ui/RobotoFlex` from the package. A
/// test that loads the faces itself loads them under this name.
///
/// ```dart
/// final loader = FontLoader(expressiveFontFamily('RobotoFlex'))..addFont(bytes);
/// await loader.load();
/// ```
String expressiveFontFamily(String family) => expressiveFontPackage == null
    ? family
    : 'packages/$expressiveFontPackage/$family';

/// Loads the bundled text and symbol faces before the first frame.
///
/// ```dart
/// await expressiveLoadFonts();
/// runApp(const MyApp());
/// ```
Future<void> expressiveLoadFonts() => Future.wait([
  for (final (family, files) in const [
    ('RobotoFlex', ['RobotoFlex.ttf']),
    ('Jost', ['Jost-400.ttf', 'Jost-500.ttf', 'Jost-600.ttf']),
    ('MaterialSymbolsRounded', ['MaterialSymbolsRounded.ttf']),
  ])
    () {
      final loader = FontLoader(expressiveFontFamily(family));
      for (final file in files) {
        loader.addFont(
          rootBundle.load(
            expressiveFontPackage == null
                ? 'assets/fonts/$file'
                : 'packages/$expressiveFontPackage/assets/fonts/$file',
          ),
        );
      }
      return loader.load();
    }(),
]);
