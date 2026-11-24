/// A control's tooltip standing down while the surface it opened is open.
library;

import 'package:flutter/widgets.dart';

/// Tells the tooltips under it whether the menu or popover their control
/// opened is open: while it is, a tip paints nothing, as a Material menu
/// button's tip stays off the menu it opened. A pointer resting on the
/// control (on the web, a click a screen reader's node takes) would
/// otherwise bring the tip up over the open surface.
class CivicTipHold extends InheritedWidget {
  /// Holds the tips under [child] down while [held].
  const CivicTipHold({super.key, required this.held, required super.child});

  /// Whether the surface the control opened is open.
  final bool held;

  /// Whether the tips at [context] stand down.
  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<CivicTipHold>()?.held ?? false;

  @override
  bool updateShouldNotify(CivicTipHold oldWidget) => oldWidget.held != held;
}
