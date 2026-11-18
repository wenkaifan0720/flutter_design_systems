/// Simmer's pictures: each recipe's dish drawn as a glazed bowl seen from
/// above, under the same light as the parts. Drawn, not photographed.
library;

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:gloss_ui/gloss_ui.dart';

import 'data.dart';

/// [recipe]'s dish on a soft tile, rounded [radius].
class SimmerDish extends StatelessWidget {
  /// The picture of [recipe].
  const SimmerDish({
    super.key,
    required this.recipe,
    this.radius = GlossMetrics.cardRadius,
    this.semanticLabel,
  });

  /// The recipe.
  final SimmerRecipe recipe;

  /// The tile's corner.
  final double radius;

  /// What a screen reader says; the picture is decoration when null.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final c = GlossTheme.of(context).colors;
    final picture = RepaintBoundary(
      child: CustomPaint(
        painter: _DishPainter(recipe, c.brightness),
        child: const SizedBox.expand(),
      ),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: semanticLabel == null
          ? ExcludeSemantics(child: picture)
          : Semantics(image: true, label: semanticLabel, child: picture),
    );
  }
}

class _DishPainter extends CustomPainter {
  _DishPainter(this.recipe, this.brightness);

  final SimmerRecipe recipe;
  final Brightness brightness;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final light = brightness == Brightness.light;
    final dish = HSLColor.fromColor(recipe.dish);
    // The table: a soft tile tinted from the dish's glaze.
    final table = dish
        .withSaturation(math.min(0.28, dish.saturation))
        .withLightness(light ? 0.86 : 0.24)
        .toColor();
    canvas.drawRect(
      rect,
      Paint()
        ..shader = ui.Gradient.linear(rect.topCenter, rect.bottomCenter, [
          Color.lerp(table, const Color(0xFFFFFFFF), light ? 0.35 : 0.06)!,
          table,
        ]),
    );
    final d = math.min(size.width, size.height) * 0.78;
    final centre = rect.center + Offset(0, size.height * 0.02);
    // The bowl's shadow, cast down from the light above.
    canvas.drawOval(
      Rect.fromCenter(
        center: centre + Offset(0, d * 0.07),
        width: d * 1.02,
        height: d * 0.98,
      ),
      Paint()
        ..color = const Color(0x40000000)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, d * 0.05),
    );
    final bowl = Rect.fromCircle(center: centre, radius: d / 2);
    // The glazed rim.
    canvas.drawOval(
      bowl,
      Paint()
        ..shader = ui.Gradient.linear(
          bowl.topCenter,
          bowl.bottomCenter,
          [
            dish.withLightness(math.min(0.95, dish.lightness + 0.16)).toColor(),
            recipe.dish,
            dish.withLightness(math.max(0.05, dish.lightness - 0.14)).toColor(),
          ],
          const [0, 0.5, 1],
        ),
    );
    // The well of the bowl, a step down, its far wall lit.
    final well = bowl.deflate(d * 0.11);
    canvas.drawOval(
      well,
      Paint()
        ..shader = ui.Gradient.linear(well.topCenter, well.bottomCenter, [
          dish.withLightness(math.max(0.05, dish.lightness - 0.12)).toColor(),
          dish.withLightness(math.min(0.92, dish.lightness + 0.1)).toColor(),
        ]),
    );
    // The food: soft pieces, the same on every draw.
    canvas
      ..save()
      ..clipPath(Path()..addOval(well.deflate(d * 0.03)));
    final random = math.Random(
      recipe.id.codeUnits.fold<int>(7, (h, c) => (h * 31 + c) & 0x7fffffff),
    );
    final bed = well.deflate(d * 0.03);
    canvas.drawOval(bed, Paint()..color = recipe.food.last);
    for (var i = 0; i < 26; i++) {
      final colour = recipe.food[i % (recipe.food.length - 1)];
      final angle = random.nextDouble() * math.pi * 2;
      final reach = math.sqrt(random.nextDouble()) * bed.width * 0.36;
      final at = bed.center + Offset(math.cos(angle), math.sin(angle)) * reach;
      final r = d * (0.05 + random.nextDouble() * 0.07);
      final piece = Rect.fromCenter(
        center: at,
        width: r * 2,
        height: r * (1.4 + random.nextDouble() * 0.5),
      );
      canvas
        ..save()
        ..translate(at.dx, at.dy)
        ..rotate(random.nextDouble() * math.pi)
        ..translate(-at.dx, -at.dy)
        ..drawOval(
          piece,
          Paint()
            ..shader = ui.Gradient.radial(
              piece.center - Offset(r * 0.3, r * 0.4),
              r * 1.3,
              [Color.lerp(colour, const Color(0xFFFFFFFF), 0.25)!, colour],
            ),
        )
        ..restore();
    }
    canvas.restore();
    // The glaze's shine along the rim's upper edge.
    canvas.drawArc(
      bowl.deflate(d * 0.03),
      math.pi * 1.12,
      math.pi * 0.5,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = d * 0.035
        ..strokeCap = StrokeCap.round
        ..color = Color.fromRGBO(255, 255, 255, light ? 0.75 : 0.45),
    );
  }

  @override
  bool shouldRepaint(_DishPainter old) =>
      old.recipe.id != recipe.id || old.brightness != brightness;
}
