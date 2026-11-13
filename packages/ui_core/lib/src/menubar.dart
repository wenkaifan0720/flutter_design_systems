/// A menubar, headless: top menus in a row, each a [DesignAnchoredOverlay]
/// of items and submenus, on a [RawMenuAnchorGroup].
///
/// The bar is one tab stop: Left and Right move along it (mirrored right to
/// left), Down, Up, Enter and Space open a menu at its first item. In a
/// menu, Up and Down move (and wrap), Home and End go to the ends, Right
/// opens a submenu (Left closes it) or else moves to the next menu, Left
/// the previous one, and Escape closes it, focus back on the bar. While a
/// menu is open, a pointer over another top item opens that one.
library;

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'anchored_overlay.dart';
import 'localizations.dart';
import 'pressable.dart';

/// An item of a menubar: a command, a submenu ([children]), or a divider.
@immutable
class DesignMenuEntry {
  /// An item [label]led, that [onPressed] runs, or a submenu of
  /// [children]. A command with no [onPressed] is disabled, as a Flutter
  /// menu item is.
  const DesignMenuEntry({
    required this.label,
    this.onPressed,
    this.children,
    this.shortcut,
    this.checked,
    this.data,
  }) : divider = false;

  /// A line between groups of items.
  const DesignMenuEntry.divider()
    : label = '',
      onPressed = null,
      children = null,
      shortcut = null,
      checked = null,
      data = null,
      divider = true;

  /// Its name.
  final String label;

  /// Runs it, after its menus closed.
  final VoidCallback? onPressed;

  /// Its submenu's items; null: it is a command.
  final List<DesignMenuEntry>? children;

  /// Its key, for the look to show ("Ctrl+S").
  final String? shortcut;

  /// Its check, for an item that toggles; null: none.
  final bool? checked;

  /// Whether it can be pressed: a command with [onPressed], or a submenu
  /// with [children].
  bool get enabled {
    return onPressed != null || (children?.isNotEmpty ?? false);
  }

  /// Anything the look needs to paint it (an icon).
  final Object? data;

  /// Whether it is a divider.
  final bool divider;

  /// Whether it opens a submenu.
  bool get isSubmenu => children != null;
}

/// Where a [DesignMenuBar]'s builder paints: the bar, a menu or a submenu.
enum DesignMenuLevel {
  /// A top item, on the bar.
  bar,

  /// An item in a menu.
  menu,
}

/// Paints an item for its [states] ([WidgetState.focused] while the
/// keyboard is on it, [WidgetState.selected] while its menu is open,
/// hovered, pressed, disabled).
typedef DesignMenuItemBuilder = Widget Function(
  BuildContext context,
  DesignMenuEntry entry,
  DesignMenuLevel level,
  Set<WidgetState> states,
);

/// A row of menus.
///
/// ```dart
/// DesignMenuBar(menus: [DesignMenuEntry(label: 'File', children: [DesignMenuEntry(label: 'New', onPressed: () {})])], itemBuilder: (context, entry, level, states) => Text(entry.label), surfaceBuilder: (context, info, items) => Column(mainAxisSize: MainAxisSize.min, children: items))
/// ```
class DesignMenuBar extends StatefulWidget {
  /// A menubar of [menus] (each with [DesignMenuEntry.children]).
  const DesignMenuBar({
    super.key,
    required this.menus,
    required this.itemBuilder,
    required this.surfaceBuilder,
    this.dividerBuilder,
    this.barBuilder,
    this.semanticLabel,
  });

  /// The top menus.
  final List<DesignMenuEntry> menus;

  /// Paints a top item or a menu item.
  final DesignMenuItemBuilder itemBuilder;

  /// Paints a menu's panel around its `items` (scroll them when
  /// [DesignOverlayInfo.maxSize] is short).
  final Widget Function(
    BuildContext context,
    DesignOverlayInfo info,
    List<Widget> items,
  )
  surfaceBuilder;

  /// Paints a divider; null: a 1 px gap.
  final WidgetBuilder? dividerBuilder;

  /// Paints the bar around its top items; null: a row.
  final Widget Function(BuildContext context, List<Widget> items)? barBuilder;

  /// What a screen reader calls the bar; null:
  /// [DesignLocalizations.menuBarLabel].
  final String? semanticLabel;

  @override
  State<DesignMenuBar> createState() => _DesignMenuBarState();
}

class _DesignMenuBarState extends State<DesignMenuBar> {
  final MenuController _group = MenuController();
  final List<MenuController> _menus = [];
  final List<FocusNode> _nodes = [];
  int _current = 0;

  @override
  void dispose() {
    for (final n in _nodes) {
      n.dispose();
    }
    super.dispose();
  }

  void _sync() {
    final n = widget.menus.length;
    while (_menus.length < n) {
      _menus.add(MenuController());
      _nodes.add(FocusNode(debugLabel: 'DesignMenuBar ${_nodes.length}'));
    }
    while (_menus.length > n) {
      _menus.removeLast();
      _nodes.removeLast().dispose();
    }
    if (_current >= n) _current = n == 0 ? 0 : n - 1;
    for (var i = 0; i < n; i++) {
      _nodes[i].skipTraversal = i != _current;
    }
  }

  int? get _openIndex {
    for (var i = 0; i < _menus.length; i++) {
      if (_menus[i].isOpen) return i;
    }
    return null;
  }

  int _wrap(int i) => i % widget.menus.length;

  // Moves to top item [i]; [open] opens its menu once focus is on it, so
  // the menu gives focus back there when it closes.
  void _goTo(int i, {required bool open}) {
    final was = _openIndex;
    if (was != null && was != i) _menus[was].close();
    setState(() => _current = i);
    _nodes[i].requestFocus();
    if (open && !_menus[i].isOpen) {
      // The focus change applies in a microtask queued before this one.
      scheduleMicrotask(() {
        if (mounted) _menus[i].open();
      });
    }
  }

  KeyEventResult _barKey(int i, FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final key = event.logicalKey;
    final next = rtl
        ? LogicalKeyboardKey.arrowLeft
        : LogicalKeyboardKey.arrowRight;
    final back = rtl
        ? LogicalKeyboardKey.arrowRight
        : LogicalKeyboardKey.arrowLeft;
    final inMenu = !_nodes[i].hasPrimaryFocus;
    if (key == next) {
      _goTo(_wrap(i + 1), open: inMenu);
    } else if (key == back) {
      _goTo(_wrap(i - 1), open: inMenu);
    } else if (!inMenu &&
        (key == LogicalKeyboardKey.arrowDown ||
            key == LogicalKeyboardKey.arrowUp)) {
      _goTo(i, open: true);
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    _sync();
    final items = <Widget>[
      for (var i = 0; i < widget.menus.length; i++) _top(context, i),
    ];
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label:
          widget.semanticLabel ?? DesignLocalizations.of(context).menuBarLabel,
      child: RawMenuAnchorGroup(
        controller: _group,
        child: FocusTraversalGroup(
          child:
              widget.barBuilder?.call(context, items) ??
              Row(mainAxisSize: MainAxisSize.min, children: items),
        ),
      ),
    );
  }

  Widget _top(BuildContext context, int i) {
    final entry = widget.menus[i];
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      includeSemantics: false,
      onKeyEvent: (node, event) => _barKey(i, node, event),
      child: DesignAnchoredOverlay(
        controller: _menus[i],
        trigger: DesignOverlayTrigger.manual,
        arrowKeyNavigation: true,
        semanticLabel: entry.label,
        onOpenChanged: (_) => setState(() {}),
        anchorBuilder: (context, anchor) => MouseRegion(
          onEnter: (_) {
            final open = _openIndex;
            if (open != null && open != i) _goTo(i, open: true);
          },
          child: DesignPressable(
            focusNode: _nodes[i],
            onPressed: entry.enabled
                ? () {
                    setState(() => _current = i);
                    anchor.toggle();
                  }
                : null,
            selected: anchor.isOpen,
            expanded: anchor.isOpen,
            semanticLabel: entry.label,
            excludeSemantics: true,
            builder: (context, states, _) =>
                widget.itemBuilder(context, entry, DesignMenuLevel.bar, states),
          ),
        ),
        overlayBuilder: (context, info) => widget.surfaceBuilder(
          context,
          info,
          _items(context, entry.children ?? const [], _menus[i]),
        ),
      ),
    );
  }

  List<Widget> _items(
    BuildContext context,
    List<DesignMenuEntry> entries,
    MenuController root,
  ) => [
    for (final e in entries)
      if (e.divider)
        ExcludeSemantics(
          child:
              widget.dividerBuilder?.call(context) ?? const SizedBox(height: 1),
        )
      else if (e.isSubmenu)
        _Submenu(entry: e, menubar: this, root: root)
      else
        DesignPressable(
          onPressed: e.enabled
              ? () {
                  root.close();
                  e.onPressed?.call();
                }
              : null,
          checked: e.checked,
          semanticLabel: e.label,
          semanticHint: e.shortcut,
          excludeSemantics: true,
          builder: (context, states, _) =>
              widget.itemBuilder(context, e, DesignMenuLevel.menu, states),
        ),
  ];
}

// A submenu's item: Right (Left in right to left), Enter, Space and a press
// open it at its first item; Left, or Escape, closes it and focus comes
// back here. A pointer resting on it opens it.
class _Submenu extends StatefulWidget {
  const _Submenu({
    required this.entry,
    required this.menubar,
    required this.root,
  });

  final DesignMenuEntry entry;
  final _DesignMenuBarState menubar;
  final MenuController root;

  @override
  State<_Submenu> createState() => _SubmenuState();
}

class _SubmenuState extends State<_Submenu> {
  final MenuController _menu = MenuController();
  final FocusNode _node = FocusNode(debugLabel: 'DesignMenuBar submenu');

  @override
  void dispose() {
    _node.dispose();
    super.dispose();
  }

  KeyEventResult _key(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final opens = rtl
        ? LogicalKeyboardKey.arrowLeft
        : LogicalKeyboardKey.arrowRight;
    final closes = rtl
        ? LogicalKeyboardKey.arrowRight
        : LogicalKeyboardKey.arrowLeft;
    final key = event.logicalKey;
    if (_node.hasPrimaryFocus && key == opens && widget.entry.enabled) {
      _menu.open();
      return KeyEventResult.handled;
    }
    if (!_node.hasPrimaryFocus && _menu.isOpen && key == closes) {
      _menu.close();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final bar = widget.menubar;
    final e = widget.entry;
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      includeSemantics: false,
      onKeyEvent: _key,
      child: DesignAnchoredOverlay(
        controller: _menu,
        trigger: DesignOverlayTrigger.manual,
        arrowKeyNavigation: true,
        semanticLabel: e.label,
        placement: const DesignOverlayPlacement(
          side: DesignOverlaySide.end,
          gap: 0,
        ),
        onOpenChanged: (_) => setState(() {}),
        anchorBuilder: (context, anchor) => MouseRegion(
          onEnter: (_) {
            if (e.enabled && !anchor.isOpen) {
              _node.requestFocus();
              scheduleMicrotask(() {
                if (mounted) _menu.open();
              });
            }
          },
          child: DesignPressable(
            focusNode: _node,
            onPressed: e.enabled ? anchor.toggle : null,
            selected: anchor.isOpen,
            expanded: anchor.isOpen,
            semanticLabel: e.label,
            excludeSemantics: true,
            builder: (context, states, _) => bar.widget.itemBuilder(
              context,
              e,
              DesignMenuLevel.menu,
              states,
            ),
          ),
        ),
        overlayBuilder: (context, info) => bar.widget.surfaceBuilder(
          context,
          info,
          bar._items(context, e.children ?? const [], widget.root),
        ),
      ),
    );
  }
}
