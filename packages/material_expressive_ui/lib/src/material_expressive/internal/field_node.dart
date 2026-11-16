/// What a text field's node says for the control it is the face of.
library;

import 'package:flutter/widgets.dart';

/// Marks the text fields below as the face of a control whose menu opens
/// from them (a select's, a combobox's): the field's own node, over its
/// container, says whether the menu is [expanded]. The node stays the
/// field's, so a screen reader outlines what a tap reaches, and the
/// field's supporting text stays a node of its own, as on any field.
class ExpressiveFieldNodeHost extends InheritedWidget {
  /// Fields in [child] say whether the menu is [expanded].
  const ExpressiveFieldNodeHost({
    required this.expanded,
    required super.child,
    super.key,
  });

  /// Whether the control's menu is open.
  final bool expanded;

  /// The expanded state a field at [context] says; null outside a host.
  static bool? expandedOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<ExpressiveFieldNodeHost>()
      ?.expanded;

  @override
  bool updateShouldNotify(ExpressiveFieldNodeHost oldWidget) =>
      expanded != oldWidget.expanded;
}
