import 'package:flutter/widgets.dart';

/// The destinations ui_core's shell built (its navigation builder's), for
/// an Expressive bar or rail to lay out in place of presses of its own:
/// `ExpressiveNavigationBar` and `ExpressiveNavigationRail` under
/// `ExpressiveAppShell`. Each paints its face through the bar's
/// [ExpressiveDestinationFaces].
class ExpressiveShellDestinations extends InheritedWidget {
  /// Publishes the shell's [destinations] and its [group] to the bar or
  /// rail in [child].
  const ExpressiveShellDestinations({
    required this.destinations,
    required this.group,
    required super.child,
    super.key,
  });

  /// The shell's destinations, built: each presses, takes the keys and
  /// speaks round the face its bar paints.
  final List<Widget> destinations;

  /// Marks a bar's destinations, laid out, as the tab bar
  /// (`RawNavigationDetails.group`).
  final Widget Function(Widget destinations) group;

  /// The shell's destinations over [context]; null outside the shell.
  static ExpressiveShellDestinations? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ExpressiveShellDestinations>();

  @override
  bool updateShouldNotify(ExpressiveShellDestinations oldWidget) =>
      !identical(destinations, oldWidget.destinations);
}

/// Paints the face of the shell's destination [index] in [states].
typedef ExpressiveDestinationPainter = Widget Function(
  BuildContext context,
  int index,
  Set<WidgetState> states,
);

/// What a bar or a rail paints the shell's destinations with, set round
/// them.
class ExpressiveDestinationFaces extends InheritedWidget {
  /// The bar's [paint] for the destinations in [child].
  const ExpressiveDestinationFaces({
    required this.paint,
    required super.child,
    super.key,
  });

  /// The bar's painter.
  final ExpressiveDestinationPainter paint;

  @override
  bool updateShouldNotify(ExpressiveDestinationFaces oldWidget) =>
      paint != oldWidget.paint;
}

/// A destination's face in ui_core's shell: whatever the bar or the rail
/// it stands in paints for it.
class ExpressiveShellFace extends StatelessWidget {
  /// The face of destination [index] in [states].
  const ExpressiveShellFace({
    required this.index,
    required this.states,
    super.key,
  });

  /// The destination's place.
  final int index;

  /// Its states, as the shell's press reports them.
  final Set<WidgetState> states;

  @override
  Widget build(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<ExpressiveDestinationFaces>()!
      .paint(context, index, states);
}
