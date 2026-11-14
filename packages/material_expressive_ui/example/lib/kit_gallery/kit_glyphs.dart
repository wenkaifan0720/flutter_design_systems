/// The demos' stock glyphs, exported by kit.dart, which is all a demo
/// imports: Material Symbols Rounded (`ExpressiveSymbols`, w1-type), the
/// only icons Expressive wears, under the names the wave 0 stand-ins had,
/// so kit.dart and the demos that use them never change. A demo names
/// `ExpressiveSymbols` directly when its family is built.
library;

import 'package:flutter/widgets.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';

/// Stock glyphs for demos that need an icon but not a particular one.
abstract final class KitGlyphs {
  /// A circle (`circle`).
  static const IconData circle = ExpressiveSymbols.circle;

  /// A square (`square`).
  static const IconData square = ExpressiveSymbols.square;

  /// A triangle (`change_history`).
  static const IconData triangle = ExpressiveSymbols.changeHistory;

  /// A plus (`add`).
  static const IconData plus = ExpressiveSymbols.add;
}
