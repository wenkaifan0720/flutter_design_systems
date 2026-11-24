// iOS's Reduce Motion calms the look as Android's Remove animations and the web's prefers-reduced-motion do. Flutter
// 3.47 on iOS sets only dart:ui's reduceMotion, never MediaQuery's disableAnimations, so each test here sets the iOS
// flag alone. The look's every move is timed by NeumorphicMotion.of, read through ui_core's rawReduceMotionOf; its
// springs (the toaster's, an anchored surface's) are ui_core's, critically damped already and calmed by the same read.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

const _second = Key('second');

void _iosReduceMotion(WidgetTester tester, bool on) {
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      FakeAccessibilityFeatures(reduceMotion: on);
}

void main() {
  testWidgets(
    'the look goes still under iOS Reduce Motion alone, and moves again when it is turned off',
    (tester) async {
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      final theme = NeumorphicThemeData.porcelain();
      late NeumorphicMotion motion;
      late bool mediaQueryFlag;
      _iosReduceMotion(tester, true);
      await tester.pumpWidget(
        MediaQuery.fromView(
          view: tester.view,
          child: NeumorphicTheme(
            data: theme,
            child: Builder(
              builder: (context) {
                motion = NeumorphicMotion.of(context);
                mediaQueryFlag = MediaQuery.disableAnimationsOf(context);
                return const SizedBox();
              },
            ),
          ),
        ),
      );
      expect(mediaQueryFlag, isFalse, reason: 'only the iOS flag is set');
      expect(motion, theme.motion.still);
      expect(motion.travel, Duration.zero);

      // A change of iOS's flag comes as a build.
      _iosReduceMotion(tester, false);
      await tester.pump();
      expect(motion, theme.motion);
      expect(motion.travel, isNot(Duration.zero));
    },
  );

  testWidgets(
    'a pushed page lands in its first frame under iOS Reduce Motion alone',
    (tester) async {
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      Future<double> pushedLeft({required bool reduce}) async {
        _iosReduceMotion(tester, reduce);
        final navigator = GlobalKey<NavigatorState>();
        await tester.pumpWidget(
          MaterialApp(
            key: UniqueKey(),
            navigatorKey: navigator,
            builder: (context, child) => NeumorphicTheme(
              data: NeumorphicThemeData.porcelain(),
              child: child!,
            ),
            home: const Text('first'),
          ),
        );
        navigator.currentState!.push(
          MaterialPageRoute<void>(
            builder: (context) => const SizedBox.expand(key: _second),
          ),
        );
        // Offstage for one frame while the HeroController measures it; on stage the next, still at 0 ms.
        await tester.pump();
        await tester.pump();
        final left = tester.getTopLeft(find.byKey(_second)).dx;
        await tester.pumpAndSettle();
        return left;
      }

      // Without it, the page starts its 16 px step from the reading end.
      expect(await pushedLeft(reduce: false), greaterThan(8));
      expect(await pushedLeft(reduce: true), 0);
    },
  );
}
