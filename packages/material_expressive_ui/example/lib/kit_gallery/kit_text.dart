/// Title and section label styles from the current Expressive type scale.
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
