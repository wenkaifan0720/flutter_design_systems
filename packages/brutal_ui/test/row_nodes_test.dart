// Brutal's rows and text scale: a row's control at its end keeps a node of its own (a screen reader reaches the row's
// menu); a row's name reads its status tag and leaves out a monogram that repeats its title; the end slot is bounded;
// the rules between rows reach under the end column. A chip's, a segment's and a button's glyph grow with the words
// beside it; a person's monogram grows with text up to 2x, its letters inside its square.
import 'package:brutal_ui/brutal_ui.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _page(Widget child, {double scale = 1}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  home: BrutalTheme(
    data: BrutalThemeData.light(),
    child: Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: Align(
          alignment: Alignment.topCenter,
          child: SizedBox(width: 390, child: child),
        ),
      ),
    ),
  ),
);

const _ada = 'Ada Lovelace';

void main() {
  setUpAll(brutalLoadFonts);

  testWidgets(
    "a row's name reads its tag, not a monogram repeating its title; its end control keeps its node",
    (tester) async {
      final semantics = tester.ensureSemantics();
      var menu = 0;
      await tester.pumpWidget(
        _page(
          BrutalListGroup(
            children: [
              BrutalListTile(
                title: 'Low Tide',
                subtitle: 'Doors at 19:00',
                trailing: const BrutalTag('Sold out'),
                onTap: () {},
              ),
              BrutalListTile(
                title: _ada,
                leading: const BrutalAvatar(name: _ada),
                onTap: () {},
              ),
              BrutalListTile(
                title: 'Night Market',
                onTap: () {},
                trailing: BrutalIconButton(
                  icon: const Icon(IconData(0xe5d4)),
                  tooltip: 'More',
                  onPressed: () => menu++,
                ),
              ),
            ],
          ),
        ),
      );
      final rows = find.semantics
          .byPredicate(
            (n) => n.getSemanticsData().hasAction(SemanticsAction.tap),
          )
          .evaluate()
          .toList();
      final tide = rows.firstWhere((n) => n.label.contains('Low Tide'));
      expect(
        tide.label.toLowerCase(),
        contains('sold out'),
        reason: 'the status tag is in the row\'s name',
      );
      final ada = rows.firstWhere((n) => n.label.contains(_ada));
      expect(
        _ada.allMatches(ada.label).length,
        1,
        reason: 'the monogram does not repeat the title: "${ada.label}"',
      );
      final more = rows.where((n) => n.tooltip == 'More' || n.label == 'More');
      expect(
        more,
        hasLength(1),
        reason: 'the end control is a node of its own',
      );
      tester.semantics.tap(
        find.semantics.byPredicate(
          (n) => n.tooltip == 'More' || n.label == 'More',
        ),
      );
      expect(menu, 1);
      semantics.dispose();
    },
  );

  testWidgets(
    'the end slot is bounded, and the rules between rows reach under it',
    (tester) async {
      await tester.pumpWidget(
        _page(
          const BrutalListGroup(
            children: [
              BrutalListTile(
                title: 'Tickets',
                trailingText: 'A value much too long to stand beside a title at the end of a row',
              ),
              BrutalListTile(title: 'Seats', trailingText: '12'),
            ],
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.text('Tickets')).width,
        greaterThan(40),
        reason: 'the title keeps its room',
      );
      // The rule between the rows runs under the end column: ink just inside the frame's end edge, between the rows.
      final first = tester.getRect(find.byType(BrutalListTile).first);
      final second = tester.getRect(find.byType(BrutalListTile).last);
      final group = tester.getRect(find.byType(BrutalListGroup));
      expect(
        second.top - first.bottom,
        greaterThan(0),
        reason: 'a rule between them',
      );
      expect(
        first.right,
        moreOrLessEquals(second.right),
        reason: 'the rows share one end edge',
      );
      expect(
        group.right - first.right,
        lessThanOrEqualTo(4),
        reason: 'the rows (and the rule between them) run to the frame',
      );
    },
  );

  testWidgets('glyphs beside words grow with them, and a tag with its words', (
    tester,
  ) async {
    Future<Map<String, double>> sizes(double scale) async {
      await tester.pumpWidget(
        _page(
          Column(
            children: [
              BrutalChip(
                label: 'Free',
                icon: const IconData(0xe047),
                selected: false,
                onSelected: (_) {},
              ),
              BrutalSegmentedButton<int>(
                segments: const [
                  BrutalSegment(
                    value: 0,
                    label: 'Day',
                    icon: Icon(IconData(0xe048)),
                  ),
                  BrutalSegment(value: 1, label: 'Night'),
                ],
                value: 0,
                onChanged: (_) {},
              ),
              BrutalButton.filled(
                'Buy',
                onPressed: () {},
                icon: const Icon(IconData(0xe049)),
              ),
              const BrutalTag('Sold out'),
            ],
          ),
          scale: scale,
        ),
      );
      Size icon(int code) => tester.getSize(
        find.byWidgetPredicate((w) => w is Icon && w.icon?.codePoint == code),
      );
      return {
        'chip': icon(0xe047).height,
        'segment': icon(0xe048).height,
        'button': icon(0xe049).height,
        'tag': tester.getSize(find.byType(BrutalTag)).height,
      };
    }

    final one = await sizes(1);
    final two = await sizes(2);
    for (final part in one.keys) {
      expect(two[part]! / one[part]!, greaterThan(1.5), reason: part);
    }
  });

  testWidgets(
    'a monogram grows with text up to 2x, its letters inside its square',
    (tester) async {
      Future<double> side(double scale) async {
        await tester.pumpWidget(
          _page(
            const Center(child: BrutalAvatar(name: _ada)),
            scale: scale,
          ),
        );
        final avatar = tester.getRect(find.byType(BrutalAvatar));
        final letters = tester.getRect(find.text('AL'));
        expect(
          avatar.contains(letters.topLeft) &&
              avatar.contains(letters.bottomRight),
          isTrue,
          reason: 'the letters inside at $scale',
        );
        return avatar.height;
      }

      final one = await side(1);
      final two = await side(2);
      expect(two / one, moreOrLessEquals(2, epsilon: .05));
      expect(await side(3), two, reason: 'up to 2x');
    },
  );
}
