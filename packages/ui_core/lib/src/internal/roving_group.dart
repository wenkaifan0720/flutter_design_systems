/// One tab stop for a group of items, the arrows moving between them, on
/// Flutter's focus system: what the radio group, the toggle group (and so a
/// segmented control) and the tab bar share, so they answer the keys alike,
/// as Flutter keeps its RadioGroup's arrows inside it. Inside ui_core; not
/// exported.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../roving_focus_intent.dart';

/// One tab stop over its [RovingItem]s, the arrows moving the
/// focus between them.
///
/// - **One tab stop.** Tab and Shift+Tab reach the group once. Tab enters
///   on its selected item ([RovingItem.selected], the first in
///   order when several are), else on its first enabled item, and the next
///   Tab leaves the group from wherever the focus is in it.
/// - **The arrows.** Along a horizontal [orientation], Right moves to the
///   next item and Left to the previous (mirrored right to left); along a
///   vertical one, Down and Up; with no [orientation], all four. Home and
///   End go to the first and the last ([homeAndEnd]). Items turned off are
///   passed over, and the ends wrap round when [loop] is true.
/// - **The order.** By each item's [RovingItem.order] when every
///   item gives one, else by where the items are drawn, in reading order.
///
/// It is built on [FocusTraversalGroup], [Shortcuts], [Actions] and
/// [RawRovingFocusIntent], so an app changes a key the Flutter way: see
/// [RawRovingFocusIntent]. It adds no semantics and draws nothing: the
/// widget that uses it says what the group is (a radio group, a tab bar).
class RovingGroup extends StatefulWidget {
  /// A group over the [RovingItem]s in [child].
  const RovingGroup({
    super.key,
    required this.child,
    this.orientation,
    this.loop = true,
    this.homeAndEnd = true,
    this.textDirection,
    this.shortcuts,
  });

  /// The items, each a [RovingItem] somewhere below.
  final Widget child;

  /// Which arrows move: Left and Right for [Axis.horizontal], Up and Down
  /// for [Axis.vertical], all four when null.
  final Axis? orientation;

  /// Whether a move past the last item goes round to the first, and back.
  final bool loop;

  /// Whether Home and End go to the first and the last item.
  final bool homeAndEnd;

  /// Which way Left and Right move; null: the ambient [Directionality].
  final TextDirection? textDirection;

  /// The keys and what they do; null: [defaultShortcuts] for [orientation],
  /// [homeAndEnd] and the reading direction.
  final Map<ShortcutActivator, Intent>? shortcuts;

  /// The group's keys: for a horizontal [orientation] (or none), Right to
  /// [RawRovingFocusMove.next] and Left to [RawRovingFocusMove.previous]
  /// (the other way round right to left); for a vertical one (or none),
  /// Down to next and Up to previous; Home to first and End to last when
  /// [homeAndEnd].
  static Map<ShortcutActivator, Intent> defaultShortcuts({
    Axis? orientation,
    bool homeAndEnd = true,
    TextDirection textDirection = TextDirection.ltr,
  }) {
    const next = RawRovingFocusIntent(RawRovingFocusMove.next);
    const previous = RawRovingFocusIntent(RawRovingFocusMove.previous);
    final rtl = textDirection == TextDirection.rtl;
    return {
      if (orientation != Axis.vertical) ...{
        const SingleActivator(LogicalKeyboardKey.arrowRight): rtl
            ? previous
            : next,
        const SingleActivator(LogicalKeyboardKey.arrowLeft): rtl
            ? next
            : previous,
      },
      if (orientation != Axis.horizontal) ...{
        const SingleActivator(LogicalKeyboardKey.arrowDown): next,
        const SingleActivator(LogicalKeyboardKey.arrowUp): previous,
      },
      if (homeAndEnd) ...{
        const SingleActivator(LogicalKeyboardKey.home):
            const RawRovingFocusIntent(RawRovingFocusMove.first),
        const SingleActivator(LogicalKeyboardKey.end):
            const RawRovingFocusIntent(RawRovingFocusMove.last),
      },
    };
  }

  @override
  State<RovingGroup> createState() => _RovingGroupState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(EnumProperty<Axis>('orientation', orientation, defaultValue: null))
      ..add(
        FlagProperty(
          'loop',
          value: loop,
          ifFalse: 'no loop',
          defaultValue: true,
        ),
      )
      ..add(
        FlagProperty(
          'homeAndEnd',
          value: homeAndEnd,
          ifFalse: 'no Home and End',
          defaultValue: true,
        ),
      )
      ..add(
        EnumProperty<TextDirection>(
          'textDirection',
          textDirection,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<Map<ShortcutActivator, Intent>>(
          'shortcuts',
          shortcuts,
          defaultValue: null,
        ),
      );
  }
}

class _RovingGroupState extends State<RovingGroup> {
  final List<_RovingItemState> _items = [];
  late final _RovingPolicy _policy = _RovingPolicy(this);
  // The group's move, which an [Actions] round the group may override.
  late final Action<RawRovingFocusIntent> _move =
      Action<RawRovingFocusIntent>.overridable(
        defaultAction: _MoveAction(this),
        context: context,
      );

  void _add(_RovingItemState item) => _items.add(item);

  void _remove(_RovingItemState item) => _items.remove(item);

  // The items laid out, enabled ones only when [enabledOnly], in the group's
  // order.
  List<_RovingItemState> _ordered({bool enabledOnly = true}) {
    final items = [
      for (final item in _items)
        if (item._node.context != null && (!enabledOnly || item._enabled)) item,
    ];
    if (items.every((item) => item.widget.order != null)) {
      return items..sort((a, b) => a.widget.order!.compareTo(b.widget.order!));
    }
    final byNode = {for (final item in items) item._node: item};
    return [
      for (final node in ReadingOrderTraversalPolicy.sort(byNode.keys))
        byNode[node]!,
    ];
  }

  // The item Tab enters on: the first selected one, else the first.
  _RovingItemState? _entry() {
    final items = _ordered();
    for (final item in items) {
      if (item.widget.selected) return item;
    }
    return items.isEmpty ? null : items.first;
  }

  _RovingItemState? _focusedItem() {
    final primary = FocusManager.instance.primaryFocus;
    for (final item in _items) {
      if (item._node == primary) return item;
    }
    return null;
  }

  // Moves the focus from the focused item, the move [move]; the key is
  // taken whether or not the focus could move.
  bool _moveFocus(RawRovingFocusMove move) {
    final from = _focusedItem();
    if (from == null) return false;
    final all = _ordered(enabledOnly: false);
    final n = all.length;
    final at = all.indexOf(from);
    if (at < 0) return false;
    // The first enabled item [step] at a time from [start], round the ends
    // when the group loops; null when none.
    int? walk(int start, int step) {
      for (var k = 1; k <= n; k++) {
        var i = start + step * k;
        if (i < 0 || i >= n) {
          if (!widget.loop) return null;
          i %= n;
        }
        if (all[i]._enabled) return i;
      }
      return null;
    }

    final to = switch (move) {
      RawRovingFocusMove.next => walk(at, 1),
      RawRovingFocusMove.previous => walk(at, -1),
      RawRovingFocusMove.first => walk(-1, 1),
      RawRovingFocusMove.last => walk(n, -1),
    };
    if (to == null) return true;
    final target = all[to];
    target._node.requestFocus();
    target.widget.onMovedTo?.call();
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final shortcuts =
        widget.shortcuts ??
        RovingGroup.defaultShortcuts(
          orientation: widget.orientation,
          homeAndEnd: widget.homeAndEnd,
          textDirection: widget.textDirection ?? Directionality.of(context),
        );
    return FocusTraversalGroup(
      policy: _policy,
      child: Shortcuts(
        shortcuts: shortcuts,
        // The keys alone: no semantics node of its own between the group's
        // owner (a radio group, a tab bar) and its items.
        includeSemantics: false,
        child: Actions(
          actions: {RawRovingFocusIntent: _move},
          child: _RovingScope(state: this, child: widget.child),
        ),
      ),
    );
  }
}

// The group's move: enabled while one of its items has the focus.
class _MoveAction extends Action<RawRovingFocusIntent> {
  _MoveAction(this._group);

  final _RovingGroupState _group;

  @override
  bool isEnabled(RawRovingFocusIntent intent) =>
      _group.mounted && _group._focusedItem() != null;

  @override
  Object? invoke(RawRovingFocusIntent intent) => _group._moveFocus(intent.move);
}

// Reading order inside the group, its items but one left out: Tab reaches
// the focused item while the focus is in the group, else its entry.
class _RovingPolicy extends ReadingOrderTraversalPolicy {
  _RovingPolicy(this._group);

  final _RovingGroupState _group;

  @override
  Iterable<FocusNode> sortDescendants(
    Iterable<FocusNode> descendants,
    FocusNode currentNode,
  ) {
    final items = {for (final item in _group._items) item._node};
    final FocusNode? stop = items.contains(currentNode)
        ? currentNode
        : _group._entry()?._node;
    return super.sortDescendants(
      descendants.where((node) => node == stop || !items.contains(node)),
      currentNode,
    );
  }
}

class _RovingScope extends InheritedWidget {
  const _RovingScope({required this.state, required super.child});

  final _RovingGroupState state;

  @override
  bool updateShouldNotify(_RovingScope oldWidget) => state != oldWidget.state;
}

/// One item of the nearest [RovingGroup]: the control that takes
/// [focusNode] somewhere in [child].
///
/// It adds no focus node of its own and changes nothing on [focusNode], so a
/// node the caller owns keeps its settings and its listeners.
class RovingItem extends StatefulWidget {
  /// An item focused through [focusNode].
  const RovingItem({
    super.key,
    required this.focusNode,
    required this.child,
    this.enabled = true,
    this.selected = false,
    this.order,
    this.onMovedTo,
  });

  /// The node of the control in [child] that takes the focus.
  final FocusNode focusNode;

  /// The control.
  final Widget child;

  /// Whether the arrows stop on it.
  final bool enabled;

  /// Whether it is the chosen one (a radio chosen, a tab selected, a
  /// toggle pressed): Tab enters the group on it.
  final bool selected;

  /// Its place in the group, when the group is not in reading order.
  final int? order;

  /// Called when a [RawRovingFocusIntent] moves the focus to it (an
  /// arrow, Home or End), also when the focus was on it already (the one
  /// item enabled): a radio chooses itself there, as a tab whose selection
  /// follows the focus shows its panel.
  final VoidCallback? onMovedTo;

  @override
  State<RovingItem> createState() => _RovingItemState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<FocusNode>('focusNode', focusNode))
      ..add(
        FlagProperty(
          'enabled',
          value: enabled,
          ifFalse: 'disabled',
          defaultValue: true,
        ),
      )
      ..add(
        FlagProperty(
          'selected',
          value: selected,
          ifTrue: 'selected',
          defaultValue: false,
        ),
      )
      ..add(IntProperty('order', order, defaultValue: null))
      ..add(ObjectFlagProperty<VoidCallback>.has('onMovedTo', onMovedTo));
  }
}

class _RovingItemState extends State<RovingItem> {
  _RovingGroupState? _group;

  FocusNode get _node => widget.focusNode;

  bool get _enabled => widget.enabled && _node.canRequestFocus;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final group = context
        .dependOnInheritedWidgetOfExactType<_RovingScope>()
        ?.state;
    if (group != _group) {
      _group?._remove(this);
      _group = group;
      group?._add(this);
    }
  }

  @override
  void dispose() {
    _group?._remove(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
