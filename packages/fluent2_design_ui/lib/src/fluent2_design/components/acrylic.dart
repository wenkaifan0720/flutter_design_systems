import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import '../theme.dart';

/// Fluent's acrylic under [child], in the theme's recipe
/// ([Fluent2ThemeData.acrylic]), clipped to [radius]: what floats over the
/// page (the tab bar, a pinned top bar, the nav pane over content, a menu),
/// the page behind blurred, a luminosity layer and a tint over it, and a
/// fine noise. One `BackdropFilter` under its fills, cheap enough for a bar
/// over a long list; [solid] stands its opaque fallback in for the blur (on
/// a media ground, under a test, where a page says nothing should blur).
///
/// ```dart
/// Fluent2Acrylic(child: Row(children: commands))
/// ```
class Fluent2Acrylic extends StatelessWidget {
  /// Acrylic under [child].
  const Fluent2Acrylic({
    required this.child,
    this.radius = BorderRadius.zero,
    this.solid = false,
    super.key,
  });

  /// What stands on the acrylic.
  final Widget child;

  /// The corners the acrylic is clipped to.
  final BorderRadiusGeometry radius;

  /// Draw the acrylic's opaque fallback, blurring nothing.
  final bool solid;

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    final a = t.acrylic;
    if (solid) {
      return ClipRRect(
        borderRadius: radius,
        child: ColoredBox(color: a.fallback, child: child),
      );
    }
    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: a.blur, sigmaY: a.blur),
        child: CustomPaint(
          painter: _AcrylicPainter(
            fill: a.fill,
            noise:
                (t.isDark ? const Color(0xFFFFFFFF) : const Color(0xFF000000))
                    .withValues(alpha: a.noiseOpacity),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// The acrylic's fills and its noise: one colour over the blur, then a
/// fixed field of single-pixel grains tiled 64 square, the same on every
/// frame.
class _AcrylicPainter extends CustomPainter {
  _AcrylicPainter({required this.fill, required this.noise});

  final Color fill;
  final Color noise;

  static const double _tile = 64;
  static final Float32List _grains = () {
    final random = math.Random(7);
    const count = 240;
    final points = Float32List(count * 2);
    for (var i = 0; i < count; i++) {
      points[i * 2] = random.nextDouble() * _tile;
      points[i * 2 + 1] = random.nextDouble() * _tile;
    }
    return points;
  }();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = fill);
    if (noise.a == 0) return;
    final grain = Paint()
      ..color = noise
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.square;
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    for (var y = 0.0; y < size.height; y += _tile) {
      for (var x = 0.0; x < size.width; x += _tile) {
        canvas.save();
        canvas.translate(x, y);
        canvas.drawRawPoints(ui.PointMode.points, _grains, grain);
        canvas.restore();
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_AcrylicPainter old) =>
      old.fill != fill || old.noise != noise;
}
