library;

import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../surface.dart';
import '../theme.dart';

/// Lights the inner edge of [child] for keyboard focus. The edge follows
/// the rounded face and moves with its [sink] when the key is held.
/// A transparent [edge] turns off the light.
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
    final light = StudioLight.of(context);
    return AnimatedBuilder(
      animation: _t,
      builder: (context, child) => CustomPaint(
        foregroundPainter: _Edge(
          color: _now,
          light: light,
          radius: widget.radius,
          sink: widget.sink,
        ),
        child: child,
      ),
      child: widget.child,
    );
  }
}

class _Edge extends CustomPainter {
  const _Edge({
    required this.color,
    required this.light,
    required this.radius,
    required this.sink,
  });

  final Color color;
  final StudioLight light;
  final double radius;
  final double sink;

  @override
  void paint(Canvas canvas, Size size) {
    final outline = RRect.fromRectAndRadius(
      (Offset.zero & size).shift(Offset(0, sink)),
      Radius.circular(radius),
    );
    paintStudioFocusLight(canvas, outline, color, light);
  }

  @override
  bool shouldRepaint(_Edge old) =>
      old.color != color ||
      old.light.colors != light.colors ||
      old.radius != radius ||
      old.sink != sink;
}
