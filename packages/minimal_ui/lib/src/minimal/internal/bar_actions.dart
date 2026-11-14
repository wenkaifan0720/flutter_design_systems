import 'package:flutter/widgets.dart';

/// Marks a subtree as a bar's trailing actions: a `MinimalIconButton` with no
/// variant of its own reads it and wears the bar's bordered square instead
/// of the bare glyph it draws in a row. `MinimalAppBar` mounts it around its
/// actions; nothing else does.
class MinimalBarActions extends InheritedWidget {
  /// Marks [child] as a bar's trailing actions.
  const MinimalBarActions({super.key, required super.child});

  /// Whether [context] stands among a bar's actions.
  static bool contains(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<MinimalBarActions>() != null;

  @override
  bool updateShouldNotify(MinimalBarActions oldWidget) => false;
}
