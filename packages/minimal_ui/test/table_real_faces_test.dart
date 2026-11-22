import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';

import 'support/page_host.dart';
import 'support/table_orders.dart';

void main() {
  // Last, because the faces stay loaded for every test after them: the
  // default test font sets every glyph a full em wide, which no real
  // column is sized for.
  group('with the real faces', () {
    setUpAll(minimalLoadFonts);

    testWidgets('at text scale 1.3 the orders table still fits 390 px', (
      tester,
    ) async {
      await tester.pumpWidget(
        pageApp(
          scaled(
            MinimalTable(
              columns: orderColumns,
              rows: orderRows,
              onSort: (_, _) {},
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(
        find.descendant(
          of: find.byType(MinimalTable),
          matching: find.byType(SingleChildScrollView),
        ),
        findsNothing,
      );
      final status = tester.getRect(find.text('STATUS'));
      expect(status.left, greaterThan(0));
      expect(status.right, lessThanOrEqualTo(390));
      expect(tester.getRect(find.text('Late')).right, lessThanOrEqualTo(390));
      // The fixed columns grew with their figures, no further.
      final id = tester.renderObject<RenderParagraph>(find.text('1047'));
      expect(id.didExceedMaxLines, isFalse);
    });

    testWidgets('two columns of figures keep 16 px apart when room is short', (
      tester,
    ) async {
      // A phone card's table at text scale 1.3: the other gaps close to 8,
      // but Café Morgen's 24 and its 10:00 still read as two figures.
      await tester.pumpWidget(
        pageApp(
          scaled(
            MinimalTable(
              columns: const [
                MinimalColumn('#', width: 40, mono: true, sortable: true),
                MinimalColumn('Customer'),
                MinimalColumn('Qty', width: 38, numeric: true, sortable: true),
                MinimalColumn('Due', width: 56, numeric: true, sortable: true),
                MinimalColumn('Status', width: 84, alignEnd: true),
              ],
              rows: orderRows,
              onSort: (_, _) {},
            ),
          ),
          width: 352,
        ),
      );
      expect(tester.takeException(), isNull);
      expect(
        tester.getRect(find.text('10:00')).left -
            tester.getRect(find.text('24')).right,
        greaterThanOrEqualTo(16),
      );
    });
  });
}
