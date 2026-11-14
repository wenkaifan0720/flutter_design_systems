import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../chrome_metrics.dart';
import '../../theme.dart';
import '../host.dart';

/// A picture: a photo ([image]) fading in over a ground of the system's own
/// making, in a hairline frame of the glass edge with corners of 14. The
/// ground is the night the system keeps over media: the dark canvas under
/// its three washes of light and a ribbon of the prism's band, each placed
/// from the [seed] alone (a title, an id), so the same words give the same
/// ground and a list of pictures that have not loaded, or never will, still
/// reads as a set. Without a photo the ground stands as the picture. It
/// takes the width it is given; with [aspect] (width over height) it sets
/// its own height, else it fills the height given. [child] is the media
/// slot, laid over the picture in the night's ink ([FrostedMediaGround]: a
/// duration, a tag, a play mark). With [label] it is read as an image;
/// without, as decoration. DERIVED: the source has no pictures; the ground
/// is drawn from the night theme and its lights.
///
/// ```dart
/// FrostedMedia(image: NetworkImage(cover), seed: 'Lisbon in May', aspect: 16 / 9, label: 'Lisbon in May')
/// ```
///
/// ```dart
/// FrostedMedia(seed: 'Harbor Transit', aspect: 1, radius: FrostedCorners.r10)
/// ```
class FrostedMedia extends StatelessWidget {
  /// Creates a [FrostedMedia].
  const FrostedMedia({
    this.image,
    this.seed = '',
    this.aspect,
    this.radius,
    this.fit = BoxFit.cover,
    this.label,
    this.child,
    super.key,
  });

  /// The photo; null leaves the ground.
  final ImageProvider? image;

  /// What the ground is drawn from.
  final String seed;

  /// The picture's width over its height; null fills the height given.
  final double? aspect;

  /// The corners; null takes 14, a tile's inner pane.
  final double? radius;

  /// How the photo fills the picture.
  final BoxFit fit;

  /// What a screen reader says; null leaves the picture as decoration.
  final String? label;

  /// A part laid over the picture, in the night's ink.
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    final night = FrostedTheme.darkOf(context);
    final corners = BorderRadius.circular(radius ?? FrostedCorners.r14);
    final duration = FrostedMotion.of(context).base;
    final photo = image;
    Widget picture = ClipRRect(
      borderRadius: corners,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(
            painter: _GroundPainter(seed: seed, night: night),
          ),
          if (photo != null)
            Image(
              image: photo,
              fit: fit,
              gaplessPlayback: true,
              frameBuilder: (context, picture, frame, sync) => AnimatedOpacity(
                opacity: sync || frame != null ? 1 : 0,
                duration: duration,
                child: picture,
              ),
              errorBuilder: (context, error, stack) => const SizedBox.shrink(),
            ),
          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: corners,
              border: Border.all(
                color: t.glass.edge,
                width: FrostedChromeMetrics.outline,
              ),
            ),
          ),
        ],
      ),
    );
    picture = label == null
        ? ExcludeSemantics(child: picture)
        : Semantics(
            label: label,
            image: true,
            child: ExcludeSemantics(child: picture),
          );
    final over = child;
    final framed = over == null
        ? picture
        : Stack(
            fit: StackFit.passthrough,
            children: [
              picture,
              FrostedMediaGround(child: over),
            ],
          );
    final ratio = aspect;
    return ratio == null
        ? framed
        : AspectRatio(aspectRatio: ratio, child: framed);
  }
}

/// A picture's ground: the night canvas, its three washes of light and the
/// ribbon of the prism's band, each placed from [seed] and nothing else.
class _GroundPainter extends CustomPainter {
  _GroundPainter({required this.seed, required this.night});

  final String seed;
  final FrostedThemeData night;

  /// The seed as a number, kept within what every platform adds exactly.
  int get _hash {
    var h = 7;
    for (final unit in seed.codeUnits) {
      h = (h * 31 + unit) & 0x7fffffff;
    }
    return h;
  }

  /// A number in [0, 1) from the seed and a [salt].
  double _unit(int salt) {
    final v = math.sin(_hash * 12.9898 + salt * 78.233) * 43758.5453;
    return v - v.floorToDouble();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final side = size.shortestSide;
    final lights = night.lights;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [night.colorScheme.background, night.colorScheme.surfaceAlt],
        ).createShader(rect),
    );
    final washes = [lights.lilac, lights.rose, lights.peach];
    for (var i = 0; i < washes.length; i++) {
      final at = Offset(
        size.width * (0.1 + 0.8 * _unit(i * 3 + 1)),
        size.height * (0.05 + 0.7 * _unit(i * 3 + 2)),
      );
      final reach = side * (0.4 + 0.5 * _unit(i * 3 + 3));
      final wash = washes[i];
      canvas.drawCircle(
        at,
        reach,
        Paint()
          ..shader = RadialGradient(
            colors: [
              wash.withValues(alpha: (0.7 * lights.strength).clamp(0.0, 1.0)),
              wash.withValues(alpha: 0),
            ],
          ).createShader(Rect.fromCircle(center: at, radius: reach)),
      );
    }
    final prism = night.hues.iris;
    final lift = size.height * (0.35 + 0.3 * _unit(11));
    final sway = size.height * (0.06 + 0.1 * _unit(12));
    final ribbon = Path()..moveTo(-side * 0.1, lift);
    for (var step = 1; step <= 8; step++) {
      final x = size.width * step / 8;
      ribbon.lineTo(
        x,
        lift + sway * math.sin(step * 0.9 + _unit(13) * math.pi * 2),
      );
    }
    canvas.drawPath(
      ribbon,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = side * 0.16
        ..strokeCap = StrokeCap.round
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, side * 0.08)
        ..shader = LinearGradient(
          colors: [
            prism.a.withValues(alpha: 0.55),
            prism.b.withValues(alpha: 0.45),
          ],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_GroundPainter old) =>
      old.seed != seed || old.night != night;
}
