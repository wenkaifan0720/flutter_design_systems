import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../theme.dart';
import 'paint.dart';
import 'spring.dart';

/// A slider's measures.
abstract final class CivicSliderMetrics {
  /// The strip a slider stands in: a finger's height.
  static const double strip = 48;

  /// The track's height, its edge included.
  static const double track = 12;

  /// The thumb's face: as wide, and as tall with its solid edge.
  static const Size thumb = Size(28, 40);
}

/// The thumb of a slider or a range slider: a face in the action colour on
/// its solid edge, which a drag sinks onto; a pointer deepens it, the
/// keyboard floods it yellow over the ink bar. Plumbing.
class CivicSliderThumb extends StatelessWidget {
  /// A thumb drawn for [states].
  const CivicSliderThumb({
    super.key,
    required this.states,
    this.styles = const [],
  });

  /// Its states: hovered, focused, pressed (dragged), disabled.
  final Set<WidgetState> states;

  /// The styles it reads: fill, foreground (unused) and edge.
  final List<RawStyle?> styles;

  @override
  Widget build(BuildContext context) {
    final t = context.civicTheme;
    final so = RawStyleOf(styles, states);
    final disabled = states.contains(WidgetState.disabled);
    final fill = disabled ? t.disabledFill : (so.fill ?? t.action);
    final edge = disabled ? t.rule : (so.edge ?? t.actionEdge);
    final hovered = !disabled && states.contains(WidgetState.hovered);
    final pressed = !disabled && states.contains(WidgetState.pressed);
    final focused = states.contains(WidgetState.focused);
    return CivicSpringValue(
      value: hovered || pressed ? 1 : 0,
      spring: CivicMotion.press,
      effects: true,
      builder: (context, hover, _) => CivicSpringValue(
        value: pressed ? 1 : 0,
        spring: CivicMotion.press,
        builder: (context, press, _) => CivicSpringValue(
          value: focused ? 1 : 0,
          spring: CivicMotion.focus,
          effects: true,
          builder: (context, focus, _) {
            final over = t.isDark
                ? Color.lerp(fill, const Color(0xFFFFFFFF), 0.25)!
                : Color.lerp(fill, const Color(0xFF000000), 0.35)!;
            return CustomPaint(
              size: CivicSliderMetrics.thumb,
              painter: CivicFacePainter(
                fill: disabled ? fill : Color.lerp(fill, over, hover)!,
                edgeColor: edge,
                edgeHeight: CivicMetrics.bar,
                press: press,
                focus: focus,
                focusColor: t.focus,
                barColor: t.focusBar,
                radius: CivicMetrics.corner,
              ),
              // Two grip lines, so the face reads as something to hold.
              foregroundPainter: _Grip(
                color: Color.lerp(
                  disabled ? t.textDisabled : t.onAction,
                  t.onFocus,
                  focus,
                )!,
                sink: CivicMetrics.bar * press,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Grip extends CustomPainter {
  _Grip({required this.color, required this.sink});

  final Color color;
  final double sink;

  @override
  void paint(Canvas canvas, Size size) {
    final face = size.height - CivicMetrics.bar;
    final mid = sink + face / 2;
    final paint = Paint()..color = color;
    for (final dx in [-3.0, 3.0]) {
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(size.width / 2 + dx, mid),
          width: 2,
          height: face * 0.4,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_Grip old) => old.color != color || old.sink != sink;
}

/// Paints a slider's track: a well [CivicSliderMetrics.track] tall across
/// the strip's middle, filled in the action colour from [from] to [to]
/// (0 to 1 from the start edge); the ends sit [inset] in from each side so
/// a thumb at an end stands whole on the track.
class CivicTrackPainter extends CustomPainter {
  /// A track.
  CivicTrackPainter({
    required this.from,
    required this.to,
    required this.inset,
    required this.rtl,
    required this.well,
    required this.edge,
    required this.fill,
    this.overhang = 0,
    this.ticks = 0,
    this.tick,
  });

  /// Where the filled part starts, 0 to 1.
  final double from;

  /// Where it ends, 0 to 1.
  final double to;

  /// How far in from each side the ends sit.
  final double inset;

  /// Whether the start is on the right.
  final bool rtl;

  /// How far the well runs past each side of the box: a range's track box
  /// spans its thumbs' centres, and its well the whole row.
  final double overhang;

  /// The track's ground.
  final Color well;

  /// Its edge.
  final Color edge;

  /// The filled part.
  final Color fill;

  /// How many steps the track snaps to: a mark at each, when 2 to 20.
  final int ticks;

  /// The marks' colour.
  final Color? tick;

  @override
  void paint(Canvas canvas, Size size) {
    final h = CivicSliderMetrics.track;
    final top = (size.height - h) / 2;
    final rect = Rect.fromLTWH(-overhang, top, size.width + 2 * overhang, h);
    canvas.drawRect(rect, Paint()..color = well);
    final span = size.width - 2 * inset;
    double x(double f) =>
        rtl ? size.width - inset - f * span : inset + f * span;
    // A slider's fill runs from the track's start edge; a range's between
    // its thumbs.
    final start = from == 0 ? (rtl ? rect.right : rect.left) : x(from);
    final end = x(to);
    canvas.drawRect(
      Rect.fromLTRB(math.min(start, end), top, math.max(start, end), top + h),
      Paint()..color = fill,
    );
    canvas.drawRect(
      rect.deflate(CivicMetrics.edge / 2),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = CivicMetrics.edge
        ..color = edge,
    );
    final tick = this.tick;
    if (tick != null && ticks >= 2 && ticks <= 20) {
      final paint = Paint()..color = tick;
      for (var i = 0; i <= ticks; i++) {
        final cx = x(i / ticks);
        canvas.drawRect(Rect.fromLTWH(cx - 1, top + h + 4, 2, 6), paint);
      }
    }
  }

  @override
  bool shouldRepaint(CivicTrackPainter old) =>
      old.from != from ||
      old.to != to ||
      old.inset != inset ||
      old.overhang != overhang ||
      old.rtl != rtl ||
      old.well != well ||
      old.edge != edge ||
      old.fill != fill ||
      old.ticks != ticks ||
      old.tick != tick;
}
