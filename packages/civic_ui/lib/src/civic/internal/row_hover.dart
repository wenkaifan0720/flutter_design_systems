import 'package:flutter/widgets.dart';

/// Marks a row made of more than one part (a list row and the "More
/// actions" button beside it): the whole row greys under a pointer over any
/// part, so a part inside leaves its own pointer's grey to the row.
class CivicRowHover extends InheritedWidget {
  /// Marks [child] as a part of such a row.
  const CivicRowHover({super.key, required super.child});

  /// Whether [context] stands in such a row.
  static bool inRow(BuildContext context) =>
      context.getInheritedWidgetOfExactType<CivicRowHover>() != null;

  @override
  bool updateShouldNotify(CivicRowHover oldWidget) => false;
}
