/// Conventional Flutter borders on Comic's corner scale.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:ui_core/ui_core.dart' show RawShapeScheme;

/// The outlines Comic's parts draw, read from a theme's `shapeScheme` ([ComicShapes.of]): an app sets the scheme,
/// and these follow it.
///
/// Buttons and fields use [small], cards and menus use [medium], and dialogs
/// and sheets use [large]. [capsule], the scheme's extra small step, is for
/// chips, tags, switches, segmented choices and tracks; [full] stays round for
/// identity and circular interaction affordances. Comic's own are square.
///
/// ```dart
/// ComicTheme.of(context).shapes.medium
/// ```
@immutable
class ComicShapes with Diagnosticable {
  /// Creates the scale with conventional square controls and surfaces.
  const ComicShapes({
    this.small = const RoundedRectangleBorder(),
    this.medium = const RoundedRectangleBorder(),
    this.large = const RoundedRectangleBorder(),
    this.capsule = const RoundedRectangleBorder(),
    this.full = const StadiumBorder(),
  });

  /// The outlines [scheme]'s corners draw: its small, medium and large steps, its extra small step as [capsule], and
  /// [full] always a stadium.
  factory ComicShapes.of(RawShapeScheme scheme) {
    final c = scheme.corners;
    OutlinedBorder at(double r) => r <= 0
        ? const RoundedRectangleBorder()
        : RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(r)),
          );
    return ComicShapes(
      small: at(c.small),
      medium: at(c.medium),
      large: at(c.large),
      capsule: at(c.extraSmall),
    );
  }

  /// The corner for buttons, fields and compact rectangular marks.
  final OutlinedBorder small;

  /// The corner for cards, menus, snack bars and tooltips.
  final OutlinedBorder medium;

  /// The corner for dialogs and sheets.
  final OutlinedBorder large;

  /// Square in the square family; a capsule in the rounded family.
  /// Used by chips, badges, switches, segmented choices and progress tracks.
  final OutlinedBorder capsule;

  /// The capsule for round affordances; square bounds produce a circle.
  final OutlinedBorder full;

  /// This with the named levels replaced.
  ComicShapes copyWith({
    OutlinedBorder? small,
    OutlinedBorder? medium,
    OutlinedBorder? large,
    OutlinedBorder? capsule,
    OutlinedBorder? full,
  }) => ComicShapes(
    small: small ?? this.small,
    medium: medium ?? this.medium,
    large: large ?? this.large,
    capsule: capsule ?? this.capsule,
    full: full ?? this.full,
  );

  /// Interpolates the scale using Flutter's border interpolation.
  static ComicShapes lerp(ComicShapes a, ComicShapes b, double t) {
    if (t == 0) return a;
    if (t == 1) return b;
    return ComicShapes(
      small: OutlinedBorder.lerp(a.small, b.small, t)!,
      medium: OutlinedBorder.lerp(a.medium, b.medium, t)!,
      large: OutlinedBorder.lerp(a.large, b.large, t)!,
      capsule: OutlinedBorder.lerp(a.capsule, b.capsule, t)!,
      full: OutlinedBorder.lerp(a.full, b.full, t)!,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ComicShapes &&
      other.small == small &&
      other.medium == medium &&
      other.large == large &&
      other.capsule == capsule &&
      other.full == full;

  @override
  int get hashCode => Object.hash(small, medium, large, capsule, full);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<OutlinedBorder>('small', small))
      ..add(DiagnosticsProperty<OutlinedBorder>('medium', medium))
      ..add(DiagnosticsProperty<OutlinedBorder>('large', large))
      ..add(DiagnosticsProperty<OutlinedBorder>('capsule', capsule))
      ..add(DiagnosticsProperty<OutlinedBorder>('full', full));
  }
}
