/// The one indicator Studio's fields with choices share: a select, a
/// combobox.
library;

import 'package:flutter/widgets.dart';

/// The stepper glyph a field with choices shows at its end: a small pair
/// of wedges, up and down, easing to a new [color].
class StudioStepperGlyph extends StatelessWidget {
  /// A glyph in [color].
  const StudioStepperGlyph({super.key, required this.color});

  /// The wedges' ink.
  final Color color;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<Color?>(
    tween: ColorTween(end: color),
    duration: MediaQuery.maybeDisableAnimationsOf(context) ?? false
        ? Duration.zero
        : const Duration(milliseconds: 160),
    builder: (context, color, _) => CustomPaint(
      size: const Size(10, 14),
      painter: _WedgesPainter(color ?? this.color),
    ),
  );
}

class _WedgesPainter extends CustomPainter {
  _WedgesPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final paint = Paint()..color = color;
    canvas
      ..drawPath(
        Path()
          ..moveTo(0, h * 0.42)
          ..lineTo(w / 2, 0)
          ..lineTo(w, h * 0.42)
          ..close(),
        paint,
      )
      ..drawPath(
        Path()
          ..moveTo(0, h * 0.58)
          ..lineTo(w / 2, h)
          ..lineTo(w, h * 0.58)
          ..close(),
        paint,
      );
  }

  @override
  bool shouldRepaint(_WedgesPainter old) => old.color != color;
}
