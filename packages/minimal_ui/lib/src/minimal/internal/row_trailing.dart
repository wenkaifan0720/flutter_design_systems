import 'package:flutter/widgets.dart';

/// Marks a list row's trailing slot. A menu key drawn there
/// (`MinimalMenu.button`'s square) stands ghost: its glyph alone at rest, in
/// the row's quiet ink, as the row's meta and chevron are; its press and
/// hover wash and its focus ring keep the square's shape. The row's own
/// hairlines already frame it, so a square round every row's key would draw
/// a column of boxes down the list. Not exported.
class MinimalRowTrailing extends InheritedWidget {
  /// Marks [child] as a list row's trailing part.
  const MinimalRowTrailing({super.key, required super.child});

  /// Whether [context] stands in a list row's trailing slot.
  static bool inRow(BuildContext context) =>
      context.getInheritedWidgetOfExactType<MinimalRowTrailing>() != null;

  @override
  bool updateShouldNotify(MinimalRowTrailing oldWidget) => false;
}
