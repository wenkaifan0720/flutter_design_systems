/// The gallery's page type: the styles kit.dart's page chrome sets a demo
/// page's title and a section's label in. Imported by kit.dart alone and
/// never exported, so no demo names it.
///
/// Over the type scale (`context.expressiveTheme.type`, w1-type): the
/// title is `titleLarge`, a section's label `labelLarge`.
library;

import 'package:flutter/widgets.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';

/// The gallery's page type, read in the demo's [BuildContext].
abstract final class KitText {
  /// A demo page's title: `titleLarge`.
  static TextStyle title(BuildContext context) =>
      context.expressiveTheme.type.titleLarge;

  /// A section's label: `labelLarge`.
  static TextStyle label(BuildContext context) =>
      context.expressiveTheme.type.labelLarge;
}
