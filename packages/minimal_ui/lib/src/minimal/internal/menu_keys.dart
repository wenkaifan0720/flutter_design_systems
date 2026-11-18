import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// The menu-button pattern's opening keys: a control that opens a menu
/// opens it on Enter and Space (its press) and on Down. (A context menu's
/// keys, Shift+F10 and the context-menu key, are ui_core's.)
final Set<LogicalKeyboardKey> _openingKeys = {
  LogicalKeyboardKey.enter,
  LogicalKeyboardKey.numpadEnter,
  LogicalKeyboardKey.space,
  LogicalKeyboardKey.select,
  LogicalKeyboardKey.arrowDown,
};

/// Whether a menu opening now was opened from the keyboard: one of the keys
/// that opens a menu is held as it opens. A menu the keyboard opened starts
/// on its chosen item; one the pointer opened starts on none.
bool minimalOpenedByKeys() =>
    HardwareKeyboard.instance.logicalKeysPressed.any(_openingKeys.contains);

/// [child], a control that opens a menu with [open], also opening it on
/// Down; null [open] leaves [child] as it is. Takes no focus and adds no
/// semantics of its own.
Widget minimalOpensOnDown({
  required VoidCallback? open,
  required Widget child,
}) {
  if (open == null) return child;
  return Focus(
    canRequestFocus: false,
    skipTraversal: true,
    includeSemantics: false,
    onKeyEvent: (node, event) {
      if (event is! KeyDownEvent ||
          event.logicalKey != LogicalKeyboardKey.arrowDown) {
        return KeyEventResult.ignored;
      }
      open();
      return KeyEventResult.handled;
    },
    child: child,
  );
}

/// Inside it, a pressable under keyboard focus draws no ring: the row it
/// presses paints the keyboard's place itself (an open menu's item, on the
/// muted fill).
class MinimalPaintsFocus extends InheritedWidget {
  /// [child]'s pressables leaving their focus to the row.
  const MinimalPaintsFocus({super.key, required super.child});

  /// Whether [context] is inside one.
  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<MinimalPaintsFocus>() != null;

  @override
  bool updateShouldNotify(MinimalPaintsFocus oldWidget) => false;
}
