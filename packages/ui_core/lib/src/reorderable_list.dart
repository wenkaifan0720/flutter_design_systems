/// A reorderable list, headless: the widgets layer's [ReorderableList]
/// (which gives a screen reader "Move up", "Move down", "Move to start" and
/// "Move to end" on each item) with a handle the look places, a long press
/// anywhere on touch, Alt with Up or Down to move the item the keyboard is
/// in (focus stays in it), and each move announced.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'internal/announce.dart';
import 'localizations.dart';
import 'pressable.dart';

/// An item's place and moves, as [RawReorderableList.itemBuilder] gets
/// them.
@immutable
class RawReorderItemDetails {
  /// The item's controls; the list makes them.
  const RawReorderItemDetails({
    required this.index,
    required this.count,
    required this.handle,
    required this.moveUp,
    required this.moveDown,
  });

  /// Its place.
  final int index;

  /// How many items there are.
  final int count;

  /// Wraps a drag handle. Focus it and use Alt+Up or Alt+Down to reorder.
  ///
  /// The handle's face gets no states from it; [buildHandle] paints one
  /// from them.
  final Widget Function(Widget handle) handle;

  /// A drag handle ([handle]) whose face [builder] paints from its states,
  /// as a [RawButton]'s: [WidgetState.focused] while the keyboard's focus
  /// is on it (Alt+Up or Alt+Down moves the item) and shows,
  /// [WidgetState.hovered] under a pointer, [WidgetState.pressed] while a
  /// pointer holds it down (a drag starting). [child] is passed to
  /// [builder], for a part that doesn't change with the states.
  ///
  /// ```dart
  /// RawReorderableList<String>(items: const ['a', 'b'], onReorder: (from, to) {}, labelOf: (item) => item, itemBuilder: (context, item, reorder) => Row(children: [Text(item), reorder.buildHandle((context, states, _) => Text(states.contains(WidgetState.focused) ? '[=]' : '='))]))
  /// ```
  Widget buildHandle(RawButtonBuilder builder, {Widget? child}) =>
      handle(_ReorderHandle(builder: builder, child: child));

  /// Moves it up one; null at the top (a menu's "Move up").
  final VoidCallback? moveUp;

  /// Moves it down one; null at the bottom.
  final VoidCallback? moveDown;
}

/// A list of [items] the reader puts in order; [onReorder] gets an item's
/// place `from` and its new place `to` (counted after it left).
///
/// The frame is the look's. Round the group (clip the list or its card),
/// not the first and last items: an item moves on its own, so an item with
/// rounded corners carries them into the middle of the list, and the item
/// that takes the end's place has square ones. The gap where a lifted item
/// will land is empty space the list opens, with no placeholder in it; the
/// lifted item is the look's to paint ([proxyDecorator]).
///
/// ```dart
/// RawReorderableList<String>(items: const ['a', 'b'], onReorder: (from, to) {}, labelOf: (item) => item, itemBuilder: (context, item, reorder) => reorder.handle(Text(item)))
/// ```
class RawReorderableList<T extends Object> extends StatefulWidget {
  /// A reorderable list of [items].
  const RawReorderableList({
    super.key,
    required this.items,
    required this.onReorder,
    required this.itemBuilder,
    required this.labelOf,
    this.keyOf,
    this.proxyDecorator,
    this.longPressToDrag = true,
    this.shrinkWrap = false,
    this.controller,
    this.padding,
    this.movedMessage,
  });

  /// The items, in order.
  final List<T> items;

  /// Moves the item at `from` to `to`.
  final void Function(int from, int to) onReorder;

  /// Paints an item; put its handle in [RawReorderItemDetails.handle].
  final Widget Function(
    BuildContext context,
    T item,
    RawReorderItemDetails reorder,
  )
  itemBuilder;

  /// What a screen reader calls an item.
  final String Function(T item) labelOf;

  /// Tells items apart across moves; null: the item itself.
  final Object Function(T item)? keyOf;

  /// Paints the item under the finger while it is dragged.
  final Widget Function(Widget child, int index, Animation<double> animation)?
  proxyDecorator;

  /// Whether a long press anywhere on an item drags it.
  final bool longPressToDrag;

  /// Whether the list is only as tall as its items.
  final bool shrinkWrap;

  /// Its scroll controller. The caller's, who disposes it; null: the list's
  /// scroll view makes its own.
  final ScrollController? controller;

  /// Its padding.
  final EdgeInsetsGeometry? padding;

  /// What a screen reader hears after a move; null:
  /// [RawWidgetsLocalizations.reorderableListMovedMessage].
  final String Function(String label, int position, int count)? movedMessage;

  @override
  State<RawReorderableList<T>> createState() => _RawReorderableListState<T>();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<T>('items', items))
      ..add(
        ObjectFlagProperty<void Function(int from, int to)>.has(
          'onReorder',
          onReorder,
        ),
      )
      ..add(
        ObjectFlagProperty<
          Widget Function(
            BuildContext context,
            T item,
            RawReorderItemDetails reorder,
          )
        >.has('itemBuilder', itemBuilder),
      )
      ..add(ObjectFlagProperty<String Function(T item)>.has('labelOf', labelOf))
      ..add(ObjectFlagProperty<Object Function(T item)>.has('keyOf', keyOf))
      ..add(
        ObjectFlagProperty<
          Widget Function(Widget child, int index, Animation<double> animation)
        >.has('proxyDecorator', proxyDecorator),
      )
      ..add(
        FlagProperty(
          'longPressToDrag',
          value: longPressToDrag,
          ifFalse: 'longPressToDrag: false',
          defaultValue: true,
        ),
      )
      ..add(
        FlagProperty(
          'shrinkWrap',
          value: shrinkWrap,
          ifTrue: 'shrinkWrap',
          defaultValue: false,
        ),
      )
      ..add(
        DiagnosticsProperty<ScrollController>(
          'controller',
          controller,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<EdgeInsetsGeometry>(
          'padding',
          padding,
          defaultValue: null,
        ),
      )
      ..add(
        ObjectFlagProperty<
          String Function(String label, int position, int count)
        >.has('movedMessage', movedMessage),
      );
  }
}

// A handle's face built from its states: the focus of the handle's own node
// (the one [RawReorderItemDetails.handle] puts round it) while it shows, a
// pointer over it, a pointer down on it.
class _ReorderHandle extends StatefulWidget {
  const _ReorderHandle({required this.builder, this.child});

  final RawButtonBuilder builder;
  final Widget? child;

  @override
  State<_ReorderHandle> createState() => _ReorderHandleState();
}

class _ReorderHandleState extends State<_ReorderHandle> {
  late final RawFocusShown _shown = RawFocusShown((shown) {
    if (mounted && shown != _focused) setState(() => _focused = shown);
  });
  FocusNode? _node;
  bool _focused = false;
  bool _hovered = false;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    FocusManager.instance.addHighlightModeListener(_highlightChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final node = Focus.maybeOf(context, createDependency: false);
    if (node == _node) return;
    _node?.removeListener(_focusChanged);
    _node = node?..addListener(_focusChanged);
    _focusChanged();
  }

  @override
  void dispose() {
    FocusManager.instance.removeHighlightModeListener(_highlightChanged);
    _node?.removeListener(_focusChanged);
    _shown.dispose();
    super.dispose();
  }

  void _highlightChanged(FocusHighlightMode mode) => _focusChanged();

  // The focus Flutter would highlight, as a FocusableActionDetector reports
  // it: on the handle's node, in the traditional highlight mode.
  void _focusChanged() => _shown.focused(
    (_node?.hasFocus ?? false) &&
        FocusManager.instance.highlightMode == FocusHighlightMode.traditional,
  );

  void _press(bool down) {
    if (down != _pressed) setState(() => _pressed = down);
  }

  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) => setState(() => _hovered = true),
    onExit: (_) => setState(() => _hovered = false),
    child: Listener(
      onPointerDown: (_) => _press(true),
      onPointerUp: (_) => _press(false),
      onPointerCancel: (_) => _press(false),
      child: widget.builder(context, {
        if (_hovered) WidgetState.hovered,
        if (_focused) WidgetState.focused,
        if (_pressed) WidgetState.pressed,
      }, widget.child),
    ),
  );
}

class _MoveIntent extends Intent {
  const _MoveIntent(this.by);

  final int by;
}

class _RawReorderableListState<T extends Object>
    extends State<RawReorderableList<T>> {
  // Each item's focus group, by its key, so a moved item gets focus back.
  final Map<Object, FocusNode> _groups = {};

  // The order after a move the parent has not rebuilt with yet, so a
  // second move in the same frame (a held key) starts from it.
  List<T>? _pending;

  List<T> get _items => _pending ?? widget.items;

  Object _keyOf(T item) => widget.keyOf?.call(item) ?? item;

  @override
  void didUpdateWidget(RawReorderableList<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    _pending = null;
  }

  @override
  void dispose() {
    for (final n in _groups.values) {
      n.dispose();
    }
    super.dispose();
  }

  void _move(int from, int to, {bool refocus = false}) {
    final items = _items;
    final n = items.length;
    final target = to.clamp(0, n - 1);
    if (from == target || from < 0 || from >= n) return;
    final item = items[from];
    final label = widget.labelOf(item);
    _pending = List.of(items)
      ..removeAt(from)
      ..insert(target, item);
    widget.onReorder(from, target);
    // A parent that refused the move never rebuilds: after the frame, the
    // order is the widget's again.
    WidgetsBinding.instance
      ..addPostFrameCallback((_) => _pending = null)
      ..ensureVisualUpdate();
    rawAnnounce(
      context,
      (widget.movedMessage ??
          RawWidgetsLocalizations.of(context)
              .reorderableListMovedMessage)(label, target + 1, n),
    );
    if (!refocus) return;
    final group = _groups[_keyOf(item)];
    final stops = group?.traversalDescendants.toList() ?? const <FocusNode>[];
    final focused = stops.indexWhere((node) => node.hasPrimaryFocus);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || group == null || group.context == null) return;
      final next = group.traversalDescendants.toList();
      if (next.isNotEmpty) {
        next[focused.clamp(0, next.length - 1)].requestFocus();
      }
    });
  }

  // Moves the item keyed [key] by [by], from where it is now.
  void _moveBy(Object key, int by, {bool refocus = false}) {
    final from = _items.indexWhere((i) => _keyOf(i) == key);
    if (from >= 0) _move(from, from + by, refocus: refocus);
  }

  Widget _item(BuildContext context, int index) {
    final item = widget.items[index];
    final key = _keyOf(item);
    final n = widget.items.length;
    final reorder = RawReorderItemDetails(
      index: index,
      count: n,
      handle: (handle) => Focus(
        child: ReorderableDragStartListener(index: index, child: handle),
      ),
      moveUp: index > 0 ? () => _moveBy(key, -1) : null,
      moveDown: index < n - 1 ? () => _moveBy(key, 1) : null,
    );
    Widget child = widget.itemBuilder(context, item, reorder);
    if (widget.longPressToDrag) {
      child = ReorderableDelayedDragStartListener(index: index, child: child);
    }
    return KeyedSubtree(
      key: ValueKey<Object>(key),
      child: Shortcuts(
        shortcuts: const {
          SingleActivator(LogicalKeyboardKey.arrowUp, alt: true): _MoveIntent(
            -1,
          ),
          SingleActivator(LogicalKeyboardKey.arrowDown, alt: true): _MoveIntent(
            1,
          ),
        },
        child: Actions(
          actions: {
            _MoveIntent: CallbackAction<_MoveIntent>(
              onInvoke: (intent) => _moveBy(key, intent.by, refocus: true),
            ),
          },
          child: Focus(
            focusNode: _groups.putIfAbsent(
              key,
              () => FocusNode(
                debugLabel: 'RawReorderableList item',
                canRequestFocus: false,
                skipTraversal: true,
              ),
            ),
            includeSemantics: false,
            child: child,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final keys = {for (final item in widget.items) _keyOf(item)};
    final gone = [
      for (final e in _groups.entries)
        if (!keys.contains(e.key)) e,
    ];
    for (final e in gone) {
      _groups.remove(e.key);
    }
    if (gone.isNotEmpty) {
      // Their items unmount in this frame; let go of the nodes after.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        for (final e in gone) {
          e.value.dispose();
        }
      });
    }
    return ReorderableList(
      itemCount: widget.items.length,
      shrinkWrap: widget.shrinkWrap,
      controller: widget.controller,
      padding: widget.padding,
      proxyDecorator: widget.proxyDecorator,
      // The new place counted after the item left, as onReorder's is.
      onReorderItem: _move,
      itemBuilder: _item,
    );
  }
}
