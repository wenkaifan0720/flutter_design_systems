// Things that sit side by side line up, measured from the layout under every corner family Customize offers, at a
// phone and a desktop width: icons centre on the words beside them in rows, fields, buttons, the app bar, the nav bar,
// the rail, the tab bar and the pager; words in a row of buttons, tabs or segments share one baseline; the buttons,
// tabs and segments of one row share one height.
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:comic_ui/comic_ui.dart';

// ignore_for_file: avoid_relative_lib_imports
import '../example/lib/main.dart';
import 'gallery_support.dart';
import 'support.dart';

const _tolerance = 1.0;

Rect _rect(WidgetTester tester, Element e) {
  final box = e.renderObject! as RenderBox;
  return box.localToGlobal(Offset.zero) & box.size;
}

/// The glyphs drawn under [of].
List<Element> _icons(Finder of) =>
    find.descendant(of: of, matching: find.byType(Icon)).evaluate().toList();

/// The paragraphs with words in them under [of].
List<Element> _words(Finder of) => find
    .descendant(of: of, matching: find.byType(RichText))
    .evaluate()
    .where((e) {
      // An icon is drawn as a glyph in a paragraph of its own; it is measured as an icon.
      if (e.findAncestorWidgetOfExactType<Icon>() != null) return false;
      final ro = e.renderObject;
      return ro is RenderParagraph && ro.text.toPlainText().trim().isNotEmpty;
    })
    .toList();

/// [e]'s first line's alphabetic baseline, in the view, measured by laying its words out again as it did.
double _baseline(Element e) {
  final ro = e.renderObject! as RenderParagraph;
  final painter = TextPainter(
    text: ro.text,
    textDirection: ro.textDirection,
    textScaler: ro.textScaler,
    maxLines: ro.maxLines,
    textWidthBasis: ro.textWidthBasis,
    textHeightBehavior: ro.textHeightBehavior,
    strutStyle: ro.strutStyle,
  )..layout(maxWidth: ro.size.width);
  final down = painter.computeDistanceToActualBaseline(TextBaseline.alphabetic);
  painter.dispose();
  return ro.localToGlobal(Offset(0, down)).dy;
}

/// [e]'s first line's centre, in the view: the line box, as centre_test measures it.
double _lineCentre(Element e) {
  final ro = e.renderObject! as RenderParagraph;
  final lines = ro.getBoxesForSelection(
    TextSelection(baseOffset: 0, extentOffset: ro.text.toPlainText().length),
  );
  final first = lines.isEmpty ? Offset.zero & ro.size : lines.first.toRect();
  return ro.localToGlobal(Offset(0, first.center.dy)).dy;
}

String _text(Element e) =>
    (e.renderObject! as RenderParagraph).text.toPlainText();

void _same(Iterable<(String, double)> values, String what) {
  final list = values.toList();
  if (list.length < 2) return;
  final first = list.first;
  for (final (name, v) in list.skip(1)) {
    expect(
      (v - first.$2).abs(),
      lessThanOrEqualTo(_tolerance),
      reason:
          '$what: $name at $v, ${first.$1} at ${first.$2} '
          '(all: ${list.map((e) => '${e.$1} ${e.$2.toStringAsFixed(1)}').join(', ')})',
    );
  }
}

void main() {
  setUpAll(() async {
    await loadComicFonts();
    await loadBundledFonts();
  });

  const items = [
    ComicNavItem(label: 'Home', short: 'Home', icon: ComicGlyphs.plus),
    ComicNavItem(label: 'Search', short: 'Find', icon: ComicGlyphs.search),
    ComicNavItem(
      label: 'Alerts',
      short: 'Alerts',
      icon: ComicGlyphs.bell,
      badge: '3',
      badgeLabel: '3 new',
    ),
    ComicNavItem(label: 'More', short: 'More', icon: ComicGlyphs.more),
  ];

  for (final corners in GalleryCorners.values) {
    final custom = GalleryCustom(corners: corners);
    for (final width in [galleryWidth, 1440.0]) {
      final at = '${corners.name}/${width.toInt()}';

      Future<void> pump(WidgetTester tester, Widget child) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final theme = custom.theme('offset', Brightness.light).atWidth(width);
        await tester.pumpWidget(
          MaterialApp(
            debugShowCheckedModeBanner: false,
            home: ComicTheme(
              data: theme,
              child: Scaffold(
                body: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: child,
                  ),
                ),
              ),
            ),
          ),
        );
        await settle(tester);
      }

      testWidgets(
        '$at: the app bar\'s back, title and actions share a centre',
        (tester) async {
          await pump(
            tester,
            ComicAppBar(
              title: 'Issues',
              leading: ComicBackButton(onPressed: () {}),
              actions: [
                ComicIconButton(
                  ComicGlyphs.search,
                  label: 'Search',
                  onPressed: () {},
                ),
                ComicIconButton(
                  ComicGlyphs.more,
                  label: 'More',
                  onPressed: () {},
                ),
              ],
            ),
          );
          final bar = find.byType(ComicAppBar);
          _same([
            for (final i in _icons(bar)) ('icon', _rect(tester, i).center.dy),
            for (final w in _words(bar)) (_text(w), _lineCentre(w)),
          ], 'app bar centres');
        },
      );

      testWidgets(
        '$at: the nav bar\'s icons share a centre and its words a baseline',
        (tester) async {
          await pump(
            tester,
            ComicNavigationBar(
              destinations: items,
              selectedIndex: 1,
              onDestinationSelected: (_) {},
            ),
          );
          final bar = find.byType(ComicNavigationBar);
          final icons = _icons(bar);
          expect(icons, hasLength(items.length));
          _same([
            for (final i in icons) ('icon', _rect(tester, i).center.dy),
          ], 'nav bar icons');
          final words = _words(bar).where((w) => _text(w).length > 1).toList();
          expect(words, hasLength(items.length));
          _same([
            for (final w in words) (_text(w), _baseline(w)),
          ], 'nav bar words');
          // Each word sits under its own icon.
          for (var i = 0; i < items.length; i++) {
            _same([
              ('icon', _rect(tester, icons[i]).center.dx),
              (_text(words[i]), _rect(tester, words[i]).center.dx),
            ], 'nav bar item $i');
          }
        },
      );

      testWidgets('$at: the rail\'s icons centre over their words', (
        tester,
      ) async {
        await pump(
          tester,
          SizedBox(
            height: 600,
            child: ComicNavigationRail(
              destinations: items,
              selectedIndex: 2,
              onDestinationSelected: (_) {},
            ),
          ),
        );
        final rail = find.byType(ComicNavigationRail);
        final icons = _icons(rail);
        final words = _words(rail).where((w) => _text(w).length > 1).toList();
        expect(icons, hasLength(items.length));
        expect(words, hasLength(items.length));
        _same([
          for (final i in icons) ('icon', _rect(tester, i).center.dx),
          for (final w in words) (_text(w), _rect(tester, w).center.dx),
        ], 'rail column');
      });

      testWidgets(
        '$at: the tab bar\'s words share a baseline and its tabs a height',
        (tester) async {
          await pump(
            tester,
            ComicTabBar(
              tabs: const ['Latest', 'Popular', 'Saved'],
              selectedIndex: 1,
              onChanged: (_) {},
              label: 'Sort',
            ),
          );
          final bar = find.byType(ComicTabBar);
          final words = _words(bar);
          expect(words, hasLength(3));
          _same([for (final w in words) (_text(w), _baseline(w))], 'tab words');
          _same([
            for (final p
                in find
                    .descendant(of: bar, matching: find.byType(ComicPressable))
                    .evaluate())
              (
                (p.widget as ComicPressable).label ?? '',
                _rect(tester, p).height,
              ),
          ], 'tab heights');
        },
      );

      testWidgets('$at: a row of buttons shares one height and one baseline', (
        tester,
      ) async {
        await pump(
          tester,
          Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 12,
            children: [
              ComicButton.filled(
                'Save',
                icon: ComicGlyphs.plus,
                onPressed: () {},
              ),
              ComicButton('Cancel', onPressed: () {}),
              ComicButton.text('Later', onPressed: () {}),
            ],
          ),
        );
        final buttons = [
          find.byWidgetPredicate((w) => '${w.runtimeType}' == '_Filled'),
          find.byWidgetPredicate((w) => '${w.runtimeType}' == '_Outlined'),
          find.byWidgetPredicate((w) => '${w.runtimeType}' == '_Action'),
        ];
        _same([
          for (final b in buttons) (b.toString(), tester.getRect(b).height),
        ], 'button heights');
        _same([
          for (final b in buttons)
            for (final w in _words(b)) (_text(w), _baseline(w)),
        ], 'button baselines');
        final act = buttons.first;
        _same([
          ('icon', _rect(tester, _icons(act).single).center.dy),
          ('Save', _lineCentre(_words(act).single)),
        ], 'icon beside its word');
      });

      testWidgets(
        '$at: a segmented control\'s segments share height and baseline',
        (tester) async {
          await pump(
            tester,
            ComicSegmentedButton<String>(
              label: 'View',
              segments: const [
                ComicButtonSegment('day', 'Day'),
                ComicButtonSegment('week', 'Week'),
                ComicButtonSegment('month', 'Month'),
              ],
              value: 'week',
              onChanged: (_) {},
            ),
          );
          final group = find.byType(ComicSegmentedButton<String>);
          final words = _words(group).where((w) => _text(w) != 'View').toList();
          expect(words, hasLength(3));
          _same([
            for (final w in words) (_text(w), _baseline(w)),
          ], 'segment words');
          _same([
            for (final p
                in find
                    .descendant(
                      of: group,
                      matching: find.byType(ComicPressable),
                    )
                    .evaluate())
              (
                (p.widget as ComicPressable).label ?? '',
                _rect(tester, p).height,
              ),
          ], 'segment heights');
        },
      );

      testWidgets('$at: a field\'s icons centre on its line', (tester) async {
        await pump(
          tester,
          ComicColumn(
            children: [
              ComicTextField(
                initialValue: 'Kim Bell',
                leading: const Icon(ComicGlyphs.search),
                trailing: const Icon(ComicGlyphs.close),
              ),
              const ComicSearchField(hint: 'Search issues'),
            ],
          ),
        );
        // The search field is a text field inside; the first is the plain one.
        final field = find.byType(ComicTextField).first;
        final line = find.descendant(
          of: field,
          matching: find.byType(EditableText),
        );
        _same([
          ('line', tester.getRect(line).center.dy),
          for (final i in _icons(field)) ('icon', _rect(tester, i).center.dy),
        ], 'text field');
        final search = find.byType(ComicSearchField);
        _same([
          (
            'line',
            tester
                .getRect(
                  find.descendant(
                    of: search,
                    matching: find.byType(EditableText),
                  ),
                )
                .center
                .dy,
          ),
          for (final i in _icons(search)) ('icon', _rect(tester, i).center.dy),
        ], 'search field');
      });

      testWidgets('$at: a row\'s leading, words and trailing share a centre', (
        tester,
      ) async {
        await pump(
          tester,
          ComicColumn(
            children: [
              ComicListTile(
                title: 'Issue 12',
                leading: const Icon(ComicGlyphs.bell),
                trailing: const Icon(ComicGlyphs.more),
                onPressed: () {},
              ),
              ComicSwitchRow(label: 'Sound', value: true, onChanged: (_) {}),
              ComicCheckRow(
                label: 'Keep issue',
                value: true,
                onChanged: (_) {},
              ),
            ],
          ),
        );
        final tile = find.byType(ComicListTile);
        _same([
          for (final i in _icons(tile)) ('icon', _rect(tester, i).center.dy),
          for (final w in _words(tile)) (_text(w), _lineCentre(w)),
        ], 'list row');
        final row = find.byType(ComicSwitchRow);
        _same([
          (
            'switch',
            tester
                .getRect(
                  find.descendant(of: row, matching: find.byType(ComicSwitch)),
                )
                .center
                .dy,
          ),
          for (final w in _words(row)) (_text(w), _lineCentre(w)),
        ], 'switch row');
        final check = find.byType(ComicCheckRow);
        _same([
          (
            'box',
            tester
                .getRect(
                  find.descendant(
                    of: check,
                    matching: find.byType(ComicCheckbox),
                  ),
                )
                .center
                .dy,
          ),
          for (final w in _words(check)) (_text(w), _lineCentre(w)),
        ], 'check row');
      });

      for (final (kind, rows) in [
        (
          'rows',
          const [
            ComicListTile(
              title: 'Alex Morgan',
              subtitle: 'Editor',
              isFirst: true,
            ),
            ComicListTile(title: 'Sam Rivera', subtitle: 'Letterer'),
            ComicListTile(title: 'Jo Chen', subtitle: 'Colourist'),
          ],
        ),
        (
          'switch rows',
          [
            ComicSwitchRow(
              label: 'New issues',
              value: true,
              isFirst: true,
              onChanged: (_) {},
            ),
            ComicSwitchRow(label: 'Replies', value: false, onChanged: (_) {}),
          ],
        ),
      ]) {
        testWidgets(
          '$at: a group of $kind has as much room above its first words as below its last',
          (tester) async {
            await pump(
              tester,
              ComicListSection(label: 'Group', children: rows),
            );
            final group = find.byType(ComicListSection);
            final frame = _rect(
              tester,
              find
                  .descendant(of: group, matching: find.byType(ComicPanel))
                  .evaluate()
                  .first,
            );
            var top = double.infinity, bottom = -double.infinity;
            for (final w in _words(group)) {
              final ro = w.renderObject! as RenderParagraph;
              for (final box in ro.getBoxesForSelection(
                TextSelection(
                  baseOffset: 0,
                  extentOffset: ro.text.toPlainText().length,
                ),
              )) {
                final r = MatrixUtils.transformRect(
                  ro.getTransformTo(null),
                  box.toRect(),
                );
                if (r.top < top) top = r.top;
                if (r.bottom > bottom) bottom = r.bottom;
              }
            }
            final above = top - frame.top, below = frame.bottom - bottom;
            expect(
              (above - below).abs(),
              lessThanOrEqualTo(_tolerance),
              reason:
                  '$kind: ${above.toStringAsFixed(1)} above the first words, '
                  '${below.toStringAsFixed(1)} below the last',
            );
          },
        );
      }

      testWidgets('$at: the pager\'s numbers and arrows share a centre', (
        tester,
      ) async {
        await pump(
          tester,
          ComicPagination(
            count: 9,
            page: 4,
            onChanged: (_) {},
            label: 'Results',
          ),
        );
        final pager = find.byType(ComicPagination);
        _same([
          for (final i in _icons(pager)) ('icon', _rect(tester, i).center.dy),
          for (final w in _words(pager)) (_text(w), _lineCentre(w)),
        ], 'pager');
      });
    }
  }
}
