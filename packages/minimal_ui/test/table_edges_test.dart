// A selectable table's sides match; the gap after an id or figure column never
// closes.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';

import 'support/scaled_page.dart';

typedef _Order = ({String id, String customer, String status, int cents});

const List<_Order> _orders = [
  (id: 'ORD-1042', customer: 'Ana Souza', status: 'Paid', cents: 12900),
  (id: 'ORD-1041', customer: 'Ben Okafor', status: 'Refunded', cents: 4500),
  (id: 'ORD-1040', customer: 'Chen Wei', status: 'Paid', cents: 31250),
];

List<MinimalDataColumn<_Order>> get _columns => [
  MinimalDataColumn<_Order>('Order', value: (o) => o.id, mono: true),
  MinimalDataColumn<_Order>('Customer', value: (o) => o.customer),
  MinimalDataColumn<_Order>('Status', value: (o) => o.status),
  MinimalDataColumn<_Order>(
    'Total',
    value: (o) =>
        '\$${o.cents ~/ 100}.${(o.cents % 100).toString().padLeft(2, '0')}',
    numeric: true,
  ),
];

void main() {
  // Selectable, the check column stands a finger wide (44) and its boxes
  // (16) stand in its middle, 14 in.
  for (final (selectable, end) in [(true, 14.0), (false, 18.0)]) {
    testWidgets('a table\'s figures end as far in as its rows start '
        '(selectable: $selectable)', (tester) async {
      setViewSize(tester, const Size(1200, 900));
      await tester.pumpWidget(
        scaledPage(
          MinimalDataTable<_Order>(
            rows: _orders,
            columns: _columns,
            rowKey: (o) => o.id,
            selectable: selectable,
          ),
          width: 1000,
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.getTopRight(find.text('\$129.00')).dx,
        closeTo(1000 - end, 0.5),
      );
    });
  }

  testWidgets('an id keeps its full gap from the name after it on a phone', (
    tester,
  ) async {
    await tester.pumpWidget(
      scaledPage(
        MinimalDataTable<_Order>(
          rows: _orders,
          columns: _columns,
          rowKey: (o) => o.id,
        ),
        width: 354,
      ),
    );
    await tester.pumpAndSettle();
    final gap =
        tester.getTopLeft(find.text('Ana Souza')).dx -
        tester.getTopRight(find.text('ORD-1042')).dx;
    expect(gap, greaterThanOrEqualTo(16 - 0.5));
  });
}
