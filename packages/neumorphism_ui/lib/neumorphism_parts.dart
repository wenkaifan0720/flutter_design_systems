/// Everything `neumorphism_ui`'s component files use, public: the look, the foundation, and the helpers the look's barrel
/// keeps back (chart.dart, controls.dart, frames.dart, internal/beside.dart, internal/cap_label.dart, internal/cell_bank.dart, internal/day_face.dart, internal/error_line.dart, internal/geometry.dart, internal/group_rows.dart, internal/out_of_use.dart, internal/panel.dart, internal/reach.dart, internal/text_entry.dart, internal/veil.dart, layout.dart, ornaments.dart, theme.dart).
///
/// Import it in a component you copied out of the package to change, in place of the `src/` imports it had; the
/// rest of your app stays on the package:
///
/// ```dart
/// // lib/ui/my_card.dart, copied from package:neumorphism_ui/src/neumorphism/... and renamed.
/// import 'package:flutter/widgets.dart';
/// import 'package:neumorphism_ui/neumorphism_parts.dart';
/// ```
library;

export 'package:ui_core/ui_core.dart';
export 'package:ui_core/alignment.dart';
export 'package:ui_core/inventory.dart';

export 'neumorphism_ui.dart';
export 'neumorphism_host.dart';
export 'src/neumorphism/chart.dart';
export 'src/neumorphism/controls.dart';
export 'src/neumorphism/frames.dart';
export 'src/neumorphism/internal/beside.dart';
export 'src/neumorphism/internal/cap_label.dart';
export 'src/neumorphism/internal/cell_bank.dart';
export 'src/neumorphism/internal/day_face.dart';
export 'src/neumorphism/internal/error_line.dart';
export 'src/neumorphism/internal/geometry.dart';
export 'src/neumorphism/internal/group_rows.dart';
export 'src/neumorphism/internal/out_of_use.dart';
export 'src/neumorphism/internal/panel.dart';
export 'src/neumorphism/internal/reach.dart';
export 'src/neumorphism/internal/text_entry.dart';
export 'src/neumorphism/internal/veil.dart';
export 'src/neumorphism/layout.dart';
export 'src/neumorphism/ornaments.dart';
export 'src/neumorphism/theme.dart';
