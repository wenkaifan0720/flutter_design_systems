// The theme-wide knobs beside the shapes: the stroke scale, density and the typeface. Each falls back to the look's
// own when null, so a theme that sets none draws Neumorphism as it was designed.
import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'fonts.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

/// How compact the controls stand, in Material's `VisualDensity` steps: each step of [vertical] takes 4 from a control's
/// height and each step of [horizontal] 2 from its padding at either side, from -4 (tightest) to 4 (roomiest). The touch
/// target does not move: the touch floor on every platform, whatever the density, so a compact face
/// stands in the same target with room around it. A theme that sets none takes [adaptivePlatformDensity].
///
/// ```dart
/// final theme = NeumorphicThemeData.porcelain().copyWith(density: NeumorphicDensity.compact);
/// ```
@immutable
class NeumorphicDensity with Diagnosticable {
  /// Steps from the look's own, each between -4 and 4.
  const NeumorphicDensity({this.horizontal = 0, this.vertical = 0})
    : assert(horizontal >= -4 && horizontal <= 4),
      assert(vertical >= -4 && vertical <= 4);

  /// The look's own on touch.
  static const NeumorphicDensity standard = NeumorphicDensity();

  /// The platform's: [compact] where a pointer drives the app (macOS, Windows, Linux, and a web build opened there),
  /// [standard] on touch, as Material's `VisualDensity.adaptivePlatformDensity`.
  static NeumorphicDensity get adaptivePlatformDensity =>
      switch (defaultTargetPlatform) {
        TargetPlatform.macOS ||
        TargetPlatform.windows ||
        TargetPlatform.linux => compact,
        _ => standard,
      };

  /// One step in: 4 off a control's height.
  static const NeumorphicDensity comfortable = NeumorphicDensity(
    horizontal: -1,
    vertical: -1,
  );

  /// Two steps in: 8 off a control's height, 4 off each side's padding.
  static const NeumorphicDensity compact = NeumorphicDensity(
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

  /// This density with the named steps changed.
  NeumorphicDensity copyWith({double? horizontal, double? vertical}) =>
      NeumorphicDensity(
        horizontal: horizontal ?? this.horizontal,
        vertical: vertical ?? this.vertical,
      );

  /// Between [a] and [b].
  static NeumorphicDensity lerp(
    NeumorphicDensity a,
    NeumorphicDensity b,
    double t,
  ) => identical(a, b)
      ? a
      : NeumorphicDensity(
          horizontal: lerpDouble(a.horizontal, b.horizontal, t)!,
          vertical: lerpDouble(a.vertical, b.vertical, t)!,
        );

  @override
  bool operator ==(Object other) =>
      other is NeumorphicDensity &&
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

/// The two faces the type is set in: [display] for heads, numerals and the balance (the look's Manrope), [text] for
/// everything read (the look's Manrope), each from [displayPackage] and [textPackage] (the package that bundles it, null
/// for the app's own fonts). Sizes are the look's, scaled by the platform's text scale. The look's faces are the default; an app's
/// own fonts work when it declares them in its pubspec and loads them before the first frame.
///
/// ```dart
/// final theme = NeumorphicThemeData.porcelain().copyWith(
///   typeface: const NeumorphicTypeface.app(display: 'Brand Display', text: 'Brand Text'),
/// );
/// ```
@immutable
class NeumorphicTypeface with Diagnosticable {
  /// The look's faces unless named.
  const NeumorphicTypeface({
    this.display = 'Manrope',
    this.text = 'Manrope',
    this.displayPackage = neumorphicFontPackage,
    this.textPackage = neumorphicFontPackage,
    this.fallback = const [],
  });

  /// The app's own faces, from its own assets: no package.
  const NeumorphicTypeface.app({
    required this.display,
    required this.text,
    this.fallback = const [],
  }) : displayPackage = null,
       textPackage = null;

  /// The look's: Manrope, at the look's sizes.
  static const NeumorphicTypeface look = NeumorphicTypeface();

  /// The display face's family.
  final String display;

  /// The text face's family.
  final String text;

  /// The package that bundles [display]; null for the app's own.
  final String? displayPackage;

  /// The package that bundles [text]; null for the app's own.
  final String? textPackage;

  /// Faces to fall back on, in order, for a glyph the faces lack: the app's own families. Every text style the theme
  /// builds names them (`TextStyle.fontFamilyFallback`), and so does the Material theme under the look's parts, as
  /// Material's `ThemeData.fontFamilyFallback` does: on the web a face the app loads at run time (a Noto Sans JP
  /// subset, say) draws only where a style names it.
  final List<String> fallback;

  /// This with the named parts changed.
  NeumorphicTypeface copyWith({
    String? display,
    String? text,
    List<String>? fallback,
  }) => NeumorphicTypeface(
    display: display ?? this.display,
    text: text ?? this.text,
    displayPackage: displayPackage,
    textPackage: textPackage,
    fallback: fallback ?? this.fallback,
  );

  /// Between [a] and [b]: the faces change at the middle.
  static NeumorphicTypeface lerp(
    NeumorphicTypeface a,
    NeumorphicTypeface b,
    double t,
  ) {
    if (identical(a, b)) return a;
    final faces = t < .5 ? a : b;
    return NeumorphicTypeface(
      display: faces.display,
      text: faces.text,
      displayPackage: faces.displayPackage,
      textPackage: faces.textPackage,
      fallback: faces.fallback,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is NeumorphicTypeface &&
      other.display == display &&
      other.text == text &&
      other.displayPackage == displayPackage &&
      other.textPackage == textPackage &&
      listEquals(other.fallback, fallback);

  @override
  int get hashCode => Object.hash(
    display,
    text,
    displayPackage,
    textPackage,
    Object.hashAll(fallback),
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('display', display));
    properties.add(StringProperty('text', text));
    properties.add(
      IterableProperty<String>('fallback', fallback, defaultValue: const []),
    );
  }
}
