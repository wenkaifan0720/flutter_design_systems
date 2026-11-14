import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import '../internal/face.dart';
import '../materials.dart';
import '../theme.dart';

/// A surface of glass, or of paint: [child] on [material], cut to [shape]
/// (or [borderRadius]). Over the page it blurs what is behind; on another
/// glass it is raised a step instead; without transparency it is opaque.
///
/// ```dart
/// FrostedSurface(material: FrostedMaterial.sheer, borderRadius: BorderRadius.circular(20), padding: const EdgeInsets.all(16), child: Text('Balance'))
/// ```
class FrostedSurface extends StatelessWidget {
  /// Creates a [FrostedSurface].
  const FrostedSurface({
    required this.material,
    this.borderRadius = BorderRadius.zero,
    this.shape,
    this.padding = EdgeInsets.zero,
    this.child,
    super.key,
  });

  /// What the surface is made of.
  final FrostedMaterial material;

  /// Its corners, unless [shape] cuts it.
  final BorderRadiusGeometry borderRadius;

  /// Its outline, in place of [borderRadius].
  final OutlinedBorder? shape;

  /// The room round [child].
  final EdgeInsetsGeometry padding;

  /// What stands on it.
  final Widget? child;

  @override
  Widget build(BuildContext context) => FrostedFace(
    material: material,
    radius: borderRadius.resolve(Directionality.maybeOf(context)),
    shape: shape,
    padding: padding.resolve(Directionality.maybeOf(context)),
    clipChild: true,
    child: child,
  );
}

/// Paints [backdrop] (the theme's when null) over the box it is given. It is
/// decoration: it takes no taps and says nothing.
///
/// ```dart
/// Positioned.fill(child: FrostedBackdropView())
/// ```
class FrostedBackdropView extends StatelessWidget {
  /// Creates a [FrostedBackdropView].
  const FrostedBackdropView({this.backdrop, super.key});

  /// What to paint; null is the theme's.
  final FrostedBackdrop? backdrop;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    final b = backdrop ?? t.backdrop;
    final Widget painted = switch (b.kind) {
      FrostedBackdropKind.dawn => CustomPaint(
        painter: _LightBackdropPainter(
          ground: t.colorScheme.background,
          lights: t.lights,
          dark: t.isDark,
        ),
      ),
      FrostedBackdropKind.night => const CustomPaint(
        painter: _NightBackdropPainter(),
      ),
      FrostedBackdropKind.image => DecoratedBox(
        decoration: BoxDecoration(
          color: t.colorScheme.background,
          image: DecorationImage(image: b.image!, fit: BoxFit.cover),
        ),
      ),
      FrostedBackdropKind.plain => ColoredBox(
        color: b.color ?? t.colorScheme.background,
      ),
    };
    return IgnorePointer(
      child: ExcludeSemantics(
        child: RepaintBoundary(child: SizedBox.expand(child: painted)),
      ),
    );
  }
}

/// The preset's dawn, the whole screen through: its ground, then three
/// broad glows of its lilac, rose and peach (top start, middle end, low
/// start), each a radial gradient to nothing.
class _LightBackdropPainter extends CustomPainter {
  const _LightBackdropPainter({
    required this.ground,
    required this.lights,
    required this.dark,
  });

  final Color ground;
  final FrostedLights lights;
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..color = ground);
    final span = math.max(size.width, math.min(size.height, 900.0));
    // The shares and the boost are the ones the theme holds its inks to
    // (FrostedLights.peaksOver), so no word stands on a deeper wash than it
    // was made to read on.
    const shares = FrostedLights.backdropShares;
    final glows = <(Offset, double, Color, double)>[
      (
        Offset(size.width * .08, size.height * .06),
        .62,
        lights.lilac,
        shares[0],
      ),
      (
        Offset(size.width * .92, size.height * .34),
        .56,
        lights.rose,
        shares[1],
      ),
      (
        Offset(size.width * .22, size.height * .78),
        .60,
        lights.peach,
        shares[2],
      ),
      (Offset(size.width * .86, size.height * .96), .42, lights.lilac, .6),
    ];
    final strength = lights.strength * FrostedLights.backdropBoost(night: dark);
    for (final (centre, reach, colour, share) in glows) {
      final r = span * reach;
      final alpha = math.min(1.0, colour.a * share * strength);
      canvas.drawRect(
        rect,
        Paint()
          ..shader = ui.Gradient.radial(
            centre,
            r,
            [
              colour.withValues(alpha: alpha),
              colour.withValues(alpha: alpha * .45),
              colour.withValues(alpha: 0),
            ],
            const [0, .45, 1],
          ),
      );
    }
  }

  @override
  bool shouldRepaint(_LightBackdropPainter old) =>
      old.ground != ground || old.lights != lights || old.dark != dark;
}

/// The night sky: deep blue into violet down the screen, a band of green
/// light and a violet glow low over it, and stars, fewer toward the glow.
class _NightBackdropPainter extends CustomPainter {
  const _NightBackdropPainter();

  /// The band at the top a page's title and its bar stand in.
  static const double _titleBand = 132;

  /// How far under the band the stars come in.
  static const double _titleFade = 48;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = ui.Gradient.linear(
          rect.topCenter,
          rect.bottomCenter,
          const [Color(0xFF070A1C), Color(0xFF111338), Color(0xFF24154A)],
          const [0, .55, 1],
        ),
    );
    final span = math.max(size.width, math.min(size.height, 900.0));
    final glows = <(Offset, double, Color)>[
      (
        Offset(size.width * .18, size.height * .30),
        .70,
        const Color(0x8C1FC7A6),
      ),
      (
        Offset(size.width * .78, size.height * .18),
        .55,
        const Color(0x7A3B82F6),
      ),
      (
        Offset(size.width * .70, size.height * .82),
        .75,
        const Color(0x99A855F7),
      ),
      (
        Offset(size.width * .12, size.height * .92),
        .45,
        const Color(0x66EC4899),
      ),
    ];
    for (final (centre, reach, colour) in glows) {
      canvas.drawRect(
        rect,
        Paint()
          ..shader = ui.Gradient.radial(
            centre,
            span * reach,
            [
              colour,
              colour.withValues(alpha: colour.a * .35),
              colour.withValues(alpha: 0),
            ],
            const [0, .5, 1],
          ),
      );
    }
    // Stars: the same scatter at every size, one per 6,000 square points,
    // none in the band a page's title stands in (a star by a word reads as
    // a stray mark), coming in under it.
    final random = math.Random(7);
    final count = (size.width * size.height / 6000).clamp(24, 260).round();
    final star = Paint();
    for (var i = 0; i < count; i++) {
      final p = Offset(
        random.nextDouble() * size.width,
        random.nextDouble() * size.height,
      );
      final bright = random.nextDouble();
      final clear = ((p.dy - _titleBand) / _titleFade).clamp(0.0, 1.0);
      if (clear == 0) continue;
      star.color = const Color(0xFFFFFFFF)
          .withValues(alpha: (.25 + .55 * bright * bright) * clear);
      canvas.drawCircle(p, .6 + bright * .9, star);
    }
  }

  @override
  bool shouldRepaint(_NightBackdropPainter old) => false;
}

/// Marks a subtree that stands on glass: a glass face inside it is raised a
/// step rather than blurring a second time.
class FrostedOnGlass extends InheritedWidget {
  /// Creates a [FrostedOnGlass].
  const FrostedOnGlass({required super.child, super.key});

  /// Whether [context] stands on glass.
  static bool of(BuildContext context) =>
      context.getInheritedWidgetOfExactType<FrostedOnGlass>() != null;

  @override
  bool updateShouldNotify(FrostedOnGlass oldWidget) => false;
}

/// Whether [context]'s glass draws its opaque form: the theme asks for it
/// ([FrostedThemeData.opaqueMaterials]) or the platform reports high
/// contrast.
bool frostedOpaqueAt(BuildContext context) =>
    context.frostedTheme.opaqueMaterials ||
    (MediaQuery.maybeHighContrastOf(context) ?? false);
