/// One radio of a Flutter [RadioGroup], drawn by Expressive.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Builds the control a radio of [ExpressiveGroupRadio] stands in: it lays
/// [focusTarget] over itself (an `ExpressivePressable.focusTarget`), drawn
/// [chosen] or not.
typedef ExpressiveGroupRadioControl = Widget Function(
  BuildContext context,
  Widget focusTarget,
  bool chosen,
);

/// Draws a radio of [ExpressiveGroupRadio.face] from its [states].
typedef ExpressiveGroupRadioFace = Widget Function(
  BuildContext context,
  Set<WidgetState> states,
);

/// One radio of the [RadioGroup] above it, as Flutter's own radios are: a
/// [RawRadio] that takes the focus, the group's keys and the radio's
/// semantics (checked, one of a group). Put `RadioGroupKeyboardFix` inside
/// the group, round the radios.
///
/// The default constructor is for a control that keeps its own tap, ripple
/// and state layers: [control] lays the [RawRadio] over itself as its focus
/// target, and the control shows the focus while the radio holds it.
/// [ExpressiveGroupRadio.face] is for a face drawn from the radio's states
/// alone, which the [RawRadio] takes the tap for.
///
/// The radio is turned off when [enabled] is false or no group stands above
/// it.
class ExpressiveGroupRadio<T> extends StatefulWidget {
  /// A radio standing for [value], laid over the control [control] builds.
  const ExpressiveGroupRadio({
    required this.value,
    required this.enabled,
    required ExpressiveGroupRadioControl this.control,
    this.focusNode,
    this.autofocus = false,
    super.key,
  }) : face = null,
       semanticLabel = null,
       minimumSize = Size.zero;

  /// A radio standing for [value], [face] drawn from its states, at least
  /// [minimumSize] to a pointer and the layout (its face centred in it), and
  /// named [semanticLabel] to a screen reader.
  const ExpressiveGroupRadio.face({
    required this.value,
    required this.enabled,
    required ExpressiveGroupRadioFace this.face,
    this.semanticLabel,
    this.minimumSize = Size.zero,
    this.focusNode,
    this.autofocus = false,
    super.key,
  }) : control = null;

  /// What choosing the radio makes the group's value.
  final T value;

  /// Whether the radio can be chosen.
  final bool enabled;

  /// Builds the control round the radio (the default constructor).
  final ExpressiveGroupRadioControl? control;

  /// Draws the radio from its states ([ExpressiveGroupRadio.face]).
  final ExpressiveGroupRadioFace? face;

  /// What a screen reader calls a [face] radio.
  final String? semanticLabel;

  /// The least size of a [face] radio.
  final Size minimumSize;

  /// The radio's focus node; one of its own when null.
  final FocusNode? focusNode;

  /// Whether the radio takes the focus when first built.
  final bool autofocus;

  @override
  State<ExpressiveGroupRadio<T>> createState() =>
      _ExpressiveGroupRadioState<T>();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<T>('value', value))
      ..add(FlagProperty('enabled', value: enabled, ifFalse: 'disabled'))
      ..add(StringProperty('semanticLabel', semanticLabel, defaultValue: null))
      ..add(
        DiagnosticsProperty<Size>(
          'minimumSize',
          minimumSize,
          defaultValue: Size.zero,
        ),
      )
      ..add(
        DiagnosticsProperty<FocusNode?>(
          'focusNode',
          focusNode,
          defaultValue: null,
        ),
      )
      ..add(FlagProperty('autofocus', value: autofocus, ifTrue: 'autofocus'));
  }
}

class _ExpressiveGroupRadioState<T> extends State<ExpressiveGroupRadio<T>> {
  FocusNode? _own;

  FocusNode get _node => widget.focusNode ?? (_own ??= FocusNode());

  @override
  void dispose() {
    _own?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final registry = RadioGroup.maybeOf<T>(context);
    final face = widget.face;
    final radio = RawRadio<T>(
      value: widget.value,
      // A control under the radio shows its own cursor.
      mouseCursor: face == null
          ? const WidgetStatePropertyAll<MouseCursor>(MouseCursor.defer)
          : WidgetStateMouseCursor.clickable,
      toggleable: false,
      focusNode: _node,
      autofocus: widget.autofocus,
      groupRegistry: registry,
      enabled: widget.enabled && registry != null,
      builder: face == null
          // Over the control: nothing drawn and nothing hit, so the
          // control's ink takes the pointer.
          ? (context, radio) => const SizedBox.expand()
          : (context, radio) => _face(context, radio, face),
    );
    if (face == null) {
      return widget.control!(
        context,
        radio,
        registry?.groupValue == widget.value,
      );
    }
    return MergeSemantics(child: radio);
  }

  Widget _face(
    BuildContext context,
    ToggleableStateMixin radio,
    ExpressiveGroupRadioFace face,
  ) {
    final minimum = widget.minimumSize;
    // The whole target hovers, the face and the room round it.
    final Widget drawn = _PointerHover(
      builder: (context, hovered) {
        Widget drawn = face(context, <WidgetState>{
          ...radio.states,
          // RawRadio shows a hover only while Flutter's highlight mode is
          // traditional; the face shows one wherever a pointer rests on it,
          // as before.
          if (hovered && radio.isInteractive) WidgetState.hovered,
          if (radio.downPosition != null) WidgetState.pressed,
        });
        if (minimum != Size.zero) {
          drawn = ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: minimum.width,
              minHeight: minimum.height,
            ),
            child: Center(widthFactor: 1, heightFactor: 1, child: drawn),
          );
        }
        return drawn;
      },
    );
    return Semantics(
      label: widget.semanticLabel,
      // The whole target takes the tap, the face and the room round it.
      child: ExcludeSemantics(
        child: MetaData(behavior: HitTestBehavior.opaque, child: drawn),
      ),
    );
  }
}

/// Builds its child knowing whether a pointer rests on it.
class _PointerHover extends StatefulWidget {
  const _PointerHover({required this.builder});

  final Widget Function(BuildContext context, bool hovered) builder;

  @override
  State<_PointerHover> createState() => _PointerHoverState();
}

class _PointerHoverState extends State<_PointerHover> {
  bool _hovered = false;

  void _hover(bool hovered) {
    if (hovered != _hovered) setState(() => _hovered = hovered);
  }

  // Opaque, so the region counts as hit and the radio's own detector above it
  // takes the press.
  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) => _hover(true),
    onExit: (_) => _hover(false),
    child: widget.builder(context, _hovered),
  );
}
