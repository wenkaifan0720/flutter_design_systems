/// A tree, headless: a controller of nodes and what is open, and a view of
/// the open rows with one tab stop. Up and Down move, Right opens a node or
/// steps into it, Left closes it or steps out to its parent (mirrored right
/// to left), Home and End go to the ends, Enter activates, Space selects,
/// and `*` opens every sibling. A screen reader hears each row's level and
/// whether it is open.
library;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'localizations.dart';
import 'pressable.dart';

/// A tree's nodes and which are open and selected.
///
/// The caller makes it (a State's field, say), keeps it across rebuilds
/// and disposes it; a widget it is given to only listens to it.
///
/// ```dart
/// DesignTreeController<String>(roots: const ['src'], childrenOf: (node) => const [])
/// ```
class DesignTreeController<T extends Object> extends ChangeNotifier {
  /// A tree from [roots], each node's children from [childrenOf].
  DesignTreeController({
    required List<T> roots,
    required this.childrenOf,
    Iterable<T> expanded = const [],
    this.multiSelectionEnabled = false,
  }) : _roots = List.of(roots),
       _expanded = {...expanded};

  /// A node's children (empty: a leaf).
  final List<T> Function(T node) childrenOf;

  /// Whether more than one node can be selected.
  final bool multiSelectionEnabled;

  List<T> _roots;
  final Set<T> _expanded;
  final Set<T> _selected = {};
  List<DesignTreeRow<T>>? _rows;

  /// The top nodes.
  List<T> get roots => List.unmodifiable(_roots);

  /// Replaces the top nodes (and re-reads every node's children).
  set roots(List<T> roots) {
    _roots = List.of(roots);
    refresh();
  }

  /// Re-reads the nodes' children after they changed.
  void refresh() {
    _rows = null;
    notifyListeners();
  }

  /// Whether [node] has children.
  bool hasChildren(T node) => childrenOf(node).isNotEmpty;

  /// Whether [node] is open.
  bool isExpanded(T node) => _expanded.contains(node);

  /// Opens or closes [node].
  void setExpanded(T node, bool open) {
    if (!hasChildren(node)) return;
    final changed = open ? _expanded.add(node) : _expanded.remove(node);
    if (changed) refresh();
  }

  /// Opens [node] when closed, closes it when open.
  void toggle(T node) => setExpanded(node, !isExpanded(node));

  /// Opens every node.
  void expandAll() {
    void walk(List<T> nodes) {
      for (final n in nodes) {
        final children = childrenOf(n);
        if (children.isEmpty) continue;
        _expanded.add(n);
        walk(children);
      }
    }

    walk(_roots);
    refresh();
  }

  /// Closes every node.
  void collapseAll() {
    _expanded.clear();
    refresh();
  }

  /// The selected nodes.
  Set<T> get selected => Set.unmodifiable(_selected);

  /// Whether [node] is selected.
  bool isSelected(T node) => _selected.contains(node);

  /// Selects [node] (alone, unless [multiSelectionEnabled]; then it
  /// toggles).
  void select(T node) {
    if (multiSelectionEnabled) {
      if (!_selected.remove(node)) _selected.add(node);
    } else {
      _selected
        ..clear()
        ..add(node);
    }
    notifyListeners();
  }

  /// The rows shown: every node whose ancestors are all open, in order.
  List<DesignTreeRow<T>> get rows {
    final cached = _rows;
    if (cached != null) return cached;
    final out = <DesignTreeRow<T>>[];
    void walk(List<T> nodes, int depth, T? parent) {
      for (var i = 0; i < nodes.length; i++) {
        final n = nodes[i];
        out.add(
          DesignTreeRow._(
            node: n,
            depth: depth,
            parent: parent,
            position: i,
            siblingCount: nodes.length,
          ),
        );
        if (_expanded.contains(n)) walk(childrenOf(n), depth + 1, n);
      }
    }

    walk(_roots, 0, null);
    return _rows = List.unmodifiable(out);
  }
}

/// A shown row of a tree.
@immutable
class DesignTreeRow<T extends Object> {
  const DesignTreeRow._({
    required this.node,
    required this.depth,
    required this.parent,
    required this.position,
    required this.siblingCount,
  });

  /// Its node.
  final T node;

  /// How deep it is (0 at the top): the look indents by it.
  final int depth;

  /// Its parent, or null at the top.
  final T? parent;

  /// Its place among its siblings.
  final int position;

  /// How many siblings it has, itself included.
  final int siblingCount;
}

/// A row's paint state.
@immutable
class DesignTreeItem<T extends Object> {
  /// The row's state; the tree makes it.
  const DesignTreeItem({
    required this.row,
    required this.hasChildren,
    required this.expanded,
    required this.selected,
    required this.states,
    required this.toggle,
  });

  /// The row.
  final DesignTreeRow<T> row;

  /// Whether it has children (the look draws a disclosure).
  final bool hasChildren;

  /// Whether it is open.
  final bool expanded;

  /// Whether it is selected.
  final bool selected;

  /// Its pressable states ([WidgetState.focused] while the keyboard is on
  /// it).
  final Set<WidgetState> states;

  /// Opens or closes it: for the disclosure's press.
  final VoidCallback toggle;
}

/// The open rows of [controller], one tab stop for all of them.
///
/// ```dart
/// DesignTree<String>(controller: controller, labelOf: (node) => node, rowBuilder: (context, item) => Text(item.row.node))
/// ```
class DesignTree<T extends Object> extends StatefulWidget {
  /// A tree view of [controller].
  const DesignTree({
    super.key,
    required this.controller,
    required this.rowBuilder,
    required this.labelOf,
    this.onActivate,
    this.levelHint,
    this.semanticLabel,
  });

  /// The nodes, and which are open and selected. The caller
  /// makes it, keeps it across rebuilds and disposes it.
  final DesignTreeController<T> controller;

  /// Paints a row (indent it by [DesignTreeRow.depth]).
  final Widget Function(BuildContext context, DesignTreeItem<T> item)
  rowBuilder;

  /// What a screen reader calls a node.
  final String Function(T node) labelOf;

  /// A row's Enter, or a press on a leaf (opens a file).
  final ValueChanged<T>? onActivate;

  /// What a screen reader hears of a row's place; null:
  /// [DesignLocalizations.treeLevelHint].
  final String Function(int level, int position, int count)? levelHint;

  /// What a screen reader calls the tree.
  final String? semanticLabel;

  @override
  State<DesignTree<T>> createState() => _DesignTreeState<T>();
}

class _DesignTreeState<T extends Object> extends State<DesignTree<T>> {
  final Map<T, FocusNode> _nodes = {};
  T? _current;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_changed);
  }

  @override
  void didUpdateWidget(DesignTree<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_changed);
      widget.controller.addListener(_changed);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_changed);
    for (final n in _nodes.values) {
      n.dispose();
    }
    super.dispose();
  }

  void _changed() => setState(() {});

  FocusNode _node(T node) =>
      _nodes.putIfAbsent(node, () => FocusNode(debugLabel: 'DesignTree row'));

  void _focus(T node) {
    setState(() => _current = node);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _nodes[node]?.requestFocus();
    });
  }

  void _press(DesignTreeRow<T> row) {
    final c = widget.controller;
    setState(() => _current = row.node);
    c.select(row.node);
    if (c.hasChildren(row.node)) {
      c.toggle(row.node);
    } else {
      widget.onActivate?.call(row.node);
    }
  }

  KeyEventResult _key(DesignTreeRow<T> row, int index, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final c = widget.controller;
    final rows = c.rows;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final key = event.logicalKey;
    final into = rtl
        ? LogicalKeyboardKey.arrowLeft
        : LogicalKeyboardKey.arrowRight;
    final out = rtl
        ? LogicalKeyboardKey.arrowRight
        : LogicalKeyboardKey.arrowLeft;
    final node = row.node;
    if (key == LogicalKeyboardKey.arrowDown) {
      if (index + 1 < rows.length) _focus(rows[index + 1].node);
    } else if (key == LogicalKeyboardKey.arrowUp) {
      if (index > 0) _focus(rows[index - 1].node);
    } else if (key == LogicalKeyboardKey.home) {
      _focus(rows.first.node);
    } else if (key == LogicalKeyboardKey.end) {
      _focus(rows.last.node);
    } else if (key == into) {
      if (!c.hasChildren(node)) return KeyEventResult.handled;
      if (!c.isExpanded(node)) {
        c.setExpanded(node, true);
      } else {
        _focus(c.rows[index + 1].node);
      }
    } else if (key == out) {
      final parent = row.parent;
      if (c.isExpanded(node)) {
        c.setExpanded(node, false);
      } else if (parent != null) {
        _focus(parent);
      }
    } else if (key == LogicalKeyboardKey.enter) {
      if (widget.onActivate != null) {
        widget.onActivate!(node);
      } else {
        c.toggle(node);
      }
    } else if (key == LogicalKeyboardKey.space) {
      c.select(node);
    } else if (event.character == '*') {
      final parent = row.parent;
      final siblings = parent == null ? c.roots : c.childrenOf(parent);
      for (final s in siblings) {
        c.setExpanded(s, true);
      }
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final rows = c.rows;
    final shown = {for (final r in rows) r.node};
    final hidden = [
      for (final e in _nodes.entries)
        if (!shown.contains(e.key)) e,
    ];
    if (hidden.isNotEmpty) {
      for (final e in hidden) {
        _nodes.remove(e.key);
      }
      // Their rows unmount in this frame; let go of the nodes after.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        for (final e in hidden) {
          e.value.dispose();
        }
      });
    }
    final current = _current;
    final stop = current != null && shown.contains(current)
        ? current
        : rows.isEmpty
        ? null
        : rows
              .firstWhere((r) => c.isSelected(r.node), orElse: () => rows.first)
              .node;
    final children = <Widget>[];
    for (var i = 0; i < rows.length; i++) {
      final row = rows[i];
      final node = row.node;
      final focus = _node(node)..skipTraversal = node != stop;
      final parentCount = row.siblingCount;
      final open = c.hasChildren(node) ? c.isExpanded(node) : null;
      children.add(
        DesignPressable(
          key: ValueKey<Object>(node),
          focusNode: focus,
          onPressed: () => _press(row),
          onKeyEvent: (n, event) => _key(row, i, event),
          selected: c.isSelected(node),
          semanticSelected: c.isSelected(node),
          expanded: open,
          semanticLabel: widget.labelOf(node),
          semanticHint:
              (widget.levelHint ??
              DesignLocalizations.of(context)
                  .treeLevelHint)(row.depth + 1, row.position + 1, parentCount),
          excludeSemantics: true,
          builder: (context, states, _) => widget.rowBuilder(
            context,
            DesignTreeItem(
              row: row,
              hasChildren: c.hasChildren(node),
              expanded: c.isExpanded(node),
              selected: c.isSelected(node),
              states: states,
              toggle: () => c.toggle(node),
            ),
          ),
        ),
      );
    }
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: widget.semanticLabel,
      child: FocusTraversalGroup(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    );
  }
}
