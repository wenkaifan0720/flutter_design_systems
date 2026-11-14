import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import 'pixel_snap.dart';

/// DM Sans' capitals over its em (its OS/2 `sCapHeight` over `unitsPerEm`):
/// the face every control's label is set in.
const double frostedSansCap = .700;

/// Bricolage Grotesque's: the display face of the titles.
const double frostedDisplayCap = .660;

/// [label], one line of words on a face, drawn with its capitals on its
/// box's middle (ui_core's DesignCapCenter), by the cap height of the face
/// its style names. A line box centred on a face leaves the capitals up to
/// three device pixels off its middle; the box still centres as before.
/// An app's own face (`FrostedTypeface.app`) takes DM Sans' measure.
/// Plumbing of the components: an icon is never wrapped, nor page code.
Widget frostedCapCentred(Text label) => DesignCapCenter(
  capHeightFactor: (label.style?.fontFamily ?? '').contains('Bricolage')
      ? frostedDisplayCap
      : frostedSansCap,
  child: label,
);

/// [label] cap-centred as [frostedCapCentred], its words painted on the
/// device-pixel grid ([FrostedPixelSnap]): the 12 px words of a filter chip
/// or a segment, so their stems keep pixels of full ink where a screen does
/// not darken stems.
Widget frostedCapCentredSnapped(Text label) => DesignCapCenter(
  capHeightFactor: (label.style?.fontFamily ?? '').contains('Bricolage')
      ? frostedDisplayCap
      : frostedSansCap,
  child: FrostedPixelSnap(child: label),
);

/// [field], a one-line `TextField` with its decoration collapsed, its typed
/// text and its hint drawn with their capitals on its box's middle, by the
/// cap height of the face [style] names; the caret, the selection and taps
/// move with them. A field beside a button then holds their capitals on one
/// line. A field of more than one line is returned as it is.
Widget frostedCapCentredEntry(
  TextStyle style,
  Widget field, {
  bool one = true,
}) => one
    ? DesignCapCenter(
        capHeightFactor: (style.fontFamily ?? '').contains('Bricolage')
            ? frostedDisplayCap
            : frostedSansCap,
        child: field,
      )
    : field;

/// [height] grown by the line its words in [style] gain as the reader's text
/// grows: the same at 1x, and at 200% a pill, a plate or a keycap is as much
/// taller as its line is, so the words never fill it to the rim or lose their
/// foot. Plumbing of the components.
double frostedGrownHeight(
  BuildContext context,
  double height,
  TextStyle style,
) {
  final size = style.fontSize ?? 14;
  final scaled = MediaQuery.textScalerOf(context).scale(size);
  if (scaled <= size) return height;
  return height + (scaled - size) * (style.height ?? 1.25);
}
