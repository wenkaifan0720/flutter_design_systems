/// The theme-wide knobs beside the shapes: the density and the typeface.
/// Each defaults to the look's own, so a theme that sets none draws Minimal
/// as it was designed.
library;

import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import 'fonts.dart';

/// How compact the controls stand, in Flutter's `VisualDensity` steps and
/// names: each step of [vertical] takes 2 from a control's height and each
/// step of [horizontal] 1 from its padding at either side, from -4 (tightest)
/// to 4 (roomiest). Half Material's reading, because Minimal's controls start
/// dense: [compact], a desktop's default, is a 28 px control and a 32 px
/// dense row. Minimal's own type, so the look's API names no Material class.
///
/// The touch target does not move: 48 where a touch reaches the control, 44
/// elsewhere, whatever the density, so a compact face stands in the same
/// target with room around it. A list row is its own target, so it never
/// stands under 44; a looser density still grows it.
///
/// ```dart
/// final theme = MinimalThemeData.standard().copyWith(
///   density: MinimalDensity.compact,
/// );
/// ```
@immutable
class MinimalDensity with Diagnosticable {
  /// Steps from the look's own, each between -4 and 4.
  const MinimalDensity({this.horizontal = 0, this.vertical = 0})
    : assert(horizontal >= -4 && horizontal <= 4),
      assert(vertical >= -4 && vertical <= 4);

  /// The look's own: 32 px controls, 44 px rows. A touch platform's default.
  static const MinimalDensity standard = MinimalDensity();

  /// One step in: 30 px controls, 34 px dense rows.
  static const MinimalDensity comfortable = MinimalDensity(
    horizontal: -1,
    vertical: -1,
  );

  /// Two steps in: 28 px controls, 32 px dense rows. A desktop's default.
  static const MinimalDensity compact = MinimalDensity(
    horizontal: -2,
    vertical: -2,
  );

  /// The density for [platform], as Flutter names it: [compact] on macOS,
  /// Windows and Linux (and a web build opened on one), [standard] on touch.
  static MinimalDensity defaultDensityForPlatform(TargetPlatform platform) =>
      switch (platform) {
        TargetPlatform.android ||
        TargetPlatform.iOS ||
        TargetPlatform.fuchsia => standard,
        TargetPlatform.linux ||
        TargetPlatform.macOS ||
        TargetPlatform.windows => compact,
      };

  /// The density for the platform the app runs on: what a theme that sets
  /// none takes.
  static MinimalDensity get adaptivePlatformDensity =>
      defaultDensityForPlatform(defaultTargetPlatform);

  /// The horizontal step.
  final double horizontal;

  /// The vertical step.
  final double vertical;

  /// What it adds to a control's height: 2 a step.
  double get heightDelta => vertical * 2;

  /// What it adds to a control's padding at either side: 1 a step.
  double get paddingDelta => horizontal;

  /// [height] at this density, at least [least].
  double height(double height, {double least = 20}) =>
      vertical == 0 ? height : math.max(least, height + heightDelta);

  /// [padding] at this density, its sides at least [least].
  EdgeInsets padding(EdgeInsets padding, {double least = 4}) {
    if (horizontal == 0) return padding;
    double side(double v) => math.max(math.min(least, v), v + paddingDelta);
    return EdgeInsets.fromLTRB(
      side(padding.left),
      padding.top,
      side(padding.right),
      padding.bottom,
    );
  }

  /// Between [a] and [b].
  static MinimalDensity lerp(MinimalDensity a, MinimalDensity b, double t) =>
      identical(a, b)
      ? a
      : MinimalDensity(
          horizontal: lerpDouble(a.horizontal, b.horizontal, t)!,
          vertical: lerpDouble(a.vertical, b.vertical, t)!,
        );

  @override
  bool operator ==(Object other) =>
      other is MinimalDensity &&
      other.horizontal == horizontal &&
      other.vertical == vertical;

  @override
  int get hashCode => Object.hash(horizontal, vertical);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DoubleProperty('horizontal', horizontal, defaultValue: 0))
      ..add(DoubleProperty('vertical', vertical, defaultValue: 0));
  }
}

/// The two faces the type is set in: [sans] for every word (the look's
/// Geist), [mono] for figures, stamps and code (the look's Geist Mono,
/// tabular), each from [sansPackage] and [monoPackage] (the package that
/// bundles it, null for the app's own fonts). The look's faces are the
/// default; an app's own fonts work when it declares them in its pubspec and
/// loads them before the first frame.
///
/// ```dart
/// final theme = MinimalThemeData.standard().copyWith(
///   typeface: const MinimalTypeface.app(sans: 'Inter', mono: 'JetBrainsMono'),
/// );
/// ```
@immutable
class MinimalTypeface with Diagnosticable {
  /// The look's faces unless named.
  const MinimalTypeface({
    this.sans = 'Geist',
    this.mono = 'GeistMono',
    this.sansPackage = minimalFontPackage,
    this.monoPackage = minimalFontPackage,
  });

  /// The app's own faces, from its own assets: no package.
  const MinimalTypeface.app({required this.sans, required this.mono})
    : sansPackage = null,
      monoPackage = null;

  /// The look's: Geist and Geist Mono.
  static const MinimalTypeface look = MinimalTypeface();

  /// The face every word is set in.
  final String sans;

  /// The face figures, stamps and code are set in: it should have tabular
  /// figures.
  final String mono;

  /// The package that bundles [sans]; null for the app's own.
  final String? sansPackage;

  /// The package that bundles [mono]; null for the app's own.
  final String? monoPackage;

  /// This with the named parts changed.
  MinimalTypeface copyWith({String? sans, String? mono}) => MinimalTypeface(
    sans: sans ?? this.sans,
    mono: mono ?? this.mono,
    sansPackage: sansPackage,
    monoPackage: monoPackage,
  );

  /// Between [a] and [b]: the faces change at the middle.
  static MinimalTypeface lerp(MinimalTypeface a, MinimalTypeface b, double t) =>
      t < .5 ? a : b;

  @override
  bool operator ==(Object other) =>
      other is MinimalTypeface &&
      other.sans == sans &&
      other.mono == mono &&
      other.sansPackage == sansPackage &&
      other.monoPackage == monoPackage;

  @override
  int get hashCode => Object.hash(sans, mono, sansPackage, monoPackage);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('sans', sans, defaultValue: 'Geist'))
      ..add(StringProperty('mono', mono, defaultValue: 'GeistMono'));
  }
}
