/// An open list's row stays in view while the keyboard is on it: every key
/// that moves the keyboard (an arrow round past an end, Home, End, a typed
/// letter) scrolls the list just far enough to show the row, as a native
/// list does. A long select or menu needs it: round past an end, and Home or
/// End, the keyboard lands on a row the list has scrolled away from.
library;

import 'package:flutter/widgets.dart';

/// Keeps each of [nodes]' rows in view whenever it takes the keyboard.
void applianceKeepInView(List<FocusNode> nodes) {
  for (final node in nodes) {
    node.addListener(() => _show(node));
  }
}

void _show(FocusNode node) {
  final context = node.context;
  if (!node.hasPrimaryFocus || context == null || !context.mounted) return;
  // Just far enough: down to a row below the view, up to one above it.
  Scrollable.ensureVisible(
    context,
    alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
  );
  Scrollable.ensureVisible(
    context,
    alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtStart,
  );
}
