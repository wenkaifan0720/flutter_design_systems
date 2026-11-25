/// A menu's rows, shared by the menubar, the context menu and the split
/// button: commands, submenus and dividers from [RawMenuEntry], their
/// focus and typed letters, and, with the highlight following the pointer,
/// one current row lit. Inside ui_core; not exported.
library;

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../anchored_overlay.dart';
import '../menubar.dart';
import '../pressable.dart';
import 'surface_focus.dart';

/// How a menu's rows and panels are painted, handed down its submenus.
@immutable
class RawMenuPainters {
  /// The painters of a menu.
  const RawMenuPainters({
    required this.itemBuilder,
    required this.surfaceBuilder,
    this.dividerBuilder,
    this.onKeyNavigation,
    this.highlightFollowsPointer = true,
  });

  /// Paints a row.
  final RawMenuItemBuilder itemBuilder;

  /// Paints a panel round its rows.
  final RawMenuBarOverlayBuilder surfaceBuilder;

  /// Paints a divider; null: a 1 px gap.
  final WidgetBuilder? dividerBuilder;

  /// Restores the active menu title when the keyboard takes over.
  final VoidCallback? onKeyNavigation;

  /// Whether a pointer over a row moves the keys there.
  final bool highlightFollowsPointer;
}

/// The states a row is painted with when the highlight follows the pointer:
/// one current row lit, the one with the focus ([current]), hovered when
/// the pointer moved last ([byPointer]) and focused when the keys did (as
/// [states] says: in the keyboard's highlight mode); no other row hovered
/// or focused.
Set<WidgetState> rawMenuRowStates(
  Set<WidgetState> states, {
  required bool current,
  required bool byPointer,
}) {
  final out = {...states}
    ..remove(WidgetState.hovered)
    ..remove(WidgetState.focused);
  if (current) {
    if (byPointer) {
      out.add(WidgetState.hovered);
    } else if (states.contains(WidgetState.focused)) {
      out.add(WidgetState.focused);
    }
  }
  return out;
}

/// A menu's row: a [RawButton] that, with [highlightFollowsPointer],
/// takes the keys as a pointer moves over it (a disabled one gives them to
/// the surface: no row lit), lights none as the pointer leaves it for no
/// other row, and paints [rawMenuRowStates].
class RawMenuRow extends StatefulWidget {
  /// A row [semanticLabel]led, that [onPressed] presses; null disables it.
  const RawMenuRow({
    super.key,
    required this.onPressed,
    required this.semanticLabel,
    required this.builder,
    this.focusNode,
    this.semanticHint,
    this.checked,
    this.selected = false,
    this.expanded,
    this.highlightFollowsPointer = true,
    this.onPointerOver,
  });

  /// The row's focus; null: its own.
  final FocusNode? focusNode;

  /// Presses it; null disables it.
  final VoidCallback? onPressed;

  /// What a screen reader calls it.
  final String semanticLabel;

  /// What a screen reader adds (its shortcut).
  final String? semanticHint;

  /// Its check, for a row that toggles.
  final bool? checked;

  /// Whether its submenu is open.
  final bool selected;

  /// Whether its submenu is open, for a row that opens one.
  final bool? expanded;

  /// Whether the pointer moves the keys.
  final bool highlightFollowsPointer;

  /// Told as a pointer comes over it (a submenu's row opens its menu).
  final VoidCallback? onPointerOver;

  /// Paints it for its states.
  final Widget Function(BuildContext context, Set<WidgetState> states) builder;

  @override
  State<RawMenuRow> createState() => _RawMenuRowState();
}

class _RawMenuRowState extends State<RawMenuRow> {
  FocusNode? _own;

  FocusNode get _node =>
      widget.focusNode ?? (_own ??= FocusNode(debugLabel: 'menu row'));

  @override
  void dispose() {
    _own?.dispose();
    super.dispose();
  }

  // The pointer over the row: the keys come here, or, on a disabled row,
  // go to the surface (none lit).
  void _over(RawSurfaceFocus shared) {
    if (widget.onPressed == null || !_node.canRequestFocus) {
      shared.focusSurface();
    } else if (!_node.hasPrimaryFocus) {
      _node.requestFocus();
    }
  }

  // The pointer left the row: none lit, unless the keys moved last (or the
  // next row takes it, in the same dispatch).
  void _left(RawSurfaceFocus shared) {
    if (!mounted || !shared.byPointer.value || !_node.hasPrimaryFocus) return;
    shared.focusSurface();
  }

  @override
  Widget build(BuildContext context) {
    final shared = widget.highlightFollowsPointer
        ? RawSurfaceFocus.maybeOf(context)
        : null;
    final node = _node;
    Widget row = RawButton(
      focusNode: node,
      onPressed: widget.onPressed,
      checked: widget.checked,
      selected: widget.selected,
      expanded: widget.expanded,
      semanticLabel: widget.semanticLabel,
      semanticHint: widget.semanticHint,
      excludeSemantics: true,
      builder: (context, states, _) {
        if (shared == null) return widget.builder(context, states);
        return ListenableBuilder(
          listenable: Listenable.merge([shared.byPointer, node]),
          builder: (context, _) => widget.builder(
            context,
            rawMenuRowStates(
              states,
              current: node.hasPrimaryFocus,
              byPointer: shared.byPointer.value,
            ),
          ),
        );
      },
    );
    final onPointerOver = widget.onPointerOver;
    if (shared != null || onPointerOver != null) {
      row = MouseRegion(
        onEnter: (_) {
          if (shared != null) _over(shared);
          onPointerOver?.call();
        },
        onHover: shared == null ? null : (_) => _over(shared),
        onExit: shared == null ? null : (_) => _left(shared),
        child: row,
      );
    }
    return row;
  }
}

/// A menu's panel of [entries], painted by [painters]: its rows and typed
/// letters. A command closes [root] (the whole menu) and runs.
class RawMenuItems extends StatefulWidget {
  /// The panel of [entries] in the surface [info] describes.
  const RawMenuItems({
    super.key,
    required this.info,
    required this.entries,
    required this.root,
    required this.painters,
  });

  /// The surface's info.
  final RawPopoverInfo info;

  /// Its rows.
  final List<RawMenuEntry> entries;

  /// The whole menu's controller, which a command closes.
  final MenuController root;

  /// How it is painted.
  final RawMenuPainters painters;

  @override
  State<RawMenuItems> createState() => _RawMenuItemsState();
}

// A menu's items' focus, and its typed letters: a letter goes to the next
// item its label starts with, round past the end, so the same letter steps
// through the items it starts; letters typed in a run (each within [_run]
// of the last) spell the start, the item on it kept while it fits.
class _RawMenuItemsState extends State<RawMenuItems> {
  final List<FocusNode> _nodes = [];
  String _typed = '';
  Timer? _pause;
  // Where the surface's own keys go, while this panel holds them.
  ValueNotifier<FocusOnKeyEventCallback?>? _onKey;

  static const Duration _run = Duration(milliseconds: 700);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final onKey = RawSurfaceFocus.maybeOf(context)?.onKey;
    if (!identical(onKey, _onKey)) {
      _release();
      _onKey = onKey;
      // The surface's own keys (no row lit) are typed letters too.
      onKey?.value = _key;
    }
  }

  void _release() {
    final onKey = _onKey;
    if (onKey != null && onKey.value == _key) onKey.value = null;
  }

  @override
  void dispose() {
    _release();
    _pause?.cancel();
    for (final n in _nodes) {
      n.dispose();
    }
    super.dispose();
  }

  void _sync() {
    while (_nodes.length < widget.entries.length) {
      _nodes.add(FocusNode(debugLabel: 'menu item ${_nodes.length}'));
    }
    while (_nodes.length > widget.entries.length) {
      _nodes.removeLast().dispose();
    }
  }

  // The letter a key types, lower case; null for a key that types none (a
  // space presses the item) or one held with Ctrl, Alt or Cmd.
  static String? _letter(KeyEvent event) {
    final c = event.character;
    if (c == null || c.trim().isEmpty || c.codeUnitAt(0) < 0x20) return null;
    final keys = HardwareKeyboard.instance;
    if (keys.isControlPressed || keys.isAltPressed || keys.isMetaPressed) {
      return null;
    }
    return c.toLowerCase();
  }

  KeyEventResult _key(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    widget.painters.onKeyNavigation?.call();
    final letter = _letter(event);
    if (letter == null) return KeyEventResult.ignored;
    _typed += letter;
    _pause?.cancel();
    _pause = Timer(_run, () => _typed = '');
    final entries = widget.entries;
    final from = _nodes.indexWhere((n) => n.hasPrimaryFocus);
    final start = from < 0 ? 0 : from + (_typed.length == 1 ? 1 : 0);
    for (var k = 0; k < entries.length; k++) {
      final i = (start + k) % entries.length;
      final e = entries[i];
      if (!e.divider && e.enabled && e.label.toLowerCase().startsWith(_typed)) {
        _nodes[i].requestFocus();
        break;
      }
    }
    return KeyEventResult.handled;
  }

  List<Widget> _rows(BuildContext context) {
    final painters = widget.painters;
    return [
      for (final (i, e) in widget.entries.indexed)
        if (e.divider)
          ExcludeSemantics(
            child:
                painters.dividerBuilder?.call(context) ??
                const SizedBox(height: 1),
          )
        else if (e.isSubmenu)
          _Submenu(
            entry: e,
            painters: painters,
            root: widget.root,
            focusNode: _nodes[i],
          )
        else
          RawMenuRow(
            focusNode: _nodes[i],
            highlightFollowsPointer: painters.highlightFollowsPointer,
            onPressed: e.enabled
                ? () {
                    widget.root.close();
                    e.onPressed?.call();
                  }
                : null,
            checked: e.checked,
            semanticLabel: e.label,
            semanticHint: e.shortcut,
            builder: (context, states) =>
                painters.itemBuilder(context, e, RawMenuLevel.menu, states),
          ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    _sync();
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      includeSemantics: false,
      onKeyEvent: _key,
      child: Builder(
        builder: (context) => widget.painters.surfaceBuilder(
          context,
          widget.info,
          _rows(context),
        ),
      ),
    );
  }
}

// A submenu's row: Right (Left in right to left), Enter, Space and a press
// open it at its first row; Left, or Escape, closes it and focus comes back
// here. A pointer resting on it opens it, no row lit.
class _Submenu extends StatefulWidget {
  const _Submenu({
    required this.entry,
    required this.painters,
    required this.root,
    required this.focusNode,
  });

  final RawMenuEntry entry;
  final RawMenuPainters painters;
  final MenuController root;

  // Its row's focus, its menu's (for the typed letters).
  final FocusNode focusNode;

  @override
  State<_Submenu> createState() => _SubmenuState();
}

class _SubmenuState extends State<_Submenu> {
  final MenuController _menu = MenuController();

  FocusNode get _node => widget.focusNode;

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
    final e = widget.entry;
    final painters = widget.painters;
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      includeSemantics: false,
      onKeyEvent: _key,
      child: RawPopover(
        controller: _menu,
        trigger: RawPopoverTrigger.manual,
        arrowKeyNavigation: true,
        semanticLabel: e.label,
        placement: const RawPopoverPlacement(side: RawPopoverSide.end, gap: 0),
        onOpenChanged: (_) => setState(() {}),
        anchorBuilder: (context, anchor) => RawMenuRow(
          focusNode: _node,
          highlightFollowsPointer: painters.highlightFollowsPointer,
          onPressed: e.enabled ? anchor.toggle : null,
          selected: anchor.isOpen,
          expanded: anchor.isOpen,
          semanticLabel: e.label,
          onPointerOver: () {
            if (e.enabled && !anchor.isOpen) {
              _node.requestFocus();
              scheduleMicrotask(() {
                if (mounted) _menu.open();
              });
            }
          },
          builder: (context, states) =>
              painters.itemBuilder(context, e, RawMenuLevel.menu, states),
        ),
        overlayBuilder: (context, info) => RawMenuItems(
          info: info,
          entries: e.children ?? const [],
          root: widget.root,
          painters: painters,
        ),
      ),
    );
  }
}
