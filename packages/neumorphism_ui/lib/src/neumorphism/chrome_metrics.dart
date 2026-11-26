import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import 'theme.dart';

/// Shared chrome measurements. Faces keep their size inside these hit targets.
abstract final class NeumorphicChromeMetrics {
  /// The least pointer target in logical pixels: ui_core's default touch floor, which every control stands at.
  @Deprecated(
    'Read the floor in effect: NeumorphicChromeMetrics.targetOf(context). Every control lays out at the touch floor.',
  )
  static double get target => RawTapTargets.fallback.touch.height;

  /// The least touch target in logical pixels: ui_core's default touch floor.
  @Deprecated(
    'Read the floor in effect: NeumorphicChromeMetrics.targetOf(context), or RawTapTargets.of(context).touch. This is '
    'only the default, which an app may raise.',
  )
  static double get touchTarget => RawTapTargets.fallback.touch.height;

  /// Whether the platform's convention calls for finger padding.
  @Deprecated(
    'The floor follows the input, not the platform: RawTapTargets.of(context).inputOn(). Every Neumorphism control '
    'stands at the touch floor wherever it runs.',
  )
  static bool get padded => switch (defaultTargetPlatform) {
    TargetPlatform.android ||
    TargetPlatform.iOS ||
    TargetPlatform.fuchsia => true,
    _ => false,
  };

  /// The default least target: ui_core's touch floor.
  @Deprecated(
    'Read the floor in effect: NeumorphicChromeMetrics.targetOf(context). This is only the default, which an app may '
    'raise.',
  )
  static double get targetSize => RawTapTargets.fallback.touch.height;

  /// The least target at [context], whatever the visual face's size: the touch floor in effect
  /// (`RawTapTargets.of(context).touch`, ui_core's 40 by 40 unless the app declares its own). Every control lays out
  /// at it on every platform, so its box is the same size wherever it runs and a row of controls lines up on a desktop
  /// as it does on a phone (ui_core's alignment contract: no control changes size or place with the platform). A
  /// pointer's floor fits inside it.
  static Size targetOf(BuildContext context) => RawTapTargets.of(context).touch;

  /// The height a medium control stands at in a line at [context]: the density's control height (48 at the standard
  /// density, 44 comfortable, 40 compact), never under the touch floor. A medium button, a field, a select, a switch
  /// row, a check row, a list row, a number field and a medium round key take it, so the controls that share a line
  /// share one height.
  static double lineOf(BuildContext context) => math.max(
    NeumorphicTheme.of(context).density.height(48),
    targetOf(context).height,
  );
}
