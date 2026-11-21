// Frosted's push on an app built on Flutter's own MaterialApp, as most apps
// that take a look are (and this example). Frosted's library is on
// material_ui, so the PageTransitionsTheme it installs in the Material theme
// it builds is material_ui's: Flutter's MaterialPageRoute never reads it, and
// on a Mac plays the Cupertino slide. Frosted exposes its transitions as a
// map of widgets-level PageTransitionsBuilders instead, one map for both
// Materials, and the app puts it in its own ThemeData.
//
// ui_core's example/test/page_transitions_test.dart, with Frosted's map in
// place of its stand-in.
import 'package:cupertino_ui/cupertino_ui.dart' show CupertinoPageTransition;
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';

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
    "Frosted's map in the app's ThemeData is the push a MaterialPageRoute "
    'plays',
    (tester) async {
      await tester.pumpWidget(_app(transitions: frostedPageTransitions));
      await tester.tap(find.text('Open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      // Frosted's push: the page clears in as it settles toward the end,
      // never further than its small travel.
      final at = tester.getTopLeft(find.text('Second'));
      expect(at.dy, 0);
      expect(at.dx, greaterThan(0));
      expect(at.dx, lessThanOrEqualTo(FrostedPageMotion.travel));
      expect(
        tester
            .widget<Opacity>(
              find
                  .ancestor(
                    of: find.text('Second'),
                    matching: find.byType(Opacity),
                  )
                  .first,
            )
            .opacity,
        lessThan(1),
      );
      expect(find.byType(CupertinoPageTransition), findsNothing);
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(find.text('Second')), Offset.zero);
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

  // iOS's swipe back lives in Cupertino's page transition, which Frosted's
  // push replaces; Frosted's map keeps it (ui_core's
  // SwipeBackPageTransitionsBuilder round the push).
  testWidgets(
    "with Frosted's map, a swipe from the left edge past half way pops the "
    'page, and one let go short of half settles it back',
    (tester) async {
      await tester.pumpWidget(_app(transitions: frostedPageTransitions));
      final width =
          tester.view.physicalSize.width / tester.view.devicePixelRatio;
      Future<void> swipe(double by) async {
        final gesture = await tester.startGesture(const Offset(4, 300));
        for (var i = 0; i < 10; i++) {
          await gesture.moveBy(Offset(by / 10, 0));
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(find.text('Open'), findsOneWidget, reason: 'shown under');
        expect(
          tester.getTopLeft(find.text('Second')).dx,
          moreOrLessEquals(by, epsilon: 1),
          reason: 'the page follows the finger',
        );
        await gesture.up();
        await tester.pumpAndSettle();
      }

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await swipe(100);
      expect(find.text('Second'), findsOneWidget);
      expect(tester.getTopLeft(find.text('Second')).dx, 0);
      await swipe(width * .6);
      expect(find.text('Second'), findsNothing, reason: 'popped');
      expect(find.text('Open'), findsOneWidget);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );
}
