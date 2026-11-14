// Alignment, measured rather than eyeballed: in rows, fields, button groups,
// the tab bar, the nav bar and the app bar each icon's centre sits on its
// words' centre line; labels that stand side by side share one centre line;
// an action row's buttons stand equally tall. In both appearances, at a phone's
// width and a desktop's.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';

import 'support.dart';

/// The look's two appearances; each brings its own corners and edges.
const appearances = <String, RetroDesktopAppearance>{
  'chisel': RetroDesktopAppearance.chisel,
  'platinum': RetroDesktopAppearance.platinum,
};

/// Each appearance's shapes, by the appearance's name.
final families = <String, RetroDesktopShapes>{
  for (final f in appearances.entries) f.key: RetroDesktopShapes.of(f.value),
};

// One device pixel at the test's ratio of one: a centre may round either way.
const near = 1.0;

double cy(WidgetTester tester, Finder finder) => tester.getCenter(finder).dy;

void sameLine(WidgetTester tester, List<Finder> parts, String why) {
  final first = cy(tester, parts.first);
  for (final part in parts.skip(1)) {
    expect(cy(tester, part), closeTo(first, near), reason: why);
  }
}

void main() {
  setUpAll(loadRetroDesktopFonts);
  for (final family in families.entries) {
    for (final width in [390.0, 1440.0]) {
      final name = '${family.key} at $width';
      Future<void> pump(WidgetTester tester, Widget child) async {
        tester.view.physicalSize = Size(width, 1200);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          MaterialApp(
            builder: (context, app) => RetroDesktopTheme(
              data: RetroDesktopThemeData.classic().copyWith(
                appearance: appearances[family.key]!,
              ),
              child: app!,
            ),
            home: Align(
              alignment: Alignment.topCenter,
              child: SingleChildScrollView(
                child: Padding(padding: const EdgeInsets.all(16), child: child),
              ),
            ),
          ),
        );
        await tester.pump();
      }

      testWidgets('$name: a row\'s icon, words and figure share a line', (
        tester,
      ) async {
        await pump(
          tester,
          RetroDesktopList(
            children: [
              RetroDesktopListTile(
                title: 'Notes',
                leading: const Icon(RetroDesktopGlyphs.fileText),
                trailing: const Icon(RetroDesktopGlyphs.chevronRight),
                onPressed: () {},
              ),
            ],
          ),
        );
        sameLine(tester, [
          find.text('Notes'),
          find.byIcon(RetroDesktopGlyphs.fileText),
          find.byIcon(RetroDesktopGlyphs.chevronRight),
        ], '$name row');
        expect(tester.takeException(), isNull);
      });

      testWidgets('$name: a field\'s icon sits on its line of text', (
        tester,
      ) async {
        await pump(tester, const RetroDesktopSearchField(hint: 'Search files'));
        sameLine(tester, [
          find.text('Search files'),
          find.byIcon(RetroDesktopGlyphs.search),
        ], '$name search field');
        expect(tester.takeException(), isNull);
      });

      testWidgets('$name: a button group shares one centre line and height', (
        tester,
      ) async {
        await pump(
          tester,
          Wrap(
            spacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              RetroDesktopButton(
                'Add',
                icon: RetroDesktopGlyphs.plus,
                onPressed: () {},
              ),
              RetroDesktopButton('Cancel', onPressed: () {}),
              RetroDesktopButton(
                'Save',
                isDefaultAction: true,
                onPressed: () {},
              ),
            ],
          ),
        );
        sameLine(tester, [
          find.text('Add'),
          find.byIcon(RetroDesktopGlyphs.plus),
          find.text('Cancel'),
          find.text('Save'),
        ], '$name buttons');
        final heights = [
          for (final f in [
            find.byType(RetroDesktopButton).at(0),
            find.byType(RetroDesktopButton).at(1),
            find.byType(RetroDesktopButton).at(2),
          ])
            tester.getSize(f).height,
        ];
        expect(heights, everyElement(closeTo(heights.first, .01)));
        expect(tester.takeException(), isNull);
      });

      testWidgets('$name: a dialog\'s actions stand level and equally tall', (
        tester,
      ) async {
        await pump(
          tester,
          const RetroDesktopDialog(
            title: 'Keep your changes?',
            message: 'Save this document before closing its window.',
            actions: [
              RetroDesktopDialogAction('Discard', value: false),
              RetroDesktopDialogAction(
                'Save',
                value: true,
                isDefaultAction: true,
              ),
            ],
          ),
        );
        sameLine(tester, [
          find.text('Discard'),
          find.text('Save'),
        ], '$name dialog actions');
        final actions = find.byType(RetroDesktopDialogAction<bool>);
        expect(
          tester.getSize(actions.first).height,
          closeTo(tester.getSize(actions.last).height, .01),
        );
        expect(tester.takeException(), isNull);
      });

      testWidgets('$name: tabs\' labels and counts share one centre line', (
        tester,
      ) async {
        for (final panel in [null, const Text('Three for today')]) {
          await pump(
            tester,
            RetroDesktopTabBar(
              tabs: const ['Today', 'Soon', 'Later'],
              counts: const ['3', '4', '5'],
              onChanged: (_) {},
              child: panel,
            ),
          );
          sameLine(tester, [
            for (final label in ['Today', 'Soon', 'Later', '3', '4', '5'])
              find.text(label),
          ], '$name tab labels${panel == null ? '' : ' over a panel'}');
          expect(tester.takeException(), isNull);
        }
      });

      testWidgets('$name: the nav bar\'s icons and labels each share a line', (
        tester,
      ) async {
        await pump(
          tester,
          RetroDesktopNavigationBar(
            onDestinationSelected: (_) {},
            items: const [
              RetroDesktopNavItem(
                label: 'Today',
                short: 'Today',
                icon: RetroDesktopGlyphs.inbox,
              ),
              RetroDesktopNavItem(
                label: 'Places',
                short: 'Places',
                icon: RetroDesktopGlyphs.folder,
              ),
              RetroDesktopNavItem(
                label: 'You',
                short: 'You',
                icon: RetroDesktopGlyphs.user,
              ),
            ],
          ),
        );
        sameLine(tester, [
          find.byIcon(RetroDesktopGlyphs.inbox),
          find.byIcon(RetroDesktopGlyphs.folder),
          find.byIcon(RetroDesktopGlyphs.user),
        ], '$name nav icons');
        sameLine(tester, [
          for (final label in ['Today', 'Places', 'You']) find.text(label),
        ], '$name nav labels');
        expect(tester.takeException(), isNull);
      });

      testWidgets('$name: the app bar\'s title and actions share a line', (
        tester,
      ) async {
        await pump(
          tester,
          RetroDesktopAppBar(
            title: 'Documents',
            actions: [
              RetroDesktopIconButton(
                RetroDesktopGlyphs.tag,
                label: 'Tag',
                onPressed: () {},
              ),
            ],
          ),
        );
        sameLine(tester, [
          find.text('Documents'),
          find.byIcon(RetroDesktopGlyphs.tag),
        ], '$name app bar');
        expect(tester.takeException(), isNull);
      });

      testWidgets('$name: segments and page numbers share one centre line', (
        tester,
      ) async {
        await pump(
          tester,
          Column(
            children: [
              RetroDesktopSegmentedButton<String>(
                label: 'View',
                value: 'list',
                segments: const [
                  RetroDesktopButtonSegment('list', 'List'),
                  RetroDesktopButtonSegment('grid', 'Grid'),
                  RetroDesktopButtonSegment('cards', 'Cards'),
                ],
                onChanged: (_) {},
              ),
              RetroDesktopPagination(count: 5, page: 1, onChanged: (_) {}),
            ],
          ),
        );
        sameLine(tester, [
          for (final label in ['List', 'Grid', 'Cards']) find.text(label),
        ], '$name segments');
        sameLine(tester, [
          for (final label in ['1', '2', '3', '4', '5']) find.text(label),
          find.byIcon(RetroDesktopGlyphs.chevronLeft),
          find.byIcon(RetroDesktopGlyphs.chevronRight),
        ], '$name pager');
        expect(tester.takeException(), isNull);
      });
    }
  }
}
