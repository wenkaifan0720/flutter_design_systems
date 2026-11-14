import 'package:flutter/widgets.dart';

/// Sets how far the buttons under it keep their words from their ends: a row of
/// buttons sharing its width pads each 16 (`.form-actions-row .btn`,
/// `.card-acts .btn`: padding 0 16px) where a button alone keeps 22. The row
/// wraps its buttons in it; [LedgerButtonEnds.of] tells a button its pad. A
/// quiet button keeps its own 13. Plumbing of the components; pages never place
/// one.
class LedgerButtonEnds extends InheritedWidget {
  /// Pads the buttons in [child] [pad] from their ends.
  const LedgerButtonEnds({required super.child, this.pad = 16, super.key});

  /// The pad at each end of a button's words.
  final double pad;

  /// The pad the nearest row sets, or null for a button's own.
  static double? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<LedgerButtonEnds>()?.pad;

  @override
  bool updateShouldNotify(LedgerButtonEnds oldWidget) => pad != oldWidget.pad;
}
