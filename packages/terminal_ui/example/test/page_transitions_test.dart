// Terminal's push on an app built on Flutter's own MaterialApp, as most apps
// that take it are (and its example). terminal_ui stands on material_ui, so
// the PageTransitionsTheme TermTheme installs in the Material theme it
// builds is material_ui's: Flutter's MaterialPageRoute never reads it, and on
// a Mac plays the Cupertino slide. The package exposes its push as
// termPageTransitions, a map of widgets-level PageTransitionsBuilders for
// both Materials, and the app puts it in its own ThemeData.
//
// ui_core's example/test/page_transitions_test.dart, with Terminal's map in
// place of its stand-in.
import 'package:cupertino_ui/cupertino_ui.dart' show CupertinoPageTransition;
import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terminal_ui/terminal_ui.dart';

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
    "the look's map in the app's ThemeData is the push a MaterialPageRoute "
    'plays',
    (tester) async {
      await tester.pumpWidget(_app(transitions: termPageTransitions));
      final open = tester.element(find.text('Open'));
      // Terminal's push (on iOS, inside ui_core's swipe back).
      expect(
        Theme.of(open).pageTransitionsTheme.builders[defaultTargetPlatform],
        same(termPageTransitions[defaultTargetPlatform]),
      );
      await tester.tap(find.text('Open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      // Terminal's push: the new screen where it stays from its first frame.
      expect(find.byType(CupertinoPageTransition), findsNothing);
      final second = find.text('Second');
      final early = tester.getRect(second);
      await tester.pumpAndSettle();
      expect(second, findsOneWidget);
      expect(tester.getRect(second), early);
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

  // iOS's swipe back from the screen's leading edge lives in Cupertino's
  // page transition, which Terminal's map replaces; the map's iOS entry is
  // ui_core's DesignSwipeBackPageTransitionsBuilder round Terminal's push.
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

    Future<void> open(WidgetTester tester) async {
      await tester.tap(find.text('Open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.byType(CupertinoPageTransition), findsNothing);
      await tester.pumpAndSettle();
      expect(find.text('Second'), findsOneWidget);
    }

    testWidgets(
      "with Terminal's map, a swipe from the left edge past half way pops "
      'the page, the one under it showing as it goes',
      (tester) async {
        await tester.pumpWidget(_app(transitions: termPageTransitions));
        final width =
            tester.view.physicalSize.width / tester.view.devicePixelRatio;
        for (var time = 0; time < 2; time++) {
          await open(tester);
          final gesture = await drag(tester, width * .6);
          expect(find.text('Open'), findsOneWidget, reason: 'shown under');
          expect(
            tester.getTopLeft(find.text('Second')).dx,
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
      await tester.pumpWidget(_app(transitions: termPageTransitions));
      await open(tester);
      final gesture = await drag(tester, 100);
      await gesture.up();
      await tester.pumpAndSettle();
      expect(find.text('Second'), findsOneWidget);
      expect(find.text('Open'), findsNothing);
      expect(tester.getTopLeft(find.text('Second')).dx, 0);
    }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));
  });
}
