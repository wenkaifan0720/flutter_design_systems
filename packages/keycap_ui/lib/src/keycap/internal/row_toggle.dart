import 'package:flutter/widgets.dart';

/// Tells the list row under it that the row is a switch: the row's press
/// says it is on or off ([value]), as Flutter's `SwitchListTile` does,
/// rather than that it is a button.
class KeycapRowToggle extends InheritedWidget {
  /// Marks the row under [child] as a switch that is [value].
  const KeycapRowToggle({super.key, required this.value, required super.child});

  /// Whether the row's switch is on.
  final bool value;

  /// The switch state of the row [context] is in, or null when it is an
  /// ordinary row.
  static bool? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<KeycapRowToggle>()?.value;

  @override
  bool updateShouldNotify(KeycapRowToggle oldWidget) =>
      oldWidget.value != value;
}
