import 'package:flutter/widgets.dart';

/// How far the desktop nav pane stands over the left of the pages under it:
/// a page lays its content out to the right of [inset] and its ground on
/// under the pane. The shell publishes it on
/// the desktop; elsewhere it is none. Plumbing of the shell and the screen;
/// pages never place one.
class Fluent2SideInset extends InheritedWidget {
  /// Tells the pages under it the nav pane's [inset].
  const Fluent2SideInset({
    required this.inset,
    required super.child,
    super.key,
  });

  /// How far the nav pane stands over the pages' start.
  final double inset;

  /// The nav pane's reach over [context]'s page: 0 off the desktop, in a
  /// sheet, or outside a shell.
  static double of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<Fluent2SideInset>()?.inset ??
      0;

  @override
  bool updateShouldNotify(Fluent2SideInset oldWidget) =>
      inset != oldWidget.inset;
}
