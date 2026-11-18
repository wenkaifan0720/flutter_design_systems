/// The look's small line glyphs, drawn with one stroke: a lens, a cross, and
/// the widget that paints one in the ambient icon colour.
library;

import 'package:flutter/widgets.dart';

/// A lens drawn with the stroke the look's glyphs use.
class ApplianceLensPainter extends CustomPainter {
  /// A lens in [color].
  ApplianceLensPainter(this.color);

  /// Its colour.
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    canvas
      ..drawCircle(Offset(s * 0.44, s * 0.44), s * 0.3, paint)
      ..drawLine(Offset(s * 0.66, s * 0.66), Offset(s * 0.88, s * 0.88), paint);
  }

  @override
  bool shouldRepaint(ApplianceLensPainter old) => old.color != color;
}

/// A cross drawn with the stroke the look's glyphs use.
class ApplianceCrossPainter extends CustomPainter {
  /// A cross in [color].
  ApplianceCrossPainter(this.color);

  /// Its colour.
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    canvas
      ..drawLine(Offset(s * 0.25, s * 0.25), Offset(s * 0.75, s * 0.75), paint)
      ..drawLine(Offset(s * 0.75, s * 0.25), Offset(s * 0.25, s * 0.75), paint);
  }

  @override
  bool shouldRepaint(ApplianceCrossPainter old) => old.color != color;
}

/// A glyph painted in the ambient icon colour at the ambient icon size.
class ApplianceGlyph extends StatelessWidget {
  /// The glyph [painter] draws.
  const ApplianceGlyph(this.painter, {super.key});

  /// Makes the painter in a colour.
  final CustomPainter Function(Color color) painter;

  @override
  Widget build(BuildContext context) {
    final icon = IconTheme.of(context);
    final size = icon.size ?? 20;
    return CustomPaint(
      size: Size.square(size),
      painter: painter(icon.color ?? const Color(0xFF000000)),
    );
  }
}
