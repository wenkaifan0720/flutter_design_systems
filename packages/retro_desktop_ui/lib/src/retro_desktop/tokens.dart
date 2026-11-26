import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// How much room the parts give their contents, in Flutter's steps. A part's
/// padding and gaps scale with it; its touch target keeps its floor.
///
/// The theme's default is [adaptivePlatformDensity]: [compact] where a
/// pointer is the usual input (macOS, Windows, Linux), [standard] on touch.
enum RetroDesktopDensity {
  /// The look's own spacing.
  standard(1),

  /// A fifth more room: for reading, or for hands less sure of a pointer.
  comfortable(1.2),

  /// A fifth less room: a desktop's denser rows and toolbars.
  compact(.8);

  const RetroDesktopDensity(this._factor);

  final double _factor;

  /// The density a platform expects: [compact] on macOS, Windows and Linux,
  /// [standard] on Android, iOS and Fuchsia.
  static RetroDesktopDensity get adaptivePlatformDensity =>
      switch (defaultTargetPlatform) {
        TargetPlatform.macOS ||
        TargetPlatform.windows ||
        TargetPlatform.linux => compact,
        TargetPlatform.android ||
        TargetPlatform.iOS ||
        TargetPlatform.fuchsia => standard,
      };

  /// The multiplier applied to horizontal spacing.
  double get horizontal => _factor;

  /// The multiplier applied to vertical spacing.
  double get vertical => _factor;

  /// [value] with its sides scaled by this density, each to a whole logical
  /// pixel: a face keeps a whole height, and what stands under it the pixel
  /// grid (a fifth of 7 left a button 37.2 high, every row below it a fifth
  /// of a pixel off the grid and its words half a device pixel off its face's
  /// middle).
  EdgeInsets apply(EdgeInsetsGeometry value, TextDirection direction) {
    final resolved = value.resolve(direction);
    return EdgeInsets.fromLTRB(
      (resolved.left * horizontal).roundToDouble(),
      (resolved.top * vertical).roundToDouble(),
      (resolved.right * horizontal).roundToDouble(),
      (resolved.bottom * vertical).roundToDouble(),
    );
  }
}

/// The look's spacing, on its own 2 px grid. Platinum measured its parts in
/// whole pixels, and its metrics are mostly even but not on a 4 or 8 point
/// scale (6 from a window's frame to what it holds, 10 and 14 in its
/// dialogs). An inset measured from a part's outer edge counts the part's
/// 1 px bevel or rule as well: a step and [px] (9 is [s8] and a pixel).
/// Parts scale these by their density.
///
/// ```dart
/// Padding(padding: EdgeInsets.all(RetroDesktopSpacing.s6), child: child)
/// ```
abstract final class RetroDesktopSpacing {
  /// One whole pixel, a bevel's or a rule's width.
  static const double px = 1;

  /// 2 px, the grid's step.
  static const double s2 = 2;

  /// 4 px.
  static const double s4 = 4;

  /// 6 px.
  static const double s6 = 6;

  /// 8 px.
  static const double s8 = 8;

  /// 10 px.
  static const double s10 = 10;

  /// 12 px.
  static const double s12 = 12;

  /// 14 px.
  static const double s14 = 14;

  /// 16 px.
  static const double s16 = 16;

  /// 18 px.
  static const double s18 = 18;

  /// 20 px.
  static const double s20 = 20;

  /// 24 px.
  static const double s24 = 24;

  /// 32 px.
  static const double s32 = 32;

  /// 40 px.
  static const double s40 = 40;
}

/// The look's line widths, read by a part that draws in its hand: a
/// 1 px frame and rule, as the period drew them, and a 2 px heavy line (a
/// default button's ring, Platinum's focus ring). Not a setting.
@immutable
class RetroDesktopStrokes {
  const RetroDesktopStrokes._();

  /// The look's widths.
  static const RetroDesktopStrokes standard = RetroDesktopStrokes._();

  /// The width of fine rules in logical pixels.
  double get hairline => 1;

  /// The width of ordinary outlines in logical pixels.
  double get regular => 1;

  /// The width of emphasized outlines in logical pixels.
  double get heavy => 2;
}

/// The look's faces: Jersey 15 for its chrome and display words, Atkinson
/// Hyperlegible Next for reading, Atkinson Hyperlegible Mono for figures that
/// line up. A brand's fonts, or a script these lack, replace them here.
@immutable
class RetroDesktopTypeface {
  /// Creates a [RetroDesktopTypeface].
  const RetroDesktopTypeface({
    this.chromeFamily = 'Jersey15',
    this.bodyFamily = 'AtkinsonNext',
    this.monoFamily = 'AtkinsonMono',
    this.fallback = const [],
  });

  /// The font family used for chrome and display labels.
  final String chromeFamily;

  /// The font family used for reading text.
  final String bodyFamily;

  /// The font family used for aligned numeric text.
  final String monoFamily;

  /// Faces to fall back on, in order, for a glyph the faces lack. Every text
  /// style the theme builds names them (`TextStyle.fontFamilyFallback`), and
  /// so does the Material theme under the look's parts, as Material's
  /// `ThemeData.fontFamilyFallback` does: on the web a face the app loads at
  /// run time (a Noto Sans JP subset, say) draws only where a style names it.
  final List<String> fallback;

  /// Returns a copy with the supplied values replaced.
  RetroDesktopTypeface copyWith({
    String? chromeFamily,
    String? bodyFamily,
    String? monoFamily,
    List<String>? fallback,
  }) => RetroDesktopTypeface(
    chromeFamily: chromeFamily ?? this.chromeFamily,
    bodyFamily: bodyFamily ?? this.bodyFamily,
    monoFamily: monoFamily ?? this.monoFamily,
    fallback: fallback ?? this.fallback,
  );

  @override
  bool operator ==(Object other) =>
      other is RetroDesktopTypeface &&
      chromeFamily == other.chromeFamily &&
      bodyFamily == other.bodyFamily &&
      monoFamily == other.monoFamily &&
      listEquals(fallback, other.fallback);
  @override
  int get hashCode => Object.hash(
    chromeFamily,
    bodyFamily,
    monoFamily,
    Object.hashAll(fallback),
  );
}
