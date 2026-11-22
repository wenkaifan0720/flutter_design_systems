import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:minimal_ui/minimal_host.dart';

import 'support/column_host.dart';

/// The ruled column a divided row group lays its rows out in.
final Finder _ruled = find
    .descendant(
      of: find.byType(MinimalListSection),
      matching: find.byWidgetPredicate(
        (w) => w.runtimeType.toString() == '_RuledColumn',
      ),
    )
    .first;

/// Paints exactly [count] hairline rules (static rows paint no rects of
/// their own, so every rect the column draws is a rule).
Matcher _rules(int count) => paintsExactlyCountTimes(#drawRect, count);

void main() {
  group('MinimalListSection', () {
    testWidgets('on the page: gutter rows, a rule between them, the last '
        'row bare', (tester) async {
      await tester.pumpWidget(
        columnHost(
          const MinimalListSection(
            children: [
              MinimalListTile(title: 'Meditate'),
              MinimalListTile(title: 'Journal'),
            ],
          ),
        ),
      );
      // Under the last row the rule would divide nothing: the space that
      // follows the list closes it.
      expect(tester.renderObject(_ruled), _rules(1));
      expect(
        tester.getTopLeft(find.text('Meditate')).dx -
            tester.getTopLeft(find.byType(MinimalListSection)).dx,
        MinimalChromeMetrics.gutter,
      );
    });

    testWidgets('in a card: the card inset and rules between rows only', (
      tester,
    ) async {
      await tester.pumpWidget(
        columnHost(
          const MinimalListSection(
            inset: true,
            children: [
              MinimalListTile(title: 'Meditate'),
              MinimalListTile(title: 'Journal'),
            ],
          ),
        ),
      );
      expect(find.byType(MinimalCard), findsOneWidget);
      expect(tester.renderObject(_ruled), _rules(1));
      // The card's hairline, then its inset.
      expect(
        tester.getTopLeft(find.text('Meditate')).dx -
            tester.getTopLeft(find.byType(MinimalListSection)).dx,
        lightTheme.hairline + MinimalCard.inset,
      );
    });

    testWidgets('gutter: false leaves the rows at the edge', (tester) async {
      await tester.pumpWidget(
        columnHost(
          const MinimalListSection(
            gutter: false,
            children: [MinimalListTile(title: 'Meditate')],
          ),
        ),
      );
      expect(
        tester.getTopLeft(find.text('Meditate')).dx,
        tester.getTopLeft(find.byType(MinimalListSection)).dx,
      );
    });

    testWidgets('a group placed in a padless card by hand reads the card', (
      tester,
    ) async {
      await tester.pumpWidget(
        columnHost(
          const MinimalCard(
            padding: EdgeInsets.zero,
            child: MinimalListSection(
              children: [
                MinimalListTile(title: 'Meditate'),
                MinimalListTile(title: 'Journal'),
                MinimalListTile(title: 'Read 20 pages'),
              ],
            ),
          ),
        ),
      );
      expect(tester.renderObject(_ruled), _rules(2));
    });

    testWidgets('a hidden trailing reveal leaves no rule on the card edge', (
      tester,
    ) async {
      Widget group(bool third) => columnHost(
        MinimalListSection(
          inset: true,
          children: [
            const MinimalListTile(title: 'Meditate'),
            const MinimalListTile(title: 'Journal'),
            MinimalReveal(
              visible: third,
              child: const MinimalListTile(title: 'Read 20 pages'),
            ),
          ],
        ),
      );
      await tester.pumpWidget(group(true));
      expect(tester.renderObject(_ruled), _rules(2));
      await tester.pumpWidget(group(false));
      await tester.pumpAndSettle();
      // Only the rule between the two rows still showing; Journal, the
      // last one showing, is closed by the card's own edge.
      expect(tester.renderObject(_ruled), _rules(1));
    });

    testWidgets('a folded reveal on the page draws no rule of its own', (
      tester,
    ) async {
      await tester.pumpWidget(
        columnHost(
          const MinimalListSection(
            children: [
              MinimalListTile(title: 'Meditate'),
              MinimalReveal(
                visible: false,
                child: MinimalListTile(title: 'Journal'),
              ),
              MinimalListTile(title: 'Read 20 pages'),
            ],
          ),
        ),
      );
      // Only Meditate's: the folded row draws none, the last is bare.
      expect(tester.renderObject(_ruled), _rules(1));
    });
  });
}
