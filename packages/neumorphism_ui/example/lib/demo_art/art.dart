/// Catalog illustration for the relief demo; excluded from the UI package.
library;

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import 'package:neumorphism_ui/neumorphism_parts.dart';

/// A plaster pediment beneath a moon and stars. Use as demo art in a relief's
/// headerArt slot, or supply an app's own picture instead.
///
/// ```dart
/// const NeumorphicGableArt()
/// ```
class NeumorphicGableArt extends StatelessWidget {
  /// Creates the catalog-only gable illustration.
  const NeumorphicGableArt({super.key});

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: NeumorphicFill(
      maxWidth: 1200,
      aspect: 620 / 176,
      child: CustomPaint(
        painter: _GablePainter(
          NeumorphicTheme.of(context).colors,
          NeumorphicFlatScope.of(context),
        ),
      ),
    ),
  );
}

class _GablePainter extends CustomPainter {
  _GablePainter(this.c, this.flat);
  final NeumorphicColors c;
  final bool flat;
  static const _w = 620.0, _h = 176.0, _apex = 8.0;
  static const _moonOuter = 23.0, _moonInner = 18.0;

  Paint _soft(Color color, double sigma) => Paint()
    ..color = color
    ..isAntiAlias = true
    ..maskFilter = MaskFilter.blur(BlurStyle.normal, sigma);

  @override
  void paint(Canvas canvas, Size s) {
    canvas.save();
    // Relief shadows may overhang; the flat face stays inside its art slot.
    if (flat) canvas.clipRect(Offset.zero & s);
    // The gable's moulded eaves reach past its points by the round join's radius (the least corner): drawn to the
    // slot's edges, its feet stood about 10 px past the column's keylines. The whole mark is set in by that reach.
    const reach = NeumorphicRadii.least;
    final sx = s.width / (_w + 2 * reach), sy = s.height / (_h + reach);
    canvas.translate(reach * sx, 0);
    canvas.scale(sx, sy);
    final th = math.atan((_h - _apex) / (_w / 2));
    final gs = math.sin(th), gc = math.cos(th);

    // Stars.
    for (final (x, y, r) in const [
      (62.0, 30.0, 2.6),
      (176.0, 34.0, 2.0),
      (540.0, 44.0, 2.4),
      (586.0, 92.0, 1.8),
      (36.0, 82.0, 2.0),
    ]) {
      if (!flat) {
        canvas.drawCircle(
          Offset(x + .9, y + .9),
          r,
          neumorphicFillPaint(c.highlight),
        );
      }
      canvas.drawCircle(
        Offset(x, y),
        r,
        neumorphicFillPaint(flat ? c.quiet : c.art.star),
      );
    }

    // The moon, raised from the wall.
    final moon = Path()
      ..moveTo(118, 20)
      ..arcToPoint(
        const Offset(146, 50),
        radius: const Radius.circular(_moonOuter),
        largeArc: true,
        clockwise: false,
      )
      ..arcToPoint(
        const Offset(118, 20),
        radius: const Radius.circular(_moonInner),
      )
      ..close();
    if (!flat) {
      canvas.drawPath(moon.shift(const Offset(3, 3)), _soft(c.shadow, 5));
      canvas.drawPath(
        moon.shift(const Offset(-2, -2)),
        _soft(c.highlightSoft, 3),
      );
    }
    canvas.drawPath(
      moon,
      Paint()
        ..isAntiAlias = true
        ..shader = cssRadial(moon.getBounds(), .38, .3, [
          c.art.moon,
          c.art.moonShade,
        ]),
    );
    if (flat) canvas.drawPath(moon, neumorphicStrokePaint(c.quiet, 1));

    // The chimney behind the right rake.
    final stack = RRect.fromRectAndRadius(
      const Rect.fromLTWH(454, 34, 40, 96),
      const Radius.circular(NeumorphicRadii.least),
    );
    final capRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(446, 22, 56, 14),
      const Radius.circular(7),
    );
    if (!flat) {
      canvas.drawRRect(stack.shift(const Offset(7, 6)), _soft(c.shadow, 7));
    }
    canvas.drawRRect(
      stack,
      Paint()
        ..shader = cssLinear(stack.outerRect, 90, [c.faceStart, c.faceEnd]),
    );
    if (!flat) {
      canvas.drawRRect(capRect.shift(const Offset(3, 4)), _soft(c.shadow, 4));
    }
    canvas.drawRRect(
      capRect,
      Paint()
        ..shader = cssLinear(capRect.outerRect, 90, [c.faceStart, c.faceEnd]),
    );
    if (!flat) {
      // The cap's catch-light along its flat top only, a hair: at 2 px it read as a stripe painted on.
      canvas.drawLine(
        const Offset(453, 22.5),
        const Offset(495, 22.5),
        neumorphicStrokePaint(c.rim, 1),
      );
    }

    // The raised gable.
    final sil = neumorphicPolyPath(const [
      Offset(0, _h),
      Offset(_w / 2, _apex),
      Offset(_w, _h),
    ]);
    // Moulded, not cut: the eaves and the apex round by the look's least corner (the round join's radius is half the
    // stroke). At 7 the points were knife-sharp (law 8).
    final round = Paint()
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 2 * NeumorphicRadii.least;
    if (!flat) {
      canvas.drawPath(sil.shift(const Offset(12, 8)), _soft(c.shadowDeep, 14));
      canvas.drawPath(sil.shift(const Offset(-9, -9)), _soft(c.highlight, 9));
    }
    final faceShader = ui.Gradient.linear(
      const Offset(140, 0),
      const Offset(520, 176),
      [c.faceStart, c.faceEnd],
    );
    canvas.drawPath(
      sil,
      Paint()
        ..isAntiAlias = true
        ..shader = faceShader,
    );
    canvas.drawPath(
      sil,
      round
        ..isAntiAlias = true
        ..shader = faceShader,
    );
    if (flat) {
      canvas.drawPath(
        neumorphicRoundedPath(const [
          Offset(-3, _h),
          Offset(_w / 2, _apex - 4),
          Offset(_w + 3, _h),
        ], close: false),
        neumorphicStrokePaint(c.quiet, 1),
      );
    } else {
      // The catch-light runs over the apex round, as the face does: lines meeting in a point drew a knife edge on the
      // moulded roof. Lit on the light's side, half as bright past the top.
      final top = neumorphicCorner(
        const Offset(1, _h - 3),
        const Offset(_w / 2, _apex - 3),
        const Offset(_w - 1, _h - 3),
      );
      // Each runs on into its eave's round, which reaches past the point: ending on the point, the light stopped
      // short of the left eave's tip.
      const foot = Offset(1, _h - 3), far = Offset(_w - 1, _h - 3);
      Offset unit(Offset o) => o / o.distance;
      final from = foot - unit(top.start - foot) * 5;
      final to = far + unit(far - top.end) * 5;
      canvas.drawPath(
        Path()
          ..moveTo(from.dx, from.dy)
          ..lineTo(top.start.dx, top.start.dy)
          ..arcToPoint(top.mid, radius: Radius.circular(top.radius)),
        neumorphicStrokePaint(c.rim, 2),
      );
      canvas.drawPath(
        Path()
          ..moveTo(top.mid.dx, top.mid.dy)
          ..arcToPoint(top.end, radius: Radius.circular(top.radius))
          ..lineTo(to.dx, to.dy),
        neumorphicStrokePaint(c.rim.withValues(alpha: c.rim.a * .55), 1.2),
      );
    }

    // The engraved moulding halfway up the rake.
    const m = 13.0;
    final mlx = m / gs, mrx = _w - m / gs, may = _apex + m / gc;
    if (!flat) {
      canvas.drawPath(
        neumorphicRoundedPath([
          Offset(mlx, _h),
          Offset(_w / 2, may),
          Offset(mrx, _h),
        ], close: false),
        neumorphicStrokePaint(c.crease, 1.4, round: false),
      );
      canvas.drawPath(
        neumorphicRoundedPath([
          Offset(mlx, _h + 1.5),
          Offset(_w / 2, may + 1.5),
          Offset(mrx, _h + 1.5),
        ], close: false),
        neumorphicStrokePaint(c.rim, 1.4, round: false),
      );
    }

    // The pressed tympanum.
    const inset = 26.0;
    final ax = _w / 2, ay = _apex + inset / gc;
    final lx = inset / gs, rx = _w - inset / gs;
    final tym = neumorphicRoundedPath([
      Offset(lx, _h),
      Offset(ax, ay),
      Offset(rx, _h),
    ]);
    canvas.drawPath(
      tym,
      Paint()
        ..isAntiAlias = true
        ..shader = ui.Gradient.linear(
          const Offset(180, 40),
          const Offset(460, 176),
          [c.wellStart, c.wellEnd],
        ),
    );
    if (!flat) {
      final ml = Offset((lx + ax) / 2, (_h + ay) / 2);
      final mr = Offset((rx + ax) / 2, (_h + ay) / 2);
      final shade = c.shadowInset;
      canvas.drawPath(
        tym,
        Paint()
          ..isAntiAlias = true
          ..shader = ui.Gradient.linear(ml, ml + Offset(gs * 40, gc * 40), [
            shade,
            shade.withValues(alpha: 0),
          ]),
      );
      canvas.drawPath(
        tym,
        Paint()
          ..isAntiAlias = true
          ..shader = ui.Gradient.linear(mr, mr + Offset(-gs * 26, gc * 26), [
            shade.withValues(alpha: shade.a * .45),
            shade.withValues(alpha: 0),
          ]),
      );
    } else {
      canvas.drawPath(tym, neumorphicStrokePaint(c.quiet, 1));
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_GablePainter o) => o.c != c || o.flat != flat;
}
