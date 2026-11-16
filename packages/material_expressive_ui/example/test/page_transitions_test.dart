// Material Expressive's push on an app built on Flutter's own MaterialApp,
// as most apps that take the look are (and this example). The look's
// library is on material_ui, so the PageTransitionsTheme its host installs
// in the Material theme it builds is material_ui's: Flutter's
// MaterialPageRoute never reads it, and on a Mac plays the Cupertino slide.
// The look exposes its transitions as a map of widgets-level
// PageTransitionsBuilders instead, expressivePageTransitions, one map for
// both Materials, and the app puts it in its own ThemeData.
//
// ui_core's example/test/page_transitions_test.dart, with the look's map in
// place of its stand-in. The map's push: the look's fade-forwards (96dp of
// travel and a fade) on macOS, Windows, Linux and Fuchsia; Flutter's
// predictive back on Android, whose push is Flutter's fade-forwards (a
// quarter of the window's travel); the Cupertino slide on iOS, which carries
// the edge swipe-back.
import 'package:flutter/cupertino.dart' show CupertinoPageTransition;
import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';

// Fade-forwards' travel, in logical pixels.
const double _fadeForwardsTravel = 96;

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

// How far the pushed page stands from where it comes to rest, 50 ms into the
// push (the travel still ahead of it), and whether Flutter's Cupertino slide,
// its default on a Mac, carries it then. (The look's iOS slide is
// cupertino_ui's, as the look's library stands on it; its travel shows it.)
Future<({double ahead, bool slide})> _push(WidgetTester tester) async {
  await tester.tap(find.text('Open'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  final moving = tester.getTopLeft(find.text('Second')).dx;
  final slide = find.byType(CupertinoPageTransition).evaluate().isNotEmpty;
  await tester.pumpAndSettle();
  expect(find.text('Second'), findsOneWidget);
  return (
    ahead: moving - tester.getTopLeft(find.text('Second')).dx,
    slide: slide,
  );
}

// The window's width, in logical pixels.
double _window(WidgetTester tester) =>
    tester.view.physicalSize.width / tester.view.devicePixelRatio;

void main() {
  testWidgets(
    "the look's map in the app's ThemeData is the push a MaterialPageRoute "
    'plays',
    (tester) async {
      final window = _window(tester);
      await tester.pumpWidget(_app(transitions: expressivePageTransitions));
      final (:ahead, :slide) = await _push(tester);
      expect(slide, isFalse);
      switch (defaultTargetPlatform) {
        case TargetPlatform.iOS:
          // The Cupertino slide, across the window.
          expect(ahead, greaterThan(window / 2));
        case TargetPlatform.android:
          // Flutter's fade-forwards: a quarter of the window at most.
          expect(ahead, greaterThan(0));
          expect(ahead, lessThanOrEqualTo(window / 4));
        case _:
          // The look's fade-forwards: 96dp at most, never across the window.
          expect(ahead, greaterThan(0));
          expect(ahead, lessThanOrEqualTo(_fadeForwardsTravel));
      }
    },
    variant: TargetPlatformVariant.all(),
  );

  testWidgets("iOS: with the look's map, the edge swipe still pops the page", (
    tester,
  ) async {
    await tester.pumpWidget(_app(transitions: expressivePageTransitions));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    final window = _window(tester);
    final gesture = await tester.startGesture(const Offset(4, 300));
    await gesture.moveBy(const Offset(40, 0));
    await tester.pump();
    await gesture.moveBy(Offset(window * 0.6, 0));
    await tester.pump();
    // The page follows the finger.
    expect(tester.getTopLeft(find.text('Second')).dx, greaterThan(window / 2));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(find.text('Second'), findsNothing);
    expect(find.text('Open'), findsOneWidget);
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

  testWidgets(
    "without it, a Mac's MaterialPageRoute plays the Cupertino slide",
    (tester) async {
      await tester.pumpWidget(_app());
      final (:ahead, :slide) = await _push(tester);
      expect(slide, isTrue);
      expect(ahead, greaterThan(_window(tester) / 2));
    },
    variant: TargetPlatformVariant.only(TargetPlatform.macOS),
  );
}
