/// Values along a line: a slider, a range slider and a meter, drawn on the
/// cell grid as a terminal draws them.
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../grid.dart';
import '../primitives/box.dart';
import '../primitives/control.dart';
import '../style.dart';
import '../theme.dart';
import 'feedback.dart';

/// A slider: a rule across its width, the part up to the value heavy in
/// the accent, the value a block one cell wide that steps from cell to
/// cell: `━━━━━━█──────────`. The arrows move it by [step], Page Up and
/// Down by a tenth, Home and End to the ends; a drag or a tap on the rule
/// puts it there. A screen reader hears a slider.
///
/// ```dart
/// TermSlider(
///   semanticLabel: 'canary share',
///   value: share,
///   onChanged: (v) => setState(() => share = v),
/// )
/// ```
class TermSlider extends StatefulWidget {
  /// A slider at [value] between [min] and [max].
  const TermSlider({
    super.key,
    required this.value,
    required this.onChanged,
    required this.semanticLabel,
    this.min = 0,
    this.max = 1,
    this.step,
    this.divisions,
    this.semanticFormatterCallback,
    this.focusNode,
    this.autofocus = false,
    this.style,
  });

  /// Overrides, over the theme's [TermThemeData.sliderStyle]: `fill` (the
  /// heavy part), `foreground` (the block) and `edge` (the rule).
  final TermStyle? style;

  /// The value.
  final double value;

  /// Called as it moves; null disables it.
  final ValueChanged<double>? onChanged;

  /// What it sets.
  final String semanticLabel;

  /// The least value.
  final double min;

  /// The greatest value.
  final double max;

  /// How far an arrow moves it; null: a hundredth of the range.
  final double? step;

  /// The values it stops at; null: any.
  final int? divisions;

  /// What a screen reader says the value is; null: a percentage.
  final String Function(double value)? semanticFormatterCallback;

  /// {@macro term.focusNode}
  final FocusNode? focusNode;

  /// {@macro term.autofocus}
  final bool autofocus;

  @override
  State<TermSlider> createState() => _TermSliderState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DoubleProperty('value', value))
      ..add(DoubleProperty('min', min))
      ..add(DoubleProperty('max', max));
  }
}

class _TermSliderState extends State<TermSlider> {
  bool _dragging = false;

  double _at(double dx, double width) {
    final f = width <= 0 ? 0.0 : (dx / width).clamp(0.0, 1.0);
    var v = widget.min + f * (widget.max - widget.min);
    final d = widget.divisions;
    if (d != null && d > 0) {
      final unit = (widget.max - widget.min) / d;
      v = widget.min + (((v - widget.min) / unit).round() * unit);
    }
    return v;
  }

  @override
  Widget build(BuildContext context) {
    final theme = TermTheme.of(context);
    final grid = context.termGrid;
    final floor = grid.ceil(DesignTapTargets.of(context).floorOn());
    final change = widget.onChanged;
    final span = widget.max - widget.min;
    final f = span <= 0 ? 0.0 : (widget.value - widget.min) / span;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? grid.cols(grid.colsIn(constraints.maxWidth))
            : grid.cols(24);
        void put(Offset local) {
          if (change == null) return;
          final dx = rtl ? width - local.dx : local.dx;
          change(_at(dx, width));
        }

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          // The handle is what a screen reader hears; the rail's own taps
          // and drags stay out of its tree, so no box round it says it
          // takes a tap.
          excludeFromSemantics: true,
          // A finger held on the rail has the block in hand, as a drag
          // does: the handle shows it pressed until the finger lifts.
          onTapDown: change == null
              ? null
              : (d) {
                  setState(() => _dragging = true);
                  put(d.localPosition);
                },
          onTapUp: change == null
              ? null
              : (_) => setState(() => _dragging = false),
          onTapCancel: change == null
              ? null
              : () => setState(() => _dragging = false),
          onHorizontalDragStart: change == null
              ? null
              : (d) {
                  setState(() => _dragging = true);
                  put(d.localPosition);
                },
          onHorizontalDragUpdate: change == null
              ? null
              : (d) => put(d.localPosition),
          onHorizontalDragEnd: change == null
              ? null
              : (_) => setState(() => _dragging = false),
          onHorizontalDragCancel: change == null
              ? null
              : () => setState(() => _dragging = false),
          child: DesignValueHandle(
            value: widget.value,
            onChanged: change,
            min: widget.min,
            max: widget.max,
            step: widget.step,
            divisions: widget.divisions,
            dragging: _dragging,
            semanticLabel: widget.semanticLabel,
            semanticFormatterCallback: widget.semanticFormatterCallback,
            focusNode: widget.focusNode,
            autofocus: widget.autofocus,
            mouseCursor: change == null
                ? SystemMouseCursors.basic
                : SystemMouseCursors.click,
            minimumSize: Size(width, floor.height),
            builder: (context, states) {
              final own = TermStyleOf([
                widget.style,
                theme.sliderStyle,
              ], states);
              return TermStateSprings(
                pressed: states.contains(WidgetState.pressed),
                focused: states.contains(WidgetState.focused),
                builder: (context, press, focus) => SizedBox(
                  width: width,
                  height: grid.lineHeight,
                  child: CustomPaint(
                    painter: _RailPainter(
                      grid: grid,
                      start: 0,
                      end: f.clamp(0.0, 1.0),
                      thumbs: [f.clamp(0.0, 1.0)],
                      focused: [focus],
                      pressed: [press],
                      rule: own.edge ?? theme.rule,
                      fill: change == null
                          ? theme.rule
                          : own.fill ?? theme.accent,
                      thumb: change == null
                          ? theme.rule
                          : Color.lerp(
                              own.foreground ?? theme.foreground,
                              theme.accent,
                              focus,
                            )!,
                      stroke: termStroke(theme, grid),
                      textDirection: Directionality.of(context),
                      inset: 0,
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

/// A range slider: two blocks on one rule, the part between them heavy in
/// the accent: `──█━━━━━━━█─────`. They cannot cross; the arrows move the
/// one with the keyboard, a drag the nearer one.
///
/// ```dart
/// TermRangeSlider(
///   values: const DesignRangeValues(200, 800),
///   max: 1000,
///   onChanged: (v) => setState(() => latency = v),
/// )
/// ```
class TermRangeSlider extends StatelessWidget {
  /// A range slider over [values].
  const TermRangeSlider({
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
    this.style,
  });

  /// Overrides, over the theme's [TermThemeData.sliderStyle]: `fill` (the
  /// heavy part), `foreground` (the blocks) and `edge` (the rule).
  final TermStyle? style;

  /// The range.
  final DesignRangeValues values;

  /// Called as it moves; null disables it.
  final ValueChanged<DesignRangeValues>? onChanged;

  /// The least value.
  final double min;

  /// The greatest value.
  final double max;

  /// The values it stops at; null: any.
  final int? divisions;

  /// The least gap between the ends.
  final double minGap;

  /// What a screen reader calls the lower end.
  final String? startLabel;

  /// What a screen reader calls the upper end.
  final String? endLabel;

  /// What a screen reader says a value is.
  final String Function(double value)? semanticFormatterCallback;

  @override
  Widget build(BuildContext context) {
    final theme = TermTheme.of(context);
    final grid = context.termGrid;
    final floor = grid.ceil(DesignTapTargets.of(context).floorOn());
    // A thumb's target: the floor wide, its face one cell in the middle.
    final target = Size(math.max(floor.width, grid.cellWidth), floor.height);
    return DesignRangeSlider(
      values: values,
      onChanged: onChanged,
      min: min,
      max: max,
      divisions: divisions,
      minGap: minGap,
      startLabel: startLabel,
      endLabel: endLabel,
      semanticFormatterCallback: semanticFormatterCallback,
      thumbSize: target,
      trackBuilder: (context, track) => SizedBox(
        height: grid.lineHeight,
        child: CustomPaint(
          painter: _RailPainter(
            grid: grid,
            start: track.start,
            end: track.end,
            thumbs: const [],
            focused: const [],
            rule:
                TermStyleOf([style, theme.sliderStyle], const {}).edge ??
                theme.rule,
            fill: track.enabled
                ? TermStyleOf([style, theme.sliderStyle], const {}).fill ??
                      theme.accent
                : theme.rule,
            thumb: theme.foreground,
            stroke: termStroke(theme, grid),
            textDirection: Directionality.of(context),
            inset: target.width / 2,
          ),
        ),
      ),
      thumbBuilder: (context, index, states) => TermStateSprings(
        pressed: states.contains(WidgetState.pressed),
        focused: states.contains(WidgetState.focused),
        builder: (context, press, focus) => Center(
          child: CustomPaint(
            size: Size(grid.cellWidth, grid.lineHeight),
            painter: _BlockPainter(
              color: states.contains(WidgetState.disabled)
                  ? theme.rule
                  : Color.lerp(
                      TermStyleOf([
                            style,
                            theme.sliderStyle,
                          ], states).foreground ??
                          theme.foreground,
                      theme.accent,
                      focus,
                    )!,
              ring: focus,
              ringColor: theme.accent,
              stroke: termStroke(theme, grid),
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
      ..add(DoubleProperty('start', values.start))
      ..add(DoubleProperty('end', values.end));
  }
}

/// A meter: how full something is, as blocks to the eighth of a cell with
/// dots for the cells left, in green, then yellow past [high]'s warning
/// and red past [full]'s, and the reading after it: `███████▌··· 72%`.
/// A screen reader hears the reading.
///
/// ```dart
/// TermMeter(value: 0.72, label: 'disk', reading: '7.2 of 10 GB')
/// ```
class TermMeter extends StatelessWidget {
  /// A meter [value] full.
  const TermMeter({
    super.key,
    required this.value,
    required this.label,
    this.reading,
    this.cols = 20,
    this.high = 0.7,
    this.full = 0.9,
    this.style,
  });

  /// Overrides, over the theme's [TermThemeData.meterStyle]: `fill` (the
  /// blocks, over the tone's ink) and `edge` (the dots of the cells left).
  final TermStyle? style;

  /// How full, 0 to 1.
  final double value;

  /// What it measures.
  final String label;

  /// The reading written after it; null: the percentage.
  final String? reading;

  /// The bar's width in cells.
  final int cols;

  /// From here the bar warns.
  final double high;

  /// From here the bar is in danger.
  final double full;

  @override
  Widget build(BuildContext context) {
    final theme = TermTheme.of(context);
    final grid = context.termGrid;
    final v = value.clamp(0.0, 1.0);
    final tone = v >= full
        ? TermTone.error
        : v >= high
        ? TermTone.warning
        : TermTone.success;
    final said = reading ?? '${(v * 100).round()}%';
    final own = TermStyleOf([style, theme.meterStyle], const {});
    return Semantics(
      label: label,
      value: said,
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: theme.dimStyle),
          SizedBox(width: grid.cellWidth),
          CustomPaint(
            size: Size(grid.cols(cols), grid.lineHeight),
            painter: TermBlocksPainter(
              grid: grid,
              value: v,
              color: own.fill ?? tone.colorIn(theme),
              track: own.edge ?? theme.rule,
              textDirection: Directionality.of(context),
            ),
          ),
          SizedBox(width: grid.cellWidth),
          Text(said, style: theme.textStyle),
        ],
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DoubleProperty('value', value))
      ..add(StringProperty('label', label));
  }
}

/// A rating: a mark a step, `*` given and `·` not, and the count after it:
/// `* * * · · 3/5`. Brackets close round the marks while it has the
/// keyboard's focus, and the arrows move it a mark, Home and End to none
/// and all. A tap or a drag puts it on a mark (left of the first: none).
/// The pointer over it previews the marks it would give, the one hover a
/// rating keeps. A screen reader hears a slider, "3 of 5".
///
/// ```dart
/// TermRating(
///   semanticLabel: 'how did the deploy go',
///   value: stars,
///   onChanged: (v) => setState(() => stars = v),
/// )
/// ```
class TermRating extends StatefulWidget {
  /// A rating of [value] marks out of [max].
  const TermRating({
    super.key,
    required this.value,
    required this.onChanged,
    required this.semanticLabel,
    this.max = 5,
    this.showCount = true,
    this.focusNode,
    this.autofocus = false,
    this.style,
  }) : assert(max > 0),
       assert(value >= 0 && value <= max);

  /// Overrides, over the theme's [TermThemeData.ratingStyle]: `fill` (the
  /// marks given), `foreground` (the marks left and the count) and `edge`
  /// (the focus brackets).
  final TermStyle? style;

  /// The marks given, 0 to [max].
  final int value;

  /// Called with the marks given; null shows it read-only.
  final ValueChanged<int>? onChanged;

  /// What it rates.
  final String semanticLabel;

  /// How many marks.
  final int max;

  /// Whether `3/5` follows the marks.
  final bool showCount;

  /// {@macro term.focusNode}
  final FocusNode? focusNode;

  /// {@macro term.autofocus}
  final bool autofocus;

  @override
  State<TermRating> createState() => _TermRatingState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IntProperty('value', value))
      ..add(IntProperty('max', max));
  }
}

class _TermRatingState extends State<TermRating> {
  bool _dragging = false;
  int? _preview;

  @override
  Widget build(BuildContext context) {
    final theme = TermTheme.of(context);
    final grid = context.termGrid;
    final cw = grid.cellWidth;
    final touch = DesignTapTargets.of(context).inputOn() == DesignInput.touch;
    final floor = grid.ceil(DesignTapTargets.of(context).floorOn());
    // A mark and its gap; a finger's are wider.
    final per = touch ? 4 : 2;
    final cells = 1 + widget.max * per;
    final width = grid.cols(cells);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final change = widget.onChanged;

    int at(Offset local) {
      final dx = rtl ? width - local.dx : local.dx;
      if (dx < cw) return 0;
      return (((dx - cw) / cw) ~/ per + 1).clamp(0, widget.max);
    }

    void put(Offset local) {
      if (change == null) return;
      final v = at(local);
      if (v != widget.value) change(v);
    }

    final marks = MouseRegion(
      onHover: change == null
          ? null
          : (e) => setState(() => _preview = at(e.localPosition)),
      onExit: (_) => setState(() => _preview = null),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        excludeFromSemantics: true,
        onTapDown: change == null ? null : (d) => put(d.localPosition),
        onHorizontalDragStart: change == null
            ? null
            : (d) {
                setState(() => _dragging = true);
                put(d.localPosition);
              },
        onHorizontalDragUpdate: change == null
            ? null
            : (d) => put(d.localPosition),
        onHorizontalDragEnd: change == null
            ? null
            : (_) => setState(() => _dragging = false),
        child: DesignValueHandle(
          value: widget.value.toDouble(),
          onChanged: change == null ? null : (v) => change(v.round()),
          max: widget.max.toDouble(),
          step: 1,
          divisions: widget.max,
          dragging: _dragging,
          semanticLabel: widget.semanticLabel,
          semanticFormatterCallback: (v) => '${v.round()} of ${widget.max}',
          focusNode: widget.focusNode,
          autofocus: widget.autofocus,
          mouseCursor: change == null
              ? SystemMouseCursors.basic
              : SystemMouseCursors.click,
          minimumSize: Size(width, floor.height),
          builder: (context, states) {
            final own = TermStyleOf([widget.style, theme.ratingStyle], states);
            final disabled = change == null;
            final given = disabled ? theme.dim : own.fill ?? theme.accent;
            final left = disabled ? theme.rule : own.foreground ?? theme.dim;
            final shown = _preview ?? widget.value;
            final focused = states.contains(WidgetState.focused);
            final bracket = TextStyle(color: own.edge ?? theme.accent);
            final pad = ' ' * ((per - 2) ~/ 2);
            return SizedBox(
              width: width,
              height: grid.lineHeight * (touch ? 2 : 1),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text.rich(
                  TextSpan(
                    style: theme.textStyle,
                    children: [
                      TextSpan(text: focused ? '[' : ' ', style: bracket),
                      for (var i = 1; i <= widget.max; i++)
                        TextSpan(
                          text: '$pad${i <= shown ? '*' : '·'}$pad',
                          style: TextStyle(
                            color: i <= shown
                                ? (_preview != null ? theme.foreground : given)
                                : left,
                          ),
                          children: [
                            if (i < widget.max)
                              const TextSpan(text: ' ')
                            else
                              TextSpan(
                                text: focused ? ']' : ' ',
                                style: bracket,
                              ),
                          ],
                        ),
                    ],
                  ),
                  maxLines: 1,
                  softWrap: false,
                ),
              ),
            );
          },
        ),
      ),
    );
    if (!widget.showCount) return marks;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        marks,
        SizedBox(width: cw),
        ExcludeSemantics(
          child: Text('${widget.value}/${widget.max}', style: theme.dimStyle),
        ),
      ],
    );
  }
}

// A rule across the cells, heavy in [fill] from [start] to [end], with a
// block for each of [thumbs] (fractions of the span between [inset]s),
// each on the nearest cell.
class _RailPainter extends CustomPainter {
  _RailPainter({
    required this.grid,
    required this.start,
    required this.end,
    required this.thumbs,
    required this.focused,
    this.pressed = const [],
    required this.rule,
    required this.fill,
    required this.thumb,
    required this.stroke,
    required this.textDirection,
    required this.inset,
  });

  final TermGrid grid;
  final double start;
  final double end;
  final List<double> thumbs;
  final List<double> focused;

  /// How far each thumb is in hand: it fills its whole cell, in the fill.
  final List<double> pressed;
  final Color rule;
  final Color fill;
  final Color thumb;
  final double stroke;
  final TextDirection textDirection;
  final double inset;

  @override
  void paint(Canvas canvas, Size size) {
    final cw = grid.cellWidth;
    final y = size.height / 2;
    final x0 = inset;
    final x1 = size.width - inset;
    double at(double f) {
      final x = x0 + (x1 - x0) * f;
      return textDirection == TextDirection.rtl ? size.width - x : x;
    }

    canvas.drawLine(
      Offset(x0, y),
      Offset(x1, y),
      Paint()
        ..color = rule
        ..strokeWidth = stroke,
    );
    // A thumb on the nearest cell: the block steps, as a terminal's would.
    final cells = math.max(1, (size.width / cw).floor());
    Rect cellOf(double t) {
      final cell = (t * (cells - 1)).round();
      final left = textDirection == TextDirection.rtl
          ? size.width - (cell + 1) * cw
          : cell * cw;
      return Rect.fromLTWH(left, 0, cw, size.height);
    }

    final a = at(start);
    // One thumb: the heavy part runs to its block's middle.
    final b = thumbs.length == 1 ? cellOf(thumbs.first).center.dx : at(end);
    canvas.drawLine(
      Offset(math.min(a, b), y),
      Offset(math.max(a, b), y),
      Paint()
        ..color = fill
        ..strokeWidth = stroke * 3,
    );
    for (final (i, t) in thumbs.indexed) {
      final rect = cellOf(t);
      final p = (i < pressed.length ? pressed[i] : 0.0).clamp(0.0, 1.0);
      canvas.drawRect(
        rect.deflate(size.height * 0.08 * (1 - p)),
        Paint()..color = Color.lerp(thumb, fill, p)!,
      );
      final f = i < focused.length ? focused[i] : 0.0;
      if (f > 0) {
        canvas.drawRect(
          rect.inflate(stroke),
          Paint()
            ..color = fill.withValues(alpha: f)
            ..style = PaintingStyle.stroke
            ..strokeWidth = stroke,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_RailPainter old) =>
      old.start != start ||
      old.end != end ||
      !listEquals(old.thumbs, thumbs) ||
      !listEquals(old.focused, focused) ||
      !listEquals(old.pressed, pressed) ||
      old.rule != rule ||
      old.fill != fill ||
      old.thumb != thumb ||
      old.grid != grid ||
      old.inset != inset ||
      old.textDirection != textDirection;
}

// A thumb: a block one cell wide, ringed in the accent by [ring].
class _BlockPainter extends CustomPainter {
  const _BlockPainter({
    required this.color,
    required this.ring,
    required this.ringColor,
    required this.stroke,
  });

  final Color color;
  final double ring;
  final Color ringColor;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(rect.deflate(size.height * 0.08), Paint()..color = color);
    if (ring > 0) {
      canvas.drawRect(
        rect.inflate(stroke),
        Paint()
          ..color = ringColor.withValues(alpha: ring)
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke,
      );
    }
  }

  @override
  bool shouldRepaint(_BlockPainter old) =>
      old.color != color || old.ring != ring || old.ringColor != ringColor;
}
