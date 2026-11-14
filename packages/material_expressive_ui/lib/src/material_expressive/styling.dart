/// Outlines an app can give a part's style: one that reserves a content
/// inset, and one nested inside another.
library;

import 'dart:ui' show lerpDouble;

import 'package:flutter/widgets.dart';

/// An outline with an explicit content inset, in addition to its stroke.
///
/// ```dart
/// const border = ExpressiveContentBorder(
///   ExpressiveMaterialShapeBorder(ExpressiveMaterialShape.cookie6Sided),
///   inset: 12,
/// );
/// ```
@immutable
class ExpressiveContentBorder extends OutlinedBorder {
  /// Wraps [outline] with its reserved safe area.
  const ExpressiveContentBorder(
    this.outline, {
    required this.inset,
    super.side,
  });

  /// The visible outline.
  final OutlinedBorder outline;

  /// The safe inset the role's contents add to their own padding.
  final double inset;

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(inset + side.strokeInset);

  @override
  ExpressiveContentBorder copyWith({BorderSide? side}) =>
      ExpressiveContentBorder(outline, inset: inset, side: side ?? this.side);

  @override
  ExpressiveContentBorder scale(double t) => ExpressiveContentBorder(
    outline.scale(t) as OutlinedBorder,
    inset: inset * t,
    side: side.scale(t),
  );

  @override
  ShapeBorder? lerpFrom(ShapeBorder? a, double t) =>
      a is ExpressiveContentBorder
      ? ExpressiveContentBorder(
          ShapeBorder.lerp(a.outline, outline, t) as OutlinedBorder,
          inset: lerpDouble(a.inset, inset, t)!,
          side: BorderSide.lerp(a.side, side, t),
        )
      : super.lerpFrom(a, t);

  @override
  ShapeBorder? lerpTo(ShapeBorder? b, double t) =>
      b is ExpressiveContentBorder ? b.lerpFrom(this, t) : super.lerpTo(b, t);

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) =>
      outline.getOuterPath(rect, textDirection: textDirection);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) => outline
      .copyWith(side: side)
      .getInnerPath(rect, textDirection: textDirection);

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) =>
      outline
          .copyWith(side: side)
          .paint(canvas, rect, textDirection: textDirection);

  @override
  bool operator ==(Object other) =>
      other is ExpressiveContentBorder &&
      other.outline == outline &&
      other.inset == inset &&
      other.side == side;

  @override
  int get hashCode => Object.hash(outline, inset, side);
}

/// A nested outline concentric with [outer], [inset] pixels inside it.
///
/// The inner radius is the outer radius minus the inset. Capsule ends stay
/// capsules; square corners stay square. Safe content wrappers do not add a
/// second inset to the nested surface.
@immutable
class ExpressiveInsetBorder extends OutlinedBorder {
  /// Follows [outer]'s inner parallel outline.
  const ExpressiveInsetBorder(this.outer, {required this.inset, super.side})
    : assert(inset >= 0);

  /// The surrounding surface's outline.
  final OutlinedBorder outer;

  /// The distance between the surrounding and nested outlines.
  final double inset;

  OutlinedBorder get _outline => outer is ExpressiveContentBorder
      ? (outer as ExpressiveContentBorder).outline
      : outer;

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(side.strokeInset);

  @override
  ExpressiveInsetBorder copyWith({BorderSide? side}) =>
      ExpressiveInsetBorder(outer, inset: inset, side: side ?? this.side);

  @override
  ExpressiveInsetBorder scale(double t) => ExpressiveInsetBorder(
    outer.scale(t) as OutlinedBorder,
    inset: inset * t,
    side: side.scale(t),
  );

  Path _path(Rect rect, double distance, TextDirection? direction) => _outline
      .copyWith(side: BorderSide(width: distance))
      .getInnerPath(rect.inflate(inset), textDirection: direction);

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) =>
      _path(rect, inset, textDirection);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      _path(rect, inset + side.strokeInset, textDirection);

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (side.style == BorderStyle.none || side.width == 0) return;
    canvas.drawPath(
      _path(rect, inset - side.strokeOffset / 2, textDirection),
      side.toPaint(),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ExpressiveInsetBorder &&
      other.outer == outer &&
      other.inset == inset &&
      other.side == side;

  @override
  int get hashCode => Object.hash(outer, inset, side);
}
