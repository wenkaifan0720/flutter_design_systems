/// A menubar, headless: top menus in a row, each a [RawPopover]
/// of items and submenus, on a [RawMenuAnchorGroup].
///
/// The bar is one tab stop: Left and Right move along it (mirrored right to
/// left), Down, Up, Enter and Space open a menu at its first item. In a
/// menu, Up and Down move (and wrap), Home and End go to the ends, a typed
/// letter goes to the next item its label starts with (letters typed in a
/// run spell the start), Right opens a submenu (Left closes it) or else
/// moves to the next menu, Left the previous one, and Escape closes it,
/// focus back on the bar. While a menu is open, a pointer over another top
/// item opens that one. Moving away clears the highlight and leaves the
/// menu open for the keyboard. A click outside, Escape or a choice closes it.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'anchored_overlay.dart';
import 'internal/menu_items.dart';
import 'localizations.dart';
import 'pressable.dart';

/// An item of a menubar: a command, a submenu ([children]), or a divider.
@immutable
class RawMenuEntry {
  /// An item [label]led, that [onPressed] runs, or a submenu of
  /// [children]. A command with no [onPressed] is disabled, as a Flutter
  /// menu item is.
  const RawMenuEntry({
    required this.label,
    this.onPressed,
    this.children,
    this.shortcut,
    this.checked,
    this.data,
    this.isDestructiveAction = false,
  }) : divider = false;

  /// A line between groups of items.
  const RawMenuEntry.divider()
    : label = '',
      onPressed = null,
      children = null,
      shortcut = null,
      checked = null,
      data = null,
      isDestructiveAction = false,
      divider = true;

  /// Its name.
  final String label;

  /// Runs it, after its menus closed.
  final VoidCallback? onPressed;

  /// Its submenu's items; null: it is a command.
  final List<RawMenuEntry>? children;

  /// Its key, for the look to show ("Ctrl+S"). `rawShortcutLabel` spells
  /// a [SingleActivator] as the platform's own menus do ("⌘ S" on macOS).
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

  /// Whether it destroys something (Delete, Remove): the look paints it in
  /// its destructive tone, as Cupertino's context menu and dialog actions
  /// paint theirs. Nothing else changes: it is pressed, reached and read as
  /// any other item.
  final bool isDestructiveAction;

  /// Whether it is a divider.
  final bool divider;

  /// Whether it opens a submenu.
  bool get isSubmenu => children != null;
}

/// Where a [RawMenuBar]'s builder paints: the bar, a menu or a submenu.
enum RawMenuLevel {
  /// A top item, on the bar.
  bar,

  /// An item in a menu.
  menu,
}

/// Paints an item for its [states] ([WidgetState.focused] while the
/// keyboard is on it, [WidgetState.selected] for the active menu title,
/// hovered, pressed, disabled). In a menu whose highlight follows the
/// pointer, one item at most is focused or hovered: the current one.
typedef RawMenuItemBuilder = Widget Function(
  BuildContext context,
  RawMenuEntry entry,
  RawMenuLevel level,
  Set<WidgetState> states,
);

/// Paints a menu's panel round its `items` (scroll them when
/// [RawPopoverInfo.maxSize] is short): a menubar's menus, a context
/// menu's.
typedef RawMenuBarOverlayBuilder = Widget Function(
  BuildContext context,
  RawPopoverInfo info,
  List<Widget> items,
);

/// A row of menus.
///
/// ```dart
/// RawMenuBar(menus: [RawMenuEntry(label: 'File', children: [RawMenuEntry(label: 'New', onPressed: () {})])], itemBuilder: (context, entry, level, states) => Text(entry.label), surfaceBuilder: (context, info, items) => Column(mainAxisSize: MainAxisSize.min, children: items))
/// ```
class RawMenuBar extends StatefulWidget {
  /// A menubar of [menus] (each with [RawMenuEntry.children]).
  const RawMenuBar({
    super.key,
    required this.menus,
    required this.itemBuilder,
    required this.surfaceBuilder,
    this.dividerBuilder,
    this.barBuilder,
    this.semanticLabel,
    this.highlightFollowsPointer = true,
  });

  /// The top menus.
  final List<RawMenuEntry> menus;

  /// Paints a top item or a menu item.
  final RawMenuItemBuilder itemBuilder;

  /// Paints a menu's panel around its `items` (scroll them when
  /// [RawPopoverInfo.maxSize] is short).
  final RawMenuBarOverlayBuilder surfaceBuilder;

  /// Paints a divider; null: a 1 px gap.
  final WidgetBuilder? dividerBuilder;

  /// Paints the bar around its top items; null: a row.
  final Widget Function(BuildContext context, List<Widget> items)? barBuilder;

  /// What a screen reader calls the bar; null:
  /// [RawWidgetsLocalizations.menuBarLabel].
  final String? semanticLabel;

  /// Whether a pointer over a menu item moves the keys there; true by
  /// default, as on every desktop.
  ///
  /// Then one item is lit, the current one: [WidgetState.hovered] when the
  /// pointer moved last, [WidgetState.focused] when the keys did, and no
  /// other item is hovered or focused; the pointer leaving the menu lights
  /// none. False: each item's states are its own (the pointer's hover and
  /// the keys' focus can light two).
  final bool highlightFollowsPointer;

  @override
  State<RawMenuBar> createState() => _RawMenuBarState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<RawMenuEntry>('menus', menus))
      ..add(
        ObjectFlagProperty<RawMenuItemBuilder>.has('itemBuilder', itemBuilder),
      )
      ..add(
        ObjectFlagProperty<RawMenuBarOverlayBuilder>.has(
          'surfaceBuilder',
          surfaceBuilder,
        ),
      )
      ..add(
        ObjectFlagProperty<WidgetBuilder>.has('dividerBuilder', dividerBuilder),
      )
      ..add(
        ObjectFlagProperty<
          Widget Function(BuildContext context, List<Widget> items)
        >.has('barBuilder', barBuilder),
      )
      ..add(StringProperty('semanticLabel', semanticLabel, defaultValue: null))
      ..add(
        FlagProperty(
          'highlightFollowsPointer',
          value: highlightFollowsPointer,
          ifFalse: 'highlight stays with the keys',
        ),
      );
  }
}

class _RawMenuBarState extends State<RawMenuBar> {
  final MenuController _group = MenuController();
  final List<MenuController> _menus = [];
  final List<FocusNode> _nodes = [];
  int _current = 0;
  int? _openIndex;
  bool _showOpenTitle = true;

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
      _nodes.add(FocusNode(debugLabel: 'RawMenuBar ${_nodes.length}'));
    }
    while (_menus.length > n) {
      _menus.removeLast();
      _nodes.removeLast().dispose();
    }
    if (_current >= n) _current = n == 0 ? 0 : n - 1;
    if ((_openIndex ?? -1) >= n) _openIndex = null;
    for (var i = 0; i < n; i++) {
      _nodes[i].skipTraversal = i != _current;
    }
  }

  int _wrap(int i) => i % widget.menus.length;

  // Leaving the title and its panels clears their pointer highlight. The menu
  // stays expanded, ready for a key or for the pointer to return.
  void _highlightTitle(int i, bool show) {
    if (_openIndex != i || _showOpenTitle == show) return;
    setState(() => _showOpenTitle = show);
  }

  // Moves to top item [i]; [open] opens its menu once focus is on it, so
  // the menu gives focus back there when it closes.
  void _goTo(int i, {required bool open}) {
    final was = _openIndex;
    if (was != null && was != i) _menus[was].close();
    setState(() => _current = i);
    _nodes[i].requestFocus();
    if (open && _openIndex != i) {
      // The focus change applies in a microtask queued before this one.
      scheduleMicrotask(() {
        if (mounted && _current == i && i < _menus.length) _menus[i].open();
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
          widget.semanticLabel ??
          RawWidgetsLocalizations.of(context).menuBarLabel,
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
      child: RawPopover(
        controller: _menus[i],
        trigger: RawPopoverTrigger.manual,
        arrowKeyNavigation: true,
        semanticLabel: entry.label,
        onOpenChanged: (open) {
          if (open) {
            _openIndex = i;
            _showOpenTitle = true;
          } else if (_openIndex == i) {
            _openIndex = null;
          }
        },
        anchorBuilder: (context, anchor) => MouseRegion(
          onEnter: (_) {
            final open = _openIndex;
            _highlightTitle(i, true);
            if (entry.enabled && open != null && open != i) {
              _goTo(i, open: true);
            }
          },
          onExit: (_) => _highlightTitle(i, false),
          child: RawButton(
            focusNode: _nodes[i],
            onPressed: entry.enabled
                ? () {
                    setState(() => _current = i);
                    anchor.toggle();
                  }
                : null,
            selected: anchor.isOpen && _showOpenTitle,
            expanded: anchor.isOpen,
            semanticLabel: entry.label,
            excludeSemantics: true,
            builder: (context, states, _) =>
                widget.itemBuilder(context, entry, RawMenuLevel.bar, states),
          ),
        ),
        overlayBuilder: (context, info) => RawMenuItems(
          info: info,
          entries: entry.children ?? const [],
          root: _menus[i],
          painters: RawMenuPainters(
            itemBuilder: widget.itemBuilder,
            surfaceBuilder: (context, info, items) => MouseRegion(
              onEnter: (_) => _highlightTitle(i, true),
              onExit: (_) => _highlightTitle(i, false),
              child: widget.surfaceBuilder(context, info, items),
            ),
            onKeyNavigation: () => _highlightTitle(i, true),
            dividerBuilder: widget.dividerBuilder,
            highlightFollowsPointer: widget.highlightFollowsPointer,
          ),
        ),
      ),
    );
  }
}
