// The theme-wide knobs beside the shapes: the stroke scale, density and the typeface. Each falls back to the look's
// own when null, so a theme that sets none draws Comic as it was designed.
import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import 'fonts.dart';

/// The widths every styled part's rims and rules read, in logical pixels: [hairline] for the rules inside a part (the
/// act plate's inner rule, a segment's, a card's second line), [regular] for a part's rim, [heavy] for the focus ring
/// and a chosen part's rim. Null keeps the look's own ink contours, with heavier focus marks.
///
/// ```dart
/// final theme = ComicThemeData.offset().copyWith(
///   strokes: const ComicStrokes(regular: 2, heavy: 3),
/// );
/// ```
@immutable
class ComicStrokes with Diagnosticable {
  /// The named widths; null keeps the look's.
  const ComicStrokes({this.hairline, this.regular, this.heavy})
    : assert(hairline == null || hairline > 0),
      assert(regular == null || regular > 0),
      assert(heavy == null || heavy > 0);

  /// The look's own widths: 2, 2.5 and 3.
  static const ComicStrokes look = ComicStrokes(
    hairline: 2,
    regular: 2.5,
    heavy: 3,
  );

  /// Rims at 4 and the focus ring at 5: a bolder line for a brand that wants it.
  static const ComicStrokes bold = ComicStrokes(
    hairline: 3,
    regular: 4,
    heavy: 5,
  );

  /// The rules inside a part.
  final double? hairline;

  /// A part's rim.
  final double? regular;

  /// The focus ring and a chosen part's rim.
  final double? heavy;

  /// True when every width is null.
  bool get isEmpty => hairline == null && regular == null && heavy == null;

  /// This with the named widths changed.
  ComicStrokes copyWith({double? hairline, double? regular, double? heavy}) =>
      ComicStrokes(
        hairline: hairline ?? this.hairline,
        regular: regular ?? this.regular,
        heavy: heavy ?? this.heavy,
      );

  /// Between [a] and [b]; a null width counts as the look's.
  static ComicStrokes lerp(ComicStrokes a, ComicStrokes b, double t) {
    if (identical(a, b) || t == 0) return a;
    if (t == 1) return b;
    double? l(double? x, double? y, double own) =>
        x == null && y == null ? null : lerpDouble(x ?? own, y ?? own, t);
    return ComicStrokes(
      hairline: l(a.hairline, b.hairline, 2),
      regular: l(a.regular, b.regular, 2.5),
      heavy: l(a.heavy, b.heavy, 3),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ComicStrokes &&
      other.hairline == hairline &&
      other.regular == regular &&
      other.heavy == heavy;

  @override
  int get hashCode => Object.hash(hairline, regular, heavy);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DoubleProperty('hairline', hairline, defaultValue: null));
    properties.add(DoubleProperty('regular', regular, defaultValue: null));
    properties.add(DoubleProperty('heavy', heavy, defaultValue: null));
  }
}

/// How compact the controls stand, as Material's `VisualDensity`: each step of [vertical] takes 4 from a control's
/// height and each step of [horizontal] 2 from its padding at either side, from -4 (tightest) to 4 (roomiest). The touch
/// target does not move: 48 where a touch reaches the control, 44 elsewhere, whatever the density, so a compact face
/// stands in the same target with room around it.
///
/// ```dart
/// final theme = ComicThemeData.offset().copyWith(density: ComicDensity.compact);
/// ```
@immutable
class ComicDensity with Diagnosticable {
  /// Steps from the look's own, each between -4 and 4.
  const ComicDensity({this.horizontal = 0, this.vertical = 0})
    : assert(horizontal >= -4 && horizontal <= 4),
      assert(vertical >= -4 && vertical <= 4);

  /// The look's own.
  static const ComicDensity standard = ComicDensity();

  /// One step in: 4 off a control's height.
  static const ComicDensity comfortable = ComicDensity(
    horizontal: -1,
    vertical: -1,
  );

  /// Two steps in: 8 off a control's height, 4 off each side's padding.
  static const ComicDensity compact = ComicDensity(
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

  /// This with either density axis changed.
  ComicDensity copyWith({double? horizontal, double? vertical}) => ComicDensity(
    horizontal: horizontal ?? this.horizontal,
    vertical: vertical ?? this.vertical,
  );

  /// Between [a] and [b].
  static ComicDensity lerp(ComicDensity a, ComicDensity b, double t) =>
      identical(a, b)
      ? a
      : ComicDensity(
          horizontal: lerpDouble(a.horizontal, b.horizontal, t)!,
          vertical: lerpDouble(a.vertical, b.vertical, t)!,
        );

  @override
  bool operator ==(Object other) =>
      other is ComicDensity &&
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

/// The two faces and the size scale the type is set in: [display] for heads, numerals and the balance (the look's
/// Bangers), [text] for everything read (the look's ShantellSans), each from [displayPackage] and [textPackage] (the package
/// that bundles it, null for the app's own fonts), every size times [scale]. The look's faces are the default; an app's
/// own fonts work when it declares them in its pubspec and loads them before the first frame. Each face's cap height
/// ([displayCapHeight], [textCapHeight]) sets its capitals on a control's middle: name it with the face.
///
/// ```dart
/// final theme = ComicThemeData.offset().copyWith(
///   typeface: const ComicTypeface(display: 'ShantellSans', text: 'ShantellSans', displayCapHeight: 0.700, scale: 1.1),
/// );
/// ```
@immutable
class ComicTypeface with Diagnosticable {
  /// The look's faces unless named.
  const ComicTypeface({
    this.display = 'Bangers',
    this.text = 'ShantellSans',
    this.displayPackage = comicFontPackage,
    this.textPackage = comicFontPackage,
    this.scale = 1,
    this.displayCapHeight = 0.721,
    this.textCapHeight = 0.700,
  }) : assert(scale > 0);

  /// The app's own faces, from its own assets: no package.
  const ComicTypeface.app({
    required this.display,
    required this.text,
    this.scale = 1,
    this.displayCapHeight = 0.7,
    this.textCapHeight = 0.7,
  }) : displayPackage = null,
       textPackage = null;

  /// The look's: Bangers over ShantellSans, at the look's sizes.
  static const ComicTypeface look = ComicTypeface();

  /// The display face's family.
  final String display;

  /// The text face's family.
  final String text;

  /// The package that bundles [display]; null for the app's own.
  final String? displayPackage;

  /// The package that bundles [text]; null for the app's own.
  final String? textPackage;

  /// Every size times this.
  final double scale;

  /// The height of [display]'s capitals as a fraction of its size: the font's OS/2 `sCapHeight` over its
  /// `unitsPerEm` (Bangers 0.721). A control's one-line label is drawn with its capitals on its face's middle by it.
  final double displayCapHeight;

  /// The height of [text]'s capitals as a fraction of its size, as [displayCapHeight] (Shantell Sans 0.700).
  final double textCapHeight;

  /// This with the named parts changed.
  ComicTypeface copyWith({
    String? display,
    String? text,
    double? scale,
    double? displayCapHeight,
    double? textCapHeight,
  }) => ComicTypeface(
    display: display ?? this.display,
    text: text ?? this.text,
    displayPackage: displayPackage,
    textPackage: textPackage,
    scale: scale ?? this.scale,
    displayCapHeight: displayCapHeight ?? this.displayCapHeight,
    textCapHeight: textCapHeight ?? this.textCapHeight,
  );

  /// Between [a] and [b]: the scale eases, the faces change at the middle.
  static ComicTypeface lerp(ComicTypeface a, ComicTypeface b, double t) {
    if (identical(a, b) || t == 0) return a;
    if (t == 1) return b;
    final faces = t < .5 ? a : b;
    return ComicTypeface(
      display: faces.display,
      text: faces.text,
      displayPackage: faces.displayPackage,
      textPackage: faces.textPackage,
      scale: lerpDouble(a.scale, b.scale, t)!,
      displayCapHeight: faces.displayCapHeight,
      textCapHeight: faces.textCapHeight,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ComicTypeface &&
      other.display == display &&
      other.text == text &&
      other.displayPackage == displayPackage &&
      other.textPackage == textPackage &&
      other.scale == scale &&
      other.displayCapHeight == displayCapHeight &&
      other.textCapHeight == textCapHeight;

  @override
  int get hashCode => Object.hash(
    display,
    text,
    displayPackage,
    textPackage,
    scale,
    displayCapHeight,
    textCapHeight,
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('display', display));
    properties.add(StringProperty('text', text));
    properties.add(DoubleProperty('scale', scale, defaultValue: 1));
    properties.add(DoubleProperty('displayCapHeight', displayCapHeight));
    properties.add(DoubleProperty('textCapHeight', textCapHeight));
  }
}
