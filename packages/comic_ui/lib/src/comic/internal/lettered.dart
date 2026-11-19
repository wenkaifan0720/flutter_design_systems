// Marks the ground a ComicLetteringScope letters, for the parts that draw on it.
import 'package:flutter/widgets.dart';

/// Marks [child] as standing on a filled ground whose letters a `ComicLetteringScope` chose (a lamp panel, a chosen
/// row): a part popping there keeps that fill behind its words rather than laying its own.
class Lettered extends InheritedWidget {
  /// Creates a [Lettered].
  const Lettered({super.key, required super.child});

  /// Whether [context] stands on a lettered ground.
  static bool of(BuildContext context) =>
      context.getInheritedWidgetOfExactType<Lettered>() != null;

  @override
  bool updateShouldNotify(Lettered oldWidget) => false;
}
