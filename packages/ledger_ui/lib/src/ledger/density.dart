import 'package:flutter/foundation.dart';

/// How tightly Ledger sets its controls and rows: the one size setting the
/// look has, in Flutter's words for density. [standard] is the touch size
/// the look is drawn at (a 48 button, a 48 field, a 52 row); [comfortable]
/// takes 4 off each, [compact] 8. Every part that takes a line height reads
/// its height here, so a field, a select and a button that share a line keep
/// one height at every density.
///
/// The default, [adaptivePlatformDensity], is compact under a pointer
/// (macOS, Windows, Linux) and standard on touch. A tap target stays 44 at
/// every density: what shrinks is the drawn face, never the reach.
///
/// ```dart
/// LedgerTheme(
///   data: LedgerThemeData.light().copyWith(density: LedgerDensity.compact),
///   child: page,
/// )
/// ```
@immutable
final class LedgerDensity with Diagnosticable {
  const LedgerDensity._(this.name, this.step);

  /// The touch size the look is drawn at.
  static const LedgerDensity standard = LedgerDensity._('standard', 0);

  /// One step tighter: 4 off every control and row.
  static const LedgerDensity comfortable = LedgerDensity._('comfortable', -1);

  /// Two steps tighter: 8 off every control and row; what a desktop wants.
  static const LedgerDensity compact = LedgerDensity._('compact', -2);

  /// Every density, loosest first.
  static const List<LedgerDensity> values = [standard, comfortable, compact];

  /// The density for [platform]: compact under a pointer (macOS, Windows,
  /// Linux), standard on touch (Android, iOS, Fuchsia).
  static LedgerDensity defaultDensityForPlatform(TargetPlatform platform) =>
      switch (platform) {
        TargetPlatform.macOS ||
        TargetPlatform.windows ||
        TargetPlatform.linux => compact,
        TargetPlatform.android ||
        TargetPlatform.iOS ||
        TargetPlatform.fuchsia => standard,
      };

  /// The density for the platform the app runs on
  /// ([defaultTargetPlatform]), as Flutter's `adaptivePlatformDensity` is.
  static LedgerDensity get adaptivePlatformDensity =>
      defaultDensityForPlatform(defaultTargetPlatform);

  /// The density's name: `standard`, `comfortable` or `compact`.
  final String name;

  /// Steps from [standard]: 0, -1 or -2.
  final int step;

  /// The pixels one step takes off a control or a row.
  static const double stepSize = 4;

  /// [base] (a standard height) at this density: 4 off per step, never under
  /// [floor].
  double height(double base, {double floor = 24}) {
    final h = base + step * stepSize;
    return h < floor ? floor : h;
  }

  /// [base] (a standard padding) at this density: 2 off per step, never
  /// under 0.
  double padding(double base) {
    final p = base + step * stepSize / 2;
    return p < 0 ? 0 : p;
  }

  @override
  bool operator ==(Object other) =>
      other is LedgerDensity && other.step == step;

  @override
  int get hashCode => step.hashCode;

  @override
  String toStringShort() => 'LedgerDensity.$name';

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('name', name));
  }
}
