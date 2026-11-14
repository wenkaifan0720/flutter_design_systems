/// A part at a list row's end, where the row's own room is round it.
library;

import 'package:flutter/widgets.dart';

/// Marks [child] as standing at a list row's end: the row keeps 8 over and
/// under its words, so a part that pads itself where it stands alone (a
/// bare switch's 8 round its track) drops that padding here, and a row
/// with a switch stands as tall as its neighbours. Plumbing of the
/// components; pages never place one.
class Fluent2InRow extends InheritedWidget {
  /// Marks [child] as standing at a list row's end.
  const Fluent2InRow({required super.child, super.key});

  /// Whether [context] stands at a list row's end.
  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<Fluent2InRow>() != null;

  @override
  bool updateShouldNotify(Fluent2InRow oldWidget) => false;
}
