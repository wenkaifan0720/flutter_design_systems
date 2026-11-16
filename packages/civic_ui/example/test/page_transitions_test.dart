// Civic's push on an app built on Flutter's own MaterialApp, as most apps
// that take Civic are (and this example is). Civic's library is on
// material_ui, so a PageTransitionsTheme it installs in the Material theme
// it builds is material_ui's: Flutter's MaterialPageRoute never reads it,
// and on a Mac plays the Cupertino slide. Civic exposes its page change as
// a map of widgets-level PageTransitionsBuilders instead,
// civicPageTransitions, one map for both Materials, and the app puts it in
// its own ThemeData. Copied from ui_core's example/test/
// page_transitions_test.dart, with Civic's map for its stand-in.
import 'package:civic_ui/civic_ui.dart';
import 'package:flutter/cupertino.dart' show CupertinoPageTransition;
import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// An app on Flutter's MaterialApp, its ThemeData carrying [transitions],
// Civic's theme over it, with a page that pushes a MaterialPageRoute.
Widget _app({Map<TargetPlatform, PageTransitionsBuilder>? transitions}) =>
    MaterialApp(
      theme: ThemeData(
        pageTransitionsTheme: transitions == null
            ? const PageTransitionsTheme()
            : PageTransitionsTheme(builders: transitions),
      ),
      builder: (context, child) =>
          CivicTheme(data: CivicThemeData.light(), child: child!),
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
    "Civic's map in the app's ThemeData is the push a MaterialPageRoute "
    'plays: the page fades in where it stands',
    (tester) async {
      await tester.pumpWidget(_app(transitions: civicPageTransitions));
      await tester.tap(find.text('Open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      final theme = Theme.of(tester.element(find.text('Second')));
      final builder =
          theme.pageTransitionsTheme.builders[defaultTargetPlatform];
      // On iOS, Civic's change with the swipe back from the edge round it.
      expect(
        builder is DesignSwipeBackPageTransitionsBuilder
            ? builder.builder
            : builder,
        isA<CivicPageTransitions>(),
      );
      expect(find.byType(CupertinoPageTransition), findsNothing);
      // Halfway in, the page is fading, not travelling.
      final fading = tester
          .widgetList<FadeTransition>(
            find.ancestor(
              of: find.text('Second'),
              matching: find.byType(FadeTransition),
            ),
          )
          .map((f) => f.opacity.value);
      expect(fading.any((o) => o < 1), isTrue);
      final places = <Offset>{tester.getTopLeft(find.text('Second'))};
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        places.add(tester.getTopLeft(find.text('Second')));
      }
      await tester.pumpAndSettle();
      places.add(tester.getTopLeft(find.text('Second')));
      expect(places, hasLength(1));
    },
    variant: TargetPlatformVariant.all(),
  );

  testWidgets("on iOS a swipe from the screen's leading edge pops the page", (
    tester,
  ) async {
    await tester.pumpWidget(_app(transitions: civicPageTransitions));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.dragFrom(const Offset(4, 300), const Offset(600, 0));
    await tester.pumpAndSettle();
    expect(find.text('Second'), findsNothing);
    expect(find.text('Open'), findsOneWidget);
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

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
