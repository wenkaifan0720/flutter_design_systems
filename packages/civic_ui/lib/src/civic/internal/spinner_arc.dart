import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

/// The turning arc of a wait: a square-ended quarter and a bit, turning
/// once a second on a hairline ring, [size] across. Under Reduce Motion it
/// stands still at its start; it says nothing (its part says the words).
/// With [filled] it stands still, that share of the ring drawn from twelve
/// o'clock (a pull on its way to a refresh).
class CivicSpinnerArc extends StatefulWidget {
  /// An arc in [color] on a [ring].
  const CivicSpinnerArc({
    super.key,
    required this.size,
    required this.color,
    required this.ring,
    this.filled,
  });

  /// The share of the ring drawn, 0 to 1, still; null: it turns.
  final double? filled;

  /// Across.
  final double size;

  /// The arc.
  final Color color;

  /// The ring under it.
  final Color ring;

  @override
  State<CivicSpinnerArc> createState() => _CivicSpinnerArcState();
}

class _CivicSpinnerArcState extends State<CivicSpinnerArc>
    with SingleTickerProviderStateMixin {
  late final AnimationController _turn = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 1),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _run();
  }

  @override
  void didUpdateWidget(CivicSpinnerArc old) {
    super.didUpdateWidget(old);
    if ((old.filled == null) != (widget.filled == null)) _run();
  }

  void _run() {
    if (widget.filled != null || RawMotionPolicy.of(context).reduceMotion) {
      _turn
        ..stop()
        ..value = 0;
    } else if (!_turn.isAnimating) {
      _turn.repeat();
    }
  }

  @override
  void dispose() {
    _turn.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: CustomPaint(
      size: Size.square(widget.size),
      painter: _Arc(
        turn: _turn,
        color: widget.color,
        ring: widget.ring,
        filled: widget.filled,
        rtl: Directionality.of(context) == TextDirection.rtl,
      ),
    ),
  );
}

class _Arc extends CustomPainter {
  _Arc({
    required this.turn,
    required this.color,
    required this.ring,
    required this.filled,
    required this.rtl,
  }) : super(repaint: turn);

  final Animation<double> turn;
  final Color color;
  final Color ring;
  final double? filled;
  final bool rtl;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = math.max(2.0, size.shortestSide / 8);
    final box = (Offset.zero & size).deflate(stroke / 2);
    canvas.drawArc(
      box,
      0,
      2 * math.pi,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = ring,
    );
    // Clockwise, or the other way for a reader who reads right to left.
    final along = rtl ? -1.0 : 1.0;
    final share = filled;
    canvas.drawArc(
      box,
      share != null
          ? -math.pi / 2
          : -math.pi / 2 + along * turn.value * 2 * math.pi,
      along * 2 * math.pi * (share?.clamp(0.0, 1.0) ?? 0.3),
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.butt
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_Arc old) =>
      old.color != color ||
      old.ring != ring ||
      old.filled != filled ||
      old.rtl != rtl;
}
