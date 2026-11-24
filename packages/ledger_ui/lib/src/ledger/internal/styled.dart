import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import 'face.dart';

/// A part's style layers over the face Ledger would draw: what each part
/// reads of a `LedgerStyle`. Plumbing of the controls; pages never use it.
extension LedgerStyled on RawStyleOf {
  /// Whether no layer is set: the face stays the book's.
  bool get isBare => layers.every((l) => l == null);

  /// [face] with this style's paper, ink, rule, corners and wash over it.
  LedgerFaceStyle dress(LedgerFaceStyle face) {
    if (isBare) return face;
    final g = face.ground;
    final corners = shape;
    final shapeSide = corners == null || corners.side == BorderSide.none
        ? null
        : corners.side;
    final rule = side ?? shapeSide;
    final ink = edge;
    final width = g.border is Border ? (g.border! as Border).top.width : 1.0;
    final BoxBorder? border = rule != null
        ? Border.fromBorderSide(rule)
        : ink != null
        ? Border.all(color: ink, width: width)
        : g.border;
    final paper = fill ?? g.color;
    final wash = overlay?.resolve(states);
    final circle = corners is CircleBorder;
    final radius = corners == null ? null : ledgerCorners(corners);
    return LedgerFaceStyle(
      ink: foreground ?? face.ink,
      quiet: face.quiet,
      rule: face.rule == null ? null : (foreground ?? face.rule),
      ground: BoxDecoration(
        color: wash == null
            ? paper
            : Color.alphaBlend(wash, paper ?? const Color(0x00000000)),
        image: g.image,
        border: border,
        borderRadius: circle
            ? null
            : radius ?? (corners == null ? g.borderRadius : null),
        boxShadow: g.boxShadow,
        gradient: g.gradient,
        backgroundBlendMode: g.backgroundBlendMode,
        shape: circle
            ? BoxShape.circle
            : radius != null
            ? BoxShape.rectangle
            : g.shape,
      ),
    );
  }

  /// [paper] with this style's fill, rule, corners and wash over it: a
  /// surface's ground, with no ink of its own.
  BoxDecoration paper(BoxDecoration paper) => isBare
      ? paper
      : dress(LedgerFaceStyle(ink: const Color(0x00000000), ground: paper))
            .ground;

  /// [base] with this style's words merged over it, in [ink].
  TextStyle words(TextStyle base, Color ink) {
    final over = textStyle;
    return (over == null ? base : base.merge(over)).copyWith(color: ink);
  }
}

/// The corners of [shape] as a box's radius: a rounded rectangle's own, a
/// stadium's (every corner round), none for another outline.
BorderRadiusGeometry? ledgerCorners(OutlinedBorder shape) => switch (shape) {
  RoundedRectangleBorder(:final borderRadius) => borderRadius,
  ContinuousRectangleBorder(:final borderRadius) => borderRadius,
  StadiumBorder() => const BorderRadius.all(Radius.circular(_round)),
  _ => null,
};

// Larger than any face's half height: a stadium's corners.
const double _round = 999;
