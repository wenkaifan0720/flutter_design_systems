/// Everything `retro_desktop_ui`'s component files use, public: the look, the foundation, and the helpers the look's barrel
/// keeps back (component_themes.dart, controls.dart, frames.dart, internal/caps.dart, internal/face.dart, internal/marks.dart, internal/parts.dart, layout.dart, pixels.dart, theme.dart).
///
/// Import it in a component you copied out of the package to change, in place of the `src/` imports it had; the
/// rest of your app stays on the package:
///
/// ```dart
/// // lib/ui/my_card.dart, copied from package:retro_desktop_ui/src/retro_desktop/... and renamed.
/// import 'package:flutter/widgets.dart';
/// import 'package:retro_desktop_ui/retro_desktop_parts.dart';
/// ```
library;

export 'package:ui_core/ui_core.dart';
export 'package:ui_core/alignment.dart';
export 'package:ui_core/inventory.dart';

export 'retro_desktop_ui.dart';
export 'retro_desktop_host.dart';
export 'src/retro_desktop/component_themes.dart';
export 'src/retro_desktop/controls.dart';
export 'src/retro_desktop/frames.dart';
export 'src/retro_desktop/internal/caps.dart';
export 'src/retro_desktop/internal/face.dart';
export 'src/retro_desktop/internal/marks.dart';
export 'src/retro_desktop/internal/parts.dart';
export 'src/retro_desktop/layout.dart';
export 'src/retro_desktop/pixels.dart';
export 'src/retro_desktop/theme.dart';
