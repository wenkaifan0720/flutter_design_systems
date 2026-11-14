import 'package:material_ui/material_ui.dart' show Theme;
import 'package:flutter/widgets.dart';

/// Shared hit-target minima for desktop chrome, controls and kit composites.
///
/// ```dart
/// SizedBox(height: RetroDesktopChromeMetrics.targetOf(context))
/// ```
abstract final class RetroDesktopChromeMetrics {
  /// The minimum extent of a desktop target.
  static const double target = 44;

  /// The minimum extent where the host platform uses touch.
  static const double touchTarget = 48;

  /// Selects a minimum from the platform preserved by the look's host bridge.
  static double targetOf(BuildContext context) =>
      switch (Theme.of(context).platform) {
        TargetPlatform.android ||
        TargetPlatform.iOS ||
        TargetPlatform.fuchsia => touchTarget,
        _ => target,
      };
}
