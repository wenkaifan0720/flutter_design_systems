// The theme-wide knobs: the stroke widths, density and the
// typeface. Each is the look's own by default, so a theme that sets none
// draws Frosted as it was designed.
import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import 'fonts.dart';

/// The widths every rim and rule is drawn at, in logical pixels: [hairline]
/// for the rules inside a part (a list's dividers, a key's hairlines),
/// [regular] for a part's glass edge, [heavy] for the focus light. Glass is
/// edged by a line of light, never a heavy stroke.
abstract final class FrostedStrokes {
  /// A rule inside a part: 1.
  static const double hairline = 1;

  /// A part's glass edge: 1.
  static const double regular = 1;

  /// The focus light's band: 2.
  static const double heavy = 2;
}

/// How compact the controls stand, as Material's `VisualDensity`: each step
/// of [vertical] takes 4 from a control's height and each step of
/// [horizontal] 2 from its padding at either side, from -4 (tightest) to 4
/// (roomiest). The touch target does not move: 48 where a touch reaches the
/// control, 44 elsewhere, whatever the density, so a compact face stands in
/// the same target with room around it.
///
/// ```dart
/// final theme = FrostedThemeData.opal().copyWith(
///   density: FrostedDensity.compact,
/// );
/// ```
@immutable
class FrostedDensity with Diagnosticable {
  /// Steps from the look's own, each between -4 and 4.
  const FrostedDensity({this.horizontal = 0, this.vertical = 0})
    : assert(horizontal >= -4 && horizontal <= 4),
      assert(vertical >= -4 && vertical <= 4);

  /// The look's own.
  static const FrostedDensity standard = FrostedDensity();

  /// One step in: 4 off a control's height.
  static const FrostedDensity comfortable = FrostedDensity(
    horizontal: -1,
    vertical: -1,
  );

  /// Two steps in: 8 off a control's height, 4 off each side's padding.
  static const FrostedDensity compact = FrostedDensity(
    horizontal: -2,
    vertical: -2,
  );

  /// The platform's own, as Flutter's `VisualDensity.adaptivePlatformDensity`:
  /// [compact] on a desktop (macOS, Windows, Linux), [standard] on a phone or
  /// a tablet.
  static FrostedDensity get adaptivePlatformDensity =>
      switch (defaultTargetPlatform) {
        TargetPlatform.macOS ||
        TargetPlatform.windows ||
        TargetPlatform.linux => compact,
        TargetPlatform.android ||
        TargetPlatform.iOS ||
        TargetPlatform.fuchsia => standard,
      };

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

  /// This with either axis changed.
  FrostedDensity copyWith({double? horizontal, double? vertical}) =>
      FrostedDensity(
        horizontal: horizontal ?? this.horizontal,
        vertical: vertical ?? this.vertical,
      );

  /// Between [a] and [b].
  static FrostedDensity lerp(FrostedDensity a, FrostedDensity b, double t) =>
      identical(a, b)
      ? a
      : FrostedDensity(
          horizontal: lerpDouble(a.horizontal, b.horizontal, t)!,
          vertical: lerpDouble(a.vertical, b.vertical, t)!,
        );

  @override
  bool operator ==(Object other) =>
      other is FrostedDensity &&
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

/// The two faces the type is set in: [display] for heads
/// and figures (the look's Bricolage Grotesque), [text] for everything read
/// (the look's DM Sans), each from [displayPackage] and [textPackage] (the
/// package that bundles it, null for the app's own fonts). The look's faces are the default; an app's own fonts work when
/// it declares them in its pubspec and loads them before the first frame.
///
/// ```dart
/// final theme = FrostedThemeData.opal().copyWith(
///   typeface: const FrostedTypeface(display: 'DMSans'),
/// );
/// ```
@immutable
class FrostedTypeface with Diagnosticable {
  /// The look's faces unless named.
  const FrostedTypeface({
    this.display = 'BricolageGrotesque',
    this.text = 'DMSans',
    this.displayPackage = frostedFontPackage,
    this.textPackage = frostedFontPackage,
  });

  /// The app's own faces, from its own assets: no package.
  const FrostedTypeface.app({required this.display, required this.text})
    : displayPackage = null,
      textPackage = null;

  /// The look's: Bricolage Grotesque over DM Sans, at the look's sizes.
  static const FrostedTypeface look = FrostedTypeface();

  /// The display face's family.
  final String display;

  /// The text face's family.
  final String text;

  /// The package that bundles [display]; null for the app's own.
  final String? displayPackage;

  /// The package that bundles [text]; null for the app's own.
  final String? textPackage;

  /// [display] under the name Flutter registers it by: the family itself,
  /// or `packages/<package>/<family>` from a package.
  String get displayFamily =>
      displayPackage == null ? display : 'packages/$displayPackage/$display';

  /// [text] under the name Flutter registers it by.
  String get textFamily =>
      textPackage == null ? text : 'packages/$textPackage/$text';

  /// This with the named parts changed.
  FrostedTypeface copyWith({String? display, String? text}) => FrostedTypeface(
    display: display ?? this.display,
    text: text ?? this.text,
    displayPackage: displayPackage,
    textPackage: textPackage,
  );

  /// Between [a] and [b]: the faces change at the middle.
  static FrostedTypeface lerp(FrostedTypeface a, FrostedTypeface b, double t) {
    if (identical(a, b) || t == 0) return a;
    if (t == 1) return b;
    final faces = t < .5 ? a : b;
    return FrostedTypeface(
      display: faces.display,
      text: faces.text,
      displayPackage: faces.displayPackage,
      textPackage: faces.textPackage,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is FrostedTypeface &&
      other.display == display &&
      other.text == text &&
      other.displayPackage == displayPackage &&
      other.textPackage == textPackage;

  @override
  int get hashCode => Object.hash(display, text, displayPackage, textPackage);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('display', display))
      ..add(StringProperty('text', text));
  }
}
