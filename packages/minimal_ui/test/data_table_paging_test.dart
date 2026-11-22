// A paged data table's count starts on the table's leading edge, its check
// boxes'.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';

import 'support/data_table_orders.dart';
import 'support/directional_page.dart';

void main() {
  testWidgets('a paged data table\'s count starts on its check boxes', (
    tester,
  ) async {
    await tester.pumpWidget(
      directionalPage(
        MinimalDataTable<Order>(
          rows: sampleOrders,
          columns: orderColumns,
          pageSize: 2,
        ),
      ),
    );
    await tester.pumpAndSettle();
    final boxes = find.byWidgetPredicate(
      (w) =>
          w is Container &&
          w.constraints?.maxWidth == 16 &&
          w.constraints?.maxHeight == 16,
    );
    expect(boxes, findsWidgets);
    final count = find.textContaining('of 3');
    expect(count, findsOneWidget);
    expect(
      tester.getTopLeft(count).dx,
      moreOrLessEquals(tester.getTopLeft(boxes.first).dx, epsilon: 0.01),
    );
  });
}
