// iOS's Reduce Motion alone. Flutter 3.47 sets only dart:ui's reduceMotion there, never MediaQuery's
// disableAnimations. Fluent 2's motion reads ui_core's designReduceMotionOf (Fluent2Motion.on), so its durations
// collapse, its loops stop and start again as the flag flips (the change reaches a part as a build), and a swiped row's
// spring lands at once with that flag alone.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluent2_design_ui/fluent2_design_ui.dart';
import 'package:fluent2_design_ui/fluent2_design_host.dart';

/// Sets iOS's Reduce Motion, and only it, for the rest of the test.
void _iosReduceMotion(WidgetTester t, bool on) {
  t.platformDispatcher.accessibilityFeaturesTestValue =
      FakeAccessibilityFeatures(reduceMotion: on);
}

Future<void> _stage(WidgetTester t, Widget body) async {
  addTearDown(t.platformDispatcher.clearAccessibilityFeaturesTestValue);
  t.view.physicalSize = const Size(800, 600);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: (context, navigator) =>
          Fluent2Host(brightness: Brightness.light, child: navigator!),
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(width: 320, child: body),
          ),
        ),
      ),
    ),
  );
}

/// [body] under Fluent 2's theme and nothing of Fluent 2's above it.
Future<void> _themeAlone(WidgetTester t, Widget body) async {
  addTearDown(t.platformDispatcher.clearAccessibilityFeaturesTestValue);
  await t.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Fluent2Theme(data: Fluent2ThemeData.lapis(), child: body),
    ),
  );
}

void main() {
  testWidgets("with only iOS's flag, Fluent 2's motion is off and every "
      'duration a cut', (t) async {
    _iosReduceMotion(t, true);
    late BuildContext context;
    await _stage(
      t,
      Builder(
        builder: (c) {
          context = c;
          return const SizedBox();
        },
      ),
    );
    expect(MediaQuery.disableAnimationsOf(context), isFalse);
    expect(Fluent2Motion.on(context), isFalse);
    expect(Fluent2Motion.of(context, Fluent2Motion.normal), Duration.zero);
  });

  // Under Fluent2Host, and under Fluent 2's theme alone, where nothing above the part reads the flag: there the flip
  // reaches the part only as its own build, so a loop started and stopped in didChangeDependencies would miss it.
  for (final (name, part) in const <(String, Widget)>[
    ('the spinner', Fluent2Spinner()),
    ('the progress bar', Fluent2ProgressBar()),
    ('the skeleton', Fluent2Skeleton(child: Fluent2SkeletonItem(width: 120))),
  ]) {
    for (final (under, stage) in [
      ('under Fluent2Host', _stage),
      ('under its theme alone', _themeAlone),
    ]) {
      testWidgets("$name $under stops as iOS's Reduce Motion turns on and "
          'runs again as it turns off', (t) async {
        await stage(t, Center(child: part));
        expect(t.hasRunningAnimations, isTrue);
        _iosReduceMotion(t, true);
        await t.pump();
        expect(t.hasRunningAnimations, isFalse);
        _iosReduceMotion(t, false);
        await t.pump();
        expect(t.hasRunningAnimations, isTrue);
      });
    }
  }

  for (final reduced in [false, true]) {
    testWidgets(
      reduced
          ? "with iOS's flag, a swiped row's spring lands at once"
          : "without it, a swiped row's spring travels",
      (t) async {
        _iosReduceMotion(t, reduced);
        await _stage(
          t,
          Fluent2SwipeActions(
            leading: [
              Fluent2SwipeAction(
                label: 'Archive',
                icon: Fluent2Icons.archive,
                tone: Fluent2Tone.success,
                onPressed: () {},
              ),
            ],
            child: const SizedBox(
              height: 56,
              width: double.infinity,
              child: Text('Mara Okafor'),
            ),
          ),
        );
        final shut = t.getTopLeft(find.text('Mara Okafor')).dx;
        await t.drag(find.text('Mara Okafor'), const Offset(56, 0));
        await t.pump();
        final moved = t.getTopLeft(find.text('Mara Okafor')).dx - shut;
        if (reduced) {
          expect(t.hasRunningAnimations, isFalse);
          expect(moved, Fluent2SwipeActions.paneWidth, reason: 'open at once');
        } else {
          expect(t.hasRunningAnimations, isTrue, reason: 'the spring runs');
          expect(moved, lessThan(Fluent2SwipeActions.paneWidth));
          await t.pumpAndSettle();
          expect(
            t.getTopLeft(find.text('Mara Okafor')).dx - shut,
            Fluent2SwipeActions.paneWidth,
          );
        }
      },
    );
  }
}
