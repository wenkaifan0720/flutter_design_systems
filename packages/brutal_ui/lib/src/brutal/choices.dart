/// Brutal's choices: [BrutalCheckbox], [BrutalRadio], [BrutalSwitch],
/// [BrutalSegmentedButton] and [BrutalStepper]. A chosen thing is filled with
/// ink and its mark is paper; a cell meets its neighbour on one rule.
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ui_core/ui_core.dart';

import 'surface.dart';
import 'theme.dart';

/// A 0-to-1 value that springs to each new target from where it stands: a
/// check drawing in, a thumb crossing its track.
class _Spring extends StatefulWidget {
  const _Spring({
    required this.value,
    required this.stiffness,
    required this.builder,
  });

  final double value;
  final double stiffness;
  final Widget Function(BuildContext context, double t) builder;

  @override
  State<_Spring> createState() => _SpringState();
}

class _SpringState extends State<_Spring> with SingleTickerProviderStateMixin {
  late final AnimationController _t = AnimationController(vsync: this)
    ..value = widget.value;

  @override
  void didUpdateWidget(_Spring old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) {
      _t.springTo(
        widget.value,
        DesignMotionPolicy.of(context).spatial(
          dampingRatio: BrutalMotion.dampingRatio,
          stiffness: widget.stiffness,
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
    builder: (context, _) => widget.builder(context, _t.value),
  );
}

/// A square box with a check. Checked, the box fills with ink and the check
/// is drawn in paper, stroke by stroke. Held down, the box turns over (ink
/// for paper) as a cell does under a press, so letting go lands on what it
/// showed. A null [onChanged] disables it.
///
/// Reads [style]'s `fill` (the box; selected while checked), `edge` (its
/// rule), `foreground` (the check) and `minimumSize` (the box's side), then
/// [BrutalThemeData.checkboxStyle]'s.
///
/// ```dart
/// BrutalCheckbox(value: agreed, onChanged: (value) => setState(() => agreed = value!))
/// ```
class BrutalCheckbox extends StatelessWidget {
  /// A checkbox.
  const BrutalCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.semanticLabel,
    this.isError = false,
    this.focusNode,
    this.autofocus = false,
    this.style,
  });

  /// Whether it is checked.
  final bool value;

  /// Called with the new value; null disables it.
  final ValueChanged<bool?>? onChanged;

  /// What a screen reader calls it, when no label beside it says.
  final String? semanticLabel;

  /// Whether its value is wrong (a required box left empty): the rule goes
  /// red.
  final bool isError;

  /// Its style, over [BrutalThemeData.checkboxStyle].
  final BrutalStyle? style;

  /// {@macro design.focusNode}
  final FocusNode? focusNode;

  /// {@macro design.autofocus}
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final theme = BrutalTheme.of(context);
    final c = theme.colors;
    return DesignPressable(
      onPressed: onChanged == null ? null : () => onChanged!(!value),
      focusNode: focusNode,
      autofocus: autofocus,
      checked: value,
      isError: isError,
      semanticLabel: semanticLabel,
      builder: (context, states, _) {
        final layered = DesignStyleOf(
          [style, theme.checkboxStyle],
          {
            ...states,
            if (value) WidgetState.selected,
            if (isError) WidgetState.error,
          },
        );
        final disabled = states.contains(WidgetState.disabled);
        final rule =
            layered.side?.color ??
            layered.edge ??
            (disabled
                ? c.disabled
                : isError
                ? c.danger
                : c.ink);
        // Held down, it turns over: ink for paper.
        final inked =
            value != (states.contains(WidgetState.pressed) && !disabled);
        final mark =
            layered.foreground ??
            (layered.fill != null && !disabled
                ? c.onColor(layered.fill!)
                : disabled
                ? c.surface
                : inked
                ? c.paper
                : rule);
        return DesignTapTarget(
          child: SizedBox.square(
            dimension: layered.minimumSize?.height ?? 24,
            child: AnimatedBrutalSurface(
              stiffness: BrutalMotion.colorStiffness,
              face: BrutalFace(
                fill: layered.fill ?? (inked ? rule : c.surface),
                border: rule,
                foreground: mark,
                focus: states.contains(WidgetState.focused)
                    ? c.ink
                    : c.ink.withValues(alpha: 0),
              ),
              child: _Spring(
                value: value ? 1 : 0,
                stiffness: BrutalMotion.moveStiffness,
                builder: (context, t) =>
                    CustomPaint(painter: _CheckPainter(t, mark)),
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
      ..add(FlagProperty('value', value: value, ifTrue: 'checked'))
      ..add(
        FlagProperty('enabled', value: onChanged != null, ifFalse: 'disabled'),
      );
  }
}

class _CheckPainter extends CustomPainter {
  _CheckPainter(this.t, this.color);

  final double t;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0) return;
    // A check of two straight strokes, square-capped, drawn in order.
    final a = Offset(size.width * 0.18, size.height * 0.52);
    final b = Offset(size.width * 0.42, size.height * 0.76);
    final d = Offset(size.width * 0.84, size.height * 0.26);
    final first = (b - a).distance;
    final total = first + (d - b).distance;
    final drawn = total * t;
    final path = Path()..moveTo(a.dx, a.dy);
    if (drawn <= first) {
      final p = Offset.lerp(a, b, drawn / first)!;
      path.lineTo(p.dx, p.dy);
    } else {
      path.lineTo(b.dx, b.dy);
      final p = Offset.lerp(b, d, (drawn - first) / (total - first))!;
      path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.square
        ..strokeJoin = StrokeJoin.miter
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_CheckPainter old) => old.t != t || old.color != color;
}

/// One of a set: a circle with a dot, round by meaning so it never reads as
/// a checkbox (the look's one round control). Chosen when [value] equals
/// [groupValue]. Held down, it turns over (an ink face, a paper dot), as a
/// cell does under a press. A null [onChanged] disables it.
///
/// Reads [style]'s `fill` (the face), `edge` (the ring and the dot; selected
/// while chosen) and `minimumSize` (its diameter), then
/// [BrutalThemeData.radioStyle]'s.
///
/// ```dart
/// BrutalRadio<String>(value: 'card', groupValue: method, onChanged: (value) => setState(() => method = value!))
/// ```
class BrutalRadio<T> extends StatelessWidget {
  /// A radio for [value].
  const BrutalRadio({
    super.key,
    required this.value,
    required this.groupValue,
    required this.onChanged,
    this.semanticLabel,
    this.focusNode,
    this.autofocus = false,
    this.style,
  });

  /// The value it stands for.
  final T value;

  /// The set's chosen value.
  final T? groupValue;

  /// Called with [value] when it is chosen; null disables it.
  final ValueChanged<T?>? onChanged;

  /// Its style, over [BrutalThemeData.radioStyle].
  final BrutalStyle? style;

  /// What a screen reader calls it, when no label beside it says.
  final String? semanticLabel;

  /// {@macro design.focusNode}
  final FocusNode? focusNode;

  /// {@macro design.autofocus}
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final theme = BrutalTheme.of(context);
    final c = theme.colors;
    final chosen = value == groupValue;
    return DesignPressable(
      onPressed: onChanged == null ? null : () => onChanged!(value),
      focusNode: focusNode,
      autofocus: autofocus,
      checked: chosen,
      inMutuallyExclusiveGroup: true,
      semanticLabel: semanticLabel,
      builder: (context, states, _) {
        final layered = DesignStyleOf(
          [style, theme.radioStyle],
          {...states, if (chosen) WidgetState.selected},
        );
        final disabled = states.contains(WidgetState.disabled);
        final focused = states.contains(WidgetState.focused);
        final pressed = states.contains(WidgetState.pressed) && !disabled;
        final rule =
            layered.side?.color ??
            layered.edge ??
            (disabled ? c.disabled : c.ink);
        final face = layered.fill ?? c.surface;
        return DesignTapTarget(
          child: SizedBox.square(
            dimension: layered.minimumSize?.height ?? 24,
            child: _Spring(
              value: chosen ? 1 : 0,
              stiffness: BrutalMotion.moveStiffness,
              builder: (context, t) => CustomPaint(
                painter: _RadioPainter(
                  t: t,
                  rule: rule,
                  // Held down, it turns over: an ink face, a paper dot.
                  face: pressed ? rule : face,
                  dot: pressed ? face : rule,
                  width: theme.borderWidth,
                  focus: focused ? c.ink : null,
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
      ..add(DiagnosticsProperty<T>('value', value))
      ..add(DiagnosticsProperty<T>('groupValue', groupValue))
      ..add(
        FlagProperty('enabled', value: onChanged != null, ifFalse: 'disabled'),
      );
  }
}

class _RadioPainter extends CustomPainter {
  _RadioPainter({
    required this.t,
    required this.rule,
    required this.face,
    required this.dot,
    required this.width,
    this.focus,
  });

  final double t;
  final Color rule;
  final Color face;
  final Color dot;
  final double width;
  final Color? focus;

  @override
  void paint(Canvas canvas, Size size) {
    final centre = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    canvas.drawCircle(centre, r, Paint()..color = face);
    canvas.drawCircle(
      centre,
      r - width / 2,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..color = rule,
    );
    if (t > 0) canvas.drawCircle(centre, r / 2 * t, Paint()..color = dot);
    if (focus != null) {
      canvas.drawCircle(
        centre,
        r + BrutalMetrics.focusGap + BrutalMetrics.focusWidth / 2,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = BrutalMetrics.focusWidth
          ..color = focus!,
      );
    }
  }

  @override
  bool shouldRepaint(_RadioPainter old) =>
      old.t != t ||
      old.rule != rule ||
      old.face != face ||
      old.dot != dot ||
      old.width != width ||
      old.focus != focus;
}

/// An on and off switch: a square track in the rule, a square thumb inside
/// it. On, the track fills with ink and the thumb, in paper, stands at the
/// end. The thumb slides on the look's move spring. Held down, the track
/// turns over (ink for paper) as a cell does under a press, so letting go
/// only slides the thumb. A null [onChanged] disables it.
///
/// Reads [style]'s `fill` (the track; selected while on), `edge` (its rule)
/// and `foreground` (the thumb), then [BrutalThemeData.switchStyle]'s. Its
/// size is the look's.
///
/// ```dart
/// BrutalSwitch(value: reminders, onChanged: (value) => setState(() => reminders = value))
/// ```
class BrutalSwitch extends StatelessWidget {
  /// A switch.
  const BrutalSwitch({
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

  /// Its style, over [BrutalThemeData.switchStyle].
  final BrutalStyle? style;

  /// What a screen reader calls it, when no label beside it says.
  final String? semanticLabel;

  /// {@macro design.focusNode}
  final FocusNode? focusNode;

  /// {@macro design.autofocus}
  final bool autofocus;

  /// The track's width.
  static const double trackWidth = 48;

  /// The track's height.
  static const double trackHeight = 28;

  @override
  Widget build(BuildContext context) {
    final theme = BrutalTheme.of(context);
    final c = theme.colors;
    return DesignPressable(
      onPressed: onChanged == null ? null : () => onChanged!(!value),
      focusNode: focusNode,
      autofocus: autofocus,
      toggled: value,
      semanticLabel: semanticLabel,
      builder: (context, states, _) {
        final layered = DesignStyleOf(
          [style, theme.switchStyle],
          {...states, if (value) WidgetState.selected},
        );
        final disabled = states.contains(WidgetState.disabled);
        final rule =
            layered.side?.color ??
            layered.edge ??
            (disabled ? c.disabled : c.ink);
        // Held down, it turns over: ink for paper. Letting go then only
        // slides the thumb.
        final inked =
            value != (states.contains(WidgetState.pressed) && !disabled);
        return DesignTapTarget(
          child: SizedBox(
            width: trackWidth,
            height: trackHeight,
            child: AnimatedBrutalSurface(
              stiffness: BrutalMotion.colorStiffness,
              face: BrutalFace(
                fill: layered.fill ?? (inked ? rule : c.surface),
                border: rule,
                foreground: rule,
                focus: states.contains(WidgetState.focused)
                    ? c.ink
                    : c.ink.withValues(alpha: 0),
              ),
              child: _Spring(
                value: inked ? 1 : 0,
                stiffness: BrutalMotion.colorStiffness,
                builder: (context, lit) => _Spring(
                  value: value ? 1 : 0,
                  stiffness: BrutalMotion.moveStiffness,
                  builder: (context, t) {
                    final inset = theme.borderWidth;
                    final thumb = trackHeight - 4 * theme.borderWidth;
                    return Padding(
                      padding: EdgeInsets.all(inset),
                      child: Align(
                        alignment: AlignmentDirectional(t * 2 - 1, 0),
                        child: SizedBox.square(
                          dimension: thumb,
                          child: ColoredBox(
                            color: Color.lerp(
                              rule,
                              layered.foreground ?? c.paper,
                              lit,
                            )!,
                          ),
                        ),
                      ),
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

/// One cell of a [BrutalSegmentedButton].
@immutable
class BrutalSegment<T> {
  /// The segment for [value], reading [label].
  const BrutalSegment({
    required this.value,
    required this.label,
    this.icon,
    this.semanticLabel,
  });

  /// What choosing it sets.
  final T value;

  /// What it says.
  final String label;

  /// A glyph before the words.
  final Widget? icon;

  /// What a screen reader says for it when its words do not name it alone
  /// ("Drive, 12 min" for "12 min"); null says [label].
  final String? semanticLabel;
}

/// Two to four short choices as cells of one frame, split by full-height
/// rules (a grid you can see). The chosen cell fills with ink, edge to edge;
/// every cell is the same width, and a label never moves when chosen. Below
/// 600 px it spans its column; wider, each cell takes the widest label's
/// width.
///
/// A null [onChanged] disables it. Left and Right move the choice.
///
/// Reads [style]'s `fill` and `edge` for the frame; `foreground`, `padding`,
/// `textStyle` and `iconSize` for each cell in its states; and
/// `minimumSize` (its height), then [BrutalThemeData.segmentedButtonStyle]'s.
///
/// ```dart
/// BrutalSegmentedButton<String>(segments: const [BrutalSegment(value: 'week', label: 'This week'), BrutalSegment(value: 'month', label: 'This month')], value: range, onChanged: (value) => setState(() => range = value))
/// ```
class BrutalSegmentedButton<T> extends StatelessWidget {
  /// Segments over [segments].
  const BrutalSegmentedButton({
    super.key,
    required this.segments,
    required this.value,
    required this.onChanged,
    this.expand,
    this.semanticLabel,
    this.style,
  }) : assert(segments.length >= 2);

  /// The choices, in order.
  final List<BrutalSegment<T>> segments;

  /// The chosen value.
  final T value;

  /// Called with the value chosen; null disables it.
  final ValueChanged<T>? onChanged;

  /// Whether it spans its column; null: below 600 px wide it does.
  final bool? expand;

  /// Its style, over [BrutalThemeData.segmentedButtonStyle].
  final BrutalStyle? style;

  /// What a screen reader calls the group.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = BrutalTheme.of(context);
    final c = theme.colors;
    final layers = [this.style, theme.segmentedButtonStyle];
    final frame = DesignStyleOf(layers, {
      if (onChanged == null) WidgetState.disabled,
    });
    final style = frame.text(
      theme.textTheme.label.copyWith(fontSize: 15, height: 20 / 15),
    );
    final rule =
        frame.side?.color ??
        frame.edge ??
        (onChanged == null ? c.disabled : c.ink);
    final scale = MediaQuery.textScalerOf(context);
    double widest = 0;
    for (final s in segments) {
      final painter = TextPainter(
        text: TextSpan(text: s.label, style: style),
        textDirection: TextDirection.ltr,
        textScaler: scale,
        maxLines: 1,
      )..layout();
      widest = math.max(widest, painter.width + (s.icon == null ? 0 : 28));
      painter.dispose();
    }
    final cell = widest + 2 * BrutalSpacing.regular;
    // Hugging its words only while they fit the room it has; else it fills.
    final hugged =
        segments.length * cell + (segments.length + 1) * theme.borderWidth;
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide =
            (expand ?? MediaQuery.sizeOf(context).width < 600) ||
            hugged > constraints.maxWidth;
        final index = segments.indexWhere((s) => s.value == value);

        void move(int by) {
          if (onChanged == null || segments.isEmpty) return;
          final next = (index + by).clamp(0, segments.length - 1);
          if (next != index) onChanged!(segments[next].value);
        }

        final rtl = Directionality.of(context) == TextDirection.rtl;
        final row = Row(
          mainAxisSize: wide ? MainAxisSize.max : MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (i, s) in segments.indexed) ...[
              if (i > 0)
                SizedBox(
                  width: theme.borderWidth,
                  child: ColoredBox(color: rule),
                ),
              _cell(
                context,
                theme,
                s,
                style,
                wide ? null : cell,
                move,
                rtl,
                layers,
              ),
            ],
          ],
        );
        // The frame's rule is drawn over the cells, so each cell (and the
        // target a finger or a screen reader finds) stands the control's
        // whole height.
        final control = Semantics(
          label: semanticLabel,
          container: true,
          child: SizedBox(
            height: frame.minimumSize?.height ?? theme.controlHeight,
            child: DecoratedBox(
              position: DecorationPosition.foreground,
              decoration: BoxDecoration(
                border: Border.all(color: rule, width: theme.borderWidth),
              ),
              child: ColoredBox(
                color: frame.fill ?? c.surface,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: theme.borderWidth),
                  child: row,
                ),
              ),
            ),
          ),
        );
        return wide
            ? control
            : Align(
                alignment: AlignmentDirectional.centerStart,
                heightFactor: 1,
                child: control,
              );
      },
    );
  }

  Widget _cell(
    BuildContext context,
    BrutalThemeData theme,
    BrutalSegment<T> s,
    TextStyle style,
    double? width,
    void Function(int by) move,
    bool rtl,
    List<BrutalStyle?> layers,
  ) {
    final c = theme.colors;
    final chosen = s.value == value;
    final child = DesignPressable(
      onPressed: onChanged == null ? null : () => onChanged!(s.value),
      selected: chosen,
      semanticSelected: chosen,
      inMutuallyExclusiveGroup: true,
      semanticLabel: s.semanticLabel ?? s.label,
      excludeSemantics: true,
      shortcuts: {
        const SingleActivator(LogicalKeyboardKey.arrowLeft): _MoveIntent(
          rtl ? 1 : -1,
        ),
        const SingleActivator(LogicalKeyboardKey.arrowRight): _MoveIntent(
          rtl ? -1 : 1,
        ),
        // Home and End: to the ends (the move stops there).
        const SingleActivator(LogicalKeyboardKey.home): _MoveIntent(
          -segments.length,
        ),
        const SingleActivator(LogicalKeyboardKey.end): _MoveIntent(
          segments.length,
        ),
      },
      actions: {
        _MoveIntent: CallbackAction<_MoveIntent>(
          onInvoke: (intent) {
            move(intent.by);
            return null;
          },
        ),
      },
      builder: (context, states, _) {
        final layered = DesignStyleOf(layers, states);
        final disabled = states.contains(WidgetState.disabled);
        final lit = chosen || states.contains(WidgetState.pressed);
        final words =
            layered.foreground ??
            (disabled
                ? (chosen ? c.surface : c.disabled)
                : lit
                ? c.paper
                : c.ink);
        // Inside the frame's rule, top and bottom.
        return Padding(
          padding: EdgeInsets.symmetric(vertical: theme.borderWidth),
          child: AnimatedBrutalSurface(
            stiffness: BrutalMotion.colorStiffness,
            face: BrutalFace(
              fill: lit
                  ? (disabled ? c.disabled : c.ink)
                  : c.ink.withValues(alpha: 0),
              border: c.ink.withValues(alpha: 0),
              foreground: words,
              borderWidth: 0,
            ),
            child: CustomPaint(
              foregroundPainter: states.contains(WidgetState.focused)
                  ? BrutalInsetFocusPainter(lit ? c.paper : c.ink)
                  : null,
              child: Padding(
                padding:
                    layered.padding(Directionality.of(context)) ??
                    const EdgeInsets.symmetric(horizontal: BrutalSpacing.small),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (s.icon != null) ...[
                      IconTheme.merge(
                        data: IconThemeData(size: layered.iconSize ?? 20),
                        child: s.icon!,
                      ),
                      const SizedBox(width: BrutalSpacing.small),
                    ],
                    Flexible(
                      child: DesignCapCenter(
                        capHeightFactor: BrutalTheme.of(context)
                            .capHeightFactor,
                        child: Text(
                          s.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: style.copyWith(color: words),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
    return width == null
        ? Expanded(child: child)
        : SizedBox(width: width, child: child);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<T>('value', value))
      ..add(IntProperty('segments', segments.length))
      ..add(
        FlagProperty('enabled', value: onChanged != null, ifFalse: 'disabled'),
      );
  }
}

class _MoveIntent extends Intent {
  const _MoveIntent(this.by);

  final int by;
}

/// A whole number stepped down and up: a minus cell, the number, a plus
/// cell, butted on shared rules. A cell at its bound is off. A null
/// [onChanged] disables it.
///
/// Reads [style]'s `fill` and `edge` for the frame; `foreground` and
/// `iconSize` for the cells in their states; `textStyle` for the number;
/// and `minimumSize` (its height), then [BrutalThemeData.stepperStyle]'s.
///
/// ```dart
/// BrutalStepper(value: tickets, min: 0, max: 8, onChanged: (value) => setState(() => tickets = value), semanticLabel: 'Standing tickets')
/// ```
class BrutalStepper extends StatelessWidget {
  /// A stepper between [min] and [max].
  const BrutalStepper({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 99,
    this.semanticLabel,
    this.decreaseLabel = 'Decrease',
    this.increaseLabel = 'Increase',
    this.style,
  }) : assert(min <= max),
       assert(value >= min && value <= max);

  /// The number.
  final int value;

  /// Called with the new number; null disables it.
  final ValueChanged<int>? onChanged;

  /// The least it goes to.
  final int min;

  /// The most it goes to.
  final int max;

  /// What a screen reader calls the number ("Standing tickets").
  final String? semanticLabel;

  /// What a screen reader calls the minus cell, before [semanticLabel]
  /// ("Decrease Standing tickets").
  final String decreaseLabel;

  /// What a screen reader calls the plus cell, before [semanticLabel].
  final String increaseLabel;

  /// Its style, over [BrutalThemeData.stepperStyle].
  final BrutalStyle? style;

  String _name(String verb) =>
      semanticLabel == null ? verb : '$verb $semanticLabel';

  @override
  Widget build(BuildContext context) {
    final theme = BrutalTheme.of(context);
    final c = theme.colors;
    final off = onChanged == null;
    final layers = [style, theme.stepperStyle];
    final frame = DesignStyleOf(layers, {if (off) WidgetState.disabled});
    final h = frame.minimumSize?.height ?? theme.controlHeight;
    final ruleColor =
        frame.side?.color ?? frame.edge ?? (off ? c.disabled : c.ink);
    Widget step(IconData glyph, String label, int to) {
      final can = !off && to >= min && to <= max;
      return DesignPressable(
        onPressed: can ? () => onChanged!(to) : null,
        semanticLabel: label,
        builder: (context, states, _) {
          final layered = DesignStyleOf(layers, states);
          final disabled = states.contains(WidgetState.disabled);
          final lit = states.contains(WidgetState.pressed);
          return SizedBox(
            width: h - theme.borderWidth,
            child: AnimatedBrutalSurface(
              stiffness: BrutalMotion.colorStiffness,
              face: BrutalFace(
                fill: lit ? c.ink : c.ink.withValues(alpha: 0),
                border: c.ink.withValues(alpha: 0),
                foreground:
                    layered.foreground ??
                    (disabled ? c.disabled : (lit ? c.paper : c.ink)),
                borderWidth: 0,
              ),
              child: CustomPaint(
                foregroundPainter: states.contains(WidgetState.focused)
                    ? BrutalInsetFocusPainter(lit ? c.paper : c.ink)
                    : null,
                child: Center(child: Icon(glyph, size: layered.iconSize ?? 20)),
              ),
            ),
          );
        },
      );
    }

    Widget rule() => SizedBox(
      width: theme.borderWidth,
      child: ColoredBox(color: ruleColor),
    );

    return Align(
      alignment: AlignmentDirectional.centerStart,
      widthFactor: 1,
      heightFactor: 1,
      child: SizedBox(
        height: h,
        child: BrutalSurface(
          face: BrutalFace(
            fill: frame.fill ?? c.surface,
            border: ruleColor,
            foreground: c.ink,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              step(LucideIcons.minus, _name(decreaseLabel), value - 1),
              rule(),
              Semantics(
                label: semanticLabel,
                value: '$value',
                child: SizedBox(
                  width: 48,
                  child: Center(
                    child: DesignCapCenter(
                      capHeightFactor: BrutalTheme.of(context).capHeightFactor,
                      child: Text(
                        '$value',
                        style: frame.text(
                          theme.textTheme.label.copyWith(
                            color: off ? c.disabled : c.ink,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              rule(),
              step(LucideIcons.plus, _name(increaseLabel), value + 1),
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
      ..add(IntProperty('value', value))
      ..add(IntProperty('min', min))
      ..add(IntProperty('max', max));
  }
}
