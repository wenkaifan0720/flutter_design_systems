// The theme's two settings beside its colours: the density and the typeface.
// Each falls back to Fluent 2's own when unset, so a theme that sets none
// draws Fluent 2 as it was designed.
import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import 'fonts.dart';

/// How compact the controls stand, in Flutter's words for `VisualDensity`
/// (this is the look's own type, free of Material's): each step
/// of [vertical] takes 4 from a control's height and each step of
/// [horizontal] 2 from its padding at either side, from -4 (tightest) to 4
/// (roomiest). The touch target does not move: 48 where a touch reaches
/// the control, 44 elsewhere, whatever the density, so a compact face
/// stands in the same target with room around it. A control's own `size:`
/// (small, medium, large) picks Fluent's measures first; the density moves
/// from there. A theme is [standard] unless set, on every platform:
/// Fluent's measures are its desktop measures; touch grows targets, not
/// faces ([adaptivePlatformDensity] is there for an app that wants a
/// desktop more compact still).
///
/// ```dart
/// final theme = Fluent2ThemeData.lapis().copyWith(
///   density: Fluent2Density.compact,
/// );
/// ```
@immutable
class Fluent2Density with Diagnosticable {
  /// Steps from Fluent's own, each between -4 and 4.
  const Fluent2Density({this.horizontal = 0, this.vertical = 0})
    : assert(horizontal >= -4 && horizontal <= 4),
      assert(vertical >= -4 && vertical <= 4);

  /// Fluent's own.
  static const Fluent2Density standard = Fluent2Density();

  /// The density for the platform the app runs on, as Flutter's
  /// `VisualDensity.adaptivePlatformDensity` picks one: [compact] on macOS,
  /// Windows and Linux, where a pointer reaches the controls, [standard] on
  /// Android, iOS and Fuchsia. An option: a theme that sets no density is
  /// [standard] on every platform, because Fluent's measures are its desktop
  /// measures; touch grows targets, not faces.
  static Fluent2Density get adaptivePlatformDensity =>
      switch (defaultTargetPlatform) {
        TargetPlatform.macOS ||
        TargetPlatform.windows ||
        TargetPlatform.linux => compact,
        TargetPlatform.android ||
        TargetPlatform.iOS ||
        TargetPlatform.fuchsia => standard,
      };

  /// One step in: 4 off a control's height.
  static const Fluent2Density comfortable = Fluent2Density(
    horizontal: -1,
    vertical: -1,
  );

  /// Two steps in: 8 off a control's height, 4 off each side's padding.
  static const Fluent2Density compact = Fluent2Density(
    horizontal: -2,
    vertical: -2,
  );

  /// The horizontal step.
  final double horizontal;

  /// The vertical step.
  final double vertical;

  /// What it adds to a control's height: 4 a step.
  double get heightDelta => vertical * 4;

  /// What it adds to a control's padding at either side: 2 a step.
  double get paddingDelta => horizontal * 2;

  /// [height] at this density, at least [least].
  double height(double height, {double least = 16}) =>
      math.max(least, height + heightDelta);

  /// [padding] at this density, its sides at least [least].
  EdgeInsets padding(EdgeInsets padding, {double least = 4}) {
    if (horizontal == 0 && vertical == 0) return padding;
    double h(double v) => math.max(math.min(least, v), v + paddingDelta);
    double v(double x) => math.max(math.min(least / 2, x), x + vertical);
    return EdgeInsets.fromLTRB(
      h(padding.left),
      v(padding.top),
      h(padding.right),
      v(padding.bottom),
    );
  }

  /// Between [a] and [b].
  static Fluent2Density lerp(Fluent2Density a, Fluent2Density b, double t) =>
      identical(a, b)
      ? a
      : Fluent2Density(
          horizontal: lerpDouble(a.horizontal, b.horizontal, t)!,
          vertical: lerpDouble(a.vertical, b.vertical, t)!,
        );

  @override
  bool operator ==(Object other) =>
      other is Fluent2Density &&
      other.horizontal == horizontal &&
      other.vertical == vertical;

  @override
  int get hashCode => Object.hash(horizontal, vertical);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DoubleProperty('horizontal', horizontal, defaultValue: 0));
    properties.add(DoubleProperty('vertical', vertical, defaultValue: 0));
  }
}

/// The face the type ramp is set in: [family] from [package] (the package
/// that bundles it, null for the app's own fonts), at Fluent's sizes. Fluent
/// sets everything in one face; the default is the bundled Selawik, the open
/// stand-in for Fluent's system face. An app's own face (a brand's, or one
/// for a script Selawik lacks) works when it declares it in its pubspec and
/// loads it before the first frame.
///
/// ```dart
/// final theme = Fluent2ThemeData.lapis().copyWith(
///   typeface: const Fluent2Typeface.app(family: 'Inter'),
/// );
/// ```
@immutable
class Fluent2Typeface with Diagnosticable {
  /// Fluent 2's face unless named.
  const Fluent2Typeface({
    this.family = 'Selawik',
    this.package = fluent2FontPackage,
  });

  /// The app's own face, from its own assets: no package.
  const Fluent2Typeface.app({required this.family}) : package = null;

  /// Fluent 2's: Selawik at Fluent's sizes.
  static const Fluent2Typeface look = Fluent2Typeface();

  /// The font family.
  final String family;

  /// The package that bundles [family]; null for the app's own fonts.
  final String? package;

  /// A ramp step in this face: [size] on a [line] px line at [weight], in
  /// [color], with even leading so a line centres in its box.
  TextStyle style(double size, double line, int weight, Color color) =>
      TextStyle(
        fontFamily: family,
        package: package,
        fontSize: size,
        height: line / size,
        fontWeight: FontWeight(weight),
        leadingDistribution: TextLeadingDistribution.even,
        color: color,
      );

  /// This with [family] changed.
  Fluent2Typeface copyWith({String? family}) =>
      Fluent2Typeface(family: family ?? this.family, package: package);

  /// Between [a] and [b]: a face does not blend, so it changes at the middle.
  static Fluent2Typeface lerp(Fluent2Typeface a, Fluent2Typeface b, double t) =>
      t < .5 ? a : b;

  @override
  bool operator ==(Object other) =>
      other is Fluent2Typeface &&
      other.family == family &&
      other.package == package;

  @override
  int get hashCode => Object.hash(family, package);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('family', family));
    properties.add(StringProperty('package', package, defaultValue: null));
  }
}
