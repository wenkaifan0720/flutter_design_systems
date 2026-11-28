import 'package:flutter/widgets.dart';

/// Marks a list group's pane, so a swipe row on it is the pane's row:
/// square and see-through, the group rounding and clipping its rows.
/// Plumbing of the components; pages never place one.
class StudioGroupPane extends InheritedWidget {
  /// Marks [child] as the rows on a group's pane.
  const StudioGroupPane({required super.child, super.key});

  /// Whether [context] stands on a list group's pane.
  static bool around(BuildContext context) =>
      context.getInheritedWidgetOfExactType<StudioGroupPane>() != null;

  @override
  bool updateShouldNotify(StudioGroupPane oldWidget) => false;
}
