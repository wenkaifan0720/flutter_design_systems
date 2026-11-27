/// Shapes a look can open: one corner style for every corner of a border
/// ([RawCornerStyle], drawn by [RawCornerBorder]), the look's corner steps
/// ([RawCornerScale]), the stroke and depth it opens ([RawShapeScheme]), and
/// the band it holds each to ([RawShapeLimits]).
///
/// A look puts a [RawShapeScheme] on its own theme data beside its colours,
/// lerps it in its theme's lerp (so a theme change animates, corners
/// morphing from one style to another without a snap), and draws its parts
/// with borders from it, deriving inner and outer parts with
/// [RawCornerBorder.inset] and [RawCornerBorder.outset] so they stay fitted
/// as a step moves. What a look does not open stays a constant of its own.
library;

import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

/// How a corner is cut. One style shapes all four corners of a
/// [RawCornerBorder], whose radii may differ. Every style fills the corner's
/// square, radius by radius, so a radius is the same extent in each.
enum RawCornerStyle {
  /// A quarter circle (an ellipse for an elliptical radius), as
  /// [RoundedRectangleBorder]'s.
  round,

  /// A smooth corner whose curvature rises from nothing where it leaves the
  /// straight sides, so no join shows, as iOS's continuous corners: fuller
  /// than [round] at the same radius.
  continuous,

  /// A straight chamfer across the corner, as [BeveledRectangleBorder]'s.
  bevel,

  /// A square cut inward: the corner's square taken out.
  notch,

  /// A stair of equal steps across the corner, each riser and tread on a
  /// whole logical pixel from the corner: 2 steps under a radius of 8, 3 up
  /// to 16, 4 above, never a step under a pixel. The count changes in whole
  /// steps as the radius grows.
  step,

  /// A quarter circle scooped inward, centred on the corner.
  concave,
}

// A cubic from $1 to $4, $2 and $3 its control points.
typedef _Cubic = (Offset, Offset, Offset, Offset);

// Each corner's fullness, start and end as the text runs: top start, top
// end, bottom start, bottom end. 1: half the shorter side; 0: its radius;
// between, lerping from one to the other.
typedef _Fullness = (double, double, double, double);

const _Fullness _noneFull = (0.0, 0.0, 0.0, 0.0);
const _Fullness _allFull = (1.0, 1.0, 1.0, 1.0);

_Fullness _lerpFullness(_Fullness a, _Fullness b, double t) => (
  a.$1 + (b.$1 - a.$1) * t,
  a.$2 + (b.$2 - a.$2) * t,
  a.$3 + (b.$3 - a.$3) * t,
  a.$4 + (b.$4 - a.$4) * t,
);

// A corner's radius [r] once its sides move [d] in (out when negative), so
// the new corner runs parallel to the old: a round corner keeps its centre
// (the radius less the inset); a chamfer at 45° keeps its distance (2 − √2
// of the inset off); a notch's or a stair's legs move with the sides (the
// same radius). A scoop's parallel is a circle d larger round the old
// corner, which no scoop round the new corner follows: the new one meets the
// sides where that circle does, √(r² + 2rd) − d from the corner, a little
// under r either way (past an outset of half the radius, where that circle
// leaves the sides, it goes on growing with the outset).
double _concentric(RawCornerStyle style, double r, double d) => switch (style) {
  RawCornerStyle.round || RawCornerStyle.continuous => r - d,
  RawCornerStyle.bevel => r - (2 - math.sqrt2) * d,
  RawCornerStyle.notch || RawCornerStyle.step => r,
  RawCornerStyle.concave => math.sqrt(math.max(r * r + 2 * r * d, 0)) - d,
};

// Every corner style as this many cubics, for a morph between two styles.
const int _morphPieces = 8;

_Cubic _line(Offset a, Offset b) =>
    (a, Offset.lerp(a, b, 1 / 3)!, Offset.lerp(a, b, 2 / 3)!, b);

// A quarter turn of an arc, [at] its point and [tangent] its derivative at
// an angle, as [pieces] cubics.
List<_Cubic> _arc(
  Offset Function(double angle) at,
  Offset Function(double angle) tangent,
  int pieces,
) {
  final step = math.pi / 2 / pieces;
  final k = 4 / 3 * math.tan(step / 4);
  return [
    for (var i = 0; i < pieces; i++)
      (
        at(i * step),
        at(i * step) + tangent(i * step) * k,
        at((i + 1) * step) - tangent((i + 1) * step) * k,
        at((i + 1) * step),
      ),
  ];
}

// The steps a stair takes across a corner [extent] long.
int _steps(double extent) {
  final n = extent < 8 ? 2 : (extent <= 16 ? 3 : 4);
  return math.min(n, math.max(1, extent.floor()));
}

// One corner from (1, 0) to (0, 1) in its unit square, the corner point at
// the origin: s runs along the side the outline arrives on ([ea] long), t
// along the side it leaves on ([eb] long).
List<_Cubic> _corner(RawCornerStyle style, double ea, double eb) {
  switch (style) {
    case RawCornerStyle.round:
      return _arc(
        (a) => Offset(1 - math.sin(a), 1 - math.cos(a)),
        (a) => Offset(-math.cos(a), math.sin(a)),
        2,
      );
    case RawCornerStyle.concave:
      return _arc(
        (a) => Offset(math.cos(a), math.sin(a)),
        (a) => Offset(-math.sin(a), math.cos(a)),
        2,
      );
    case RawCornerStyle.continuous:
      // Each half's handles lie on its side, so the curvature is 0 where it
      // leaves the side; the halves meet on the diagonal, tangent.
      const m = 0.22;
      return const [
        (Offset(1, 0), Offset(0.72, 0), Offset(2 * m, 0), Offset(m, m)),
        (Offset(m, m), Offset(0, 2 * m), Offset(0, 0.72), Offset(0, 1)),
      ];
    case RawCornerStyle.bevel:
      return [_line(const Offset(1, 0), const Offset(0, 1))];
    case RawCornerStyle.notch:
      return [
        _line(const Offset(1, 0), const Offset(1, 1)),
        _line(const Offset(1, 1), const Offset(0, 1)),
      ];
    case RawCornerStyle.step:
      final n = _steps(math.max(ea, eb));
      // Inner positions on whole pixels from the corner; the ends stay on
      // the sides.
      double snap(double f, double extent) => f <= 0 || f >= 1 || extent < 1
          ? f
          : (extent * f).roundToDouble() / extent;
      final points = <Offset>[const Offset(1, 0)];
      for (var k = 1; k <= n; k++) {
        final t = snap(k / n, eb);
        points
          ..add(Offset(snap(1 - (k - 1) / n, ea), t))
          ..add(Offset(snap(1 - k / n, ea), t));
      }
      return [
        for (var i = 0; i < points.length - 1; i++)
          _line(points[i], points[i + 1]),
      ];
  }
}

(_Cubic, _Cubic) _split(_Cubic c) {
  final (p0, p1, p2, p3) = c;
  final a = (p0 + p1) / 2, b = (p1 + p2) / 2, d = (p2 + p3) / 2;
  final ab = (a + b) / 2, bd = (b + d) / 2;
  final mid = (ab + bd) / 2;
  return ((p0, a, ab, mid), (mid, bd, d, p3));
}

// [cubics] as [_morphPieces] cubics drawing the same curve: the longest
// split in half until there are as many.
List<_Cubic> _resample(List<_Cubic> cubics) {
  final out = [...cubics];
  while (out.length < _morphPieces) {
    var at = 0;
    var longest = -1.0;
    for (var i = 0; i < out.length; i++) {
      final chord = (out[i].$4 - out[i].$1).distance;
      if (chord > longest + 1e-9) {
        longest = chord;
        at = i;
      }
    }
    final (a, b) = _split(out[at]);
    out
      ..removeAt(at)
      ..insertAll(at, [a, b]);
  }
  return out;
}

// A corner between styles, [weights] each style's share.
List<_Cubic> _mixed(List<double> weights, double ea, double eb) {
  var sum = List<_Cubic>.filled(_morphPieces, (
    Offset.zero,
    Offset.zero,
    Offset.zero,
    Offset.zero,
  ));
  for (final style in RawCornerStyle.values) {
    final w = weights[style.index];
    if (w == 0) continue;
    final c = _resample(_corner(style, ea, eb));
    sum = [
      for (var i = 0; i < _morphPieces; i++)
        (
          sum[i].$1 + c[i].$1 * w,
          sum[i].$2 + c[i].$2 * w,
          sum[i].$3 + c[i].$3 * w,
          sum[i].$4 + c[i].$4 * w,
        ),
    ];
  }
  return sum;
}

List<double> _oneHot(RawCornerStyle style) => [
  for (final s in RawCornerStyle.values) s == style ? 1.0 : 0.0,
];

List<double> _lerpWeights(List<double> a, List<double> b, double t) => [
  for (var i = 0; i < a.length; i++) a[i] + (b[i] - a[i]) * t,
];

// The style with the largest share.
RawCornerStyle _dominant(List<double> weights) {
  var at = 0;
  for (var i = 1; i < weights.length; i++) {
    if (weights[i] > weights[at]) at = i;
  }
  return RawCornerStyle.values[at];
}

// [weights] when it mixes styles, null when one style has it all.
List<double>? _mixOrNull(List<double> weights) {
  final top = _dominant(weights).index;
  for (var i = 0; i < weights.length; i++) {
    if ((weights[i] - (i == top ? 1 : 0)).abs() > 1e-9) return weights;
  }
  return null;
}

/// A rectangle's outline whose four corners are cut in one [style], each to
/// its own radius in [borderRadius] (elliptical and directional radii
/// allowed), or round as a stadium ([full]). A look's border for a part
/// whose corners each take their own step comes from
/// [RawCornerScale.borderOf], where a single corner may be full.
///
/// Lerps from and to Flutter's [RoundedRectangleBorder] (as
/// [RawCornerStyle.round]), [RoundedSuperellipseBorder] (as
/// [RawCornerStyle.continuous]), [BeveledRectangleBorder] (as
/// [RawCornerStyle.bevel]) and [StadiumBorder] (round and [full]), and
/// between any two styles, morphing the outline: a [ShapeBorderTween] from a
/// bevel to a round corner moves the corner continuously, where Flutter's
/// own borders of two kinds switch halfway.
///
/// A round corner at rest draws and clips as an [RRect], Flutter's fast
/// path; the other styles, and a corner between styles, draw a path made
/// once per size.
///
/// ```dart
/// const DecoratedBox(decoration: ShapeDecoration(color: Color(0xFFE8E8EE), shape: RawCornerBorder(style: RawCornerStyle.bevel, borderRadius: BorderRadius.all(Radius.circular(12)))), child: SizedBox(width: 120, height: 48))
/// ```
@immutable
class RawCornerBorder extends OutlinedBorder {
  /// Corners cut in [style] to [borderRadius]; with [full], to half the
  /// shorter side (a stadium), at most [maxRadius] when given.
  const RawCornerBorder({
    super.side,
    this.style = RawCornerStyle.round,
    this.borderRadius = BorderRadius.zero,
    bool full = false,
    this.maxRadius,
  }) : _fullness = full ? _allFull : _noneFull,
       _mix = null,
       _inset = null,
       _floor = 0,
       assert(maxRadius == null || maxRadius >= 0);

  const RawCornerBorder._raw({
    required super.side,
    required this.style,
    required this.borderRadius,
    required this._fullness,
    required this.maxRadius,
    required this._mix,
    required this._inset,
    required this._floor,
  });

  /// How every corner is cut: while lerping between two styles, the style
  /// with the larger share.
  final RawCornerStyle style;

  /// Each corner's radius: how far along each side the corner reaches.
  final BorderRadiusGeometry borderRadius;

  /// The most a [full] corner's radius reaches (a capsule kept from
  /// ballooning under enlarged text); null, half the shorter side always.
  final double? maxRadius;

  // Each corner's: 1, half the shorter side (all four: a stadium); 0, its
  // [borderRadius]; between, lerping from one to the other.
  final _Fullness _fullness;

  // Each style's share while lerping between styles; null: [style] alone.
  final List<double>? _mix;

  // The concentric inset from the border this one was made from (inset).
  final EdgeInsetsGeometry? _inset;

  // The least an inset corner shrinks to.
  final double _floor;

  /// Whether every corner is half the shorter side (a stadium, at most
  /// [maxRadius]).
  bool get full =>
      _fullness.$1 >= 1 &&
      _fullness.$2 >= 1 &&
      _fullness.$3 >= 1 &&
      _fullness.$4 >= 1;

  List<double> get _weights => _mix ?? _oneHot(style);

  bool get _roundOnly => _mix == null && style == RawCornerStyle.round;

  /// The face [by] inside this one, its corners concentric with these: given
  /// the rect deflated by [by], its outline runs parallel to this one's. A
  /// round corner's radius is this one's less the inset on each side
  /// (elliptical where the insets differ); a chamfer's keeps its distance;
  /// a notch's and a stair's keep their size; a scoop meets the sides where
  /// its parallel does, a little smaller. A corner of 0
  /// stays 0; any other never shrinks below [floor] (a look with no sharp
  /// corner gives its least). A [full] border stays full inside.
  ///
  /// ```dart
  /// const RawCornerBorder(full: true).inset(const EdgeInsets.all(3))
  /// ```
  RawCornerBorder inset(EdgeInsetsGeometry by, {double floor = 0}) {
    assert(floor >= 0);
    return RawCornerBorder._raw(
      side: side,
      style: style,
      borderRadius: borderRadius,
      fullness: _fullness,
      maxRadius: maxRadius,
      mix: _mix,
      inset: (_inset ?? EdgeInsets.zero).add(by),
      floor: math.max(_floor, floor),
    );
  }

  /// The ring [by] outside this one, its corners concentric with these:
  /// given the rect inflated by [by] (a focus ring's gap and half its
  /// stroke, for a ring drawn on its centre line). See [inset].
  RawCornerBorder outset(EdgeInsetsGeometry by) => inset(by * -1);

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(side.strokeInset);

  @override
  RawCornerBorder scale(double t) => RawCornerBorder._raw(
    side: side.scale(t),
    style: style,
    borderRadius: borderRadius * t,
    fullness: _fullness,
    maxRadius: maxRadius == null ? null : maxRadius! * t,
    mix: _mix,
    inset: _inset == null ? null : _inset * t,
    floor: _floor * t,
  );

  @override
  RawCornerBorder copyWith({
    BorderSide? side,
    RawCornerStyle? style,
    BorderRadiusGeometry? borderRadius,
    bool? full,
    double? maxRadius,
  }) => RawCornerBorder._raw(
    side: side ?? this.side,
    style: style ?? this.style,
    borderRadius: borderRadius ?? this.borderRadius,
    fullness: full == null ? _fullness : (full ? _allFull : _noneFull),
    maxRadius: maxRadius ?? this.maxRadius,
    mix: style == null ? _mix : null,
    inset: _inset,
    floor: _floor,
  );

  // [s] as a corner border, when it is one of Flutter's this one stands in
  // for.
  static RawCornerBorder? _from(ShapeBorder? s) => switch (s) {
    RawCornerBorder() => s,
    RoundedRectangleBorder(:final side, :final borderRadius) => RawCornerBorder(
      side: side,
      borderRadius: borderRadius,
    ),
    RoundedSuperellipseBorder(:final side, :final borderRadius) =>
      RawCornerBorder(
        side: side,
        style: RawCornerStyle.continuous,
        borderRadius: borderRadius,
      ),
    BeveledRectangleBorder(:final side, :final borderRadius) => RawCornerBorder(
      side: side,
      style: RawCornerStyle.bevel,
      borderRadius: borderRadius,
    ),
    StadiumBorder(:final side) => RawCornerBorder(side: side, full: true),
    _ => null,
  };

  static RawCornerBorder _lerp(RawCornerBorder a, RawCornerBorder b, double t) {
    if (identical(a, b)) return a;
    final weights = _lerpWeights(a._weights, b._weights, t);
    return RawCornerBorder._raw(
      side: BorderSide.lerp(a.side, b.side, t),
      style: _dominant(weights),
      borderRadius: BorderRadiusGeometry.lerp(
        a.borderRadius,
        b.borderRadius,
        t,
      )!,
      fullness: _lerpFullness(a._fullness, b._fullness, t),
      maxRadius: a.maxRadius != null && b.maxRadius != null
          ? lerpDouble(a.maxRadius, b.maxRadius, t)
          : (t < 0.5 ? a.maxRadius : b.maxRadius),
      mix: _mixOrNull(weights),
      inset: EdgeInsetsGeometry.lerp(a._inset, b._inset, t),
      floor: lerpDouble(a._floor, b._floor, t)!,
    );
  }

  @override
  ShapeBorder? lerpFrom(ShapeBorder? a, double t) {
    final from = _from(a);
    if (from != null) return _lerp(from, this, t);
    return super.lerpFrom(a, t);
  }

  @override
  ShapeBorder? lerpTo(ShapeBorder? b, double t) {
    final to = _from(b);
    if (to != null) return _lerp(this, to, t);
    return super.lerpTo(b, t);
  }

  // The rect drawn and its four corners' radii (top left, top right, bottom
  // right, bottom left) for [rect], [extra] further in on every side (a
  // stroke's centre line; out when negative), concentric.
  (Rect, List<Radius>) _resolve(
    Rect rect,
    TextDirection? textDirection,
    double extra,
  ) {
    final r = borderRadius.resolve(textDirection);
    final pending = _inset?.resolve(textDirection) ?? EdgeInsets.zero;
    final box = rect.deflate(extra);
    final weights = _weights;
    // Between styles, each style's concentric radius by its share.
    double moved(double radius, double inset) {
      var out = 0.0;
      for (final style in RawCornerStyle.values) {
        final w = weights[style.index];
        if (w != 0) out += w * _concentric(style, radius, inset);
      }
      return out;
    }

    double along(double radius, double inset) {
      if (radius <= 0) return 0;
      final to = moved(radius, inset);
      return math.max(math.max(to, math.min(radius, _floor)), 0);
    }

    final half = math.max(box.shortestSide / 2, 0.0);
    double fullAlong(double inset) => maxRadius == null
        ? half
        : math.min(half, math.max(moved(maxRadius!, inset), 0.0));
    Radius corner(Radius base, double dx, double dy, double fullness) {
      final own = Radius.elliptical(along(base.x, dx), along(base.y, dy));
      fullness = fullness.clamp(0.0, 1.0);
      if (fullness == 0) return own;
      return Radius.lerp(
        own,
        Radius.elliptical(fullAlong(dx), fullAlong(dy)),
        fullness,
      )!;
    }

    // Each corner's fullness, top left first round to bottom left.
    final (ts, te, bs, be) = _fullness;
    assert(
      textDirection != null || (ts == te && te == bs && bs == be),
      'A RawCornerBorder whose corners are not all equally full needs a '
      'text direction: start and end are read from it.',
    );
    final f = textDirection == TextDirection.rtl
        ? [te, ts, bs, be]
        : [ts, te, be, bs];
    final left = pending.left + extra, right = pending.right + extra;
    final top = pending.top + extra, bottom = pending.bottom + extra;
    final radii = [
      corner(r.topLeft, left, top, f[0]),
      corner(r.topRight, right, top, f[1]),
      corner(r.bottomRight, right, bottom, f[2]),
      corner(r.bottomLeft, left, bottom, f[3]),
    ];
    // Corners that would overlap shrink together, as an RRect's do.
    final rrect = RRect.fromRectAndCorners(
      box,
      topLeft: radii[0].clamp(minimum: Radius.zero),
      topRight: radii[1].clamp(minimum: Radius.zero),
      bottomRight: radii[2].clamp(minimum: Radius.zero),
      bottomLeft: radii[3].clamp(minimum: Radius.zero),
    ).scaleRadii();
    return (
      box,
      [rrect.tlRadius, rrect.trRadius, rrect.brRadius, rrect.blRadius],
    );
  }

  RRect _rrect(Rect rect, TextDirection? textDirection, double extra) {
    final (box, radii) = _resolve(rect, textDirection, extra);
    return RRect.fromRectAndCorners(
      box,
      topLeft: radii[0],
      topRight: radii[1],
      bottomRight: radii[2],
      bottomLeft: radii[3],
    );
  }

  static const List<Offset> _arrive = [
    Offset(0, 1),
    Offset(-1, 0),
    Offset(0, -1),
    Offset(1, 0),
  ];
  static const List<Offset> _leave = [
    Offset(1, 0),
    Offset(0, 1),
    Offset(-1, 0),
    Offset(0, -1),
  ];

  Path _build(Rect box, List<Radius> radii) {
    final corners = [
      box.topLeft,
      box.topRight,
      box.bottomRight,
      box.bottomLeft,
    ];
    final path = Path();
    for (var i = 0; i < 4; i++) {
      // The top right and bottom left corners arrive along a horizontal side.
      final ea = i.isOdd ? radii[i].x : radii[i].y;
      final eb = i.isOdd ? radii[i].y : radii[i].x;
      Offset at(Offset p) =>
          corners[i] + _arrive[i] * (p.dx * ea) + _leave[i] * (p.dy * eb);
      final start = at(const Offset(1, 0));
      if (i == 0) {
        path.moveTo(start.dx, start.dy);
      } else {
        path.lineTo(start.dx, start.dy);
      }
      final mix = _mix;
      final cubics = mix == null ? _corner(style, ea, eb) : _mixed(mix, ea, eb);
      for (final (_, p1, p2, p3) in cubics) {
        final a = at(p1), b = at(p2), c = at(p3);
        path.cubicTo(a.dx, a.dy, b.dx, b.dy, c.dx, c.dy);
      }
    }
    return path..close();
  }

  static final Expando<Map<(Size, TextDirection?, double), Path>> _paths =
      Expando('RawCornerBorder paths');

  // The outline for [rect], [extra] in; made once per size, direction and
  // inset, at the origin, and moved to [rect].
  Path _path(Rect rect, TextDirection? textDirection, double extra) {
    if (_roundOnly) {
      return Path()..addRRect(_rrect(rect, textDirection, extra));
    }
    final cache = _paths[this] ??= {};
    final key = (rect.size, textDirection, extra);
    var path = cache[key];
    if (path == null) {
      if (cache.length >= 8) cache.clear();
      final (box, radii) = _resolve(
        Offset.zero & rect.size,
        textDirection,
        extra,
      );
      path = cache[key] = _build(box, radii);
    }
    return path.shift(rect.topLeft);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) =>
      _path(rect, textDirection, 0);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      _path(rect, textDirection, side.strokeInset);

  @override
  bool get preferPaintInterior => true;

  @override
  void paintInterior(
    Canvas canvas,
    Rect rect,
    Paint paint, {
    TextDirection? textDirection,
  }) {
    if (_roundOnly) {
      canvas.drawRRect(_rrect(rect, textDirection, 0), paint);
    } else {
      canvas.drawPath(_path(rect, textDirection, 0), paint);
    }
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (side.style == BorderStyle.none) return;
    if (side.width == 0) {
      // A hairline on the edge.
      if (_roundOnly) {
        canvas.drawRRect(_rrect(rect, textDirection, 0), side.toPaint());
      } else {
        canvas.drawPath(_path(rect, textDirection, 0), side.toPaint());
      }
      return;
    }
    if (_roundOnly) {
      canvas.drawDRRect(
        _rrect(rect, textDirection, -side.strokeOutset),
        _rrect(rect, textDirection, side.strokeInset),
        Paint()..color = side.color,
      );
      return;
    }
    // The stroke on its centre line, concentric with the outline.
    canvas.drawPath(
      _path(rect, textDirection, -side.strokeOffset / 2),
      side.toPaint(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RawCornerBorder &&
        other.side == side &&
        other.style == style &&
        other.borderRadius == borderRadius &&
        other._fullness == _fullness &&
        other.maxRadius == maxRadius &&
        listEquals(other._mix, _mix) &&
        other._inset == _inset &&
        other._floor == _floor;
  }

  @override
  int get hashCode => Object.hash(
    side,
    style,
    borderRadius,
    _fullness,
    maxRadius,
    _mix == null ? null : Object.hashAll(_mix),
    _inset,
    _floor,
  );

  @override
  String toString() {
    final (ts, te, bs, be) = _fullness;
    final fullAt = [
      if (ts >= 1) 'topStart',
      if (te >= 1) 'topEnd',
      if (bs >= 1) 'bottomStart',
      if (be >= 1) 'bottomEnd',
    ];
    final corners = full
        ? 'full'
        : fullAt.isEmpty
        ? '$borderRadius'
        : '$borderRadius, full at ${fullAt.join(', ')}';
    return '${objectRuntimeType(this, 'RawCornerBorder')}(${style.name}, '
        '$corners, $side)';
  }
}

/// A step of a [RawCornerScale]: Material 3's corner tokens.
enum RawCorner {
  /// Square: a radius of 0.
  none,

  /// The least rounding (4 in Material 3).
  extraSmall,

  /// 8 in Material 3.
  small,

  /// 12 in Material 3.
  medium,

  /// 16 in Material 3.
  large,

  /// The most rounding short of full (28 in Material 3).
  extraLarge,

  /// Half the shorter side: a stadium, or a circle when square.
  full,
}

/// Which step ([RawCorner]) each corner of a part takes: an app's per-part
/// override of the part's own corners, as a part's style carries it. Start
/// and end follow the text direction, so the corners mirror in a
/// right-to-left app. A corner left null keeps the part's own ([over]).
///
/// A look holds it to what it allows ([RawShapeLimits.clampCorners]) and
/// draws it in its own corner scale ([RawCornerScale.borderOf]), so an
/// overridden corner follows the theme as the part's own corners do.
///
/// ```dart
/// const RawCorners(topEnd: RawCorner.none, bottomStart: RawCorner.none)
/// ```
@immutable
class RawCorners with Diagnosticable {
  /// The corners given; each one left null keeps the part's own.
  const RawCorners({
    this.topStart,
    this.topEnd,
    this.bottomStart,
    this.bottomEnd,
  });

  /// [step] on every corner.
  const RawCorners.all(RawCorner step)
    : topStart = step,
      topEnd = step,
      bottomStart = step,
      bottomEnd = step;

  /// The corners given, every other one square ([RawCorner.none]), as
  /// [BorderRadius.only] makes the others 0.
  ///
  /// ```dart
  /// const RawCorners.only(topStart: RawCorner.large)
  /// ```
  const RawCorners.only({
    RawCorner this.topStart = RawCorner.none,
    RawCorner this.topEnd = RawCorner.none,
    RawCorner this.bottomStart = RawCorner.none,
    RawCorner this.bottomEnd = RawCorner.none,
  });

  /// The top corner where the text starts: the top left in a left-to-right
  /// app.
  final RawCorner? topStart;

  /// The top corner where the text ends.
  final RawCorner? topEnd;

  /// The bottom corner where the text starts.
  final RawCorner? bottomStart;

  /// The bottom corner where the text ends.
  final RawCorner? bottomEnd;

  List<RawCorner?> get _all => [topStart, topEnd, bottomStart, bottomEnd];

  /// Whether no corner is given.
  bool get isEmpty =>
      topStart == null &&
      topEnd == null &&
      bottomStart == null &&
      bottomEnd == null;

  /// Whether every corner given takes the same step (none given: true).
  bool get isUniform => _all.nonNulls.toSet().length <= 1;

  /// This over [base]: each corner this gives, else [base]'s.
  RawCorners over(RawCorners base) => RawCorners(
    topStart: topStart ?? base.topStart,
    topEnd: topEnd ?? base.topEnd,
    bottomStart: bottomStart ?? base.bottomStart,
    bottomEnd: bottomEnd ?? base.bottomEnd,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RawCorners &&
          other.topStart == topStart &&
          other.topEnd == topEnd &&
          other.bottomStart == bottomStart &&
          other.bottomEnd == bottomEnd;

  @override
  int get hashCode => Object.hash(topStart, topEnd, bottomStart, bottomEnd);

  @override
  String toStringShort() {
    final given = [
      for (final (name, step) in [
        ('topStart', topStart),
        ('topEnd', topEnd),
        ('bottomStart', bottomStart),
        ('bottomEnd', bottomEnd),
      ])
        if (step != null) '$name: ${step.name}',
    ];
    return '${objectRuntimeType(this, 'RawCorners')}(${given.join(', ')})';
  }

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) =>
      toStringShort();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(EnumProperty<RawCorner>('topStart', topStart, defaultValue: null))
      ..add(EnumProperty<RawCorner>('topEnd', topEnd, defaultValue: null))
      ..add(
        EnumProperty<RawCorner>('bottomStart', bottomStart, defaultValue: null),
      )
      ..add(
        EnumProperty<RawCorner>('bottomEnd', bottomEnd, defaultValue: null),
      );
  }
}

/// A look's corner steps, Material 3's tokens ([RawCorner]) in one corner
/// [style], each a radius the look sets; Material 3's numbers by default.
/// A look derives its other radii from these steps (an inner pane with
/// [RawCornerBorder.inset]), so they follow when an app moves a step.
///
/// ```dart
/// const RawCornerScale(small: 6, medium: 10, large: 20).border(RawCorner.medium, side: const BorderSide(color: Color(0xFF8A8F99)))
/// ```
@immutable
class RawCornerScale with Diagnosticable {
  /// Steps in [style].
  const RawCornerScale({
    this.style = RawCornerStyle.round,
    this.extraSmall = 4,
    this.small = 8,
    this.medium = 12,
    this.large = 16,
    this.extraLarge = 28,
    this.fullMaxRadius,
  }) : _mix = null,
       assert(extraSmall >= 0 && extraSmall < double.infinity),
       assert(small >= 0 && small < double.infinity),
       assert(medium >= 0 && medium < double.infinity),
       assert(large >= 0 && large < double.infinity),
       assert(extraLarge >= 0 && extraLarge < double.infinity),
       assert(fullMaxRadius == null || fullMaxRadius >= 0);

  const RawCornerScale._raw({
    required this.style,
    required this.extraSmall,
    required this.small,
    required this.medium,
    required this.large,
    required this.extraLarge,
    required this.fullMaxRadius,
    required this._mix,
  });

  /// How every corner is cut: while lerping between two styles, the style
  /// with the larger share (the borders morph between them).
  final RawCornerStyle style;

  /// [RawCorner.extraSmall]'s radius.
  final double extraSmall;

  /// [RawCorner.small]'s radius.
  final double small;

  /// [RawCorner.medium]'s radius.
  final double medium;

  /// [RawCorner.large]'s radius.
  final double large;

  /// [RawCorner.extraLarge]'s radius.
  final double extraLarge;

  /// The most a [RawCorner.full] corner reaches ([RawCornerBorder.maxRadius]);
  /// null, half the shorter side always.
  final double? fullMaxRadius;

  final List<double>? _mix;

  /// [step]'s radius: 0 for [RawCorner.none], infinity for [RawCorner.full]
  /// (half the shorter side, resolved against the size).
  double radius(RawCorner step) => switch (step) {
    RawCorner.none => 0,
    RawCorner.extraSmall => extraSmall,
    RawCorner.small => small,
    RawCorner.medium => medium,
    RawCorner.large => large,
    RawCorner.extraLarge => extraLarge,
    RawCorner.full => double.infinity,
  };

  /// A border at [step], its corners in this scale's style, [side] its
  /// stroke.
  RawCornerBorder border(RawCorner step, {BorderSide side = BorderSide.none}) {
    final full = step == RawCorner.full;
    return RawCornerBorder._raw(
      side: side,
      style: style,
      borderRadius: full || step == RawCorner.none
          ? BorderRadius.zero
          : BorderRadius.all(Radius.circular(radius(step))),
      fullness: full ? _allFull : _noneFull,
      maxRadius: full ? fullMaxRadius : null,
      mix: _mix,
      inset: null,
      floor: 0,
    );
  }

  /// A border whose corners each take their own step of [corners] (a corner
  /// left null is square), in this scale's style, [side] its stroke. Start
  /// and end follow the text direction, so the corners mirror in a
  /// right-to-left app. A [RawCorner.full] corner reaches half the shorter
  /// side (at most [fullMaxRadius]), and corners that would overlap shrink
  /// together. Where every corner takes one step, the same border as
  /// [border].
  ///
  /// ```dart
  /// const RawCornerScale(style: RawCornerStyle.bevel).borderOf(const RawCorners.all(RawCorner.medium).over(const RawCorners(topEnd: RawCorner.none, bottomStart: RawCorner.none)))
  /// ```
  RawCornerBorder borderOf(
    RawCorners corners, {
    BorderSide side = BorderSide.none,
  }) {
    final ts = corners.topStart ?? RawCorner.none;
    final te = corners.topEnd ?? RawCorner.none;
    final bs = corners.bottomStart ?? RawCorner.none;
    final be = corners.bottomEnd ?? RawCorner.none;
    if (ts == te && te == bs && bs == be) return border(ts, side: side);
    Radius at(RawCorner step) =>
        step == RawCorner.none || step == RawCorner.full
        ? Radius.zero
        : Radius.circular(radius(step));
    double fullAt(RawCorner step) => step == RawCorner.full ? 1 : 0;
    final anyFull = [ts, te, bs, be].contains(RawCorner.full);
    return RawCornerBorder._raw(
      side: side,
      style: style,
      borderRadius: BorderRadiusDirectional.only(
        topStart: at(ts),
        topEnd: at(te),
        bottomStart: at(bs),
        bottomEnd: at(be),
      ),
      fullness: (fullAt(ts), fullAt(te), fullAt(bs), fullAt(be)),
      maxRadius: anyFull ? fullMaxRadius : null,
      mix: _mix,
      inset: null,
      floor: 0,
    );
  }

  /// Every step times [factor], [fullMaxRadius] too: an app's "rounder" or
  /// "squarer" in one value. A look holds the result to its band
  /// ([RawShapeLimits.clamp]).
  RawCornerScale scaled(double factor) {
    assert(factor >= 0 && factor < double.infinity);
    return RawCornerScale._raw(
      style: style,
      extraSmall: extraSmall * factor,
      small: small * factor,
      medium: medium * factor,
      large: large * factor,
      extraLarge: extraLarge * factor,
      fullMaxRadius: fullMaxRadius == null ? null : fullMaxRadius! * factor,
      mix: _mix,
    );
  }

  /// A copy with the given values.
  RawCornerScale copyWith({
    RawCornerStyle? style,
    double? extraSmall,
    double? small,
    double? medium,
    double? large,
    double? extraLarge,
    double? fullMaxRadius,
  }) => RawCornerScale._raw(
    style: style ?? this.style,
    extraSmall: extraSmall ?? this.extraSmall,
    small: small ?? this.small,
    medium: medium ?? this.medium,
    large: large ?? this.large,
    extraLarge: extraLarge ?? this.extraLarge,
    fullMaxRadius: fullMaxRadius ?? this.fullMaxRadius,
    mix: style == null ? _mix : null,
  );

  /// Between [a] and [b]: every step lerped, and the corners between their
  /// styles, so a border from the result morphs from one style to the other.
  static RawCornerScale lerp(RawCornerScale a, RawCornerScale b, double t) {
    if (identical(a, b)) return a;
    final weights = _lerpWeights(
      a._mix ?? _oneHot(a.style),
      b._mix ?? _oneHot(b.style),
      t,
    );
    return RawCornerScale._raw(
      style: _dominant(weights),
      extraSmall: lerpDouble(a.extraSmall, b.extraSmall, t)!,
      small: lerpDouble(a.small, b.small, t)!,
      medium: lerpDouble(a.medium, b.medium, t)!,
      large: lerpDouble(a.large, b.large, t)!,
      extraLarge: lerpDouble(a.extraLarge, b.extraLarge, t)!,
      fullMaxRadius: a.fullMaxRadius != null && b.fullMaxRadius != null
          ? lerpDouble(a.fullMaxRadius, b.fullMaxRadius, t)
          : (t < 0.5 ? a.fullMaxRadius : b.fullMaxRadius),
      mix: _mixOrNull(weights),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RawCornerScale &&
          other.style == style &&
          other.extraSmall == extraSmall &&
          other.small == small &&
          other.medium == medium &&
          other.large == large &&
          other.extraLarge == extraLarge &&
          other.fullMaxRadius == fullMaxRadius &&
          listEquals(other._mix, _mix);

  @override
  int get hashCode => Object.hash(
    style,
    extraSmall,
    small,
    medium,
    large,
    extraLarge,
    fullMaxRadius,
    _mix == null ? null : Object.hashAll(_mix),
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(EnumProperty<RawCornerStyle>('style', style))
      ..add(DoubleProperty('extraSmall', extraSmall))
      ..add(DoubleProperty('small', small))
      ..add(DoubleProperty('medium', medium))
      ..add(DoubleProperty('large', large))
      ..add(DoubleProperty('extraLarge', extraLarge))
      ..add(DoubleProperty('fullMaxRadius', fullMaxRadius, defaultValue: null));
  }
}

/// The shape constants a look opens, the shape counterpart of a colour
/// scheme: its [corners], the [stroke] its lines derive from, and the
/// [depth] of its relief, offset or shadow. A look puts one on its theme
/// data and lerps it in its theme's lerp. Null is "not opened": the look
/// draws its own constant, never a 0.
///
/// ```dart
/// RawShapeScheme.lerp(const RawShapeScheme(stroke: 2), const RawShapeScheme(corners: RawCornerScale(style: RawCornerStyle.bevel), stroke: 3), 0.5)
/// ```
@immutable
class RawShapeScheme with Diagnosticable {
  /// A scheme of [corners], [stroke] and [depth].
  const RawShapeScheme({
    this.corners = const RawCornerScale(),
    this.stroke,
    this.depth,
  }) : assert(stroke == null || (stroke >= 0 && stroke < double.infinity)),
       assert(depth == null || (depth >= 0 && depth < double.infinity));

  const RawShapeScheme._raw(this.corners, this.stroke, this.depth);

  /// The look's corner steps.
  final RawCornerScale corners;

  /// The weight, in logical pixels, the look's lines derive from (a hairline
  /// stays a hairline); null when the look opens none.
  final double? stroke;

  /// The look's relief, offset or shadow as a multiple of its design (1);
  /// null when the look opens none. Colour and opacity stay the look's.
  final double? depth;

  /// A copy with the given values.
  RawShapeScheme copyWith({
    RawCornerScale? corners,
    double? stroke,
    double? depth,
  }) => RawShapeScheme(
    corners: corners ?? this.corners,
    stroke: stroke ?? this.stroke,
    depth: depth ?? this.depth,
  );

  /// Between [a] and [b]. A value opened on one side only switches halfway.
  static RawShapeScheme lerp(RawShapeScheme a, RawShapeScheme b, double t) {
    if (identical(a, b)) return a;
    double? open(double? x, double? y) =>
        x != null && y != null ? lerpDouble(x, y, t) : (t < 0.5 ? x : y);
    return RawShapeScheme._raw(
      RawCornerScale.lerp(a.corners, b.corners, t),
      open(a.stroke, b.stroke),
      open(a.depth, b.depth),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RawShapeScheme &&
          other.corners == corners &&
          other.stroke == stroke &&
          other.depth == depth;

  @override
  int get hashCode => Object.hash(corners, stroke, depth);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<RawCornerScale>('corners', corners))
      ..add(DoubleProperty('stroke', stroke, defaultValue: null))
      ..add(DoubleProperty('depth', depth, defaultValue: null));
  }
}

/// The values a look allows one of its shape constants: [min] to [max],
/// one value when [isFixed].
///
/// ```dart
/// const RawBand(10, 20).clamp(40)
/// ```
@immutable
class RawBand {
  /// From [min] to [max].
  const RawBand(this.min, this.max) : assert(min >= 0), assert(min <= max);

  /// [value] alone: a constant the look keeps on its scheme, not open.
  const RawBand.fixed(double value) : this(value, value);

  /// Any length: a step the look leaves free.
  static const RawBand any = RawBand(0, double.infinity);

  /// The least value.
  final double min;

  /// The most.
  final double max;

  /// Whether the band holds one value.
  bool get isFixed => min == max;

  /// Whether [value] is in the band.
  bool contains(double value) => value >= min && value <= max;

  /// [value] held to the band.
  double clamp(double value) => value.clamp(min, max).toDouble();

  @override
  bool operator ==(Object other) =>
      other is RawBand && other.min == min && other.max == max;

  @override
  int get hashCode => Object.hash(min, max);

  @override
  String toString() => isFixed
      ? 'RawBand.fixed(${_number(min)})'
      : 'RawBand(${_number(min)}, ${_number(max)})';
}

String _number(double v) =>
    v.isFinite && v == v.roundToDouble() ? '${v.round()}' : '$v';

// Corner styles that stand in for each other, nearest first.
const List<List<RawCornerStyle>> _kin = [
  [RawCornerStyle.round, RawCornerStyle.continuous],
  [RawCornerStyle.bevel, RawCornerStyle.notch, RawCornerStyle.step],
  [RawCornerStyle.concave],
];

/// How far a look lets an app's per-part corners ([RawCorners]) go: the
/// part's own corners, one step on every corner, or a step per corner.
enum RawCornerFreedom {
  /// The part's own corners: an override is ignored, and debug says so.
  fixed,

  /// One step on every corner: an override is taken when, over the part's
  /// own corners, all four take one step (every corner given, or a partial
  /// one that leaves the four equal); one that leaves them differing is
  /// ignored, and debug says so.
  uniform,

  /// A step per corner: each corner given is taken.
  perCorner,
}

/// The bands a look holds its [RawShapeScheme] to: the corner [styles] it
/// allows (the first its default), a band per corner step, and bands for the
/// stroke and depth it opens (null: not opened). One const per look, the
/// code twin of the table in its theme's docs. How far an app's per-part
/// corners go is its [cornerFreedom] and [cornerSteps], held by
/// [clampCorners].
///
/// A look holds every scheme it is given to its bands ([clamp]) where its
/// theme data takes it, in debug and release alike: a value from an app's
/// settings shows the same on a developer's phone as in production. A lerp
/// between two held schemes is not held again, so a spring may pass a band's
/// end for a moment.
///
/// ```dart
/// const RawShapeLimits(medium: RawBand(10, 20), stroke: RawBand(1, 3)).clamp(const RawShapeScheme(corners: RawCornerScale(medium: 40), stroke: 2))
/// ```
@immutable
class RawShapeLimits with Diagnosticable {
  /// Bands for a look's scheme.
  const RawShapeLimits({
    this.styles = const {RawCornerStyle.round},
    this.extraSmall = RawBand.any,
    this.small = RawBand.any,
    this.medium = RawBand.any,
    this.large = RawBand.any,
    this.extraLarge = RawBand.any,
    this.fullMaxRadius,
    this.stroke,
    this.depth,
    this.cornerFreedom = RawCornerFreedom.fixed,
    this.cornerSteps,
  });

  /// The corner styles the look allows, its default first; one: fixed.
  final Set<RawCornerStyle> styles;

  /// [RawCornerScale.extraSmall]'s band.
  final RawBand extraSmall;

  /// [RawCornerScale.small]'s band.
  final RawBand small;

  /// [RawCornerScale.medium]'s band.
  final RawBand medium;

  /// [RawCornerScale.large]'s band.
  final RawBand large;

  /// [RawCornerScale.extraLarge]'s band.
  final RawBand extraLarge;

  /// [RawCornerScale.fullMaxRadius]'s band, when the scheme gives one; null
  /// leaves it as given.
  final RawBand? fullMaxRadius;

  /// [RawShapeScheme.stroke]'s band; null: the look opens no stroke, and a
  /// stroke given is dropped.
  final RawBand? stroke;

  /// [RawShapeScheme.depth]'s band; null: the look opens no depth, and a
  /// depth given is dropped.
  final RawBand? depth;

  /// How far an app's per-part corners go ([clampCorners]): fixed, the
  /// default, so a look opens them on purpose.
  final RawCornerFreedom cornerFreedom;

  /// The steps an app's per-part corner may take; null, every step. A step
  /// outside them goes to the nearest ([nearestStep]).
  final Set<RawCorner>? cornerSteps;

  /// The allowed step nearest [step]: [step] itself when [cornerSteps]
  /// allows it (or is null), else the nearest in step order (none, extra
  /// small … extra large, full), the larger on a tie.
  RawCorner nearestStep(RawCorner step) {
    final allowed = cornerSteps;
    assert(allowed == null || allowed.isNotEmpty, 'cornerSteps allows none');
    if (allowed == null || allowed.contains(step)) return step;
    RawCorner? best;
    for (final s in allowed) {
      if (best == null) {
        best = s;
        continue;
      }
      final d = (s.index - step.index).abs(),
          b = (best.index - step.index).abs();
      if (d < b || (d == b && s.index > best.index)) best = s;
    }
    return best!;
  }

  /// The corners a part draws: [override] (an app's, from the part's style)
  /// over [base] (the part's own), as [cornerFreedom] allows, each step
  /// given held to [cornerSteps]. The steps resolve through the look's held
  /// [RawCornerScale] ([RawCornerScale.borderOf]), so every corner lies in
  /// its step's band. In debug, an override ignored, or a step moved, is
  /// printed once per look and what changed, [look] naming whose limits.
  ///
  /// ```dart
  /// const RawShapeLimits(cornerFreedom: RawCornerFreedom.perCorner).clampCorners(const RawCorners(topEnd: RawCorner.none, bottomStart: RawCorner.none), base: const RawCorners.all(RawCorner.medium))
  /// ```
  RawCorners clampCorners(
    RawCorners? override, {
    required RawCorners base,
    String? look,
  }) {
    final (held, notes) = _corners(override, base);
    assert(() {
      final name = look ?? 'The look';
      for (final (what, line) in notes) {
        if (_reported.add('$name $what')) debugPrint('$name $line.');
      }
      return true;
    }());
    return held;
  }

  // What [clampCorners] gives, and what it tells, each with what it is.
  (RawCorners, List<(String, String)>) _corners(
    RawCorners? override,
    RawCorners base,
  ) {
    if (override == null || override.isEmpty) return (base, const []);
    final notes = <(String, String)>[];
    RawCorner? step(RawCorner? given) {
      if (given == null) return null;
      final to = nearestStep(given);
      if (to != given) {
        notes.add((
          'corner ${given.name}',
          'holds corner ${given.name} to ${to.name}, the nearest step it '
              'allows',
        ));
      }
      return to;
    }

    switch (cornerFreedom) {
      case RawCornerFreedom.fixed:
        if (override.over(base) == base) return (base, const []);
        return (
          base,
          const [
            (
              'corners fixed',
              'ignores a corners override: its corners are fixed',
            ),
          ],
        );
      case RawCornerFreedom.uniform:
        final resolved = override.over(base);
        if (!resolved.isUniform) {
          return (
            base,
            const [
              (
                'corners mixed',
                'ignores a corners override whose corners differ: it takes '
                    'one step on every corner',
              ),
            ],
          );
        }
        final agreed = resolved._all.nonNulls.firstOrNull;
        if (agreed == null || resolved == base) return (base, const []);
        return (RawCorners.all(step(agreed)!), notes);
      case RawCornerFreedom.perCorner:
        return (
          RawCorners(
            topStart: step(override.topStart),
            topEnd: step(override.topEnd),
            bottomStart: step(override.bottomStart),
            bottomEnd: step(override.bottomEnd),
          ).over(base),
          notes,
        );
    }
  }

  /// The allowed style nearest [style]: [style] itself when allowed, else
  /// the first allowed of its kin (round and continuous; bevel, notch and
  /// step), else the look's default.
  RawCornerStyle nearestStyle(RawCornerStyle style) {
    assert(styles.isNotEmpty, 'a look allows at least one corner style');
    if (styles.contains(style)) return style;
    for (final kin in _kin) {
      if (!kin.contains(style)) continue;
      for (final s in kin) {
        if (styles.contains(s)) return s;
      }
    }
    return styles.first;
  }

  /// [scheme] held to these bands: each value to its band's nearer end, the
  /// style to [nearestStyle]. In debug, what changed is printed once per
  /// look, value and band end (a slider dragged past a band prints one
  /// line), [look] naming whose bands they are.
  RawShapeScheme clamp(RawShapeScheme scheme, {String? look}) {
    final c = scheme.corners;
    final held = RawShapeScheme(
      corners: RawCornerScale(
        style: nearestStyle(c.style),
        extraSmall: extraSmall.clamp(math.max(c.extraSmall, 0)),
        small: small.clamp(math.max(c.small, 0)),
        medium: medium.clamp(math.max(c.medium, 0)),
        large: large.clamp(math.max(c.large, 0)),
        extraLarge: extraLarge.clamp(math.max(c.extraLarge, 0)),
        fullMaxRadius: c.fullMaxRadius == null || fullMaxRadius == null
            ? c.fullMaxRadius
            : fullMaxRadius!.clamp(c.fullMaxRadius!),
      ),
      stroke: stroke == null || scheme.stroke == null
          ? null
          : stroke!.clamp(math.max(scheme.stroke!, 0)),
      depth: depth == null || scheme.depth == null
          ? null
          : depth!.clamp(math.max(scheme.depth!, 0)),
    );
    assert(() {
      // Once per look, value and end: a slider dragged past a band prints
      // one line, not one per frame.
      for (final (what, change) in _changes(scheme)) {
        final name = look ?? 'The look';
        if (_reported.add('$name $what')) debugPrint('$name holds $change.');
      }
      return true;
    }());
    return held;
  }

  static final Set<String> _reported = {};

  /// What [clamp] changes in [scheme], one line each ("medium 40 to 20, the
  /// band's most").
  List<String> debugDescribeClamps(RawShapeScheme scheme) => [
    for (final (_, change) in _changes(scheme)) change,
  ];

  // What [clamp] changes, each with what it is (the value and the band's
  // end), the same however far past it.
  List<(String, String)> _changes(RawShapeScheme scheme) {
    final c = scheme.corners;
    final out = <(String, String)>[];
    void held(String name, double value, RawBand band) {
      if (band.contains(value)) return;
      final to = band.clamp(value);
      final end = to == band.max ? 'most' : 'least';
      out.add((
        '$name $end',
        '$name ${_number(value)} to ${_number(to)}, the band\'s $end',
      ));
    }

    final style = nearestStyle(c.style);
    if (style != c.style) {
      out.add((
        'style ${c.style.name}',
        'style ${c.style.name} to ${style.name}',
      ));
    }
    held('extraSmall', c.extraSmall, extraSmall);
    held('small', c.small, small);
    held('medium', c.medium, medium);
    held('large', c.large, large);
    held('extraLarge', c.extraLarge, extraLarge);
    if (c.fullMaxRadius != null && fullMaxRadius != null) {
      held('fullMaxRadius', c.fullMaxRadius!, fullMaxRadius!);
    }
    for (final (name, value, band) in [
      ('stroke', scheme.stroke, stroke),
      ('depth', scheme.depth, depth),
    ]) {
      if (value == null) continue;
      if (band == null) {
        out.add((
          '$name dropped',
          '$name ${_number(value)}: not opened, dropped',
        ));
      } else {
        held(name, value, band);
      }
    }
    return out;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RawShapeLimits &&
          setEquals(other.styles, styles) &&
          other.extraSmall == extraSmall &&
          other.small == small &&
          other.medium == medium &&
          other.large == large &&
          other.extraLarge == extraLarge &&
          other.fullMaxRadius == fullMaxRadius &&
          other.stroke == stroke &&
          other.depth == depth &&
          other.cornerFreedom == cornerFreedom &&
          setEquals(other.cornerSteps, cornerSteps);

  @override
  int get hashCode => Object.hash(
    Object.hashAllUnordered(styles),
    extraSmall,
    small,
    medium,
    large,
    extraLarge,
    fullMaxRadius,
    stroke,
    depth,
    cornerFreedom,
    cornerSteps == null ? null : Object.hashAllUnordered(cornerSteps!),
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<RawCornerStyle>('styles', styles))
      ..add(DiagnosticsProperty<RawBand>('extraSmall', extraSmall))
      ..add(DiagnosticsProperty<RawBand>('small', small))
      ..add(DiagnosticsProperty<RawBand>('medium', medium))
      ..add(DiagnosticsProperty<RawBand>('large', large))
      ..add(DiagnosticsProperty<RawBand>('extraLarge', extraLarge))
      ..add(
        DiagnosticsProperty<RawBand>(
          'fullMaxRadius',
          fullMaxRadius,
          defaultValue: null,
        ),
      )
      ..add(DiagnosticsProperty<RawBand>('stroke', stroke, defaultValue: null))
      ..add(DiagnosticsProperty<RawBand>('depth', depth, defaultValue: null))
      ..add(
        EnumProperty<RawCornerFreedom>(
          'cornerFreedom',
          cornerFreedom,
          defaultValue: RawCornerFreedom.fixed,
        ),
      )
      ..add(
        IterableProperty<RawCorner>(
          'cornerSteps',
          cornerSteps,
          defaultValue: null,
        ),
      );
  }
}
