/// Everything `fluent2_design_ui`'s component files use, public: the look, the foundation, and the helpers the look's barrel
/// keeps back (colors.dart, component_themes.dart, components/input/field_core.dart, components/list/check_indicator.dart, components/pressable/pressable.dart, internal/arrow.dart, internal/bar_gutter.dart, internal/cap_label.dart, internal/footer_band.dart, internal/hit_slop.dart, internal/icon_fill.dart, internal/in_row.dart, internal/key_focus.dart, internal/layer.dart, internal/measure.dart, internal/menu_surface.dart, internal/presets.g.dart, internal/report_height.dart, internal/side_inset.dart, internal/well.dart, knobs.dart).
///
/// Import it in a component you copied out of the package to change, in place of the `src/` imports it had; the
/// rest of your app stays on the package:
///
/// ```dart
/// // lib/ui/my_card.dart, copied from package:fluent2_design_ui/src/fluent2_design/... and renamed.
/// import 'package:flutter/widgets.dart';
/// import 'package:fluent2_design_ui/fluent2_design_parts.dart';
/// ```
library;

export 'package:ui_core/ui_core.dart';
export 'package:ui_core/alignment.dart';
export 'package:ui_core/inventory.dart';

export 'fluent2_design_ui.dart';
export 'fluent2_design_host.dart';
export 'src/fluent2_design/colors.dart';
export 'src/fluent2_design/component_themes.dart';
export 'src/fluent2_design/components/input/field_core.dart';
export 'src/fluent2_design/components/list/check_indicator.dart';
export 'src/fluent2_design/components/pressable/pressable.dart';
export 'src/fluent2_design/internal/arrow.dart';
export 'src/fluent2_design/internal/bar_gutter.dart';
export 'src/fluent2_design/internal/cap_label.dart';
export 'src/fluent2_design/internal/footer_band.dart';
export 'src/fluent2_design/internal/hit_slop.dart';
export 'src/fluent2_design/internal/icon_fill.dart';
export 'src/fluent2_design/internal/in_row.dart';
export 'src/fluent2_design/internal/key_focus.dart';
export 'src/fluent2_design/internal/layer.dart';
export 'src/fluent2_design/internal/measure.dart';
export 'src/fluent2_design/internal/menu_surface.dart';
export 'src/fluent2_design/internal/presets.g.dart';
export 'src/fluent2_design/internal/report_height.dart';
export 'src/fluent2_design/internal/side_inset.dart';
export 'src/fluent2_design/internal/well.dart';
export 'src/fluent2_design/knobs.dart';
