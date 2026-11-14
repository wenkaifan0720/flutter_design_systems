/// Everything `fluent2_ui`'s component files use, public: the look, the foundation, and the helpers the look's barrel
/// keeps back (colors.dart, component_themes.dart, components/input/field_core.dart, components/list/check_indicator.dart, components/pressable/pressable.dart, internal/arrow.dart, internal/bar_gutter.dart, internal/cap_label.dart, internal/footer_band.dart, internal/hit_slop.dart, internal/icon_fill.dart, internal/in_row.dart, internal/key_focus.dart, internal/layer.dart, internal/measure.dart, internal/menu_surface.dart, internal/presets.g.dart, internal/report_height.dart, internal/side_inset.dart, internal/well.dart, knobs.dart).
///
/// Import it in a component you copied out of the package to change, in place of the `src/` imports it had; the
/// rest of your app stays on the package:
///
/// ```dart
/// // lib/ui/my_card.dart, copied from package:fluent2_ui/src/fluent2/... and renamed.
/// import 'package:flutter/widgets.dart';
/// import 'package:fluent2_ui/fluent2_parts.dart';
/// ```
library;

export 'package:ui_core/ui_core.dart';
export 'package:ui_core/alignment.dart';
export 'package:ui_core/inventory.dart';

export 'fluent2_ui.dart';
export 'fluent2_host.dart';
export 'src/fluent2/colors.dart';
export 'src/fluent2/component_themes.dart';
export 'src/fluent2/components/input/field_core.dart';
export 'src/fluent2/components/list/check_indicator.dart';
export 'src/fluent2/components/pressable/pressable.dart';
export 'src/fluent2/internal/arrow.dart';
export 'src/fluent2/internal/bar_gutter.dart';
export 'src/fluent2/internal/cap_label.dart';
export 'src/fluent2/internal/footer_band.dart';
export 'src/fluent2/internal/hit_slop.dart';
export 'src/fluent2/internal/icon_fill.dart';
export 'src/fluent2/internal/in_row.dart';
export 'src/fluent2/internal/key_focus.dart';
export 'src/fluent2/internal/layer.dart';
export 'src/fluent2/internal/measure.dart';
export 'src/fluent2/internal/menu_surface.dart';
export 'src/fluent2/internal/presets.g.dart';
export 'src/fluent2/internal/report_height.dart';
export 'src/fluent2/internal/side_inset.dart';
export 'src/fluent2/internal/well.dart';
export 'src/fluent2/knobs.dart';
