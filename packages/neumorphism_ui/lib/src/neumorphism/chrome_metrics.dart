import 'package:flutter/foundation.dart';

/// Shared chrome measurements. Faces keep their size inside these hit targets.
abstract final class NeumorphicChromeMetrics {
  /// The least pointer target in logical pixels.
  static const double target = 44;

  /// The least touch target in logical pixels.
  static const double touchTarget = 48;

  /// Whether the current platform convention calls for finger padding.
  static bool get padded => switch (defaultTargetPlatform) {
    TargetPlatform.android ||
    TargetPlatform.iOS ||
    TargetPlatform.fuchsia => true,
    _ => false,
  };

  /// The least target, independent of the visual face size: a finger's 48 on every platform. A control's box is the
  /// same size wherever it runs, so a row of controls lines up on a desktop as it does on a phone (ui_core's alignment
  /// contract: no control changes size or place with the platform). A pointer's [target] fits inside it.
  static double get targetSize => touchTarget;
}
