/// One choice of a Clay radio group, on Flutter's own: a [RawRadio] in the
/// group's [RadioGroup], drawn by the part that holds it.
library;

import 'package:flutter/widgets.dart';

/// One choice of a radio group: Flutter's [RawRadio] for [value] in the
/// [RadioGroup] round it, with a focus node of its own. A screen reader hears
/// it as one node, a radio saying [label], checked or not, one of a group.
/// [builder] draws its face from the radio's states (disabled, hovered,
/// focused, selected, and pressed while a press is down on it); the face
/// takes no press and no focus of its own. `ClayRadioGroup`, a
/// `ClaySegmentedButton`'s segments and a one-choice `ClayToggleGroup` each
/// draw their choices with it, inside ui_core's `RadioGroupKeyboardFix`.
///
/// ```dart
/// ClayGroupRadio<String>(value: 'week', label: 'Week', builder: (context, states) => Text(states.contains(WidgetState.selected) ? 'Week, chosen' : 'Week'))
/// ```
class ClayGroupRadio<T> extends StatefulWidget {
  /// The choice of [value], read as [label].
  const ClayGroupRadio({
    super.key,
    required this.value,
    required this.label,
    required this.builder,
    this.enabled = true,
    this.toggleable = false,
  });

  /// The value it stands for.
  final T value;

  /// What a screen reader calls it.
  final String label;

  /// Whether it can be chosen; a group that takes no choice turns each off.
  final bool enabled;

  /// Whether a press on it when chosen takes the choice away (the group's
  /// `onChanged` hears null).
  final bool toggleable;

  /// Draws its face from its states.
  final Widget Function(BuildContext context, Set<WidgetState> states) builder;

  @override
  State<ClayGroupRadio<T>> createState() => _ClayGroupRadioState<T>();
}

class _ClayGroupRadioState<T> extends State<ClayGroupRadio<T>> {
  final FocusNode _node = FocusNode();

  @override
  void dispose() {
    _node.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MergeSemantics(
    child: RawRadio<T>(
      value: widget.value,
      mouseCursor: WidgetStateMouseCursor.clickable,
      toggleable: widget.toggleable,
      focusNode: _node,
      autofocus: false,
      groupRegistry: RadioGroup.maybeOf<T>(context),
      enabled: widget.enabled,
      // Hit all over, between the face's painted parts too: RawRadio takes a
      // press only where its face is hit.
      builder: (context, radio) => Semantics(
        label: widget.label,
        child: ExcludeSemantics(
          child: Listener(
            behavior: HitTestBehavior.opaque,
            child: widget.builder(context, {
              ...radio.states,
              if (radio.downPosition != null) WidgetState.pressed,
            }),
          ),
        ),
      ),
    ),
  );
}
