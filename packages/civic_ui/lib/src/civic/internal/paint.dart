import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

/// Civic's fixed measures: the edges, the focus bar and the boxes every part
/// is drawn with.
abstract final class CivicMetrics {
  /// A field's and a box's edge.
  static const double edge = 2;

  /// What a well's edge grows by when it holds the focus: the edge doubles.
  static const double focusEdgeGrowth = 2;

  /// The yellow ring a focused well wears outside its edge.
  static const double focusRing = 4;

  /// The ink bar under a focused face, and the solid edge under a button.
  static const double bar = 4;

  /// A control's height: a field's, a button's (its edge included), a
  /// select's.
  static const double controlHeight = 48;

  /// A checkbox's and a radio's box.
  static const double box = 40;

  /// The inset rule a hint, a warning or an error group stands on.
  static const double insetRule = 4;

  /// A button's and a tag's corners: a little rounded, so a face reads as
  /// something to press and never as a box drawn round words. A field's
  /// well keeps square corners: its strong edge is for reading, not for show.
  static const double corner = 4;

  /// A card's corners: a group of rows, white on the page's ground.
  static const double cardCorner = 8;
}

/// Tints a control with its own ink on hover and while the pointer is held.
Color civicPointerFill(Color fill, Color ink, Set<WidgetState> states) {
  if (states.contains(WidgetState.disabled)) return fill;
  final double opacity;
  if (states.contains(WidgetState.pressed)) {
    opacity = 0.12;
  } else if (states.contains(WidgetState.hovered)) {
    opacity = 0.08;
  } else {
    return fill;
  }
  return Color.alphaBlend(ink.withValues(alpha: ink.a * opacity), fill);
}

/// A surface that floats over the page (an open list, a menu, a popover, a
/// dialog): the card's [face], its corners rounded ([radius]), a [hairline]
/// round it and a soft shadow under it; never an ink edge, which Civic keeps
/// for a field's well. By night the shadow is lost on the dark ground, so
/// the edge carries the surface: a [hairline] that reads at less than 3:1
/// against the [face] is lifted toward white until it does.
BoxDecoration civicFloating({
  required Color face,
  required Color hairline,
  required bool dark,
  double radius = CivicMetrics.corner,
}) => BoxDecoration(
  color: face,
  borderRadius: BorderRadius.circular(radius),
  border: Border.all(color: dark ? _readable(hairline, face) : hairline),
  boxShadow: [
    BoxShadow(
      color: Color(dark ? 0x99000000 : 0x2E0C1116),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ],
);

/// [edge], or the nearest tone of its hue that reads at 3:1 against [face]
/// (ui_core's RawPalette).
Color _readable(Color edge, Color face) =>
    RawPalette.readableTone(edge, on: [face], ratio: 3);

/// Paints a face: its fill and, under it, a solid edge [edgeHeight] tall
/// that a press sinks onto ([press] 0 to 1); with [focus] (0 to 1) the fill
/// floods to [focusColor] and the edge turns to the focus bar in [barColor],
/// at least [CivicMetrics.bar] tall.
class CivicFacePainter extends CustomPainter {
  /// A face.
  CivicFacePainter({
    required this.fill,
    required this.edgeColor,
    required this.edgeHeight,
    required this.press,
    required this.focus,
    required this.focusColor,
    required this.barColor,
    this.side,
    this.outset = 0,
    this.radius = 0,
  });

  /// The face's fill at rest.
  final Color fill;

  /// The solid edge's colour at rest.
  final Color edgeColor;

  /// The solid edge's height at rest; 0 for a face with none.
  final double edgeHeight;

  /// How far a press has sunk, 0 to 1.
  final double press;

  /// How far the focus has arrived, 0 to 1.
  final double focus;

  /// The focus plate.
  final Color focusColor;

  /// The focus bar.
  final Color barColor;

  /// An edge drawn round the face, inside its box.
  final BorderSide? side;

  /// How far the face and its bar reach past the box at each side: room
  /// round words that stand flush with the text beside them (a link).
  final double outset;

  /// The corners' radius ([CivicMetrics.corner] for a button): the face
  /// and the edge under it round together, as one piece.
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final sink = edgeHeight * press;
    final faceHeight = size.height - edgeHeight;
    final face = Rect.fromLTWH(
      -outset,
      sink,
      size.width + 2 * outset,
      faceHeight,
    );
    if (radius > 0) {
      canvas
        ..save()
        ..clipRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTRB(face.left, sink, face.right, size.height),
            Radius.circular(radius),
          ),
        );
    }
    _paint(canvas, size, face);
    if (radius > 0) canvas.restore();
  }

  void _paint(Canvas canvas, Size size, Rect face) {
    final sink = edgeHeight * press;
    final f = focus.clamp(0.0, 1.0);
    final fillColor = Color.lerp(fill, focusColor, f)!;
    if (fillColor.a > 0) canvas.drawRect(face, Paint()..color = fillColor);
    final s = side;
    if (s != null && s.width > 0 && f < 1) {
      canvas.drawRect(
        face.deflate(s.width / 2),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = s.width
          ..color = s.color.withValues(alpha: s.color.a * (1 - f)),
      );
    }
    // The solid edge, what is left of it under a press.
    final edgeLeft = edgeHeight - sink;
    if (edgeLeft > 0) {
      canvas.drawRect(
        Rect.fromLTWH(face.left, face.bottom, face.width, edgeLeft),
        Paint()..color = Color.lerp(edgeColor, barColor, f)!,
      );
    }
    // A face with no edge of its own takes the bar on focus, inside its box.
    if (f > 0 && edgeHeight == 0) {
      canvas.drawRect(
        Rect.fromLTWH(
          face.left,
          size.height - CivicMetrics.bar,
          face.width,
          CivicMetrics.bar,
        ),
        Paint()..color = barColor.withValues(alpha: barColor.a * f),
      );
    }
  }

  @override
  bool shouldRepaint(CivicFacePainter old) =>
      old.fill != fill ||
      old.edgeColor != edgeColor ||
      old.edgeHeight != edgeHeight ||
      old.press != press ||
      old.focus != focus ||
      old.focusColor != focusColor ||
      old.barColor != barColor ||
      old.outset != outset ||
      old.radius != radius ||
      old.side != side;
}

/// Paints a well (a field, a box, a radio): its fill and its edge, and, with
/// [focus] (0 to 1), the edge doubled and a yellow ring outside it, around
/// the same square corners (or the same centre, for a [circle]).
class CivicWellPainter extends CustomPainter {
  /// A well.
  CivicWellPainter({
    required this.fill,
    required this.edgeColor,
    required this.focus,
    required this.focusColor,
    required this.focusEdgeColor,
    this.edge = CivicMetrics.edge,
    this.circle = false,
  });

  /// The well's fill.
  final Color fill;

  /// Its edge at rest.
  final Color edgeColor;

  /// Its edge's width at rest.
  final double edge;

  /// How far the focus has arrived, 0 to 1.
  final double focus;

  /// The ring.
  final Color focusColor;

  /// The doubled edge's colour.
  final Color focusEdgeColor;

  /// Whether the well is round.
  final bool circle;

  @override
  void paint(Canvas canvas, Size size) {
    final outer = Offset.zero & size;
    final f = focus.clamp(0.0, 1.0);
    final fillPaint = Paint()..color = fill;
    final grow = CivicMetrics.focusEdgeGrowth * f;
    final width = edge + grow;
    final edgePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..color = Color.lerp(edgeColor, focusEdgeColor, f)!;
    final ringWidth = CivicMetrics.focusRing * f;
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = ringWidth
      ..color = focusColor.withValues(alpha: focusColor.a * math.min(1, f * 2));
    if (circle) {
      final c = outer.center;
      final r = outer.shortestSide / 2;
      canvas.drawCircle(c, r, fillPaint);
      canvas.drawCircle(c, r - width / 2, edgePaint);
      if (ringWidth > 0) canvas.drawCircle(c, r + ringWidth / 2, ringPaint);
    } else {
      canvas.drawRect(outer, fillPaint);
      canvas.drawRect(outer.deflate(width / 2), edgePaint);
      if (ringWidth > 0) {
        canvas.drawRect(outer.inflate(ringWidth / 2), ringPaint);
      }
    }
  }

  @override
  bool shouldRepaint(CivicWellPainter old) =>
      old.fill != fill ||
      old.edgeColor != edgeColor ||
      old.edge != edge ||
      old.focus != focus ||
      old.focusColor != focusColor ||
      old.focusEdgeColor != focusEdgeColor ||
      old.circle != circle;
}
