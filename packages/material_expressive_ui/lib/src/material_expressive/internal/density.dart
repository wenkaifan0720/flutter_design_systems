// The look's density: Flutter's four-pixel steps and Flutter's names for
// them, in the look's own type. Flutter's VisualDensity is Material's
// (material/theme_data.dart), so a look that is free of Material types
// cannot take it, and an app on another Material could not pass its own.
import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Density in Flutter's four-pixel steps: [standard], [comfortable] and
/// [compact], as Flutter names them, and [adaptivePlatformDensity], compact
/// where a pointer is the norm (macOS, Windows, Linux) and standard on
/// touch. A part keeps each visual's floor at every density, and the
/// pressable keeps every touch target's accessible minimum.
///
/// ```dart
/// ExpressiveThemeData.preset('baseline', Brightness.light).copyWith(density: ExpressiveDensity.compact)
/// ```
@immutable
class ExpressiveDensity with Diagnosticable {
  /// Horizontal and vertical steps, within Flutter's range (-4 to 4).
  const ExpressiveDensity({this.horizontal = 0, this.vertical = 0})
    : assert(horizontal >= -4 && horizontal <= 4),
      assert(vertical >= -4 && vertical <= 4);

  /// Horizontal four-pixel steps.
  final double horizontal;

  /// Vertical four-pixel steps.
  final double vertical;

  /// The components' token measurements.
  static const standard = ExpressiveDensity();

  /// One step closer together.
  static const comfortable = ExpressiveDensity(horizontal: -1, vertical: -1);

  /// Two steps closer together.
  static const compact = ExpressiveDensity(horizontal: -2, vertical: -2);

  /// The density for [platform]: [compact] on macOS, Windows and Linux,
  /// [standard] on Android, iOS and Fuchsia.
  static ExpressiveDensity defaultDensityForPlatform(TargetPlatform platform) =>
      switch (platform) {
        TargetPlatform.macOS ||
        TargetPlatform.windows ||
        TargetPlatform.linux => compact,
        TargetPlatform.android ||
        TargetPlatform.iOS ||
        TargetPlatform.fuchsia => standard,
      };

  /// The density for the platform the app runs on
  /// ([defaultDensityForPlatform] of `defaultTargetPlatform`): a theme's
  /// density when it sets none.
  static ExpressiveDensity get adaptivePlatformDensity =>
      defaultDensityForPlatform(defaultTargetPlatform);

  /// Adjusts a visual width without reducing it below [floor].
  double width(double own, {double floor = 24}) =>
      (own + horizontal * 4).clamp(floor, double.infinity);

  /// Adjusts a visual height without reducing it below [floor].
  double height(double own, {double floor = 24}) =>
      (own + vertical * 4).clamp(floor, double.infinity);

  /// Adjusts each side's padding without negative insets.
  EdgeInsets padding(EdgeInsets own) => EdgeInsets.fromLTRB(
    (own.left + horizontal * 2).clamp(0, double.infinity),
    (own.top + vertical * 2).clamp(0, double.infinity),
    (own.right + horizontal * 2).clamp(0, double.infinity),
    (own.bottom + vertical * 2).clamp(0, double.infinity),
  );

  /// This density with the given axes replaced.
  ExpressiveDensity copyWith({double? horizontal, double? vertical}) =>
      ExpressiveDensity(
        horizontal: horizontal ?? this.horizontal,
        vertical: vertical ?? this.vertical,
      );

  /// Interpolates both axes.
  static ExpressiveDensity lerp(
    ExpressiveDensity a,
    ExpressiveDensity b,
    double t,
  ) => ExpressiveDensity(
    horizontal: lerpDouble(a.horizontal, b.horizontal, t)!.clamp(-4, 4),
    vertical: lerpDouble(a.vertical, b.vertical, t)!.clamp(-4, 4),
  );

  @override
  bool operator ==(Object other) =>
      other is ExpressiveDensity &&
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
