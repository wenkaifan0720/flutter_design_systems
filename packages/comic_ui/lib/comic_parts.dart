/// Everything `comic_ui`'s component files use, public: the look, the foundation, and the helpers the look's barrel
/// keeps back (balloons.dart, component_themes.dart, frames.dart, internal/cap_label.dart, internal/field_icon.dart, internal/geometry.dart, internal/lettering.dart, internal/reach.dart, internal/row_frame.dart, internal/track.dart, inventory/action_rows.dart, inventory/inputs.dart, layout.dart, press.dart, print.dart, raised.dart, styled.dart, theme.dart).
///
/// Import it in a component you copied out of the package to change, in place of the `src/` imports it had; the
/// rest of your app stays on the package:
///
/// ```dart
/// // lib/ui/my_card.dart, copied from package:comic_ui/src/comic/... and renamed.
/// import 'package:flutter/widgets.dart';
/// import 'package:comic_ui/comic_parts.dart';
/// ```
library;

export 'package:ui_core/ui_core.dart';
export 'package:ui_core/alignment.dart';
export 'package:ui_core/inventory.dart';

export 'comic_ui.dart';
export 'comic_host.dart';
export 'src/comic/balloons.dart';
export 'src/comic/component_themes.dart';
export 'src/comic/frames.dart';
export 'src/comic/internal/cap_label.dart';
export 'src/comic/internal/field_icon.dart';
export 'src/comic/internal/geometry.dart';
export 'src/comic/internal/lettering.dart';
export 'src/comic/internal/reach.dart';
export 'src/comic/internal/row_frame.dart';
export 'src/comic/internal/track.dart';
export 'src/comic/inventory/action_rows.dart';
export 'src/comic/inventory/inputs.dart';
export 'src/comic/layout.dart';
export 'src/comic/press.dart';
export 'src/comic/print.dart';
export 'src/comic/raised.dart';
export 'src/comic/styled.dart';
export 'src/comic/theme.dart';
