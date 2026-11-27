/// Studio's physical controls: [StudioFader] (a slider: a metal cap riding a
/// dark slot, the slot lit up to it), [StudioKnob] (a knurled rotary with a
/// lit pointer and detents) and [StudioMeter] (a column of lit segments).
library;

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import 'surface.dart';
import 'theme.dart';

// A value control's keyboard: the arrows step it, Page Up and Down by a
// tenth, Home and End to its ends.
class _StepIntent extends Intent {
  const _StepIntent(this.by, {this.toEnd = false});

  final double by;
  final bool toEnd;
}

Map<ShortcutActivator, Intent> _stepKeys(bool rtl, Axis axis) => {
  SingleActivator(
    axis == Axis.vertical
        ? LogicalKeyboardKey.arrowDown
        : (rtl ? LogicalKeyboardKey.arrowRight : LogicalKeyboardKey.arrowLeft),
  ): const _StepIntent(
    -1,
  ),
  SingleActivator(
    axis == Axis.vertical
        ? LogicalKeyboardKey.arrowUp
        : (rtl ? LogicalKeyboardKey.arrowLeft : LogicalKeyboardKey.arrowRight),
  ): const _StepIntent(
    1,
  ),
  if (axis == Axis.horizontal) ...{
    const SingleActivator(LogicalKeyboardKey.arrowDown): const _StepIntent(-1),
    const SingleActivator(LogicalKeyboardKey.arrowUp): const _StepIntent(1),
  } else ...{
    SingleActivator(
      rtl ? LogicalKeyboardKey.arrowRight : LogicalKeyboardKey.arrowLeft,
    ): const _StepIntent(
      -1,
    ),
    SingleActivator(
      rtl ? LogicalKeyboardKey.arrowLeft : LogicalKeyboardKey.arrowRight,
    ): const _StepIntent(
      1,
    ),
  },
  const SingleActivator(LogicalKeyboardKey.pageDown): const _StepIntent(-10),
  const SingleActivator(LogicalKeyboardKey.pageUp): const _StepIntent(10),
  const SingleActivator(LogicalKeyboardKey.home): const _StepIntent(
    -1,
    toEnd: true,
  ),
  const SingleActivator(LogicalKeyboardKey.end): const _StepIntent(
    1,
    toEnd: true,
  ),
};

/// A fader: a metal cap with an index line riding a dark slot, the slot lit
/// in the indicator light from its start up to the cap, engraved ticks beside
/// it. Drag the cap or press anywhere along the slot; the arrows step it.
/// Horizontal it is a scrubber or a level; [axis] vertical stands it up as a
/// mixing desk's fader, its start at the bottom.
///
/// [value] stands between [min] and [max]; [divisions] gives it steps (and
/// its ticks). A null [onChanged] disables it. [semanticFormatter] says the
/// value to a screen reader ("1 minute 24 seconds", "-6 dB").
///
/// Reads [style]'s `fill` (the lit slot) and `minimumSize` (its thickness),
/// then [StudioThemeData.faderStyle].
///
/// ```dart
/// StudioFader(value: position, max: length, onChanged: (v) => seek(v), semanticLabel: 'Position')
/// ```
class StudioFader extends StatefulWidget {
  /// A fader showing [value].
  const StudioFader({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 1,
    this.divisions,
    this.axis = Axis.horizontal,
    this.ticks,
    this.onChangeStart,
    this.onChangeEnd,
    this.semanticLabel,
    this.semanticFormatter,
    this.focusNode,
    this.autofocus = false,
    this.style,
  }) : assert(min < max),
       assert(divisions == null || divisions > 0);

  /// Where it stands.
  final double value;

  /// Called as it moves; null disables it.
  final ValueChanged<double>? onChanged;

  /// Called as a drag starts.
  final ValueChanged<double>? onChangeStart;

  /// Called as a drag ends.
  final ValueChanged<double>? onChangeEnd;

  /// Its least value.
  final double min;

  /// Its greatest value.
  final double max;

  /// How many steps it moves in; null for any value.
  final int? divisions;

  /// Which way it runs.
  final Axis axis;

  /// How many tick marks it is engraved with; by default its [divisions]
  /// (up to 20), else 10.
  final int? ticks;

  /// What a screen reader calls it.
  final String? semanticLabel;

  /// How a screen reader says a value.
  final String Function(double value)? semanticFormatter;

  /// {@macro design.focusNode}
  final FocusNode? focusNode;

  /// {@macro design.autofocus}
  final bool autofocus;

  /// Its style, over [StudioThemeData.faderStyle].
  final StudioStyle? style;

  /// The slot's thickness.
  static const double slot = 6;

  /// The cap along and across the slot, horizontal.
  static const Size cap = Size(18, 30);

  @override
  State<StudioFader> createState() => _StudioFaderState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DoubleProperty('value', value))
      ..add(DoubleProperty('min', min))
      ..add(DoubleProperty('max', max))
      ..add(EnumProperty<Axis>('axis', axis))
      ..add(
        FlagProperty('enabled', value: onChanged != null, ifFalse: 'disabled'),
      );
  }
}

class _StudioFaderState extends State<StudioFader> {
  bool _focused = false;
  // Focus shows as ui_core's parts show it: after a key, not after a click
  // or a drag, and for a Tab after a mouse that came before any other input
  // (a trackpad on an iPad), which leaves the detector's highlight stale.
  late final RawFocusShown _focusShown = RawFocusShown((on) {
    if (mounted) setState(() => _focused = on);
  });

  @override
  void dispose() {
    _focusShown.dispose();
    super.dispose();
  }

  bool _hovered = false;
  bool _held = false;

  double get _t =>
      ((widget.value - widget.min) / (widget.max - widget.min)).clamp(0.0, 1.0);

  double _snap(double v) {
    final d = widget.divisions;
    final c = v.clamp(widget.min, widget.max);
    if (d == null) return c;
    final step = (widget.max - widget.min) / d;
    return widget.min + ((c - widget.min) / step).round() * step;
  }

  double get _step {
    final d = widget.divisions;
    return (widget.max - widget.min) / (d ?? 20);
  }

  void _set(double v) {
    final next = _snap(v);
    if (next != widget.value) widget.onChanged?.call(next);
  }

  double _valueAt(Offset local, Size size, bool rtl) {
    final along = widget.axis == Axis.horizontal;
    final capLen = StudioFader.cap.width;
    final length = (along ? size.width : size.height) - capLen;
    var p = ((along ? local.dx : local.dy) - capLen / 2) / length;
    if (along && rtl) p = 1 - p;
    if (!along) p = 1 - p;
    return widget.min + p.clamp(0.0, 1.0) * (widget.max - widget.min);
  }

  String _say(double v) =>
      widget.semanticFormatter?.call(v) ??
      '${(100 * (v - widget.min) / (widget.max - widget.min)).round()}%';

  @override
  Widget build(BuildContext context) {
    final theme = StudioTheme.of(context);
    final c = theme.colors;
    final enabled = widget.onChanged != null;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final layered = RawStyleOf(
      [widget.style, theme.faderStyle],
      {
        if (!enabled) WidgetState.disabled,
        if (_focused) WidgetState.focused,
        if (_hovered) WidgetState.hovered,
        if (_held) WidgetState.pressed,
      },
    );
    final thickness = math.max(
      layered.minimumSize?.height ?? theme.controlHeight,
      StudioFader.cap.height + 4,
    );
    final along = widget.axis == Axis.horizontal;
    final ticks = widget.ticks ?? math.min(widget.divisions ?? 10, 20);
    final next = _snap(widget.value + _step);
    final prev = _snap(widget.value - _step);
    final face = CustomPaint(
      painter: _FaderPainter(
        t: _t,
        axis: widget.axis,
        rtl: rtl,
        light: StudioLight.of(context),
        lit: layered.fill ?? c.lightInDark,
        enabled: enabled,
        held: _held,
        ticks: ticks,
        indexColor: !enabled
            ? c.disabled
            : Color.lerp(
                c.legend,
                layered.fill ?? c.indicator,
                _focused
                    ? 0.85
                    : _hovered
                    ? 0.14
                    : 0,
              )!,
        ratio: MediaQuery.maybeDevicePixelRatioOf(context) ?? 1,
      ),
      child: along
          ? SizedBox(height: thickness, width: double.infinity)
          : SizedBox(width: thickness, height: double.infinity),
    );
    // The drawn fader, under the hands that move it. (A builder closes over
    // a variable, not its value: never reassign one a builder reads.)
    final fader = LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        void at(Offset p) => _set(_valueAt(p, size, rtl));
        void hold(bool on) {
          if (_held != on) setState(() => _held = on);
        }

        // A finger on the fader holds its cap at once, before it moves.
        return Listener(
          onPointerDown: enabled ? (_) => hold(true) : null,
          onPointerUp: (_) => hold(false),
          onPointerCancel: (_) => hold(false),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            dragStartBehavior: DragStartBehavior.down,
            onTapDown: enabled ? (d) => at(d.localPosition) : null,
            onHorizontalDragStart: enabled && along
                ? (d) {
                    setState(() => _held = true);
                    widget.onChangeStart?.call(widget.value);
                    at(d.localPosition);
                  }
                : null,
            onHorizontalDragUpdate: enabled && along
                ? (d) => at(d.localPosition)
                : null,
            onHorizontalDragEnd: enabled && along
                ? (_) {
                    setState(() => _held = false);
                    widget.onChangeEnd?.call(widget.value);
                  }
                : null,
            onVerticalDragStart: enabled && !along
                ? (d) {
                    setState(() => _held = true);
                    widget.onChangeStart?.call(widget.value);
                    at(d.localPosition);
                  }
                : null,
            onVerticalDragUpdate: enabled && !along
                ? (d) => at(d.localPosition)
                : null,
            onVerticalDragEnd: enabled && !along
                ? (_) {
                    setState(() => _held = false);
                    widget.onChangeEnd?.call(widget.value);
                  }
                : null,
            child: face,
          ),
        );
      },
    );
    return Semantics(
      slider: true,
      enabled: enabled,
      label: widget.semanticLabel,
      value: _say(widget.value),
      increasedValue: enabled ? _say(next) : null,
      decreasedValue: enabled ? _say(prev) : null,
      onIncrease: enabled ? () => _set(next) : null,
      onDecrease: enabled ? () => _set(prev) : null,
      child: FocusableActionDetector(
        enabled: enabled,
        focusNode: widget.focusNode,
        autofocus: widget.autofocus,
        mouseCursor: enabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        onShowHoverHighlight: (v) => setState(() => _hovered = v),
        onFocusChange: _focusShown.focused,
        shortcuts: _stepKeys(rtl, widget.axis),
        actions: {
          _StepIntent: CallbackAction<_StepIntent>(
            onInvoke: (i) {
              if (i.toEnd) {
                _set(i.by < 0 ? widget.min : widget.max);
              } else {
                _set(widget.value + i.by * _step);
              }
              return null;
            },
          ),
        },
        child: ExcludeSemantics(child: fader),
      ),
    );
  }
}

class _FaderPainter extends CustomPainter {
  _FaderPainter({
    required this.t,
    required this.axis,
    required this.rtl,
    required this.light,
    required this.lit,
    required this.enabled,
    required this.held,
    required this.ticks,
    required this.indexColor,
    required this.ratio,
  });

  final double t;
  final Axis axis;
  final bool rtl;
  final StudioLight light;
  final Color lit;
  final bool enabled;
  final bool held;
  final int ticks;
  final Color indexColor;
  final double ratio;

  @override
  void paint(Canvas canvas, Size size) {
    final c = light.colors;
    final along = axis == Axis.horizontal;
    // Work in the fader's own frame: x along the slot, y across it.
    canvas.save();
    if (!along) {
      canvas
        ..translate(0, size.height)
        ..rotate(-math.pi / 2);
    } else if (rtl) {
      canvas
        ..translate(size.width, 0)
        ..scale(-1, 1);
    }
    final length = along ? size.width : size.height;
    final across = along ? size.height : size.width;
    final cap = StudioFader.cap;
    final run = length - cap.width;
    final mid = across / 2;
    // Ticks engraved below the slot (to its side, standing up).
    final tickPaint = Paint()..strokeWidth = 1;
    for (var i = 0; i <= ticks; i++) {
      final x = cap.width / 2 + run * i / ticks;
      final major = i == 0 || i == ticks || i * 2 == ticks;
      final y0 = mid + cap.height / 2 - 1;
      final y1 = y0 - (major ? 7 : 4);
      canvas
        ..drawLine(Offset(x, y1), Offset(x, y0), tickPaint..color = c.groove)
        ..drawLine(
          Offset(x + 1, y1),
          Offset(x + 1, y0),
          tickPaint..color = c.edgeLight,
        );
    }
    final slot = Rect.fromLTWH(
      cap.width / 2 - StudioFader.slot / 2,
      mid - StudioFader.slot / 2,
      run + StudioFader.slot,
      StudioFader.slot,
    );
    paintStudioFace(
      canvas,
      slot,
      StudioFace(
        fill: c.slot,
        fillLow: Color.lerp(c.slot, c.shadow, 0.3)!,
        depth: StudioDepth.sunk,
        radius: StudioFader.slot / 2,
      ),
      light,
      ratio: ratio,
    );
    final x = cap.width / 2 + run * t;
    if (t > 0) {
      final litRect = Rect.fromLTRB(
        slot.left + 1,
        slot.top + 1,
        x,
        slot.bottom - 1,
      );
      final rr = RRect.fromRectAndRadius(
        litRect,
        const Radius.circular(StudioFader.slot / 2 - 1),
      );
      final strength = enabled ? 1.0 : 0.3;
      canvas
        ..drawRRect(
          rr,
          Paint()
            ..color = lit.withValues(alpha: 0.5 * strength)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
        )
        ..drawRRect(rr, Paint()..color = lit.withValues(alpha: strength));
    }
    final capRect = Rect.fromCenter(
      center: Offset(x, mid),
      width: cap.width,
      height: cap.height,
    );
    paintStudioFace(
      canvas,
      capRect,
      StudioFace(
        fill: enabled ? c.cap : Color.lerp(c.cap, c.panelLow, 0.4)!,
        fillLow: enabled ? c.capLow : Color.lerp(c.capLow, c.panelLow, 0.4)!,
        depth: StudioDepth.raised,
        radius: StudioRadii.cap,
        travel: held ? 0.5 : 0,
        brushed: true,
      ),
      light,
      ratio: ratio,
    );
    // The index line across the cap: the value's mark.
    final sink = held ? 0.5 * StudioMetrics.pressTravel : 0.0;
    canvas.drawLine(
      Offset(x, capRect.top + 5 + sink),
      Offset(x, capRect.bottom - 5 + sink),
      Paint()
        ..strokeWidth = 2
        ..color = indexColor,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_FaderPainter old) =>
      old.t != t ||
      old.axis != axis ||
      old.rtl != rtl ||
      old.light != light ||
      old.lit != lit ||
      old.enabled != enabled ||
      old.held != held ||
      old.ticks != ticks ||
      old.indexColor != indexColor ||
      old.ratio != ratio;
}

/// A knob: a knurled rotary with a lit pointer, ticks round it on the metal.
/// Drag up or right to turn it up; the arrows step it. With [divisions] it
/// clicks into detents and settles into the nearest with a small give, as a
/// stepped knob does.
///
/// [value] stands between 0 and 1 over its 270° sweep. A null [onChanged]
/// disables it.
///
/// Reads [style]'s `fill` (the pointer's light) and `minimumSize` (its
/// diameter), then [StudioThemeData.knobStyle].
///
/// ```dart
/// StudioKnob(value: gain, onChanged: (v) => setState(() => gain = v), semanticLabel: 'Input gain')
/// ```
class StudioKnob extends StatefulWidget {
  /// A knob turned to [value].
  const StudioKnob({
    super.key,
    required this.value,
    required this.onChanged,
    this.divisions,
    this.semanticLabel,
    this.semanticFormatter,
    this.focusNode,
    this.autofocus = false,
    this.style,
  }) : assert(value >= 0 && value <= 1);

  /// Where it is turned, 0 to 1.
  final double value;

  /// Called as it turns; null disables it.
  final ValueChanged<double>? onChanged;

  /// Its detents; null turns freely.
  final int? divisions;

  /// What a screen reader calls it.
  final String? semanticLabel;

  /// How a screen reader says a value.
  final String Function(double value)? semanticFormatter;

  /// {@macro design.focusNode}
  final FocusNode? focusNode;

  /// {@macro design.autofocus}
  final bool autofocus;

  /// Its style, over [StudioThemeData.knobStyle].
  final StudioStyle? style;

  /// Its diameter.
  static const double size = 44;

  @override
  State<StudioKnob> createState() => _StudioKnobState();
}

class _StudioKnobState extends State<StudioKnob>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shown = AnimationController(
    vsync: this,
    lowerBound: -1,
    upperBound: 2,
    value: widget.value,
  );
  bool _focused = false;
  // Focus shows as ui_core's parts show it: after a key, not after a click
  // or a drag, and for a Tab after a mouse that came before any other input
  // (a trackpad on an iPad), which leaves the detector's highlight stale.
  late final RawFocusShown _focusShown = RawFocusShown((on) {
    if (mounted) setState(() => _focused = on);
  });
  double _raw = 0;
  bool _dragging = false;
  // A finger or the pointer's button on the knob.
  bool _held = false;

  void _hold(bool on) {
    if (_held != on) setState(() => _held = on);
  }

  @override
  void didUpdateWidget(StudioKnob old) {
    super.didUpdateWidget(old);
    if (!_dragging && widget.value != _shown.value) _settle();
  }

  void _settle() {
    _shown.springTo(
      widget.value,
      RawMotionPolicy.of(context).spatial(
        dampingRatio: widget.divisions == null
            ? StudioMotion.dampingRatio
            : StudioMotion.detentDampingRatio,
        stiffness: StudioMotion.detentStiffness,
      ),
    );
  }

  double _snap(double v) {
    final d = widget.divisions;
    final c = v.clamp(0.0, 1.0);
    return d == null ? c : (c * d).round() / d;
  }

  double get _step => 1 / (widget.divisions ?? 20);

  void _set(double v) {
    final next = _snap(v);
    if (next != widget.value) widget.onChanged?.call(next);
  }

  String _say(double v) =>
      widget.semanticFormatter?.call(v) ?? '${(v * 100).round()}%';

  @override
  void dispose() {
    _shown.dispose();
    _focusShown.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = StudioTheme.of(context);
    final c = theme.colors;
    final enabled = widget.onChanged != null;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final layered = RawStyleOf(
      [widget.style, theme.knobStyle],
      {if (!enabled) WidgetState.disabled, if (_focused) WidgetState.focused},
    );
    final size = layered.minimumSize?.height ?? StudioKnob.size;
    final next = _snap(widget.value + _step);
    final prev = _snap(widget.value - _step);
    return Semantics(
      slider: true,
      enabled: enabled,
      label: widget.semanticLabel,
      value: _say(widget.value),
      increasedValue: enabled ? _say(next) : null,
      decreasedValue: enabled ? _say(prev) : null,
      onIncrease: enabled ? () => _set(next) : null,
      onDecrease: enabled ? () => _set(prev) : null,
      child: FocusableActionDetector(
        enabled: enabled,
        focusNode: widget.focusNode,
        autofocus: widget.autofocus,
        mouseCursor: enabled
            ? SystemMouseCursors.resizeUpDown
            : SystemMouseCursors.basic,
        onFocusChange: _focusShown.focused,
        shortcuts: _stepKeys(rtl, Axis.vertical),
        actions: {
          _StepIntent: CallbackAction<_StepIntent>(
            onInvoke: (i) {
              _set(i.toEnd ? (i.by < 0 ? 0 : 1) : widget.value + i.by * _step);
              return null;
            },
          ),
        },
        child: ExcludeSemantics(
          child: Listener(
            onPointerDown: enabled ? (_) => _hold(true) : null,
            onPointerUp: (_) => _hold(false),
            onPointerCancel: (_) => _hold(false),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanStart: enabled
                  ? (_) {
                      _dragging = true;
                      _raw = widget.value;
                    }
                  : null,
              onPanUpdate: enabled
                  ? (d) {
                      // Up and toward the end turn it up: 160 px turns it all
                      // the way.
                      final along =
                          (rtl ? -d.delta.dx : d.delta.dx) - d.delta.dy;
                      _raw = (_raw + along / 160).clamp(0.0, 1.0);
                      _shown.value = _raw;
                      _set(_raw);
                    }
                  : null,
              onPanEnd: enabled
                  ? (_) {
                      _dragging = false;
                      _settle();
                    }
                  : null,
              child: SizedBox.square(
                dimension: size + 12,
                // Gripped, the cap's sheen dims under the hand and the
                // pointer burns brighter; let go, both ease back.
                child: TweenAnimationBuilder<double>(
                  tween: Tween(end: _held ? 1 : 0),
                  duration:
                      MediaQuery.maybeDisableAnimationsOf(context) ?? false
                      ? Duration.zero
                      : const Duration(milliseconds: 120),
                  builder: (context, grip, _) => AnimatedBuilder(
                    animation: _shown,
                    builder: (context, _) => CustomPaint(
                      painter: _KnobPainter(
                        t: _shown.value,
                        grip: grip,
                        light: StudioLight.of(context),
                        lit: layered.fill ?? c.lightInDark,
                        enabled: enabled,
                        ticks: widget.divisions ?? 10,
                        focus: _focused ? c.focusRing : null,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _KnobPainter extends CustomPainter {
  _KnobPainter({
    required this.t,
    required this.grip,
    required this.light,
    required this.lit,
    required this.enabled,
    required this.ticks,
    required this.focus,
  });

  final double t;

  /// How firmly it is held, 0 to 1.
  final double grip;
  final StudioLight light;
  final Color lit;
  final bool enabled;
  final int ticks;
  final Color? focus;

  static const double _sweep = 1.5 * math.pi;
  static const double _start = 0.75 * math.pi;

  @override
  void paint(Canvas canvas, Size size) {
    final c = light.colors;
    final centre = size.center(Offset.zero);
    final r = size.shortestSide / 2 - 6;
    // Ticks on the metal round it.
    final tick = Paint()
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i <= ticks; i++) {
      final a = _start + _sweep * i / ticks;
      final dir = Offset(math.cos(a), math.sin(a));
      final on = enabled && i / ticks <= t + 1e-6;
      canvas.drawLine(
        centre + dir * (r + 2),
        centre + dir * (r + 5),
        tick..color = on ? c.litLegend : c.legendMuted.withValues(alpha: 0.6),
      );
    }
    // Its shadow, then the knurled body: a ring of fine ridges round a
    // smooth, lit-from-above cap.
    canvas.drawCircle(
      centre.translate(0, 2),
      r,
      Paint()
        ..color = c.shadow.withValues(alpha: light.castStrength)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5),
    );
    canvas.drawCircle(
      centre,
      r,
      Paint()
        ..shader = ui.Gradient.linear(
          centre.translate(0, -r),
          centre.translate(0, r),
          [c.key, c.keyLow],
        ),
    );
    final ridge = Paint()..strokeWidth = 1;
    final turn = _start + _sweep * t;
    for (var i = 0; i < 36; i++) {
      final a = turn + i * 2 * math.pi / 36;
      final dir = Offset(math.cos(a), math.sin(a));
      canvas.drawLine(
        centre + dir * (r - 3.5),
        centre + dir * (r - 0.5),
        ridge
          ..color = (dir.dy < 0
              ? c.edgeLight
              : c.shadow.withValues(alpha: 0.3)),
      );
    }
    canvas.drawCircle(
      centre,
      r - 5,
      Paint()
        ..shader = ui.Gradient.linear(
          centre.translate(0, -r),
          centre.translate(0, r),
          [
            Color.lerp(c.key, const Color(0xFFFFFFFF), 0.15 - 0.1 * grip)!,
            Color.lerp(c.keyLow, c.shadow, 0.15 * grip)!,
          ],
        ),
    );
    canvas.drawCircle(
      centre,
      r - 5,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = c.edgeLight,
    );
    // The pointer: a lit line from near the middle to the rim.
    final dir = Offset(math.cos(turn), math.sin(turn));
    final from = centre + dir * (r * 0.3);
    final to = centre + dir * (r - 7);
    final pointer = enabled ? lit : c.disabled;
    if (enabled) {
      canvas.drawLine(
        from,
        to,
        Paint()
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round
          ..color = pointer.withValues(alpha: 0.4 + 0.45 * grip)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 2 + grip),
      );
    }
    canvas.drawLine(
      from,
      to,
      Paint()
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..color = pointer,
    );
    // Focused, the knob's own edge lights amber, as Studio's keys do.
    if (focus != null) {
      paintStudioFocusLight(
        canvas,
        RRect.fromRectAndRadius(
          Rect.fromCircle(center: centre, radius: r),
          Radius.circular(r),
        ),
        focus!,
        light,
      );
    }
  }

  @override
  bool shouldRepaint(_KnobPainter old) =>
      old.t != t ||
      old.grip != grip ||
      old.light != light ||
      old.lit != lit ||
      old.enabled != enabled ||
      old.ticks != ticks ||
      old.focus != focus;
}

/// A level meter: a row (or a column) of segments behind readout glass, lit
/// from the start up to [level] in the indicator light, the segments past
/// [clip] in the danger colour (only those: red means clipping), a dark red
/// while unlit so the zone shows. [peak]
/// holds one segment lit where the level last reached.
///
/// It paints only itself on each change: give it the level every frame.
///
/// ```dart
/// StudioMeter(level: left, peak: leftPeak, semanticLabel: 'Left channel')
/// ```
class StudioMeter extends StatelessWidget {
  /// A meter showing [level], 0 to 1.
  const StudioMeter({
    super.key,
    required this.level,
    this.peak,
    this.segments = 24,
    this.clip = 0.9,
    this.axis = Axis.horizontal,
    this.thickness = 12,
    this.semanticLabel,
    this.style,
  }) : assert(level >= 0 && level <= 1),
       assert(segments > 1);

  /// How full it is, 0 to 1.
  final double level;

  /// The held peak, 0 to 1, or null.
  final double? peak;

  /// How many segments it has.
  final int segments;

  /// Where clipping starts, 0 to 1: segments past it light red.
  final double clip;

  /// Which way it runs (vertical fills from the bottom).
  final Axis axis;

  /// Its thickness across.
  final double thickness;

  /// What a screen reader calls it.
  final String? semanticLabel;

  /// Its style (its `fill`, the lit segments), over
  /// [StudioThemeData.meterStyle].
  final StudioStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = StudioTheme.of(context);
    final c = theme.colors;
    final layered = RawStyleOf([style, theme.meterStyle], const {});
    final along = axis == Axis.horizontal;
    return Semantics(
      label: semanticLabel,
      value: '${(level * 100).round()}%',
      child: SizedBox(
        height: along ? thickness : null,
        width: along ? null : thickness,
        child: StudioSurface(
          face: c.readoutFace.copyWith(radius: 3),
          child: Padding(
            padding: const EdgeInsets.all(StudioSpacing.hair),
            child: RepaintBoundary(
              child: CustomPaint(
                size: Size.infinite,
                painter: _MeterPainter(
                  level: level,
                  peak: peak,
                  segments: segments,
                  clip: clip,
                  axis: axis,
                  rtl: Directionality.of(context) == TextDirection.rtl,
                  lit: layered.fill ?? c.readoutLit,
                  danger: c.litReadout ? c.dangerLegend : c.danger,
                  off: Color.lerp(c.readout, c.readoutLit, 0.1)!,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MeterPainter extends CustomPainter {
  _MeterPainter({
    required this.level,
    required this.peak,
    required this.segments,
    required this.clip,
    required this.axis,
    required this.rtl,
    required this.lit,
    required this.danger,
    required this.off,
  });

  final double level;
  final double? peak;
  final int segments;
  final double clip;
  final Axis axis;
  final bool rtl;
  final Color lit;
  final Color danger;
  final Color off;

  @override
  void paint(Canvas canvas, Size size) {
    final along = axis == Axis.horizontal;
    final length = along ? size.width : size.height;
    final across = along ? size.height : size.width;
    const gap = 2.0;
    final seg = (length - gap * (segments - 1)) / segments;
    final peakAt = peak == null ? -1 : (peak! * segments).ceil() - 1;
    final on = (level * segments).round();
    for (var i = 0; i < segments; i++) {
      final hot = (i + 1) / segments > clip;
      final colour = hot ? danger : lit;
      final isOn = i < on || i == peakAt;
      var p = i * (seg + gap);
      if (along && rtl) p = length - p - seg;
      if (!along) p = length - p - seg;
      final r = along
          ? Rect.fromLTWH(p, 0, seg, across)
          : Rect.fromLTWH(0, p, across, seg);
      final rr = RRect.fromRectAndRadius(r, const Radius.circular(1));
      // Unlit, the clipping zone is a dark red, so the scale shows where
      // it starts before the level reaches it.
      canvas.drawRRect(
        rr,
        Paint()
          ..color = isOn
              ? colour
              : hot
              ? Color.lerp(off, danger, 0.14)!
              : off,
      );
    }
  }

  @override
  bool shouldRepaint(_MeterPainter old) =>
      old.level != level ||
      old.peak != peak ||
      old.segments != segments ||
      old.clip != clip ||
      old.axis != axis ||
      old.rtl != rtl ||
      old.lit != lit ||
      old.danger != danger ||
      old.off != off;
}
