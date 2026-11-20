/// Gloss's controls for a value: the checkbox's socket, the radio's socket
/// and its bead (and [GlossRadioGroup], radios and their words, one Tab
/// stop), the switch's slot, the segmented trough and its gel thumb, the
/// stepper, the slider's groove and bead, and the latching chip.
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'fonts.dart';
import 'internal/glaze_state.dart';
import 'surface.dart';
import 'theme.dart';

/// A 0-to-1 value that springs to [target] whenever it changes: what a
/// control's moving part rides on.
class _Sprung extends StatefulWidget {
  const _Sprung({
    required this.target,
    required this.builder,
    this.damping = GlossMotion.snapDamping,
    this.stiffness = GlossMotion.snapStiffness,
  });

  final double target;
  final double damping;
  final double stiffness;
  final Widget Function(BuildContext context, double t) builder;

  @override
  State<_Sprung> createState() => _SprungState();
}

class _SprungState extends State<_Sprung> with SingleTickerProviderStateMixin {
  late final AnimationController _t = AnimationController.unbounded(
    vsync: this,
    value: widget.target,
  );

  @override
  void didUpdateWidget(_Sprung old) {
    super.didUpdateWidget(old);
    if (old.target != widget.target) {
      _t.springTo(
        widget.target,
        DesignMotionPolicy.of(context)
            .spatial(dampingRatio: widget.damping, stiffness: widget.stiffness),
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

/// A Gloss checkbox: a rounded-square socket pressed into the surface; when
/// checked, a jade gel insert fills it with a white check.
///
/// A null [onChanged] turns it off. With [tristate], a null [value] is the
/// mixed state (a bar in the insert).
///
/// ```dart
/// GlossCheckbox(value: true, onChanged: (value) {})
/// ```
class GlossCheckbox extends StatelessWidget {
  /// A checkbox at [value].
  const GlossCheckbox({
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

  /// Whether to show a warning beside the socket.
  final bool isError;

  /// What a screen reader calls it, when no words beside it say.
  final String? semanticLabel;

  /// This checkbox's own style, over [GlossThemeData.checkboxStyle].
  final GlossStyle? style;

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
    final theme = GlossTheme.of(context);
    final c = theme.colors;
    return DesignPressable(
      onPressed: onChanged == null ? null : _next,
      focusNode: focusNode,
      autofocus: autofocus,
      // A checkbox, not a button, as Flutter's Checkbox reads.
      button: false,
      checked: value ?? false,
      mixed: value == null,
      isError: isError,
      semanticLabel: semanticLabel,
      builder: (context, states, _) {
        final layered = DesignStyleOf([style, theme.checkboxStyle], states);
        final disabled = states.contains(WidgetState.disabled);
        final pressed = states.contains(WidgetState.pressed);
        final size = layered.minimumSize?.width ?? 24;
        final on = value != false;
        final socket = SizedBox.square(
          dimension: size,
          child: _Sprung(
            target: on ? 1 : 0,
            damping: GlossMotion.pressDamping,
            stiffness: GlossMotion.snapStiffness,
            builder: (context, t) => animatedGlazePaint(
              context,
              glossGlazeOf(c, states),
              (light) => _SocketPainter(
                colors: c,
                t: t,
                round: false,
                mixed: value == null,
                pressed: pressed,
                disabled: disabled,
                fill: layered.fill,
                focus: light,
                highContrast: MediaQuery.maybeHighContrastOf(context) ?? false,
              ),
            ),
          ),
        );
        return DesignTapTarget(
          child: isError
              ? FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      socket,
                      const SizedBox(width: GlossSpacing.tight),
                      Icon(LucideIcons.circleAlert, size: 14, color: c.danger),
                    ],
                  ),
                )
              : socket,
        );
      },
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
      ..add(FlagProperty('tristate', value: tristate, ifTrue: 'tristate'));
  }
}

/// A Gloss radio: a round socket; the chosen one holds a jade gel bead.
///
/// ```dart
/// GlossRadio<String>(value: 'metric', groupValue: units, onChanged: (v) {})
/// ```
class GlossRadio<T> extends StatelessWidget {
  /// The radio for [value] in a group whose choice is [groupValue].
  const GlossRadio({
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

  /// This radio's own style, over [GlossThemeData.radioStyle].
  final GlossStyle? style;

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
      // A radio, not a button, as Flutter's Radio reads.
      button: false,
      checked: chosen,
      inMutuallyExclusiveGroup: true,
      semanticLabel: semanticLabel,
      builder: (context, states, _) => DesignTapTarget(
        child: _RadioSocket(chosen: chosen, style: style, states: states),
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

// A radio's round socket in [states], its bead in when [chosen]:
// [GlossRadio]'s, and each of [GlossRadioGroup]'s rows'.
class _RadioSocket extends StatelessWidget {
  const _RadioSocket({
    required this.chosen,
    required this.style,
    required this.states,
  });

  final bool chosen;
  final GlossStyle? style;
  final Set<WidgetState> states;

  @override
  Widget build(BuildContext context) {
    final theme = GlossTheme.of(context);
    final c = theme.colors;
    final layered = DesignStyleOf([style, theme.radioStyle], states);
    final size = layered.minimumSize?.width ?? 24;
    return SizedBox.square(
      dimension: size,
      child: _Sprung(
        target: chosen ? 1 : 0,
        builder: (context, t) => animatedGlazePaint(
          context,
          glossGlazeOf(c, states),
          (light) => _SocketPainter(
            colors: c,
            t: t,
            round: true,
            mixed: false,
            pressed: states.contains(WidgetState.pressed),
            disabled: states.contains(WidgetState.disabled),
            fill: layered.fill,
            focus: light,
            highContrast: MediaQuery.maybeHighContrastOf(context) ?? false,
          ),
        ),
      ),
    );
  }
}

/// Radios and their words, one choice of [options]: each row a round socket
/// that holds the jade bead when chosen, beside its words, the whole row
/// one target. Tab reaches the group once, at its choice; the arrows choose
/// the next or the previous (mirrored right to left in a row) and wrap,
/// Home and End its ends, Space chooses, as Flutter's RadioGroup does; a
/// screen reader hears a radio group of radios. A null [onChanged]
/// disables it.
///
/// Built on ui_core's DesignRadioGroup, over Flutter's RadioGroup. Reads
/// [style] as [GlossRadio] does.
///
/// ```dart
/// GlossRadioGroup<String>(options: const ['metric', 'imperial'], value: units, labelOf: (u) => u == 'metric' ? 'Metric' : 'Imperial', onChanged: (u) {})
/// ```
class GlossRadioGroup<T> extends StatelessWidget {
  /// A group of [options], [value] chosen.
  const GlossRadioGroup({
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

  /// The words beside a choice's socket, which a screen reader says too.
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

  /// The sockets' style, over [GlossThemeData.radioStyle].
  final GlossStyle? style;

  @override
  Widget build(BuildContext context) => _GlossRadioGroupBody<T>(group: this);

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

// GlossRadioGroup's radios, with a focus node of its own for each option so
// that Home and End can choose and focus the first or the last choice that
// can be made. Flutter's RadioGroup moves only with the arrows.
class _GlossRadioGroupBody<T> extends StatefulWidget {
  const _GlossRadioGroupBody({required this.group});

  final GlossRadioGroup<T> group;

  @override
  State<_GlossRadioGroupBody<T>> createState() =>
      _GlossRadioGroupBodyState<T>();
}

class _GlossRadioGroupBodyState<T> extends State<_GlossRadioGroupBody<T>> {
  final _nodes = <T, FocusNode>{};

  FocusNode _nodeFor(T option) => _nodes.putIfAbsent(
    option,
    () => FocusNode(debugLabel: 'GlossRadioGroup $option'),
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
    final theme = GlossTheme.of(context);
    final c = theme.colors;
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
    final radios = DesignRadioGroup<T>(
      options: options,
      value: value,
      onChanged: group.onChanged,
      isEnabled: group.isEnabled,
      focusNodeFor: _nodeFor,
      semanticLabel: group.semanticLabel,
      direction: direction,
      layoutBuilder: (context, rows) => direction == Axis.vertical
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: rows,
            )
          : Wrap(spacing: GlossSpacing.regular, children: rows),
      // Each row is one radio, named by its words: the socket and the words
      // take the press together.
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
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: GlossSpacing.small),
              child: Row(
                mainAxisSize: direction == Axis.vertical
                    ? MainAxisSize.max
                    : MainAxisSize.min,
                children: [
                  _RadioSocket(
                    chosen: states.contains(WidgetState.selected),
                    style: style,
                    states: states,
                  ),
                  const SizedBox(width: GlossSpacing.medium),
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
            ),
          );
        },
      ),
    );
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.home): () =>
            _toEnd(last: false),
        const SingleActivator(LogicalKeyboardKey.end): () => _toEnd(last: true),
      },
      child: radios,
    );
  }
}

class _SocketPainter extends CustomPainter {
  _SocketPainter({
    required this.colors,
    required this.t,
    required this.round,
    required this.mixed,
    required this.pressed,
    required this.disabled,
    required this.fill,
    required this.focus,
    required this.highContrast,
  });

  final GlossColors colors;
  final double t;
  final bool round;
  final bool mixed;
  final bool pressed;
  final bool disabled;
  final Color? fill;
  final Color focus;
  final bool highContrast;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final radius = round ? null : GlossMetrics.socketRadius;
    final light = colors.brightness == Brightness.light;
    var socket = GlossFace.well(colors, radius: radius).copyWith(
      lift: disabled ? -0.5 : (pressed ? -1 : -0.85),
      // A fine rim round the socket's mouth, so an empty one (a box not
      // ticked, a dot not chosen) reads on a well's floor, day and night.
      edge: disabled
          ? (light ? const Color(0x1A000000) : const Color(0x1AFFFFFF))
          : light
          ? const Color(0x33000000)
          : const Color(0x33FFFFFF),
      focus: t < 0.01 || round ? focus : null,
      travel: pressed ? 0.7 : 0,
    );
    if (highContrast) socket = socket.copyWith(edge: colors.ink);
    paintGlossFace(
      canvas,
      rect,
      socket,
      brightness: colors.brightness,
      highContrast: highContrast,
    );
    final shown = t.clamp(0.0, 1.2);
    if (shown <= 0.01) return;
    // The insert (a checkbox) or the bead (a radio): jade gel, seated in the
    // socket, concentric with it.
    final inset = round ? 6.0 : 2.0;
    final full = rect.deflate(inset);
    final scale = round ? (0.4 + 0.6 * shown) : (0.7 + 0.3 * shown);
    final seat = Rect.fromCenter(
      center: full.center,
      width: full.width * scale,
      height: full.height * scale,
    );
    var gel = disabled
        ? GlossFace.pearlOff(colors).copyWith(lift: 0.2)
        : GlossFace.gel(
            colors,
            radius: round ? null : GlossMetrics.socketRadius - inset,
          );
    if (fill != null && !disabled) gel = gel.glazed(fill!);
    gel = gel.copyWith(
      focus: focus,
      lift: 0.35,
      radius: round ? null : (GlossMetrics.socketRadius - inset) * scale,
    );
    canvas.saveLayer(
      rect.inflate(4),
      Paint()..color = Color.fromRGBO(0, 0, 0, shown.clamp(0.0, 1.0)),
    );
    paintGlossFace(
      canvas,
      seat,
      gel,
      brightness: colors.brightness,
      highContrast: highContrast,
    );
    if (!round) {
      final mark = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = disabled ? colors.inkDisabled : colors.onJade;
      final c = seat.center;
      final s = seat.width / 16;
      if (mixed) {
        canvas.drawLine(c + Offset(-4 * s, 0), c + Offset(4 * s, 0), mark);
      } else {
        final path = Path()
          ..moveTo(c.dx - 4.2 * s, c.dy + 0.2 * s)
          ..lineTo(c.dx - 1.2 * s, c.dy + 3.2 * s)
          ..lineTo(c.dx + 4.4 * s, c.dy - 3.4 * s);
        // The check draws itself as the insert seats.
        final metric = path.computeMetrics().first;
        canvas.drawPath(
          metric.extractPath(0, metric.length * shown.clamp(0.0, 1.0)),
          mark,
        );
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_SocketPainter old) =>
      old.colors != colors ||
      old.t != t ||
      old.round != round ||
      old.mixed != mixed ||
      old.pressed != pressed ||
      old.disabled != disabled ||
      old.fill != fill ||
      old.focus != focus ||
      old.highContrast != highContrast;
}

/// A Gloss switch: a capsule slot pressed into the surface with a pearl bead
/// in it. On, the slot lights jade from inside and the bead sits at the end;
/// the bead snaps through and settles, and follows a finger dragging it.
///
/// ```dart
/// GlossSwitch(value: true, onChanged: (value) {})
/// ```
class GlossSwitch extends StatefulWidget {
  /// A switch at [value].
  const GlossSwitch({
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

  /// Called with the next value; null turns it off.
  final ValueChanged<bool>? onChanged;

  /// What a screen reader calls it, when no words beside it say.
  final String? semanticLabel;

  /// This switch's own style, over [GlossThemeData.switchStyle].
  final GlossStyle? style;

  /// {@macro design.focusNode}
  final FocusNode? focusNode;

  /// {@macro design.autofocus}
  final bool autofocus;

  @override
  State<GlossSwitch> createState() => _GlossSwitchState();

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

class _GlossSwitchState extends State<GlossSwitch>
    with SingleTickerProviderStateMixin {
  static const double _width = 52;
  static const double _height = 30;
  static const double _bead = 26;
  static const double _travel = _width - _bead - 4;

  late final AnimationController _position = AnimationController.unbounded(
    vsync: this,
    value: widget.value ? 1 : 0,
  );
  bool _dragging = false;

  @override
  void didUpdateWidget(GlossSwitch old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value && !_dragging) _settle(widget.value);
  }

  void _settle(bool on) {
    _position.springTo(
      on ? 1 : 0,
      DesignMotionPolicy.of(context).spatial(
        dampingRatio: GlossMotion.snapDamping,
        stiffness: GlossMotion.snapStiffness,
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
    _dragging = false;
    final v = details.primaryVelocity ?? 0;
    final next = v.abs() > 300 ? ((v > 0) != _rtl) : _position.value > 0.5;
    if (next != widget.value) {
      widget.onChanged?.call(next);
    }
    _settle(next);
  }

  @override
  void dispose() {
    _position.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = GlossTheme.of(context);
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
        final pressed = states.contains(WidgetState.pressed);
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
                  builder: (context, _) => animatedGlazePaint(
                    context,
                    glossGlazeOf(c, states),
                    (light) => _SwitchPainter(
                      colors: c,
                      t: _position.value,
                      rtl: _rtl,
                      pressed: pressed || _dragging,
                      disabled: disabled,
                      light: layered.fill,
                      focus: light,
                      highContrast:
                          MediaQuery.maybeHighContrastOf(context) ?? false,
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

class _SwitchPainter extends CustomPainter {
  _SwitchPainter({
    required this.colors,
    required this.t,
    required this.rtl,
    required this.pressed,
    required this.disabled,
    required this.light,
    required this.focus,
    required this.highContrast,
  });

  final GlossColors colors;
  final double t;
  final bool rtl;
  final bool pressed;
  final bool disabled;
  final Color? light;
  final Color focus;
  final bool highContrast;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final on = t.clamp(0.0, 1.0);
    final day = colors.brightness == Brightness.light;
    // The groove, pressed into the porcelain.
    paintGlossFace(
      canvas,
      rect,
      GlossFace.well(colors).copyWith(
        lift: disabled ? -0.5 : -1,
        edge: highContrast ? colors.ink : const Color(0x00000000),
      ),
      brightness: colors.brightness,
      highContrast: highContrast,
    );
    // The gel moulded into it: smoke when off, jade when on, one glossy
    // tube whose colour runs between the two as the bead travels.
    final smoke = GlossFace(
      top: day ? const Color(0xFFBCC5CE) : const Color(0xFF3C434A),
      middle: day ? const Color(0xFF9BA6B2) : const Color(0xFF2B3137),
      bottom: day ? const Color(0xFF8995A2) : const Color(0xFF22272C),
      foreground: colors.ink,
      edge: day ? const Color(0xFF6E7B88) : const Color(0xFF0C0E10),
      glow: day ? const Color(0x59FFFFFF) : const Color(0x14FFFFFF),
      shade: colors.shadow,
      lens: day ? 0.75 : 0.3,
      lift: 0,
    );
    var jade = GlossFace.gel(colors).copyWith(lift: 0, lens: 0.7);
    if (light != null) jade = jade.glazed(light!);
    var gel = GlossFace.lerp(smoke, jade, on);
    if (disabled) {
      gel = gel.copyWith(
        top: Color.lerp(gel.top, colors.page, 0.55),
        middle: Color.lerp(gel.middle, colors.page, 0.55),
        bottom: Color.lerp(gel.bottom, colors.page, 0.55),
        edge: Color.lerp(gel.edge, colors.page, 0.55),
        lens: gel.lens * 0.4,
        glow: const Color(0x00000000),
      );
    }
    paintGlossFace(
      canvas,
      rect.deflate(2),
      gel.copyWith(edge: highContrast ? colors.ink : null, focus: focus),
      brightness: colors.brightness,
      highContrast: highContrast,
    );
    // The bead.
    const bead = _GlossSwitchState._bead;
    final travel = rtl ? 1 - t : t;
    final x = 2 + travel * _GlossSwitchState._travel;
    final beadRect = Rect.fromLTWH(x, (size.height - bead) / 2, bead, bead);
    // By night the bead is the brightest thing on the gel, as by day.
    final pearl = GlossFace.pearl(colors).copyWith(
      focus: focus,
      // By night the bead a finger carries is moonlit pearl: light against
      // the dark slot, so a switch never reads as switched off for good.
      top: day ? null : const Color(0xFFD5DADF),
      middle: day ? null : const Color(0xFFBCC3CA),
      bottom: day ? null : const Color(0xFFA5ADB5),
      travel: pressed ? 0.6 : 0,
      lens: disabled ? (day ? 0.3 : 0) : (day ? null : 0.55),
      foreground: colors.ink,
    );
    // A pressed bead widens a little toward the slot's middle, as a finger
    // flattens it.
    final squeeze = pressed ? 3.0 : 0.0;
    final shaped = Rect.fromLTWH(
      beadRect.left - squeeze * travel.clamp(0.0, 1.0),
      beadRect.top,
      bead + squeeze,
      bead,
    );
    paintGlossFace(
      canvas,
      shaped,
      pearl,
      brightness: colors.brightness,
      highContrast: highContrast,
    );
  }

  @override
  bool shouldRepaint(_SwitchPainter old) =>
      old.colors != colors ||
      old.t != t ||
      old.rtl != rtl ||
      old.pressed != pressed ||
      old.disabled != disabled ||
      old.light != light ||
      old.focus != focus ||
      old.highContrast != highContrast;
}

/// One choice of a [GlossSegmentedButton].
@immutable
class GlossSegment<T> {
  /// The choice [value], shown as [label] (and [icon]).
  const GlossSegment({required this.value, required this.label, this.icon});

  /// The value it stands for.
  final T value;

  /// Its words.
  final String label;

  /// A glyph before its words.
  final IconData? icon;
}

/// A Gloss segmented control: a capsule trough pressed into the surface,
/// one equal slot per choice, and one jade gel thumb that slides to the
/// chosen slot. Labels never move; the chosen one turns white on the gel.
///
/// A screen reader hears a group of radios, the chosen one checked. Tab
/// reaches the control once, at its choice; the arrows choose the next or
/// the previous slot and wrap, as Flutter's RadioGroup does.
///
/// Below 600 px of window it fills its row; wider, it hugs its words unless
/// [expanded] says otherwise.
///
/// ```dart
/// GlossSegmentedButton<String>(segments: const [GlossSegment(value: 'day', label: 'Daily'), GlossSegment(value: 'week', label: 'Weekly')], selected: 'week', onChanged: (value) {})
/// ```
class GlossSegmentedButton<T> extends StatelessWidget {
  /// A control over [segments], [selected] chosen.
  const GlossSegmentedButton({
    super.key,
    required this.segments,
    required this.selected,
    required this.onChanged,
    this.expanded,
    this.semanticLabel,
    this.style,
  });

  /// The choices, in order.
  final List<GlossSegment<T>> segments;

  /// The chosen value.
  final T selected;

  /// Called with the value a person chooses; null turns the control off.
  final ValueChanged<T>? onChanged;

  /// Whether it fills its row; null fills below 600 px and hugs above.
  final bool? expanded;

  /// What a screen reader calls the group.
  final String? semanticLabel;

  /// This control's own style, over [GlossThemeData.segmentedButtonStyle].
  final GlossStyle? style;

  @override
  Widget build(BuildContext context) {
    assert(
      segments.length >= 2,
      'A segmented button has two segments or more.',
    );
    final theme = GlossTheme.of(context);
    final c = theme.colors;
    final height = theme.controlHeight;
    final fill = expanded ?? MediaQuery.sizeOf(context).width < 600;
    final index = math.max(0, segments.indexWhere((s) => s.value == selected));
    final label = theme.textTheme.label.copyWith(fontSize: 15);
    // Every slot as wide as the widest label needs, so the slots are equal.
    final painter = TextPainter(textDirection: TextDirection.ltr);
    var widest = 0.0;
    for (final s in segments) {
      painter.text = TextSpan(text: s.label, style: label);
      painter.layout();
      widest = math.max(widest, painter.width + (s.icon == null ? 0 : 24));
    }
    painter.dispose();
    final scale = MediaQuery.textScalerOf(context).scale(1);
    final slot = widest * scale + 2 * GlossSpacing.large;
    const inset = 3.0;
    Widget body = LayoutBuilder(
      builder: (context, box) {
        final width = fill && box.hasBoundedWidth
            ? box.maxWidth
            : math.min(
                slot * segments.length + 2 * inset,
                box.hasBoundedWidth ? box.maxWidth : double.infinity,
              );
        final each = (width - 2 * inset) / segments.length;
        final rtl = Directionality.of(context) == TextDirection.rtl;
        // A trough that hugs its slots stands at the start of a wider room
        // (a stretched column would otherwise pull it wide under its thumb).
        return Align(
          alignment: AlignmentDirectional.centerStart,
          widthFactor: 1,
          heightFactor: 1,
          child: SizedBox(
            width: width,
            height: height,
            child: Stack(
              children: [
                Positioned.fill(
                  child: GlossSurface(
                    face: GlossFace.well(c)
                        .copyWith(lift: onChanged == null ? -0.5 : -1),
                  ),
                ),
                _Sprung(
                  target: index.toDouble(),
                  damping: 0.8,
                  stiffness: 600,
                  builder: (context, t) {
                    final at = rtl ? segments.length - 1 - t : t;
                    return Positioned(
                      left: inset + at * each,
                      top: inset,
                      width: each,
                      height: height - inset * 2,
                      child: GlossSurface(
                        face: onChanged == null
                            ? GlossFace.pearlOff(c).copyWith(foreground: c.ink)
                            : GlossFace.gel(c).copyWith(lift: 0.7),
                      ),
                    );
                  },
                ),
                Positioned.fill(
                  left: inset,
                  right: inset,
                  child: DesignRadioGroup<int>(
                    options: [for (var i = 0; i < segments.length; i++) i],
                    value: index,
                    onChanged: onChanged == null
                        ? null
                        : (i) => onChanged!(segments[i].value),
                    layoutBuilder: (context, slots) => Row(
                      children: [
                        for (final slot in slots) Expanded(child: slot),
                      ],
                    ),
                    itemBuilder: (context, i, node, select) => _Segment<T>(
                      segment: segments[i],
                      chosen: i == index,
                      focusNode: node,
                      onPressed: select,
                      style: label,
                      height: height - inset * 2,
                      layered: style,
                    ),
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
    required this.height,
    required this.layered,
  });

  final GlossSegment<T> segment;
  final bool chosen;
  final FocusNode focusNode;
  final VoidCallback? onPressed;
  final TextStyle style;
  final double height;
  final GlossStyle? layered;

  @override
  Widget build(BuildContext context) {
    final theme = GlossTheme.of(context);
    final c = theme.colors;
    return DesignPressable(
      focusNode: focusNode,
      // The chosen slot keeps its focus but takes no press: it is already
      // the choice.
      onPressed: chosen ? null : onPressed,
      enabled: onPressed != null,
      // A radio of the control's group: checked when chosen, not a button.
      checked: chosen,
      inMutuallyExclusiveGroup: true,
      mouseCursor: chosen || onPressed == null
          ? SystemMouseCursors.basic
          : SystemMouseCursors.click,
      builder: (context, states, _) {
        final styles = DesignStyleOf(
          [layered, theme.segmentedButtonStyle],
          {...states, if (chosen) WidgetState.selected},
        );
        final disabled = onPressed == null;
        final colour =
            styles.foreground ??
            (disabled
                ? c.inkDisabled
                : chosen
                ? c.onJade
                : c.ink);
        final focused = states.contains(WidgetState.focused);
        final pressed = states.contains(WidgetState.pressed);
        return DesignTapTarget(
          child: GlossGlazeHighlight(
            focused: focused,
            hovered: states.contains(WidgetState.hovered),
            pressed: states.contains(WidgetState.pressed),
            inside: true,
            // On the chosen position's jade, the light of its words.
            color: chosen && !disabled ? c.onJade : null,
            child: SizedBox(
              height: height,
              child: Transform.translate(
                offset: Offset(0, pressed ? 1 : 0),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (segment.icon != null) ...[
                        Icon(segment.icon, size: 18, color: colour),
                        const SizedBox(width: GlossSpacing.tight + 2),
                      ],
                      // A word too long for its segment at a large text
                      // size is drawn a little smaller, never cut.
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: DesignCapCenter(
                            capHeightFactor: glossCapHeightFactor,
                            child: Text(
                              segment.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: style
                                  .copyWith(
                                    color: colour,
                                    shadows: chosen
                                        ? [
                                            Shadow(
                                              color: c.jadeEdge.withValues(
                                                alpha: 0.45,
                                              ),
                                              offset: const Offset(0, -1),
                                            ),
                                          ]
                                        : null,
                                  )
                                  .merge(styles.textStyle),
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
        );
      },
    );
  }
}

/// A Gloss stepper: a readout window pressed into the surface between two
/// pearl beads, minus and plus, the beads as tall as the window (the
/// control's height, or taller as the text grows). The count steps with a
/// detent; the arrow keys step it too, and a screen reader hears it as an
/// adjustable value.
///
/// ```dart
/// GlossStepper(value: 4, min: 1, max: 12, onChanged: (value) {})
/// ```
class GlossStepper extends StatelessWidget {
  /// A stepper at [value], between [min] and [max].
  const GlossStepper({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 99,
    this.step = 1,
    this.semanticLabel,
    this.format,
    this.style,
    this.focusNode,
  }) : assert(min <= max),
       assert(step > 0);

  /// The count.
  final int value;

  /// Called with the next count; null turns it off.
  final ValueChanged<int>? onChanged;

  /// The least count.
  final int min;

  /// The most count.
  final int max;

  /// How far one press moves it.
  final int step;

  /// What a screen reader calls it.
  final String? semanticLabel;

  /// How the count reads in the window (`4 servings`); its number alone when
  /// null.
  final String Function(int value)? format;

  /// This stepper's own style, over [GlossThemeData.stepperStyle].
  final GlossStyle? style;

  /// {@macro design.focusNode}
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final theme = GlossTheme.of(context);
    final c = theme.colors;
    final enabled = onChanged != null;
    void set(int next) => onChanged?.call(next.clamp(min, max));
    final words = format?.call(value) ?? '$value';
    final figure = theme.textTheme.label.copyWith(
      color: enabled ? c.ink : c.inkDisabled,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    // The beads and the window are one height: the control's, or taller as
    // the text grows.
    final line = TextPainter(
      text: TextSpan(text: words, style: figure),
      textDirection: TextDirection.ltr,
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    final height = math.max(
      theme.controlHeight,
      line.height + 2 * GlossSpacing.small,
    );
    line.dispose();
    Widget key(IconData glyph, int by) {
      final can = enabled && (by < 0 ? value > min : value < max);
      // The beads are for a finger and a pointer; the keyboard and a screen
      // reader step the count through the readout.
      return ExcludeSemantics(
        child: ExcludeFocus(
          child: DesignPressable(
            onPressed: can ? () => set(value + by) : null,
            builder: (context, states, _) => DesignTapTarget(
              child: SizedBox.square(
                dimension: height,
                child: AnimatedGlossSurface(
                  face: can
                      ? GlossFace.pearl(c).copyWith(
                          focus: glossGlazeOf(c, states),
                          travel: states.contains(WidgetState.pressed) ? 1 : 0,
                        )
                      : GlossFace.pearlOff(c),
                  child: Center(child: Icon(glyph, size: 18)),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return DesignValueHandle(
      value: value.toDouble(),
      min: min.toDouble(),
      max: math.max(min + 1, max).toDouble(),
      step: step.toDouble(),
      onChanged: enabled ? (v) => set(v.round()) : null,
      semanticLabel: semanticLabel,
      semanticFormatterCallback: (v) =>
          format?.call(v.round()) ?? '${v.round()}',
      focusNode: focusNode,
      axis: Axis.vertical,
      mouseCursor: SystemMouseCursors.basic,
      builder: (context, states) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            key(LucideIcons.minus, -step),
            const SizedBox(width: GlossSpacing.small),
            ConstrainedBox(
              constraints: BoxConstraints(minWidth: theme.controlHeight + 16),
              child: SizedBox(
                height: height,
                child: AnimatedGlossSurface(
                  face: GlossFace.well(c, radius: GlossMetrics.fieldRadius)
                      .copyWith(
                        lift: enabled ? -1 : -0.5,
                        focus: glossGlazeOf(c, states),
                      ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: GlossSpacing.medium,
                    ),
                    child: Center(
                      widthFactor: 1,
                      child: _Rolling(
                        value: value,
                        child: DesignCapCenter(
                          capHeightFactor: glossCapHeightFactor,
                          child: Text(words, maxLines: 1, style: figure),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: GlossSpacing.small),
            key(LucideIcons.plus, step),
          ],
        );
      },
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IntProperty('value', value))
      ..add(IntProperty('min', min))
      ..add(IntProperty('max', max))
      ..add(IntProperty('step', step, defaultValue: 1))
      ..add(
        FlagProperty('enabled', value: onChanged != null, ifFalse: 'disabled'),
      );
  }
}

/// The count rolling a notch when it changes, up for more, down for less.
class _Rolling extends StatefulWidget {
  const _Rolling({required this.value, required this.child});

  final int value;
  final Widget child;

  @override
  State<_Rolling> createState() => _RollingState();
}

class _RollingState extends State<_Rolling>
    with SingleTickerProviderStateMixin {
  late final AnimationController _roll = AnimationController.unbounded(
    vsync: this,
  );

  @override
  void didUpdateWidget(_Rolling old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) {
      _roll.value = widget.value > old.value ? 1 : -1;
      _roll.springTo(
        0,
        DesignMotionPolicy.of(context)
            .spatial(dampingRatio: GlossMotion.snapDamping, stiffness: 900),
      );
    }
  }

  @override
  void dispose() {
    _roll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ClipRect(
    child: AnimatedBuilder(
      animation: _roll,
      child: widget.child,
      builder: (context, child) => Opacity(
        opacity: (1 - _roll.value.abs() * 0.8).clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, _roll.value * 10),
          child: child,
        ),
      ),
    ),
  );
}

/// A Gloss slider: a groove pressed into the surface, lit jade up to the
/// value, and a pearl bead the finger carries. Keys move it by [divisions]
/// (or a hundredth), Page Up and Down by a tenth, Home and End to the ends.
///
/// ```dart
/// GlossSlider(value: 0.6, onChanged: (value) {}, semanticLabel: 'Volume')
/// ```
class GlossSlider extends StatefulWidget {
  /// A slider at [value], between [min] and [max].
  const GlossSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 1,
    this.divisions,
    this.onChangeStart,
    this.onChangeEnd,
    this.semanticLabel,
    this.semanticFormatterCallback,
    this.style,
    this.focusNode,
    this.autofocus = false,
  }) : assert(min < max),
       assert(value >= min && value <= max);

  /// The value.
  final double value;

  /// Called as the value moves; null turns it off.
  final ValueChanged<double>? onChanged;

  /// Called when a drag or a key starts to move it.
  final ValueChanged<double>? onChangeStart;

  /// Called when it comes to rest.
  final ValueChanged<double>? onChangeEnd;

  /// The least value.
  final double min;

  /// The most value.
  final double max;

  /// How many steps it moves in; null for any value.
  final int? divisions;

  /// What a screen reader calls it.
  final String? semanticLabel;

  /// How a screen reader says the value.
  final String Function(double value)? semanticFormatterCallback;

  /// This slider's own style, over [GlossThemeData.sliderStyle].
  final GlossStyle? style;

  /// {@macro design.focusNode}
  final FocusNode? focusNode;

  /// {@macro design.autofocus}
  final bool autofocus;

  @override
  State<GlossSlider> createState() => _GlossSliderState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DoubleProperty('value', value))
      ..add(DoubleProperty('min', min))
      ..add(DoubleProperty('max', max))
      ..add(IntProperty('divisions', divisions, defaultValue: null))
      ..add(
        FlagProperty('enabled', value: onChanged != null, ifFalse: 'disabled'),
      );
  }
}

class _GlossSliderState extends State<GlossSlider> {
  static const double _bead = 28;
  bool _dragging = false;

  double _snap(double v) {
    final clamped = v.clamp(widget.min, widget.max);
    final d = widget.divisions;
    if (d == null || d <= 0) return clamped;
    final unit = (widget.max - widget.min) / d;
    return widget.min + ((clamped - widget.min) / unit).round() * unit;
  }

  double _valueAt(Offset local, double width) {
    final usable = width - _bead;
    var x = ((local.dx - _bead / 2) / usable).clamp(0.0, 1.0);
    if (Directionality.of(context) == TextDirection.rtl) x = 1 - x;
    return _snap(widget.min + x * (widget.max - widget.min));
  }

  @override
  Widget build(BuildContext context) {
    final theme = GlossTheme.of(context);
    final c = theme.colors;
    final enabled = widget.onChanged != null;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final fraction = (widget.value - widget.min) / (widget.max - widget.min);
    return LayoutBuilder(
      builder: (context, box) {
        final width = box.hasBoundedWidth ? box.maxWidth : 240.0;
        final usable = width - _bead;
        void start(Offset at) {
          setState(() => _dragging = true);
          widget.onChangeStart?.call(widget.value);
          final v = _valueAt(at, width);
          if (v != widget.value) widget.onChanged?.call(v);
        }

        void end() {
          setState(() => _dragging = false);
          widget.onChangeEnd?.call(widget.value);
        }

        return SizedBox(
          width: width,
          height: 44,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            excludeFromSemantics: true,
            onHorizontalDragStart: enabled
                ? (d) => start(d.localPosition)
                : null,
            onHorizontalDragUpdate: enabled
                ? (d) {
                    final v = _valueAt(d.localPosition, width);
                    if (v != widget.value) widget.onChanged?.call(v);
                  }
                : null,
            onHorizontalDragEnd: enabled ? (_) => end() : null,
            onTapDown: enabled ? (d) => start(d.localPosition) : null,
            onTapUp: enabled ? (_) => end() : null,
            onTapCancel: enabled ? end : null,
            child: MouseRegion(
              cursor: enabled
                  ? (_dragging
                        ? SystemMouseCursors.grabbing
                        : SystemMouseCursors.click)
                  : SystemMouseCursors.basic,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: _bead / 2 - 5,
                    right: _bead / 2 - 5,
                    top: 17,
                    height: 10,
                    child: CustomPaint(
                      painter: _GroovePainter(
                        colors: c,
                        fraction: fraction,
                        rtl: rtl,
                        enabled: enabled,
                        light: DesignStyleOf([
                          widget.style,
                          theme.sliderStyle,
                        ], const {}).fill,
                        highContrast:
                            MediaQuery.maybeHighContrastOf(context) ?? false,
                      ),
                    ),
                  ),
                  PositionedDirectional(
                    start: fraction * usable,
                    top: 8,
                    child: DesignValueHandle(
                      value: widget.value,
                      min: widget.min,
                      max: widget.max,
                      divisions: widget.divisions,
                      onChanged: enabled
                          ? (v) => widget.onChanged!(_snap(v))
                          : null,
                      onChangeStart: widget.onChangeStart,
                      onChangeEnd: widget.onChangeEnd,
                      dragging: _dragging,
                      semanticLabel: widget.semanticLabel,
                      semanticFormatterCallback:
                          widget.semanticFormatterCallback,
                      focusNode: widget.focusNode,
                      autofocus: widget.autofocus,
                      minimumSize: const Size(_bead, _bead),
                      builder: (context, states) => SizedBox.square(
                        dimension: _bead,
                        child: AnimatedGlossSurface(
                          face: GlossFace.pearl(c).copyWith(
                            travel: _dragging ? 0.6 : 0,
                            lens: enabled ? null : 0.3,
                            lift: enabled ? null : 0.4,
                            focus: glossGlazeOf(c, states),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _GroovePainter extends CustomPainter {
  _GroovePainter({
    required this.colors,
    required this.fraction,
    required this.rtl,
    required this.enabled,
    required this.light,
    required this.highContrast,
  });

  final GlossColors colors;
  final double fraction;
  final bool rtl;
  final bool enabled;
  final Color? light;
  final bool highContrast;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    paintGlossFace(
      canvas,
      rect,
      GlossFace.well(colors).copyWith(
        lift: enabled ? -1 : -0.5,
        edge: highContrast ? colors.ink : const Color(0x00000000),
      ),
      highContrast: highContrast,
    );
    // The lit part, from the start to the value (the bead's centre).
    final lit = 5 + fraction * (size.width - 10);
    final litRect = rtl
        ? Rect.fromLTRB(size.width - lit, 0, size.width, size.height)
        : Rect.fromLTRB(0, 0, lit, size.height);
    var face = GlossFace.well(colors).copyWith(
      top: colors.jadeBottom,
      middle: colors.jade,
      bottom: colors.jadeTop,
      shade: const Color(0x80002814),
    );
    if (light != null) face = face.glazed(light!);
    if (!enabled) {
      face = face.copyWith(
        top: colors.inkDisabled,
        middle: colors.inkDisabled,
        bottom: colors.inkDisabled,
      );
    }
    paintGlossFace(canvas, litRect, face, highContrast: highContrast);
  }

  @override
  bool shouldRepaint(_GroovePainter old) =>
      old.colors != colors ||
      old.fraction != fraction ||
      old.rtl != rtl ||
      old.enabled != enabled ||
      old.light != light ||
      old.highContrast != highContrast;
}

/// A Gloss filter chip: a small pearl key that latches. Chosen, it stays
/// pressed in, its words and check lit jade.
///
/// ```dart
/// GlossChip(label: 'Vegetarian', selected: true, onSelected: (on) {})
/// ```
class GlossChip extends StatelessWidget {
  /// A chip reading [label].
  const GlossChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
    this.icon,
    this.style,
    this.focusNode,
  });

  /// Its words.
  final String label;

  /// Whether it is latched in.
  final bool selected;

  /// Called with the next state; null turns it off.
  final ValueChanged<bool>? onSelected;

  /// A glyph before the words, when it is not chosen.
  final Widget? icon;

  /// This chip's own style, over [GlossThemeData.chipStyle].
  final GlossStyle? style;

  /// {@macro design.focusNode}
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final theme = GlossTheme.of(context);
    final c = theme.colors;
    return DesignPressable(
      onPressed: onSelected == null ? null : () => onSelected!(!selected),
      focusNode: focusNode,
      selected: selected,
      semanticSelected: selected,
      builder: (context, states, _) {
        final layered = DesignStyleOf(
          [style, theme.chipStyle],
          {...states, if (selected) WidgetState.selected},
        );
        final disabled = states.contains(WidgetState.disabled);
        final pressed = states.contains(WidgetState.pressed);
        final colour =
            layered.foreground ??
            (disabled
                ? c.inkDisabled
                : selected
                ? c.jadeInk
                : c.ink);
        var face = selected
            ? GlossFace.well(c).copyWith(lift: pressed ? -1 : -0.8)
            : GlossFace.pearl(c).copyWith(travel: pressed ? 1 : 0);
        if (disabled) {
          face = GlossFace.pearlOff(c).copyWith(foreground: c.ink);
        }
        if (layered.fill != null) face = face.glazed(layered.fill!);
        face = face.copyWith(
          foreground: colour,
          focus: glossGlazeOf(c, states),
        );
        final height = math.max(32.0, theme.controlHeight - 12);
        // Its height is a floor: large words make the capsule taller, never
        // clipped.
        return DesignTapTarget(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: height),
            child: AnimatedGlossSurface(
              face: face,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 4,
                  horizontal: GlossSpacing.medium + 2,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _Sprung(
                      target: selected ? 1 : 0,
                      builder: (context, t) {
                        final shown = t.clamp(0.0, 1.0);
                        if (shown < 0.02 && icon == null) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsetsDirectional.only(
                            end: GlossSpacing.tight + 2,
                          ),
                          child: SizedBox(
                            width: icon == null ? 16 * shown : 16,
                            height: 16,
                            child: Opacity(
                              opacity: icon == null ? shown : 1,
                              child: IconTheme.merge(
                                data: IconThemeData(size: 16, color: colour),
                                child: shown > 0.5 || icon == null
                                    ? CustomPaint(
                                        painter: _TickPainter(colour, shown),
                                      )
                                    : icon!,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    DesignCapCenter(
                      capHeightFactor: glossCapHeightFactor,
                      child: Text(
                        label,
                        maxLines: 1,
                        style: theme.textTheme.label
                            .copyWith(fontSize: 14, color: colour)
                            .merge(layered.textStyle),
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
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('label', label))
      ..add(FlagProperty('selected', value: selected, ifTrue: 'selected'))
      ..add(
        FlagProperty('enabled', value: onSelected != null, ifFalse: 'disabled'),
      );
  }
}

class _TickPainter extends CustomPainter {
  _TickPainter(this.color, this.t);

  final Color color;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width * 0.18, size.height * 0.52)
      ..lineTo(size.width * 0.42, size.height * 0.74)
      ..lineTo(size.width * 0.84, size.height * 0.28);
    final metric = path.computeMetrics().first;
    canvas.drawPath(
      metric.extractPath(0, metric.length * t),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_TickPainter old) => old.color != color || old.t != t;
}
