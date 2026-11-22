/// A group of radios whose faces and layout are supplied by the look.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'roving_focus.dart';

/// Builds the look's radio for [option]. Attach [focusNode] to the control
/// that takes the press and use [select] as its press callback. A null
/// callback disables the control. Use the supplied node directly so a caller
/// can focus the radio through [DesignRadioGroup.focusNodeFor].
@Deprecated(
  'Use RadioGroup and RawRadio, with RadioGroupKeyboardFix inside the group round the radios, and draw each face in RawRadio.builder. This feature was deprecated after ui_core 0.4.0.',
)
typedef DesignRadioItemBuilder<T> = Widget Function(
  BuildContext context,
  T option,
  FocusNode focusNode,
  VoidCallback? select,
);

/// A single choice drawn by [itemBuilder], the look's own pressable for each
/// option, under a Flutter [RadioGroup].
///
/// Tab and Shift+Tab enter on the chosen enabled option, or the first
/// enabled option in reading order. All four arrows move and choose in
/// that order, wrapping and skipping disabled options. Left advances in
/// right-to-left text. Space, Enter, a tap or a semantics tap chooses.
/// Home and End do nothing, as in Flutter's [RadioGroup]. Each arrow is a
/// [RawRovingFocusIntent], which an [Actions] round the group overrides.
///
/// ```dart
/// DesignRadioGroup<String>(options: const ['Day', 'Week'], value: chosen, onChanged: choose, itemBuilder: (context, option, node, select) => RawButton(focusNode: node, onPressed: select, checked: option == chosen, inMutuallyExclusiveGroup: true, builder: (context, states, _) => Text(option)))
/// ```
@Deprecated(
  'Use RadioGroup and RawRadio, with RadioGroupKeyboardFix inside the group round the radios, and draw each face in RawRadio.builder. This feature was deprecated after ui_core 0.4.0.',
)
class DesignRadioGroup<T> extends StatefulWidget {
  /// A group with one pressable for each distinct value in [options].
  const DesignRadioGroup({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
    required this.itemBuilder,
    this.isEnabled,
    this.focusNodeFor,
    this.semanticLabel,
    this.direction = Axis.vertical,
    this.layoutBuilder,
  });

  /// The choices in layout order. Each value identifies its focus node.
  final List<T> options;

  /// The chosen option, or null for an empty selection.
  final T? value;

  /// Called when the user chooses a different option. Null disables the group.
  final ValueChanged<T>? onChanged;

  /// Builds each complete radio, including its checked state and name.
  final DesignRadioItemBuilder<T> itemBuilder;

  /// Whether an option can be chosen. By default every option is enabled.
  final bool Function(T value)? isEnabled;

  /// The caller's focus node for an option. Returning a different node on a
  /// rebuild attaches that node to the radio. Each supplied node belongs to
  /// its caller and must be distinct from the nodes used for other options.
  /// The group creates and disposes a node for each option that has none.
  final FocusNode? Function(T option)? focusNodeFor;

  /// The accessible name of the group.
  final String? semanticLabel;

  /// Which way the default layout runs.
  final Axis direction;

  /// Places the finished controls. By default they form a [Flex].
  final Widget Function(BuildContext context, List<Widget> items)?
  layoutBuilder;

  @override
  State<DesignRadioGroup<T>> createState() => _DesignRadioGroupState<T>();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<T>('options', options))
      ..add(DiagnosticsProperty<T>('value', value, defaultValue: null))
      ..add(ObjectFlagProperty<ValueChanged<T>>.has('onChanged', onChanged))
      ..add(
        ObjectFlagProperty<DesignRadioItemBuilder<T>>.has(
          'itemBuilder',
          itemBuilder,
        ),
      )
      ..add(ObjectFlagProperty<bool Function(T)>.has('isEnabled', isEnabled))
      ..add(
        ObjectFlagProperty<FocusNode? Function(T)>.has(
          'focusNodeFor',
          focusNodeFor,
        ),
      )
      ..add(StringProperty('semanticLabel', semanticLabel, defaultValue: null))
      ..add(
        EnumProperty<Axis>('direction', direction, defaultValue: Axis.vertical),
      )
      ..add(
        ObjectFlagProperty<Widget Function(BuildContext, List<Widget>)>.has(
          'layoutBuilder',
          layoutBuilder,
        ),
      );
  }
}

class _DesignRadioGroupState<T> extends State<DesignRadioGroup<T>> {
  // The group's own node for each option that has been built without one of
  // the caller's: kept while the option stays, so a caller that stops
  // supplying a node finds the radio where it was.
  final _owned = <T, FocusNode>{};

  @override
  void dispose() {
    for (final node in _owned.values) {
      node.dispose();
    }
    super.dispose();
  }

  void _choose(T value) {
    if (widget.value != value) widget.onChanged?.call(value);
  }

  bool _enabled(T value) =>
      widget.onChanged != null && (widget.isEnabled?.call(value) ?? true);

  FocusNode _nodeFor(T value) =>
      widget.focusNodeFor?.call(value) ?? (_owned[value] ??= FocusNode());

  @override
  Widget build(BuildContext context) {
    final options = widget.options.toSet();
    assert(
      options.length == widget.options.length,
      'Radio values must be distinct.',
    );
    for (final value in _owned.keys.toSet().difference(options)) {
      _owned.remove(value)!.dispose();
    }
    final nodes = {for (final value in widget.options) value: _nodeFor(value)};
    assert(
      nodes.values.toSet().length == nodes.length,
      'Each radio needs its own FocusNode.',
    );
    final items = [
      for (final value in widget.options)
        RawRovingFocusItem(
          key: ObjectKey(value),
          focusNode: nodes[value]!,
          enabled: _enabled(value),
          selected: value == widget.value,
          onMovedTo: () => _choose(value),
          child: Builder(
            builder: (context) => widget.itemBuilder(
              context,
              value,
              nodes[value]!,
              _enabled(value) ? () => _choose(value) : null,
            ),
          ),
        ),
    ];
    final layout =
        widget.layoutBuilder?.call(context, items) ??
        Flex(
          direction: widget.direction,
          mainAxisSize: MainAxisSize.min,
          children: items,
        );
    final label = widget.semanticLabel;
    // RadioGroup says the group is a radio group, and gives a Radio or a
    // RawRadio in a face the group's value; the keys and the tab stop are
    // the roving group's.
    return RadioGroup<T>(
      groupValue: widget.value,
      onChanged: (value) {
        if (value != null) _choose(value);
      },
      child: RawRovingFocusGroup(
        homeAndEnd: false,
        child: label == null ? layout : Semantics(label: label, child: layout),
      ),
    );
  }
}
