/// Everything `brutal_ui`'s component files use, public: the look, the foundation, and the helpers the look's barrel
/// keeps back (internal/dialog_foot.dart, internal/inventory.dart, internal/keep_in_view.dart, internal/ruled_column.dart, internal/type_ahead.dart).
///
/// Import it in a component you copied out of the package to change, in place of the `src/` imports it had; the
/// rest of your app stays on the package:
///
/// ```dart
/// // lib/ui/my_card.dart, copied from package:brutal_ui/src/brutal/... and renamed.
/// import 'package:flutter/widgets.dart';
/// import 'package:brutal_ui/brutal_parts.dart';
/// ```
///
/// Outside semver: this library may change in any version, a patch included; the CHANGELOG says how to move.
library;

export 'package:ui_core/ui_core.dart';
export 'package:ui_core/inventory.dart';

export 'brutal_ui.dart';
export 'brutal_host.dart';
export 'src/brutal/internal/dialog_foot.dart';
export 'src/brutal/internal/inventory.dart';
export 'src/brutal/internal/keep_in_view.dart';
export 'src/brutal/internal/ruled_column.dart';
export 'src/brutal/internal/type_ahead.dart';
