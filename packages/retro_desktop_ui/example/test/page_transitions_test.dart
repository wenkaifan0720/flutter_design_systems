// The look's page change on an app built on Flutter's own MaterialApp, as most apps that take the look are (and this
// example). The look's library is on material_ui, so the PageTransitionsTheme in the Material theme it builds is
// material_ui's: Flutter's MaterialPageRoute never reads it, and on a Mac plays the Cupertino slide. The look gives
// its page change as a map of widgets-level PageTransitionsBuilders instead, retroDesktopPageTransitions, and the app
// puts it in its own ThemeData (the README's setup). Copied from ui_core's example/test/page_transitions_test.dart,
// with the look's map in place of its stand-in: Retro Desktop's page change stands in place at once, so the test
// reads where the page stands in each frame.
import 'package:cupertino_ui/cupertino_ui.dart' show CupertinoPageTransition;
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart'
    show retroDesktopPageTransitions;

// An app on Flutter's MaterialApp, its ThemeData carrying [transitions], with a page that pushes a MaterialPageRoute.
Widget _app({Map<TargetPlatform, PageTransitionsBuilder>? transitions}) =>
    MaterialApp(
      theme: ThemeData(
        pageTransitionsTheme: transitions == null
            ? const PageTransitionsTheme()
            : PageTransitionsTheme(builders: transitions),
      ),
      home: Builder(
        builder: (context) => Align(
          alignment: Alignment.topLeft,
          child: GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                // A page with its own ground, as an app's are: a swipe from the edge starts on the page.
                builder: (_) => const ColoredBox(
                  color: Color(0xFFFFFFFF),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Text('Second'),
                  ),
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
    "the look's map in the app's ThemeData is the push a MaterialPageRoute "
    'plays: in place at once, and back the same way',
    (tester) async {
      await tester.pumpWidget(_app(transitions: retroDesktopPageTransitions));
      final home = tester.getTopLeft(find.text('Open'));
      await tester.tap(find.text('Open'));
      await tester.pump();
      expect(
        tester.getTopLeft(find.text('Second')),
        home,
        reason: 'the page stands in its place in the first frame',
      );
      expect(find.byType(CupertinoPageTransition), findsNothing);
      await tester.pump(const Duration(milliseconds: 50));
      expect(tester.getTopLeft(find.text('Second')), home);
      expect(tester.hasRunningAnimations, isFalse, reason: 'nothing to move');
      await tester.pumpAndSettle();
      expect(find.text('Second'), findsOneWidget);
      Navigator.of(tester.element(find.text('Second'))).pop();
      await tester.pump();
      await tester.pump();
      expect(find.text('Second'), findsNothing, reason: 'popped at once');
      expect(find.text('Open'), findsOneWidget);
    },
    variant: TargetPlatformVariant.all(),
  );

  // iOS's swipe back from the screen's leading edge lives in Cupertino's page transition, which the look's map
  // replaces; the map's iOS entry stands ui_core's swipe back round the look's change, so the swipe still pops.
  group("iOS's swipe back", () {
    // A drag from the screen's left edge, [by] to the right, slow enough not to be a fling, the finger still down.
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
      expect(tester.getTopLeft(find.text('Second')).dx, 0, reason: 'in place');
      await tester.pumpAndSettle();
    }

    testWidgets(
      "with the look's map, a swipe from the left edge past half way pops "
      'the page, the one under it showing as it goes',
      (tester) async {
        await tester.pumpWidget(_app(transitions: retroDesktopPageTransitions));
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
      await tester.pumpWidget(_app(transitions: retroDesktopPageTransitions));
      await open(tester);
      final gesture = await drag(tester, 100);
      await gesture.up();
      await tester.pumpAndSettle();
      expect(find.text('Second'), findsOneWidget);
      expect(find.text('Open'), findsNothing);
      expect(tester.getTopLeft(find.text('Second')).dx, 0);
    }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));
  });

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
}
