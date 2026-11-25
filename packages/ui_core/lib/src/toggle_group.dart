/// A toggle group, headless: one choice of several (a segmented control) or
/// any number (a toolbar's bold, italic, underline), one tab stop for the
/// group, arrows between its items.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/semantics.dart' show SemanticsRole;
import 'package:flutter/widgets.dart';

import 'pressable.dart';
import 'roving_focus.dart';

/// Builds an item's face for its [states] (selected, focused while the
/// keyboard is on it, hovered, pressed, disabled).
typedef RawSegmentBuilder<T> = Widget Function(
  BuildContext context,
  T value,
  Set<WidgetState> states,
);

/// A row (or column) of toggles over [options].
///
/// With [multiSelectionEnabled] false it is one choice and answers as
/// Flutter's [RadioGroup] does: a screen reader hears a radio group of
/// radios, all four arrows move and choose (mirrored right to left), and a
/// press on the chosen item keeps it unless [emptySelectionAllowed]. With
/// [multiSelectionEnabled] true each item
/// toggles on its own: the arrows along [direction] move without pressing.
///
/// Tab reaches the group once, at its chosen item (its first chosen one
/// when several are, else its first enabled one); the arrows wrap and pass
/// over items turned off; Home and End go to its ends (and choose, with
/// one choice); Space and Enter press. Each arrow, Home and End is a
/// [RawRovingFocusIntent], which an [Actions] round the group overrides.
///
/// ```dart
/// RawSegmentedButton<String>(options: const ['day', 'week'], selected: const {'day'}, onSelectionChanged: (next) {}, itemBuilder: (context, value, states) => Text(value))
/// ```
class RawSegmentedButton<T> extends StatefulWidget {
  /// A group of [options], [selected] chosen.
  const RawSegmentedButton({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelectionChanged,
    required this.itemBuilder,
    this.multiSelectionEnabled = false,
    this.emptySelectionAllowed = false,
    this.selectFollowsFocus = false,
    this.isEnabled,
    this.labelOf,
    this.semanticLabel,
    this.direction = Axis.horizontal,
    this.layoutBuilder,
    this.minimumSize = const Size(40, 40),
  });

  /// The items, in order.
  final List<T> options;

  /// The chosen ones.
  final Set<T> selected;

  /// A press's new choice.
  ///
  /// {@macro design.nullDisables}
  final ValueChanged<Set<T>>? onSelectionChanged;

  /// Paints an item.
  final RawSegmentBuilder<T> itemBuilder;

  /// Whether any number may be chosen.
  final bool multiSelectionEnabled;

  /// Whether a one-choice group may be left with none.
  final bool emptySelectionAllowed;

  /// Kept for older callers: a one-choice group chooses as the arrows
  /// move whatever it says, as a radio group does, and a group of many
  /// never does.
  final bool selectFollowsFocus;

  /// Whether an item can be pressed; null: all can.
  final bool Function(T value)? isEnabled;

  /// What a screen reader calls an item; null: its face's own words.
  final String Function(T value)? labelOf;

  /// What a screen reader calls the group.
  final String? semanticLabel;

  /// Which way the items run (and which arrows move along them), as
  /// `SegmentedButton.direction`.
  final Axis direction;

  /// Lays out the items; null puts them in a row or column at their own
  /// size.
  final Widget Function(BuildContext context, List<Widget> items)?
  layoutBuilder;

  /// The smallest an item's target may be.
  final Size minimumSize;

  @override
  State<RawSegmentedButton<T>> createState() => _DesignToggleGroupState<T>();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<T>('options', options))
      ..add(IterableProperty<T>('selected', selected))
      ..add(
        ObjectFlagProperty<ValueChanged<Set<T>>>.has(
          'onSelectionChanged',
          onSelectionChanged,
        ),
      )
      ..add(
        ObjectFlagProperty<RawSegmentBuilder<T>>.has(
          'itemBuilder',
          itemBuilder,
        ),
      )
      ..add(
        FlagProperty(
          'multiSelectionEnabled',
          value: multiSelectionEnabled,
          ifTrue: 'multiSelectionEnabled',
          defaultValue: false,
        ),
      )
      ..add(
        FlagProperty(
          'emptySelectionAllowed',
          value: emptySelectionAllowed,
          ifTrue: 'emptySelectionAllowed',
          defaultValue: false,
        ),
      )
      ..add(
        FlagProperty(
          'selectFollowsFocus',
          value: selectFollowsFocus,
          ifTrue: 'selectFollowsFocus',
          defaultValue: false,
        ),
      )
      ..add(
        ObjectFlagProperty<bool Function(T value)>.has('isEnabled', isEnabled),
      )
      ..add(
        ObjectFlagProperty<String Function(T value)>.has('labelOf', labelOf),
      )
      ..add(StringProperty('semanticLabel', semanticLabel, defaultValue: null))
      ..add(
        EnumProperty<Axis>(
          'direction',
          direction,
          defaultValue: Axis.horizontal,
        ),
      )
      ..add(
        ObjectFlagProperty<
          Widget Function(BuildContext context, List<Widget> items)
        >.has('layoutBuilder', layoutBuilder),
      )
      ..add(
        DiagnosticsProperty<Size>(
          'minimumSize',
          minimumSize,
          defaultValue: const Size(40, 40),
        ),
      );
  }
}

class _DesignToggleGroupState<T> extends State<RawSegmentedButton<T>> {
  final List<FocusNode> _nodes = [];

  bool _enabled(int i) =>
      widget.onSelectionChanged != null &&
      (widget.isEnabled?.call(widget.options[i]) ?? true);

  @override
  void dispose() {
    for (final n in _nodes) {
      n.dispose();
    }
    super.dispose();
  }

  void _press(int i) {
    final v = widget.options[i];
    final on = widget.selected.contains(v);
    final Set<T> next;
    if (widget.multiSelectionEnabled) {
      next = on ? ({...widget.selected}..remove(v)) : {...widget.selected, v};
    } else if (on) {
      if (!widget.emptySelectionAllowed) return;
      next = {};
    } else {
      next = {v};
    }
    widget.onSelectionChanged?.call(next);
  }

  // One choice is a radio group: a key that moves to an item chooses it.
  void _movedTo(int i) {
    final v = widget.options[i];
    if (!widget.selected.contains(v)) widget.onSelectionChanged?.call({v});
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.options.length;
    while (_nodes.length < n) {
      _nodes.add(FocusNode(debugLabel: 'RawSegmentedButton ${_nodes.length}'));
    }
    while (_nodes.length > n) {
      _nodes.removeLast().dispose();
    }
    final single = !widget.multiSelectionEnabled;
    final items = <Widget>[for (var i = 0; i < n; i++) _item(context, i)];
    final layout =
        widget.layoutBuilder?.call(context, items) ??
        Flex(
          direction: widget.direction,
          mainAxisSize: MainAxisSize.min,
          children: items,
        );
    return Semantics(
      container: true,
      explicitChildNodes: true,
      role: single ? SemanticsRole.radioGroup : null,
      label: widget.semanticLabel,
      child: RawRovingFocusGroup(
        // One choice answers every arrow, as a radio group does; many, the
        // arrows along the group, as a toolbar's toggles do.
        orientation: single ? null : widget.direction,
        child: layout,
      ),
    );
  }

  Widget _item(BuildContext context, int i) {
    final v = widget.options[i];
    final on = widget.selected.contains(v);
    return RawRovingFocusItem(
      focusNode: _nodes[i],
      enabled: _enabled(i),
      selected: on,
      order: i,
      onMovedTo: widget.multiSelectionEnabled ? null : () => _movedTo(i),
      child: RawButton(
        focusNode: _nodes[i],
        onPressed: _enabled(i) ? () => _press(i) : null,
        selected: on,
        minimumSize: widget.minimumSize,
        semanticLabel: widget.labelOf?.call(v),
        excludeSemantics: widget.labelOf != null,
        button: widget.multiSelectionEnabled,
        // One choice: radios. Many: toggle buttons, each a button that is
        // selected or not, as SegmentedButton's segments and
        // IconButton(isSelected:) are.
        checked: widget.multiSelectionEnabled ? null : on,
        inMutuallyExclusiveGroup: !widget.multiSelectionEnabled,
        semanticSelected: widget.multiSelectionEnabled ? on : null,
        builder: (context, states, _) => widget.itemBuilder(context, v, states),
      ),
    );
  }
}
