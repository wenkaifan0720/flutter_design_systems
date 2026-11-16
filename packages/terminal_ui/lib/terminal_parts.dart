/// Everything `terminal_ui`'s component files use, public: the look, the foundation, and the helpers the look's barrel
/// keeps back (internal/focus_block.dart, internal/list_open.dart, internal/menu_marks.dart, internal/snap.dart, internal/type_ahead.dart).
///
/// Import it in a component you copied out of the package to change, in place of the `src/` imports it had; the
/// rest of your app stays on the package:
///
/// ```dart
/// // lib/ui/my_card.dart, copied from package:terminal_ui/src/terminal/... and renamed.
/// import 'package:flutter/widgets.dart';
/// import 'package:terminal_ui/terminal_parts.dart';
/// ```
///
/// Outside semver: this library may change in any version, a patch included; the CHANGELOG says how to move.
library;

export 'package:ui_core/ui_core.dart';
export 'package:ui_core/alignment.dart';
export 'package:ui_core/inventory.dart';

export 'terminal_ui.dart';
export 'terminal_host.dart';
export 'src/terminal/internal/focus_block.dart';
export 'src/terminal/internal/list_open.dart';
export 'src/terminal/internal/menu_marks.dart';
export 'src/terminal/internal/snap.dart';
export 'src/terminal/internal/type_ahead.dart';
