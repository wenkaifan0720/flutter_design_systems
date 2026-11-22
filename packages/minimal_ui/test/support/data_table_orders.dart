import 'package:minimal_ui/minimal_ui.dart';

/// An order, as a data table's row.
typedef Order = ({String id, String customer, int total});

/// Three orders.
const List<Order> sampleOrders = [
  (id: 'ORD-1042', customer: 'Ben Okafor', total: 129),
  (id: 'ORD-1041', customer: 'Hanna', total: 45),
  (id: 'ORD-1040', customer: 'Chen Wei', total: 312),
];

/// A data table's columns over [Order]: its id, its customer and its total.
List<MinimalDataColumn<Order>> get orderColumns => [
  MinimalDataColumn<Order>('Order', value: (o) => o.id, mono: true),
  MinimalDataColumn<Order>('Customer', value: (o) => o.customer),
  MinimalDataColumn<Order>(
    'Total',
    value: (o) => '\$${o.total}.00',
    numeric: true,
  ),
];
