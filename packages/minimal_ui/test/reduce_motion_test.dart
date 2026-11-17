// iOS's Reduce Motion alone stills Minimal. Flutter 3.47 sets only dart:ui's
// AccessibilityFeatures.reduceMotion on iOS, which MediaQuery does not carry
// (MediaQuery.disableAnimations is Android's and the web's), so
// context.minimalStill reads ui_core's designReduceMotionOf. Its change comes
// as a build, so each loop starts and stops from build, not once in
// didChangeDependencies.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:minimal_ui/minimal_host.dart';

Widget _page(Widget child) => MaterialApp(
  debugShowCheckedModeBanner: false,
  builder: (context, navigator) => MinimalHost(
    light: MinimalThemeData.preset('standard', Brightness.light),
    dark: MinimalThemeData.preset('standard', Brightness.dark),
    brightness: Brightness.light,
    child: navigator!,
  ),
  home: Scaffold(
    body: Center(child: SizedBox(width: 320, child: child)),
  ),
);

/// iOS's Reduce Motion, and nothing else.
void _ios(WidgetTester tester, bool on) =>
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        FakeAccessibilityFeatures(reduceMotion: on);

/// Whether anything still moves: a frame is wanted after two have passed.
Future<bool> _moving(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 16));
  await tester.pump(const Duration(milliseconds: 16));
  return tester.binding.hasScheduledFrame;
}

void main() {
  setUp(() => MinimalMotion.animate = true);
  tearDown(() => MinimalMotion.animate = true);

  testWidgets("with only iOS's flag Minimal is still, and its readers build "
      'again as the flag changes', (tester) async {
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    final seen = <bool>[];
    await tester.pumpWidget(
      _page(
        Builder(
          builder: (context) {
            seen.add(context.minimalStill);
            return const SizedBox();
          },
        ),
      ),
    );
    expect(seen.last, isFalse);
    _ios(tester, true);
    await tester.pump();
    expect(seen.last, isTrue, reason: "iOS's Reduce Motion went unread");
    _ios(tester, false);
    await tester.pump();
    expect(seen.last, isFalse);
  });

  final loops = <String, Widget>{
    'a busy button': MinimalButton('Saving', onPressed: () {}, busy: true),
    'a spinner': const MinimalCircularProgressIndicator(),
    'a progress bar of no known total': const MinimalLinearProgressIndicator(
      label: 'Uploading',
    ),
    'a skeleton': const MinimalSkeleton(width: 120),
    'the loading state': const MinimalLoadingState(),
  };
  for (final MapEntry(key: what, value: loop) in loops.entries) {
    testWidgets("$what stops as iOS's Reduce Motion turns on and runs again "
        'as it turns off', (tester) async {
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      await tester.pumpWidget(_page(loop));
      expect(await _moving(tester), isTrue, reason: 'it never ran');
      _ios(tester, true);
      expect(await _moving(tester), isFalse, reason: 'it ran on');
      _ios(tester, false);
      expect(await _moving(tester), isTrue, reason: 'it never ran again');
      // A page that opens under the flag starts still.
      _ios(tester, true);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(_page(loop));
      expect(
        await _moving(tester),
        isFalse,
        reason: 'it started under the flag',
      );
    });
  }

  testWidgets("a switch lands at once with iOS's flag on, and eases with it "
      'off', (tester) async {
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    var on = false;
    await tester.pumpWidget(
      _page(
        StatefulBuilder(
          builder: (context, setState) => MinimalSwitch(
            value: on,
            label: 'Reminders',
            onChanged: (v) => setState(() => on = v),
          ),
        ),
      ),
    );
    _ios(tester, true);
    await tester.pump();
    await tester.tap(find.byType(MinimalSwitch));
    await tester.pump();
    expect(on, isTrue);
    expect(tester.binding.hasScheduledFrame, isFalse, reason: 'it eased');
    _ios(tester, false);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(MinimalSwitch));
    await tester.pump();
    expect(on, isFalse);
    expect(tester.binding.hasScheduledFrame, isTrue, reason: 'it did not ease');
    await tester.pumpAndSettle();
  });
}
