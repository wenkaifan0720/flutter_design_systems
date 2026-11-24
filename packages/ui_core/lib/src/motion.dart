/// Springs: the one mapping from a spring token (damping ratio ζ,
/// stiffness k) to Flutter's physics, the Reduce Motion policy, and a
/// controller helper that runs a spring.
///
/// Motion is springs only. Nothing in this API takes a duration or an
/// easing curve: a system's motion tokens are (ζ, k) pairs — Material's come
/// from Compose's `ExpressiveMotionTokens` / `StandardMotionTokens` — and a
/// component runs them through [rawSpring], [RawMotionPolicy] and
/// [RawSpringDrive.springTo]. Whether the reader asked for reduced
/// motion is one read, [rawReduceMotionOf], whichever platform asked.
library;

import 'package:flutter/physics.dart' show SpringSimulation, Tolerance;
import 'package:flutter/scheduler.dart' show SchedulerBinding, SchedulerPhase;
import 'package:flutter/widgets.dart';

/// Whether the reader asked for reduced motion at [context]: Android's
/// Remove animations or the web's prefers-reduced-motion
/// ([MediaQuery.disableAnimationsOf]), or iOS's Reduce Motion (dart:ui's
/// `AccessibilityFeatures.reduceMotion`, which MediaQuery does not carry).
///
/// [context] builds again when either changes. A change of iOS's comes as a
/// build, not as `didChangeDependencies`, so a State reads it in `build` or
/// as it acts, not once in `didChangeDependencies`.
///
/// ```dart
/// rawReduceMotionOf(context) ? Duration.zero : const Duration(milliseconds: 200)
/// ```
bool rawReduceMotionOf(BuildContext context) {
  // Both read, so [context] hears either change.
  final disabled = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
  final reduced = _PlatformReduceMotion.of(context);
  return disabled || reduced;
}

// iOS's Reduce Motion: MediaQuery's data has no field for it, so MediaQuery
// tells no one when it alone changes. Read from the platform; each context
// that read it is built again when it changes.
final class _PlatformReduceMotion with WidgetsBindingObserver {
  _PlatformReduceMotion._() : _value = _read() {
    WidgetsBinding.instance.addObserver(this);
  }

  static _PlatformReduceMotion? _instance;

  static bool of(BuildContext context) {
    final watcher = _instance ??= _PlatformReduceMotion._();
    if (context is Element) watcher._add(context);
    return _read();
  }

  static bool _read() => WidgetsBinding
      .instance
      .platformDispatcher
      .accessibilityFeatures
      .reduceMotion;

  bool _value;
  final List<WeakReference<Element>> _readers = [];
  final Expando<bool> _reading = Expando();
  int _pruneAt = 64;

  void _add(Element element) {
    if (_reading[element] ?? false) return;
    _reading[element] = true;
    if (_readers.length >= _pruneAt) {
      _readers.removeWhere(_gone);
      _pruneAt = _readers.length < 32 ? 64 : _readers.length * 2;
    }
    _readers.add(WeakReference(element));
  }

  static bool _gone(WeakReference<Element> reader) =>
      !(reader.target?.mounted ?? false);

  @override
  void didChangeAccessibilityFeatures() {
    final value = _read();
    if (value == _value) return;
    _value = value;
    // Mid-build an element may be marked only under the one building.
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) => _rebuild());
    } else {
      _rebuild();
    }
  }

  void _rebuild() {
    _readers.removeWhere(_gone);
    for (final reader in _readers) {
      reader.target?.markNeedsBuild();
    }
  }
}

/// The Flutter spring for the token (ζ = [dampingRatio], k = [stiffness]):
/// `SpringDescription.withDampingRatio(mass: 1, stiffness: k, ratio: ζ)`,
/// so damping = 2ζ√k. Compose's `spring(dampingRatio, stiffness)` is
/// written against unit mass, so the two run the same curve.
SpringDescription rawSpring({
  required double dampingRatio,
  required double stiffness,
}) => SpringDescription.withDampingRatio(
  mass: 1,
  stiffness: stiffness,
  ratio: dampingRatio,
);

/// The Reduce Motion policy: which spring a component actually runs.
///
/// Under Reduce Motion ([rawReduceMotionOf]) every SPATIAL
/// spring — one that moves, resizes or reshapes something — is critically
/// damped: ζ = 1 at the token's stiffness, so nothing overshoots or
/// bounces and it still arrives on the token's timescale. EFFECTS springs
/// (opacity, colour) become a short fade: critically damped at no less than
/// [reducedEffectsStiffness], so a fade or a colour change settles within
/// 150 ms and nothing lingers, without being cut to an instant change (an
/// instant change reads as a flash). A token already faster keeps its
/// stiffness.
///
/// ```dart
/// controller.springTo(1, RawMotionPolicy.of(context).spatial(dampingRatio: 0.6, stiffness: 800))
/// ```
@immutable
class RawMotionPolicy {
  /// Creates a [RawMotionPolicy].
  const RawMotionPolicy({this.reduceMotion = false});

  /// The policy in force at [context]: Reduce Motion when the reader asked
  /// for it, on any platform ([rawReduceMotionOf]); [context] builds again
  /// when that changes.
  factory RawMotionPolicy.of(BuildContext context) =>
      RawMotionPolicy(reduceMotion: rawReduceMotionOf(context));

  /// Whether the reader asked for reduced motion.
  final bool reduceMotion;

  /// The spring a spatial token (ζ, k) runs under this policy: the token's
  /// own, or critically damped (ζ = 1, same k) under Reduce Motion.
  SpringDescription spatial({
    required double dampingRatio,
    required double stiffness,
  }) => rawSpring(
    dampingRatio: reduceMotion ? 1 : dampingRatio,
    stiffness: stiffness,
  );

  /// The least stiffness an effects spring runs at under Reduce Motion:
  /// critically damped at k = 3800 (Material's fastest effects token), a
  /// spring settles within [rawSpringTolerance] in 150 ms.
  static const double reducedEffectsStiffness = 3800;

  /// The spring an effects token (ζ, k) runs under this policy: the token's
  /// own, or under Reduce Motion a short fade, critically damped (ζ = 1) at
  /// k or [reducedEffectsStiffness], whichever is stiffer.
  SpringDescription effects({
    required double dampingRatio,
    required double stiffness,
  }) => reduceMotion
      ? rawSpring(
          dampingRatio: 1,
          stiffness: stiffness > reducedEffectsStiffness
              ? stiffness
              : reducedEffectsStiffness,
        )
      : rawSpring(dampingRatio: dampingRatio, stiffness: stiffness);

  @override
  bool operator ==(Object other) =>
      other is RawMotionPolicy && other.reduceMotion == reduceMotion;

  @override
  int get hashCode => reduceMotion.hashCode;
}

/// When a spring-driven controller counts as settled, in the controller's
/// own units (a 0–1 progress, or dp for a position):
///
/// - distance 0.001 — within a thousandth of the target: under a pixel for
///   any travel up to 1000 dp on a progress controller;
/// - velocity 0.1 units/s — above ω₀ × 0.001 for every Material spring
///   (ω₀ = √k ≤ 62 rad/s at k = 3800), so once a spring's swing is inside
///   the distance bound the velocity bound already holds; it exists so an
///   underdamped spring crossing the target at speed is not taken as
///   settled.
///
/// On settling the controller lands exactly on the target
/// ([SpringSimulation]'s `snapToEnd`).
const Tolerance rawSpringTolerance = Tolerance(distance: 0.001, velocity: 0.1);

/// The simulation of [spring] from [from] to [to], starting at [velocity]
/// units per second, that settles at [tolerance] and lands exactly on [to].
SpringSimulation rawSpringSimulation(
  SpringDescription spring, {
  required double from,
  required double to,
  double velocity = 0,
  Tolerance tolerance = rawSpringTolerance,
}) => SpringSimulation(
  spring,
  from,
  to,
  velocity,
  tolerance: tolerance,
  snapToEnd: true,
);

/// Runs an [AnimationController] on a spring instead of a duration.
extension RawSpringDrive on AnimationController {
  /// Drives the controller from its current value to [target] on
  /// [spring] (`animateWith(SpringSimulation)`), settling at [tolerance]
  /// ([rawSpringTolerance]) exactly on [target]. [velocity] defaults to the
  /// controller's own, so a spring retargeted mid-flight keeps its
  /// momentum.
  ///
  /// Use an unbounded controller (`AnimationController.unbounded`) for an
  /// underdamped spring: a bounded one clamps the overshoot at its bounds.
  TickerFuture springTo(
    double target,
    SpringDescription spring, {
    double? velocity,
    Tolerance tolerance = rawSpringTolerance,
  }) => animateWith(
    rawSpringSimulation(
      spring,
      from: value,
      to: target,
      velocity: velocity ?? this.velocity,
      tolerance: tolerance,
    ),
  );
}
