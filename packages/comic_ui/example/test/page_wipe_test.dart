// A page change under Comic is a panel wipe on an app's own MaterialApp. comic_ui stands on material_ui (Flutter's
// Material from 3.50), and ComicTheme gives material_ui's Theme comicPageTransitions, so a MaterialPageRoute the app
// pushes stands whole and in place in every frame, revealed from the reading start, with no theme of the app's (the
// README's quick start) and with the line an app on Flutter's own MaterialApp needs (the README's set-up) alike.
//
// A widget test: the export puts package/example_unit_test/ in the example's test/, where `flutter test` runs it.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:comic_ui/comic_ui.dart';
import 'package:comic_ui_example/gallery_pages.dart' show GalleryPage;
import 'package:comic_ui_example/gallery.dart';

/// A MaterialApp with Comic installed as the README shows, with or without the page change in its own theme.
Widget _app(GlobalKey<NavigatorState> navigator, {required bool themed}) =>
    MaterialApp(
      navigatorKey: navigator,
      theme: themed
          ? ThemeData(
              pageTransitionsTheme: const PageTransitionsTheme(
                builders: comicPageTransitions,
              ),
            )
          : null,
      builder: (context, child) =>
          ComicTheme(data: ComicThemeData.offset(), child: child!),
      home: const ComicScaffold(body: Text('The first page')),
    );

/// Material's own route, as an app pushes it.
Route<void> _second() => MaterialPageRoute<void>(
  builder: (context) => const ComicScaffold(
    topBar: ComicAppBar(title: 'The second page'),
    body: Text('Its words'),
  ),
);

Rect _pageOf(WidgetTester tester, String words) => tester.getRect(
  find
      .ancestor(of: find.text(words), matching: find.byType(ComicScaffold))
      .first,
);

/// A push and its pop each wipe: the page stands whole and in place in every frame, the one under it showing until
/// the wipe is done.
Future<void> _wipes(
  WidgetTester tester,
  NavigatorState navigator,
  String first,
  String second,
) async {
  final screen = tester.getRect(find.byType(Navigator).first);
  expect(_pageOf(tester, first), screen);
  navigator.push(_second()).ignore();
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 60));
  expect(_pageOf(tester, second), screen);
  expect(find.text(first), findsOneWidget);
  expect(tester.hasRunningAnimations, isTrue);
  await tester.pumpAndSettle();
  expect(find.text(first), findsNothing);
  navigator.pop();
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 40));
  expect(_pageOf(tester, second), screen);
  expect(_pageOf(tester, first), screen);
  await tester.pumpAndSettle();
  expect(find.text(second), findsNothing);
  expect(tester.hasRunningAnimations, isFalse);
}

void main() {
  testWidgets("a MaterialPageRoute wipes with no theme of the app's", (
    tester,
  ) async {
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(_app(navigator, themed: false));
    await _wipes(
      tester,
      navigator.currentState!,
      'The first page',
      'Its words',
    );
  }, variant: TargetPlatformVariant.all());

  testWidgets(
    "a MaterialPageRoute wipes under the README's ThemeData line too",
    (tester) async {
      final navigator = GlobalKey<NavigatorState>();
      await tester.pumpWidget(_app(navigator, themed: true));
      expect(
        comicPageTransitions.values,
        everyElement(isA<PageTransitionsBuilder>()),
        reason: "One map for both Materials' PageTransitionsTheme",
      );
      await _wipes(
        tester,
        navigator.currentState!,
        'The first page',
        'Its words',
      );
    },
    variant: TargetPlatformVariant.all(),
  );

  testWidgets("a page the example's own app pushes wipes", (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1440, 900);
    addTearDown(tester.view.reset);
    final List<GalleryPage> pages = [
      (
        id: 'first',
        title: 'First',
        build: (_) => const ComicScaffold(body: Text('The gallery page')),
      ),
    ];
    await tester.pumpWidget(
      GalleryPageDeck(
        pages: pages,
        pageId: 'first',
        preset: 'offset',
        brightness: Brightness.light,
      ),
    );
    await tester.pump();
    await _wipes(
      tester,
      tester.state<NavigatorState>(find.byType(Navigator).first),
      'The gallery page',
      'Its words',
    );
    expect(tester.takeException(), isNull);
  }, variant: TargetPlatformVariant.all());

  testWidgets(
    "on iOS the edge swipe still takes a page back, the page following the finger",
    (tester) async {
      final navigator = GlobalKey<NavigatorState>();
      await tester.pumpWidget(_app(navigator, themed: false));
      navigator.currentState!.push(_second()).ignore();
      await tester.pumpAndSettle();
      final screen = tester.getRect(find.byType(Navigator).first);
      // Halfway, the page stands where the finger has it and the one under it shows.
      final swipe = await tester.startGesture(const Offset(4, 300));
      await swipe.moveBy(const Offset(20, 0));
      await swipe.moveBy(Offset(screen.width / 2 - 20, 0));
      await tester.pump();
      expect(_pageOf(tester, 'Its words').left, greaterThan(screen.width / 4));
      expect(find.text('The first page'), findsOneWidget);
      await swipe.moveBy(Offset(screen.width / 4, 0));
      await swipe.up();
      await tester.pumpAndSettle();
      expect(find.text('Its words'), findsNothing);
      expect(_pageOf(tester, 'The first page'), screen);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );
}
