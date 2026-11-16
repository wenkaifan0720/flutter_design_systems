// The example is an app on Flutter's own Material, and the Overview opens
// slipway with Flutter's MaterialPageRoute. That route reads the app's
// ThemeData, not the theme TermTheme sets on the Material terminal_ui draws
// on (material_ui), so the example's ThemeData carries termPageTransitions:
// slipway comes up in place and goes again in place, as a terminal's screen
// does. page_transitions_test.dart holds the map's own case and the slide an
// app without it gets.
import 'package:flutter/foundation.dart'
    show debugDefaultTargetPlatformOverride;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terminal_ui/terminal_ui.dart';
import 'package:terminal_ui_example/kit_gallery/overview.dart';
import 'package:terminal_ui_example/kit_gallery/slipway.dart';

void _size(WidgetTester tester, Size size) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);
}

/// What flies a screen in: the platforms' page transitions are built of
/// these. One at rest flies nothing: iOS's swipe back (ui_core's, round
/// Terminal's change) holds the page in a slide that stays still until a
/// finger drags it.
bool _carries(Widget w) => switch (w) {
  SlideTransition(:final position) => position.value != Offset.zero,
  FractionalTranslation(:final translation) => translation != Offset.zero,
  ScaleTransition(:final scale) => scale.value != 1,
  RotationTransition(:final turns) => turns.value != 0,
  SnapshotWidget() => true,
  _ => false,
};

List<Type> _flying(Finder of) => [
  for (final element
      in find
          .ancestor(of: of, matching: find.byWidgetPredicate(_carries))
          .evaluate())
    element.widget.runtimeType,
];

/// Runs [body] as if on [platform], and unsets the override whatever happens:
/// the binding checks it before tear-downs.
Future<void> _on(TargetPlatform platform, Future<void> Function() body) async {
  debugDefaultTargetPlatformOverride = platform;
  try {
    await body();
  } finally {
    debugDefaultTargetPlatformOverride = null;
  }
}

void main() {
  testWidgets("the Overview's MaterialPageRoute pushes and pops in place on "
      'every platform', (tester) async {
    for (final platform in TargetPlatform.values) {
      for (final size in const [Size(390, 844), Size(1440, 900)]) {
        final why = '${platform.name} at ${size.width.round()}';
        await _on(platform, () async {
          _size(tester, size);
          await tester.pumpWidget(const SizedBox());
          await tester.pumpWidget(overviewApp(Brightness.dark));
          await tester.pump(const Duration(milliseconds: 500));
          final overview = find.byType(OverviewPage);
          // The app's own theme, the one Flutter's route reads.
          expect(
            Theme.of(tester.element(overview))
                .pageTransitionsTheme
                .builders[platform],
            // Terminal's change (on iOS, inside ui_core's swipe back).
            same(termPageTransitions[platform]),
            reason: why,
          );

          final open = find.text('new deploy').first;
          await tester.ensureVisible(open);
          await tester.pump();
          await tester.tap(open);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 60));
          final shell = find.byType(SlipwayShell);
          expect(shell, findsOneWidget, reason: 'push, $why');
          expect(_flying(shell), isEmpty, reason: 'push, $why');
          expect(_flying(overview), isEmpty, reason: 'push, $why');
          final pushed = tester.getRect(shell);
          await tester.pump(const Duration(milliseconds: 200));
          expect(tester.getRect(shell), pushed, reason: 'push, $why');
          // slipway's run keeps moving (its spinner), so the route's change
          // is waited out, not settled.
          await tester.pump(const Duration(seconds: 1));

          Navigator.of(tester.element(shell)).pop();
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 60));
          expect(_flying(overview), isEmpty, reason: 'pop, $why');
          if (shell.evaluate().isNotEmpty) {
            expect(_flying(shell), isEmpty, reason: 'pop, $why');
          }
          final popped = tester.getRect(overview);
          await tester.pump(const Duration(milliseconds: 200));
          expect(tester.getRect(overview), popped, reason: 'pop, $why');
          await tester.pump(const Duration(seconds: 1));
          expect(shell, findsNothing, reason: 'pop, $why');
        });
      }
    }
  });
}
