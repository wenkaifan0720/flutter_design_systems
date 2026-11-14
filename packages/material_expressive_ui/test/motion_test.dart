/// The motion part: w1-motion's test, with `motion.dart`, its
/// `internal/motion/` part and the generator's `emit/motion.ts`. Every
/// spring is proved from the generated tokens and against CONTRACT §2's
/// table; then the Standard override (the jar over the token DB), the
/// Standard pin, Reduce Motion, and how the springs settle.
library;

import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';
import 'package:material_expressive_ui/src/material_expressive/internal/tokens/expressive_motion_tokens.g.dart';
import 'package:material_expressive_ui/src/material_expressive/internal/tokens/standard_motion_tokens.g.dart';

/// CONTRACT §2 "Motion": (ζ, k) per scheme and key.
const Map<ExpressiveMotionScheme, Map<ExpressiveMotionKey, (double, double)>>
contract = {
  ExpressiveMotionScheme.expressive: {
    ExpressiveMotionKey.fastSpatial: (0.6, 800),
    ExpressiveMotionKey.defaultSpatial: (0.8, 380),
    ExpressiveMotionKey.slowSpatial: (0.8, 200),
    ExpressiveMotionKey.fastEffects: (1.0, 3800),
    ExpressiveMotionKey.defaultEffects: (1.0, 1600),
    ExpressiveMotionKey.slowEffects: (1.0, 800),
  },
  ExpressiveMotionScheme.standard: {
    ExpressiveMotionKey.fastSpatial: (0.9, 1400),
    ExpressiveMotionKey.defaultSpatial: (0.9, 700),
    ExpressiveMotionKey.slowSpatial: (0.9, 300),
    ExpressiveMotionKey.fastEffects: (1.0, 3800),
    ExpressiveMotionKey.defaultEffects: (1.0, 1600),
    ExpressiveMotionKey.slowEffects: (1.0, 800),
  },
};

/// The generated tokens, read straight from the token classes.
({double dampingRatio, double stiffness}) generated(
  ExpressiveMotionScheme scheme,
  ExpressiveMotionKey key,
) {
  final token = switch (scheme) {
    ExpressiveMotionScheme.expressive => ExpressiveMotionTokens.of(key),
    ExpressiveMotionScheme.standard => StandardMotionTokens.of(key),
  };
  return (dampingRatio: token.dampingRatio, stiffness: token.stiffness);
}

void expectSpring(SpringDescription spring, double ratio, double stiffness) {
  expect(spring.mass, 1);
  expect(spring.stiffness, stiffness);
  expect(spring.damping, closeTo(2 * ratio * math.sqrt(stiffness), 1e-9));
}

/// The step response 0 → 1 of [spring], sampled every millisecond until it
/// settles at the kit's tolerance: its peak and when it settled (s).
({double peak, double settled, double end}) step(SpringDescription spring) {
  final sim = designSpringSimulation(spring, from: 0, to: 1);
  var peak = 0.0;
  var t = 0.0;
  while (!sim.isDone(t)) {
    peak = math.max(peak, sim.x(t));
    t += 0.001;
    if (t > 5) fail('did not settle in 5 s');
  }
  return (peak: peak, settled: t, end: sim.x(t));
}

const keys = ExpressiveMotionKey.values;
const spatialKeys = <ExpressiveMotionKey>[
  ExpressiveMotionKey.fastSpatial,
  ExpressiveMotionKey.defaultSpatial,
  ExpressiveMotionKey.slowSpatial,
];

void main() {
  test('copyWith replaces the scheme or Reduce Motion; lerp switches at '
      'halfway', () {
    const a = ExpressiveMotion(scheme: ExpressiveMotionScheme.expressive);
    final b = a.copyWith(
      scheme: ExpressiveMotionScheme.standard,
      reduceMotion: true,
    );
    expect(b.scheme, ExpressiveMotionScheme.standard);
    expect(b.reduceMotion, isTrue);
    expect(a.copyWith(), a);
    expect(ExpressiveMotion.lerp(a, b, .4), a);
    expect(ExpressiveMotion.lerp(a, b, .6), b);
  });

  test('baseline runs the expressive scheme in both brightnesses', () {
    for (final brightness in Brightness.values) {
      final t = ExpressiveThemeData.preset('baseline', brightness);
      expect(t.motion.scheme, ExpressiveMotionScheme.expressive);
      expect(t.motion.reduceMotion, isFalse);
    }
  });

  group('every spring comes from the generated tokens', () {
    for (final scheme in ExpressiveMotionScheme.values) {
      for (final key in keys) {
        test('${scheme.name} ${key.name}', () {
          final motion = ExpressiveMotion(scheme: scheme);
          final token = generated(scheme, key);
          final (ratio, stiffness) = contract[scheme]![key]!;
          expect(token.dampingRatio, ratio);
          expect(token.stiffness, stiffness);
          expect(motion.tokenOf(key), token);
          expectSpring(motion.spring(key), ratio, stiffness);
        });
      }
    }
  });

  for (final tween in [false, true]) {
    testWidgets(
      '${tween ? "tween" : "value"} spring preserves focus on its first animation',
      (tester) async {
        final node = FocusNode();
        addTearDown(node.dispose);
        final childKey = GlobalKey();
        final child = Focus(
          key: childKey,
          focusNode: node,
          child: const SizedBox(width: 20, height: 20),
        );
        Widget at(double value) => tween
            ? ExpressiveSpringSize(
                value: Size(value, 20),
                motion: ExpressiveMotionKey.fastSpatial,
                child: child,
                builder: (context, size, child) => Transform.translate(
                  offset: Offset(size.width, 0),
                  child: child,
                ),
              )
            : ExpressiveSpringValue(
                value: value,
                motion: ExpressiveMotionKey.fastSpatial,
                child: child,
                builder: (context, value, child) =>
                    Transform.translate(offset: Offset(value, 0), child: child),
              );
        await tester.pumpWidget(at(0));
        node.requestFocus();
        await tester.pump();
        final element = tester.element(find.byKey(childKey));
        expect(node.hasFocus, isTrue);
        await tester.pumpWidget(at(100));
        await tester.pump(const Duration(milliseconds: 16));
        expect(tester.element(find.byKey(childKey)), same(element));
        expect(node.hasFocus, isTrue);
        await tester.pumpWidget(at(40));
        await tester.pumpAndSettle();
        expect(tester.element(find.byKey(childKey)), same(element));
        expect(node.hasFocus, isTrue);
        expect(tester.takeException(), isNull);
      },
    );
  }

  test('spatial(), effects() and the named springs are the keyed ones', () {
    for (final scheme in ExpressiveMotionScheme.values) {
      final m = ExpressiveMotion(scheme: scheme);
      void same(SpringDescription a, ExpressiveMotionKey key) {
        final b = m.spring(key);
        expect(
          (a.mass, a.stiffness, a.damping),
          (b.mass, b.stiffness, b.damping),
        );
      }

      same(
        m.spatial(ExpressiveMotionSpeed.fast),
        ExpressiveMotionKey.fastSpatial,
      );
      same(m.spatial(), ExpressiveMotionKey.defaultSpatial);
      same(
        m.spatial(ExpressiveMotionSpeed.slow),
        ExpressiveMotionKey.slowSpatial,
      );
      same(
        m.effects(ExpressiveMotionSpeed.fast),
        ExpressiveMotionKey.fastEffects,
      );
      same(m.effects(), ExpressiveMotionKey.defaultEffects);
      same(
        m.effects(ExpressiveMotionSpeed.slow),
        ExpressiveMotionKey.slowEffects,
      );
      same(m.fastSpatial, ExpressiveMotionKey.fastSpatial);
      same(m.defaultSpatial, ExpressiveMotionKey.defaultSpatial);
      same(m.slowSpatial, ExpressiveMotionKey.slowSpatial);
      same(m.fastEffects, ExpressiveMotionKey.fastEffects);
      same(m.defaultEffects, ExpressiveMotionKey.defaultEffects);
      same(m.slowEffects, ExpressiveMotionKey.slowEffects);
    }
    expect(keys.where(ExpressiveMotion.isSpatial).toSet(), spatialKeys.toSet());
  });

  group('the Standard override', () {
    test('standard spatial springs are Compose\'s, not the token DB\'s '
        '(which repeats the expressive ones)', () {
      const db = <ExpressiveMotionKey, (double, double)>{
        ExpressiveMotionKey.fastSpatial: (0.6, 800),
        ExpressiveMotionKey.defaultSpatial: (0.8, 380),
        ExpressiveMotionKey.slowSpatial: (0.8, 200),
      };
      for (final key in spatialKeys) {
        final standard = generated(ExpressiveMotionScheme.standard, key);
        final expressive = generated(ExpressiveMotionScheme.expressive, key);
        expect((standard.dampingRatio, standard.stiffness), isNot(db[key]));
        expect(standard.dampingRatio, 0.9);
        expect(standard.stiffness, greaterThan(expressive.stiffness));
      }
    });

    test('standard effects springs equal the expressive ones', () {
      for (final key in keys.where((k) => !ExpressiveMotion.isSpatial(k))) {
        expect(
          generated(ExpressiveMotionScheme.standard, key),
          generated(ExpressiveMotionScheme.expressive, key),
        );
      }
    });

    test('a standard spring barely overshoots; an expressive one bounces', () {
      for (final key in spatialKeys) {
        final standard = step(
          const ExpressiveMotion(scheme: ExpressiveMotionScheme.standard)
              .spring(key),
        );
        final expressive = step(
          const ExpressiveMotion(scheme: ExpressiveMotionScheme.expressive)
              .spring(key),
        );
        // ζ = 0.9 overshoots by e^(-πζ/√(1-ζ²)) ≈ 0.15 %.
        expect(standard.peak, lessThan(1.002));
        // ζ = 0.8 overshoots ≈ 1.5 %, ζ = 0.6 ≈ 9.5 %.
        expect(expressive.peak, greaterThan(1.01));
      }
    });
  });

  group('ExpressiveStandardMotion pins a subtree to Standard', () {
    Future<List<ExpressiveMotion>> read(
      WidgetTester tester, {
      required ExpressiveMotionScheme theme,
      required bool pinned,
      bool reduce = false,
    }) async {
      final seen = <ExpressiveMotion>[];
      final data = ExpressiveThemeData.preset('baseline', Brightness.light);
      Widget probe = Builder(
        builder: (context) {
          seen
            ..add(ExpressiveMotion.of(context))
            ..add(context.expressiveMotion);
          return const SizedBox.shrink();
        },
      );
      if (pinned) probe = ExpressiveStandardMotion(child: probe);
      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(disableAnimations: reduce),
          child: ExpressiveTheme(
            data: ExpressiveThemeData(
              id: data.id,
              brightness: data.brightness,
              expression: data.expression,
              colors: data.colors,
              type: data.type,
              shapes: data.shapes,
              motion: ExpressiveMotion(scheme: theme),
            ),
            child: probe,
          ),
        ),
      );
      return seen;
    }

    testWidgets('the theme\'s scheme when unpinned', (tester) async {
      for (final scheme in ExpressiveMotionScheme.values) {
        final seen = await read(tester, theme: scheme, pinned: false);
        expect(seen.map((m) => m.scheme).toSet(), {scheme});
      }
    });

    testWidgets('Standard when pinned, whatever the theme', (tester) async {
      for (final scheme in ExpressiveMotionScheme.values) {
        final seen = await read(tester, theme: scheme, pinned: true);
        expect(seen.map((m) => m.scheme).toSet(), {
          ExpressiveMotionScheme.standard,
        });
      }
    });

    testWidgets('the pin follows the subtree into captured themes', (
      tester,
    ) async {
      late BuildContext inside;
      await tester.pumpWidget(
        ExpressiveStandardMotion(
          child: Builder(
            builder: (context) {
              inside = context;
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      final captured = InheritedTheme.capture(from: inside, to: null);
      late ExpressiveMotion elsewhere;
      await tester.pumpWidget(
        captured.wrap(
          Builder(
            builder: (context) {
              elsewhere = ExpressiveMotion.of(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(elsewhere.scheme, ExpressiveMotionScheme.standard);
    });
  });

  group('Reduce Motion', () {
    for (final scheme in ExpressiveMotionScheme.values) {
      test('${scheme.name}: spatial springs critically damped at the token '
          'stiffness, effects unchanged', () {
        final reduced = ExpressiveMotion(scheme: scheme, reduceMotion: true);
        final full = ExpressiveMotion(scheme: scheme);
        for (final key in keys) {
          final token = generated(scheme, key);
          final ratio = ExpressiveMotion.isSpatial(key)
              ? 1.0
              : token.dampingRatio;
          expectSpring(reduced.spring(key), ratio, token.stiffness);
          expect(reduced.tokenOf(key), full.tokenOf(key));
          expect(step(reduced.spring(key)).peak, lessThanOrEqualTo(1));
        }
      });
    }

    testWidgets('is read from MediaQuery.disableAnimations', (tester) async {
      late ExpressiveMotion motion;
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: ExpressiveStandardMotion(
            child: Builder(
              builder: (context) {
                motion = ExpressiveMotion.of(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );
      expect(motion.reduceMotion, isTrue);
      expect(motion.scheme, ExpressiveMotionScheme.standard);
      expectSpring(motion.fastSpatial, 1, 1400);
    });
  });

  group('settling', () {
    for (final scheme in ExpressiveMotionScheme.values) {
      test('${scheme.name}: every spring lands exactly on its target, '
          'fast before default before slow', () {
        final m = ExpressiveMotion(scheme: scheme);
        for (final kind in [
          [m.fastSpatial, m.defaultSpatial, m.slowSpatial],
          [m.fastEffects, m.defaultEffects, m.slowEffects],
        ]) {
          final times = <double>[];
          for (final spring in kind) {
            final r = step(spring);
            expect(r.end, 1);
            expect(r.settled, lessThan(1.5));
            times.add(r.settled);
          }
          expect(times[0], lessThan(times[1]));
          expect(times[1], lessThan(times[2]));
        }
      });
    }

    testWidgets('ExpressiveSpringValue overshoots, then settles exactly', (
      tester,
    ) async {
      final values = <double>[];
      Widget at(double v) => ExpressiveSpringValue(
        value: v,
        motion: ExpressiveMotionKey.fastSpatial,
        builder: (context, value, _) {
          values.add(value);
          return const SizedBox.shrink();
        },
      );
      await tester.pumpWidget(at(0));
      expect(values, [0]);
      await tester.pumpWidget(at(100));
      await tester.pumpAndSettle(const Duration(milliseconds: 4));
      expect(values.reduce(math.max), greaterThan(105));
      expect(values.last, 100);
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('ExpressiveSpringValue retargeted mid-flight keeps momentum', (
      tester,
    ) async {
      final values = <double>[];
      Widget at(double v) => ExpressiveSpringValue(
        value: v,
        motion: ExpressiveMotionKey.defaultSpatial,
        builder: (context, value, _) {
          values.add(value);
          return const SizedBox.shrink();
        },
      );
      await tester.pumpWidget(at(0));
      await tester.pumpWidget(at(100));
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump(const Duration(milliseconds: 16));
      final before = values.last;
      await tester.pumpWidget(at(200));
      await tester.pump(const Duration(milliseconds: 16));
      expect(values.last, greaterThan(before));
      await tester.pumpAndSettle(const Duration(milliseconds: 4));
      expect(values.last, 200);
    });

    testWidgets('under Reduce Motion a spatial helper never overshoots', (
      tester,
    ) async {
      final values = <double>[];
      Widget at(double v) => MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: ExpressiveSpringValue(
          value: v,
          motion: ExpressiveMotionKey.fastSpatial,
          builder: (context, value, _) {
            values.add(value);
            return const SizedBox.shrink();
          },
        ),
      );
      await tester.pumpWidget(at(0));
      await tester.pumpWidget(at(100));
      await tester.pumpAndSettle(const Duration(milliseconds: 4));
      expect(values.reduce(math.max), 100);
      expect(values.last, 100);
    });

    testWidgets('colour, size and shape helpers spring and settle exactly', (
      tester,
    ) async {
      const a = Color(0xFF000000);
      const b = Color(0xFFFFFFFF);
      final colors = <Color>[];
      final sizes = <Size>[];
      final shapes = <ShapeBorder>[];
      final r8 = RoundedRectangleBorder(borderRadius: BorderRadius.circular(8));
      final r28 = RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
      );
      Widget at(bool on) => Column(
        children: [
          ExpressiveSpringColor(
            value: on ? b : a,
            motion: ExpressiveMotionKey.defaultEffects,
            builder: (context, value, _) {
              colors.add(value);
              return const SizedBox.shrink();
            },
          ),
          ExpressiveSpringSize(
            value: on ? const Size(80, 40) : const Size(40, 40),
            motion: ExpressiveMotionKey.fastSpatial,
            builder: (context, value, _) {
              sizes.add(value);
              return const SizedBox.shrink();
            },
          ),
          ExpressiveSpringShape(
            value: on ? r28 : r8,
            motion: ExpressiveMotionKey.fastSpatial,
            builder: (context, value, _) {
              shapes.add(value);
              return const SizedBox.shrink();
            },
          ),
        ],
      );
      await tester.pumpWidget(
        Directionality(textDirection: TextDirection.ltr, child: at(false)),
      );
      await tester.pumpWidget(
        Directionality(textDirection: TextDirection.ltr, child: at(true)),
      );
      await tester.pump(const Duration(milliseconds: 16));
      expect(colors.last, isNot(a));
      expect(colors.last, isNot(b));
      await tester.pumpAndSettle(const Duration(milliseconds: 4));
      expect(colors.last, b);
      expect(sizes.map((s) => s.width).reduce(math.max), greaterThan(80));
      expect(sizes.last, const Size(80, 40));
      expect(shapes.last, r28);
      expect(tester.hasRunningAnimations, isFalse);
    });
  });
}
