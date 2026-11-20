/// A group of radios whose faces and layout are supplied by the look.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Builds the look's radio for [option]. Attach [focusNode] to the control
/// that takes the press and use [select] as its press callback. A null
/// callback disables the control. Use the supplied node directly so a caller
/// can focus the radio through [DesignRadioGroup.focusNodeFor].
typedef DesignRadioItemBuilder<T> = Widget Function(
  BuildContext context,
  T option,
  FocusNode focusNode,
  VoidCallback? select,
);

/// A single choice drawn by [itemBuilder]. Flutter's [RadioGroup] manages
/// the focus and selection of the look's own pressable for each option.
///
/// Tab and Shift+Tab enter on the chosen enabled option, or the first
/// enabled option in reading order. All four arrows move and choose in
/// that order, wrapping and skipping disabled options. Left advances in
/// right-to-left text. Space, Enter, a tap or a semantics tap chooses.
///
/// ```dart
/// DesignRadioGroup<String>(options: const ['Day', 'Week'], value: chosen, onChanged: choose, itemBuilder: (context, option, node, select) => DesignPressable(focusNode: node, onPressed: select, checked: option == chosen, inMutuallyExclusiveGroup: true, builder: (context, states, _) => Text(option)))
/// ```
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

// Register the same node the pressable uses. A RawRadio wrapped around a
// pressable would introduce a second focus target and gesture recognizer.
class _RadioOption<T> with RadioClient<T> {
  _RadioOption(this.radioValue);

  @override
  final T radioValue;
  FocusNode? suppliedNode;
  FocusNode? _ownedNode;
  @override
  FocusNode get focusNode => suppliedNode ?? (_ownedNode ??= FocusNode());
  @override
  bool get enabled => registry != null;
  @override
  bool get tristate => false;

  void dispose() {
    registry = null;
    _ownedNode?.dispose();
  }
}

class _DesignRadioGroupState<T> extends State<DesignRadioGroup<T>> {
  final _radios = <T, _RadioOption<T>>{};

  @override
  void dispose() {
    for (final radio in _radios.values) {
      radio.dispose();
    }
    super.dispose();
  }

  void _choose(T value) {
    if (widget.value != value) widget.onChanged?.call(value);
  }

  void _move(_RadioOption<T> from, int step) {
    final byNode = {
      for (final radio in _radios.values)
        if (radio.enabled) radio.focusNode: radio,
    };
    final order = ReadingOrderTraversalPolicy.sort(byNode.keys).toList();
    final next = order[(order.indexOf(from.focusNode) + step) % order.length];
    _choose(byNode[next]!.radioValue);
    next.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final options = widget.options.toSet();
    assert(
      options.length == widget.options.length,
      'Radio values must be distinct.',
    );
    for (final value in _radios.keys.toSet().difference(options)) {
      _radios.remove(value)!.dispose();
    }
    return RadioGroup<T>(
      groupValue: widget.value,
      // These clients never ask the registry to clear a choice.
      onChanged: (value) => _choose(value as T),
      child: Builder(builder: _buildOptions),
    );
  }

  Widget _buildOptions(BuildContext context) {
    final registry = RadioGroup.maybeOf<T>(context)!;
    for (final value in widget.options) {
      final radio = _radios.putIfAbsent(value, () => _RadioOption<T>(value));
      radio.suppliedNode = widget.focusNodeFor?.call(value);
      // A selected disabled radio still says it is checked. Leaving it out
      // of the registry lets Flutter find the first enabled Tab stop.
      radio.registry =
          widget.onChanged != null && (widget.isEnabled?.call(value) ?? true)
          ? registry
          : null;
    }
    assert(
      _radios.values.map((radio) => radio.focusNode).toSet().length ==
          _radios.length,
      'Each radio needs its own FocusNode.',
    );
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final single = _radios.values.where((radio) => radio.enabled).length == 1;
    final items = [
      for (final value in widget.options)
        _item(_radios[value]!, rtl: rtl, single: single),
    ];
    final layout =
        widget.layoutBuilder?.call(context, items) ??
        Flex(
          direction: widget.direction,
          mainAxisSize: MainAxisSize.min,
          children: items,
        );
    final label = widget.semanticLabel;
    return label == null ? layout : Semantics(label: label, child: layout);
  }

  Widget _item(
    _RadioOption<T> radio, {
    required bool rtl,
    required bool single,
  }) {
    final value = radio.radioValue;
    return CallbackShortcuts(
      key: ObjectKey(radio),
      // Flutter binds Right to next in both text directions, and ignores
      // arrows when only one client is enabled. Supply those two cases.
      bindings: {
        if (radio.enabled && (rtl || single)) ...{
          const SingleActivator(LogicalKeyboardKey.arrowLeft): () =>
              _move(radio, rtl ? 1 : -1),
          const SingleActivator(LogicalKeyboardKey.arrowRight): () =>
              _move(radio, rtl ? -1 : 1),
        },
        if (radio.enabled && single) ...{
          const SingleActivator(LogicalKeyboardKey.arrowDown): () =>
              _move(radio, 1),
          const SingleActivator(LogicalKeyboardKey.arrowUp): () =>
              _move(radio, -1),
        },
      },
      child: Builder(
        builder: (context) => widget.itemBuilder(
          context,
          value,
          radio.focusNode,
          radio.enabled ? () => _choose(value) : null,
        ),
      ),
    );
  }
}
