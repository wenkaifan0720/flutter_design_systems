/// A typed letter in an open list (a select's, a menu's): the keyboard goes
/// to the next row whose words start with it, after the row it is on and
/// round to the top, as a native select and menu do on every platform.
library;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Round an open list's rows: [labels] are their words and [nodes] their
/// focus nodes, top to bottom (a null node, a row the keyboard skips: a
/// disabled one).
class BrutalTypeAhead extends StatelessWidget {
  /// Type-ahead over [child]'s rows.
  const BrutalTypeAhead({
    super.key,
    required this.labels,
    required this.nodes,
    required this.child,
  }) : assert(labels.length == nodes.length);

  /// The rows' words, top to bottom.
  final List<String> labels;

  /// The rows' focus nodes, top to bottom; null for a row the keyboard skips.
  final List<FocusNode?> nodes;

  /// The list.
  final Widget child;

  KeyEventResult _key(FocusNode _, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final keys = HardwareKeyboard.instance;
    if (keys.isControlPressed || keys.isMetaPressed || keys.isAltPressed) {
      return KeyEventResult.ignored;
    }
    final char = event.character;
    // Space chooses the row, as Enter does: never a jump.
    if (char == null || char.length != 1 || char.trim().isEmpty) {
      return KeyEventResult.ignored;
    }
    final letter = char.toLowerCase();
    final at = nodes.indexWhere((n) => n?.hasPrimaryFocus ?? false);
    for (var step = 1; step <= labels.length; step++) {
      final i = (at + step) % labels.length;
      final node = nodes[i];
      if (node != null &&
          node.canRequestFocus &&
          labels[i].toLowerCase().startsWith(letter)) {
        // Focused and scrolled into the list's view, as the arrows do.
        FocusTraversalPolicy.defaultTraversalRequestFocusCallback(node);
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) => Focus(
    canRequestFocus: false,
    skipTraversal: true,
    includeSemantics: false,
    onKeyEvent: _key,
    child: child,
  );
}
