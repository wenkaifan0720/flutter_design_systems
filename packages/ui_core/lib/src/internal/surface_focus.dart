/// How an anchored surface was opened (the keys, a pointer, or neither: a
/// screen reader or the app), which decides where its focus starts, and
/// what an open surface shares with the menu rows inside it: its own focus,
/// whether the pointer or the keys moved last, and its keys while no row
/// has them. Inside ui_core; not exported.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// What opened a surface.
enum DesignOpenedBy {
  /// A key: focus starts on the first item.
  keys,

  /// A pointer (a press, a right click, a long press, a hover): focus
  /// starts on the surface itself and no item is lit; Down goes to the
  /// first, Up to the last.
  pointer,

  /// Neither: a screen reader's tap, or the app. Focus starts on the first
  /// item, as for the keys: a reader follows focus.
  other,
}

/// What opened a surface now: a pointer pressed on its anchor ([pressed]),
/// else a key held, else a pointer resting on the anchor ([hovered]: on the
/// web with semantics on, a click arrives as a semantics tap with no press,
/// and a mouse has moved over the anchor first), else neither.
DesignOpenedBy designOpenedBy({required bool pressed, required bool hovered}) {
  if (pressed) return DesignOpenedBy.pointer;
  if (HardwareKeyboard.instance.logicalKeysPressed.isNotEmpty) {
    return DesignOpenedBy.keys;
  }
  return hovered ? DesignOpenedBy.pointer : DesignOpenedBy.other;
}

/// The key of an anchored overlay whose anchor is a region, not a control
/// (a context menu's): focus goes back where it was when its surface
/// closes, never to the region's first control.
class DesignRegionAnchorKey extends ValueKey<String> {
  /// The key.
  const DesignRegionAnchorKey() : super('region anchor');
}

/// What an open surface shares with the rows inside it.
class DesignSurfaceFocus extends InheritedWidget {
  /// Shares [focusSurface], [byPointer] and [onKey] with [child].
  const DesignSurfaceFocus({
    super.key,
    required this.focusSurface,
    required this.byPointer,
    required this.onKey,
    required super.child,
  });

  /// Gives the focus to the surface itself: no row lit, the keys still
  /// the surface's.
  final VoidCallback focusSurface;

  /// Whether the pointer moved last in the surface (else the keys).
  final ValueListenable<bool> byPointer;

  /// Where a row-less surface's keys go: a menu's typed letters register
  /// here, since a key on the surface itself never passes the rows' own
  /// handlers below it.
  final ValueNotifier<FocusOnKeyEventCallback?> onKey;

  /// The nearest surface's, or null outside one.
  static DesignSurfaceFocus? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<DesignSurfaceFocus>();

  @override
  bool updateShouldNotify(DesignSurfaceFocus oldWidget) =>
      focusSurface != oldWidget.focusSurface ||
      byPointer != oldWidget.byPointer ||
      onKey != oldWidget.onKey;
}
