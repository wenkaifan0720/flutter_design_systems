/// The chevron Gloss's openers share.
library;

import 'package:flutter/widgets.dart';

/// The chevron of a field or key that opens a list: it turns over as the
/// list opens.
class GlossChevron extends StatelessWidget {
  /// A chevron in [color], turned over while [open].
  const GlossChevron({super.key, required this.open, required this.color});

  /// Whether its list is open.
  final bool open;

  /// Its ink.
  final Color color;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(end: open ? 0.5 : 0),
    duration: MediaQuery.maybeDisableAnimationsOf(context) ?? false
        ? Duration.zero
        : const Duration(milliseconds: 180),
    curve: Curves.easeOutBack,
    builder: (context, turns, _) => Transform.rotate(
      angle: turns * 6.283185307179586,
      child: CustomPaint(
        size: const Size(10, 6),
        painter: _ChevronPainter(color),
      ),
    ),
  );
}

class _ChevronPainter extends CustomPainter {
  _ChevronPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      Path()
        ..moveTo(0.5, 0.5)
        ..lineTo(size.width / 2, size.height - 0.5)
        ..lineTo(size.width - 0.5, 0.5),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_ChevronPainter old) => old.color != color;
}

/// The choices on a porcelain panel rounded 16; a lit row is a plate
/// inset 4 px, its corners 12, concentric with the panel's.
