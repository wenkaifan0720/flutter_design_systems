// Reduce Motion, whichever platform asks for it (ui_core's
// designReduceMotionOf): on iOS Flutter sets only dart:ui's
// AccessibilityFeatures.reduceMotion, never MediaQuery's disableAnimations,
// and Civic still calms. A colour or opacity change becomes a short fade
// (settled within 150 ms), a move stays as it was (Civic's springs are
// critically damped already: nothing of Civic's bounces), and a dialog is
// up within 150 ms.
// ignore_for_file: avoid_relative_lib_imports
import 'dart:async';

import 'package:civic_ui/civic_ui.dart';
import 'package:civic_ui/src/civic/internal/spring.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import '../example/lib/kit_gallery/kit.dart';

/// iOS's Reduce Motion alone: MediaQuery's disableAnimations stays false.
const _iosReduceMotion = FakeAccessibilityFeatures(reduceMotion: true);

/// A [CivicSpringValue] sent from 0 to 1 on Civic's state spring, read [at]
/// after it starts.
Future<double> _springAfter(
  WidgetTester tester,
  Duration at, {
  required bool effects,
}) async {
  await tester.pumpWidget(const SizedBox());
  var value = 0.0;
  var seen = 0.0;
  late StateSetter change;
  await tester.pumpWidget(
    kitApp(
      brightness: Brightness.light,
      home: StatefulBuilder(
        builder: (context, setState) {
          change = setState;
          return CivicSpringValue(
            value: value,
            effects: effects,
            builder: (context, v, _) {
              seen = v;
              return const SizedBox();
            },
          );
        },
      ),
    ),
  );
  change(() => value = 1);
  await tester.pump();
  await tester.pump(at);
  final read = seen;
  await tester.pumpAndSettle();
  expect(seen, closeTo(1, 1e-3));
  return read;
}

/// How far a dialog opened by [showCivicDialog] has come up 150 ms after
/// it opens (its route's animation, which the scrim and, under Reduce
/// Motion, the dialog's fade follow).
Future<double> _dialogAt150(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  final page = GlobalKey();
  await tester.pumpWidget(
    kitApp(
      brightness: Brightness.light,
      home: SizedBox(key: page),
    ),
  );
  late ModalRoute<Object?> route;
  unawaited(
    showCivicDialog<void>(
      context: page.currentContext!,
      builder: (context) {
        route = ModalRoute.of(context)!;
        return const SizedBox();
      },
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 150));
  final shown = route.animation!.value;
  route.navigator!.pop();
  await tester.pumpAndSettle();
  return shown;
}

void main() {
  testWidgets("iOS's Reduce Motion alone turns a Civic fade into a short one, "
      'settled within 150 ms', (tester) async {
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    const at = Duration(milliseconds: 150);
    final usual = await _springAfter(tester, at, effects: true);
    tester.platformDispatcher.accessibilityFeaturesTestValue = _iosReduceMotion;
    final calmed = await _springAfter(tester, at, effects: true);
    expect(usual, lessThan(0.99), reason: 'Civic fades slower by default');
    expect(calmed, closeTo(1, 0.01), reason: 'a short fade under it');
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

  testWidgets("under iOS's Reduce Motion a move is as it was: Civic's "
      'springs never overshoot', (tester) async {
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    const at = Duration(milliseconds: 60);
    final usual = await _springAfter(tester, at, effects: false);
    tester.platformDispatcher.accessibilityFeaturesTestValue = _iosReduceMotion;
    final calmed = await _springAfter(tester, at, effects: false);
    expect(usual, inExclusiveRange(0, 1));
    expect(calmed, closeTo(usual, 1e-9));
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

  testWidgets("a dialog is up within 150 ms under Reduce Motion, iOS's "
      "alone or Android's; its scrim comes up on a spring otherwise", (
    tester,
  ) async {
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    expect(await _dialogAt150(tester), lessThan(0.99), reason: 'a spring');
    tester.platformDispatcher.accessibilityFeaturesTestValue = _iosReduceMotion;
    expect(await _dialogAt150(tester), closeTo(1, 0.01), reason: 'iOS');
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    expect(await _dialogAt150(tester), closeTo(1, 0.01), reason: 'Android');
  });
}
