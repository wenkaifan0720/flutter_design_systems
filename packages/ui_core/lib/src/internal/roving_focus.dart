/// One tab stop over a row of items, the arrows moving along it (the
/// WAI-ARIA "roving tabindex"): a tab bar's tabs, a shell's destinations.
/// Inside ui_core; not exported.
library;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// The focus nodes of a row of items, one of them the tab stop.
class RovingFocus {
  /// Nodes named [debugLabel] and their place.
  RovingFocus(this.debugLabel);

  /// What each node is called in a focus tree's dump.
  final String debugLabel;

  final List<FocusNode> _nodes = [];

  /// The node of item [index].
  FocusNode operator [](int index) => _nodes[index];

  /// Keeps one node per item, [count] of them.
  void sync(int count) {
    while (_nodes.length < count) {
      _nodes.add(FocusNode(debugLabel: '$debugLabel ${_nodes.length}'));
    }
    while (_nodes.length > count) {
      _nodes.removeLast().dispose();
    }
  }

  /// Makes item [stop] the only one Tab lands on; null: none.
  void stopAt(int? stop) {
    for (var i = 0; i < _nodes.length; i++) {
      _nodes[i].skipTraversal = i != stop;
    }
  }

  /// The item [event] moves to from item [from] of [count]: along [axis]
  /// with its arrows (mirrored right to left), wrapping at the ends; Home
  /// and End to the first and the last. Items not [enabled] are skipped.
  /// Null when [event] is none of those keys.
  static int? target(
    KeyEvent event, {
    required int from,
    required int count,
    required Axis axis,
    required TextDirection textDirection,
    required bool Function(int index) enabled,
  }) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return null;
    final rtl = textDirection == TextDirection.rtl;
    final horizontal = axis == Axis.horizontal;
    final forward = horizontal
        ? (rtl ? LogicalKeyboardKey.arrowLeft : LogicalKeyboardKey.arrowRight)
        : LogicalKeyboardKey.arrowDown;
    final back = horizontal
        ? (rtl ? LogicalKeyboardKey.arrowRight : LogicalKeyboardKey.arrowLeft)
        : LogicalKeyboardKey.arrowUp;
    // The first enabled item [step] at a time from [start], wrapping.
    int step(int start, int step) {
      for (var k = 1; k <= count; k++) {
        final i = (start + step * k) % count;
        if (enabled(i)) return i;
      }
      return from;
    }

    final key = event.logicalKey;
    if (key == forward) return step(from, 1);
    if (key == back) return step(from, -1);
    if (key == LogicalKeyboardKey.home) return step(-1, 1);
    if (key == LogicalKeyboardKey.end) return step(0, -1);
    return null;
  }

  /// Disposes the nodes.
  void dispose() {
    for (final node in _nodes) {
      node.dispose();
    }
    _nodes.clear();
  }
}
