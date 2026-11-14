/// Material 3 Expressive for Flutter: Material's newest look, ported from
/// Jetpack Compose's material3 1.5.0-alpha29 (its tokens, motion springs,
/// shape library and components). The one import an app needs.
///
/// It exports the theme ([ExpressiveTheme], [ExpressiveThemeData]), one
/// library per foundation (colour, type, shape, motion, spacing, icons,
/// elevation, interaction states) and every component.
///
/// The parts library (`material_expressive_parts.dart`), for a component
/// file copied out of the package to change, also exports what the
/// components are built from, among it the generated token classes. Those
/// keep Compose's names (`ButtonSmallTokens`, `AlertDialogBehavior`, …):
/// they are generated from Compose's source, the docs cite them by those
/// names, and a value checked against Compose is found by the same name
/// there.
library;

export 'package:ui_core/ui_core.dart';

export 'src/material_expressive.dart';
