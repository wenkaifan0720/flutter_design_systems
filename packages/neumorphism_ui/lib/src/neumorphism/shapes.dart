import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import 'theme.dart' show NeumorphicRadii;

/// Neumorphism's rounded family. A border also describes the inset needed to
/// keep a rectangular child inside its corners. Round marks use [fit] before
/// reading [dimensions], because Flutter's dimensions getter has no size.
///
/// ```dart
/// final border = const NeumorphicCircleBorder().fit(const Size.square(40));
/// final padding = border.dimensions;
/// ```
abstract class NeumorphicBorder extends OutlinedBorder {
  /// The printed edge, independent of the relief shadows.
  const NeumorphicBorder({super.side});

  RRect _outline(Rect rect);

  /// Resolves size-dependent insets. Rounded and capped stadium borders already
  /// have an upper bound; a circle's inset follows the square mark's diameter.
  NeumorphicBorder fit(Size size) => this;

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) =>
      Path()..addRRect(_outline(rect));

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      Path()..addRRect(_outline(rect).deflate(side.strokeInset));

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (side.style == BorderStyle.none || side.width == 0) return;
    canvas.drawRRect(
      _outline(rect).inflate(side.strokeOffset / 2),
      side.toPaint(),
    );
  }

  @override
  ShapeBorder? lerpFrom(ShapeBorder? a, double t) =>
      a is NeumorphicBorder ? _blend(a, this, t) : super.lerpFrom(a, t);

  @override
  ShapeBorder? lerpTo(ShapeBorder? b, double t) =>
      b is NeumorphicBorder ? _blend(this, b, t) : super.lerpTo(b, t);

  static NeumorphicBorder _blend(
    NeumorphicBorder a,
    NeumorphicBorder b,
    double t,
  ) {
    if (t == 0) return a;
    if (t == 1) return b;
    final side = BorderSide.lerp(a.side, b.side, t);
    if (a is NeumorphicRoundedBorder && b is NeumorphicRoundedBorder) {
      return NeumorphicRoundedBorder(
        radius: lerpDouble(a.radius, b.radius, t)!,
        side: side,
      );
    }
    if (a is NeumorphicStadiumBorder && b is NeumorphicStadiumBorder) {
      return NeumorphicStadiumBorder(
        maxRadius: lerpDouble(a.maxRadius, b.maxRadius, t)!,
        side: side,
      );
    }
    if (a is NeumorphicCircleBorder && b is NeumorphicCircleBorder) {
      return NeumorphicCircleBorder(
        diameter: lerpDouble(a.diameter, b.diameter, t)!,
        side: side,
      );
    }
    return _RoundedBlend(a, b, t, side);
  }
}

double _cut(double radius) => radius * (1 - math.sqrt(.5));

/// A rounded rectangle with a capped radius, for any content height.
///
/// ```dart
/// const NeumorphicRoundedBorder(radius: 20)
/// ```
class NeumorphicRoundedBorder extends NeumorphicBorder {
  /// Rounds each corner by [radius], capped at half the shortest side.
  const NeumorphicRoundedBorder({super.side, this.radius = 12})
    : assert(radius >= 0);

  /// The maximum corner radius in logical pixels.
  final double radius;

  @override
  EdgeInsetsGeometry get dimensions =>
      EdgeInsets.all(_cut(radius) + side.strokeInset);

  @override
  RRect _outline(Rect rect) => RRect.fromRectAndRadius(
    rect,
    Radius.circular(math.min(radius, rect.shortestSide / 2)),
  );

  @override
  NeumorphicRoundedBorder copyWith({BorderSide? side, double? radius}) =>
      NeumorphicRoundedBorder(
        side: side ?? this.side,
        radius: radius ?? this.radius,
      );

  @override
  NeumorphicRoundedBorder scale(double t) => NeumorphicRoundedBorder(
    side: side.scale(t),
    radius: radius * math.max(0, t),
  );

  @override
  bool operator ==(Object other) =>
      other is NeumorphicRoundedBorder &&
      other.side == side &&
      other.radius == radius;

  @override
  int get hashCode => Object.hash(side, radius);
}

/// A stadium for one-line content. Its radius stops growing at [maxRadius], so
/// large text cannot consume a short control's straight run.
///
/// ```dart
/// const NeumorphicStadiumBorder(maxRadius: 24)
/// ```
class NeumorphicStadiumBorder extends NeumorphicBorder {
  /// Caps the ends of a pill at [maxRadius].
  const NeumorphicStadiumBorder({super.side, this.maxRadius = 24})
    : assert(maxRadius >= 0);

  /// The greatest end radius; used to reserve the content's safe inset.
  final double maxRadius;

  @override
  EdgeInsetsGeometry get dimensions =>
      EdgeInsets.all(_cut(maxRadius) + side.strokeInset);

  @override
  RRect _outline(Rect rect) => RRect.fromRectAndRadius(
    rect,
    Radius.circular(math.min(maxRadius, rect.shortestSide / 2)),
  );

  @override
  NeumorphicStadiumBorder copyWith({BorderSide? side, double? maxRadius}) =>
      NeumorphicStadiumBorder(
        side: side ?? this.side,
        maxRadius: maxRadius ?? this.maxRadius,
      );

  @override
  NeumorphicStadiumBorder scale(double t) => NeumorphicStadiumBorder(
    side: side.scale(t),
    maxRadius: maxRadius * math.max(0, t),
  );

  @override
  bool operator ==(Object other) =>
      other is NeumorphicStadiumBorder &&
      other.side == side &&
      other.maxRadius == maxRadius;

  @override
  int get hashCode => Object.hash(side, maxRadius);
}

/// A circle for square marks only. Use [fit] with the final mark size before
/// adding [dimensions] to its content padding.
///
/// ```dart
/// const NeumorphicCircleBorder(diameter: 48)
/// ```
class NeumorphicCircleBorder extends NeumorphicBorder {
  /// Reserves the square safe area of a mark of [diameter].
  const NeumorphicCircleBorder({super.side, this.diameter = 48})
    : assert(diameter >= 0);

  /// The mark's layout diameter, used by [dimensions].
  final double diameter;

  @override
  EdgeInsetsGeometry get dimensions =>
      EdgeInsets.all(_cut(diameter / 2) + side.strokeInset);

  @override
  NeumorphicCircleBorder fit(Size size) =>
      copyWith(diameter: size.shortestSide);

  @override
  RRect _outline(Rect rect) => RRect.fromRectAndRadius(
    Rect.fromCircle(center: rect.center, radius: rect.shortestSide / 2),
    Radius.circular(rect.shortestSide / 2),
  );

  @override
  NeumorphicCircleBorder copyWith({BorderSide? side, double? diameter}) =>
      NeumorphicCircleBorder(
        side: side ?? this.side,
        diameter: diameter ?? this.diameter,
      );

  @override
  NeumorphicCircleBorder scale(double t) => NeumorphicCircleBorder(
    side: side.scale(t),
    diameter: diameter * math.max(0, t),
  );

  @override
  bool operator ==(Object other) =>
      other is NeumorphicCircleBorder &&
      other.side == side &&
      other.diameter == diameter;

  @override
  int get hashCode => Object.hash(side, diameter);
}

class _RoundedBlend extends NeumorphicBorder {
  const _RoundedBlend(this.a, this.b, this.t, BorderSide side)
    : super(side: side);
  final NeumorphicBorder a, b;
  final double t;

  @override
  RRect _outline(Rect rect) =>
      RRect.lerp(a._outline(rect), b._outline(rect), t)!;

  @override
  EdgeInsetsGeometry get dimensions =>
      EdgeInsetsGeometry.lerp(a.dimensions, b.dimensions, t)!;

  @override
  NeumorphicBorder fit(Size size) =>
      _RoundedBlend(a.fit(size), b.fit(size), t, side);

  @override
  NeumorphicBorder copyWith({BorderSide? side}) =>
      _RoundedBlend(a, b, t, side ?? this.side);

  @override
  ShapeBorder scale(double factor) => _RoundedBlend(
    a.scale(factor) as NeumorphicBorder,
    b.scale(factor) as NeumorphicBorder,
    t,
    side.scale(factor),
  );

  @override
  bool operator ==(Object other) =>
      other is _RoundedBlend &&
      other.a == a &&
      other.b == b &&
      other.t == t &&
      other.side == side;

  @override
  int get hashCode => Object.hash(a, b, t, side);
}

/// One cell of a bank of cells: the bank's own outline, [frame] inside it, clipped to the cell's rectangle. Where the
/// cell meets the bank's edge its corners are the bank's corners moved in by [frame], around the same centres; where it
/// meets a neighbour it is square. [reach] is how far the bank runs past the cell on each side, so the outline is
/// worked out from the cell's own rectangle and stays concentric when it is moved in or out
/// (`NeumorphicShapes.inset`, `NeumorphicShapes.outset`).
///
/// ```dart
/// // The middle of three equal cells, 100 wide, in a 300 x 48 capsule bank.
/// NeumorphicCellBorder(
///   bank: const NeumorphicStadiumBorder(),
///   reach: const EdgeInsets.only(left: 100, right: 100),
/// )
/// ```
class NeumorphicCellBorder extends OutlinedBorder {
  /// A cell of a bank shaped by [bank], which runs [reach] past the cell on each side.
  const NeumorphicCellBorder({
    super.side,
    required this.bank,
    this.reach = EdgeInsets.zero,
    this.frame = 0,
    this.joins = 0,
  }) : assert(frame >= 0),
       assert(joins >= 0);

  /// The whole bank's outline.
  final OutlinedBorder bank;

  /// How far the bank's rectangle runs past the cell's, side by side.
  final EdgeInsets reach;

  /// How far inside the bank's outline the cell's face starts: the width of the bank's rim.
  final double frame;

  /// The bank's rectangle around a cell drawn in [rect].
  Rect bankRect(Rect rect) => Rect.fromLTRB(
    rect.left - reach.left,
    rect.top - reach.top,
    rect.right + reach.right,
    rect.bottom + reach.bottom,
  );

  /// The round of the corners where the cell meets a neighbour: 0 leaves them square, for a cell drawn flush with the
  /// next one; a cell that sinks on its own (a pressed row, a chosen cell) rounds them by the least corner.
  final double joins;

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(side.strokeInset);

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    final outline = bankRect(rect).deflate(frame);
    final Path cut;
    if (joins <= 0) {
      cut = Path()..addRect(rect);
    } else {
      // Where the bank runs on past the cell, the cell's own edge, rounded; where the cell is on the bank's edge, the
      // bank's, whose own corner is the rounder.
      cut = Path()
        ..addRRect(
          RRect.fromLTRBR(
            reach.left > frame ? rect.left : outline.left,
            reach.top > frame ? rect.top : outline.top,
            reach.right > frame ? rect.right : outline.right,
            reach.bottom > frame ? rect.bottom : outline.bottom,
            Radius.circular(joins),
          ),
        );
    }
    return Path.combine(
      PathOperation.intersect,
      NeumorphicShapes.inset(
        bank,
        frame,
      ).getOuterPath(outline, textDirection: textDirection),
      cut,
    );
  }

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) => inset(
    side.strokeInset,
  ).getOuterPath(rect.deflate(side.strokeInset), textDirection: textDirection);

  /// This cell moved [by] inward (outward when negative), around the same corner centres.
  NeumorphicCellBorder inset(double by) =>
      copyWith(bank: NeumorphicShapes.inset(bank, by));

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (side.style == BorderStyle.none || side.width == 0) return;
    final half = side.strokeInset - side.width / 2;
    canvas.drawPath(
      inset(half)
          .getOuterPath(rect.deflate(half), textDirection: textDirection),
      side.toPaint(),
    );
  }

  @override
  NeumorphicCellBorder copyWith({
    BorderSide? side,
    OutlinedBorder? bank,
    EdgeInsets? reach,
    double? frame,
    double? joins,
  }) => NeumorphicCellBorder(
    side: side ?? this.side,
    bank: bank ?? this.bank,
    reach: reach ?? this.reach,
    frame: frame ?? this.frame,
    joins: joins ?? this.joins,
  );

  @override
  NeumorphicCellBorder scale(double t) => NeumorphicCellBorder(
    side: side.scale(t),
    bank: bank.scale(t) as OutlinedBorder,
    reach: reach * t,
    frame: frame * t,
    joins: joins * t,
  );

  @override
  ShapeBorder? lerpFrom(ShapeBorder? a, double t) => a is NeumorphicCellBorder
      ? NeumorphicCellBorder(
          side: BorderSide.lerp(a.side, side, t),
          bank: OutlinedBorder.lerp(a.bank, bank, t)!,
          reach: EdgeInsets.lerp(a.reach, reach, t)!,
          frame: lerpDouble(a.frame, frame, t)!,
          joins: lerpDouble(a.joins, joins, t)!,
        )
      : super.lerpFrom(a, t);

  @override
  ShapeBorder? lerpTo(ShapeBorder? b, double t) =>
      b is NeumorphicCellBorder ? b.lerpFrom(this, t) : super.lerpTo(b, t);

  @override
  bool operator ==(Object other) =>
      other is NeumorphicCellBorder &&
      other.side == side &&
      other.bank == bank &&
      other.reach == reach &&
      other.frame == frame &&
      other.joins == joins;

  @override
  int get hashCode => Object.hash(side, bank, reach, frame, joins);
}

/// The look's moulded corners, what every part is cut from. Not a setting: a component theme sets one part's shape, and
/// the corners themselves are the look.
@immutable
class NeumorphicShapes {
  /// The look's corners.
  const NeumorphicShapes();

  /// A frame at [step].
  NeumorphicRoundedBorder corner(double step) =>
      NeumorphicRoundedBorder(radius: step);

  /// A one-line track, chip or badge, capped for enlarged text.
  OutlinedBorder get capsule => const NeumorphicStadiumBorder(maxRadius: 24);

  /// A semantic circle: radio, avatar, round key or moving thumb.
  NeumorphicCircleBorder circle([double diameter = 48]) =>
      NeumorphicCircleBorder(diameter: diameter);

  /// A concentric outer ring around [border], [gap] outside it: its radius is the shape's radius plus [gap], around
  /// the same corner centres. A square corner stays square in its ring.
  static OutlinedBorder outset(OutlinedBorder border, double gap) =>
      inset(border, -gap);

  /// A concentric inner face, whose radius is the outer radius minus [inset] around the same centres, never below
  /// the look's least corner ([NeumorphicRadii.least]): moulded plaster has no sharp corner. A corner a theme made
  /// square stays square, inside or out.
  static OutlinedBorder inset(OutlinedBorder border, double inset) {
    if (border is NeumorphicCellBorder) return border.inset(inset);
    if (border is NeumorphicRoundedBorder) {
      return border.radius == 0
          ? border
          : border.copyWith(radius: _least(border.radius, inset));
    }
    if (border is NeumorphicStadiumBorder) {
      return border.maxRadius == 0
          ? border
          : border.copyWith(maxRadius: _least(border.maxRadius, inset));
    }
    if (border is NeumorphicCircleBorder) {
      return border.copyWith(
        diameter: math.max(0, border.diameter - 2 * inset),
      );
    }
    if (border is RoundedRectangleBorder) {
      // Corner by corner: a square corner stays square, a rounded one moves by [inset] around its centre.
      final r = border.borderRadius.resolve(TextDirection.ltr);
      Radius move(Radius x) => x == Radius.zero
          ? x
          : Radius.elliptical(_least(x.x, inset), _least(x.y, inset));
      return border.copyWith(
        borderRadius: BorderRadius.only(
          topLeft: move(r.topLeft),
          topRight: move(r.topRight),
          bottomLeft: move(r.bottomLeft),
          bottomRight: move(r.bottomRight),
        ),
      );
    }
    return border;
  }

  /// [radius] moved in by [inset], held at the least corner (or at [radius] itself, if that was smaller). Moved out,
  /// it simply grows.
  static double _least(double radius, double inset) => inset <= 0
      ? radius - inset
      : math.max(radius - inset, math.min(radius, NeumorphicRadii.least));
}
