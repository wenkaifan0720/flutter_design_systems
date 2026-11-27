// The app frame's parts beside and under a page: a drawer stands its own width in a Row, a tab bar under a page draws
// one rule, and on a desktop the top bar's words and the footer's act keep to the page's column.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:comic_ui/comic_ui.dart';

import 'support.dart';

const _places = [
  ComicNavItem(label: 'Books', short: 'Books', icon: ComicGlyphs.house),
  ComicNavItem(label: 'Settings', short: 'Settings', icon: ComicGlyphs.person),
];

Future<void> _pump(
  WidgetTester tester,
  double width,
  Widget page, {
  TextDirection direction = TextDirection.ltr,
}) async {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(comicApp(page, width: width, direction: direction));
  await tester.pump();
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await loadComicFonts();
  });

  testWidgets('a drawer beside the page in a Row stands its own width', (
    tester,
  ) async {
    await _pump(
      tester,
      1440,
      Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ComicNavigationDrawer(
            destinations: _places,
            onDestinationSelected: (_) {},
          ),
          const Expanded(child: SizedBox.expand()),
        ],
      ),
    );
    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(ComicNavigationDrawer)).width, 304);
    expect(find.text('Books'), findsOneWidget);
  });

  testWidgets('a drawer takes the width it is given', (tester) async {
    await _pump(
      tester,
      1440,
      Row(
        children: [
          ComicNavigationDrawer(
            destinations: _places,
            width: 280,
            onDestinationSelected: (_) {},
          ),
          const Expanded(child: SizedBox.expand()),
        ],
      ),
    );
    expect(tester.getSize(find.byType(ComicNavigationDrawer)).width, 280);
  });

  for (final dark in [false, true]) {
    testWidgets(
      'a tab bar at a page\'s foot draws one rule over it (dark: $dark)',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          comicApp(
            ComicScaffold(
              topBar: const ComicAppBar(title: 'Books'),
              body: const SizedBox(height: 200),
              footer: ComicNavigationBar(
                destinations: _places,
                onDestinationSelected: (_) {},
              ),
            ),
            dark: dark,
          ),
        );
        await tester.pump();
        final ruledAbove = find.ancestor(
          of: find.byType(ComicNavigationBar),
          matching: find.byWidgetPredicate(
            (w) =>
                w is DecoratedBox &&
                w.decoration is BoxDecoration &&
                ((w.decoration as BoxDecoration).border?.top.width ?? 0) > 0,
          ),
        );
        expect(ruledAbove, findsNothing);
        // The bar stands at the page's foot, its full width.
        expect(tester.getSize(find.byType(ComicNavigationBar)).width, 390);
        expect(tester.getRect(find.byType(ComicNavigationBar)).bottom, 844);
      },
    );
  }

  for (final width in [1440.0, 1920.0]) {
    for (final direction in TextDirection.values) {
      testWidgets(
        'on a desktop the footer act ends with the page column / $width ${direction.name}',
        (tester) async {
          const body = ValueKey('column'), save = ValueKey('save');
          await _pump(
            tester,
            width,
            ComicScaffold(
              topBar: const ComicAppBar(title: 'Add a book'),
              body: const ComicSections(
                children: [
                  SizedBox(key: body, height: 40, width: double.infinity),
                ],
              ),
              footer: ComicButton.filled('Save', key: save, onPressed: () {}),
            ),
            direction: direction,
          );
          final column = tester.getRect(find.byKey(body));
          final act = tester.getRect(find.byKey(save));
          if (direction == TextDirection.ltr) {
            expect(act.right, moreOrLessEquals(column.right, epsilon: .5));
          } else {
            expect(act.left, moreOrLessEquals(column.left, epsilon: .5));
          }
        },
      );

      testWidgets(
        'on a desktop the top bar\'s title starts with the page column / $width ${direction.name}',
        (tester) async {
          const body = ValueKey('column');
          await _pump(
            tester,
            width,
            const ComicScaffold(
              topBar: ComicAppBar(title: 'Books'),
              body: ComicSections(
                children: [
                  SizedBox(key: body, height: 40, width: double.infinity),
                ],
              ),
            ),
            direction: direction,
          );
          final column = tester.getRect(find.byKey(body));
          final title = tester.getRect(find.text('BOOKS'));
          if (direction == TextDirection.ltr) {
            expect(title.left, moreOrLessEquals(column.left, epsilon: 1));
          } else {
            expect(title.right, moreOrLessEquals(column.right, epsilon: 1));
          }
        },
      );
    }
  }
}
