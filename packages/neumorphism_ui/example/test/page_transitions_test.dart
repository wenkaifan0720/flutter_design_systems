// The look's push on an app built on Flutter's own MaterialApp, as most apps that take a look are (and this example).
// The look's library is on material_ui, so the PageTransitionsTheme it installs in the Material theme it builds is
// material_ui's: Flutter's MaterialPageRoute never reads it, and on a Mac plays the Cupertino slide. The look exposes
// its transitions as a map of widgets-level PageTransitionsBuilders instead, `neumorphicPageTransitions`, and the app
// puts it in its own ThemeData. On iOS the map keeps the swipe back from the screen's leading edge round the look's
// push (ui_core's DesignSwipeBackPageTransitionsBuilder). ui_core's example/test/page_transitions_test.dart, with the
// look's map.
import 'package:flutter/cupertino.dart' show CupertinoPageTransition;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart'
    show neumorphicPageTransitions;

// An app on Flutter's MaterialApp, its ThemeData carrying [transitions], with a page that pushes a MaterialPageRoute.
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

// The look's push, part way: the page steps in from the reading end, at most 16 px, and never rises or falls.
bool _stepping(WidgetTester tester) => tester
    .widgetList<Transform>(
      find.ancestor(of: find.text('Second'), matching: find.byType(Transform)),
    )
    .any((t) {
      final move = t.transform.getTranslation();
      return move.x > 0 && move.x <= 16 && move.y == 0;
    });

void main() {
  testWidgets(
    "the look's map in the app's ThemeData is the push a MaterialPageRoute plays",
    (tester) async {
      await tester.pumpWidget(_app(transitions: neumorphicPageTransitions));
      await tester.tap(find.text('Open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(_stepping(tester), isTrue);
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
      expect(_stepping(tester), isFalse);
      expect(find.byType(CupertinoPageTransition), findsWidgets);
      await tester.pumpAndSettle();
    },
    variant: TargetPlatformVariant.only(TargetPlatform.macOS),
  );

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
      await tester.pump(const Duration(milliseconds: 50));
      expect(_stepping(tester), isTrue, reason: "the look's push plays");
      expect(find.byType(CupertinoPageTransition), findsNothing);
      await tester.pumpAndSettle();
    }

    testWidgets(
      "with the look's map, a swipe from the left edge past half way pops the page, the one under it showing",
      (tester) async {
        await tester.pumpWidget(_app(transitions: neumorphicPageTransitions));
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
      await tester.pumpWidget(_app(transitions: neumorphicPageTransitions));
      await open(tester);
      final gesture = await drag(tester, 100);
      await gesture.up();
      await tester.pumpAndSettle();
      expect(find.text('Second'), findsOneWidget);
      expect(find.text('Open'), findsNothing);
    }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));
  });
}
