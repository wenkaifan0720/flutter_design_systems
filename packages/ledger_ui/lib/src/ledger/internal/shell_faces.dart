import 'package:flutter/widgets.dart';

/// The destinations ui_core's shell built (its navigation builder's), for a
/// Ledger bar to lay out in place of presses of its own: [LedgerNavBar] and
/// [LedgerSideBar] under [LedgerNavigationFrame]. Each paints its face
/// through the bar's [LedgerDestinationFaces].
class LedgerShellDestinations extends InheritedWidget {
  /// Publishes the shell's [destinations] to the bar in [child].
  const LedgerShellDestinations({
    required this.destinations,
    required super.child,
    super.key,
  });

  /// The shell's destinations, built: each presses, takes the keys and
  /// speaks round the face its bar paints.
  final List<Widget> destinations;

  /// The shell's destinations over [context]; null outside the frame.
  static List<Widget>? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<LedgerShellDestinations>()
      ?.destinations;

  @override
  bool updateShouldNotify(LedgerShellDestinations oldWidget) =>
      !identical(destinations, oldWidget.destinations);
}

/// Paints the face of the shell's destination [index] in [states].
typedef LedgerDestinationPainter = Widget Function(
  BuildContext context,
  int index,
  Set<WidgetState> states,
);

/// What a bar paints the shell's destinations with, set round them.
class LedgerDestinationFaces extends InheritedWidget {
  /// The bar's [paint] for the destinations in [child].
  const LedgerDestinationFaces({
    required this.paint,
    required super.child,
    super.key,
  });

  /// The bar's painter.
  final LedgerDestinationPainter paint;

  @override
  bool updateShouldNotify(LedgerDestinationFaces oldWidget) =>
      paint != oldWidget.paint;
}

/// A destination's face in ui_core's shell: whatever the bar it stands in
/// paints for it.
class LedgerShellFace extends StatelessWidget {
  /// The face of destination [index] in [states].
  const LedgerShellFace({required this.index, required this.states, super.key});

  /// The destination's place.
  final int index;

  /// Its states, as the shell's press reports them.
  final Set<WidgetState> states;

  @override
  Widget build(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<LedgerDestinationFaces>()!
      .paint(context, index, states);
}
