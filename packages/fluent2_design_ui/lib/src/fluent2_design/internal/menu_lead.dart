/// One current row in an open menu, as Fluent's menus and Windows' keep one:
/// the hand that moved last leads. Opened by a key, the keys lead and the
/// row in focus shows Fluent's focus ring; opened by a pointer, no row
/// lights until the pointer or a key moves. A pointer moving over a row
/// lights it in the hover fill and takes the focus there, so the keys go on
/// from it; a key leads again, the ring on its row and the pointer's fill
/// put out until the pointer moves. Plumbing of the menus; pages never
/// place one.
library;

import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

bool _keysLast = false;
bool _routed = false;

/// Watches which hand moves last, a key or a pointer, for a menu that opens
/// a frame after the key or click that opened it (a kit's split button):
/// its control calls this as it builds. Idempotent; it watches again after
/// the keyboard's handlers are cleared (as between tests).
void fluent2WatchInput() {
  HardwareKeyboard.instance
    ..removeHandler(_key)
    ..addHandler(_key);
  if (_routed) return;
  _routed = true;
  GestureBinding.instance.pointerRouter.addGlobalRoute(_pointer);
}

/// Whether a key, not a pointer, moved last ([fluent2WatchInput]), or a key
/// is held as it is asked (a menu opened in the key's own handler): a
/// browser's `:focus-visible`, for an open menu's first lit row.
bool fluent2KeysLed() =>
    _keysLast ||
    HardwareKeyboard.instance.logicalKeysPressed.any(
      (key) => !_modifiers.contains(key),
    );

final _modifiers = {
  ...LogicalKeyboardKey.expandSynonyms({
    LogicalKeyboardKey.shift,
    LogicalKeyboardKey.control,
    LogicalKeyboardKey.alt,
    LogicalKeyboardKey.meta,
  }),
  LogicalKeyboardKey.shift,
  LogicalKeyboardKey.control,
  LogicalKeyboardKey.alt,
  LogicalKeyboardKey.meta,
  LogicalKeyboardKey.fn,
  LogicalKeyboardKey.capsLock,
};

bool _key(KeyEvent event) {
  if (event is KeyDownEvent && !_modifiers.contains(event.logicalKey)) {
    _keysLast = true;
  }
  return false;
}

void _pointer(PointerEvent event) {
  if (event is PointerDownEvent) _keysLast = false;
}

/// The rows of an open menu in [child], one of them current: the keys lead
/// first when [keys] (the menu opened by a key). Each row's face reads
/// [Fluent2MenuLead.of] for what to draw.
class Fluent2MenuLead extends StatefulWidget {
  /// The lead of the menu in [child].
  const Fluent2MenuLead({required this.keys, required this.child, super.key});

  /// Whether the keys lead as it opens.
  final bool keys;

  /// The menu's rows.
  final Widget child;

  /// The lead of the menu round [context]; null outside an open menu (a
  /// menu drawn in place on a page), where a row draws what its states say.
  static Fluent2MenuLeadState? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_Lead>()?.state;

  @override
  State<Fluent2MenuLead> createState() => Fluent2MenuLeadState();
}

/// What an open menu's rows draw: [shown] filters a row's states.
class Fluent2MenuLeadState extends State<Fluent2MenuLead> {
  late bool _keys = widget.keys;
  // Whether the pointer has moved over the menu since it opened: a menu
  // that opens under a resting pointer lights nothing.
  bool _moved = false;
  final _rows = FocusNode(
    debugLabel: 'menu rows',
    canRequestFocus: false,
    skipTraversal: true,
  );

  @override
  void dispose() {
    _rows.dispose();
    super.dispose();
  }

  /// A row's [states] as the lead draws them: the focus ring only while the
  /// keys lead, the pointer's fill only while the pointer does.
  Set<WidgetState> shown(Set<WidgetState> states) {
    if (_keys) return states.difference(const {WidgetState.hovered});
    if (_moved) return states.difference(const {WidgetState.focused});
    return states.difference(const {WidgetState.hovered, WidgetState.focused});
  }

  /// The pointer moved over the row holding [node]: it leads, and the
  /// focus follows it there when the menu holds the focus (a field's menu
  /// leaves it in the field).
  void pointed(FocusNode? node) {
    if (_keys || !_moved) {
      setState(() {
        _keys = false;
        _moved = true;
      });
    }
    if (node != null &&
        _rows.hasFocus &&
        node.canRequestFocus &&
        !node.hasPrimaryFocus) {
      node.requestFocus();
    }
  }

  KeyEventResult _key(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent &&
        !_keys &&
        !_modifiers.contains(event.logicalKey)) {
      setState(() => _keys = true);
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) => Focus(
    focusNode: _rows,
    includeSemantics: false,
    onKeyEvent: _key,
    child: _Lead(state: this, keys: _keys, moved: _moved, child: widget.child),
  );
}

class _Lead extends InheritedWidget {
  const _Lead({
    required this.state,
    required this.keys,
    required this.moved,
    required super.child,
  });

  final Fluent2MenuLeadState state;
  final bool keys;
  final bool moved;

  @override
  bool updateShouldNotify(_Lead old) => old.keys != keys || old.moved != moved;
}
