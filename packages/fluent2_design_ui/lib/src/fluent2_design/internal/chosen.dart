/// How a chosen option stands out in an open list (a select's, a
/// combobox's, a tag picker's, a menu with a choice): Fluent 2's selected
/// list item, as its mail and chat lists draw the item in hand. Under the
/// row the subtle brand fill (`brandBackground2`, its hover and pressed
/// steps), at its leading edge the selection indicator (a 3 × 16 pill of
/// `compoundBrandStroke`, the tab's and the nav item's), and the check in
/// the brand. The pointer over another row only steps the neutral fill and
/// the keyboard's focus is a ring round the whole row: neither wears the
/// brand fill or the pill, so neither reads as a second choice.
library;

import 'package:flutter/widgets.dart';

import '../colors.dart';
import '../components/pressable/pressable.dart';

/// The fill under a list row in [press]: the brand's subtle fill while it is
/// [chosen], else the neutral fill under the pointer and the press
/// ([resting] at rest).
Color fluent2RowFill(
  Fluent2Colors c,
  Fluent2Press press, {
  required bool chosen,
  required Color resting,
}) => chosen && press != Fluent2Press.disabled
    ? press.pick(
        c.brandBackground2,
        c.brandBackground2Hover,
        c.brandBackground2Pressed,
        c.brandBackground2,
      )
    : press.pick(
        resting,
        c.neutralBackground1Hover,
        c.neutralBackground1Pressed,
        resting,
      );

/// The ink of a chosen row's check in [press]: the brand's, out of use the
/// disabled ink.
Color fluent2ChosenInk(Fluent2Colors c, Fluent2Press press) =>
    press == Fluent2Press.disabled
    ? c.neutralForegroundDisabled
    : c.compoundBrandForeground1;

/// [row] with the selection indicator at its leading edge while [chosen].
Widget fluent2ChosenRow({
  required Widget row,
  required bool chosen,
  required Fluent2Colors colors,
  required Fluent2Press press,
}) {
  if (!chosen) return row;
  return Stack(
    children: [
      row,
      PositionedDirectional(
        start: 0,
        top: 0,
        bottom: 0,
        child: Center(
          child: Container(
            width: 3,
            height: 16,
            decoration: BoxDecoration(
              color: press == Fluent2Press.disabled
                  ? colors.neutralForegroundDisabled
                  : colors.compoundBrandStroke,
              borderRadius: BorderRadius.circular(1.5),
            ),
          ),
        ),
      ),
    ],
  );
}
