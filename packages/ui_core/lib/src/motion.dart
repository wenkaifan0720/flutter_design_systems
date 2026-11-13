/// Springs: the one mapping from a spring token (damping ratio ζ,
/// stiffness k) to Flutter's physics, the Reduce Motion policy, and a
/// controller helper that runs a spring.
///
/// Motion is springs only. Nothing in this API takes a duration or an
/// easing curve: a system's motion tokens are (ζ, k) pairs — Material's come
/// from Compose's `ExpressiveMotionTokens` / `StandardMotionTokens` — and a
/// component runs them through [designSpring], [DesignMotionPolicy] and
/// [DesignSpringDrive.springTo].
library;

import 'package:flutter/physics.dart' show SpringSimulation, Tolerance;
import 'package:flutter/widgets.dart';

/// The Flutter spring for the token (ζ = [dampingRatio], k = [stiffness]):
/// `SpringDescription.withDampingRatio(mass: 1, stiffness: k, ratio: ζ)`,
/// so damping = 2ζ√k. Compose's `spring(dampingRatio, stiffness)` is
/// written against unit mass, so the two run the same curve.
SpringDescription designSpring({
  required double dampingRatio,
  required double stiffness,
}) => SpringDescription.withDampingRatio(
  mass: 1,
  stiffness: stiffness,
  ratio: dampingRatio,
);

/// The Reduce Motion policy: which spring a component actually runs.
///
/// Under Reduce Motion ([MediaQuery.disableAnimationsOf]) every SPATIAL
/// spring — one that moves, resizes or reshapes something — is critically
/// damped: ζ = 1 at the token's stiffness, so nothing overshoots or
/// bounces and it still arrives on the token's timescale. EFFECTS springs
/// (opacity, colour) run unchanged; Material's are critically damped
/// already.
///
/// ```dart
/// controller.springTo(1, DesignMotionPolicy.of(context).spatial(dampingRatio: 0.6, stiffness: 800))
/// ```
@immutable
class DesignMotionPolicy {
  /// Creates a [DesignMotionPolicy].
  const DesignMotionPolicy({this.reduceMotion = false});

  /// The policy in force at [context]: Reduce Motion when the platform asks
  /// animations to be disabled.
  factory DesignMotionPolicy.of(BuildContext context) => DesignMotionPolicy(
    reduceMotion: MediaQuery.maybeDisableAnimationsOf(context) ?? false,
  );

  /// Whether the reader asked for reduced motion.
  final bool reduceMotion;

  /// The spring a spatial token (ζ, k) runs under this policy: the token's
  /// own, or critically damped (ζ = 1, same k) under Reduce Motion.
  SpringDescription spatial({
    required double dampingRatio,
    required double stiffness,
  }) => designSpring(
    dampingRatio: reduceMotion ? 1 : dampingRatio,
    stiffness: stiffness,
  );

  /// The spring an effects token (ζ, k) runs: the token's own, under any
  /// policy.
  SpringDescription effects({
    required double dampingRatio,
    required double stiffness,
  }) => designSpring(dampingRatio: dampingRatio, stiffness: stiffness);

  @override
  bool operator ==(Object other) =>
      other is DesignMotionPolicy && other.reduceMotion == reduceMotion;

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
const Tolerance designSpringTolerance = Tolerance(
  distance: 0.001,
  velocity: 0.1,
);

/// The simulation of [spring] from [from] to [to], starting at [velocity]
/// units per second, that settles at [tolerance] and lands exactly on [to].
SpringSimulation designSpringSimulation(
  SpringDescription spring, {
  required double from,
  required double to,
  double velocity = 0,
  Tolerance tolerance = designSpringTolerance,
}) => SpringSimulation(
  spring,
  from,
  to,
  velocity,
  tolerance: tolerance,
  snapToEnd: true,
);

/// Runs an [AnimationController] on a spring instead of a duration.
extension DesignSpringDrive on AnimationController {
  /// Drives the controller from its current value to [target] on
  /// [spring] (`animateWith(SpringSimulation)`), settling at [tolerance]
  /// ([designSpringTolerance]) exactly on [target]. [velocity] defaults to the
  /// controller's own, so a spring retargeted mid-flight keeps its
  /// momentum.
  ///
  /// Use an unbounded controller (`AnimationController.unbounded`) for an
  /// underdamped spring: a bounded one clamps the overshoot at its bounds.
  TickerFuture springTo(
    double target,
    SpringDescription spring, {
    double? velocity,
    Tolerance tolerance = designSpringTolerance,
  }) => animateWith(
    designSpringSimulation(
      spring,
      from: value,
      to: target,
      velocity: velocity ?? this.velocity,
      tolerance: tolerance,
    ),
  );
}
