// A page change under Comic is a panel wipe on every platform: a page pushed or popped stands in its place, whole,
// in every frame, revealed from the reading start (and wiped back as it pops), nothing sliding; on iOS the edge swipe
// still takes a page back.
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
    'a page pushed or popped wipes: whole and in place in every frame, the page under it showing until it is done',
    (tester) async {
      final navigator = GlobalKey<NavigatorState>();
      await tester.pumpWidget(_app(navigator));
      final screen = tester.getRect(find.byType(Navigator));
      Rect pageOf(String words) => tester.getRect(
        find
            .ancestor(
              of: find.text(words),
              matching: find.byType(ComicScaffold),
            )
            .first,
      );

      navigator.currentState!.push(_second()).ignore();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));
      expect(pageOf('Its words'), screen, reason: 'nothing slides');
      expect(find.text('The first page'), findsOneWidget, reason: 'wiping');
      expect(tester.hasRunningAnimations, isTrue);
      await tester.pumpAndSettle();
      expect(find.text('The first page'), findsNothing);

      navigator.currentState!.pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 40));
      expect(pageOf('Its words'), screen, reason: 'nothing slides');
      expect(pageOf('The first page'), screen);
      await tester.pumpAndSettle();
      expect(find.text('Its words'), findsNothing);
      expect(tester.hasRunningAnimations, isFalse);
    },
    variant: TargetPlatformVariant.all(),
  );

  testWidgets('on iOS the edge swipe still takes a page back', (tester) async {
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(_app(navigator));
    navigator.currentState!.push(_second()).ignore();
    await tester.pumpAndSettle();
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
