// A column of names keeps a run of its words at larger text, as the words grow.
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';

import 'support/data_table_orders.dart';
import 'support/directional_page.dart';

bool _cut(WidgetTester tester, String text) =>
    tester.renderObject<RenderParagraph>(find.text(text)).didExceedMaxLines;

void main() {
  group('a column of names keeps its words at larger text', () {
    testWidgets('MinimalTable', (tester) async {
      await tester.pumpWidget(
        directionalPage(
          const MinimalTable(
            columns: [
              MinimalColumn('#', width: 54, mono: true),
              MinimalColumn('Customer'),
              MinimalColumn('Qty', width: 38, numeric: true),
            ],
            rows: [
              MinimalTableRow([
                MinimalCell('1043'),
                MinimalCell('Hanna'),
                MinimalCell('6'),
              ]),
            ],
          ),
          width: 180,
          scale: 1.3,
        ),
      );
      await tester.pumpAndSettle();
      // Too narrow for every column, the table scrolls; the names column
      // stands at its least, which grows with the words (72 at 1×). The
      // test face sets every glyph an em wide: five at 1.3 × 13 are 84.5,
      // past 72 and inside 93.6.
      expect(_cut(tester, 'Hanna'), isFalse);
    });

    testWidgets('MinimalDataTable', (tester) async {
      await tester.pumpWidget(
        directionalPage(
          MinimalDataTable<Order>(
            rows: sampleOrders,
            columns: orderColumns,
            selectable: false,
          ),
          width: 200,
          scale: 1.3,
        ),
      );
      await tester.pumpAndSettle();
      expect(_cut(tester, 'Hanna'), isFalse);
    });
  });
}
