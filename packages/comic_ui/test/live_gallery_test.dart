// The live example (polish3 §4): every page opens through the look's own navigation, the side nav at a desktop's width
// and the drawer from the app bar's menu button on a phone; it builds without an error and the app bar names it. Between
// them the pages build every component the package exports: an export no live page shows fails here, as the census in
// shape_system_test fails for the catalog's gallery.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:comic_ui/comic_ui.dart';

// ignore_for_file: avoid_relative_lib_imports
import '../example/lib/main.dart';
import '../example/lib/kit_gallery/kit.dart';
import '../example/lib/kit_gallery/live_pages.dart';
import 'gallery_support.dart';
import 'support.dart';

/// What no page shows by itself, and why.
const _offPage = {
  'ComicTextContextMenu': "built when a field's text is selected and the menu asked for; the editing tests open it",
};

/// The example's own side nav or drawer (the Navigation page shows other drawers as specimens).
final _pages = find.byWidgetPredicate(
  (w) => w is ComicNavigationDrawer && w.label == 'Pages',
);

/// Moves the example to page [id] the way a person does.
Future<void> _open(WidgetTester tester, String id, double width) async {
  if (width < 840) {
    await tester.tap(find.byKey(const ValueKey('nav/open')));
    await settle(tester);
  }
  final item = find.byKey(ValueKey('nav/$id'));
  await tester.ensureVisible(item);
  await settle(tester);
  await tester.tap(item);
  await settle(tester);
}

void main() {
  setUpAll(() async {
    await loadComicFonts();
    await loadBundledFonts();
  });

  test('the pages carry plain names in the order polish3 sets', () {
    expect(livePages.map((p) => p.title).take(16), [
      'Overview',
      'Buttons',
      'Text fields',
      'Selection',
      'Pickers',
      'Navigation',
      'Lists and tables',
      'Cards and media',
      'Dialogs and sheets',
      'Feedback',
      'Charts',
      'Type and colour',
      'Form',
      'Settings',
      'List',
      'Checkout',
    ]);
  });

  final built = <String>{};
  for (final width in [390.0, 1440.0]) {
    for (final page in livePages) {
      testWidgets(
        '${page.id} opens through the navigation at ${width.toInt()}',
        (tester) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = Size(width, 1000);
          addTearDown(tester.view.reset);
          addTearDown(() {
            kitShownTheme = null;
            kitShownPreset = 'offset';
          });
          await tester.pumpWidget(const GalleryApp());
          await settle(tester);
          if (page.id != livePages.first.id) {
            await _open(tester, page.id, width);
          }
          expect(tester.takeException(), isNull);
          expect(find.byKey(ValueKey('live/${page.id}')), findsOneWidget);
          expect(find.text(page.title.toUpperCase()), findsWidgets);
          // A phone's drawer is closed again; a desktop's side nav marks the page.
          if (width < 840) {
            expect(_pages, findsNothing);
          } else {
            expect(
              tester.widget<ComicNavigationDrawer>(_pages).selectedIndex,
              livePages.indexOf(page),
            );
          }
          for (final e in tester.allElements) {
            final name = e.widget.runtimeType.toString().split('<').first;
            if (name.startsWith('Comic') || name.startsWith('AnimatedComic')) {
              built.add(name);
            }
          }
        },
      );
    }
  }

  testWidgets('Day and Night, and Customize, reach the page on show', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1440, 1000);
    addTearDown(tester.view.reset);
    addTearDown(() {
      kitShownTheme = null;
      kitShownPreset = 'offset';
    });
    await tester.pumpWidget(const GalleryApp());
    await settle(tester);
    await _open(tester, 'selection', 1440);
    final page = find.byKey(const ValueKey('live/selection'));
    ComicThemeData shown() => ComicTheme.of(tester.element(page));
    expect(shown().colors.brightness, Brightness.light);
    await tester.tap(find.byKey(const ValueKey('appearance')));
    await settle(tester);
    expect(shown().colors.brightness, Brightness.dark);
    await tester.tap(find.byKey(const ValueKey('customize')));
    await settle(tester);
    await tester.tap(
      find.descendant(
        of: find.byType(CustomizePanel),
        matching: find.text('Large'),
      ),
    );
    await settle(tester);
    expect(shown().shapes, ComicShapes.rounded(12));
    // Natural widths: a two-way strip is not stretched across the window.
    final strokes = find.descendant(
      of: find.byType(CustomizePanel),
      matching: find.byWidgetPredicate(
        (w) => w is ComicSegmentedButton<bool> && w.label == 'Strokes',
      ),
    );
    expect(tester.getSize(strokes).width, lessThan(360));
    expect(tester.takeException(), isNull);
  });

  for (final width in [390.0, 1440.0]) {
    testWidgets('the Overview: the intro across the top, the cards in a grid '
        'under it at ${width.toInt()}', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 1000);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const GalleryApp());
      await settle(tester);
      final intro = tester.getRect(find.text('COMIC'));
      final cards = [
        for (final e in find.byType(ComicCard).evaluate())
          tester.getRect(find.byWidget(e.widget)),
      ];
      expect(cards, isNotEmpty);
      expect(cards.first.top, greaterThan(intro.bottom));
      // The paragraph starts under the title, set from the start (11-10: it was a centred balanced box).
      final words = tester.getRect(
        find.textContaining('A comic page for Flutter'),
      );
      expect((words.left - intro.left).abs(), lessThan(1));
      final columns = {for (final c in cards) c.left.round()}.length;
      if (width < 840) {
        expect(columns, 1);
      } else {
        expect(columns, greaterThanOrEqualTo(2));
        // The grid runs across the sheet, from under the intro's start.
        expect((cards.first.left - intro.left).abs(), lessThan(1));
      }
    });
  }

  test('every exported component is live on a page', () {
    final missing = publicComicWidgets()
        .difference(built)
        .difference(_offPage.keys.toSet());
    expect(
      missing,
      isEmpty,
      reason: 'Show each exported component on a live page (live_pages.dart)',
    );
  });
}
