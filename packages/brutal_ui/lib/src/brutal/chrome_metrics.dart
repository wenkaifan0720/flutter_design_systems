import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import 'theme.dart';

/// Brutal's page and control measures in one place, for a page or a kit
/// that lays its own things out beside the parts: the tap floors, a field's
/// height, the reading column and the widths the layout turns at.
///
/// ```dart
/// SizedBox(height: BrutalChromeMetrics.field, child: child)
/// ```
abstract final class BrutalChromeMetrics {
  /// The least area a pointer's click reaches.
  static const double pointerTarget = 24;

  /// The least area a finger's tap reaches.
  static const double touchTarget = 48;

  /// The floor in effect at [context]: the finger's or the pointer's, by
  /// what reaches the controls there.
  static double targetOf(BuildContext context) =>
      RawTapTargets.of(context).floorOn().shortestSide;

  /// A one-line field's box, and every control's height at the standard
  /// density.
  static const double field = BrutalMetrics.controlHeight;

  /// The widest a form, a dialog or a reading column stands.
  static const double readingWidth = BrutalMetrics.readingWidth;

  /// The width from which a page lays out as a tablet's: a rail of places,
  /// a framed sheet.
  static const double tablet = 600;

  /// The width from which a page lays out as a desktop's: a side bar of
  /// places, columns side by side.
  static const double desktop = 1024;

  /// The page margin for a window [width] wide: 16 on a phone, 24 on a
  /// tablet, 32 on a desktop.
  static double margin(double width) => BrutalSpacing.pageMargin(width);
}
