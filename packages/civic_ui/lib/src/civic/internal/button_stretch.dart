import 'package:flutter/widgets.dart';

/// Whether the CivicButtons under it span their slot at any screen width: a
/// stacked action bar's keys, one column of one width.
class CivicButtonStretch extends InheritedWidget {
  /// Buttons in [child] that span their slot, or keep their words' width.
  const CivicButtonStretch({
    super.key,
    required this.stretch,
    required super.child,
  });

  /// Whether they span their slot.
  final bool stretch;

  /// The setting above [context], or null where none is.
  static bool? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<CivicButtonStretch>()?.stretch;

  @override
  bool updateShouldNotify(CivicButtonStretch oldWidget) =>
      oldWidget.stretch != stretch;
}
