import 'package:flutter/widgets.dart';

import 'press.dart';

/// Shared measures of Comic's page and controls.
abstract final class ComicChromeMetrics {
  /// The least target at [context]: [ComicTapTarget.targetOf].
  static double targetOf(BuildContext context) =>
      ComicTapTarget.targetOf(context);

  /// Single-line editor height.
  static const double field = 48;

  /// Minimum multiline editor height.
  static const double area = 92;

  /// Width at which panel tiers become the desktop page.
  static const double desktop = 1024;

  /// Phone page margin.
  static const double margin = 16;
}
