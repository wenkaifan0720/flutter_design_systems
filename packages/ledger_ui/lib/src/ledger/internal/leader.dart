import 'package:flutter/widgets.dart';

import '../chrome_metrics.dart';

/// The dot leader as Chrome draws the source's `.leader`: a strip 3 tall
/// tiled every 5 from its start with one dot, centred 1.5 into the tile,
/// solid to .85 and faded out by 1.15 (`radial-gradient(circle at 1.5px
/// 1.5px, ink-4 .85px, transparent 1.15px)` repeated along x), the last
/// tile cut at the strip's end. Plumbing of the leader and the rows.
class LedgerLeaderPainter extends CustomPainter {
  /// Paints the dot leader in [color].
  const LedgerLeaderPainter(this.color);

  /// The dots' colour.
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const c = LedgerChromeMetrics.leaderCentre;
    const fade = LedgerChromeMetrics.leaderFade;
    final clear = color.withValues(alpha: 0);
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    for (
      var x = c;
      x - fade < size.width;
      x += LedgerChromeMetrics.leaderPitch
    ) {
      final centre = Offset(x, c);
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [color, color, clear],
          stops: const [0, LedgerChromeMetrics.leaderDot / fade, 1],
        ).createShader(Rect.fromCircle(center: centre, radius: fade));
      canvas.drawCircle(centre, fade, paint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(LedgerLeaderPainter old) => old.color != color;
}
