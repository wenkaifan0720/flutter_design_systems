// One current row in a design-kit menu (a menu bar's, a split button's), as in Comic's own menus. ui_core lights it
// (highlightFollowsPointer, on by default): the row the pointer moved over last or the one the keys moved to, and none
// in a menu the pointer opened until one of them moves. Comic draws that row in its one lit face, whichever lit it.
import 'package:flutter/widgets.dart';

/// A design-kit menu row's face, built by [face] for the states it shows: the current row (hovered or focused, which
/// ui_core gives one row of a menu at most) as focused, Comic's one lit face, and nothing else of the pointer's or the
/// keys'.
Widget comicMenuRow(
  Set<WidgetState> states,
  Widget Function(Set<WidgetState> states) face,
) {
  final current =
      !states.contains(WidgetState.disabled) &&
      (states.contains(WidgetState.focused) ||
          states.contains(WidgetState.hovered));
  return face({
    ...states.difference(const {WidgetState.hovered, WidgetState.focused}),
    if (current) WidgetState.focused,
  });
}
