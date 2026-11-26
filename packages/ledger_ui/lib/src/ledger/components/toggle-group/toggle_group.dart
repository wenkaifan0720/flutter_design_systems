/// A toggle group in Ledger's hand: the filter pills' face over ui_core's
/// [RawSegmentedButton], or over Flutter's RadioGroup for one choice.
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
/// with [multiSelectionEnabled] each pill toggles on its own (a register's columns
/// shown), the arrows moving along it, mirrored right to left. Home and End
/// go to its ends; Space and Enter press. A hover takes the ring to the
/// strong rule, a press sinks the pill, the keyboard's focus rules the
/// double rule under it. Each pill lays out at the tap floor round its 32 face
/// (40 for a finger, 24 for a pointer), so a tap anywhere in that room
/// reaches it. [labelOf] names
/// each option (its words and its spoken name); [onSelectionChanged] null shows the
/// row without letting it change.
///
/// ```dart
/// LedgerToggleGroup<String>(label: 'Show', options: const ['day', 'week', 'month'], labelOf: (v) => v, selected: const {'week'}, onSelectionChanged: (next) {})
/// ```
class LedgerToggleGroup<T> extends StatelessWidget {
  /// Pills for [options], [selected] chosen.
  const LedgerToggleGroup({
    required this.options,
    required this.selected,
    required this.label,
    required this.labelOf,
    this.onSelectionChanged,
    this.multiSelectionEnabled = false,
    this.emptySelectionAllowed = false,
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
  final ValueChanged<Set<T>>? onSelectionChanged;

  /// Whether any number may be chosen (each pill a toggle).
  final bool multiSelectionEnabled;

  /// Whether one choice may be left with none (a press on the chosen pill
  /// clears it).
  final bool emptySelectionAllowed;

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
        ObjectFlagProperty<ValueChanged<Set<T>>>.has(
          'onSelectionChanged',
          onSelectionChanged,
        ),
      )
      ..add(
        FlagProperty(
          'multiSelectionEnabled',
          value: multiSelectionEnabled,
          ifTrue: 'multiple',
        ),
      )
      ..add(
        FlagProperty(
          'emptySelectionAllowed',
          value: emptySelectionAllowed,
          ifTrue: 'allowEmpty',
        ),
      )
      ..add(
        DiagnosticsProperty<LedgerStyle>('style', style, defaultValue: null),
      );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    final words = t.meta.medium.sized(_words).line(_line).tracked(_track);
    final change = onSelectionChanged;
    final minimumSize = RawTapTargets.of(context).floorOn();
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
              // The words' line stands in the pill with its room above and
              // below it, so larger text grows the pill rather than sitting
              // on its rule.
              padding:
                  so.padding(Directionality.of(context)) ??
                  const EdgeInsets.symmetric(
                    horizontal: _pad,
                    vertical: (_height - _line) / 2,
                  ),
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

    if (!multiSelectionEnabled && !emptySelectionAllowed) {
      return _radios(minimumSize, pill, layout);
    }
    return RawSegmentedButton<T>(
      options: options,
      selected: selected,
      onSelectionChanged: change,
      multiSelectionEnabled: multiSelectionEnabled,
      emptySelectionAllowed: emptySelectionAllowed,
      selectFollowsFocus: !multiSelectionEnabled,
      isEnabled: change == null ? (_) => false : isEnabled,
      labelOf: labelOf,
      semanticLabel: label,
      minimumSize: minimumSize,
      layoutBuilder: layout,
      itemBuilder: pill,
    );
  }

  bool _enabled(T value) =>
      onSelectionChanged != null && (isEnabled?.call(value) ?? true);

  // One choice that is never empty: Flutter's RadioGroup, each pill a
  // RawRadio laid out at the tap floor, as RawSegmentedButton lays its out.
  Widget _radios(
    Size minimumSize,
    Widget Function(BuildContext, T, Set<WidgetState>) pill,
    Widget Function(BuildContext, List<Widget>) layout,
  ) => _PillRadios<T>(
    group: this,
    minimumSize: minimumSize,
    pill: pill,
    layout: layout,
  );

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

// The pills of a LedgerToggleGroup of one choice that is never empty: one
// group's radios (Flutter's RadioGroup, with ui_core's keyboard fix inside
// it), each with a focus node of its own so that Home and End can choose and
// focus an end.
class _PillRadios<T> extends StatefulWidget {
  const _PillRadios({
    required this.group,
    required this.minimumSize,
    required this.pill,
    required this.layout,
  });

  final LedgerToggleGroup<T> group;
  final Size minimumSize;
  final Widget Function(BuildContext, T, Set<WidgetState>) pill;
  final Widget Function(BuildContext, List<Widget>) layout;

  @override
  State<_PillRadios<T>> createState() => _PillRadiosState<T>();
}

class _PillRadiosState<T> extends State<_PillRadios<T>> {
  final _nodes = <T, FocusNode>{};

  FocusNode _nodeFor(T value) => _nodes.putIfAbsent(
    value,
    () => FocusNode(debugLabel: 'LedgerToggleGroup $value'),
  );

  T? get _chosen {
    final selected = widget.group.selected;
    return selected.isEmpty ? null : selected.first;
  }

  void _choose(T value) {
    if (value != _chosen) widget.group.onSelectionChanged?.call({value});
  }

  // Home and End choose the first and the last that can be chosen.
  void _toEnd({required bool last}) {
    final group = widget.group;
    final order = last ? group.options.reversed : group.options;
    for (final value in order) {
      if (!group._enabled(value)) continue;
      _choose(value);
      _nodeFor(value).requestFocus();
      break;
    }
  }

  @override
  void dispose() {
    for (final node in _nodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final group = widget.group;
    final current = group.options.toSet();
    final gone = [
      for (final value in _nodes.keys)
        if (!current.contains(value)) value,
    ];
    if (gone.isNotEmpty) {
      final nodes = [for (final value in gone) _nodes.remove(value)!];
      // The radios that held them unmount in this frame; let them go first.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        for (final node in nodes) {
          node.dispose();
        }
      });
    }
    final size = widget.minimumSize;
    final pills = [
      for (final value in group.options)
        Builder(
          key: ObjectKey(value),
          builder: (context) => MergeSemantics(
            child: RawRadio<T>(
              value: value,
              mouseCursor: WidgetStateMouseCursor.clickable,
              toggleable: false,
              focusNode: _nodeFor(value),
              autofocus: false,
              groupRegistry: RadioGroup.maybeOf<T>(context),
              enabled: group._enabled(value),
              builder: (context, radio) => Semantics(
                label: group.labelOf(value),
                child: ExcludeSemantics(
                  // All of its box takes a press, its gaps too:
                  // RawRadio's detector finds only what the face
                  // paints.
                  child: Listener(
                    behavior: HitTestBehavior.opaque,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minWidth: size.width,
                        minHeight: size.height,
                      ),
                      child: Center(
                        widthFactor: 1,
                        heightFactor: 1,
                        child: widget.pill(context, value, {
                          ...radio.states,
                          if (radio.downPosition != null) WidgetState.pressed,
                        }),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
    ];
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: group.label,
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.home): () =>
              _toEnd(last: false),
          const SingleActivator(LogicalKeyboardKey.end): () =>
              _toEnd(last: true),
        },
        child: RadioGroup<T>(
          groupValue: _chosen,
          onChanged: (value) {
            if (value is T) _choose(value);
          },
          child: RadioGroupKeyboardFix<T>(
            child: Builder(builder: (context) => widget.layout(context, pills)),
          ),
        ),
      ),
    );
  }
}
