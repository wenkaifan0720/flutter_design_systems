/// One radio of a Flutter [RadioGroup], drawn by Keycap.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

/// Builds a Keycap group's face from its radio's states.
typedef KeycapRadioFace = Widget Function(
  BuildContext context,
  Set<WidgetState> states,
);

/// A group of radios as Flutter's [RadioGroup] makes one: one Tab stop, at
/// the chosen radio (or the first that can be chosen), and the arrows choose
/// as they move. [value] is chosen; [onChanged] hears a new choice, and null
/// when the chosen radio lets up ([KeycapGroupRadio.toggleable]). ui_core's
/// [RadioGroupKeyboardFix] stands inside, round [child], until Flutter's own
/// fixes do; [semanticLabel] names the group. Each radio in [child] is a
/// [KeycapGroupRadio].
class KeycapGroupRadios<T> extends StatelessWidget {
  /// A group whose chosen radio stands for [value].
  const KeycapGroupRadios({
    required this.value,
    required this.onChanged,
    required this.child,
    this.semanticLabel,
    super.key,
  });

  /// The value of the chosen radio; null when none is.
  final T? value;

  /// Hears a new choice; null when the chosen radio lets up.
  final ValueChanged<T?> onChanged;

  /// The radios, laid out as the group likes.
  final Widget child;

  /// What a screen reader calls the group.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) => RadioGroup<T>(
    groupValue: value,
    onChanged: (choice) {
      if (choice != value) onChanged(choice);
    },
    child: RadioGroupKeyboardFix<T>(
      child: semanticLabel == null
          ? child
          : Semantics(label: semanticLabel, child: child),
    ),
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<T?>('value', value))
      ..add(StringProperty('semanticLabel', semanticLabel, defaultValue: null));
  }
}

/// One radio of the [RadioGroup] above it: a [RawRadio] that takes the
/// focus, the press, the group's keys and the radio's semantics (checked,
/// one of a group), named [label], its face drawn by [builder] from the
/// radio's states, the whole face its target. With [toggleable], a press on
/// the chosen radio lets it up. Turned off when [enabled] is false or no
/// group stands above it.
class KeycapGroupRadio<T> extends StatefulWidget {
  /// A radio standing for [value].
  const KeycapGroupRadio({
    required this.value,
    required this.enabled,
    required this.label,
    required this.builder,
    this.toggleable = false,
    super.key,
  });

  /// What choosing it makes the group's value.
  final T value;

  /// Whether it can be chosen.
  final bool enabled;

  /// What a screen reader calls it.
  final String label;

  /// Draws its face.
  final KeycapRadioFace builder;

  /// Whether a press on it, chosen, lets it up.
  final bool toggleable;

  @override
  State<KeycapGroupRadio<T>> createState() => _KeycapGroupRadioState<T>();
}

class _KeycapGroupRadioState<T> extends State<KeycapGroupRadio<T>> {
  final FocusNode _node = FocusNode();

  // A click while it can be chosen, else the pointer round it.
  static final WidgetStateProperty<MouseCursor> _cursor =
      WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.disabled)
            ? MouseCursor.defer
            : SystemMouseCursors.click,
      );

  @override
  void dispose() {
    _node.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final registry = RadioGroup.maybeOf<T>(context);
    return MergeSemantics(
      child: RawRadio<T>(
        value: widget.value,
        mouseCursor: _cursor,
        toggleable: widget.toggleable,
        focusNode: _node,
        autofocus: false,
        groupRegistry: registry,
        enabled: widget.enabled && registry != null,
        builder: (context, radio) => Semantics(
          label: widget.label,
          child: ExcludeSemantics(
            child: MetaData(
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
}
