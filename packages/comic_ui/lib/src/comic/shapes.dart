/// Conventional Flutter borders on Comic's corner scale.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

/// One corner scale for controls and surfaces, with square corners by default.
///
/// Buttons and fields use [small], cards and menus use [medium], and dialogs
/// and sheets use [large]. [capsule] follows the family for chips and tracks;
/// [full] stays round for identity and circular interaction affordances.
/// Every slot accepts any caller-supplied [OutlinedBorder].
///
/// ```dart
/// ComicThemeData.offset().copyWith(shapes: ComicShapes.rounded(8))
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

  /// A rounded scale on [radius], in logical pixels.
  ///
  /// Controls and frames share [radius], so a field and the menu it opens, a
  /// tab bar and the card under it, wear one corner; dialogs and sheets use
  /// one and a half. A small mark (a checkbox) caps its own corner so it never
  /// reads as round.
  ///
  /// ```dart
  /// ComicShapes.rounded(8)
  /// ```
  factory ComicShapes.rounded(double radius) {
    assert(radius >= 0);
    OutlinedBorder border(double value) =>
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(value));
    return ComicShapes(
      small: border(radius),
      medium: border(radius),
      large: border(radius * 1.5),
      capsule: const StadiumBorder(),
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
