// Fluent 2's push on an app built on Flutter's own MaterialApp, as most apps that take the look are (and this
// example): ui_core's example/test/page_transitions_test.dart with Fluent 2's map in place of its stand-in. The
// look's library stands on material_ui, so the PageTransitionsTheme Fluent2Theme installs in the Material theme it
// builds is material_ui's: Flutter's MaterialPageRoute never reads it, and on a Mac plays the Cupertino slide. The
// look exposes its push as fluent2PageTransitions, a map of widgets-level PageTransitionsBuilders, and the app puts
// it in its own ThemeData. On every platform the push played is Fluent 2's own; on iOS ui_core's swipe back stands
// round it, so a swipe from the screen's left edge still pops the page.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluent2_design_ui/fluent2_design_ui.dart';

// The Cupertino push, Flutter's own or cupertino_ui's.
final _cupertinoPush = find.byWidgetPredicate(
  (w) => w.runtimeType.toString() == 'CupertinoPageTransition',
);

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
    "Fluent 2's map in the app's ThemeData is the push a MaterialPageRoute "
    'plays',
    (tester) async {
      await tester.pumpWidget(_app(transitions: fluent2PageTransitions));
      await tester.tap(find.text('Open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(
        find.ancestor(
          of: find.text('Second'),
          matching: find.byType(Fluent2PageTransition),
        ),
        findsOneWidget,
      );
      expect(_cupertinoPush, findsNothing);
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
      expect(find.byType(Fluent2PageTransition), findsNothing);
      expect(_cupertinoPush, findsWidgets);
      await tester.pumpAndSettle();
    },
    variant: TargetPlatformVariant.only(TargetPlatform.macOS),
  );

  // iOS's swipe back from the screen's leading edge lives in Cupertino's page
  // transition, which Fluent 2's push replaces; the map's iOS entry stands
  // ui_core's DesignSwipeBackPageTransitionsBuilder round it.
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
      expect(
        find.ancestor(
          of: find.text('Second'),
          matching: find.byType(Fluent2PageTransition),
        ),
        findsOneWidget,
        reason: "Fluent 2's push plays",
      );
      expect(_cupertinoPush, findsNothing);
      await tester.pumpAndSettle();
    }

    testWidgets(
      'a swipe from the left edge past half way pops the page, the one under '
      'it showing as it goes',
      (tester) async {
        await tester.pumpWidget(_app(transitions: fluent2PageTransitions));
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
      await tester.pumpWidget(_app(transitions: fluent2PageTransitions));
      await open(tester);
      final gesture = await drag(tester, 100);
      await gesture.up();
      await tester.pumpAndSettle();
      expect(find.text('Second'), findsOneWidget);
      expect(find.text('Open'), findsNothing);
      expect(tester.getTopLeft(find.text('Second')).dx, 0);
    }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

    testWidgets("without ui_core's swipe back round it, Fluent 2's push "
        'takes no swipe', (tester) async {
      await tester.pumpWidget(
        _app(
          transitions: {
            for (final platform in TargetPlatform.values)
              platform: const Fluent2PageTransitionsBuilder(),
          },
        ),
      );
      await open(tester);
      final width =
          tester.view.physicalSize.width / tester.view.devicePixelRatio;
      final gesture = await drag(tester, width * .6);
      await gesture.up();
      await tester.pumpAndSettle();
      expect(find.text('Second'), findsOneWidget);
    }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));
  });
}
