// A page change under Comic is a cut on every platform: a page pushed or popped stands in its place, whole, in the
// first frame, with nothing left running; on iOS the edge swipe still takes a page back.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:comic_ui/comic_ui.dart';

Widget _app(GlobalKey<NavigatorState> navigator) => MaterialApp(
  navigatorKey: navigator,
  builder: (context, child) =>
      ComicTheme(data: ComicThemeData.offset(), child: child!),
  home: const ComicScaffold(body: Text('The first page')),
);

Route<void> _second() => MaterialPageRoute<void>(
  builder: (context) => const ComicScaffold(
    topBar: ComicAppBar(title: 'The second page'),
    body: Text('Its words'),
  ),
);

void main() {
  testWidgets(
    'a page pushed or popped cuts: whole and in place in its first frame',
    (tester) async {
      final navigator = GlobalKey<NavigatorState>();
      await tester.pumpWidget(_app(navigator));
      final screen = tester.getRect(find.byType(Navigator));

      navigator.currentState!.push(_second()).ignore();
      await tester.pump();
      final page = find
          .ancestor(
            of: find.text('Its words'),
            matching: find.byType(ComicScaffold),
          )
          .first;
      expect(tester.getRect(page), screen);
      expect(find.text('The first page'), findsNothing);
      expect(tester.hasRunningAnimations, isFalse);

      navigator.currentState!.pop();
      await tester.pump();
      expect(find.text('Its words'), findsNothing);
      expect(
        tester.getRect(
          find
              .ancestor(
                of: find.text('The first page'),
                matching: find.byType(ComicScaffold),
              )
              .first,
        ),
        screen,
      );
      expect(tester.hasRunningAnimations, isFalse);
    },
    variant: TargetPlatformVariant.all(),
  );

  testWidgets('on iOS the edge swipe still takes a page back', (tester) async {
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(_app(navigator));
    navigator.currentState!.push(_second()).ignore();
    await tester.pump();
    await tester.dragFrom(const Offset(4, 300), const Offset(600, 0));
    await tester.pumpAndSettle();
    expect(find.text('Its words'), findsNothing);
    expect(find.text('The first page'), findsOneWidget);
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

  test(
    "every platform has Comic's page change, iOS's in ui_core's swipe back",
    () {
      for (final platform in TargetPlatform.values) {
        final builder = comicPageTransitions[platform];
        expect(
          builder is SwipeBackPageTransitionsBuilder
              ? builder.builder
              : builder,
          isA<ComicPageTransitionsBuilder>(),
          reason: '$platform',
        );
        expect(
          builder is SwipeBackPageTransitionsBuilder,
          platform == TargetPlatform.iOS,
          reason: '$platform',
        );
      }
    },
  );
}
