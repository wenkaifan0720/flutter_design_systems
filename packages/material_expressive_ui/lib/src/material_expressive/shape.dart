/// Expressive's shape (CONTRACT §2 "Shape"): [ExpressiveShapes], the corner
/// scale (0 · 4 · 8 · 12 · 16 · 20 · 28 · 32 · 48 · full, with top, bottom,
/// start and end variants for inner corners), which
/// `context.expressiveTheme.shapes` carries; and the 35 library shapes of
/// Compose's `MaterialShapes` ([ExpressiveMaterialShape]) with their border
/// ([ExpressiveMaterialShapeBorder]) and morph ([ExpressiveMorph]).
///
/// The scale is Compose's `Shapes`: every step an [ExpressiveCornerBorder]
/// whose corners are the theme's baked `ShapeTokens` (`internal/shape/`,
/// written by `tools/expressive_tokens`' `emit/shape.ts`), resolved at
/// paint time exactly as Compose's `CornerBasedShape` does — a percent
/// corner against the shorter side, every corner clamped to half of it.
/// Components name a step or an [ExpressiveShapeKey] token, never a length.
///
/// The library shapes are generated from `MaterialShapes.kt` and built on
/// a vendored port of androidx graphics-shapes (`internal/shape/graphics/`,
/// MIT via `material_new_shapes`), held to Compose's own cubics by
/// `test/shape_test.dart`. They mask imagery — media, avatars, metrics —
/// never text containers (CONTRACT §3).
///
/// Owner: w1-shape.
library;

import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'internal/shape/graphics/graphics.dart';
import 'internal/shape/library.dart';
import 'internal/shape/library_shapes.g.dart';
import 'internal/tokens/keys.g.dart';

export 'internal/shape/library_shapes.g.dart' show ExpressiveMaterialShape;

/// The steps of the corner scale, smallest first.
enum ExpressiveCorner {
  /// 0dp (`md.sys.shape.corner.none`).
  none,

  /// 4dp (`md.sys.shape.corner.extra-small`).
  extraSmall,

  /// 8dp (`md.sys.shape.corner.small`).
  small,

  /// 12dp (`md.sys.shape.corner.medium`).
  medium,

  /// 16dp (`md.sys.shape.corner.large`).
  large,

  /// 20dp (`md.sys.shape.corner.large-increased`).
  largeIncreased,

  /// 28dp (`md.sys.shape.corner.extra-large`).
  extraLarge,

  /// 32dp (`md.sys.shape.corner.extra-large-increased`).
  extraLargeIncreased,

  /// 48dp (`md.sys.shape.corner.extra-extra-large`).
  extraExtraLarge,

  /// Fully round: half the shorter side (`md.sys.shape.corner.full`).
  full,
}

/// One corner's size: [dp] plus [fraction] of the shape's shorter side
/// (Compose's `CornerSize`; one of the two is zero unless interpolated).
@immutable
class ExpressiveCornerSize {
  /// A corner [dp] long.
  const ExpressiveCornerSize.dp(this.dp) : fraction = 0;

  /// A corner [fraction] of the shorter side long (0.5: fully round).
  const ExpressiveCornerSize.fraction(this.fraction) : dp = 0;

  const ExpressiveCornerSize._(this.dp, this.fraction);

  /// A square corner.
  static const ExpressiveCornerSize zero = ExpressiveCornerSize.dp(0);

  /// The length part, in logical pixels.
  final double dp;

  /// The share of the shorter side.
  final double fraction;

  /// The corner's radius on a shape of [size], before clamping.
  double resolve(Size size) => dp + fraction * size.shortestSide;

  /// Scaled by [t] (only the length: a share of the side scales with it).
  ExpressiveCornerSize scale(double t) =>
      ExpressiveCornerSize._(dp * t, fraction);

  /// Between [a] and [b]: linear in both parts, so linear in pixels on any
  /// one size — how Compose animates a shape between corner sizes.
  static ExpressiveCornerSize lerp(
    ExpressiveCornerSize a,
    ExpressiveCornerSize b,
    double t,
  ) => ExpressiveCornerSize._(
    lerpDouble(a.dp, b.dp, t)!,
    lerpDouble(a.fraction, b.fraction, t)!,
  );

  @override
  bool operator ==(Object other) =>
      other is ExpressiveCornerSize &&
      other.dp == dp &&
      other.fraction == fraction;

  @override
  int get hashCode => Object.hash(dp, fraction);

  @override
  String toString() => 'ExpressiveCornerSize(dp: $dp, fraction: $fraction)';
}

/// A rectangle with four independently sized corners, start and end
/// following the reading direction: Compose's `RoundedCornerShape`. Each
/// corner resolves against the painted rectangle and is clamped to half its
/// shorter side, as Compose clamps. Lerps corner by corner.
@immutable
class ExpressiveCornerBorder extends OutlinedBorder {
  /// A rectangle with the given corners.
  const ExpressiveCornerBorder({
    super.side,
    this.topStart = ExpressiveCornerSize.zero,
    this.topEnd = ExpressiveCornerSize.zero,
    this.bottomEnd = ExpressiveCornerSize.zero,
    this.bottomStart = ExpressiveCornerSize.zero,
  });

  /// Every corner [corner].
  const ExpressiveCornerBorder.all(ExpressiveCornerSize corner, {super.side})
    : topStart = corner,
      topEnd = corner,
      bottomEnd = corner,
      bottomStart = corner;

  /// The size of the top start corner.
  final ExpressiveCornerSize topStart;

  /// The size of the top end corner.
  final ExpressiveCornerSize topEnd;

  /// The size of the bottom end corner.
  final ExpressiveCornerSize bottomEnd;

  /// The size of the bottom start corner.
  final ExpressiveCornerSize bottomStart;

  /// Only the top corners kept; the bottom ones [bottom] (Compose's
  /// `CornerBasedShape.top()`).
  ExpressiveCornerBorder top([
    ExpressiveCornerSize bottom = ExpressiveCornerSize.zero,
  ]) => _with(bottomStart: bottom, bottomEnd: bottom);

  /// Only the bottom corners kept; the top ones [top].
  ExpressiveCornerBorder bottom([
    ExpressiveCornerSize top = ExpressiveCornerSize.zero,
  ]) => _with(topStart: top, topEnd: top);

  /// Only the start corners kept; the end ones [end].
  ExpressiveCornerBorder start([
    ExpressiveCornerSize end = ExpressiveCornerSize.zero,
  ]) => _with(topEnd: end, bottomEnd: end);

  /// Only the end corners kept; the start ones [start].
  ExpressiveCornerBorder end([
    ExpressiveCornerSize start = ExpressiveCornerSize.zero,
  ]) => _with(topStart: start, bottomStart: start);

  ExpressiveCornerBorder _with({
    BorderSide? side,
    ExpressiveCornerSize? topStart,
    ExpressiveCornerSize? topEnd,
    ExpressiveCornerSize? bottomEnd,
    ExpressiveCornerSize? bottomStart,
  }) => ExpressiveCornerBorder(
    side: side ?? this.side,
    topStart: topStart ?? this.topStart,
    topEnd: topEnd ?? this.topEnd,
    bottomEnd: bottomEnd ?? this.bottomEnd,
    bottomStart: bottomStart ?? this.bottomStart,
  );

  /// The corner radii on [rect], clamped, start and end placed by
  /// [textDirection] (left-to-right when null).
  BorderRadius radiiOn(Rect rect, [TextDirection? textDirection]) {
    final limit = rect.shortestSide * 0.5;
    Radius r(ExpressiveCornerSize corner) =>
        Radius.circular(math.min(corner.resolve(rect.size), limit));
    return BorderRadiusDirectional.only(
      topStart: r(topStart),
      topEnd: r(topEnd),
      bottomEnd: r(bottomEnd),
      bottomStart: r(bottomStart),
    ).resolve(textDirection ?? TextDirection.ltr);
  }

  RoundedRectangleBorder _on(Rect rect, TextDirection? textDirection) =>
      RoundedRectangleBorder(
        side: side,
        borderRadius: radiiOn(rect, textDirection),
      );

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(side.strokeInset);

  @override
  ExpressiveCornerBorder copyWith({BorderSide? side}) => _with(side: side);

  @override
  ExpressiveCornerBorder scale(double t) => ExpressiveCornerBorder(
    side: side.scale(t),
    topStart: topStart.scale(t),
    topEnd: topEnd.scale(t),
    bottomEnd: bottomEnd.scale(t),
    bottomStart: bottomStart.scale(t),
  );

  @override
  ShapeBorder? lerpFrom(ShapeBorder? a, double t) {
    if (a is ExpressiveCornerBorder) {
      return ExpressiveCornerBorder.lerp(a, this, t);
    }
    return super.lerpFrom(a, t);
  }

  @override
  ShapeBorder? lerpTo(ShapeBorder? b, double t) {
    if (b is ExpressiveCornerBorder) {
      return ExpressiveCornerBorder.lerp(this, b, t);
    }
    return super.lerpTo(b, t);
  }

  /// Between [a] and [b], corner by corner.
  static ExpressiveCornerBorder lerp(
    ExpressiveCornerBorder a,
    ExpressiveCornerBorder b,
    double t,
  ) => ExpressiveCornerBorder(
    side: BorderSide.lerp(a.side, b.side, t),
    topStart: ExpressiveCornerSize.lerp(a.topStart, b.topStart, t),
    topEnd: ExpressiveCornerSize.lerp(a.topEnd, b.topEnd, t),
    bottomEnd: ExpressiveCornerSize.lerp(a.bottomEnd, b.bottomEnd, t),
    bottomStart: ExpressiveCornerSize.lerp(a.bottomStart, b.bottomStart, t),
  );

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      _on(rect, textDirection).getInnerPath(rect, textDirection: textDirection);

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) =>
      _on(rect, textDirection).getOuterPath(rect, textDirection: textDirection);

  @override
  bool get preferPaintInterior => true;

  @override
  void paintInterior(
    Canvas canvas,
    Rect rect,
    Paint paint, {
    TextDirection? textDirection,
  }) => _on(
    rect,
    textDirection,
  ).paintInterior(canvas, rect, paint, textDirection: textDirection);

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) => _on(
    rect,
    textDirection,
  ).paint(canvas, rect, textDirection: textDirection);

  @override
  bool operator ==(Object other) =>
      other is ExpressiveCornerBorder &&
      other.side == side &&
      other.topStart == topStart &&
      other.topEnd == topEnd &&
      other.bottomEnd == bottomEnd &&
      other.bottomStart == bottomStart;

  @override
  int get hashCode =>
      Object.hash(side, topStart, topEnd, bottomEnd, bottomStart);

  @override
  String toString() =>
      'ExpressiveCornerBorder($topStart, $topEnd, $bottomEnd, $bottomStart)';
}

/// The shape scale of one theme: Compose's `Shapes` plus none and full.
@immutable
class ExpressiveShapes with Diagnosticable {
  /// A shape scale of the given steps.
  const ExpressiveShapes({
    required this.none,
    required this.extraSmall,
    required this.small,
    required this.medium,
    required this.large,
    required this.largeIncreased,
    required this.extraLarge,
    required this.extraLargeIncreased,
    required this.extraExtraLarge,
    required this.full,
  });

  /// The square step, with no rounding.
  final ExpressiveCornerBorder none;

  /// The extra-small step.
  final ExpressiveCornerBorder extraSmall;

  /// The small step.
  final ExpressiveCornerBorder small;

  /// The medium step.
  final ExpressiveCornerBorder medium;

  /// The large step.
  final ExpressiveCornerBorder large;

  /// The large-increased step.
  final ExpressiveCornerBorder largeIncreased;

  /// The extra-large step.
  final ExpressiveCornerBorder extraLarge;

  /// The extra-large-increased step.
  final ExpressiveCornerBorder extraLargeIncreased;

  /// The extra-extra-large step.
  final ExpressiveCornerBorder extraExtraLarge;

  /// The full step, rounded to a pill or circle.
  final ExpressiveCornerBorder full;

  /// This corner scale with supplied steps replaced.
  ExpressiveShapes copyWith({
    ExpressiveCornerBorder? none,
    ExpressiveCornerBorder? extraSmall,
    ExpressiveCornerBorder? small,
    ExpressiveCornerBorder? medium,
    ExpressiveCornerBorder? large,
    ExpressiveCornerBorder? largeIncreased,
    ExpressiveCornerBorder? extraLarge,
    ExpressiveCornerBorder? extraLargeIncreased,
    ExpressiveCornerBorder? extraExtraLarge,
    ExpressiveCornerBorder? full,
  }) => ExpressiveShapes(
    none: none ?? this.none,
    extraSmall: extraSmall ?? this.extraSmall,
    small: small ?? this.small,
    medium: medium ?? this.medium,
    large: large ?? this.large,
    largeIncreased: largeIncreased ?? this.largeIncreased,
    extraLarge: extraLarge ?? this.extraLarge,
    extraLargeIncreased: extraLargeIncreased ?? this.extraLargeIncreased,
    extraExtraLarge: extraExtraLarge ?? this.extraExtraLarge,
    full: full ?? this.full,
  );

  /// Interpolates every step using its corner geometry.
  static ExpressiveShapes lerp(
    ExpressiveShapes a,
    ExpressiveShapes b,
    double t,
  ) => ExpressiveShapes(
    none: ExpressiveCornerBorder.lerp(a.none, b.none, t),
    extraSmall: ExpressiveCornerBorder.lerp(a.extraSmall, b.extraSmall, t),
    small: ExpressiveCornerBorder.lerp(a.small, b.small, t),
    medium: ExpressiveCornerBorder.lerp(a.medium, b.medium, t),
    large: ExpressiveCornerBorder.lerp(a.large, b.large, t),
    largeIncreased: ExpressiveCornerBorder.lerp(
      a.largeIncreased,
      b.largeIncreased,
      t,
    ),
    extraLarge: ExpressiveCornerBorder.lerp(a.extraLarge, b.extraLarge, t),
    extraLargeIncreased: ExpressiveCornerBorder.lerp(
      a.extraLargeIncreased,
      b.extraLargeIncreased,
      t,
    ),
    extraExtraLarge: ExpressiveCornerBorder.lerp(
      a.extraExtraLarge,
      b.extraExtraLarge,
      t,
    ),
    full: ExpressiveCornerBorder.lerp(a.full, b.full, t),
  );

  /// The step [corner] of the scale.
  ExpressiveCornerBorder corner(ExpressiveCorner corner) => switch (corner) {
    ExpressiveCorner.none => none,
    ExpressiveCorner.extraSmall => extraSmall,
    ExpressiveCorner.small => small,
    ExpressiveCorner.medium => medium,
    ExpressiveCorner.large => large,
    ExpressiveCorner.largeIncreased => largeIncreased,
    ExpressiveCorner.extraLarge => extraLarge,
    ExpressiveCorner.extraLargeIncreased => extraLargeIncreased,
    ExpressiveCorner.extraExtraLarge => extraExtraLarge,
    ExpressiveCorner.full => full,
  };

  /// The shape a component token names (Compose's `Shapes.fromToken`): the
  /// theme's step, or its top, start or end variant.
  ExpressiveCornerBorder of(ExpressiveShapeKey key) => switch (key) {
    ExpressiveShapeKey.cornerNone => none,
    ExpressiveShapeKey.cornerExtraSmall => extraSmall,
    ExpressiveShapeKey.cornerExtraSmallTop => extraSmall.top(),
    ExpressiveShapeKey.cornerSmall => small,
    ExpressiveShapeKey.cornerMedium => medium,
    ExpressiveShapeKey.cornerLarge => large,
    ExpressiveShapeKey.cornerLargeTop => large.top(),
    ExpressiveShapeKey.cornerLargeStart => large.start(),
    ExpressiveShapeKey.cornerLargeEnd => large.end(),
    ExpressiveShapeKey.cornerLargeIncreased => largeIncreased,
    ExpressiveShapeKey.cornerExtraLarge => extraLarge,
    ExpressiveShapeKey.cornerExtraLargeTop => extraLarge.top(),
    ExpressiveShapeKey.cornerExtraLargeIncreased => extraLargeIncreased,
    ExpressiveShapeKey.cornerExtraExtraLarge => extraExtraLarge,
    ExpressiveShapeKey.cornerFull => full,
  };

  @override
  bool operator ==(Object other) =>
      other is ExpressiveShapes &&
      other.none == none &&
      other.extraSmall == extraSmall &&
      other.small == small &&
      other.medium == medium &&
      other.large == large &&
      other.largeIncreased == largeIncreased &&
      other.extraLarge == extraLarge &&
      other.extraLargeIncreased == extraLargeIncreased &&
      other.extraExtraLarge == extraExtraLarge &&
      other.full == full;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    for (final (name, corner) in <(String, ExpressiveCornerBorder)>[
      ('none', none),
      ('extraSmall', extraSmall),
      ('small', small),
      ('medium', medium),
      ('large', large),
      ('largeIncreased', largeIncreased),
      ('extraLarge', extraLarge),
      ('extraLargeIncreased', extraLargeIncreased),
      ('extraExtraLarge', extraExtraLarge),
      ('full', full),
    ]) {
      properties.add(DiagnosticsProperty<ExpressiveCornerBorder>(name, corner));
    }
  }

  @override
  int get hashCode => Object.hash(
    none,
    extraSmall,
    small,
    medium,
    large,
    largeIncreased,
    extraLarge,
    extraLargeIncreased,
    extraExtraLarge,
    full,
  );
}

/// The outline of [shape] in [rect], as Compose's `RoundedPolygon.toShape`
/// lays it out: the unit shape stretched to the rectangle's size, then
/// moved so its bounds are centred in it.
Path expressiveLibraryShapePath(ExpressiveMaterialShape shape, Rect rect) {
  final stretched = expressiveLibraryUnitPath(shape)
      .transform(Matrix4.diagonal3Values(rect.width, rect.height, 1).storage);
  return stretched.shift(rect.center - stretched.getBounds().center);
}

/// A library shape as a border: to clip imagery (`ClipPath.shape`,
/// `ShapeDecoration`), never a text container (CONTRACT §3).
@immutable
class ExpressiveMaterialShapeBorder extends OutlinedBorder {
  /// A border of the library [shape], with an optional [side].
  const ExpressiveMaterialShapeBorder(this.shape, {super.side});

  /// The library shape the border follows.
  final ExpressiveMaterialShape shape;

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(side.strokeInset);

  @override
  ExpressiveMaterialShapeBorder copyWith({BorderSide? side}) =>
      ExpressiveMaterialShapeBorder(shape, side: side ?? this.side);

  @override
  ExpressiveMaterialShapeBorder scale(double t) =>
      ExpressiveMaterialShapeBorder(shape, side: side.scale(t));

  @override
  ShapeBorder? lerpFrom(ShapeBorder? a, double t) =>
      a is ExpressiveMaterialShapeBorder
      ? _LibraryMorphBorder(a.shape, shape, t, BorderSide.lerp(a.side, side, t))
      : super.lerpFrom(a, t);

  @override
  ShapeBorder? lerpTo(ShapeBorder? b, double t) =>
      b is ExpressiveMaterialShapeBorder
      ? _LibraryMorphBorder(shape, b.shape, t, BorderSide.lerp(side, b.side, t))
      : super.lerpTo(b, t);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      expressiveLibraryShapePath(shape, rect.deflate(side.strokeInset));

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) =>
      expressiveLibraryShapePath(shape, rect);

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (side.style == BorderStyle.none) return;
    canvas.drawPath(
      expressiveLibraryShapePath(shape, rect.inflate(side.strokeOffset * 0.5)),
      side.toPaint(),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ExpressiveMaterialShapeBorder &&
      other.shape == shape &&
      other.side == side;

  @override
  int get hashCode => Object.hash(shape, side);
}

/// A frame of the M3 polygon morph, also usable as an animation endpoint.
class _LibraryMorphBorder extends OutlinedBorder {
  const _LibraryMorphBorder(this.from, this.to, this.progress, BorderSide side)
    : super(side: side);

  final ExpressiveMaterialShape from;
  final ExpressiveMaterialShape to;
  final double progress;

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(side.strokeInset);

  @override
  _LibraryMorphBorder copyWith({BorderSide? side}) =>
      _LibraryMorphBorder(from, to, progress, side ?? this.side);

  @override
  _LibraryMorphBorder scale(double t) => copyWith(side: side.scale(t));

  @override
  ShapeBorder? lerpTo(ShapeBorder? b, double t) {
    final end = b is ExpressiveMaterialShapeBorder
        ? (b.shape == from
              ? 0.0
              : b.shape == to
              ? 1.0
              : null)
        : b is _LibraryMorphBorder && b.from == from && b.to == to
        ? b.progress
        : null;
    return end == null
        ? super.lerpTo(b, t)
        : _LibraryMorphBorder(
            from,
            to,
            lerpDouble(progress, end, t)!,
            BorderSide.lerp(side, (b! as OutlinedBorder).side, t),
          );
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    // Preserve the exact endpoint paths as well as the intervening cubics.
    if (progress == 0) return expressiveLibraryShapePath(from, rect);
    if (progress == 1) return expressiveLibraryShapePath(to, rect);
    final path = Path();
    ExpressiveMorph.between(from, to).writePath(path, progress, rect.size);
    return path.shift(rect.center - path.getBounds().center);
  }

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) => getOuterPath(
    rect.deflate(side.strokeInset),
    textDirection: textDirection,
  );

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (side.style == BorderStyle.none) return;
    canvas.drawPath(
      getOuterPath(
        rect.inflate(side.strokeOffset * .5),
        textDirection: textDirection,
      ),
      side.toPaint(),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is _LibraryMorphBorder &&
      from == other.from &&
      to == other.to &&
      progress == other.progress &&
      side == other.side;

  @override
  int get hashCode => Object.hash(from, to, progress, side);
}

/// A morph between two library shapes (Compose's `Morph`): the curves of
/// both matched once, then any progress between them written into a
/// [Path] the caller owns and reuses — nothing is allocated per frame.
/// The matched data is shared and immutable; the output path never is, so
/// any number of clippers and painters can use one pair at their own
/// progress. Progress is what a spring drives (0: [from], 1: [to]; a
/// little beyond overshoots).
class ExpressiveMorph {
  /// The morph from [from] to [to]; [ExpressiveMorph.between] shares one.
  ExpressiveMorph(this.from, this.to)
    : _morph = ExpressivePolygonMorph(
        expressiveLibraryPolygon(from),
        expressiveLibraryPolygon(to),
      );

  /// The shared morph from [from] to [to], matched once per pair.
  factory ExpressiveMorph.between(
    ExpressiveMaterialShape from,
    ExpressiveMaterialShape to,
  ) => _shared[(from, to)] ??= ExpressiveMorph(from, to);

  static final Map<
    (ExpressiveMaterialShape, ExpressiveMaterialShape),
    ExpressiveMorph
  >
  _shared =
      <(ExpressiveMaterialShape, ExpressiveMaterialShape), ExpressiveMorph>{};

  /// The shape the morph starts from.
  final ExpressiveMaterialShape from;

  /// The shape the morph ends at.
  final ExpressiveMaterialShape to;
  final ExpressivePolygonMorph _morph;

  /// Writes the shape at [progress] in the unit square scaled to [size]
  /// (Compose's `Morph.toPath`, start angle 0) into [into], replacing its
  /// contents. [into] belongs to the caller: keep one per clipper or
  /// painter and reuse it every frame.
  void writePath(Path into, double progress, Size size) =>
      _morph.writePath(into, progress, scaleX: size.width, scaleY: size.height);

  /// The shape at [progress] as Compose's cubics, each a list of eight
  /// numbers (anchor, control, control, anchor): allocates, for tests and
  /// tools, never per frame.
  List<List<double>> cubicsAt(double progress) => <List<double>>[
    for (final c in _morph.asCubics(progress))
      <double>[
        c.anchor0X,
        c.anchor0Y,
        c.control0X,
        c.control0Y,
        c.control1X,
        c.control1Y,
        c.anchor1X,
        c.anchor1Y,
      ],
  ];
}

/// Clips to [morph] at [progress]'s value, re-clipping as it changes: a
/// library-shape morph over imagery, driven by a spring.
class ExpressiveMorphClipper extends CustomClipper<Path> {
  /// A clipper that clips to [morph] at [progress].
  ExpressiveMorphClipper(this.morph, this.progress) : super(reclip: progress);

  /// The morph clipped to.
  final ExpressiveMorph morph;

  /// How far the morph has run, from 0 to 1.
  final ValueListenable<double> progress;

  // This clipper's own path: the render object keeps the clip between
  // re-clips, so it must never be written by another consumer of [morph].
  final Path _path = Path();

  @override
  Path getClip(Size size) {
    morph.writePath(_path, progress.value, size);
    return _path;
  }

  @override
  bool shouldReclip(ExpressiveMorphClipper oldClipper) =>
      oldClipper.morph != morph || oldClipper.progress != progress;
}

/// [shape]'s cubics, normalized into the unit square as Compose's
/// `MaterialShapes.<Name>` holds them, each a list of eight numbers: for
/// tests and tools.
List<List<double>> expressiveLibraryShapeCubics(
  ExpressiveMaterialShape shape,
) => <List<double>>[
  for (final c in expressiveLibraryPolygon(shape).cubics)
    <double>[
      c.anchor0X,
      c.anchor0Y,
      c.control0X,
      c.control0Y,
      c.control1X,
      c.control1Y,
      c.anchor1X,
      c.anchor1Y,
    ],
];
