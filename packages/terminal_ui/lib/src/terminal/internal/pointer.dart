/// The pointer's mark on a control: an ink change, lighter than the
/// keyboard's cursor.
library;

import 'package:flutter/widgets.dart';

import '../theme.dart';

/// Whether [states] say a pointer is over an enabled control.
bool termHovered(Set<WidgetState> states) =>
    states.contains(WidgetState.hovered) &&
    !states.contains(WidgetState.disabled);

/// [rest], or [to] (the accent when null) while a pointer is over an
/// enabled control: the ink a control's edge takes under the pointer (its
/// brackets, a slider's block, a tab's words).
///
/// Only the ink changes, never the cells' ground. The keyboard's cursor is
/// a block of the accent over the cells, so the pointer's mark stays the
/// lighter of the two and the two never read as one, as Material's hover
/// overlay is fainter than its focus.
Color termHoverInk(
  TermThemeData theme,
  Color rest,
  Set<WidgetState> states, {
  Color? to,
}) => termHovered(states) ? to ?? theme.accent : rest;
