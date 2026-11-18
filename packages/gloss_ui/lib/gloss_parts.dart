/// Everything `gloss_ui`'s component files use, public: the look, the foundation, and the helpers the look's barrel
/// keeps back (internal/chevron.dart, internal/entry_parts.dart, internal/inventory.dart, internal/key_paint.dart, internal/menu_parts.dart, internal/platform_words.dart).
///
/// Import it in a component you copied out of the package to change, in place of the `src/` imports it had; the
/// rest of your app stays on the package:
///
/// ```dart
/// // lib/ui/my_card.dart, copied from package:gloss_ui/src/gloss/... and renamed.
/// import 'package:flutter/widgets.dart';
/// import 'package:gloss_ui/gloss_parts.dart';
/// ```
///
/// Outside semver: this library may change in any version, a patch included; the CHANGELOG says how to move.
library;

export 'package:ui_core/ui_core.dart';
export 'package:ui_core/inventory.dart';

export 'gloss_ui.dart';
export 'gloss_host.dart';
export 'src/gloss/internal/chevron.dart';
export 'src/gloss/internal/entry_parts.dart';
export 'src/gloss/internal/inventory.dart';
export 'src/gloss/internal/key_paint.dart';
export 'src/gloss/internal/menu_parts.dart';
export 'src/gloss/internal/platform_words.dart';
