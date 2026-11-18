/// Everything `studio_ui`'s component files use, public: the look, the foundation, and the helpers the look's barrel
/// keeps back (internal/brush.dart, internal/curved.dart, internal/inventory.dart, internal/list_keys.dart, internal/strip.dart).
///
/// Import it in a component you copied out of the package to change, in place of the `src/` imports it had; the
/// rest of your app stays on the package:
///
/// ```dart
/// // lib/ui/my_card.dart, copied from package:studio_ui/src/studio/... and renamed.
/// import 'package:flutter/widgets.dart';
/// import 'package:studio_ui/studio_parts.dart';
/// ```
///
/// Outside semver: this library may change in any version, a patch included; the CHANGELOG says how to move.
library;

export 'package:ui_core/ui_core.dart';
export 'package:ui_core/inventory.dart';

export 'studio_ui.dart';
export 'studio_host.dart';
export 'src/studio/internal/brush.dart';
export 'src/studio/internal/curved.dart';
export 'src/studio/internal/inventory.dart';
export 'src/studio/internal/list_keys.dart';
export 'src/studio/internal/strip.dart';
