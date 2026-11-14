// Each everyday part mirrors right to left (ui_core's shared check, world_checks.dart): its words and icons stand where
// their left-to-right twins stand, reflected across the screen, at the same height and size. The words themselves
// still read in their own direction; only their places mirror.
import 'package:material_ui/material_ui.dart' show MaterialApp;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:comic_ui/comic_ui.dart';

import 'support.dart';
import 'world_checks.dart';

const _width = 390.0;

Widget Function(TextDirection) _at(Widget part) =>
    (direction) => comicApp(
      Align(
        alignment: AlignmentDirectional.topStart,
        child: SizedBox(width: _width - 30, child: part),
      ),
      direction: direction,
    );

void main() {
  setUpAll(loadComicFonts);

  final parts = <String, (Widget, List<Finder>)>{
    'button with an icon': (
      ComicButton('Share', icon: ComicGlyphs.share2, onPressed: () {}),
      [find.text('SHARE'), find.byIcon(ComicGlyphs.share2)],
    ),
    'filled button': (
      ComicButton.filled('New plan', icon: ComicGlyphs.plus, onPressed: () {}),
      [find.text('NEW PLAN'), find.byIcon(ComicGlyphs.plus)],
    ),
    'chip with an icon': (
      ComicChip('Saved', icon: ComicGlyphs.check, onPressed: () {}),
      [find.text('Saved'), find.byIcon(ComicGlyphs.check)],
    ),
    'text field': (
      ComicTextField(
        label: 'Weight',
        hint: 'In kilograms',
        leading: const Icon(ComicGlyphs.search),
        trailing: const Text('kg'),
        onChanged: (_) {},
      ),
      [find.byIcon(ComicGlyphs.search), find.text('kg')],
    ),
    'list tile': (
      ComicListTile(
        title: 'Issue 12',
        subtitle: 'Twelve pages',
        leading: const Icon(ComicGlyphs.house),
        trailing: const Text('New'),
        onPressed: () {},
      ),
      [find.text('Issue 12'), find.byIcon(ComicGlyphs.house), find.text('New')],
    ),
    'switch row': (
      ComicSwitchRow(
        label: 'Reminders',
        note: 'The evening before',
        value: true,
        onChanged: (_) {},
      ),
      [find.text('Reminders'), find.byType(ComicSwitch)],
    ),
    'checkbox': (
      ComicCheckbox(label: 'Unread only', value: true, onChanged: (_) {}),
      [find.byType(ComicCheckbox)],
    ),
    'segmented button': (
      ComicSegmentedButton<String>(
        label: 'View',
        value: 'all',
        segments: const [
          ComicButtonSegment('all', 'All'),
          ComicButtonSegment('saved', 'Saved'),
          ComicButtonSegment('read', 'Read'),
        ],
        onChanged: (_) {},
      ),
      [find.text('All'), find.text('Read')],
    ),
    'tab bar': (
      ComicTabBar(
        tabs: const ['All', 'Saved', 'Read'],
        selectedIndex: 0,
        onChanged: (_) {},
      ),
      [find.text('All'), find.text('Read')],
    ),
    'number field': (
      ComicNumberField(value: 3, unit: 'nights', onChanged: (_) {}),
      [find.byIcon(ComicGlyphs.minus), find.byIcon(ComicGlyphs.plus)],
    ),
    'navigation bar': (
      ComicNavigationBar(
        destinations: const [
          ComicNavItem(label: 'Home', short: 'Home', icon: ComicGlyphs.house),
          ComicNavItem(
            label: 'Alerts',
            short: 'Alerts',
            icon: ComicGlyphs.bell,
          ),
          ComicNavItem(label: 'You', short: 'You', icon: ComicGlyphs.person),
        ],
        selectedIndex: 0,
        onDestinationSelected: (_) {},
      ),
      [find.byIcon(ComicGlyphs.house), find.byIcon(ComicGlyphs.person)],
    ),
    'pagination': (
      ComicPagination(count: 12, page: 2, onChanged: (_) {}),
      [find.text('1'), find.text('12')],
    ),
  };

  // An app that sets its direction above the theme (as the gallery does) keeps it: the theme's words don't reset it.
  for (final material in [true, false]) {
    testWidgets('a direction set above the theme stands under it '
        '(${material ? 'MaterialApp' : 'WidgetsApp'})', (tester) async {
      Widget wrap(BuildContext context, Widget? child) => Directionality(
        textDirection: TextDirection.rtl,
        child: ComicTheme(data: ComicThemeData.offset(), child: child!),
      );
      const home = SizedBox(key: ValueKey('home'));
      await tester.pumpWidget(
        material
            ? MaterialApp(builder: wrap, home: home)
            : WidgetsApp(
                color: const Color(0xFF000000),
                builder: (context, _) => wrap(context, home),
              ),
      );
      expect(
        Directionality.of(tester.element(find.byKey(const ValueKey('home')))),
        TextDirection.rtl,
      );
    });
  }

  for (final MapEntry(key: name, value: (part, finders)) in parts.entries) {
    testWidgets('$name mirrors right to left', (tester) async {
      tester.view.physicalSize = const Size(_width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await expectMirrorsInRtl(tester, _at(part), parts: finders);
    });
  }
}
