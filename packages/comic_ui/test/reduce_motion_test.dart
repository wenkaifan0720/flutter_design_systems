// iOS's Reduce Motion alone. Flutter 3.47 sets only dart:ui's reduceMotion there, never MediaQuery's
// disableAnimations. Comic's motion reads ui_core's rawReduceMotionOf, so its cuts, its loops and its presses calm
// with that flag alone, and a flip while a loop runs reaches the loop as a build.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:comic_ui/comic_ui.dart';

import 'support.dart';

/// Sets iOS's Reduce Motion, and only it, for the rest of the test.
void _iosReduceMotion(WidgetTester tester, bool on) {
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      FakeAccessibilityFeatures(reduceMotion: on);
}

void main() {
  testWidgets('with only iOS\'s flag, every motion token is a cut', (
    tester,
  ) async {
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    _iosReduceMotion(tester, true);
    late BuildContext context;
    await tester.pumpWidget(
      comicApp(
        Builder(
          builder: (c) {
            context = c;
            return const SizedBox();
          },
        ),
      ),
    );
    expect(MediaQuery.disableAnimationsOf(context), isFalse);
    expect(ComicMotion.of(context), ComicMotion.still);
    expect(
      ComicMotion.durationOf(context, const Duration(seconds: 1)),
      Duration.zero,
    );
  });

  for (final (name, part) in const <(String, Widget)>[
    ('the progress burst', ComicCircularProgressIndicator()),
    ('the progress bar', ComicLinearProgressIndicator()),
    ('the skeleton', ComicSkeleton(width: 120)),
  ]) {
    testWidgets(
      '$name stops as iOS\'s Reduce Motion turns on and runs as it turns off',
      (tester) async {
        addTearDown(
          tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
        );
        await tester.pumpWidget(comicApp(Center(child: part)));
        expect(tester.hasRunningAnimations, isTrue);
        _iosReduceMotion(tester, true);
        await tester.pump();
        expect(tester.hasRunningAnimations, isFalse);
        _iosReduceMotion(tester, false);
        await tester.pump();
        expect(tester.hasRunningAnimations, isTrue);
      },
    );
  }

  for (final reduced in const [false, true]) {
    testWidgets(
      'a press ${reduced ? 'lands at once' : 'eases in'} with iOS\'s flag ${reduced ? 'on' : 'off'}',
      (tester) async {
        addTearDown(
          tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
        );
        _iosReduceMotion(tester, reduced);
        await tester.pumpWidget(
          comicApp(Center(child: ComicButton.filled('Go', onPressed: () {}))),
        );
        final press = await tester.startGesture(
          tester.getCenter(find.byType(ComicButton)),
        );
        await tester.pump();
        expect(tester.hasRunningAnimations, !reduced);
        await press.up();
        await tester.pumpAndSettle();
      },
    );
  }
}
