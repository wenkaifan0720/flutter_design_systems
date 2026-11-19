/// Studio's keyboard focus as lit gear shows it: the part's own edge lights
/// amber and the indicator's light spills round it, with no ring drawn
/// apart from the part.
library;

import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../theme.dart';

/// [child], a face with [radius] corners, lit from behind while [edge]
/// shows: the light comes out of the gap round the face, 3 px of [edge]
/// hugging its outline with no gap (3:1 and more against what is round the
/// part, over more than a 2 px perimeter, by day and by night), and a soft
/// amber glow beyond it. The face itself and its words are untouched.
/// [sink] moves the light with a key pressed into its socket. A transparent
/// [edge] puts the light out; it comes and goes on the lamp's spring, cut
/// under Reduce Motion.
class StudioFocusLight extends StatefulWidget {
  /// [child] lit in [edge].
  const StudioFocusLight({
    super.key,
    required this.edge,
    required this.radius,
    required this.child,
    this.sink = 0,
  });

  /// The edge light; transparent when the part has no focus.
  final Color edge;

  /// The face's corners.
  final double radius;

  /// How far the face has sunk into its socket.
  final double sink;

  /// The face.
  final Widget child;

  @override
  State<StudioFocusLight> createState() => _StudioFocusLightState();
}

class _StudioFocusLightState extends State<StudioFocusLight>
    with SingleTickerProviderStateMixin {
  late final AnimationController _t = AnimationController(
    vsync: this,
    value: 1,
  );
  late Color _from = widget.edge;
  late Color _to = widget.edge;

  Color get _now => Color.lerp(_from, _to, _t.value.clamp(0.0, 1.0))!;

  @override
  void didUpdateWidget(StudioFocusLight old) {
    super.didUpdateWidget(old);
    if (widget.edge == _to) return;
    _from = _now;
    _to = widget.edge;
    _t.value = 0;
    _t.springTo(
      1,
      DesignMotionPolicy.of(context).effects(
        dampingRatio: StudioMotion.dampingRatio,
        stiffness: StudioMotion.lampStiffness,
      ),
    );
  }

  @override
  void dispose() {
    _t.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = StudioTheme.of(context).colors;
    return AnimatedBuilder(
      animation: _t,
      builder: (context, child) {
        final edge = _now;
        return CustomPaint(
          painter: _Glow(
            color: c.indicator.withValues(
              alpha: edge.a * (c.brightness == Brightness.dark ? 0.55 : 0.7),
            ),
            radius: widget.radius,
            sink: widget.sink,
          ),
          foregroundPainter: _Edge(
            color: edge,
            radius: widget.radius,
            sink: widget.sink,
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

// The lit band's width, all of it outside the face.
const double _band = StudioMetrics.focusWidth;

RRect _face(Size size, double radius, double sink) => RRect.fromRectAndRadius(
  (Offset.zero & size).shift(Offset(0, sink)),
  Radius.circular(radius),
);

class _Glow extends CustomPainter {
  _Glow({required this.color, required this.radius, required this.sink});

  final Color color;
  final double radius;
  final double sink;

  @override
  void paint(Canvas canvas, Size size) {
    if (color.a == 0) return;
    // Only outside the face: nothing lights behind its words.
    canvas.drawRRect(
      _face(size, radius, sink),
      Paint()
        ..color = color
        ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 6),
    );
  }

  @override
  bool shouldRepaint(_Glow old) =>
      old.color != color || old.radius != radius || old.sink != sink;
}

class _Edge extends CustomPainter {
  _Edge({required this.color, required this.radius, required this.sink});

  final Color color;
  final double radius;
  final double sink;

  @override
  void paint(Canvas canvas, Size size) {
    if (color.a == 0) return;
    canvas.drawRRect(
      _face(size, radius, sink).inflate(_band / 2),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = _band
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_Edge old) =>
      old.color != color || old.radius != radius || old.sink != sink;
}
