import 'dart:math' as math;

import 'package:material_ui/material_ui.dart' show Theme;
import 'package:flutter/widgets.dart';

import 'package:ui_core/ui_core.dart';

/// Shared hit-target minima for desktop chrome, controls and kit composites.
///
/// ```dart
/// SizedBox(height: RetroDesktopChromeMetrics.targetOf(context))
/// ```
abstract final class RetroDesktopChromeMetrics {
  /// The least height a control reaches under a pointer: the look's press
  /// height on a desk, round its 38 px faces. Across, a desk control reaches
  /// the pointer's floor (`RawTapTargets`, 24).
  static const double target = 40;

  /// ui_core's default touch floor (`RawTapTargets.fallback`), 40. An app's `RawTapTargetScope` may raise
  /// the floor, so a reach reads the one in effect: [targetOf], or `RawTapTargets.of(context).touch`.
  @Deprecated(
    'Read the floor in effect: RawTapTargets.of(context).touch, or targetOf. '
    'This is only the default, which an app may raise.',
  )
  static double get touchTarget => RawTapTargets.fallback.touch.height;

  /// Whether a finger reaches the controls at [context]: by the app's
  /// `RawTapTargets` input, else the platform the look's host keeps.
  static bool touchOf(BuildContext context) =>
      RawTapTargets.of(context).inputOn(Theme.of(context).platform) ==
      RawInput.touch;

  /// The least a control reaches at [context]: the finger's floor in effect
  /// where a finger reaches the controls, else the desk's [target] (never
  /// under the pointer's floor in effect).
  static double targetOf(BuildContext context) {
    final floors = RawTapTargets.of(context);
    return touchOf(context)
        ? floors.touch.height
        : math.max(target, floors.pointer.height);
  }
}
