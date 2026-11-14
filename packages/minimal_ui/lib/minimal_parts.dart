/// Everything `minimal_ui`'s component files use, public: the look, the foundation, and the helpers the look's barrel
/// keeps back (internal/bar_actions.dart, internal/cap_label.dart, internal/centred_sheet_route.dart, internal/column_plan.dart, internal/controls.dart, internal/edge_fade.dart, internal/face.dart, internal/field.dart, internal/give_way_row.dart, internal/kit_paint.dart, internal/lucide_cut.g.dart, internal/page_foot.dart, internal/rail_action.dart, internal/sheet_header.dart, internal/styled.dart, internal/text_entry.dart, internal/today_mark.dart, internal/trailing_glyph.dart).
///
/// Import it in a component you copied out of the package to change, in place of the `src/` imports it had; the
/// rest of your app stays on the package:
///
/// ```dart
/// // lib/ui/my_card.dart, copied from package:minimal_ui/src/minimal/... and renamed.
/// import 'package:flutter/widgets.dart';
/// import 'package:minimal_ui/minimal_parts.dart';
/// ```
library;

export 'package:ui_core/ui_core.dart';
export 'package:ui_core/alignment.dart';
export 'package:ui_core/inventory.dart';

export 'minimal_ui.dart';
export 'minimal_host.dart';
export 'src/minimal/internal/bar_actions.dart';
export 'src/minimal/internal/cap_label.dart';
export 'src/minimal/internal/centred_sheet_route.dart';
export 'src/minimal/internal/column_plan.dart';
export 'src/minimal/internal/controls.dart';
export 'src/minimal/internal/edge_fade.dart';
export 'src/minimal/internal/face.dart';
export 'src/minimal/internal/field.dart';
export 'src/minimal/internal/give_way_row.dart';
export 'src/minimal/internal/kit_paint.dart';
export 'src/minimal/internal/lucide_cut.g.dart';
export 'src/minimal/internal/page_foot.dart';
export 'src/minimal/internal/rail_action.dart';
export 'src/minimal/internal/sheet_header.dart';
export 'src/minimal/internal/styled.dart';
export 'src/minimal/internal/text_entry.dart';
export 'src/minimal/internal/today_mark.dart';
export 'src/minimal/internal/trailing_glyph.dart';
