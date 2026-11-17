/// iOS's Reduce Motion alone calms Expressive. Flutter 3.47 puts it in
/// dart:ui's `AccessibilityFeatures.reduceMotion`, not in
/// `MediaQuery.disableAnimations` (Android's and the web's), so every test
/// here sets only the iOS flag, under a MediaQuery that allows animations.
/// It is read through ui_core's `designReduceMotionOf`, and a change of it
/// comes as a build, so the parts that loop (the loading and progress
/// indicators, the skeleton's pulse) read it as they build and follow it
/// both ways while shown.
library;

import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';
import 'package:material_expressive_ui/material_expressive_host.dart';

Widget _app(Widget child) => ExpressiveHost(
  light: ExpressiveThemeData.preset('baseline', Brightness.light),
  brightness: Brightness.light,
  child: Directionality(
    textDirection: TextDirection.ltr,
    // Animations allowed as far as MediaQuery knows.
    child: MediaQuery(
      data: const MediaQueryData(),
      child: Center(child: child),
    ),
  ),
);

/// Sets iOS's Reduce Motion, and only it; cleared after the test.
void _iosReduceMotion(WidgetTester tester, bool on) {
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      FakeAccessibilityFeatures(reduceMotion: on);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
}

/// Whether anything still ticks a frame on.
Future<bool> _moving(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 16));
  await tester.pump(const Duration(milliseconds: 16));
  return tester.binding.transientCallbackCount > 0;
}

void main() {
  testWidgets("ExpressiveMotion reads iOS's Reduce Motion alone, and follows "
      'it as it changes', (tester) async {
    final seen = <bool>[];
    _iosReduceMotion(tester, true);
    await tester.pumpWidget(
      _app(
        Builder(
          builder: (context) {
            seen.add(ExpressiveMotion.of(context).reduceMotion);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    expect(seen.last, isTrue);
    _iosReduceMotion(tester, false);
    await tester.pump();
    expect(seen.last, isFalse, reason: 'not built again when it changed');
  });

  testWidgets("a spatial spring calms under iOS's Reduce Motion alone: no "
      'overshoot, and the bounce back once it is off', (tester) async {
    final values = <double>[];
    Widget at(double v) => _app(
      ExpressiveSpringValue(
        value: v,
        motion: ExpressiveMotionKey.fastSpatial,
        builder: (context, value, _) {
          values.add(value);
          return const SizedBox.shrink();
        },
      ),
    );
    _iosReduceMotion(tester, true);
    await tester.pumpWidget(at(0));
    await tester.pumpWidget(at(100));
    await tester.pumpAndSettle(const Duration(milliseconds: 4));
    expect(values.reduce(math.max), 100, reason: 'it overshot');
    expect(values.last, 100);

    _iosReduceMotion(tester, false);
    await tester.pumpWidget(at(0));
    await tester.pumpAndSettle(const Duration(milliseconds: 4));
    values.clear();
    await tester.pumpWidget(at(100));
    await tester.pumpAndSettle(const Duration(milliseconds: 4));
    expect(values.reduce(math.max), greaterThan(100), reason: 'no bounce');
    expect(values.last, 100);
  });

  for (final (name, widget) in <(String, Widget)>[
    ('loading indicator', const ExpressiveLoadingIndicator()),
    (
      'circular progress indicator',
      const ExpressiveCircularProgressIndicator(),
    ),
    ('linear progress indicator', const ExpressiveLinearProgressIndicator()),
    ("skeleton's pulse", const ExpressiveSkeleton(width: 120, height: 24)),
  ]) {
    testWidgets("an indeterminate $name holds still under iOS's Reduce "
        'Motion alone, and follows it both ways while shown', (tester) async {
      _iosReduceMotion(tester, true);
      await tester.pumpWidget(_app(widget));
      expect(
        await _moving(tester),
        isFalse,
        reason:
            'it moves under Reduce '
            'Motion',
      );
      _iosReduceMotion(tester, false);
      expect(await _moving(tester), isTrue, reason: 'still once it is off');
      _iosReduceMotion(tester, true);
      expect(
        await _moving(tester),
        isFalse,
        reason:
            'it kept moving once '
            'Reduce Motion came on',
      );
    });
  }
}
