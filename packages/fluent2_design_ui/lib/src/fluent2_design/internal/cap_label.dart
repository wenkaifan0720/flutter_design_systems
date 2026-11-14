/// A face's one-line label, drawn with its capitals on the face's middle.
library;

import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

/// Selawik's cap height over its em, the same in every weight: 1434 of its
/// 2048 units (its OS/2 `sCapHeight` and head `unitsPerEm`).
const double fluent2CapHeight = 1434 / 2048;

/// Whether [fluent2CapCentred] centres by the capitals. A test turns it off
/// to read the faces as they stood without it (the label sweep's counts
/// before and after).
@visibleForTesting
bool debugFluent2CapCentring = true;

/// [label], a face's one-line words, drawn so the middle of its capitals is
/// the middle of its box: whatever centres the box (a button's face, a tab,
/// a menu row) then centres the capitals, not the line's ascent and
/// descent. Wrap the words alone, never an icon. Plumbing of the
/// components; pages never write it.
Widget fluent2CapCentred(Widget label) => debugFluent2CapCentring
    ? DesignCapCenter(capHeightFactor: fluent2CapHeight, child: label)
    : label;

/// [control] beside words in [style], dropped by half what their first line
/// grows under the reader's text size, so it stays on that line's middle (0
/// at the default size, where the row's own padding centres it). Plumbing
/// of the components; pages never write it.
Widget fluent2OnFirstLine(
  BuildContext context,
  TextStyle style,
  Widget control,
) {
  final size = style.fontSize ?? 14;
  final grown =
      (MediaQuery.textScalerOf(context).scale(size) - size) *
      (style.height ?? 1);
  if (grown <= 0) return control;
  return Padding(
    padding: EdgeInsets.only(top: grown / 2),
    child: control,
  );
}
