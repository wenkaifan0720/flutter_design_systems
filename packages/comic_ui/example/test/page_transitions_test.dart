// ui_core's example/test/page_transitions_test.dart, with Comic's map in place of its stand-in.
//
// A look's push on an app built on Flutter's own MaterialApp, as most apps
// that take a look are (and every look's example). A look's library is on
// material_ui, so a PageTransitionsTheme it installs in the Material theme
// it builds is material_ui's: Flutter's MaterialPageRoute never reads it,
// and on a Mac plays the Cupertino slide. A look exposes its transitions as
// a map of widgets-level PageTransitionsBuilders instead, one map for both
// Materials, and the app puts it in its own ThemeData.
//
// Comic's push is a cut: the route takes no time, and the page it pushes
// stands whole and in place in its first frame, nothing left running. On iOS
// the map wraps the cut in ui_core's SwipeBackPageTransitionsBuilder, so
// a swipe from the left edge still pops a page (Flutter's
// CupertinoPageTransition is never built).
import 'package:cupertino_ui/cupertino_ui.dart' show CupertinoPageTransition;
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:comic_ui/comic_ui.dart'
    show ComicPageTransitionsBuilder, comicPageTransitions;

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
      await tester.pumpWidget(_app(transitions: comicPageTransitions));
      await tester.tap(find.text('Open'));
      await tester.pump();
      // Comic's push: the route read the map (its duration is the cut's), and
      // in its first frame the page stands in place, the first one gone.
      expect(
        ModalRoute.of(tester.element(find.text('Second')))!.transitionDuration,
        Duration.zero,
      );
      expect(tester.getTopLeft(find.text('Second')), Offset.zero);
      expect(find.text('Open'), findsNothing);
      expect(tester.hasRunningAnimations, isFalse);
      expect(find.byType(CupertinoPageTransition), findsNothing);
      await tester.pumpAndSettle();
      expect(find.text('Second'), findsOneWidget);
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
      expect(tester.hasRunningAnimations, isTrue);
      expect(find.byType(CupertinoPageTransition), findsWidgets);
      await tester.pumpAndSettle();
    },
    variant: TargetPlatformVariant.only(TargetPlatform.macOS),
  );

  // iOS's swipe back from the screen's leading edge lives in Cupertino's
  // page transition, which Comic's cut replaces; the map keeps it round the
  // cut.
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
      expect(tester.getTopLeft(find.text('Second')), Offset.zero);
      expect(find.byType(CupertinoPageTransition), findsNothing);
      await tester.pumpAndSettle();
    }

    double width(WidgetTester tester) =>
        tester.view.physicalSize.width / tester.view.devicePixelRatio;

    testWidgets(
      "with Comic's map, a swipe from the left edge past half way pops the "
      'page, the one under it showing as it goes',
      (tester) async {
        await tester.pumpWidget(_app(transitions: comicPageTransitions));
        for (var time = 0; time < 2; time++) {
          await open(tester);
          final gesture = await drag(tester, width(tester) * .6);
          expect(find.text('Open'), findsOneWidget, reason: 'shown under');
          expect(
            tester.getTopLeft(find.text('Second')).dx,
            moreOrLessEquals(width(tester) * .6, epsilon: 1),
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
      await tester.pumpWidget(_app(transitions: comicPageTransitions));
      await open(tester);
      final gesture = await drag(tester, 100);
      await gesture.up();
      await tester.pumpAndSettle();
      expect(find.text('Second'), findsOneWidget);
      expect(find.text('Open'), findsNothing);
      expect(tester.getTopLeft(find.text('Second')).dx, 0);
    }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

    testWidgets('the cut alone takes no swipe', (tester) async {
      await tester.pumpWidget(
        _app(
          transitions: const {
            TargetPlatform.iOS: ComicPageTransitionsBuilder(),
          },
        ),
      );
      await open(tester);
      final gesture = await drag(tester, width(tester) * .6);
      await gesture.up();
      await tester.pumpAndSettle();
      expect(find.text('Second'), findsOneWidget);
    }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));
  });
}
