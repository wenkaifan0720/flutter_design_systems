// A list row's trailing slot: a control there keeps its own semantics node
// (the row menu is reachable by a screen reader, in a swipe row too), the
// slot is bounded so a long tag ellipsizes instead of pushing the title
// out, and the group's rules run on to the trailing column's edge.
import 'package:material_ui/material_ui.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:minimal_ui/minimal_host.dart';

Widget _page(Widget body, {TextDirection direction = TextDirection.ltr}) =>
    MaterialApp(
      builder: (context, app) => Directionality(
        textDirection: direction,
        child: MinimalHost(brightness: Brightness.light, child: app!),
      ),
      home: Builder(
        builder: (context) => MinimalScaffold(
          maxWidth: MinimalLayout.contentWidth(context),
          padding: EdgeInsets.zero,
          body: body,
        ),
      ),
    );

MinimalListTile _row(String title, {Widget? trailing}) => MinimalListTile(
  title: title,
  onTap: () {},
  trailing:
      trailing ??
      MinimalMenu.button(
        LucideIcons.ellipsis,
        semanticLabel: '$title actions',
        items: [MinimalMenuItem('Delete', onPressed: () {})],
      ),
);

void _size(WidgetTester tester, double width) {
  tester.view
    ..physicalSize = Size(width, 900)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('the row menu keeps its own node beside the row', (tester) async {
    await tester.pumpWidget(
      _page(MinimalListSection(children: [_row('Dune')])),
    );
    await tester.pumpAndSettle();
    final menu = find.semantics.byLabel('Dune actions');
    expect(menu, findsOneWidget);
    expect(
      menu.evaluate().single.getSemanticsData().hasAction(SemanticsAction.tap),
      isTrue,
    );
    final row = find.semantics.byPredicate(
      (node) =>
          node.label.startsWith('Dune') &&
          node.getSemanticsData().hasAction(SemanticsAction.tap),
    );
    expect(row, findsNWidgets(2));
  });

  testWidgets('in a swipe row too', (tester) async {
    await tester.pumpWidget(
      _page(
        MinimalListSection(
          children: [
            MinimalSwipeActions(
              trailing: [MinimalSwipeAction('Archive', onPressed: () {})],
              child: _row('Dune'),
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.semantics.byLabel('Dune actions'), findsOneWidget);
  });

  for (final direction in TextDirection.values) {
    testWidgets('a long tag ellipsizes in a bounded slot (${direction.name})', (
      tester,
    ) async {
      _size(tester, 390);
      await tester.pumpWidget(
        _page(
          MinimalListSection(
            children: [
              _row(
                'Dune',
                trailing: const MinimalTag(
                  'Wanted since the spring of last year, on a friend\'s word',
                  tone: MinimalTone.primary,
                ),
              ),
            ],
          ),
          direction: direction,
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final row = tester.getRect(find.byType(MinimalListTile));
      final tag = tester.getRect(find.byType(MinimalTag));
      final title = tester.getRect(find.text('Dune'));
      // The line is the row less its gutters; the tag takes two thirds of
      // it at most, and the title the rest.
      final line = row.width - 2 * MinimalChromeMetrics.gutter;
      expect(tag.width, lessThanOrEqualTo(line * 2 / 3));
      expect(tag.width, greaterThan(line / 2));
      expect(tag.left, greaterThanOrEqualTo(row.left));
      expect(tag.right, lessThanOrEqualTo(row.right));
      // The title keeps its words, clear of the tag.
      expect(
        direction == TextDirection.ltr
            ? title.right <= tag.left
            : title.left >= tag.right,
        isTrue,
      );
    });
  }

  for (final width in const [390.0, 1440.0]) {
    testWidgets('the rules reach the trailing column (${width.toInt()})', (
      tester,
    ) async {
      _size(tester, width);
      await tester.pumpWidget(
        _page(MinimalListSection(children: [_row('Dune'), _row('Emma')])),
      );
      await tester.pumpAndSettle();
      final section = tester.getRect(find.byType(MinimalListSection));
      final rules = <Rect>[];
      expect(
        tester.renderObject(find.byType(MinimalListSection)),
        paints..everything((method, arguments) {
          if (method == #drawRect) {
            final rect = arguments[0] as Rect;
            if (rect.height <= 1 && rect.width > 100) rules.add(rect);
          }
          return true;
        }),
      );
      expect(rules, hasLength(1));
      final menu = tester.getRect(find.byType(MinimalMenu).first);
      final row = tester.getRect(find.byType(MinimalListTile).first);
      final rule = rules.single.shift(section.topLeft);
      // The rule's end meets the menu's drawn edge or runs past it.
      expect(rule.right, greaterThanOrEqualTo(menu.right - 0.5));
      expect(rule.right, lessThanOrEqualTo(row.right));
      // ignore: avoid_print
      print('W $width rule $rule menu $menu row $row');
    });
  }
}
