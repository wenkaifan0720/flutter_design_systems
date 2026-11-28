/// Minimal's corner scale: one radius, and the shape each role of part draws
/// from it, as Flutter's own `OutlinedBorder`s.
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:ui_core/ui_core.dart';

/// The corner scale every framed part reads, on `MinimalThemeData.shapes`:
/// the theme's [RawShapeScheme] (`MinimalThemeData.shapeScheme`) as the
/// outline each role of part draws.
///
/// | step | scheme step | default | band | parts |
/// |---|---|---|---|---|
/// | [mark] | extraSmall | 4 | 0–8 | a checkbox's box, a tag, a status label, a key cap, a segment's plate |
/// | [small] | small | 8 | 0–12 | buttons, fields, selects, the segmented track, steppers, picker cells, a button group |
/// | [medium] | medium | 10 | 0–14 | cards, list sections, menus, the snack bar, banners, the command palette |
/// | [large] | large | 14 | 0–20 | dialogs and bottom sheets |
/// | [pill] | full | a capsule | | chips, a switch's track, progress and slider tracks, count badges, page dots |
///
/// The extra large step (18, 0–24) is drawn only where a part's style names
/// it in its own corners. A scheme whose small step is 0 squares every role,
/// the capsules too. A part inside another takes its frame's shape [inset]
/// by the gap between them, so the two stay concentric. What is round by
/// meaning stays round whatever the scale: a radio, a slider's thumb, an
/// avatar, a status dot and a step's marker. One part's own corners are its
/// style's `corners` (or its whole outline, its `shape`).
///
/// `MinimalShapes(radius: r)` is the one-knob way to a scheme, every step
/// from one radius as Minimal draws them ([scheme]):
///
/// ```dart
/// final softer = MinimalThemeData.standard().copyWith(
///   shapeScheme: const MinimalShapes(radius: 12).scheme,
/// );
/// ```
@immutable
class MinimalShapes with Diagnosticable {
  /// The scale from [radius]; 8 is the look's own.
  const MinimalShapes({this.radius = 8}) : assert(radius >= 0), _corners = null;

  /// The scale [scheme] draws: what `MinimalThemeData.shapes` reads.
  MinimalShapes.of(RawShapeScheme scheme)
    : radius = scheme.corners.small,
      _corners = scheme.corners;

  /// The look's own scale: 4, 8, 10 and 14 px corners.
  static const MinimalShapes look = MinimalShapes();

  /// The small step's radius, which the others derive from in
  /// `MinimalShapes(radius:)`.
  final double radius;

  final RawCornerScale? _corners;

  /// The steps: a scheme's as given, else each from [radius] (the mark 4 px
  /// squarer, medium 2 px rounder, large 6, extra large 10; all square at 0).
  RawCornerScale get corners =>
      _corners ??
      (radius == 0
          ? const RawCornerScale(
              extraSmall: 0,
              small: 0,
              medium: 0,
              large: 0,
              extraLarge: 0,
            )
          : RawCornerScale(
              extraSmall: math.max(0, radius - 4),
              small: radius,
              medium: radius + 2,
              large: radius + 6,
              extraLarge: radius + 10,
            ));

  /// The scheme these steps make, for `MinimalThemeData.shapeScheme`; the
  /// theme holds it to its bands.
  RawShapeScheme get scheme => RawShapeScheme(corners: corners);

  static OutlinedBorder _at(double r) => RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(math.max(0, r))),
  );

  /// A checkbox's box, a tag, a key cap, a segment's plate.
  OutlinedBorder get mark => _at(corners.extraSmall);

  /// Buttons, fields, selects, the segmented track, chips and steppers.
  OutlinedBorder get small => _at(corners.small);

  /// Cards, list sections, menus, the snack bar and the command palette.
  OutlinedBorder get medium => _at(corners.medium);

  /// Dialogs and bottom sheets.
  OutlinedBorder get large => _at(corners.large);

  /// Whether the capsules square: the small step is 0.
  bool get square => corners.small == 0;

  /// What a capsule role draws on this scale — a switch's track, a progress
  /// bar, a slider's track, a count badge, a chip, page dots: a capsule,
  /// square when the small step is 0.
  OutlinedBorder get pill => square ? _at(0) : const StadiumBorder();

  /// The outline [step] draws as a role's own: [pill] at full, square at
  /// none.
  OutlinedBorder at(RawCorner step) => switch (step) {
    RawCorner.none => _at(0),
    RawCorner.extraSmall => mark,
    RawCorner.small => small,
    RawCorner.medium => medium,
    RawCorner.large => large,
    RawCorner.extraLarge => _at(corners.extraLarge),
    RawCorner.full => pill,
  };

  /// The corner radius [shape] draws, for a part that paints a
  /// `BorderRadius` rather than a shape: a rounded rectangle's (and a
  /// bevel's, a squircle's, a part's own corners') top-start corner, a
  /// capsule's or a circle's [fullRadius], 0 for any other shape.
  static double radiusOf(ShapeBorder? shape) => switch (shape) {
    RoundedRectangleBorder(:final borderRadius) ||
    BeveledRectangleBorder(:final borderRadius) ||
    ContinuousRectangleBorder(:final borderRadius) ||
    RoundedSuperellipseBorder(:final borderRadius) ||
    RawCornerBorder(
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
  /// capsule, a circle or a shape this does not know comes back as given; a
  /// part's own corners ([RawCornerBorder]) shrink each corner, a capsule end
  /// staying round.
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
      final RawCornerBorder s => s.inset(EdgeInsets.all(inset)),
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

  /// This at another [radius] (a scale from one radius).
  MinimalShapes copyWith({double? radius}) =>
      MinimalShapes(radius: radius ?? this.radius);

  /// Between [a] and [b]: every step eases.
  static MinimalShapes lerp(MinimalShapes a, MinimalShapes b, double t) {
    if (identical(a, b)) return a;
    if (a._corners == null && b._corners == null) {
      return MinimalShapes(radius: a.radius + (b.radius - a.radius) * t);
    }
    return MinimalShapes.of(RawShapeScheme.lerp(a.scheme, b.scheme, t));
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MinimalShapes && other.corners == corners;

  @override
  int get hashCode => corners.hashCode;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DoubleProperty('radius', radius, defaultValue: 8))
      ..add(
        DiagnosticsProperty<RawCornerScale>(
          'corners',
          _corners,
          defaultValue: null,
        ),
      );
  }
}
