/// A value along an inked track, with a circular drag handle.
library;

import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';

import 'theme.dart';
import 'component_themes.dart';
import 'styled.dart';

/// An adjustable value with keyboard, pointer and accessibility actions.
///
/// ```dart
/// ComicSlider(label: 'Budget', value: budget, max: 500, divisions: 10, onChanged: select)
/// ```
class ComicSlider extends StatefulWidget {
  /// Creates a slider. Null onChanged disables all input paths.
  const ComicSlider({
    super.key,
    this.style,
    required this.label,
    required this.value,
    this.min = 0,
    this.max = 1,
    this.divisions,
    this.onChanged,
    this.onChangeEnd,
    this.valueLabel,
    this.focusNode,
    this.quiet = false,
    this.rowWidth = 200,
    this.autofocus = false,
  }) : assert(max > min),
       assert(value >= min && value <= max),
       assert(divisions == null || divisions > 0);

  /// Per-state track and handle appearance.
  final ComicStyle? style;

  /// Accessible and visible name.
  final String label;

  /// Current value in the range.
  final double value;

  /// Minimum value.
  final double min;

  /// Maximum value.
  final double max;

  /// Number of equal steps; null means continuous.
  final int? divisions;

  /// Reports changes while dragging or stepping.
  final ValueChanged<double>? onChanged;

  /// Reports the final value once per completed gesture or key action.
  final ValueChanged<double>? onChangeEnd;

  /// Formats a value; defaults to percent of the range.
  final String Function(double)? valueLabel;

  /// Optional caller-owned focus node.
  final FocusNode? focusNode;

  /// Hides the visible label and value, retaining accessibility.
  final bool quiet;

  /// Width when placed in a row with unbounded width.
  final double rowWidth;

  /// How far the track stands in from each end: the held knob's radius, so the knob at either end stands on the
  /// slider's edge. The range slider ([ComicRangeSlider]) takes the same, so a slider and a range stacked in one column
  /// share their track's ends.
  static const double inset = 12;

  /// Whether the part asks for the focus when it first appears.
  final bool autofocus;

  @override
  State<ComicSlider> createState() => _ComicSliderState();
}

class _ComicSliderState extends State<ComicSlider> {
  final _ownedFocus = FocusNode();
  FocusNode get _focus => widget.focusNode ?? _ownedFocus;
  bool _focused = false, _hovered = false, _dragging = false;
  double? _moved;
  double get _span => widget.max - widget.min;
  double get _step => _span / (widget.divisions ?? 20);
  double _snap(double value) {
    final v = value.clamp(widget.min, widget.max);
    return widget.divisions == null
        ? v
        : widget.min +
              ((v - widget.min) / _span * widget.divisions!).round() /
                  widget.divisions! *
                  _span;
  }

  String _words(double value) =>
      widget.valueLabel?.call(value) ??
      '${((value - widget.min) / _span * 100).round()}%';
  void _set(double value) {
    final next = _snap(value);
    if (next != (_moved ?? widget.value)) widget.onChanged?.call(next);
    _moved = next;
  }

  void _settle() {
    final next = _moved ?? widget.value;
    _moved = null;
    widget.onChangeEnd?.call(next);
  }

  void _stepBy(double by) {
    _set(widget.value + by);
    _settle();
  }

  void _point(Offset point, double width) {
    final ratio = ((point.dx - 12) / math.max(1, width - 24)).clamp(0, 1);
    _set(
      widget.min +
          (Directionality.of(context) == TextDirection.rtl
                  ? 1 - ratio
                  : ratio) *
              _span,
    );
  }

  KeyEventResult _keys(FocusNode node, KeyEvent event) {
    if (widget.onChanged == null ||
        (event is! KeyDownEvent && event is! KeyRepeatEvent)) {
      return KeyEventResult.ignored;
    }
    final rtl = Directionality.of(context) == TextDirection.rtl,
        key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowRight) {
      _set(widget.value + (rtl ? -_step : _step));
    } else if (key == LogicalKeyboardKey.arrowLeft) {
      _set(widget.value + (rtl ? _step : -_step));
    } else if (key == LogicalKeyboardKey.arrowUp) {
      _set(widget.value + _step);
    } else if (key == LogicalKeyboardKey.arrowDown) {
      _set(widget.value - _step);
    } else if (key == LogicalKeyboardKey.home) {
      _set(widget.min);
    } else if (key == LogicalKeyboardKey.end) {
      _set(widget.max);
    } else {
      return KeyEventResult.ignored;
    }
    _settle();
    return KeyEventResult.handled;
  }

  @override
  void dispose() {
    _ownedFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = ComicTheme.of(context), live = widget.onChanged != null;
    final look = ComicStyleOf(
      [widget.style, t.sliderTheme],
      comicStates(
        enabled: live,
        focused: _focused,
        hovered: _hovered,
        pressed: _dragging,
      ),
    );
    final track = LayoutBuilder(
      builder: (context, box) {
        final width = box.hasBoundedWidth ? box.maxWidth : widget.rowWidth;
        return SizedBox(
          width: width,
          height: 48,
          child: Focus(
            canRequestFocus: false,
            skipTraversal: true,
            includeSemantics: false,
            onKeyEvent: _keys,
            child: FocusableActionDetector(
              autofocus: widget.autofocus,
              enabled: live,
              focusNode: _focus,
              // The thumb drags: an open hand over it, a closed one while it moves.
              mouseCursor: !live
                  ? SystemMouseCursors.basic
                  : _dragging
                  ? SystemMouseCursors.grabbing
                  : SystemMouseCursors.grab,
              onShowFocusHighlight: (value) => setState(() => _focused = value),
              onShowHoverHighlight: (value) => setState(() => _hovered = value),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                excludeFromSemantics: true,
                onTapDown: live
                    ? (event) {
                        _focus.requestFocus();
                        _point(event.localPosition, width);
                      }
                    : null,
                onTapUp: live ? (_) => _settle() : null,
                onTapCancel: () => _moved = null,
                onHorizontalDragStart: live
                    ? (event) {
                        _focus.requestFocus();
                        setState(() => _dragging = true);
                        _point(event.localPosition, width);
                      }
                    : null,
                onHorizontalDragUpdate: live
                    ? (event) => _point(event.localPosition, width)
                    : null,
                onHorizontalDragEnd: live
                    ? (_) {
                        setState(() => _dragging = false);
                        _settle();
                      }
                    : null,
                onHorizontalDragCancel: () {
                  setState(() => _dragging = false);
                  _moved = null;
                },
                child: AnimatedComicShape(
                  shape: look.shape ?? t.shapes.capsule,
                  builder: (context, shape) => CustomPaint(
                    painter: _SliderInk(
                      (widget.value - widget.min) / _span,
                      t.colors,
                      Directionality.of(context) == TextDirection.rtl,
                      live,
                      _focused,
                      // The thumb grows under the drag, never under the pointer's approach.
                      _dragging,
                      t.focus,
                      fill: look.fill,
                      foreground: look.foreground,
                      side: comicRim(t, look, t.colors.nightLine, 2),
                      shape: shape,
                      thumb: t.shapes.full,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
    final node = Semantics(
      container: true,
      slider: true,
      label: widget.label,
      value: _words(widget.value),
      enabled: live,
      increasedValue: live ? _words(_snap(widget.value + _step)) : null,
      decreasedValue: live ? _words(_snap(widget.value - _step)) : null,
      onIncrease: live ? () => _stepBy(_step) : null,
      onDecrease: live ? () => _stepBy(-_step) : null,
      child: ExcludeSemantics(child: track),
    );
    return LimitedBox(
      maxWidth: widget.rowWidth,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!widget.quiet)
            ExcludeSemantics(
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                spacing: 12,
                runSpacing: 4,
                children: [
                  Text(widget.label, style: t.type.title),
                  Text(_words(widget.value), style: t.type.body),
                ],
              ),
            ),
          node,
        ],
      ),
    );
  }
}

class _SliderInk extends CustomPainter {
  _SliderInk(
    this.at,
    this.colors,
    this.rtl,
    this.enabled,
    this.focused,
    this.held,
    this.focus, {
    this.fill,
    this.foreground,
    this.side,
    this.shape,
    required this.thumb,
  });
  final Color? fill, foreground;
  final BorderSide? side;
  final OutlinedBorder? shape;
  final OutlinedBorder thumb;
  final double at;
  final ComicColors colors;
  final bool rtl, enabled, focused, held;
  final ComicFocusRing focus;
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(
          ComicSlider.inset,
          size.height / 2 - 4,
          math.max(0, size.width - 2 * ComicSlider.inset),
          8,
        ),
        x = ComicSlider.inset + (rtl ? 1 - at : at) * rect.width;
    final paint = Paint();
    final path =
        shape?.getOuterPath(
          rect,
          textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
        ) ??
        (Path()..addRect(rect));
    canvas.drawPath(path, paint..color = colors.track);
    canvas.save();
    canvas.clipPath(path);
    canvas.drawRect(
      Rect.fromLTRB(
        rtl ? x : rect.left,
        rect.top,
        rtl ? rect.right : x,
        rect.bottom,
      ),
      paint
        ..color = fill ?? (enabled ? colors.primaryText : colors.textSecondary),
    );
    canvas.restore();
    canvas.drawPath(
      path,
      paint
        ..style = PaintingStyle.stroke
        ..strokeWidth = side?.width ?? 2
        ..color = side?.color ?? colors.nightLine,
    );
    final knob = Rect.fromCenter(
      center: Offset(x, size.height / 2),
      width: held ? 24 : 22,
      height: held ? 24 : 22,
    );
    final knobPath = thumb.getOuterPath(knob);
    canvas.drawPath(
      knobPath,
      paint
        ..style = PaintingStyle.fill
        ..color = foreground ?? (enabled ? colors.caption : colors.unlit),
    );
    canvas.drawPath(
      knobPath,
      paint
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = colors.nightLine,
    );
    if (focused) {
      canvas.drawPath(
        thumb.getOuterPath(knob.inflate(focus.gap)),
        paint
          ..strokeWidth = focus.width
          ..color = focus.color,
      );
    }
  }

  @override
  bool shouldRepaint(_SliderInk old) =>
      old.at != at ||
      old.colors != colors ||
      old.rtl != rtl ||
      old.enabled != enabled ||
      old.focused != focused ||
      old.held != held ||
      old.focus != focus ||
      old.fill != fill ||
      old.foreground != foreground ||
      old.side != side ||
      old.thumb != thumb ||
      old.shape != shape;
}
