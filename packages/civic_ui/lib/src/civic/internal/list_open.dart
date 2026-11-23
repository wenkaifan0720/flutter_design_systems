import 'package:flutter/widgets.dart';

/// Tells the CivicTextField under it whether the list its field opens is
/// showing (a combobox's, a multi-select's). The field puts it on its text
/// input's own node, as the select's button says expanded.
class CivicListOpen extends InheritedWidget {
  /// The list's state for the field in [child].
  const CivicListOpen({super.key, required this.open, required super.child});

  /// Whether the list shows.
  final bool open;

  /// The state above [context], or null where no list hangs off the field.
  static bool? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<CivicListOpen>()?.open;

  @override
  bool updateShouldNotify(CivicListOpen oldWidget) => oldWidget.open != open;
}
