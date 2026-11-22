// A table that scrolls cuts no name.
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';

import 'support/scaled_page.dart';

bool _cut(WidgetTester tester, String text) =>
    tester.renderObject<RenderParagraph>(find.text(text)).didExceedMaxLines;

typedef _Order = ({String id, String customer, String status, int total});

const List<_Order> _orders = [
  (id: 'ORD-1042', customer: 'Café Morgenrot', status: 'Shipped', total: 129),
  (id: 'ORD-1041', customer: 'Studio Nordlicht', status: 'Pending', total: 45),
  (id: 'ORD-1040', customer: 'Mara Quintero', status: 'Paid', total: 312),
];

void main() {
  group('a table that scrolls cuts no name', () {
    final scrolls = find.byWidgetPredicate(
      (w) => w is SingleChildScrollView && w.scrollDirection == Axis.horizontal,
    );

    testWidgets('MinimalTable', (tester) async {
      await tester.pumpWidget(
        scaledPage(
          MinimalTable(
            columns: const [
              MinimalColumn('Order', width: 80, mono: true),
              MinimalColumn('Customer'),
              MinimalColumn('Status'),
              MinimalColumn('Total', width: 72, numeric: true),
            ],
            rows: [
              for (final o in _orders)
                MinimalTableRow([
                  MinimalCell(o.id),
                  MinimalCell(o.customer),
                  MinimalCell(o.status),
                  MinimalCell('\$${o.total}.00'),
                ]),
            ],
          ),
          width: 260,
          scale: 2,
        ),
      );
      expect(tester.takeException(), isNull);
      expect(scrolls, findsWidgets);
      for (final o in _orders) {
        expect(_cut(tester, o.customer), isFalse, reason: o.customer);
      }
    });

    testWidgets('MinimalDataTable', (tester) async {
      await tester.pumpWidget(
        scaledPage(
          MinimalDataTable<_Order>(
            rows: _orders,
            columns: [
              MinimalDataColumn<_Order>(
                'Order',
                value: (o) => o.id,
                mono: true,
              ),
              MinimalDataColumn<_Order>('Customer', value: (o) => o.customer),
              MinimalDataColumn<_Order>('Status', value: (o) => o.status),
              MinimalDataColumn<_Order>(
                'Total',
                value: (o) => '\$${o.total}.00',
                numeric: true,
              ),
            ],
          ),
          width: 260,
          scale: 2,
        ),
      );
      expect(tester.takeException(), isNull);
      expect(scrolls, findsWidgets);
      for (final o in _orders) {
        expect(_cut(tester, o.customer), isFalse, reason: o.customer);
      }
    });
  });
}
