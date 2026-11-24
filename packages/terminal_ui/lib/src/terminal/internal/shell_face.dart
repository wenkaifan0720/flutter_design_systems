/// How [TermScaffold]'s shell (ui_core's `RawAdaptiveShell`) wears the
/// window list, the rail and the side pane: the shell builds each
/// destination (its press, its keys, its words to a screen reader) and asks
/// the look for a face; the part lays the shell's destinations out where
/// its own pressables stand and paints each face as it paints its own.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// The shell's destinations, built, for the part under it to lay out in
/// place of its own pressables.
class TermShellDestinations extends InheritedWidget {
  /// The shell's [destinations] over the part [child].
  const TermShellDestinations({
    super.key,
    required this.destinations,
    required super.child,
  });

  /// One per destination, in order.
  final List<Widget> destinations;

  /// The shell's destinations, or null outside a shell.
  static List<Widget>? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<TermShellDestinations>()
      ?.destinations;

  @override
  bool updateShouldNotify(TermShellDestinations oldWidget) =>
      !listEquals(destinations, oldWidget.destinations);
}

/// The face the part paints for the shell's destination [child], from the
/// destination's states: the shell's face builder calls [build].
class TermShellFace extends InheritedWidget {
  /// [face] for the destination [child].
  const TermShellFace({super.key, required this.face, required super.child});

  /// Paints the destination in its states.
  final Widget Function(BuildContext context, Set<WidgetState> states) face;

  /// The face of the destination [context] is in, in [states].
  static Widget build(BuildContext context, Set<WidgetState> states) {
    final scope = context.dependOnInheritedWidgetOfExactType<TermShellFace>();
    assert(scope != null, 'a shell destination outside its part');
    return scope?.face(context, states) ?? const SizedBox.shrink();
  }

  @override
  bool updateShouldNotify(TermShellFace oldWidget) => face != oldWidget.face;
}

/// The states a pressable round a face gives it, for a face that is also a
/// part (a side pane's row): the part paints them, and adds no press or
/// words to a screen reader of its own.
class TermFaceStates extends InheritedWidget {
  /// [states] for the face [child].
  const TermFaceStates({super.key, required this.states, required super.child});

  /// The pressable's states.
  final Set<WidgetState> states;

  /// The states given, or null when the part is its own pressable.
  static Set<WidgetState>? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<TermFaceStates>()?.states;

  @override
  bool updateShouldNotify(TermFaceStates oldWidget) =>
      !setEquals(states, oldWidget.states);
}
