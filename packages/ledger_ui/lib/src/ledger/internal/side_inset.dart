import 'package:flutter/widgets.dart';

/// How far the desktop sidebar stands over the left of the pages under it:
/// a page lays its content out to the right of [inset], as the source's
/// grid does. The shell publishes it on
/// the desktop; elsewhere it is none. Plumbing of the shell and the screen;
/// pages never place one.
class LedgerSideInset extends InheritedWidget {
  /// Publishes the sidebar's [inset] to [child].
  const LedgerSideInset({required this.inset, required super.child, super.key});

  /// How far the sidebar stands over the pages' start.
  final double inset;

  /// The sidebar's reach over [context]'s page: 0 off the desktop, in a
  /// sheet, or outside a shell.
  static double of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<LedgerSideInset>()?.inset ?? 0;

  @override
  bool updateShouldNotify(LedgerSideInset oldWidget) =>
      inset != oldWidget.inset;
}
