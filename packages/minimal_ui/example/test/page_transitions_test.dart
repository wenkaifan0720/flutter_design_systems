// Minimal's push on an app built on Flutter's own MaterialApp, as most apps
// that take Minimal are (and this example). Minimal's library is on
// material_ui, so the PageTransitionsTheme MinimalTheme installs in the
// Material theme it builds is material_ui's: Flutter's MaterialPageRoute
// never reads it, and on a Mac plays the Cupertino slide. Minimal exposes
// its push as a map of widgets-level PageTransitionsBuilders instead,
// minimalPageTransitions, one map for both Materials, and the app puts it in
// its own ThemeData.
//
// ui_core's example/test/page_transitions_test.dart, with Minimal's map in
// place of its stand-in.
//
// Minimal's push replaces iOS's, and with it iOS's edge swipe back, so iOS's
// entry wraps it in ui_core's SwipeBackPageTransitionsBuilder: the last
// tests drag from the page's leading edge.
import 'package:cupertino_ui/cupertino_ui.dart' show CupertinoPageTransition;
import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';

// Minimal's push travels this far at most (the chrome metrics' push slide).
const double _pushSlide = 8;

// An app on Flutter's MaterialApp, its ThemeData carrying [transitions], with
// a page that pushes a MaterialPageRoute.
Widget _app({Map<TargetPlatform, PageTransitionsBuilder>? transitions}) =>
    MaterialApp(
      theme: ThemeData(
        pageTransitionsTheme: transitions == null
            ? const PageTransitionsTheme()
            : PageTransitionsTheme(builders: transitions),
      ),
      home: Builder(
        builder: (context) => Center(
          child: GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const Text('Second')),
            ),
            child: const Text('Open'),
          ),
        ),
      ),
    );

void main() {
  testWidgets(
    "Minimal's map in the app's ThemeData is the push a MaterialPageRoute "
    'plays',
    (tester) async {
      await tester.pumpWidget(_app(transitions: minimalPageTransitions));
      await tester.tap(find.text('Open'));
      await tester.pump();
      // Halfway through Minimal's push: the page is fading in, a few pixels
      // from where it lands, on its own line.
      final push = minimalPageTransitions[defaultTargetPlatform]!;
      await tester.pump(push.transitionDuration ~/ 2);
      final second = find.text('Second');
      final mid = tester.getTopLeft(second);
      final fade = tester.widget<FadeTransition>(
        find.ancestor(of: second, matching: find.byType(FadeTransition)).first,
      );
      expect(fade.opacity.value, inExclusiveRange(0, 1));
      expect(find.byType(CupertinoPageTransition), findsNothing);
      await tester.pumpAndSettle();
      final end = tester.getTopLeft(second);
      expect(mid.dy, end.dy);
      expect((mid.dx - end.dx).abs(), inInclusiveRange(0.5, _pushSlide));
      // The pop reverses it.
      Navigator.of(tester.element(second)).pop();
      await tester.pump();
      await tester.pump(push.reverseTransitionDuration ~/ 2);
      final back = tester.getTopLeft(second);
      expect(back.dy, end.dy);
      expect((back.dx - end.dx).abs(), inInclusiveRange(0.5, _pushSlide));
      await tester.pumpAndSettle();
      expect(second, findsNothing);
    },
    variant: TargetPlatformVariant.all(),
  );

  testWidgets(
    "without it, a Mac's MaterialPageRoute plays the Cupertino slide",
    (tester) async {
      await tester.pumpWidget(_app());
      await tester.tap(find.text('Open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.byType(CupertinoPageTransition), findsWidgets);
      await tester.pumpAndSettle();
    },
    variant: TargetPlatformVariant.only(TargetPlatform.macOS),
  );

  // Pushes the second page, then drags from (x, 300) by [steps] moves of
  // 30 px, 100 ms apart (300 px a second, too slow to fling), and holds.
  // Returns the gesture and where the second page stood before the drag.
  Future<(TestGesture, Offset)> swipe(
    WidgetTester tester,
    double x,
    int steps,
  ) async {
    await tester.pumpWidget(_app(transitions: minimalPageTransitions));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('Open'), findsNothing, reason: 'covered: not built');
    final rest = tester.getTopLeft(find.text('Second'));
    final gesture = await tester.startGesture(Offset(x, 300));
    for (var i = 0; i < steps; i++) {
      await gesture.moveBy(const Offset(30, 0));
      await tester.pump(const Duration(milliseconds: 100));
    }
    return (gesture, rest);
  }

  testWidgets(
    'on iOS a drag from the leading edge takes the page with the finger, '
    'and let go past halfway, pops it',
    (tester) async {
      final (gesture, rest) = await swipe(tester, 5, 18);
      // Under the finger: the page moved with it, the page below showing.
      expect(find.text('Open'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('Second')).dx - rest.dx,
        greaterThan(300),
      );
      await gesture.up();
      await tester.pumpAndSettle();
      expect(find.text('Second'), findsNothing);
      expect(find.text('Open'), findsOneWidget);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );

  testWidgets(
    'on iOS a short slow drag puts the page back; a quick one pops it',
    (tester) async {
      final (gesture, rest) = await swipe(tester, 5, 6);
      expect(tester.getTopLeft(find.text('Second')).dx, greaterThan(rest.dx));
      await gesture.up();
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(find.text('Second')), rest);
      expect(find.text('Open'), findsNothing, reason: 'covered again');

      await tester.flingFrom(const Offset(5, 300), const Offset(160, 0), 1600);
      await tester.pumpAndSettle();
      expect(find.text('Second'), findsNothing);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );

  testWidgets(
    'on iOS a drag that starts away from the edge leaves the page be',
    (tester) async {
      final (gesture, rest) = await swipe(tester, 120, 18);
      expect(tester.getTopLeft(find.text('Second')), rest);
      expect(find.text('Open'), findsNothing);
      await gesture.up();
      await tester.pumpAndSettle();
      expect(find.text('Second'), findsOneWidget);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );

  testWidgets("on Android the edge drags nothing: its back is the system's", (
    tester,
  ) async {
    final (gesture, rest) = await swipe(tester, 5, 18);
    expect(tester.getTopLeft(find.text('Second')), rest);
    await gesture.up();
    await tester.pumpAndSettle();
    expect(find.text('Second'), findsOneWidget);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));
}
