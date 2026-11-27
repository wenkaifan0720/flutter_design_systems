import 'package:flutter/widgets.dart';

/// Marks the lines under it as standing on a cheque, where a
/// field's rule is the faint ink rather than the ink it is off one. The cheque wraps its lines in it; [LedgerOnCheque.of] tells a
/// field which rule to draw. Plumbing of the components; pages never
/// place one.
class LedgerOnCheque extends InheritedWidget {
  /// Marks the lines in [child] as standing on a cheque.
  const LedgerOnCheque({required super.child, super.key});

  /// Whether [context] stands on a cheque.
  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<LedgerOnCheque>() != null;

  @override
  bool updateShouldNotify(LedgerOnCheque oldWidget) => false;
}
