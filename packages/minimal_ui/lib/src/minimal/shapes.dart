/// Minimal's corner scale: one radius, and the shape each role of part draws
/// from it, as Flutter's own `OutlinedBorder`s.
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

/// The corner scale every framed part reads, on `MinimalThemeData.shapes`:
/// one [radius], as a shadcn theme sets one `--radius` and derives the rest.
///
/// | step | from [radius] | at 8 | parts |
/// |---|---|---|---|
/// | [mark] | 4 px squarer | 4 | a checkbox's box, a tag, a status label, a key cap, a segment's plate |
/// | [small] | [radius] | 8 | buttons, fields, selects, the segmented track, steppers, picker cells, a button group |
/// | [medium] | 2 px rounder | 10 | cards, list sections, menus, the snack bar, banners, the command palette |
/// | [large] | 6 px rounder | 14 | dialogs and bottom sheets |
/// | [pill] | a capsule | | chips, a switch's track, progress and slider tracks, count badges, page dots |
///
/// `MinimalShapes(radius: 0)` squares every step, the capsules too. A part
/// inside another takes its frame's shape [inset] by the gap between them,
/// so the two stay concentric. What is round by meaning stays round whatever
/// the scale: a radio, a slider's thumb, an avatar, a status dot and a
/// step's marker. One part's own corners are its component theme's `shape`.
///
/// ```dart
/// final softer = MinimalThemeData.standard().copyWith(
///   shapes: const MinimalShapes(radius: 12),
/// );
/// ```
@immutable
class MinimalShapes with Diagnosticable {
  /// The scale from [radius]; 8 is the look's own.
  const MinimalShapes({this.radius = 8}) : assert(radius >= 0);

  /// The look's own scale: 4, 8, 10 and 14 px corners.
  static const MinimalShapes look = MinimalShapes();

  /// The one radius the steps derive from: [small]'s.
  final double radius;

  static OutlinedBorder _at(double r) => RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(math.max(0, r))),
  );

  /// A checkbox's box, a tag, a key cap, a segment's plate.
  OutlinedBorder get mark => _at(radius - 4);

  /// Buttons, fields, selects, the segmented track, chips and steppers.
  OutlinedBorder get small => _at(radius);

  /// Cards, list sections, menus, the snack bar and the command palette.
  OutlinedBorder get medium => radius == 0 ? _at(0) : _at(radius + 2);

  /// Dialogs and bottom sheets.
  OutlinedBorder get large => radius == 0 ? _at(0) : _at(radius + 6);

  /// What a capsule role draws on this scale — a switch's track, a progress
  /// bar, a slider's track, a count badge, a chip, page dots: a capsule,
  /// square at a radius of 0.
  OutlinedBorder get pill => radius == 0 ? _at(0) : const StadiumBorder();

  /// The corner radius [shape] draws, for a part that paints a
  /// `BorderRadius` rather than a shape: a rounded rectangle's (and a
  /// bevel's, a squircle's) top-start corner, a capsule's or a circle's
  /// [fullRadius], 0 for any other shape.
  static double radiusOf(ShapeBorder? shape) => switch (shape) {
    RoundedRectangleBorder(:final borderRadius) ||
    BeveledRectangleBorder(:final borderRadius) ||
    ContinuousRectangleBorder(:final borderRadius) ||
    RoundedSuperellipseBorder(
      :final borderRadius,
    ) => borderRadius.resolve(TextDirection.ltr).topLeft.x,
    StadiumBorder() || CircleBorder() => fullRadius,
    _ => 0,
  };

  /// A radius that rounds any part's ends fully: what [radiusOf] says for a
  /// capsule or a circle.
  static const double fullRadius = 999;

  /// [shape] drawn [inset] px inside another, for a plate that sits within a
  /// frame (a segment in its track, a thumb in its slot): its corners
  /// shrink by [inset], never below 0, so the two stay concentric. A
  /// capsule, a circle or a shape this does not know comes back as given.
  static OutlinedBorder inset(OutlinedBorder shape, double inset) {
    BorderRadiusGeometry less(BorderRadiusGeometry r) {
      final c = r.resolve(TextDirection.ltr);
      Radius s(Radius x) =>
          Radius.elliptical(math.max(0, x.x - inset), math.max(0, x.y - inset));
      return BorderRadius.only(
        topLeft: s(c.topLeft),
        topRight: s(c.topRight),
        bottomLeft: s(c.bottomLeft),
        bottomRight: s(c.bottomRight),
      );
    }

    return switch (shape) {
      final RoundedRectangleBorder s => s.copyWith(
        borderRadius: less(s.borderRadius),
      ),
      final BeveledRectangleBorder s => s.copyWith(
        borderRadius: less(s.borderRadius),
      ),
      final ContinuousRectangleBorder s => s.copyWith(
        borderRadius: less(s.borderRadius),
      ),
      final RoundedSuperellipseBorder s => s.copyWith(
        borderRadius: less(s.borderRadius),
      ),
      _ => shape,
    };
  }

  /// This at another [radius].
  MinimalShapes copyWith({double? radius}) =>
      MinimalShapes(radius: radius ?? this.radius);

  /// Between [a] and [b]: the radius eases.
  static MinimalShapes lerp(MinimalShapes a, MinimalShapes b, double t) =>
      identical(a, b)
      ? a
      : MinimalShapes(radius: a.radius + (b.radius - a.radius) * t);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MinimalShapes && other.radius == radius;

  @override
  int get hashCode => radius.hashCode;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DoubleProperty('radius', radius, defaultValue: 8));
  }
}
