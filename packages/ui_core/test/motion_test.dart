import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/ui_core.dart';

/// Material's spring tokens (ζ, k): Expressive spatial fast/default/slow,
/// effects fast/default/slow, and Standard spatial fast/default/slow, as
/// Material 3's motion spec gives them.
const List<(double, double)> _tokens = <(double, double)>[
  (0.6, 800),
  (0.8, 380),
  (0.8, 200),
  (1.0, 3800),
  (1.0, 1600),
  (1.0, 800),
  (0.9, 1400),
  (0.9, 700),
  (0.9, 300),
];

Future<DesignMotionPolicy> _policyUnder(
  WidgetTester tester, {
  required bool disableAnimations,
}) async {
  late DesignMotionPolicy policy;
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(disableAnimations: disableAnimations),
      child: Builder(
        builder: (context) {
          policy = DesignMotionPolicy.of(context);
          return const SizedBox();
        },
      ),
    ),
  );
  return policy;
}

/// Pumps 16 ms frames until [controller] settles (at most two seconds).
Future<void> _runFrames(
  WidgetTester tester,
  AnimationController controller,
) async {
  await tester.pump();
  for (var frame = 0; frame < 125 && controller.isAnimating; frame++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
  expect(controller.isAnimating, isFalse, reason: 'settled within 2 s');
}

void main() {
  test('designSpring maps (ζ, k) to mass 1, stiffness k, damping 2ζ√k', () {
    for (final (ratio, stiffness) in _tokens) {
      final spring = designSpring(dampingRatio: ratio, stiffness: stiffness);
      expect(spring.mass, 1, reason: '$ratio/$stiffness');
      expect(spring.stiffness, stiffness, reason: '$ratio/$stiffness');
      expect(
        spring.damping,
        ratio * 2 * math.sqrt(stiffness),
        reason: '$ratio/$stiffness',
      );
      // The ratio reads back exactly as the token wrote it.
      expect(
        spring.damping / (2 * math.sqrt(spring.mass * spring.stiffness)),
        closeTo(ratio, 1e-12),
      );
    }
    // One spelled out: Expressive's fast spatial spring.
    final fast = designSpring(dampingRatio: 0.6, stiffness: 800);
    expect(fast.damping, closeTo(33.941125496954285, 1e-12));
  });

  group('DesignMotionPolicy', () {
    test('runs every token as written without Reduce Motion', () {
      const policy = DesignMotionPolicy();
      for (final (ratio, stiffness) in _tokens) {
        final spatial = policy.spatial(
          dampingRatio: ratio,
          stiffness: stiffness,
        );
        expect(spatial.damping, ratio * 2 * math.sqrt(stiffness));
        final effects = policy.effects(
          dampingRatio: ratio,
          stiffness: stiffness,
        );
        expect(effects.damping, ratio * 2 * math.sqrt(stiffness));
      }
    });

    test('critically damps spatial springs under Reduce Motion', () {
      const policy = DesignMotionPolicy(reduceMotion: true);
      for (final (ratio, stiffness) in _tokens) {
        final spatial = policy.spatial(
          dampingRatio: ratio,
          stiffness: stiffness,
        );
        expect(spatial.mass, 1);
        expect(spatial.stiffness, stiffness);
        expect(spatial.damping, 2 * math.sqrt(stiffness), reason: 'ζ = 1');
      }
    });

    test('under Reduce Motion an effects spring is a short fade: no '
        'overshoot, settled within 150 ms', () {
      const policy = DesignMotionPolicy(reduceMotion: true);
      for (final (ratio, stiffness) in [
        ..._tokens,
        // A slow fade a look might write, and a bouncy colour change.
        (1.0, 200.0),
        (0.5, 300.0),
      ]) {
        final effects = policy.effects(
          dampingRatio: ratio,
          stiffness: stiffness,
        );
        final k = math.max(
          stiffness,
          DesignMotionPolicy.reducedEffectsStiffness,
        );
        expect(effects.stiffness, k, reason: '$ratio/$stiffness');
        expect(effects.damping, 2 * math.sqrt(k), reason: 'ζ = 1');
        final fade = designSpringSimulation(effects, from: 0, to: 1);
        for (var t = 0.0; t < .15; t += .005) {
          expect(fade.x(t), lessThanOrEqualTo(1), reason: 'no overshoot');
        }
        expect(fade.isDone(.15), isTrue, reason: '$ratio/$stiffness at 150 ms');
        // Not cut to an instant: one 120 Hz frame in, it is not half way.
        expect(fade.x(1 / 120), lessThan(.5), reason: 'a fade, not a cut');
      }
    });

    testWidgets('follows the platform\'s disable-animations setting', (
      tester,
    ) async {
      expect(
        await _policyUnder(tester, disableAnimations: true),
        const DesignMotionPolicy(reduceMotion: true),
      );
      expect(
        await _policyUnder(tester, disableAnimations: false),
        const DesignMotionPolicy(),
      );
    });

    testWidgets('designReduceMotionOf: Android\'s Remove animations, the '
        'web\'s prefers-reduced-motion (both flags), or iOS\'s Reduce Motion '
        'alone', (tester) async {
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      Future<bool> under({
        bool disableAnimations = false,
        bool reduceMotion = false,
      }) async {
        tester.platformDispatcher.accessibilityFeaturesTestValue =
            FakeAccessibilityFeatures(
              disableAnimations: disableAnimations,
              reduceMotion: reduceMotion,
            );
        late bool reduced;
        await tester.pumpWidget(
          MediaQuery.fromView(
            view: tester.view,
            child: Builder(
              builder: (context) {
                reduced = designReduceMotionOf(context);
                return const SizedBox();
              },
            ),
          ),
        );
        return reduced;
      }

      expect(await under(), isFalse);
      expect(await under(disableAnimations: true), isTrue, reason: 'Android');
      expect(
        await under(disableAnimations: true, reduceMotion: true),
        isTrue,
        reason: 'the web',
      );
      expect(await under(reduceMotion: true), isTrue, reason: 'iOS');
    });

    testWidgets('follows iOS\'s Reduce Motion alone, which MediaQuery does '
        'not carry, and its reader builds again as it changes', (tester) async {
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      final seen = <bool>[];
      await tester.pumpWidget(
        MediaQuery.fromView(
          view: tester.view,
          child: Builder(
            builder: (context) {
              seen.add(DesignMotionPolicy.of(context).reduceMotion);
              return const SizedBox();
            },
          ),
        ),
      );
      expect(seen, [false]);
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(reduceMotion: true);
      await tester.pump();
      expect(seen, [false, true]);
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures();
      await tester.pump();
      expect(seen, [false, true, false]);
    });

    test('equal policies share a hash; reduced and full differ', () {
      expect(
        DesignMotionPolicy(reduceMotion: DateTime.now().year > 0).hashCode,
        const DesignMotionPolicy(reduceMotion: true).hashCode,
      );
      expect(
        const DesignMotionPolicy(reduceMotion: true),
        isNot(const DesignMotionPolicy()),
      );
    });
  });

  test('the settle tolerance is a thousandth in distance, 0.1/s in speed', () {
    expect(designSpringTolerance.distance, 0.001);
    expect(designSpringTolerance.velocity, 0.1);
    // The velocity bound sits above ω₀ × distance for the stiffest token.
    expect(
      designSpringTolerance.velocity,
      greaterThan(math.sqrt(3800) * 0.001),
    );
  });

  test('a spring simulation lands exactly on its target once settled', () {
    final simulation = designSpringSimulation(
      designSpring(dampingRatio: 0.6, stiffness: 800),
      from: 0,
      to: 1,
    );
    expect(simulation.isDone(0), isFalse);
    expect(simulation.isDone(2), isTrue);
    expect(simulation.x(2), 1.0);
    expect(simulation.dx(2), 0.0);
  });

  group('springTo', () {
    testWidgets('an underdamped spring overshoots and settles exactly', (
      tester,
    ) async {
      final controller = AnimationController.unbounded(vsync: tester);
      addTearDown(controller.dispose);
      var peak = 0.0;
      controller.addListener(() => peak = math.max(peak, controller.value));
      unawaited(
        controller.springTo(1, designSpring(dampingRatio: 0.6, stiffness: 800)),
      );
      // Frame by frame: e^(−ζπ/√(1−ζ²)) ≈ 9.5 % peak overshoot at ζ = 0.6.
      await _runFrames(tester, controller);
      expect(peak, greaterThan(1.08), reason: 'ζ = 0.6 overshoots');
      expect(controller.value, 1.0);
      expect(controller.isAnimating, isFalse);
    });

    testWidgets('a critically damped spring arrives without overshoot', (
      tester,
    ) async {
      final controller = AnimationController.unbounded(vsync: tester);
      addTearDown(controller.dispose);
      var peak = 0.0;
      controller.addListener(() => peak = math.max(peak, controller.value));
      unawaited(
        controller.springTo(
          1,
          const DesignMotionPolicy(reduceMotion: true)
              .spatial(dampingRatio: 0.6, stiffness: 800),
        ),
      );
      await _runFrames(tester, controller);
      expect(peak, lessThanOrEqualTo(1.0));
      expect(controller.value, 1.0);
    });

    testWidgets('a spring retargeted mid-flight keeps its momentum', (
      tester,
    ) async {
      final controller = AnimationController.unbounded(vsync: tester);
      addTearDown(controller.dispose);
      final spring = designSpring(dampingRatio: 0.8, stiffness: 380);
      unawaited(controller.springTo(1, spring));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 48));
      final atTurn = controller.value;
      expect(controller.velocity, greaterThan(0));

      unawaited(controller.springTo(0, spring));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
      expect(
        controller.value,
        greaterThan(atTurn),
        reason: 'still carried upward by its velocity',
      );
      await tester.pumpAndSettle();
      expect(controller.value, 0.0);
    });
  });
}
