// Brutal's push on an app built on Flutter's own MaterialApp, as most apps
// that take Brutal are (and its example, Admit). Brutal's library is on
// material_ui, so the PageTransitionsTheme its theme lays is material_ui's:
// Flutter's MaterialPageRoute never reads it, and on a Mac plays the
// Cupertino slide. So the app puts brutalPageTransitions, a map of
// widgets-level builders, in its own ThemeData.
//
// ui_core's example/test/page_transitions_test.dart, with Brutal's map in
// place of its stand-in. The push is Brutal's on every platform: the page
// comes a short way in from the end side; on iOS the map keeps iOS's swipe
// back from the screen's leading edge round it.
import 'package:brutal_ui/brutal_ui.dart'
    show BrutalPageTransitionsBuilder, brutalPageTransitions;
import 'package:flutter/cupertino.dart' show CupertinoPageTransition;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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
              MaterialPageRoute<void>(
                builder: (_) => const ColoredBox(
                  color: Color(0xFFFFFFFF),
                  child: Center(child: Text('Second')),
                ),
              ),
            ),
            child: const Text('Open'),
          ),
        ),
      ),
    );

void main() {
  testWidgets(
    "Brutal's map in the app's ThemeData is the push a MaterialPageRoute "
    'plays',
    (tester) async {
      await tester.pumpWidget(_app(transitions: brutalPageTransitions));
      await tester.tap(find.text('Open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));
      final mid = tester.getRect(find.text('Second'));
      // Not Flutter's Cupertino slide, the one a Mac's MaterialPageRoute
      // plays without the map; on iOS too, where the map keeps only iOS's
      // swipe back round Brutal's push.
      expect(find.byType(CupertinoPageTransition), findsNothing);
      await tester.pumpAndSettle();
      final rest = tester.getRect(find.text('Second'));
      expect(mid.top, rest.top);
      // Brutal's: in from the end side, a short way, never across.
      expect(
        mid.left - rest.left,
        inInclusiveRange(1, BrutalPageTransitionsBuilder.travel),
      );
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

  // iOS's swipe back from the screen's leading edge lives in Cupertino's page
  // transition, which Brutal's push replaces; the map's iOS entry keeps it
  // round the push (ui_core's DesignSwipeBackPageTransitionsBuilder).
  group("iOS's swipe back", () {
    // A drag from the screen's left edge, [by] to the right, slow enough not
    // to be a fling, the finger still down at the end.
    Future<TestGesture> drag(WidgetTester tester, double by) async {
      final gesture = await tester.startGesture(const Offset(4, 300));
      for (var i = 0; i < 10; i++) {
        await gesture.moveBy(Offset(by / 10, 0));
        await tester.pump(const Duration(milliseconds: 100));
      }
      return gesture;
    }

    Future<Rect> open(WidgetTester tester) async {
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      return tester.getRect(find.text('Second'));
    }

    testWidgets(
      'a swipe from the left edge past half way pops the page, the one '
      'under it showing as it goes',
      (tester) async {
        await tester.pumpWidget(_app(transitions: brutalPageTransitions));
        final width =
            tester.view.physicalSize.width / tester.view.devicePixelRatio;
        for (var time = 0; time < 2; time++) {
          final rest = await open(tester);
          final gesture = await drag(tester, width * .6);
          expect(find.text('Open'), findsOneWidget, reason: 'shown under');
          expect(
            tester.getRect(find.text('Second')).left - rest.left,
            moreOrLessEquals(width * .6, epsilon: 1),
            reason: 'the page follows the finger',
          );
          await gesture.up();
          await tester.pumpAndSettle();
          expect(find.text('Second'), findsNothing, reason: 'popped');
          expect(find.text('Open'), findsOneWidget);
        }
      },
      variant: TargetPlatformVariant.only(TargetPlatform.iOS),
    );

    testWidgets('a swipe let go short of half way settles the page back', (
      tester,
    ) async {
      await tester.pumpWidget(_app(transitions: brutalPageTransitions));
      final rest = await open(tester);
      final gesture = await drag(tester, 100);
      await gesture.up();
      await tester.pumpAndSettle();
      expect(find.text('Second'), findsOneWidget);
      expect(tester.getRect(find.text('Second')), rest);
    }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));
  });
}
