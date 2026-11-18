// The keys of an open list (a select's, a menu's): a row the keyboard moves to
// scrolls into the list's view, and a typed letter goes to the next row it
// starts.
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Keeps each of [nodes]' rows in its list's view as the keyboard reaches it.
void studioKeepInView(List<FocusNode> nodes) {
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

/// Type-ahead over a list's rows: a letter moves the keyboard to the next row
/// whose words start with it.
class StudioTypeAhead extends StatelessWidget {
  /// Type-ahead over [child]'s rows.
  const StudioTypeAhead({
    super.key,
    required this.labels,
    required this.nodes,
    required this.child,
  }) : assert(labels.length == nodes.length);

  /// The rows' words, top to bottom.
  final List<String> labels;

  /// The rows' focus nodes; null for a row the keyboard skips.
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
