/// Expressive's spacing: [ExpressiveSpacing], Material's 8dp scale
/// `space0…space900` = 0, 2, 4, 6, 8, 10, 12, 14, 16, 20, 24, 32, 36, 40,
/// 48, 56, 64, 72 under Cody's member names (`ExpressiveSpacing.s8` =
/// `space100`; CONTRACT §2 "Spacing"). Fixed: themes never vary it.
///
/// Generated: tools/expressive_tokens reads the scale from
/// `spec/spacing.json` (its source page and retrieval date), cross-checks
/// every step against the token DB's `md.sys.measurement.*` and writes
/// `internal/spacing/spacing.g.dart`, which this names. Owner: w1-tokens.
library;

import 'internal/spacing/spacing.g.dart';

/// The 8dp spacing scale, in logical pixels (dp).
abstract final class ExpressiveSpacing {
  /// 0dp (`md.sys.measurement.space0`).
  static const double s0 = SpacingTokens.s0;

  /// 2dp (`md.sys.measurement.space25`).
  static const double s2 = SpacingTokens.s2;

  /// 4dp (`md.sys.measurement.space50`).
  static const double s4 = SpacingTokens.s4;

  /// 6dp (`md.sys.measurement.space75`).
  static const double s6 = SpacingTokens.s6;

  /// 8dp (`md.sys.measurement.space100`).
  static const double s8 = SpacingTokens.s8;

  /// 10dp (`md.sys.measurement.space125`).
  static const double s10 = SpacingTokens.s10;

  /// 12dp (`md.sys.measurement.space150`).
  static const double s12 = SpacingTokens.s12;

  /// 14dp (`md.sys.measurement.space175`).
  static const double s14 = SpacingTokens.s14;

  /// 16dp (`md.sys.measurement.space200`).
  static const double s16 = SpacingTokens.s16;

  /// 20dp (`md.sys.measurement.space250`).
  static const double s20 = SpacingTokens.s20;

  /// 24dp (`md.sys.measurement.space300`).
  static const double s24 = SpacingTokens.s24;

  /// 32dp (`md.sys.measurement.space400`).
  static const double s32 = SpacingTokens.s32;

  /// 36dp (`md.sys.measurement.space450`).
  static const double s36 = SpacingTokens.s36;

  /// 40dp (`md.sys.measurement.space500`).
  static const double s40 = SpacingTokens.s40;

  /// 48dp (`md.sys.measurement.space600`).
  static const double s48 = SpacingTokens.s48;

  /// 56dp (`md.sys.measurement.space700`).
  static const double s56 = SpacingTokens.s56;

  /// 64dp (`md.sys.measurement.space800`).
  static const double s64 = SpacingTokens.s64;

  /// 72dp (`md.sys.measurement.space900`).
  static const double s72 = SpacingTokens.s72;

  /// Every step, smallest first.
  static const List<double> scale = SpacingTokens.scale;
}
