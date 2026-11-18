/// Everything `appliance_ui`'s component files use, public: the look, the foundation, and the helpers the look's barrel
/// keeps back (internal/bare_field.dart, internal/glyphs.dart, internal/keep_in_view.dart, internal/menu_paint.dart, internal/spring_value.dart, internal/type_ahead.dart).
///
/// Import it in a component you copied out of the package to change, in place of the `src/` imports it had; the
/// rest of your app stays on the package:
///
/// ```dart
/// // lib/ui/my_card.dart, copied from package:appliance_ui/src/appliance/... and renamed.
/// import 'package:flutter/widgets.dart';
/// import 'package:appliance_ui/appliance_parts.dart';
/// ```
///
/// Outside semver: this library may change in any version, a patch included; the CHANGELOG says how to move.
library;

export 'package:ui_core/ui_core.dart';
export 'package:ui_core/inventory.dart';

export 'appliance_ui.dart';
export 'appliance_host.dart';
export 'src/appliance/internal/bare_field.dart';
export 'src/appliance/internal/glyphs.dart';
export 'src/appliance/internal/keep_in_view.dart';
export 'src/appliance/internal/menu_paint.dart';
export 'src/appliance/internal/spring_value.dart';
export 'src/appliance/internal/type_ahead.dart';
