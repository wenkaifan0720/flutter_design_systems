// Whether the menu a ComicMenuAnchor opens is up, for the anchor it builds: a select's field announces it, expanded
// while its list is open and collapsed otherwise, as a screen reader expects of a select.
import 'package:flutter/widgets.dart';

/// Holds whether the menu of the `ComicMenuAnchor` above is up.
class ComicMenuOpen extends InheritedWidget {
  /// Creates a [ComicMenuOpen].
  const ComicMenuOpen({super.key, required this.open, required super.child});

  /// Whether the menu is up.
  final bool open;

  /// Whether the anchor above [context] has its menu up; null outside one, where a field announces nothing.
  static bool? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ComicMenuOpen>()?.open;

  @override
  bool updateShouldNotify(ComicMenuOpen oldWidget) => open != oldWidget.open;
}
