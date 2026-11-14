import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../internal/hit_slop.dart';
import '../../internal/key_focus.dart';
import '../../internal/well.dart';
import '../../styled.dart';
import '../../theme.dart';

/// A slider's size, Fluent's `size`: [medium] a 20 thumb on a 4 rail, 32
/// tall; [small] a 16 thumb on a 2 rail, 24 tall; either 48 tall under a
/// finger.
enum Fluent2SliderSize {
  /// The small size.
  small,

  /// The medium size.
  medium,
}

/// Fluent 2's Slider: a value between [min] and [max] along a rail (4,
/// its corners 8) in the accessible stroke, filled in the brand
/// (`compoundBrandBackground`) up to the thumb: a 20 disc of the surface
/// with its 1 `neutralStroke1` edge round a 12 brand disc (the brand
/// ring). With [step] the value snaps and the rail is cut at each step. A
/// drag or a tap on the rail moves it, as do the arrow keys (a step, or a
/// hundredth), Page Up and Down (a tenth), Home and End; [onChanged] gets
/// each value and [onChangeEnd] the one let go at. Read as a slider named
/// [label] saying [valueLabel]'s words (the value by default). Null
/// [onChanged] draws it disabled.
///
/// ```dart
/// Fluent2Slider(label: 'Volume', value: volume, onChanged: (v) => setState(() => volume = v))
/// ```
class Fluent2Slider extends StatefulWidget {
  /// A slider at [value] between [min] and [max].
  const Fluent2Slider({
    required this.value,
    required this.onChanged,
    required this.label,
    this.min = 0,
    this.max = 100,
    this.step,
    this.size = Fluent2SliderSize.medium,
    this.valueLabel,
    this.onChangeEnd,
    this.focusNode,
    this.autofocus = false,
    super.key,
  }) : assert(max > min, 'a slider spans a range');

  /// The value the thumb stands at.
  final double value;

  /// Called with the value as the thumb moves; null puts it out of use.
  final ValueChanged<double>? onChanged;

  /// Called with the value when the thumb is let go.
  final ValueChanged<double>? onChangeEnd;

  /// The spoken name.
  final String label;

  /// The value at the track's start.
  final double min;

  /// The value at the track's end.
  final double max;

  /// The step it snaps to; null is continuous.
  final double? step;

  /// Fluent's `size`: the track's and thumb's size.
  final Fluent2SliderSize size;

  /// The control's focus node; null makes and disposes its own.
  final FocusNode? focusNode;

  /// Whether the control takes focus when it first builds.
  final bool autofocus;

  /// The spoken value; null says the number.
  final String Function(double value)? valueLabel;

  @override
  State<Fluent2Slider> createState() => _Fluent2SliderState();
}

class _Fluent2SliderState extends State<Fluent2Slider> {
  bool _over = false;
  bool _down = false;

  bool get _live => widget.onChanged != null;

  double get _thumb => widget.size == Fluent2SliderSize.small ? 16 : 20;

  double get _inner => widget.size == Fluent2SliderSize.small ? 5 : 6;

  double _snap(double v) {
    final step = widget.step;
    var out = v.clamp(widget.min, widget.max).toDouble();
    if (step != null && step > 0) {
      out = widget.min + ((out - widget.min) / step).round() * step;
      out = out.clamp(widget.min, widget.max).toDouble();
    }
    return out;
  }

  void _set(double v) {
    final next = _snap(v);
    if (next != widget.value) widget.onChanged?.call(next);
  }

  void _at(Offset local, double width) {
    final rail = math.max(1.0, width - _thumb);
    var p = ((local.dx - _thumb / 2) / rail).clamp(0.0, 1.0);
    if (Directionality.of(context) == TextDirection.rtl) p = 1 - p;
    _set(widget.min + p * (widget.max - widget.min));
  }

  double get _nudge => widget.step ?? (widget.max - widget.min) / 100;

  String _say(double v) =>
      widget.valueLabel?.call(v) ??
      (v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1));

  void _end() {
    if (_down) setState(() => _down = false);
    widget.onChangeEnd?.call(widget.value);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    final live = _live;
    final small = widget.size == Fluent2SliderSize.small;
    final span = widget.max - widget.min;
    final p = ((widget.value - widget.min) / span).clamp(0.0, 1.0);
    final up = _snap(widget.value + _nudge);
    final down = _snap(widget.value - _nudge);
    final keys = <LogicalKeyboardKey, VoidCallback>{
      LogicalKeyboardKey.arrowRight: () => _set(widget.value + _nudge),
      LogicalKeyboardKey.arrowUp: () => _set(widget.value + _nudge),
      LogicalKeyboardKey.arrowLeft: () => _set(widget.value - _nudge),
      LogicalKeyboardKey.arrowDown: () => _set(widget.value - _nudge),
      LogicalKeyboardKey.pageUp: () => _set(widget.value + span / 10),
      LogicalKeyboardKey.pageDown: () => _set(widget.value - span / 10),
      LogicalKeyboardKey.home: () => _set(widget.min),
      LogicalKeyboardKey.end: () => _set(widget.max),
    };
    final step = widget.step;
    final marks = step == null || step <= 0 ? 0 : (span / step).round();
    final look = Fluent2StyleOf([
      t.sliderTheme,
    ], fluent2States(enabled: live, hovered: _over, pressed: _down));
    return Semantics(
      container: true,
      slider: true,
      enabled: live,
      focusable: live,
      label: widget.label,
      value: _say(widget.value),
      increasedValue: live ? _say(up) : null,
      decreasedValue: live ? _say(down) : null,
      onIncrease: live ? () => _set(up) : null,
      onDecrease: live ? () => _set(down) : null,
      child: Fluent2HitSlop(
        child: Fluent2KeyFocus(
          focusNode: widget.focusNode,
          autofocus: widget.autofocus,
          enabled: live,
          keys: live ? keys : const {},
          radius: Fluent2Radius.medium,
          ringInsets: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: MouseRegion(
            cursor: live ? SystemMouseCursors.click : MouseCursor.defer,
            onEnter: live ? (_) => setState(() => _over = true) : null,
            onExit: live ? (_) => setState(() => _over = false) : null,
            child: LayoutBuilder(
              builder: (context, box) {
                final width = box.maxWidth.isFinite ? box.maxWidth : 240.0;
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: live
                      ? (d) {
                          setState(() => _down = true);
                          _at(d.localPosition, width);
                        }
                      : null,
                  onTapUp: live ? (_) => _end() : null,
                  onTapCancel: live
                      ? () => setState(() => _down = false)
                      : null,
                  onHorizontalDragStart: live
                      ? (d) {
                          setState(() => _down = true);
                          _at(d.localPosition, width);
                        }
                      : null,
                  onHorizontalDragUpdate: live
                      ? (d) => _at(d.localPosition, width)
                      : null,
                  onHorizontalDragEnd: live ? (_) => _end() : null,
                  dragStartBehavior: DragStartBehavior.down,
                  // Under a finger the rail stands in a whole target (48).
                  child: SizedBox(
                    width: width,
                    height: Fluent2Layout.padded(context)
                        ? Fluent2Layout.touchHitTarget
                        : small
                        ? 24
                        : 32,
                    child: CustomPaint(
                      painter: _SliderPainter(
                        progress: p,
                        thumb: _thumb,
                        inner: _inner,
                        rail: small ? 2 : 4,
                        marks: marks,
                        rtl: Directionality.of(context) == TextDirection.rtl,
                        // The slider theme's colours over Fluent's, in its
                        // states: `fill` (the filled rail and the thumb's
                        // core), `foreground` (the rest of the rail),
                        // `edge` (the thumb's rim).
                        railInk:
                            look.foreground ??
                            (live
                                ? t.colors.neutralStrokeAccessible
                                // Fluent's disabled rail, as a step over
                                // the ground.
                                : fluent2Step(
                                    t,
                                    t.colors.neutralStrokeDisabled,
                                  )),
                        fill:
                            look.fill ??
                            (!live
                                ? t.colors.neutralForegroundDisabled
                                : _down
                                ? t.colors.compoundBrandBackgroundPressed
                                : _over
                                ? t.colors.compoundBrandBackgroundHover
                                : t.colors.compoundBrandBackground),
                        ground: t.colors.neutralBackground1,
                        edge:
                            look.edge ??
                            (live
                                ? t.colors.neutralStroke1
                                : t.colors.neutralForegroundDisabled),
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
  }
}

class _SliderPainter extends CustomPainter {
  const _SliderPainter({
    required this.progress,
    required this.thumb,
    required this.inner,
    required this.rail,
    required this.marks,
    required this.rtl,
    required this.railInk,
    required this.fill,
    required this.ground,
    required this.edge,
  });

  final double progress;
  final double thumb;
  final double inner;
  final double rail;
  final int marks;
  final bool rtl;
  final Color railInk;
  final Color fill;
  final Color ground;
  final Color edge;

  @override
  void paint(Canvas canvas, Size size) {
    // The rail spans the width less the thumb, centred; the thumb's
    // centre keeps its inner radius inside the rail's ends.
    final left = thumb / 2;
    final width = math.max(0.0, size.width - thumb);
    final cy = size.height / 2;
    final railRect = Rect.fromLTWH(left, cy - rail / 2, width, rail);
    final r = Radius.circular(Fluent2Radius.xLarge);
    final at = progress * width;
    canvas.drawRRect(
      RRect.fromRectAndRadius(railRect, r),
      Paint()..color = railInk,
    );
    final filled = rtl
        ? Rect.fromLTRB(
            railRect.right - at,
            railRect.top,
            railRect.right,
            railRect.bottom,
          )
        : Rect.fromLTRB(
            railRect.left,
            railRect.top,
            railRect.left + at,
            railRect.bottom,
          );
    canvas.save();
    canvas.clipRRect(RRect.fromRectAndRadius(railRect, r));
    canvas.drawRect(filled, Paint()..color = fill);
    // The steps: a 1 cut of the surface at each step's end.
    if (marks > 1) {
      final cut = Paint()..color = ground;
      for (var i = 1; i < marks; i++) {
        final x = railRect.left + width * i / marks;
        canvas.drawRect(Rect.fromLTWH(x - 1, railRect.top, 1, rail), cut);
      }
    }
    canvas.restore();
    final clamped = at.clamp(inner, math.max(inner, width - inner));
    final cx = rtl ? railRect.right - clamped : railRect.left + clamped;
    final centre = Offset(cx, cy);
    canvas.drawCircle(centre, thumb / 2, Paint()..color = ground);
    canvas.drawCircle(centre, thumb / 2 - thumb * 0.2, Paint()..color = fill);
    canvas.drawCircle(
      centre,
      thumb / 2 - thumb * 0.025,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = thumb * 0.05
        ..color = edge,
    );
  }

  @override
  bool shouldRepaint(_SliderPainter old) =>
      old.progress != progress ||
      old.thumb != thumb ||
      old.rail != rail ||
      old.marks != marks ||
      old.rtl != rtl ||
      old.railInk != railInk ||
      old.fill != fill ||
      old.ground != ground ||
      old.edge != edge;
}
