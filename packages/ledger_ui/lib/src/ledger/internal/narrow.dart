import 'package:flutter/widgets.dart';

/// Sets the parts under it in their phone form on any window: a part laid
/// in a slot too narrow for its desktop form (a receipt in a column beside
/// a form) reads [LedgerLayout.isWide] as false under it. Plumbing of the
/// parts.
class LedgerNarrowScope extends InheritedWidget {
  /// Sets the parts in [child] in their phone form.
  const LedgerNarrowScope({required super.child, super.key});

  /// Whether [context] stands under one.
  static bool isIn(BuildContext context) =>
      context.getInheritedWidgetOfExactType<LedgerNarrowScope>() != null;

  @override
  bool updateShouldNotify(LedgerNarrowScope oldWidget) => false;
}

/// Lifts the measure for the acts under it: in a sheet's or a dialog's foot
/// the card is the measure, so one act takes the card's width and two share
/// it evenly, as on a phone ([LedgerLayout.keepsMeasure] reads false under
/// it). Without it a desktop sheet's two acts each hugged their words at the
/// start of their half, off the card's middle. Plumbing of the parts.
class LedgerCardActsScope extends InheritedWidget {
  /// Lifts the measure for the acts in [child].
  const LedgerCardActsScope({required super.child, super.key});

  /// Whether [context] stands under one.
  static bool isIn(BuildContext context) =>
      context.getInheritedWidgetOfExactType<LedgerCardActsScope>() != null;

  @override
  bool updateShouldNotify(LedgerCardActsScope oldWidget) => false;
}
