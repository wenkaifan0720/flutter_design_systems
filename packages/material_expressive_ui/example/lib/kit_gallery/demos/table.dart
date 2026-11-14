/// The table group's demo: records under their columns at width, and the
/// same records stacked as list items under the medium window class.
library;

import 'package:flutter/widgets.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';

import '../kit.dart';

/// The table group's demo, in [brightness].
Widget kitTableDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Table',
  sections: <Widget>[
    kitSection(
      'At width',
      children: <Widget>[_watering(ExpressiveWindowSizeClass.compact)],
    ),
    kitSection(
      'Stacked under 600',
      children: <Widget>[
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: kitSpecimenTable(),
          ),
        ),
      ],
    ),
    const _Data(),
  ],
);

/// Four plants and their care, one row chosen, the figures tabular: ruled at
/// width, stacked on a phone.
Widget kitSpecimenTable() => ExpressiveTable(
  semanticLabel: 'Watering',
  columns: _columns,
  rows: _rows(),
);

/// The specimen's table, ruled from [stackBelow] wide.
Widget _watering(ExpressiveWindowSizeClass stackBelow) => ExpressiveTable(
  semanticLabel: 'Watering',
  stackBelow: stackBelow,
  columns: _columns,
  rows: _rows(),
);

const List<ExpressiveTableColumn> _columns = <ExpressiveTableColumn>[
  ExpressiveTableColumn('Plant', flex: 2),
  ExpressiveTableColumn('Light'),
  ExpressiveTableColumn('Water', numeric: true),
];

List<ExpressiveTableRow> _rows() => <ExpressiveTableRow>[
  ExpressiveTableRow(const <Object>[
    'Fern',
    'Shade',
    '200 ml',
  ], onPressed: () {}),
  ExpressiveTableRow(
    const <Object>['Monstera', 'Bright', '350 ml'],
    onPressed: () {},
    selected: true,
  ),
  ExpressiveTableRow(const <Object>[
    'Cactus',
    'Sun',
    '50 ml',
  ], onPressed: () {}),
  ExpressiveTableRow(const <Object>[
    'Pothos',
    'Any',
    '150 ml',
  ], onPressed: () {}),
];

/// An order: its number, customer, state and total in cents.
typedef _Order = ({String id, String customer, String state, int cents});

const List<_Order> _orders = <_Order>[
  (id: '#4821', customer: 'Ada Okafor', state: 'Shipped', cents: 12840),
  (id: '#4822', customer: 'Ben Ito', state: 'Paid', cents: 4200),
  (id: '#4823', customer: 'Cleo Marsh', state: 'Refunded', cents: 1890),
  (id: '#4824', customer: 'Dev Patel', state: 'Shipped', cents: 31025),
  (id: '#4825', customer: 'Eli Romero', state: 'Paid', cents: 7610),
  (id: '#4826', customer: 'Fay Lund', state: 'Shipped', cents: 999),
  (id: '#4827', customer: 'Gus Abara', state: 'Paid', cents: 15400),
];

String _money(int cents) =>
    'USD ${cents ~/ 100}.${(cents % 100).toString().padLeft(2, '0')}';

DesignTableController<_Order> _orderTable() => DesignTableController<_Order>(
  rows: _orders,
  rowKey: (o) => o.id,
  pageSize: 5,
  columns: <DesignTableColumn<_Order>>[
    DesignTableColumn<_Order>(id: 'id', label: 'Order', sortKey: (o) => o.id),
    DesignTableColumn<_Order>(
      id: 'customer',
      label: 'Customer',
      sortKey: (o) => o.customer,
    ),
    const DesignTableColumn<_Order>(id: 'state', label: 'State'),
    DesignTableColumn<_Order>(
      id: 'total',
      label: 'Total',
      numeric: true,
      sortKey: (o) => o.cents,
    ),
  ],
);

const Map<String, int> _orderFlex = <String, int>{'customer': 2};

Widget _orderCell(
  BuildContext context,
  _Order o,
  DesignTableColumn<_Order> column,
) => Text(switch (column.id) {
  'id' => o.id,
  'customer' => o.customer,
  'state' => o.state,
  _ => _money(o.cents),
});

class _Data extends StatefulWidget {
  const _Data();

  @override
  State<_Data> createState() => _DataState();
}

class _DataState extends State<_Data> {
  // Sorted by order from the start, so the sort arrow the caption names
  // shows (unsorted, a column only keeps its room).
  late final DesignTableController<_Order> _table = _orderTable()..sort('id');

  @override
  void dispose() {
    _table.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => kitSection(
    'Data table · sort, select and page',
    children: <Widget>[
      ExpressiveDataTable<_Order>(
        controller: _table,
        columnFlex: _orderFlex,
        cellBuilder: _orderCell,
      ),
    ],
  );
}

/// Five orders sorted by total, two chosen.
Widget kitSpecimenDataTableOrders() => ExpressiveDataTable<_Order>(
  controller: _orderTable()
    ..sort('total')
    ..toggle(_orders[0])
    ..toggle(_orders[3]),
  columnFlex: _orderFlex,
  cellBuilder: _orderCell,
);
