/// A toggle group, headless: one choice of several (a segmented control) or
/// any number (a toolbar's bold, italic, underline), one tab stop for the
/// group, arrows between its items.
library;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'pressable.dart';

/// Builds an item's face for its [states] (selected, focused while the
/// keyboard is on it, hovered, pressed, disabled).
typedef DesignToggleItemBuilder<T> = Widget Function(
  BuildContext context,
  T value,
  Set<WidgetState> states,
);

/// A row (or column) of toggles over [options].
///
/// With [multiSelectionEnabled] false it is one choice: a screen reader
/// hears a radio group, and a press on the chosen item keeps it unless
/// [emptySelectionAllowed]. With [multiSelectionEnabled] true each item
/// toggles on its own.
///
/// Tab reaches the group once, at its chosen item (or its first enabled
/// one); the arrows move along it (and wrap), mirrored right to left; Home
/// and End go to its ends; Space and Enter press. [selectFollowsFocus]
/// chooses as the arrows move, as a segmented control does.
///
/// ```dart
/// DesignToggleGroup<String>(options: const ['day', 'week'], selected: const {'day'}, onSelectionChanged: (next) {}, itemBuilder: (context, value, states) => Text(value))
/// ```
class DesignToggleGroup<T> extends StatefulWidget {
  /// A group of [options], [selected] chosen.
  const DesignToggleGroup({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelectionChanged,
    required this.itemBuilder,
    this.multiSelectionEnabled = false,
    this.emptySelectionAllowed = false,
    this.selectFollowsFocus = false,
    this.isEnabled,
    this.labelOf,
    this.semanticLabel,
    this.direction = Axis.horizontal,
    this.layoutBuilder,
    this.minimumSize = const Size(44, 44),
  });

  /// The items, in order.
  final List<T> options;

  /// The chosen ones.
  final Set<T> selected;

  /// A press's new choice; null disables the group.
  final ValueChanged<Set<T>>? onSelectionChanged;

  /// Paints an item.
  final DesignToggleItemBuilder<T> itemBuilder;

  /// Whether any number may be chosen.
  final bool multiSelectionEnabled;

  /// Whether a one-choice group may be left with none.
  final bool emptySelectionAllowed;

  /// Whether the arrows choose as they move (one-choice groups).
  final bool selectFollowsFocus;

  /// Whether an item can be pressed; null: all can.
  final bool Function(T value)? isEnabled;

  /// What a screen reader calls an item; null: its face's own words.
  final String Function(T value)? labelOf;

  /// What a screen reader calls the group.
  final String? semanticLabel;

  /// Which way the items run (and which arrows move along them), as
  /// `SegmentedButton.direction`.
  final Axis direction;

  /// Lays out the items; null puts them in a row or column at their own
  /// size.
  final Widget Function(BuildContext context, List<Widget> items)?
  layoutBuilder;

  /// The smallest an item's target may be.
  final Size minimumSize;

  @override
  State<DesignToggleGroup<T>> createState() => _DesignToggleGroupState<T>();
}

class _DesignToggleGroupState<T> extends State<DesignToggleGroup<T>> {
  final List<FocusNode> _nodes = [];
  int? _current;

  bool _enabled(int i) =>
      widget.onSelectionChanged != null &&
      (widget.isEnabled?.call(widget.options[i]) ?? true);

  @override
  void dispose() {
    for (final n in _nodes) {
      n.dispose();
    }
    super.dispose();
  }

  // The tab stop: the item the keyboard was last on, else the first chosen,
  // else the first enabled.
  int? _stop() {
    final c = _current;
    if (c != null && c < widget.options.length && _enabled(c)) return c;
    for (var i = 0; i < widget.options.length; i++) {
      if (_enabled(i) && widget.selected.contains(widget.options[i])) return i;
    }
    for (var i = 0; i < widget.options.length; i++) {
      if (_enabled(i)) return i;
    }
    return null;
  }

  void _press(int i) {
    final v = widget.options[i];
    final on = widget.selected.contains(v);
    final Set<T> next;
    if (widget.multiSelectionEnabled) {
      next = on ? ({...widget.selected}..remove(v)) : {...widget.selected, v};
    } else if (on) {
      if (!widget.emptySelectionAllowed) return;
      next = {};
    } else {
      next = {v};
    }
    setState(() => _current = i);
    widget.onSelectionChanged?.call(next);
  }

  void _move(int from, int step) {
    final n = widget.options.length;
    for (var k = 1; k <= n; k++) {
      final i = (from + step * k) % n;
      if (_enabled(i)) {
        _go(i);
        return;
      }
    }
  }

  void _go(int i) {
    setState(() => _current = i);
    _nodes[i].requestFocus();
    if (widget.selectFollowsFocus &&
        !widget.multiSelectionEnabled &&
        !widget.selected.contains(widget.options[i])) {
      widget.onSelectionChanged?.call({widget.options[i]});
    }
  }

  KeyEventResult _key(int i, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final key = event.logicalKey;
    final horizontal = widget.direction == Axis.horizontal;
    final forward = horizontal
        ? (rtl ? LogicalKeyboardKey.arrowLeft : LogicalKeyboardKey.arrowRight)
        : LogicalKeyboardKey.arrowDown;
    final back = horizontal
        ? (rtl ? LogicalKeyboardKey.arrowRight : LogicalKeyboardKey.arrowLeft)
        : LogicalKeyboardKey.arrowUp;
    if (key == forward) {
      _move(i, 1);
    } else if (key == back) {
      _move(i, -1);
    } else if (key == LogicalKeyboardKey.home) {
      _move(-1, 1);
    } else if (key == LogicalKeyboardKey.end) {
      _move(0, -1);
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.options.length;
    while (_nodes.length < n) {
      _nodes.add(FocusNode(debugLabel: 'DesignToggleGroup ${_nodes.length}'));
    }
    while (_nodes.length > n) {
      _nodes.removeLast().dispose();
    }
    final stop = _stop();
    final items = <Widget>[for (var i = 0; i < n; i++) _item(context, i, stop)];
    final layout =
        widget.layoutBuilder?.call(context, items) ??
        Flex(
          direction: widget.direction,
          mainAxisSize: MainAxisSize.min,
          children: items,
        );
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: widget.semanticLabel,
      child: FocusTraversalGroup(child: layout),
    );
  }

  Widget _item(BuildContext context, int i, int? stop) {
    final v = widget.options[i];
    final on = widget.selected.contains(v);
    _nodes[i].skipTraversal = i != stop;
    return DesignPressable(
      focusNode: _nodes[i],
      onPressed: _enabled(i) ? () => _press(i) : null,
      onKeyEvent: (node, event) => _key(i, event),
      selected: on,
      minimumSize: widget.minimumSize,
      semanticLabel: widget.labelOf?.call(v),
      excludeSemantics: widget.labelOf != null,
      button: widget.multiSelectionEnabled,
      checked: widget.multiSelectionEnabled ? null : on,
      inMutuallyExclusiveGroup: !widget.multiSelectionEnabled,
      toggled: widget.multiSelectionEnabled ? on : null,
      builder: (context, states, _) => widget.itemBuilder(context, v, states),
    );
  }
}
