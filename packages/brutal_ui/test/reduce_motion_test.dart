// iOS's Reduce Motion alone calms Brutal. Flutter 3.47 sets only dart:ui's
// reduceMotion on iOS, never MediaQuery's disableAnimations; Brutal reads
// ui_core's designReduceMotionOf, which hears either. Each test sets only the
// iOS flag. A colour spring becomes a short fade, a theme change and a select's
// chevron cut, and the loops stop and start again as the flag flips while they
// run (the flip reaches them as a build).
import 'package:brutal_ui/brutal_ui.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sets iOS's Reduce Motion, and only it, until the test ends.
void _iosReduceMotion(WidgetTester tester, bool on) {
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      FakeAccessibilityFeatures(reduceMotion: on);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
}

Widget _app(Widget child, {BrutalThemeData? theme}) => MaterialApp(
  home: AnimatedBrutalTheme(
    data: theme ?? BrutalThemeData.light(),
    child: Center(child: child),
  ),
);

const _paper = BrutalFace(
  fill: Color(0xFFFFFFFF),
  border: Color(0xFF000000),
  foreground: Color(0xFF000000),
);
const _ink = BrutalFace(
  fill: Color(0xFF000000),
  border: Color(0xFF000000),
  foreground: Color(0xFFFFFFFF),
);

Widget _surface(BrutalFace face) => AnimatedBrutalSurface(
  face: face,
  stiffness: BrutalMotion.colorStiffness,
  child: const SizedBox.square(dimension: 48),
);

void main() {
  for (final reduced in const [false, true]) {
    testWidgets(
      "a colour spring ${reduced ? 'settles in 150 ms' : 'runs its course'} "
      "with iOS's flag ${reduced ? 'on' : 'off'}",
      (tester) async {
        _iosReduceMotion(tester, reduced);
        await tester.pumpWidget(_app(_surface(_paper)));
        await tester.pumpWidget(_app(_surface(_ink)));
        // Critically damped at k 1200 it takes about 270 ms; Reduce Motion
        // raises it to ui_core's short fade, k 3800, about 150 ms.
        await tester.pump(const Duration(milliseconds: 160));
        expect(tester.hasRunningAnimations, !reduced);
        await tester.pumpAndSettle();
      },
    );
  }

  testWidgets("a theme change cuts with iOS's flag alone", (tester) async {
    _iosReduceMotion(tester, true);
    late BuildContext context;
    final probe = Builder(
      builder: (c) {
        context = c;
        return const SizedBox();
      },
    );
    await tester.pumpWidget(_app(probe));
    expect(MediaQuery.disableAnimationsOf(context), isFalse);
    final dark = BrutalThemeData.dark();
    await tester.pumpWidget(_app(probe, theme: dark));
    await tester.pump(const Duration(milliseconds: 16));
    expect(BrutalTheme.of(context).colors.paper, dark.colors.paper);
    await tester.pumpAndSettle();
  });

  testWidgets("a select's chevron turns at once with iOS's flag alone", (
    tester,
  ) async {
    _iosReduceMotion(tester, true);
    await tester.pumpWidget(
      _app(
        SizedBox(
          width: 280,
          child: BrutalSelect<String>(
            labelText: 'Room',
            value: 'hall1',
            items: const [
              BrutalSelectItem(value: 'hall1', label: 'Hall 1'),
              BrutalSelectItem(value: 'hall2', label: 'Hall 2'),
            ],
            onChanged: (_) {},
          ),
        ),
      ),
    );
    await tester.tap(find.byType(BrutalSelect<String>));
    await tester.pump();
    final turns = tester.widgetList<TweenAnimationBuilder<double>>(
      find.descendant(
        of: find.byType(BrutalSelect<String>),
        matching: find.byType(TweenAnimationBuilder<double>),
      ),
    );
    expect(turns, isNotEmpty);
    for (final turn in turns) {
      expect(turn.duration, Duration.zero);
    }
    await tester.pumpAndSettle();
  });

  for (final (name, part) in const <(String, Widget)>[
    ('the spinner', BrutalSpinner()),
    ('the running bar', SizedBox(width: 200, child: BrutalProgressBar())),
    ('the skeleton', BrutalSkeleton(width: 120)),
  ]) {
    testWidgets(
      "$name stops as iOS's Reduce Motion turns on and runs as it turns off",
      (tester) async {
        await tester.pumpWidget(_app(part));
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
}
