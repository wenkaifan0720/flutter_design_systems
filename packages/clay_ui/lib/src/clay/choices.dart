/// Clay's choices: a checkbox and a radio pressed into the ground that puff
/// up in the accent when chosen, a switch's clay ball rolling in its groove,
/// a segmented groove whose choice rises out of it, and chips.
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import 'button.dart' show ClayPressDepth;
import 'fonts.dart';
import 'internal/menu.dart';
import 'internal/spring.dart';
import 'surface.dart';
import 'theme.dart';

/// A Clay checkbox: a small square well pressed into the ground; checked, it
/// puffs up into a coral volume with a dark check drawn across it. Mixed
/// shows a dash. [isError] rims it in the danger colour.
///
/// ```dart
/// ClayCheckbox(value: true, onChanged: (value) {}, semanticLabel: 'Done')
/// ```
class ClayCheckbox extends StatelessWidget {
  /// A checkbox at [value].
  const ClayCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.tristate = false,
    this.isError = false,
    this.semanticLabel,
    this.style,
    this.focusNode,
    this.autofocus = false,
  }) : assert(tristate || value != null);

  /// Whether it is checked; null is mixed, with [tristate].
  final bool? value;

  /// Called with the next value; null turns it off.
  final ValueChanged<bool?>? onChanged;

  /// Whether a press steps through mixed as well.
  final bool tristate;

  /// Whether its value is wrong: a danger rim.
  final bool isError;

  /// What a screen reader calls it, when no words beside it say.
  final String? semanticLabel;

  /// This checkbox's own style, over [ClayThemeData.checkboxStyle]: `fill`
  /// the checked clay, `foreground` the check, `minimumSize` its side.
  final ClayStyle? style;

  /// {@macro design.focusNode}
  final FocusNode? focusNode;

  /// {@macro design.autofocus}
  final bool autofocus;

  void _next() {
    onChanged?.call(switch (value) {
      false => true,
      true => tristate ? null : false,
      null => false,
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = ClayTheme.of(context);
    return DesignPressable(
      onPressed: onChanged == null ? null : _next,
      focusNode: focusNode,
      autofocus: autofocus,
      button: false,
      checked: value ?? false,
      mixed: value == null,
      isError: isError,
      semanticLabel: semanticLabel,
      builder: (context, states, _) => DesignTapTarget(
        child: ClayCheckMark(
          value: value,
          states: states,
          isError: isError,
          style: DesignStyleOf([style, theme.checkboxStyle], states),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<bool>('value', value))
      ..add(
        FlagProperty('enabled', value: onChanged != null, ifFalse: 'disabled'),
      )
      ..add(FlagProperty('tristate', value: tristate, ifTrue: 'tristate'))
      ..add(FlagProperty('isError', value: isError, ifTrue: 'error'));
  }
}

/// The checkbox's face alone, in [states] at [value], for a row or a cell
/// that is itself the control.
///
/// ```dart
/// const ClayCheckMark(value: true, states: {})
/// ```
class ClayCheckMark extends StatelessWidget {
  /// A check face at [value].
  const ClayCheckMark({
    super.key,
    required this.value,
    required this.states,
    this.isError = false,
    this.style,
  });

  /// Checked, unchecked, or mixed (null).
  final bool? value;

  /// The control's states.
  final Set<WidgetState> states;

  /// Whether its value is wrong.
  final bool isError;

  /// Its resolved style.
  final DesignStyleOf? style;

  @override
  Widget build(BuildContext context) {
    final c = ClayTheme.of(context).colors;
    final disabled = states.contains(WidgetState.disabled);
    final on = value != false;
    final side = style?.minimumSize?.width ?? 24;
    final fill = style?.fill ?? c.accent;
    final radius = math.min(ClayRadius.small - 1, side / 3);
    var face = on
        ? (disabled
              ? ClayFace.flat(c, color: c.well, radius: radius)
              : ClayFace.raised(c, color: fill, radius: radius))
        : ClayFace.well(
            c,
            color: disabled ? c.trackOff : c.track,
            radius: radius,
          );
    face = face.copyWith(
      press: states.contains(WidgetState.pressed) ? 1 : 0,
      focus: states.contains(WidgetState.focused) || isError ? 1 : 0,
      focusColor: isError ? c.danger : null,
      shadeOpacity: !on && disabled ? face.shadeOpacity * 0.4 : null,
    );
    final mark =
        style?.foreground ?? (disabled ? c.inkDisabled : c.onColor(fill));
    return SizedBox.square(
      dimension: side,
      child: AnimatedClaySurface(
        face: face,
        child: ClaySpring(
          target: on ? 1 : 0,
          damping: 1,
          stiffness: ClayMotion.liftStiffness,
          builder: (context, t) => _Cup(
            show: disabled ? 0 : 1 - t,
            rim: side * 0.13,
            radius: radius,
            child: CustomPaint(
              painter: value == null
                  ? _DashPainter(mark.withValues(alpha: t.clamp(0.0, 1.0)))
                  : ClayCheckPainter(
                      mark,
                      progress: t.clamp(0.0, 1.0),
                      stroke: side / 10,
                    ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<bool>('value', value))
      ..add(IterableProperty<WidgetState>('states', states));
  }
}

// An empty control's pale well inside its deep rim of track: the rim keeps
// 3:1 at its edge, the well keeps it from reading as a filled block. [show]
// fades it as the control fills.
class _Cup extends StatelessWidget {
  const _Cup({
    required this.show,
    required this.rim,
    required this.radius,
    required this.child,
  });

  final double show;
  final double rim;
  final double radius;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final opacity = show.clamp(0.0, 1.0);
    if (opacity < 0.01) return child;
    final c = ClayTheme.of(context).colors;
    return Stack(
      fit: StackFit.expand,
      children: [
        Padding(
          padding: EdgeInsets.all(rim),
          child: Opacity(
            opacity: opacity,
            child: ClaySurface(
              face: ClayFace.well(c, radius: math.max(0, radius - rim)),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class _DashPainter extends CustomPainter {
  _DashPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawLine(
      Offset(size.width * 0.28, size.height / 2),
      Offset(size.width * 0.72, size.height / 2),
      Paint()
        ..strokeWidth = size.width / 10
        ..strokeCap = StrokeCap.round
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_DashPainter old) => old.color != color;
}

/// A Clay radio: a round cup pressed into the ground; the chosen one holds a
/// coral ball that swells into it.
///
/// ```dart
/// ClayRadio<String>(value: 'morning', groupValue: 'morning', onChanged: (v) {}, semanticLabel: 'Morning')
/// ```
class ClayRadio<T> extends StatelessWidget {
  /// The radio for [value] in a group whose choice is [groupValue].
  const ClayRadio({
    super.key,
    required this.value,
    required this.groupValue,
    required this.onChanged,
    this.semanticLabel,
    this.style,
    this.focusNode,
    this.autofocus = false,
  });

  /// The value this radio stands for.
  final T value;

  /// The group's choice; this radio is chosen when it equals [value].
  final T? groupValue;

  /// Called with [value] when chosen; null turns it off.
  final ValueChanged<T>? onChanged;

  /// What a screen reader calls it, when no words beside it say.
  final String? semanticLabel;

  /// This radio's own style, over [ClayThemeData.radioStyle]: `fill` the
  /// ball, `minimumSize` the cup.
  final ClayStyle? style;

  /// {@macro design.focusNode}
  final FocusNode? focusNode;

  /// {@macro design.autofocus}
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final chosen = value == groupValue;
    return DesignPressable(
      onPressed: onChanged == null ? null : () => onChanged!(value),
      focusNode: focusNode,
      autofocus: autofocus,
      button: false,
      checked: chosen,
      inMutuallyExclusiveGroup: true,
      semanticLabel: semanticLabel,
      builder: (context, states, _) => DesignTapTarget(
        child: ClayRadioMark(chosen: chosen, states: states, style: style),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<T>('value', value))
      ..add(DiagnosticsProperty<T>('groupValue', groupValue))
      ..add(
        FlagProperty('enabled', value: onChanged != null, ifFalse: 'disabled'),
      );
  }
}

/// A radio's cup and ball alone, for a row that is itself the control.
///
/// ```dart
/// const ClayRadioMark(chosen: true, states: {})
/// ```
class ClayRadioMark extends StatelessWidget {
  /// A cup, its ball in when [chosen].
  const ClayRadioMark({
    super.key,
    required this.chosen,
    required this.states,
    this.style,
  });

  /// Whether the ball is in.
  final bool chosen;

  /// The control's states.
  final Set<WidgetState> states;

  /// The radio's own style, over [ClayThemeData.radioStyle].
  final ClayStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = ClayTheme.of(context);
    final c = theme.colors;
    final layered = DesignStyleOf([style, theme.radioStyle], states);
    final side = layered.minimumSize?.width ?? 24;
    final disabled = states.contains(WidgetState.disabled);
    final fill = layered.fill ?? c.accent;
    return SizedBox.square(
      dimension: side,
      child: AnimatedClaySurface(
        face:
            ClayFace.well(
              c,
              color: chosen
                  ? null
                  : disabled
                  ? c.trackOff
                  : c.track,
              radius: side / 2,
            ).copyWith(
              focus: states.contains(WidgetState.focused) ? 1 : 0,
              shadeOpacity: disabled ? 0.1 : null,
            ),
        child: ClaySpring(
          target: chosen ? 1 : 0,
          damping: 1,
          stiffness: ClayMotion.liftStiffness,
          builder: (context, t) {
            final ball = side * 0.58 * t.clamp(0.0, 1.0);
            if (ball < 1) {
              return _Cup(
                show: disabled ? 0 : 1 - t,
                rim: side * 0.13,
                radius: side / 2,
                child: const SizedBox.expand(),
              );
            }
            return Center(
              child: SizedBox.square(
                dimension: ball,
                child: ClaySurface(
                  face: disabled
                      ? ClayFace.flat(c, color: c.inkDisabled, radius: ball)
                      : ClayFace.raised(c, color: fill, radius: ball).copyWith(
                          press: states.contains(WidgetState.pressed) ? 1 : 0,
                        ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(FlagProperty('chosen', value: chosen, ifTrue: 'chosen'));
  }
}

/// Radios and their words, one choice of [options]: each row a cup beside
/// its words, the whole row one target. Tab reaches the group once, at its
/// choice (or its first that can be chosen); the arrows choose as they move,
/// round its ends and past a choice turned off, Left onward right to left;
/// Space chooses, as Flutter's RadioGroup does. A screen reader hears each
/// row as a radio, checked or not. A null [onChanged] disables it.
///
/// ```dart
/// ClayRadioGroup<String>(options: const ['morning', 'evening'], value: 'morning', labelOf: (v) => v == 'morning' ? 'Morning' : 'Evening', onChanged: (v) {})
/// ```
class ClayRadioGroup<T> extends StatelessWidget {
  /// A group of [options], [value] chosen.
  const ClayRadioGroup({
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

  /// The words beside a choice's cup, which a screen reader says too.
  final String Function(T value) labelOf;

  /// Called with the choice made; null disables the group.
  final ValueChanged<T>? onChanged;

  /// Whether a choice can be made; null: all can.
  final bool Function(T value)? isEnabled;

  /// Which way the rows run, and which arrows move along them.
  final Axis direction;

  /// What a screen reader calls the group.
  final String? semanticLabel;

  /// The cups' style, over [ClayThemeData.radioStyle].
  final ClayStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = ClayTheme.of(context);
    final c = theme.colors;
    return DesignRadioGroup<T>(
      options: options,
      value: value,
      onChanged: onChanged,
      isEnabled: isEnabled,
      semanticLabel: semanticLabel,
      direction: direction,
      layoutBuilder: (context, rows) => direction == Axis.vertical
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: rows,
            )
          : Wrap(spacing: ClaySpacing.large, children: rows),
      // Each row one radio: the cup and its words read as one, checked or
      // not, on the node the group gives it.
      itemBuilder: (context, option, node, select) => DesignPressable(
        focusNode: node,
        onPressed: select,
        semanticLabel: labelOf(option),
        excludeSemantics: true,
        checked: option == value,
        selected: option == value,
        inMutuallyExclusiveGroup: true,
        builder: (context, states, _) {
          final off = states.contains(WidgetState.disabled);
          return ConstrainedBox(
            constraints: BoxConstraints(minHeight: theme.controlHeight),
            child: Row(
              mainAxisSize: direction == Axis.vertical
                  ? MainAxisSize.max
                  : MainAxisSize.min,
              children: [
                ClayRadioMark(
                  chosen: states.contains(WidgetState.selected),
                  states: states,
                  style: style,
                ),
                const SizedBox(width: ClaySpacing.medium),
                Flexible(
                  child: Text(
                    labelOf(option),
                    style: theme.textTheme.body.copyWith(
                      color: off ? c.inkDisabled : c.ink,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

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

/// A Clay switch: a ball of white clay in a groove pressed into the ground.
/// On, the groove fills with the accent and the ball rolls to its end; it
/// can be dragged. A press squashes the ball a little.
///
/// ```dart
/// ClaySwitch(value: true, onChanged: (value) {}, semanticLabel: 'Reminders')
/// ```
class ClaySwitch extends StatefulWidget {
  /// A switch at [value].
  const ClaySwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.semanticLabel,
    this.style,
    this.focusNode,
    this.autofocus = false,
  });

  /// Whether it is on.
  final bool value;

  /// Called with the new value; null turns it off.
  final ValueChanged<bool>? onChanged;

  /// What a screen reader calls it, when no words beside it say.
  final String? semanticLabel;

  /// This switch's own style, over [ClayThemeData.switchStyle]: `fill` the
  /// groove when on, `foreground` the ball.
  final ClayStyle? style;

  /// {@macro design.focusNode}
  final FocusNode? focusNode;

  /// {@macro design.autofocus}
  final bool autofocus;

  @override
  State<ClaySwitch> createState() => _ClaySwitchState();

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

class _ClaySwitchState extends State<ClaySwitch>
    with SingleTickerProviderStateMixin {
  static const double _width = 56;
  static const double _height = 32;
  static const double _inset = 3;
  static const double _ball = _height - 2 * _inset;
  static const double _travel = _width - _ball - 2 * _inset;

  late final AnimationController _position = AnimationController.unbounded(
    vsync: this,
    value: widget.value ? 1 : 0,
  );
  bool _dragging = false;

  @override
  void didUpdateWidget(ClaySwitch old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value && !_dragging) _settle(widget.value);
  }

  void _settle(bool on) {
    _position.springTo(
      on ? 1 : 0,
      DesignMotionPolicy.of(context).spatial(
        dampingRatio: ClayMotion.slideDamping,
        stiffness: ClayMotion.slideStiffness,
      ),
    );
  }

  bool get _rtl => Directionality.of(context) == TextDirection.rtl;

  void _dragUpdate(DragUpdateDetails details) {
    final dx = details.primaryDelta ?? 0;
    _position.value = (_position.value + (_rtl ? -dx : dx) / _travel).clamp(
      0.0,
      1.0,
    );
  }

  void _dragEnd(DragEndDetails details) {
    setState(() => _dragging = false);
    final v = details.primaryVelocity ?? 0;
    final next = v.abs() > 300 ? ((v > 0) != _rtl) : _position.value > 0.5;
    if (next != widget.value) widget.onChanged?.call(next);
    _settle(next);
  }

  @override
  void dispose() {
    _position.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ClayTheme.of(context);
    final c = theme.colors;
    final enabled = widget.onChanged != null;
    return DesignPressable(
      onPressed: enabled ? () => widget.onChanged!(!widget.value) : null,
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      toggled: widget.value,
      semanticLabel: widget.semanticLabel,
      builder: (context, states, _) {
        final layered = DesignStyleOf([
          widget.style,
          theme.switchStyle,
        ], states);
        final disabled = states.contains(WidgetState.disabled);
        final pressed = states.contains(WidgetState.pressed) || _dragging;
        final focused = states.contains(WidgetState.focused);
        final onFill = layered.fill ?? c.accent;
        return DesignTapTarget(
          child: GestureDetector(
            excludeFromSemantics: true,
            onHorizontalDragStart: enabled
                ? (_) => setState(() => _dragging = true)
                : null,
            onHorizontalDragUpdate: enabled ? _dragUpdate : null,
            onHorizontalDragEnd: enabled ? _dragEnd : null,
            child: MouseRegion(
              cursor: enabled
                  ? (_dragging
                        ? SystemMouseCursors.grabbing
                        : SystemMouseCursors.click)
                  : SystemMouseCursors.basic,
              child: SizedBox(
                width: _width,
                height: _height,
                child: AnimatedBuilder(
                  animation: _position,
                  builder: (context, _) {
                    final t = _position.value.clamp(0.0, 1.0);
                    final off = ClayFace.well(
                      c,
                      color: disabled ? c.trackOff : c.track,
                      radius: _height / 2,
                    );
                    final on = ClayFace.well(
                      c,
                      color: disabled ? c.well : onFill,
                      radius: _height / 2,
                    );
                    final groove = ClayFace.lerp(off, on, t).copyWith(
                      focus: focused ? 1 : 0,
                      focusColor: t > 0.5 ? c.onColor(onFill) : c.focus,
                      shadeOpacity: disabled ? 0.1 : null,
                    );
                    final ballFill = layered.foreground ?? c.knob;
                    final ball = disabled
                        ? ClayFace.flat(c, color: c.knobDisabled, radius: _ball)
                        : ClayFace.raised(
                            c,
                            color: ballFill,
                            radius: _ball,
                          ).copyWith(
                            press: pressed ? 1 : 0,
                            // The ball's shadow takes the groove's hue as it
                            // rolls into colour.
                            shade: Color.lerp(
                              c.shadeOf(ballFill),
                              c.shadeOf(onFill),
                              t,
                            ),
                          );
                    final x = _inset + _travel * (_rtl ? 1 - t : t);
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned.fill(child: ClaySurface(face: groove)),
                        Positioned(
                          left: x,
                          top: _inset,
                          width: _ball,
                          height: _ball,
                          child: AnimatedClaySurface(face: ball),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Whether a glyph stands beside a part's words: not under large text
/// (150% and up), where the words alone carry it and keep their room.
bool _glyphsBesideWords(BuildContext context) =>
    MediaQuery.textScalerOf(context).scale(10) < 15;

/// One segment of a [ClaySegmentedButton].
@immutable
class ClaySegment<T> {
  /// A segment for [value], reading [label].
  const ClaySegment({required this.value, required this.label, this.icon});

  /// The value it stands for.
  final T value;

  /// Its words.
  final String label;

  /// A glyph before its words; under large text the words stand alone.
  final Widget? icon;
}

/// A Clay segmented button: a groove pressed into the ground holding its
/// segments; the chosen one rises out of it as a white clay thumb that
/// slides from segment to segment. Every segment is as wide as the widest.
/// It fills its row below 600 px; above, it hugs its segments. One choice of
/// several, it is a radio group: one Tab stop, on the choice; the arrows
/// choose as they move, round its ends; a screen reader hears each segment
/// as a radio, checked or not.
///
/// ```dart
/// ClaySegmentedButton<String>(segments: const [ClaySegment(value: 'week', label: 'Week'), ClaySegment(value: 'month', label: 'Month')], selected: 'week', onChanged: (value) {})
/// ```
class ClaySegmentedButton<T> extends StatelessWidget {
  /// A segmented button over [segments], [selected] chosen.
  const ClaySegmentedButton({
    super.key,
    required this.segments,
    required this.selected,
    required this.onChanged,
    this.expanded,
    this.semanticLabel,
    this.style,
  });

  /// The segments, two or more.
  final List<ClaySegment<T>> segments;

  /// The chosen segment's value.
  final T selected;

  /// Called with the value chosen; null turns it off.
  final ValueChanged<T>? onChanged;

  /// Whether it fills its row; null: below 600 px of window.
  final bool? expanded;

  /// What a screen reader calls the group.
  final String? semanticLabel;

  /// This button's own style, over [ClayThemeData.segmentedButtonStyle]:
  /// `fill` the thumb, `foreground` the chosen words.
  final ClayStyle? style;

  @override
  Widget build(BuildContext context) {
    assert(segments.length >= 2, 'A segmented button has two segments.');
    final theme = ClayTheme.of(context);
    final c = theme.colors;
    final height = theme.controlHeight;
    final fill = expanded ?? MediaQuery.sizeOf(context).width < 600;
    final index = math.max(0, segments.indexWhere((s) => s.value == selected));
    final label = theme.textTheme.label;
    final painter = TextPainter(textDirection: TextDirection.ltr);
    final glyphs = _glyphsBesideWords(context);
    var widest = 0.0;
    for (final s in segments) {
      painter.text = TextSpan(
        text: s.label,
        style: label.copyWith(
          fontWeight: FontWeight.w600,
          fontVariations: clayWeight(FontWeight.w600),
        ),
      );
      painter.layout();
      final glyph = s.icon != null && glyphs ? 28 : 0;
      widest = math.max(widest, painter.width + glyph);
    }
    painter.dispose();
    final scale = MediaQuery.textScalerOf(context).scale(1);
    final slot = widest * scale + 2 * ClaySpacing.roomy;
    const inset = 4.0;
    final enabled = onChanged != null;
    final body = LayoutBuilder(
      builder: (context, box) {
        final width = fill && box.hasBoundedWidth
            ? box.maxWidth
            : math.min(
                slot * segments.length + 2 * inset,
                box.hasBoundedWidth ? box.maxWidth : double.infinity,
              );
        final each = (width - 2 * inset) / segments.length;
        // Where side by side the widest segment's words would be cut (large
        // text, a narrow column), the segments stand one under another, the
        // thumb sliding down the groove.
        final stacked =
            segments.length > 1 &&
            each < widest * scale + 2 * ClaySpacing.small + 2;
        // Stacked, each row still takes a finger's 44.
        final row = stacked
            ? math.max(height - inset * 2, 44.0)
            : height - inset * 2;
        final rtl = Directionality.of(context) == TextDirection.rtl;
        final thumbStates = <WidgetState>{
          WidgetState.selected,
          if (!enabled) WidgetState.disabled,
        };
        final layered = DesignStyleOf([
          style,
          theme.segmentedButtonStyle,
        ], thumbStates);
        return Align(
          alignment: AlignmentDirectional.centerStart,
          widthFactor: 1,
          heightFactor: 1,
          child: SizedBox(
            width: stacked && box.hasBoundedWidth ? box.maxWidth : width,
            height: stacked ? row * segments.length + inset * 2 : height,
            child: Stack(
              children: [
                Positioned.fill(
                  child: ClaySurface(
                    face: ClayFace.well(
                      c,
                      radius: ClayRadius.control,
                    ).copyWith(shadeOpacity: enabled ? null : 0.1),
                  ),
                ),
                ClaySpring(
                  target: index.toDouble(),
                  builder: (context, t) {
                    final at = rtl ? segments.length - 1 - t : t;
                    return Positioned(
                      left: stacked ? inset : inset + at * each,
                      right: stacked ? inset : null,
                      top: stacked ? inset + t * row : inset,
                      width: stacked ? null : each,
                      height: row,
                      child: ClaySurface(
                        face: enabled
                            ? ClayFace.raised(
                                c,
                                color: layered.fill ?? c.risen,
                                radius: ClayRadius.control - inset,
                              )
                            : ClayFace.flat(
                                c,
                                radius: ClayRadius.control - inset,
                              ),
                      ),
                    );
                  },
                ),
                // The segments reach the groove's whole height (a finger's
                // 44 and more); each draws its words and rim inset like the
                // thumb.
                Positioned.fill(
                  left: inset,
                  right: inset,
                  top: stacked ? inset : 0,
                  bottom: stacked ? inset : 0,
                  child: DesignRadioGroup<T>(
                    options: [for (final s in segments) s.value],
                    value: selected,
                    onChanged: onChanged,
                    layoutBuilder: (context, items) => Flex(
                      direction: stacked ? Axis.vertical : Axis.horizontal,
                      children: [
                        for (final item in items) Expanded(child: item),
                      ],
                    ),
                    itemBuilder: (context, value, node, select) {
                      final i = segments.indexWhere((s) => s.value == value);
                      return _Segment<T>(
                        segment: segments[i],
                        chosen: i == index,
                        focusNode: node,
                        onPressed: select,
                        style: style,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    return Semantics(container: true, label: semanticLabel, child: body);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<String>('segments', segments.map((s) => s.label)))
      ..add(DiagnosticsProperty<T>('selected', selected))
      ..add(
        FlagProperty('enabled', value: onChanged != null, ifFalse: 'disabled'),
      );
  }
}

class _Segment<T> extends StatelessWidget {
  const _Segment({
    required this.segment,
    required this.chosen,
    required this.focusNode,
    required this.onPressed,
    required this.style,
  });

  final ClaySegment<T> segment;
  final bool chosen;
  final FocusNode focusNode;
  final VoidCallback? onPressed;
  final ClayStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = ClayTheme.of(context);
    final c = theme.colors;
    return DesignPressable(
      focusNode: focusNode,
      onPressed: onPressed,
      selected: chosen,
      checked: chosen,
      inMutuallyExclusiveGroup: true,
      semanticLabel: segment.label,
      excludeSemantics: true,
      builder: (context, states, _) {
        final layered = DesignStyleOf([
          style,
          theme.segmentedButtonStyle,
        ], states);
        final disabled = states.contains(WidgetState.disabled);
        final words = disabled
            ? c.inkDisabled
            : chosen
            ? (layered.foreground ?? c.ink)
            : c.inkSecondary;
        final weight = chosen ? FontWeight.w600 : FontWeight.w500;
        final focused = states.contains(WidgetState.focused);
        return DesignTapTarget(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: ClaySpacing.tight),
            child: ClayPressDepth(
              pressed: states.contains(WidgetState.pressed),
              builder: (depth) => CustomPaint(
                foregroundPainter: focused
                    ? _SegmentRim(c.focus, ClayRadius.control - 4)
                    : null,
                child: Transform.translate(
                  offset: Offset(0, depth),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: ClaySpacing.small,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (segment.icon != null &&
                              _glyphsBesideWords(context)) ...[
                            IconTheme.merge(
                              data: IconThemeData(size: 18, color: words),
                              child: segment.icon!,
                            ),
                            const SizedBox(width: ClaySpacing.small),
                          ],
                          Flexible(
                            child: DesignCapCenter(
                              capHeightFactor: clayCapHeightFactor,
                              child: Text(
                                segment.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.label.copyWith(
                                  color: words,
                                  fontWeight: weight,
                                  fontVariations: clayWeight(weight),
                                ),
                              ),
                            ),
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
      },
    );
  }
}

// A focused segment's 2 px rim, inside its slot, concentric with the thumb.
class _SegmentRim extends CustomPainter {
  _SegmentRim(this.color, this.radius);

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(1);
    canvas.drawRSuperellipse(
      RSuperellipse.fromRectAndRadius(rect, Radius.circular(radius - 1)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_SegmentRim old) =>
      old.color != color || old.radius != radius;
}

/// A Clay chip: a small pill of white clay; on, it warms toward the accent
/// and shows a check before its words. [onSelected] makes it a filter chip;
/// with [onPressed] instead it is an action chip; with [onDeleted] it shows
/// a remove key at its end.
///
/// ```dart
/// ClayChip(label: 'Morning', selected: true, onSelected: (on) {})
/// ```
class ClayChip extends StatelessWidget {
  /// A chip reading [label].
  const ClayChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onSelected,
    this.onPressed,
    this.onDeleted,
    this.icon,
    this.style,
    this.focusNode,
  });

  /// Its words.
  final String label;

  /// Whether a filter chip is on.
  final bool selected;

  /// Called with the new state of a filter chip; null with [onPressed]
  /// null turns it off.
  final ValueChanged<bool>? onSelected;

  /// Called when an action chip is pressed.
  final VoidCallback? onPressed;

  /// Called by the remove key; null shows none.
  final VoidCallback? onDeleted;

  /// A glyph before its words (an off filter chip's; on, the check stands
  /// there).
  final Widget? icon;

  /// This chip's own style, over [ClayThemeData.chipStyle].
  final ClayStyle? style;

  /// {@macro design.focusNode}
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final theme = ClayTheme.of(context);
    final c = theme.colors;
    final filter = onSelected != null;
    final action = filter ? () => onSelected!(!selected) : onPressed;
    const height = 36.0;
    return DesignPressable(
      onPressed: action,
      focusNode: focusNode,
      selected: filter && selected,
      toggled: filter ? selected : null,
      semanticLabel: label,
      excludeSemantics: true,
      builder: (context, states, _) {
        final layered = DesignStyleOf([style, theme.chipStyle], states);
        final disabled = states.contains(WidgetState.disabled);
        final on = filter && selected;
        final fill = layered.fill ?? (on ? clayChosenFill(c) : c.clay);
        var face = disabled
            ? ClayFace.flat(c, color: fill, radius: height / 2)
            : ClayFace.raised(c, color: fill, radius: height / 2);
        face = face.copyWith(
          press: states.contains(WidgetState.pressed) ? 1 : 0,
          lift: states.contains(WidgetState.hovered) ? 0.6 : 0,
          focus: states.contains(WidgetState.focused) ? 1 : 0,
        );
        final words = layered.foreground ?? (disabled ? c.inkDisabled : c.ink);
        final weight = on ? FontWeight.w600 : FontWeight.w500;
        final lead = on
            ? SizedBox.square(
                dimension: 16,
                child: CustomPaint(painter: ClayCheckPainter(words)),
              )
            : icon;
        return DesignTapTarget(
          child: SizedBox(
            height: layered.minimumSize?.height ?? height,
            child: AnimatedClaySurface(
              face: face,
              child: Padding(
                padding: EdgeInsetsDirectional.only(
                  start: lead == null
                      ? ClaySpacing.regular
                      : ClaySpacing.medium,
                  end: onDeleted == null
                      ? ClaySpacing.regular
                      : ClaySpacing.tight,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (lead != null) ...[
                      IconTheme.merge(
                        data: IconThemeData(size: 16, color: words),
                        child: lead,
                      ),
                      const SizedBox(width: ClaySpacing.small),
                    ],
                    Flexible(
                      child: DesignCapCenter(
                        capHeightFactor: clayCapHeightFactor,
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.secondary.copyWith(
                            color: words,
                            fontWeight: weight,
                            fontVariations: clayWeight(weight),
                          ),
                        ),
                      ),
                    ),
                    if (onDeleted != null)
                      _ChipRemove(
                        label: label,
                        onPressed: disabled ? null : onDeleted,
                        color: words,
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('label', label))
      ..add(FlagProperty('selected', value: selected, ifTrue: 'selected'));
  }
}

class _ChipRemove extends StatelessWidget {
  const _ChipRemove({
    required this.label,
    required this.onPressed,
    required this.color,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final words = DesignLocalizations.of(context);
    return DesignPressable(
      onPressed: onPressed,
      semanticLabel: '${words.deleteButtonTooltip} $label',
      builder: (context, states, _) => DesignTapTarget(
        child: SizedBox.square(
          dimension: 28,
          child: Center(
            child: CustomPaint(
              size: const Size.square(10),
              painter: _CrossPainter(color),
            ),
          ),
        ),
      ),
    );
  }
}

class _CrossPainter extends CustomPainter {
  _CrossPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..color = color;
    canvas
      ..drawLine(Offset.zero, Offset(size.width, size.height), p)
      ..drawLine(Offset(size.width, 0), Offset(0, size.height), p);
  }

  @override
  bool shouldRepaint(_CrossPainter old) => old.color != color;
}
