// A desktop page keeps a readable column: on a wide window a page's panels and fields stand no
// wider than the column, on the masthead's start keyline, and its title's actions and its footer end where the column
// ends. A phone's page keeps its whole width; a full-bleed page takes the window.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:comic_ui/comic_ui.dart';

import 'support.dart';

const _panel = ValueKey('panel');
const _field = ValueKey('field');
const _edit = ValueKey('edit');
const _delete = ValueKey('delete');
const _save = ValueKey('save');

const _places = [
  ComicNavItem(label: 'Books', short: 'Books', icon: ComicGlyphs.house),
  ComicNavItem(label: 'Settings', short: 'Me', icon: ComicGlyphs.person),
];

Widget _page({
  bool footer = false,
  bool fullBleed = false,
  bool scroll = true,
  double maxWidth = ComicScaffold.readableWidth,
}) => ComicScaffold(
  topBar: ComicAppBar(
    title: 'Stoner',
    actions: [
      ComicIconButton(
        ComicGlyphs.edit,
        key: _edit,
        semanticLabel: 'Edit',
        onPressed: () {},
      ),
      ComicIconButton(
        ComicGlyphs.trash2,
        key: _delete,
        semanticLabel: 'Delete',
        onPressed: () {},
      ),
    ],
  ),
  fullBleed: fullBleed,
  scroll: scroll,
  maxWidth: maxWidth,
  footer: footer
      ? ComicButton.filled('Save', key: _save, onPressed: () {})
      : null,
  body: const ComicSections(
    children: [
      ComicPanel(key: _panel, caption: 'Details', child: Text('John Williams')),
      ComicTextField(key: _field, labelText: 'Title'),
    ],
  ),
);

Widget _shell(Widget page) => ComicAppShell.branches(
  brand: 'Shelf',
  destinations: _places,
  selectedIndex: 0,
  onDestinationSelected: (_) {},
  branches: [(context) => page, (context) => const SizedBox()],
);

Future<void> _pump(
  WidgetTester tester,
  Widget home, {
  double width = 1440,
  TextDirection direction = TextDirection.ltr,
}) async {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(comicApp(home, width: width, direction: direction));
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await loadComicFonts();
  });

  for (final direction in TextDirection.values) {
    final rtl = direction == TextDirection.rtl;
    testWidgets(
      'a desktop page under the masthead keeps a readable column / ${direction.name}',
      (tester) async {
        await _pump(tester, _shell(_page()), direction: direction);
        final panel = tester.getRect(find.byKey(_panel));
        final field = tester.getRect(find.byKey(_field));
        final brand = tester.getRect(find.byType(ComicLogo));
        // A readable measure: no wider than a column of 880, not a strip.
        expect(panel.width, inInclusiveRange(600, 880));
        expect(field.width, lessThanOrEqualTo(880));
        // The column keeps the masthead's start keyline.
        expect(
          rtl ? panel.right : panel.left,
          moreOrLessEquals(rtl ? brand.right : brand.left, epsilon: .5),
        );
        // The page's actions end where its column ends, not at the window's edge.
        final last = tester.getRect(find.byKey(_delete));
        expect(
          rtl ? last.left : last.right,
          moreOrLessEquals(rtl ? panel.left : panel.right, epsilon: .5),
        );
      },
    );

    testWidgets(
      'a desktop page with its own bar and a footer keeps them to its column / ${direction.name}',
      (tester) async {
        await _pump(tester, _page(footer: true), direction: direction);
        final panel = tester.getRect(find.byKey(_panel));
        expect(panel.width, inInclusiveRange(600, 880));
        final last = tester.getRect(find.byKey(_delete));
        final save = tester.getRect(find.byKey(_save));
        expect(
          rtl ? last.left : last.right,
          moreOrLessEquals(rtl ? panel.left : panel.right, epsilon: .5),
        );
        expect(
          rtl ? save.left : save.right,
          moreOrLessEquals(rtl ? panel.left : panel.right, epsilon: .5),
        );
      },
    );
  }

  testWidgets('a page asks for no measure and reads in the readable column', (
    tester,
  ) async {
    await _pump(
      tester,
      _shell(
        const ComicScaffold(
          body: ComicPanel(key: _panel, caption: 'Details', child: Text('x')),
        ),
      ),
    );
    expect(
      tester.getRect(find.byKey(_panel)).width,
      ComicScaffold.readableWidth,
    );
  });

  testWidgets(
    'a form keeps a narrower column, its actions and footer with it',
    (tester) async {
      await _pump(tester, _shell(_page(footer: true, maxWidth: 640)));
      final panel = tester.getRect(find.byKey(_panel));
      expect(panel.width, 640);
      expect(
        tester.getRect(find.byKey(_delete)).right,
        moreOrLessEquals(panel.right, epsilon: .5),
      );
      expect(
        tester.getRect(find.byKey(_save)).right,
        moreOrLessEquals(panel.right, epsilon: .5),
      );
    },
  );

  testWidgets('a board takes the desktop frame', (tester) async {
    await _pump(tester, _shell(_page(maxWidth: double.infinity)));
    expect(
      tester.getRect(find.byKey(_panel)).width,
      1376 - 2 * ComicSpace.tier,
    );
  });

  testWidgets('a page that scrolls itself keeps the column too', (
    tester,
  ) async {
    await _pump(tester, _shell(_page(scroll: false)));
    expect(
      tester.getRect(find.byKey(_panel)).width,
      ComicScaffold.readableWidth,
    );
  });

  testWidgets(
    'a window wider than the frame centres it, the column at its start',
    (tester) async {
      await _pump(tester, _shell(_page()), width: 1920);
      final panel = tester.getRect(find.byKey(_panel));
      final brand = tester.getRect(find.byType(ComicLogo));
      expect(panel.left, moreOrLessEquals(brand.left, epsilon: .5));
      expect(
        panel.left,
        moreOrLessEquals((1920 - 1376) / 2 + ComicSpace.tier, epsilon: .5),
      );
    },
  );

  testWidgets('a phone page keeps its whole width', (tester) async {
    await _pump(tester, _shell(_page()), width: 390);
    final panel = tester.getRect(find.byKey(_panel));
    expect(
      panel.width,
      moreOrLessEquals(390 - 2 * ComicSpace.near, epsilon: .5),
    );
  });

  testWidgets('a full-bleed desktop page takes the window', (tester) async {
    await _pump(tester, _page(fullBleed: true));
    expect(tester.getRect(find.byKey(_panel)).width, 1440);
  });
}
