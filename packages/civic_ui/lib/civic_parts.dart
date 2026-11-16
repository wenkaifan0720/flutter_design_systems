/// Everything `civic_ui`'s component files use, public: the look, the foundation, and the helpers the look's barrel
/// keeps back (internal/announce.dart, internal/field_frame.dart, internal/fit_words.dart, internal/frame_scope.dart, internal/list_option.dart, internal/option.dart, internal/overhang.dart, internal/paint.dart, internal/platform_words.dart, internal/spring.dart, internal/underline.dart).
///
/// Import it in a component you copied out of the package to change, in place of the `src/` imports it had; the
/// rest of your app stays on the package:
///
/// ```dart
/// // lib/ui/my_card.dart, copied from package:civic_ui/src/civic/... and renamed.
/// import 'package:flutter/widgets.dart';
/// import 'package:civic_ui/civic_parts.dart';
/// ```
///
/// Outside semver: this library may change in any version, a patch included; the CHANGELOG says how to move.
library;

export 'package:ui_core/ui_core.dart';
export 'package:ui_core/alignment.dart';
export 'package:ui_core/inventory.dart';

export 'civic_ui.dart';
export 'civic_host.dart';
export 'src/civic/internal/announce.dart';
export 'src/civic/internal/field_frame.dart';
export 'src/civic/internal/fit_words.dart';
export 'src/civic/internal/frame_scope.dart';
export 'src/civic/internal/list_option.dart';
export 'src/civic/internal/option.dart';
export 'src/civic/internal/overhang.dart';
export 'src/civic/internal/paint.dart';
export 'src/civic/internal/platform_words.dart';
export 'src/civic/internal/spring.dart';
export 'src/civic/internal/underline.dart';
