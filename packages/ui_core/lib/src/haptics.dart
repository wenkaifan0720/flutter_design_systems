/// Haptics, as one table: the moments ui_core's behaviours mark with a
/// haptic (a wheel's detent, a slider's tick, a long press that opened
/// something, a drag passing the point where letting go acts), each one
/// callback an app or a look swaps or silences.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// The haptics ui_core's behaviours play: one callback per moment; a null
/// callback plays nothing.
///
/// The default plays the platform's own: [HapticFeedback.selectionClick]
/// for a step, the platform's long-press feedback (Android's vibration, as
/// `Feedback.forLongPress` plays it; iOS's medium impact) and
/// [HapticFeedback.lightImpact] for a threshold. Platforms with no haptics
/// (desktop, the web) ignore them.
///
/// A behaviour reads the table where it plays, with [of]; a
/// [DesignHapticsScope] above it swaps the table for its subtree:
/// [DesignHaptics.silent] for none, or a table of the look's or the app's
/// own. Under flutter_test no haptic plays (the platform message has no
/// receiver); a test that checks one gives a table that records.
///
/// ```dart
/// DesignHaptics.of(context).selectionChanged?.call();
/// ```
@immutable
class DesignHaptics {
  /// A table of the given callbacks; each defaults to the platform's own.
  const DesignHaptics({
    this.selectionChanged = HapticFeedback.selectionClick,
    this.longPress = _longPress,
    this.thresholdCrossed = HapticFeedback.lightImpact,
  });

  /// A table that plays nothing.
  const DesignHaptics.silent()
    : selectionChanged = null,
      longPress = null,
      thresholdCrossed = null;

  /// A step from one value to the next: a wheel's row crossing its centre,
  /// a slider's thumb crossing a division, a rating's step while dragged.
  /// Null plays nothing.
  final VoidCallback? selectionChanged;

  /// A long press that opened something (a context menu) or lifted it
  /// (a row to reorder). Null plays nothing.
  final VoidCallback? longPress;

  /// A drag passing the point where letting go acts (a swipe row's action,
  /// a sheet's dismiss). Null plays nothing.
  final VoidCallback? thresholdCrossed;

  /// The table in force at [context]: the nearest [DesignHapticsScope]'s,
  /// else the platform's own (`const DesignHaptics()`).
  static DesignHaptics of(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<DesignHapticsScope>()
          ?.haptics ??
      const DesignHaptics();

  @override
  bool operator ==(Object other) =>
      other is DesignHaptics &&
      other.selectionChanged == selectionChanged &&
      other.longPress == longPress &&
      other.thresholdCrossed == thresholdCrossed;

  @override
  int get hashCode =>
      Object.hash(selectionChanged, longPress, thresholdCrossed);
}

// The platform's long-press feedback: Android's and Fuchsia's vibration (as
// Flutter's Feedback.forLongPress), iOS's medium impact (UIKit's context
// menus); nothing elsewhere.
void _longPress() {
  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
    case TargetPlatform.fuchsia:
      HapticFeedback.vibrate();
    case TargetPlatform.iOS:
      HapticFeedback.mediumImpact();
    case TargetPlatform.linux:
    case TargetPlatform.macOS:
    case TargetPlatform.windows:
      break;
  }
}

/// Puts [haptics] in force for [child]: the table every ui_core behaviour
/// below reads with [DesignHaptics.of].
///
/// ```dart
/// const DesignHapticsScope(haptics: DesignHaptics.silent(), child: Text('Quiet'))
/// ```
class DesignHapticsScope extends InheritedWidget {
  /// Puts [haptics] in force for [child].
  const DesignHapticsScope({
    super.key,
    required this.haptics,
    required super.child,
  });

  /// The table for the subtree.
  final DesignHaptics haptics;

  @override
  bool updateShouldNotify(DesignHapticsScope oldWidget) =>
      haptics != oldWidget.haptics;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<DesignHaptics>('haptics', haptics));
  }
}
