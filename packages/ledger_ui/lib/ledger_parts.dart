/// Everything `ledger_ui`'s component files use, public: the look, the foundation, and the helpers the look's barrel
/// keeps back (components/pressable/pressable.dart, components/structure/structure.dart, internal/bar_slot.dart, internal/button_ends.dart, internal/cap_center.dart, internal/css_shadow.dart, internal/dashed.dart, internal/end_glyph.dart, internal/engraving.dart, internal/even_acts.dart, internal/face.dart, internal/field_frame.dart, internal/footer_band.dart, internal/grabber.dart, internal/hatch.dart, internal/hit_slop.dart, internal/key_focus.dart, internal/leader.dart, internal/narrow.dart, internal/on_cheque.dart, internal/per_line.dart, internal/plot.dart, internal/report_height.dart, internal/side_inset.dart, internal/text_input.dart, internal/themes/frost.g.dart, internal/themes/gallery.g.dart, internal/themes/paper.g.dart, internal/themes/signal.g.dart, internal/whole_pixel.dart, tokens.dart).
///
/// Import it in a component you copied out of the package to change, in place of the `src/` imports it had; the
/// rest of your app stays on the package:
///
/// ```dart
/// // lib/ui/my_card.dart, copied from package:ledger_ui/src/ledger/... and renamed.
/// import 'package:flutter/widgets.dart';
/// import 'package:ledger_ui/ledger_parts.dart';
/// ```
library;

export 'package:ui_core/ui_core.dart';
export 'package:ui_core/alignment.dart';
export 'package:ui_core/inventory.dart';

export 'ledger_ui.dart';
export 'ledger_host.dart';
export 'src/ledger/components/pressable/pressable.dart';
export 'src/ledger/components/structure/structure.dart';
export 'src/ledger/internal/bar_slot.dart';
export 'src/ledger/internal/button_ends.dart';
export 'src/ledger/internal/cap_center.dart';
export 'src/ledger/internal/css_shadow.dart';
export 'src/ledger/internal/dashed.dart';
export 'src/ledger/internal/end_glyph.dart';
export 'src/ledger/internal/engraving.dart';
export 'src/ledger/internal/even_acts.dart';
export 'src/ledger/internal/face.dart';
export 'src/ledger/internal/field_frame.dart';
export 'src/ledger/internal/footer_band.dart';
export 'src/ledger/internal/grabber.dart';
export 'src/ledger/internal/hatch.dart';
export 'src/ledger/internal/hit_slop.dart';
export 'src/ledger/internal/key_focus.dart';
export 'src/ledger/internal/leader.dart';
export 'src/ledger/internal/narrow.dart';
export 'src/ledger/internal/on_cheque.dart';
export 'src/ledger/internal/per_line.dart';
export 'src/ledger/internal/plot.dart';
export 'src/ledger/internal/report_height.dart';
export 'src/ledger/internal/side_inset.dart';
export 'src/ledger/internal/text_input.dart';
export 'src/ledger/internal/themes/frost.g.dart';
export 'src/ledger/internal/themes/gallery.g.dart';
export 'src/ledger/internal/themes/paper.g.dart';
export 'src/ledger/internal/themes/signal.g.dart';
export 'src/ledger/internal/whole_pixel.dart';
export 'src/ledger/tokens.dart';
