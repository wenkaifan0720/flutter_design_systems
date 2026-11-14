import 'package:flutter/widgets.dart';

/// How far the desktop sidebar stands over the left of the pages under it:
/// a page lays its content out to the right of [inset] and its sky on under
/// the sidebar's glass, as the source's grid does. The shell publishes it on
/// the desktop; elsewhere it is none. Plumbing of the shell and the screen;
/// pages never place one.
class FrostedSideInset extends InheritedWidget {
  /// Creates a [FrostedSideInset].
  const FrostedSideInset({
    required this.inset,
    required super.child,
    super.key,
  });

  /// The room at each side.
  final double inset;

  /// The sidebar's reach over [context]'s page: 0 off the desktop, in a
  /// sheet, or outside a shell.
  static double of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<FrostedSideInset>()?.inset ??
      0;

  @override
  bool updateShouldNotify(FrostedSideInset oldWidget) =>
      inset != oldWidget.inset;
}
