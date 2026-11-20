/// A toggle group in Ledger's hand: the filter pills' face over ui_core's
/// [DesignToggleGroup], or its [DesignRadioGroup] for one choice.
library;

import 'package:flutter/foundation.dart';

import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../../internal/cap_center.dart';
import '../../internal/face.dart';
import '../../internal/state_face.dart';
import '../../internal/styled.dart';
import '../../style.dart';
import '../../theme.dart';

/// A row of pills over [options] (`.filters`' face), one tab stop for the
/// row: each its own ring of the light paper, a chosen one in the ink. One
/// choice is a group of radios: the Tab stop is the chosen pill, and all
/// four arrows move and choose, round the ends and past one turned off;
/// with [multiple] each pill toggles on its own (a register's columns
/// shown), the arrows moving along it, mirrored right to left. Home and End
/// go to its ends; Space and Enter press. A hover takes the ring to the
/// strong rule, a press sinks the pill, the keyboard's focus rules the
/// double rule under it. Each pill lays out at the tap floor round its 32 face
/// (44 for a finger, 24 for a pointer), so a tap anywhere in that room
/// reaches it. [labelOf] names
/// each option (its words and its spoken name); [onChanged] null shows the
/// row without letting it change.
///
/// ```dart
/// LedgerToggleGroup<String>(label: 'Show', options: const ['day', 'week', 'month'], labelOf: (v) => v, selected: const {'week'}, onChanged: (next) {})
/// ```
class LedgerToggleGroup<T> extends StatelessWidget {
  /// Pills for [options], [selected] chosen.
  const LedgerToggleGroup({
    required this.options,
    required this.selected,
    required this.label,
    required this.labelOf,
    this.onChanged,
    this.multiple = false,
    this.allowEmpty = false,
    this.isEnabled,
    this.style,
    super.key,
  });

  /// The values, in order.
  final List<T> options;

  /// The chosen values.
  final Set<T> selected;

  /// What the row chooses, for a screen reader.
  final String label;

  /// Each value's words.
  final String Function(T value) labelOf;

  /// Called with the new choice; null shows the row without letting it
  /// change.
  final ValueChanged<Set<T>>? onChanged;

  /// Whether any number may be chosen (each pill a toggle).
  final bool multiple;

  /// Whether one choice may be left with none (a press on the chosen pill
  /// clears it).
  final bool allowEmpty;

  /// Whether a value can be pressed; null: every one.
  final bool Function(T value)? isEnabled;

  /// Each pill's look, over `components.toggleGroup`. It reads `fill`,
  /// `foreground`, `edge`, `side`, `overlay`, `shape`, `padding`,
  /// `minimumSize` and `textStyle`; a chosen pill is `selected`.
  final LedgerStyle? style;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(ObjectFlagProperty<Object?>.has('labelOf', labelOf));
    properties.add(ObjectFlagProperty<Object?>.has('isEnabled', isEnabled));
    properties
      ..add(IterableProperty<T>('options', options))
      ..add(IterableProperty<T>('selected', selected))
      ..add(StringProperty('label', label))
      ..add(
        ObjectFlagProperty<ValueChanged<Set<T>>>.has('onChanged', onChanged),
      )
      ..add(FlagProperty('multiple', value: multiple, ifTrue: 'multiple'))
      ..add(FlagProperty('allowEmpty', value: allowEmpty, ifTrue: 'allowEmpty'))
      ..add(
        DiagnosticsProperty<LedgerStyle>('style', style, defaultValue: null),
      );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    final words = t.meta.medium.sized(_words).line(_line).tracked(_track);
    final change = onChanged;
    final minimumSize = DesignTapTargets.of(context).floorOn();
    Widget layout(BuildContext context, List<Widget> items) =>
        Wrap(spacing: _gap, children: items);
    Widget pill(BuildContext context, T value, Set<WidgetState> states) {
      final on = states.contains(WidgetState.selected);
      final hover = states.contains(WidgetState.hovered);
      final so = LedgerStyleOf([style, t.components.toggleGroup], states);
      final least = so.minimumSize;
      final face = LedgerFace(
        style: so.dress(
          LedgerFaceStyle(
            ink: on
                ? t.surface
                : hover
                ? t.textPrimary
                : t.textSecondary,
            ground: BoxDecoration(
              color: on ? t.textPrimary : t.surface,
              borderRadius: BorderRadius.circular(t.controlRadius),
              border: Border.all(
                color: on
                    ? t.textPrimary
                    : hover
                    ? t.borderStrong
                    : t.border,
              ),
            ),
          ),
        ),
        builder: (context, s, _) => ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: math.max(_height, least?.height ?? 0),
            minWidth: least?.width ?? 0,
          ),
          child: DecoratedBox(
            decoration: s.ground,
            child: Padding(
              padding:
                  so.padding(Directionality.of(context)) ??
                  const EdgeInsets.symmetric(horizontal: _pad),
              child: Center(
                widthFactor: 1,
                heightFactor: 1,
                child: ledgerCapCenter(
                  words,
                  Text(
                    labelOf(value),
                    softWrap: false,
                    style: so.words(words, s.ink),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      // The pill keeps its own height in the slot the group lays out at
      // the tap floor, centred in it.
      return Center(
        widthFactor: 1,
        heightFactor: 1,
        child: LedgerStateFace(
          states: states,
          radius: t.controlRadius,
          child: states.contains(WidgetState.disabled) && !on
              ? Opacity(opacity: _off, child: face)
              : face,
        ),
      );
    }

    if (!multiple && !allowEmpty) {
      return _radios(minimumSize, pill, layout);
    }
    return DesignToggleGroup<T>(
      options: options,
      selected: selected,
      onSelectionChanged: change,
      multiSelectionEnabled: multiple,
      emptySelectionAllowed: allowEmpty,
      selectFollowsFocus: !multiple,
      isEnabled: change == null ? (_) => false : isEnabled,
      labelOf: labelOf,
      semanticLabel: label,
      minimumSize: minimumSize,
      layoutBuilder: layout,
      itemBuilder: pill,
    );
  }

  bool _enabled(T value) =>
      onChanged != null && (isEnabled?.call(value) ?? true);

  // One choice that is never empty: radios over Flutter's RadioGroup, each
  // pill the pressable DesignToggleGroup would give it.
  Widget _radios(
    Size minimumSize,
    Widget Function(BuildContext, T, Set<WidgetState>) pill,
    Widget Function(BuildContext, List<Widget>) layout,
  ) {
    final chosen = selected.isEmpty ? null : selected.first;
    final nodes = <T, FocusNode>{};
    void choose(T value) {
      if (value != chosen) onChanged?.call({value});
    }

    // Home and End choose the first and the last that can be chosen.
    KeyEventResult ends(KeyEvent event) {
      if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
        return KeyEventResult.ignored;
      }
      final key = event.logicalKey;
      if (key != LogicalKeyboardKey.home && key != LogicalKeyboardKey.end) {
        return KeyEventResult.ignored;
      }
      final order = key == LogicalKeyboardKey.home ? options : options.reversed;
      for (final value in order) {
        if (!_enabled(value)) continue;
        choose(value);
        nodes[value]?.requestFocus();
        break;
      }
      return KeyEventResult.handled;
    }

    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: label,
      child: DesignRadioGroup<T>(
        options: options,
        value: chosen,
        onChanged: onChanged == null ? null : choose,
        isEnabled: isEnabled,
        layoutBuilder: layout,
        itemBuilder: (context, value, node, select) {
          nodes[value] = node;
          return DesignPressable(
            focusNode: node,
            onPressed: select,
            onKeyEvent: (node, event) => ends(event),
            selected: value == chosen,
            minimumSize: minimumSize,
            semanticLabel: labelOf(value),
            excludeSemantics: true,
            button: false,
            checked: value == chosen,
            inMutuallyExclusiveGroup: true,
            builder: (context, states, _) => pill(context, value, states),
          );
        },
      ),
    );
  }

  // The filters' pill: 32 tall, 12 at its ends (13 in the source), 500 11/16 tracked .02, 6
  // apart; each laid out at the tap floor.
  static const double _height = 32;
  static const double _pad = 12;
  static const double _gap = LedgerSpacing.s6;
  static const double _words = 11;
  static const double _line = 16;
  static const double _track = .02;
  static const double _off = .45;
}
