// iOS's Reduce Motion calms Frosted. Flutter 3.47 sets MediaQuery.disableAnimations on Android and the
// web but only the platform's accessibilityFeatures.reduceMotion on iOS, so
// Frosted reads both through ui_core 0.2.1's designReduceMotionOf. Every case
// here sets iOS's flag alone (MediaQuery still says animations run): the
// timings are cuts, each loop stops as the flag turns on and runs again as
// it turns off (a change of iOS's flag comes as a build, never as
// didChangeDependencies), and a switch lands at once.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:frosted_ui/frosted_host.dart';

Widget _host(Widget child) {
  final t = FrostedThemeData.opal();
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    builder: (context, page) =>
        FrostedHost(theme: t, darkTheme: t, child: page!),
    home: ColoredBox(
      color: t.colorScheme.background,
      child: Center(child: SizedBox(width: 320, child: child)),
    ),
  );
}

/// Sets iOS's Reduce Motion alone, as an iPhone reports it.
Future<void> _iosReduceMotion(WidgetTester tester, bool on) async {
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      FakeAccessibilityFeatures(reduceMotion: on);
  await tester.pump();
}

/// Whether anything is still moving after a frame.
Future<bool> _moving(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 16));
  return tester.binding.hasScheduledFrame;
}

void main() {
  tearDown(() {
    TestWidgetsFlutterBinding.instance.platformDispatcher
        .clearAccessibilityFeaturesTestValue();
  });

  testWidgets('with only iOS\'s flag, every timing is a cut', (tester) async {
    late BuildContext at;
    await tester.pumpWidget(
      _host(
        Builder(
          builder: (context) {
            at = context;
            return const SizedBox();
          },
        ),
      ),
    );
    expect(FrostedMotion.of(at), FrostedMotion.look);
    await _iosReduceMotion(tester, true);
    expect(
      MediaQuery.disableAnimationsOf(at),
      isFalse,
      reason: "MediaQuery carries iOS's flag after all",
    );
    expect(FrostedMotion.of(at), FrostedMotion.still);
    expect(FrostedMotion.of(at).moves, isFalse);
  });

  for (final (name, loop) in <(String, Widget)>[
    (
      'circular progress',
      const FrostedCircularProgressIndicator(label: 'Loading'),
    ),
    ('linear progress', const FrostedLinearProgressIndicator(label: 'Loading')),
    ('skeleton', const FrostedSkeleton(width: 200)),
    ('loading state', const FrostedLoadingState(message: 'Loading')),
  ]) {
    testWidgets(
      "the $name stops as iOS's Reduce Motion turns on and runs as it turns off",
      (tester) async {
        await tester.pumpWidget(_host(loop));
        expect(await _moving(tester), isTrue, reason: 'it never ran');
        await _iosReduceMotion(tester, true);
        expect(
          await _moving(tester),
          isFalse,
          reason: "it kept running under iOS's Reduce Motion",
        );
        await tester.pumpAndSettle();
        await _iosReduceMotion(tester, false);
        expect(
          await _moving(tester),
          isTrue,
          reason: 'it stayed still once Reduce Motion was off',
        );
      },
    );
  }

  testWidgets(
    "a switch lands at once under iOS's Reduce Motion, and eases with it off",
    (tester) async {
      var on = false;
      await tester.pumpWidget(
        _host(
          StatefulBuilder(
            builder: (context, setState) => FrostedSwitch(
              value: on,
              label: 'Alerts',
              onChanged: (v) => setState(() => on = v),
            ),
          ),
        ),
      );
      await tester.tap(find.bySemanticsLabel('Alerts'));
      expect(await _moving(tester), isTrue, reason: 'the switch did not ease');
      await tester.pumpAndSettle();
      await _iosReduceMotion(tester, true);
      await tester.tap(find.bySemanticsLabel('Alerts'));
      expect(
        await _moving(tester),
        isFalse,
        reason: "the switch eased under iOS's Reduce Motion",
      );
      expect(on, isFalse);
    },
  );
}
