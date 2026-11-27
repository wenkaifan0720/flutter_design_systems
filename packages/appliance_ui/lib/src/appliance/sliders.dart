/// Appliance's mechanical selectors for an amount: [ApplianceSlider] (a fader
/// cap riding in a slot), [ApplianceRangeSlider] (two caps), [ApplianceKnob]
/// (a knurled knob turning through detents) and [ApplianceRating] (five
/// stars, lit).
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import 'internal/spring_value.dart';
import 'material.dart';
import 'theme.dart';

// The ui_core types this part's API takes, through the look's barrel.
export 'package:ui_core/ui_core.dart' show RawRangeValues;

/// The width a fader cap's touch takes: the touch floor on every input
/// (40, or the app's [RawTapTargetScope]), so a finger finds it on a
/// pointer device too.
double _capReachOf(BuildContext context) =>
    RawTapTargets.of(context).touch.width;

/// A fader cap's size.
const Size _capSize = Size(20, 30);

/// The slot a fader rides in: a dark groove with the travelled part lit.
class _SlotPainter extends CustomPainter {
  _SlotPainter({
    required this.colors,
    required this.start,
    required this.end,
    required this.enabled,
    required this.rtl,
    this.ticks = 0,
  });

  final ApplianceColors colors;
  final double start;
  final double end;
  final bool enabled;
  final bool rtl;
  final int ticks;

  @override
  void paint(Canvas canvas, Size size) {
    const h = 6.0;
    final y = size.height / 2;
    final slot = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, y - h / 2, size.width, h),
      const Radius.circular(h / 2),
    );
    canvas
      ..drawRRect(
        slot.shift(const Offset(0, 1)),
        Paint()..color = colors.seamLight,
      )
      ..drawRRect(slot, Paint()..color = colors.slot);
    // The rounded end of the two-pixel light sits two pixels into the
    // six-pixel slot, just as it does along the top and bottom.
    final endRadius = math.min(h / 2, size.width / 2);
    double at(double f) => ((rtl ? 1 - f : f) * size.width).clamp(
      endRadius,
      size.width - endRadius,
    );
    final a = at(start);
    final b = at(end);
    canvas.drawLine(
      Offset(math.min(a, b), y),
      Offset(math.max(a, b), y),
      Paint()
        ..color = enabled ? colors.signal : colors.printDisabled
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
    if (ticks > 0) {
      final tick = Paint()
        ..color = enabled ? colors.printMuted : colors.printDisabled
        ..strokeWidth = 1;
      for (var i = 0; i <= ticks; i++) {
        final x = size.width * i / ticks;
        canvas.drawLine(Offset(x, y + 9), Offset(x, y + 13), tick);
      }
    }
  }

  @override
  bool shouldRepaint(_SlotPainter old) =>
      old.colors != colors ||
      old.start != start ||
      old.end != end ||
      old.enabled != enabled ||
      old.rtl != rtl ||
      old.ticks != ticks;
}

/// A fader's cap: a key standing on the slot, its index line across it.
class _Cap extends StatelessWidget {
  const _Cap({
    required this.enabled,
    required this.focused,
    required this.held,
    this.hovered = false,
    this.style,
  });

  final bool enabled;
  final bool focused;
  final bool held;
  final bool hovered;
  final ApplianceStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = ApplianceTheme.of(context);
    final c = theme.colors;
    final layered = RawStyleOf(
      [style, theme.sliderStyle],
      {
        if (!enabled) WidgetState.disabled,
        if (focused) WidgetState.focused,
        if (hovered) WidgetState.hovered,
        if (held) WidgetState.pressed,
      },
    );
    final face = layered.on(
      ApplianceFace.key(c, radius: ApplianceSpacing.tight).copyWith(
        lift: !enabled ? 0.35 : (held ? 0.6 : 1),
        foreground: enabled
            ? Color.lerp(
                c.print,
                c.signal,
                focused
                    ? 0.85
                    : hovered
                    ? 0.14
                    : 0,
              )
            : c.printDisabled,
      ),
      // A thumb is a mechanism and keeps its own form.
      corners: false,
    );
    return SizedBox.fromSize(
      size: _capSize,
      child: AnimatedApplianceSurface(
        face: face,
        child: Center(
          child: Container(width: 2, height: 14, color: face.foreground),
        ),
      ),
    );
  }
}

String _plain(double v) =>
    v == v.roundToDouble() ? v.round().toString() : v.toStringAsFixed(1);

/// A slider: a fader. A key-like cap rides in a dark slot, the travelled
/// part of the slot lit in the signal colour; with [divisions] the cap snaps
/// to them and ticks are printed under the slot.
///
/// Drag the cap or press anywhere on the slot; the arrows step it (a
/// division, or a hundredth of the way), Home and End go to its ends. A null
/// [onChanged] disables it.
///
/// Reads [style] in the cap's states, then [ApplianceThemeData.sliderStyle].
///
/// ```dart
/// ApplianceSlider(value: 0.4, onChanged: (v) {}, semanticLabel: 'Volume')
/// ```
class ApplianceSlider extends StatefulWidget {
  /// A fader at [value] between [min] and [max].
  const ApplianceSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 1,
    this.divisions,
    this.semanticLabel,
    this.semanticFormatterCallback,
    this.onChangeStart,
    this.onChangeEnd,
    this.focusNode,
    this.autofocus = false,
    this.style,
  }) : assert(min < max, 'min is less than max');

  /// Where the cap stands.
  final double value;

  /// Called with each new value; null disables the fader.
  final ValueChanged<double>? onChanged;

  /// The least value.
  final double min;

  /// The greatest value.
  final double max;

  /// How many steps the slot is cut into; null: smooth.
  final int? divisions;

  /// The fader's name for a screen reader.
  final String? semanticLabel;

  /// How a value is said to a screen reader ("40%"); its number otherwise.
  final String Function(double value)? semanticFormatterCallback;

  /// Called as a drag starts.
  final ValueChanged<double>? onChangeStart;

  /// Called as a drag ends.
  final ValueChanged<double>? onChangeEnd;

  /// {@macro design.focusNode}
  final FocusNode? focusNode;

  /// {@macro design.autofocus}
  final bool autofocus;

  /// The cap's style, over [ApplianceThemeData.sliderStyle]. The cap keeps
  /// its moulded form: a style's corners leave it.
  final ApplianceStyle? style;

  @override
  State<ApplianceSlider> createState() => _ApplianceSliderState();

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

class _ApplianceSliderState extends State<ApplianceSlider> {
  bool _dragging = false;
  bool _hovered = false;

  double _snap(double v) {
    final d = widget.divisions;
    final clamped = v.clamp(widget.min, widget.max).toDouble();
    if (d == null) return clamped;
    final step = (widget.max - widget.min) / d;
    return widget.min + ((clamped - widget.min) / step).round() * step;
  }

  double _at(double dx, double width, bool rtl, double reach) {
    final usable = width - reach;
    var f = usable <= 0 ? 0.0 : (dx - reach / 2) / usable;
    f = f.clamp(0.0, 1.0);
    if (rtl) f = 1 - f;
    return _snap(widget.min + f * (widget.max - widget.min));
  }

  @override
  Widget build(BuildContext context) {
    final theme = ApplianceTheme.of(context);
    final c = theme.colors;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final enabled = widget.onChanged != null;
    final span = widget.max - widget.min;
    final fraction = ((widget.value - widget.min) / span).clamp(0.0, 1.0);
    final reach = _capReachOf(context);
    return LayoutBuilder(
      builder: (context, box) {
        final width = box.maxWidth.isFinite ? box.maxWidth : 240.0;
        void drag(double dx) =>
            widget.onChanged?.call(_at(dx, width, rtl, reach));
        return MouseRegion(
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          cursor: enabled ? SystemMouseCursors.click : MouseCursor.defer,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            // The cap's handle is the slider to a screen reader (its steps
            // up and down); the slot's drag would add a second.
            excludeFromSemantics: true,
            dragStartBehavior: DragStartBehavior.down,
            onTapDown: enabled ? (d) => drag(d.localPosition.dx) : null,
            onHorizontalDragStart: enabled
                ? (d) {
                    setState(() => _dragging = true);
                    widget.onChangeStart?.call(widget.value);
                    drag(d.localPosition.dx);
                  }
                : null,
            onHorizontalDragUpdate: enabled
                ? (d) => drag(d.localPosition.dx)
                : null,
            onHorizontalDragEnd: enabled
                ? (_) {
                    setState(() => _dragging = false);
                    widget.onChangeEnd?.call(widget.value);
                  }
                : null,
            child: SizedBox(
              width: width,
              height: theme.controlHeight,
              child: ApplianceSpringValue(
                value: fraction,
                spring: _dragging
                    ? ApplianceMotion.press
                    : ApplianceMotion.snap,
                builder: (context, f, _) {
                  final x = reach / 2 + (rtl ? 1 - f : f) * (width - reach);
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        left: reach / 2,
                        right: reach / 2,
                        top: 0,
                        bottom: 0,
                        child: CustomPaint(
                          painter: _SlotPainter(
                            colors: c,
                            start: 0,
                            end: f,
                            enabled: enabled,
                            rtl: rtl,
                            ticks:
                                widget.divisions != null &&
                                    widget.divisions! <= 20
                                ? widget.divisions!
                                : 0,
                          ),
                        ),
                      ),
                      Positioned(
                        left: x - reach / 2,
                        top: 0,
                        width: reach,
                        height: theme.controlHeight,
                        child: RawValueHandle(
                          value: widget.value
                              .clamp(widget.min, widget.max)
                              .toDouble(),
                          onChanged: widget.onChanged == null
                              ? null
                              : (v) => widget.onChanged!(_snap(v)),
                          min: widget.min,
                          max: widget.max,
                          divisions: widget.divisions,
                          step: widget.divisions == null ? span / 100 : null,
                          dragging: _dragging,
                          semanticLabel: widget.semanticLabel,
                          semanticFormatterCallback:
                              widget.semanticFormatterCallback ?? _plain,
                          focusNode: widget.focusNode,
                          autofocus: widget.autofocus,
                          minimumSize: Size(reach, theme.controlHeight),
                          builder: (context, states) => Center(
                            child: _Cap(
                              enabled: !states.contains(WidgetState.disabled),
                              focused: states.contains(WidgetState.focused),
                              hovered: _hovered,
                              held:
                                  _dragging ||
                                  states.contains(WidgetState.pressed),
                              style: widget.style,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

/// A range: two fader caps in one slot, the slot lit between them. Each cap
/// is its own stop for the keys and the screen reader; they never pass.
///
/// ```dart
/// ApplianceRangeSlider(values: const RawRangeValues(20, 60), max: 100, onChanged: (range) {})
/// ```
class ApplianceRangeSlider extends StatelessWidget {
  /// A range of [values] between [min] and [max].
  const ApplianceRangeSlider({
    super.key,
    required this.values,
    required this.onChanged,
    this.min = 0,
    this.max = 1,
    this.divisions,
    this.minGap = 0,
    this.startLabel,
    this.endLabel,
    this.semanticFormatterCallback,
    this.onChangeStart,
    this.onChangeEnd,
    this.style,
  });

  /// The range.
  final RawRangeValues values;

  /// Called with each new range; null disables it.
  final ValueChanged<RawRangeValues>? onChanged;

  /// The least value.
  final double min;

  /// The greatest value.
  final double max;

  /// How many steps the slot is cut into; null: smooth.
  final int? divisions;

  /// The least the two may stand apart.
  final double minGap;

  /// The lower cap's name for a screen reader.
  final String? startLabel;

  /// The upper cap's name for a screen reader.
  final String? endLabel;

  /// Formats the value of each thumb for assistive technologies.
  /// For a price, include the currency in the returned string.
  final String Function(double value)? semanticFormatterCallback;

  /// Called as a drag starts.
  final ValueChanged<RawRangeValues>? onChangeStart;

  /// Called as a drag ends.
  final ValueChanged<RawRangeValues>? onChangeEnd;

  /// The caps' style, over [ApplianceThemeData.sliderStyle]. A cap keeps
  /// its moulded form: a style's corners leave it.
  final ApplianceStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = ApplianceTheme.of(context);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return SizedBox(
      height: theme.controlHeight,
      child: RawRangeSlider(
        values: values,
        onChanged: onChanged,
        min: min,
        max: max,
        divisions: divisions,
        minGap: minGap,
        startLabel: startLabel,
        endLabel: endLabel,
        semanticFormatterCallback: semanticFormatterCallback,
        onChangeStart: onChangeStart,
        onChangeEnd: onChangeEnd,
        thumbSize: Size(_capReachOf(context), theme.controlHeight),
        trackBuilder: (context, track) => SizedBox(
          height: theme.controlHeight,
          child: CustomPaint(
            painter: _SlotPainter(
              colors: theme.colors,
              // From the track's start edge; the slot mirrors them.
              start: track.start,
              end: track.end,
              enabled: track.enabled,
              rtl: rtl,
              ticks: divisions != null && divisions! <= 20 ? divisions! : 0,
            ),
          ),
        ),
        thumbBuilder: (context, index, states) => Center(
          child: _Cap(
            enabled: !states.contains(WidgetState.disabled),
            focused: states.contains(WidgetState.focused),
            held:
                states.contains(WidgetState.pressed) ||
                states.contains(WidgetState.dragged),
            style: style,
          ),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DoubleProperty('start', values.start))
      ..add(DoubleProperty('end', values.end))
      ..add(
        FlagProperty('enabled', value: onChanged != null, ifFalse: 'disabled'),
      );
  }
}

/// One detent of an [ApplianceKnob].
@immutable
class ApplianceKnobOption<T> {
  /// The detent for [value], printed [label] round the knob.
  const ApplianceKnobOption({required this.value, required this.label});

  /// What it means.
  final T value;

  /// Its name, printed round the knob.
  final String label;
}

/// The arc a knob's detents spread over, in radians.
const double _sweep = math.pi * 1.5;

/// A knob's body: a knurled metal ring under a moulded cap, its pointer in
/// the signal colour.
class _KnobPainter extends CustomPainter {
  _KnobPainter({
    required this.colors,
    required this.angle,
    required this.enabled,
    required this.focused,
  });

  final ApplianceColors colors;
  final double angle;
  final bool enabled;
  final bool focused;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    final ring = Rect.fromCircle(center: c, radius: r);
    canvas
      ..drawCircle(
        c.translate(0, 2),
        r,
        Paint()
          ..color = colors.shade.withValues(alpha: 0.18)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
      )
      ..drawCircle(
        c,
        r,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [colors.metalLight, colors.metalDark],
          ).createShader(ring),
      );
    final knurl = Paint()
      ..color = colors.shade.withValues(alpha: 0.22)
      ..strokeWidth = 1;
    for (var i = 0; i < 48; i++) {
      final a = i * math.pi * 2 / 48;
      final d = Offset(math.cos(a), math.sin(a));
      canvas.drawLine(c + d * (r - 5), c + d * (r - 1), knurl);
    }
    final cap = r - 7;
    canvas.drawCircle(
      c,
      cap,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [colors.keyTop, colors.keyBottom],
        ).createShader(Rect.fromCircle(center: c, radius: cap)),
    );
    canvas.drawCircle(
      c,
      cap,
      Paint()
        ..color = colors.highlight
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    final d = Offset(math.sin(angle), -math.cos(angle));
    canvas.drawLine(
      c + d * (cap * 0.35),
      c + d * (cap - 4),
      Paint()
        ..color = enabled ? colors.signal : colors.printDisabled
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
    if (focused) {
      // The knurled ring backlit from inside its edge, as a key's rim is.
      canvas.drawCircle(
        c,
        r - ApplianceMetrics.focusWidth / 2,
        Paint()
          ..color = applianceFocusLight(
            colors.focus,
            colors.metalLight,
            bottom: colors.metalDark,
          )
          ..style = PaintingStyle.stroke
          ..strokeWidth = ApplianceMetrics.focusWidth,
      );
    }
  }

  @override
  bool shouldRepaint(_KnobPainter old) =>
      old.colors != colors ||
      old.angle != angle ||
      old.enabled != enabled ||
      old.focused != focused;
}

/// A knob: a knurled metal ring under a moulded cap, turned through detents
/// whose names are printed round it (an oven's Bake, Grill, Fan). The
/// pointer snaps to the nearest detent.
///
/// Turn it by dragging round it, press a name to go to it, or use the
/// arrows; a screen reader adjusts it and hears the detent's name. A null
/// [onChanged] disables it.
///
/// ```dart
/// ApplianceKnob<String>(options: const [ApplianceKnobOption(value: 'bake', label: 'Bake'), ApplianceKnobOption(value: 'grill', label: 'Grill')], value: 'bake', onChanged: (mode) {}, semanticLabel: 'Mode')
/// ```
class ApplianceKnob<T> extends StatefulWidget {
  /// A knob over [options], at [value].
  const ApplianceKnob({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
    this.semanticLabel,
    this.diameter = 72,
    this.focusNode,
    this.style,
  }) : assert(options.length > 1, 'a knob has two detents or more');

  /// The detents, in turning order.
  final List<ApplianceKnobOption<T>> options;

  /// The detent the pointer stands at.
  final T value;

  /// Called with the detent turned to; null disables the knob.
  final ValueChanged<T>? onChanged;

  /// The knob's name for a screen reader.
  final String? semanticLabel;

  /// The knob's size; its names stand round it.
  final double diameter;

  /// {@macro design.focusNode}
  final FocusNode? focusNode;

  /// Its style, over [ApplianceThemeData.sliderStyle]: foreground (the chosen mark), textStyle.
  final ApplianceStyle? style;

  @override
  State<ApplianceKnob<T>> createState() => _ApplianceKnobState<T>();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<T>('value', value))
      ..add(
        FlagProperty('enabled', value: onChanged != null, ifFalse: 'disabled'),
      );
  }
}

class _ApplianceKnobState<T> extends State<ApplianceKnob<T>> {
  int get _index {
    final i = widget.options.indexWhere((o) => o.value == widget.value);
    return i < 0 ? 0 : i;
  }

  double _angleOf(int i) =>
      -_sweep / 2 + _sweep * i / (widget.options.length - 1);

  void _go(int i) {
    final n = i.clamp(0, widget.options.length - 1);
    if (n != _index) widget.onChanged?.call(widget.options[n].value);
  }

  void _turnTo(Offset local, Offset centre) {
    final v = local - centre;
    if (v.distance < 4) return;
    final a = math.atan2(v.dx, -v.dy);
    var best = 0;
    for (var i = 1; i < widget.options.length; i++) {
      if ((_angleOf(i) - a).abs() < (_angleOf(best) - a).abs()) best = i;
    }
    _go(best);
  }

  @override
  Widget build(BuildContext context) {
    final look = RawStyleOf([
      widget.style,
      ApplianceTheme.of(context).sliderStyle,
    ], const {});
    final theme = ApplianceTheme.of(context);
    final c = theme.colors;
    final enabled = widget.onChanged != null;
    final d = widget.diameter;
    const labelWidth = 72.0;
    // Each word is a key a finger's reach high, reaching away from the dial
    // (its words on the dial's side), on an orbit that keeps it off the
    // dial's box.
    const words = 24.0;
    const reach = ApplianceMetrics.controlHeight;
    final orbit = d / 2 + 34;
    final side = 2 * orbit + labelWidth;
    final centre = Offset(side / 2, side / 2);
    return SizedBox.square(
      dimension: side,
      child: Stack(
        children: [
          for (final (i, o) in widget.options.indexed)
            Positioned(
              left: centre.dx + math.sin(_angleOf(i)) * orbit - labelWidth / 2,
              top:
                  centre.dy -
                  math.cos(_angleOf(i)) * orbit -
                  (math.cos(_angleOf(i)) > 0 ? reach - words / 2 : words / 2),
              width: labelWidth,
              height: reach,
              child: MouseRegion(
                cursor: enabled ? SystemMouseCursors.click : MouseCursor.defer,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: enabled ? () => _go(i) : null,
                  child: Align(
                    alignment: math.cos(_angleOf(i)) > 0
                        ? Alignment.bottomCenter
                        : Alignment.topCenter,
                    child: SizedBox(
                      height: words,
                      child: Center(
                        child: Text(
                          o.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: look
                              .text(theme.textTheme.secondary)
                              .copyWith(
                                color: !enabled
                                    ? c.printDisabled
                                    : i == _index
                                    ? look.foreground ?? c.print
                                    : c.printMuted,
                                fontWeight: i == _index
                                    ? FontWeight.w600
                                    : null,
                              ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          Positioned(
            left: centre.dx - d / 2,
            top: centre.dy - d / 2,
            width: d,
            height: d,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanDown: enabled
                  ? (e) => _turnTo(e.localPosition, Offset(d / 2, d / 2))
                  : null,
              onPanUpdate: enabled
                  ? (e) => _turnTo(e.localPosition, Offset(d / 2, d / 2))
                  : null,
              child: RawValueHandle(
                value: _index.toDouble(),
                onChanged: enabled ? (v) => _go(v.round()) : null,
                max: widget.options.length - 1.0,
                divisions: widget.options.length - 1,
                axis: Axis.vertical,
                semanticLabel: widget.semanticLabel,
                semanticFormatterCallback: (v) =>
                    widget.options[v.round()].label,
                focusNode: widget.focusNode,
                minimumSize: Size.square(d),
                builder: (context, states) => ApplianceSpringValue(
                  value: _angleOf(_index),
                  spring: ApplianceMotion.snap,
                  builder: (context, angle, _) => CustomPaint(
                    size: Size.square(d),
                    painter: _KnobPainter(
                      colors: c,
                      angle: angle,
                      enabled: enabled,
                      focused: states.contains(WidgetState.focused),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A star, five points.
Path _star(Offset c, double r) {
  final path = Path();
  for (var i = 0; i < 10; i++) {
    final a = -math.pi / 2 + i * math.pi / 5;
    final rr = i.isEven ? r : r * 0.45;
    final p = c + Offset(math.cos(a), math.sin(a)) * rr;
    i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
  }
  return path..close();
}

class _StarPainter extends CustomPainter {
  _StarPainter({
    required this.lit,
    required this.colors,
    required this.ink,
    this.rtl = false,
  });

  final double lit;
  final ApplianceColors colors;
  final Color ink;

  /// Whether the stars read right to left: a part-lit star lights from its
  /// right.
  final bool rtl;

  @override
  void paint(Canvas canvas, Size size) {
    final star = _star(size.center(Offset.zero), size.shortestSide * 0.46);
    canvas
      ..drawPath(star, Paint()..color = colors.lampOff)
      ..save()
      ..clipRect(
        rtl
            ? Rect.fromLTRB(size.width * (1 - lit), 0, size.width, size.height)
            : Rect.fromLTWH(0, 0, size.width * lit, size.height),
      )
      ..drawPath(star, Paint()..color = ink)
      ..restore();
  }

  @override
  bool shouldRepaint(_StarPainter old) =>
      old.lit != lit ||
      old.colors != colors ||
      old.ink != ink ||
      old.rtl != rtl;
}

/// A rating: five stars, lit in the signal colour up to [value], on
/// ui_core's [RawRating]. Under the pointer the stars light to the one
/// it is over, a preview of the press.
///
/// A press or a drag across sets it; with the keys (one tab stop) the
/// arrows step it, Home clears it, End fills it and a digit sets that many.
/// A null [onChanged] shows it only (a product's average, lit in part),
/// read as a value with no tab stop.
///
/// ```dart
/// ApplianceRating(value: 4, onChanged: (stars) {})
/// ```
class ApplianceRating extends StatefulWidget {
  /// A rating of [value] out of [count].
  const ApplianceRating({
    super.key,
    required this.value,
    this.onChanged,
    this.count = 5,
    this.semanticLabel = 'Rating',
    this.size = 24,
    this.style,
  });

  /// How many stars are lit (in part, for a shown average).
  final double value;

  /// Called with the stars chosen; null shows the rating only.
  final ValueChanged<int>? onChanged;

  /// How many stars.
  final int count;

  /// Its name for a screen reader.
  final String semanticLabel;

  /// A star's size.
  final double size;

  /// Its style, over [ApplianceThemeData.sliderStyle]: foreground (the stars).
  final ApplianceStyle? style;

  @override
  State<ApplianceRating> createState() => _ApplianceRatingState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DoubleProperty('value', value))
      ..add(IntProperty('count', count));
  }
}

class _ApplianceRatingState extends State<ApplianceRating> {
  final FocusNode _focus = FocusNode(debugLabel: 'ApplianceRating');

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final look = RawStyleOf([
      widget.style,
      ApplianceTheme.of(context).sliderStyle,
    ], const {});
    final theme = ApplianceTheme.of(context);
    final c = theme.colors;
    final enabled = widget.onChanged != null;
    final rating = RawRating(
      value: widget.value.clamp(0, widget.count).toDouble(),
      onChanged: enabled ? (v) => widget.onChanged!(v.round()) : null,
      readOnly: !enabled,
      itemCount: widget.count,
      semanticLabel: widget.semanticLabel,
      focusNode: _focus,
      itemBuilder: (context, item) => Padding(
        // The padding is the star's reach.
        padding: EdgeInsets.all(
          enabled ? ApplianceSpacing.medium : ApplianceSpacing.hair,
        ),
        child: CustomPaint(
          size: Size.square(widget.size),
          painter: _StarPainter(
            rtl: Directionality.of(context) == TextDirection.rtl,
            lit: item.fill,
            colors: c,
            // A preview under the pointer lights brighter.
            ink: look.foreground ?? (item.isPreview ? c.signalTop : c.signal),
          ),
        ),
      ),
    );
    if (!enabled) return rating;
    return ListenableBuilder(
      listenable: _focus,
      builder: (context, child) => DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(ApplianceSpacing.small),
          border: Border.all(
            color: _focus.hasFocus ? c.focus : c.focus.withValues(alpha: 0),
            width: ApplianceMetrics.focusWidth,
          ),
        ),
        child: child,
      ),
      child: rating,
    );
  }
}
