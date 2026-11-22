/// Text measurements and small line icons used by Appliance controls.
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

/// The legend at the end of a field that opens a list (a select's key, a
/// combobox's well): a small chevron up over one down.
class ApplianceUpDownPainter extends CustomPainter {
  /// The legend in [color].
  ApplianceUpDownPainter(this.color);

  /// The legend's box.
  static const Size size = Size(10, 16);

  /// Its colour.
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas
      ..drawPath(
        Path()
          ..moveTo(1, h * 0.38)
          ..lineTo(w / 2, h * 0.12)
          ..lineTo(w - 1, h * 0.38),
        paint,
      )
      ..drawPath(
        Path()
          ..moveTo(1, h * 0.62)
          ..lineTo(w / 2, h * 0.88)
          ..lineTo(w - 1, h * 0.62),
        paint,
      );
  }

  @override
  bool shouldRepaint(ApplianceUpDownPainter old) => old.color != color;
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

/// The size of a single unwrapped label at the current text scale.
Size applianceLabelSize(BuildContext context, String value, TextStyle style) {
  final painter = TextPainter(
    text: TextSpan(text: value, style: style),
    textDirection: Directionality.of(context),
    textScaler: MediaQuery.textScalerOf(context),
  )..layout();
  final size = painter.size;
  painter.dispose();
  return size;
}
