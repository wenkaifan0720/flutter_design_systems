/// Studio's choices: [StudioCheckbox] (a latching square key whose check
/// lights), [StudioCheckRow] (a checkbox and its words as one target),
/// [StudioRadio] (a round latching key with a lamp), [StudioRadioGroup]
/// (radios and their words, one choice, one Tab stop), [StudioSwitch]
/// (a slide toggle whose slot lights behind its cap) and
/// [StudioSegmentedButton] (a bank of latching keys in a recess).
library;

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import 'internal/control_light.dart';

import 'surface.dart';
import 'theme.dart';

/// A checkbox: a small square key that latches in when checked, its check
/// lit in the indicator light. A press sinks it; letting go latches it in or
/// lets it out.
///
/// A null [onChanged] disables it. [isError] lights its rim in the danger
/// colour. Its tap target is the platform's floor round its 24 px key; with
/// words beside it, use a [StudioCheckRow], whose whole row is the target.
///
/// Reads [style]'s `fill` and `foreground` (the check's light), then
/// [StudioThemeData.checkboxStyle].
///
/// ```dart
/// StudioCheckbox(value: explicit, onChanged: (v) => setState(() => explicit = v), semanticLabel: 'Explicit')
/// ```
class StudioCheckbox extends StatelessWidget {
  /// A checkbox showing [value].
  const StudioCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.isError = false,
    this.semanticLabel,
    this.focusNode,
    this.autofocus = false,
    this.style,
  });

  /// Whether it is checked.
  final bool value;

  /// Called with the new value; null disables it.
  final ValueChanged<bool>? onChanged;

  /// Whether what it answers is wrong.
  final bool isError;

  /// What a screen reader calls it, when no row names it.
  final String? semanticLabel;

  /// {@macro design.focusNode}
  final FocusNode? focusNode;

  /// {@macro design.autofocus}
  final bool autofocus;

  /// Its style, over [StudioThemeData.checkboxStyle].
  final StudioStyle? style;

  /// The key's side.
  static const double size = 24;

  @override
  Widget build(BuildContext context) => RawButton(
    onPressed: onChanged == null ? null : () => onChanged!(!value),
    focusNode: focusNode,
    autofocus: autofocus,
    // A checkbox, not a button, as Flutter's Checkbox reads.
    button: false,
    checked: value,
    isError: isError,
    semanticLabel: semanticLabel,
    builder: (context, states, _) => TapTargetPadding(
      child: _CheckKey(
        value: value,
        isError: isError,
        style: style,
        states: states,
      ),
    ),
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(FlagProperty('value', value: value, ifTrue: 'checked'))
      ..add(
        FlagProperty('enabled', value: onChanged != null, ifFalse: 'disabled'),
      );
  }
}

// A checkbox's key in [states]: [StudioCheckbox]'s, and [StudioCheckRow]'s,
// whose whole row is the one target.
class _CheckKey extends StatelessWidget {
  const _CheckKey({
    required this.value,
    required this.isError,
    required this.style,
    required this.states,
  });

  final bool value;
  final bool isError;
  final StudioStyle? style;
  final Set<WidgetState> states;

  @override
  Widget build(BuildContext context) {
    final theme = StudioTheme.of(context);
    final c = theme.colors;
    const size = StudioCheckbox.size;
    final layered = RawStyleOf(
      [style, theme.checkboxStyle],
      {...states, if (value) WidgetState.selected},
    );
    final disabled = states.contains(WidgetState.disabled);
    final pressed = states.contains(WidgetState.pressed);
    final cue = studioControlLight(states);
    final face = layered.on(
      c.keyFace
          .copyWith(
            radius: StudioRadii.small,
            travel: value || pressed ? 1 : 0,
            fill: disabled ? Color.lerp(c.key, c.panelLow, 0.5) : null,
            presence: disabled ? studioUnpowered : 1,
            rim: isError ? c.danger : c.indicator.withValues(alpha: cue),
          )
          .backlitIf(
            c,
            value && !disabled,
            focused: states.contains(WidgetState.focused),
          ),
    );
    final light = layered.foreground ?? c.litLegend;
    return SizedBox.square(
      dimension: size,
      child: AnimatedStudioSurface(
        face: face,
        child: _Glyph(
          on: value,
          painter: (t) => _CheckPainter(
            t: t,
            lit: disabled
                ? c.disabled
                : Color.lerp(
                    light,
                    Color.lerp(c.indicator, const Color(0xFFFFFFFF), 0.5),
                    cue,
                  )!,
            unlit: c.onKey.withValues(alpha: 0),
          ),
        ),
      ),
    );
  }
}

/// A checkbox and its words as one target and one spoken control: a press
/// anywhere on the row latches the key in or out, and keyboard focus lights
/// the key's own edge. [note] stands under the words. A null [onChanged]
/// disables it; [isError] lights the key's rim in the danger colour.
///
/// Reads [style] as [StudioCheckbox] does.
///
/// ```dart
/// StudioCheckRow(label: 'Done', value: done, onChanged: (v) => setState(() => done = v))
/// ```
class StudioCheckRow extends StatelessWidget {
  /// A row checking [label].
  const StudioCheckRow({
    super.key,
    required this.label,
    this.note,
    required this.value,
    required this.onChanged,
    this.isError = false,
    this.focusNode,
    this.autofocus = false,
    this.style,
  });

  /// What it checks.
  final String label;

  /// A line under [label]; none when null.
  final String? note;

  /// Whether it is checked.
  final bool value;

  /// Called with the new value; null disables it.
  final ValueChanged<bool>? onChanged;

  /// Whether what it answers is wrong.
  final bool isError;

  /// {@macro design.focusNode}
  final FocusNode? focusNode;

  /// {@macro design.autofocus}
  final bool autofocus;

  /// The key's style, over [StudioThemeData.checkboxStyle].
  final StudioStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = StudioTheme.of(context);
    final c = theme.colors;
    final off = onChanged == null;
    return RawButton(
      onPressed: off ? null : () => onChanged!(!value),
      focusNode: focusNode,
      autofocus: autofocus,
      button: false,
      checked: value,
      isError: isError,
      semanticLabel: note == null ? label : '$label, $note',
      excludeSemantics: true,
      builder: (context, states, _) => ConstrainedBox(
        constraints: BoxConstraints(minHeight: theme.controlHeight),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: StudioSpacing.small),
          child: Row(
            children: [
              _CheckKey(
                value: value,
                isError: isError,
                style: style,
                states: states,
              ),
              const SizedBox(width: StudioSpacing.medium),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: theme.textTheme.label.copyWith(
                        color: off ? c.disabled : c.legend,
                      ),
                    ),
                    if (note != null)
                      Text(
                        note!,
                        style: theme.textTheme.secondary.copyWith(
                          color: off ? c.disabled : c.legendMuted,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('label', label))
      ..add(FlagProperty('value', value: value, ifTrue: 'checked'))
      ..add(
        FlagProperty('enabled', value: onChanged != null, ifFalse: 'disabled'),
      );
  }
}

// A glyph that lights up and goes dark on the lamp's spring.
class _Glyph extends StatefulWidget {
  const _Glyph({required this.on, required this.painter});

  final bool on;
  final CustomPainter Function(double t) painter;

  @override
  State<_Glyph> createState() => _GlyphState();
}

class _GlyphState extends State<_Glyph> with SingleTickerProviderStateMixin {
  late final AnimationController _t = AnimationController(
    vsync: this,
    value: widget.on ? 1 : 0,
  );

  @override
  void didUpdateWidget(_Glyph old) {
    super.didUpdateWidget(old);
    if (old.on != widget.on) {
      _t.springTo(
        widget.on ? 1 : 0,
        RawMotionPolicy.of(context).effects(
          dampingRatio: StudioMotion.dampingRatio,
          stiffness: StudioMotion.lampStiffness,
        ),
      );
    }
  }

  @override
  void dispose() {
    _t.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _t,
    builder: (context, _) => CustomPaint(
      size: Size.infinite,
      painter: widget.painter(_t.value.clamp(0.0, 1.0)),
    ),
  );
}

class _CheckPainter extends CustomPainter {
  _CheckPainter({required this.t, required this.lit, required this.unlit});

  final double t;
  final Color lit;
  final Color unlit;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final o = Offset((size.width - s) / 2, (size.height - s) / 2);
    final path = Path()
      ..moveTo(o.dx + s * 0.27, o.dy + s * 0.52)
      ..lineTo(o.dx + s * 0.43, o.dy + s * 0.67)
      ..lineTo(o.dx + s * 0.74, o.dy + s * 0.35);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    // Unlit, the cap is blank; lit, the check glows.
    canvas.drawPath(path, stroke..color = Color.lerp(unlit, lit, t)!);
    if (t > 0) {
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round
          ..color = lit.withValues(alpha: 0.28 * t)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
      );
    }
  }

  @override
  bool shouldRepaint(_CheckPainter old) =>
      old.t != t || old.lit != lit || old.unlit != unlit;
}

/// A radio button: a round key that latches in when chosen, its lamp lit.
/// Choosing another in the group lets it out.
///
/// [groupValue] is the group's choice; it is chosen when that is [value].
/// A null [onChanged] disables it.
///
/// Reads [style]'s `fill` and `foreground` (the lamp's light), then
/// [StudioThemeData.radioStyle].
///
/// ```dart
/// StudioRadio<String>(value: 'mp3', groupValue: format, onChanged: (v) => setState(() => format = v), semanticLabel: 'MP3')
/// ```
class StudioRadio<T> extends StatelessWidget {
  /// A radio for [value] in a group showing [groupValue].
  const StudioRadio({
    super.key,
    required this.value,
    required this.groupValue,
    required this.onChanged,
    this.semanticLabel,
    this.focusNode,
    this.autofocus = false,
    this.style,
  });

  /// What choosing it sets.
  final T value;

  /// The group's choice.
  final T? groupValue;

  /// Called with [value] when it is chosen; null disables it.
  final ValueChanged<T>? onChanged;

  /// What a screen reader calls it, when no row names it.
  final String? semanticLabel;

  /// {@macro design.focusNode}
  final FocusNode? focusNode;

  /// {@macro design.autofocus}
  final bool autofocus;

  /// Its style, over [StudioThemeData.radioStyle].
  final StudioStyle? style;

  @override
  Widget build(BuildContext context) {
    final chosen = value == groupValue;
    return RawButton(
      onPressed: onChanged == null ? null : () => onChanged!(value),
      focusNode: focusNode,
      autofocus: autofocus,
      // A radio, not a button, as Flutter's Radio reads.
      button: false,
      checked: chosen,
      inMutuallyExclusiveGroup: true,
      semanticLabel: semanticLabel,
      builder: (context, states, _) => TapTargetPadding(
        child: _RadioKey(chosen: chosen, style: style, states: states),
      ),
    );
  }
}

// A radio's round key in [states]: [StudioRadio]'s, and each of
// [StudioRadioGroup]'s rows'.
class _RadioKey extends StatelessWidget {
  const _RadioKey({
    required this.chosen,
    required this.style,
    required this.states,
  });

  final bool chosen;
  final StudioStyle? style;
  final Set<WidgetState> states;

  @override
  Widget build(BuildContext context) {
    final theme = StudioTheme.of(context);
    final c = theme.colors;
    final layered = RawStyleOf(
      [style, theme.radioStyle],
      {...states, if (chosen) WidgetState.selected},
    );
    final disabled = states.contains(WidgetState.disabled);
    final pressed = states.contains(WidgetState.pressed);
    final face = layered.on(
      c.keyFace
          .copyWith(
            radius: 12,
            travel: chosen || pressed ? 1 : 0,
            fill: disabled ? Color.lerp(c.key, c.panelLow, 0.5) : null,
            presence: disabled ? studioUnpowered : 1,
            rim: studioLitFocus(c, states, lit: chosen && !disabled),
          )
          .backlitIf(
            c,
            chosen && !disabled,
            focused: states.contains(WidgetState.focused),
          ),
    );
    return SizedBox.square(
      dimension: StudioCheckbox.size,
      child: AnimatedStudioSurface(
        face: face,
        child: Center(
          child: StudioControlLamp(
            on: chosen && !disabled,
            color: layered.foreground,
            states: states,
          ),
        ),
      ),
    );
  }
}

/// Radios and their words, one choice of [options]: each row a round key
/// that latches in when chosen, its lamp lit, beside its words, the whole
/// row one target. Tab reaches the group once, at its choice (the first
/// choice that can be made, while none is or the chosen one is turned off);
/// the arrows choose the next or the previous (mirrored right to left) and
/// wrap, as Flutter's RadioGroup does, and Home and End choose its ends; a
/// screen reader hears a radio group of radios. A null [onChanged] disables
/// it.
///
/// Built on Flutter's RadioGroup, each row a RawRadio, with ui_core's
/// RadioGroupKeyboardFix inside the group. Reads [style] as [StudioRadio]
/// does.
///
/// ```dart
/// StudioRadioGroup<String>(options: const ['mp3', 'aac', 'wav'], value: format, labelOf: (f) => f.toUpperCase(), onChanged: (f) => setState(() => format = f))
/// ```
class StudioRadioGroup<T> extends StatelessWidget {
  /// A group of [options], [value] chosen.
  const StudioRadioGroup({
    super.key,
    required this.options,
    required this.value,
    required this.labelOf,
    required this.onChanged,
    this.isEnabled,
    this.direction = Axis.vertical,
    this.semanticLabel,
    this.style,
  });

  /// The choices, in order.
  final List<T> options;

  /// The one chosen; none when null.
  final T? value;

  /// The words beside a choice's key, which a screen reader says too.
  final String Function(T value) labelOf;

  /// Called with the choice the reader makes; null disables the group.
  final ValueChanged<T>? onChanged;

  /// Whether a choice can be made; null: all can.
  final bool Function(T value)? isEnabled;

  /// Which way the rows run, and which arrows move along them: a column
  /// by default.
  final Axis direction;

  /// What a screen reader calls the group.
  final String? semanticLabel;

  /// The keys' style, over [StudioThemeData.radioStyle].
  final StudioStyle? style;

  @override
  Widget build(BuildContext context) => _StudioRadioGroupBody<T>(group: this);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<T>('options', options))
      ..add(DiagnosticsProperty<T>('value', value))
      ..add(
        FlagProperty('enabled', value: onChanged != null, ifFalse: 'disabled'),
      );
  }
}

// StudioRadioGroup's radios, with a focus node of its own for each option so
// that Home and End can choose and focus the first or the last choice that
// can be made. Flutter's RadioGroup moves only with the arrows.
class _StudioRadioGroupBody<T> extends StatefulWidget {
  const _StudioRadioGroupBody({required this.group});

  final StudioRadioGroup<T> group;

  @override
  State<_StudioRadioGroupBody<T>> createState() =>
      _StudioRadioGroupBodyState<T>();
}

class _StudioRadioGroupBodyState<T> extends State<_StudioRadioGroupBody<T>> {
  final _nodes = <T, FocusNode>{};

  FocusNode _nodeFor(T option) => _nodes.putIfAbsent(
    option,
    () => FocusNode(debugLabel: 'StudioRadioGroup $option'),
  );

  void _toEnd({required bool last}) {
    final group = widget.group;
    final change = group.onChanged;
    if (change == null) return;
    final open = [
      for (final option in group.options)
        if (group.isEnabled?.call(option) ?? true) option,
    ];
    if (open.isEmpty) return;
    final option = last ? open.last : open.first;
    if (option != group.value) change(option);
    _nodeFor(option).requestFocus();
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
    final options = group.options;
    final value = group.value;
    final labelOf = group.labelOf;
    final direction = group.direction;
    final style = group.style;
    final current = options.toSet();
    final gone = [
      for (final option in _nodes.keys)
        if (!current.contains(option)) option,
    ];
    if (gone.isNotEmpty) {
      final nodes = [for (final option in gone) _nodes.remove(option)!];
      // The radios that held them unmount in this frame; let them go first.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        for (final node in nodes) {
          node.dispose();
        }
      });
    }
    final onChanged = group.onChanged;
    final rows = [
      for (final option in options)
        _StudioRadioRow<T>(
          key: ObjectKey(option),
          value: option,
          label: labelOf(option),
          focusNode: _nodeFor(option),
          enabled: onChanged != null && (group.isEnabled?.call(option) ?? true),
          direction: direction,
          style: style,
        ),
    ];
    final layout = direction == Axis.vertical
        ? Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: rows,
          )
        : Wrap(spacing: StudioSpacing.large, children: rows);
    final label = group.semanticLabel;
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.home): () =>
            _toEnd(last: false),
        const SingleActivator(LogicalKeyboardKey.end): () => _toEnd(last: true),
      },
      // Flutter's radio group: one Tab stop, at the choice; the arrows move
      // and choose. ui_core's keyboard fix inside it gives the group its Tab
      // stop when the chosen radio is turned off, and swaps Left and Right
      // right to left, until Flutter's own fixes do. RadioGroup takes no null
      // onChanged: a group that takes no choice turns each radio off.
      child: RadioGroup<T>(
        groupValue: value,
        onChanged: (next) {
          if (next != null && next != value) onChanged?.call(next);
        },
        child: RadioGroupKeyboardFix<T>(
          child: label == null
              ? layout
              : Semantics(label: label, child: layout),
        ),
      ),
    );
  }
}

// One row of a StudioRadioGroup: a RawRadio on the group, which says it is
// checked and one of a group and takes the tap, the focus and the keys; the
// row draws the key and the words, named by the words.
class _StudioRadioRow<T> extends StatelessWidget {
  const _StudioRadioRow({
    super.key,
    required this.value,
    required this.label,
    required this.focusNode,
    required this.enabled,
    required this.direction,
    required this.style,
  });

  final T value;
  final String label;
  final FocusNode focusNode;
  final bool enabled;
  final Axis direction;
  final StudioStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = StudioTheme.of(context);
    final c = theme.colors;
    return MergeSemantics(
      child: RawRadio<T>(
        value: value,
        mouseCursor: WidgetStateMouseCursor.clickable,
        toggleable: false,
        focusNode: focusNode,
        autofocus: false,
        groupRegistry: RadioGroup.maybeOf<T>(context),
        enabled: enabled,
        builder: (context, radio) {
          // The radio's states, and pressed while a press is down on it.
          final states = {
            ...radio.states,
            if (radio.downPosition != null) WidgetState.pressed,
          };
          final off = states.contains(WidgetState.disabled);
          return Semantics(
            label: label,
            child: ExcludeSemantics(
              // All of the row takes a press, its gaps too: RawRadio's
              // detector finds only what the face paints.
              child: Listener(
                behavior: HitTestBehavior.opaque,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: theme.controlHeight),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: StudioSpacing.small,
                    ),
                    child: Row(
                      mainAxisSize: direction == Axis.vertical
                          ? MainAxisSize.max
                          : MainAxisSize.min,
                      children: [
                        _RadioKey(
                          chosen: states.contains(WidgetState.selected),
                          style: style,
                          states: states,
                        ),
                        const SizedBox(width: StudioSpacing.medium),
                        Flexible(
                          child: Text(
                            label,
                            style: theme.textTheme.label.copyWith(
                              color: off ? c.disabled : c.legend,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// A switch: a metal cap in a dark slot, thrown from one end to the other.
/// On, the slot behind the cap lights in the indicator light. The cap can be
/// dragged; let go, it snaps to the nearer end (or the way it was flung).
///
/// A null [onChanged] disables it.
///
/// Reads [style]'s `fill` (the lit slot) and `minimumSize`, then
/// [StudioThemeData.switchStyle].
///
/// ```dart
/// StudioSwitch(value: notify, onChanged: (v) => setState(() => notify = v), semanticLabel: 'New episodes')
/// ```
class StudioSwitch extends StatefulWidget {
  /// A switch showing [value].
  const StudioSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.semanticLabel,
    this.focusNode,
    this.autofocus = false,
    this.style,
  });

  /// Whether it is on.
  final bool value;

  /// Called with the new value; null disables it.
  final ValueChanged<bool>? onChanged;

  /// What a screen reader calls it, when no row names it.
  final String? semanticLabel;

  /// {@macro design.focusNode}
  final FocusNode? focusNode;

  /// {@macro design.autofocus}
  final bool autofocus;

  /// Its style, over [StudioThemeData.switchStyle].
  final StudioStyle? style;

  /// The slot's size.
  static const Size size = Size(52, 28);

  /// The cap's size.
  static const Size capSize = Size(24, 22);

  /// The lip between the slot and the cap.
  static const double lip = 3;

  @override
  State<StudioSwitch> createState() => _StudioSwitchState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(FlagProperty('value', value: value, ifTrue: 'on', ifFalse: 'off'))
      ..add(
        FlagProperty('enabled', value: onChanged != null, ifFalse: 'disabled'),
      );
  }
}

class _StudioSwitchState extends State<StudioSwitch>
    with SingleTickerProviderStateMixin {
  late final AnimationController _at = AnimationController(
    vsync: this,
    value: widget.value ? 1 : 0,
  );
  bool _dragging = false;

  double get _throw =>
      StudioSwitch.size.width -
      2 * StudioSwitch.lip -
      StudioSwitch.capSize.width;

  @override
  void didUpdateWidget(StudioSwitch old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value && !_dragging) _go(widget.value);
  }

  void _go(bool on) {
    _at.springTo(
      on ? 1 : 0,
      RawMotionPolicy.of(context).spatial(
        dampingRatio: StudioMotion.dampingRatio,
        stiffness: StudioMotion.throwStiffness,
      ),
    );
  }

  @override
  void dispose() {
    _at.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = StudioTheme.of(context);
    final c = theme.colors;
    final enabled = widget.onChanged != null;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final light = StudioLight.of(context);
    return RawButton(
      onPressed: enabled ? () => widget.onChanged!(!widget.value) : null,
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      toggled: widget.value,
      semanticLabel: widget.semanticLabel,
      builder: (context, states, _) {
        final layered = RawStyleOf(
          [widget.style, theme.switchStyle],
          {...states, if (widget.value) WidgetState.selected},
        );
        final cue = studioControlLight(states);
        final pressed = states.contains(WidgetState.pressed);
        return TapTargetPadding(
          child: GestureDetector(
            onHorizontalDragStart: enabled
                ? (_) => setState(() => _dragging = true)
                : null,
            onHorizontalDragUpdate: enabled
                ? (d) {
                    final dx = (rtl ? -1 : 1) * d.delta.dx / _throw;
                    _at.value = (_at.value + dx).clamp(0.0, 1.0);
                  }
                : null,
            onHorizontalDragEnd: enabled
                ? (d) {
                    final v = (rtl ? -1 : 1) * d.velocity.pixelsPerSecond.dx;
                    final on = v.abs() > 200 ? v > 0 : _at.value > 0.5;
                    setState(() => _dragging = false);
                    _go(on);
                    if (on != widget.value) widget.onChanged!(on);
                  }
                : null,
            dragStartBehavior: DragStartBehavior.down,
            child: SizedBox.fromSize(
              size: StudioSwitch.size,
              child: AnimatedBuilder(
                animation: _at,
                builder: (context, _) => CustomPaint(
                  painter: _SwitchPainter(
                    at: _at.value.clamp(0.0, 1.0),
                    rtl: rtl,
                    light: light,
                    lit: layered.fill ?? c.indicator,
                    enabled: enabled,
                    pressed: pressed,
                    cue: cue,
                    capFocus: studioLitFocus(
                      c,
                      states,
                      lit: widget.value && enabled,
                    ),
                    ratio: MediaQuery.maybeDevicePixelRatioOf(context) ?? 1,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SwitchPainter extends CustomPainter {
  _SwitchPainter({
    required this.at,
    required this.rtl,
    required this.light,
    required this.lit,
    required this.enabled,
    required this.pressed,
    required this.cue,
    required this.capFocus,
    required this.ratio,
  });

  final double at;
  final bool rtl;
  final StudioLight light;
  final Color lit;
  final bool enabled;
  final bool pressed;
  final double cue;
  // An on switch's window is lit already: focus lights the cap's rim.
  final Color capFocus;
  final double ratio;

  @override
  void paint(Canvas canvas, Size size) {
    final c = light.colors;
    const lip = StudioSwitch.lip;
    final slot = Offset.zero & size;
    paintStudioFace(
      canvas,
      slot,
      StudioFace(
        fill: c.slot,
        fillLow: Color.lerp(c.slot, c.shadow, 0.3)!,
        depth: StudioDepth.sunk,
        radius: StudioRadii.small + 1,
      ),
      light,
      ratio: ratio,
    );
    // The slot is a lamp window: unlit glass when off, so an off switch
    // still shows where it stands on dark glass; at night its lip catches
    // the light as well.
    final window = RRect.fromRectAndRadius(
      slot.deflate(lip),
      const Radius.circular(StudioRadii.cap),
    );
    // By night the unlit lens is fainter, so it never reads half lit.
    final night = c.brightness == ui.Brightness.dark;
    canvas.drawRRect(
      window,
      Paint()
        ..color = c.lampOff.withValues(
          alpha: enabled ? (night ? 0.3 : 0.55) : (night ? 0.18 : 0.3),
        ),
    );
    if (c.brightness == ui.Brightness.dark) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          slot.deflate(0.5),
          const Radius.circular(StudioRadii.small + 1),
        ),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = c.edgeLight.withValues(alpha: c.edgeLight.a * 1.6),
      );
    }
    final cap = StudioSwitch.capSize;
    final travel = size.width - 2 * lip - cap.width;
    final x0 = rtl
        ? size.width - lip - cap.width - travel * at
        : lip + travel * at;
    final capRect = Rect.fromLTWH(x0, lip, cap.width, cap.height);
    // The slot uncovered behind the thrown cap lights up.
    final strength = enabled ? at : at * 0.35;
    if (strength > 0) {
      final litRect = rtl
          ? Rect.fromLTRB(
              capRect.center.dx,
              lip,
              size.width - lip,
              size.height - lip,
            )
          : Rect.fromLTRB(lip, lip, capRect.center.dx, size.height - lip);
      final rr = RRect.fromRectAndRadius(
        litRect,
        const Radius.circular(StudioRadii.cap),
      );
      canvas.drawRRect(
        rr,
        Paint()
          ..color = lit.withValues(alpha: 0.45 * strength)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
      canvas.drawRRect(
        rr.deflate(1),
        Paint()
          ..shader = ui.Gradient.linear(
            litRect.topCenter,
            litRect.bottomCenter,
            [
              Color.lerp(
                lit,
                const Color(0xFFFFFFFF),
                0.35,
              )!.withValues(alpha: strength),
              lit.withValues(alpha: strength),
            ],
          ),
      );
    }
    if (cue > 0) {
      final light = Color.lerp(lit, const Color(0xFFFFFFFF), 0.45)!;
      canvas.drawRRect(
        window,
        Paint()..color = light.withValues(alpha: cue * 0.32),
      );
    }
    // The metal cap, standing in the slot, with grip lines across it.
    paintStudioFace(
      canvas,
      capRect,
      StudioFace(
        fill: enabled ? c.cap : Color.lerp(c.cap, c.slot, 0.35)!,
        fillLow: enabled ? c.capLow : Color.lerp(c.capLow, c.slot, 0.35)!,
        depth: StudioDepth.raised,
        radius: StudioRadii.cap,
        travel: pressed ? 0.6 : 0,
        brushed: true,
        rim: capFocus,
      ),
      light,
      ratio: ratio,
    );
    final sink = pressed ? 0.6 * StudioMetrics.pressTravel : 0.0;
    final grip = Paint()..strokeWidth = 1;
    for (var i = -1; i <= 1; i++) {
      final x = capRect.center.dx + i * 4;
      canvas
        ..drawLine(
          Offset(x, capRect.top + 6 + sink),
          Offset(x, capRect.bottom - 6 + sink),
          grip..color = c.shadow.withValues(alpha: 0.35),
        )
        ..drawLine(
          Offset(x + 1, capRect.top + 6 + sink),
          Offset(x + 1, capRect.bottom - 6 + sink),
          grip..color = c.edgeLight,
        );
    }
  }

  @override
  bool shouldRepaint(_SwitchPainter old) =>
      old.at != at ||
      old.rtl != rtl ||
      old.light != light ||
      old.lit != lit ||
      old.enabled != enabled ||
      old.pressed != pressed ||
      old.cue != cue ||
      old.capFocus != capFocus ||
      old.ratio != ratio;
}

/// One key of a [StudioSegmentedButton].
@immutable
class StudioSegment<T> {
  /// A key for [value], legend [label].
  const StudioSegment({
    required this.value,
    required this.label,
    this.icon,
    this.semanticLabel,
  });

  /// What choosing it sets.
  final T value;

  /// Its legend.
  final String label;

  /// A glyph before the legend.
  final Widget? icon;

  /// What a screen reader calls it, when not its [label].
  final String? semanticLabel;
}

/// A segmented button: a bank of latching keys set in a recess, one latched
/// in at a time with its lamp lit. The keys are inset 4 px from the recess,
/// their corners concentric with its own. A screen reader hears a group of
/// radios, the latched key checked. Tab reaches the bank once, at its latched
/// key; the arrows latch the next or the previous key and wrap, as Flutter's
/// RadioGroup does, and Home and End latch its ends.
///
/// Below 600 logical pixels, the bank spans its column unless [expand]
/// overrides this. Keys make room for the system text size and wrap onto
/// additional rows when their legends no longer fit side by side.
///
/// Reads [style]'s `fill`, `foreground`, `padding`, `minimumSize` and
/// `textStyle`, then [StudioThemeData.segmentedButtonStyle].
///
/// ```dart
/// StudioSegmentedButton<double>(segments: const [StudioSegment(value: 1, label: '1×'), StudioSegment(value: 1.5, label: '1.5×')], value: speed, onChanged: (v) => setState(() => speed = v))
/// ```
class StudioSegmentedButton<T> extends StatefulWidget {
  /// A bank over [segments], [value] latched in.
  const StudioSegmentedButton({
    super.key,
    required this.segments,
    required this.value,
    required this.onChanged,
    this.expand,
    this.semanticLabel,
    this.style,
  });

  /// The keys, in order.
  final List<StudioSegment<T>> segments;

  /// The latched key's value.
  final T value;

  /// Called with the value chosen; null disables the bank.
  final ValueChanged<T>? onChanged;

  /// Whether it spans its column; null: below 600 px wide it does.
  final bool? expand;

  /// What a screen reader calls the group.
  final String? semanticLabel;

  /// Its style, over [StudioThemeData.segmentedButtonStyle].
  final StudioStyle? style;

  @override
  State<StudioSegmentedButton<T>> createState() =>
      _StudioSegmentedButtonState<T>();
}

class _StudioSegmentedButtonState<T> extends State<StudioSegmentedButton<T>> {
  final List<FocusNode> _nodes = [];

  void _fit() {
    while (_nodes.length < widget.segments.length) {
      _nodes.add(FocusNode(debugLabel: 'StudioSegment ${_nodes.length}'));
    }
    while (_nodes.length > widget.segments.length) {
      _nodes.removeLast().dispose();
    }
  }

  @override
  void dispose() {
    for (final n in _nodes) {
      n.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    assert(
      widget.segments.length >= 2,
      'A segmented button has two segments or more.',
    );
    _fit();
    final theme = StudioTheme.of(context);
    final c = theme.colors;
    final segments = widget.segments;
    final layers = [widget.style, theme.segmentedButtonStyle];
    final frame = RawStyleOf(layers, {
      if (widget.onChanged == null) WidgetState.disabled,
    });
    final words = frame.text(theme.textTheme.label);
    final height = frame.minimumSize?.height ?? theme.controlHeight;
    final scale = MediaQuery.textScalerOf(context);
    final direction = Directionality.of(context);
    final widths = <double>[];
    final horizontalPadding =
        frame.padding(direction)?.horizontal ?? 2 * StudioSpacing.small;
    for (final segment in segments) {
      final painter = TextPainter(
        text: TextSpan(
          text: segment.label,
          style: words.copyWith(fontWeight: FontWeight.w600),
        ),
        textDirection: direction,
        textScaler: scale,
        maxLines: 1,
      )..layout();
      widths.add(
        painter.width.ceilToDouble() +
            horizontalPadding +
            6 +
            StudioSpacing.small +
            2 * StudioSpacing.hair +
            (segment.icon == null
                ? 0
                : (frame.iconSize ?? 18) + StudioSpacing.tight),
      );
      painter.dispose();
    }
    final preferred = widths.reduce(math.max) + StudioSpacing.regular;
    final hugged = segments.length * preferred + 2 * StudioSpacing.hair;
    final index = segments.indexWhere((s) => s.value == widget.value);

    void move(int by) {
      final onChanged = widget.onChanged;
      if (onChanged == null) return;
      final next = (index + by).clamp(0, segments.length - 1);
      if (next == index) return;
      onChanged(segments[next].value);
      _nodes[next].requestFocus();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide =
            (widget.expand ??
                MediaQuery.sizeOf(context).width < StudioMetrics.tablet) ||
            hugged > constraints.maxWidth;
        final available = wide && constraints.hasBoundedWidth
            ? constraints.maxWidth - 2 * StudioSpacing.hair
            : hugged - 2 * StudioSpacing.hair;
        final equal = available / segments.length;
        final total = widths.fold(0.0, (sum, width) => sum + width);
        final extra = math.max(0.0, available - total) / segments.length;
        final equalFits = widths.every((width) => width <= equal);
        final bank = Semantics(
          label: widget.semanticLabel,
          container: true,
          child: SizedBox(
            width: available + 2 * StudioSpacing.hair,
            child: StudioSurface(
              face: c.recessFace,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: StudioSpacing.hair,
                ),
                // The bank's keys are one group's radios: Flutter's radio
                // group, with ui_core's keyboard fix inside it (as in
                // StudioRadioGroup). The arrows choose the next key and
                // wrap; Home and End latch the first and the last.
                child: CallbackShortcuts(
                  bindings: {
                    const SingleActivator(LogicalKeyboardKey.home): () =>
                        move(-segments.length),
                    const SingleActivator(LogicalKeyboardKey.end): () =>
                        move(segments.length),
                  },
                  child: RadioGroup<int>(
                    groupValue: index < 0 ? null : index,
                    onChanged: (i) {
                      if (i != null && i != index) {
                        widget.onChanged?.call(segments[i].value);
                      }
                    },
                    child: RadioGroupKeyboardFix<int>(
                      child: Wrap(
                        children: [
                          for (var i = 0; i < segments.length; i++)
                            _key(
                              theme,
                              i,
                              segments[i],
                              layers,
                              words,
                              equalFits
                                  ? equal
                                  : math.min(available, widths[i] + extra),
                              height,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        return wide
            ? bank
            : Align(
                alignment: AlignmentDirectional.centerStart,
                heightFactor: 1,
                child: bank,
              );
      },
    );
  }

  Widget _key(
    StudioThemeData theme,
    int i,
    StudioSegment<T> s,
    List<StudioStyle?> layers,
    TextStyle words,
    double width,
    double height,
  ) {
    final c = theme.colors;
    final chosen = s.value == widget.value;
    const inset = StudioMetrics.recessInset;
    // Half the gap each side (the recess's inset is two hairs); the bank
    // adds the other half at its ends.
    const start = StudioSpacing.hair, end = StudioSpacing.hair;
    Widget drawKey(BuildContext context, Set<WidgetState> states) {
      final layered = RawStyleOf(layers, {
        ...states,
        if (chosen) WidgetState.selected,
      });
      final disabled = states.contains(WidgetState.disabled);
      final pressed = states.contains(WidgetState.pressed);
      final ink =
          layered.foreground ??
          (disabled
              ? c.disabled
              : chosen
              ? c.litLegend
              : c.onKey);
      final face = layered.on(
        c.keyFace
            .copyWith(
              radius: StudioRadii.bank - StudioMetrics.recessInset,
              travel: chosen || pressed ? 1 : 0,
              fill: disabled ? Color.lerp(c.key, c.panelLow, 0.5) : null,
              presence: disabled ? studioUnpowered : 1,
              foreground: ink,
              focus: states.contains(WidgetState.focused)
                  ? c.focusRing
                  : c.focusRing.withValues(alpha: 0),
            )
            .backlitIf(
              c,
              chosen && !disabled,
              focused: states.contains(WidgetState.focused),
            ),
      );
      return Padding(
        padding: const EdgeInsetsDirectional.only(
          start: start,
          end: end,
          top: inset,
          bottom: inset,
        ),
        child: AnimatedStudioSurface.inBank(
          face: face,
          child: Padding(
            padding:
                layered.padding(Directionality.of(context)) ??
                const EdgeInsets.symmetric(horizontal: StudioSpacing.small),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                StudioLamp(on: chosen && !disabled, size: 6),
                const SizedBox(width: StudioSpacing.small),
                if (s.icon != null) ...[
                  IconTheme.merge(
                    data: IconThemeData(
                      size: layered.iconSize ?? 18,
                      color: ink,
                    ),
                    child: s.icon!,
                  ),
                  const SizedBox(width: StudioSpacing.tight),
                ],
                Flexible(
                  child: RawCapCenter(
                    capHeightFactor: theme.capHeightFactor,
                    child: Text(
                      s.label,
                      textAlign: TextAlign.center,
                      style: words.copyWith(
                        color: ink,
                        fontWeight: chosen ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final label = s.semanticLabel ?? s.label;
    // A radio of the bank's group: checked when latched, not a button.
    final child = Builder(
      builder: (context) => MergeSemantics(
        child: RawRadio<int>(
          value: i,
          mouseCursor: WidgetStateMouseCursor.clickable,
          toggleable: false,
          focusNode: _nodes[i],
          autofocus: false,
          groupRegistry: RadioGroup.maybeOf<int>(context),
          enabled: widget.onChanged != null,
          builder: (context, radio) => Semantics(
            label: label,
            child: ExcludeSemantics(
              // All of the key takes a press, as the face's box: RawRadio's
              // detector finds only what the face paints.
              child: Listener(
                behavior: HitTestBehavior.opaque,
                child: drawKey(context, {
                  ...radio.states,
                  if (radio.downPosition != null) WidgetState.pressed,
                }),
              ),
            ),
          ),
        ),
      ),
    );
    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: width,
        maxWidth: width,
        minHeight: height,
      ),
      child: child,
    );
  }
}
