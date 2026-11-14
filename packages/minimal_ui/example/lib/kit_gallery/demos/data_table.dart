/// The back-office table that sorts, filters, selects and pages its own
/// rows, live.
library;

import 'package:flutter/material.dart';
import 'package:minimal_ui/minimal_ui.dart';

import '../kit.dart';

typedef _Order = ({String id, String customer, String status, int cents});

const List<_Order> _orders = [
  (id: 'ORD-1042', customer: 'Ana Souza', status: 'Paid', cents: 12900),
  (id: 'ORD-1041', customer: 'Ben Okafor', status: 'Refunded', cents: 4500),
  (id: 'ORD-1040', customer: 'Chen Wei', status: 'Paid', cents: 31250),
  (id: 'ORD-1039', customer: 'Dara Kelly', status: 'Pending', cents: 8800),
  (id: 'ORD-1038', customer: 'Eli Navarro', status: 'Paid', cents: 2100),
  (id: 'ORD-1037', customer: 'Farah Haddad', status: 'Pending', cents: 64000),
  (id: 'ORD-1036', customer: 'Gus Lindqvist', status: 'Paid', cents: 15999),
  (id: 'ORD-1035', customer: 'Hana Sato', status: 'Paid', cents: 7300),
];

String _money(int cents) =>
    '\$${(cents ~/ 100).toString()}.${(cents % 100).toString().padLeft(2, '0')}';

List<MinimalDataColumn<_Order>> _columns() => [
  MinimalDataColumn<_Order>(
    'Order',
    value: (o) => o.id,
    mono: true,
    sortable: true,
  ),
  MinimalDataColumn<_Order>(
    'Customer',
    value: (o) => o.customer,
    sortable: true,
    flex: 2,
  ),
  MinimalDataColumn<_Order>(
    'Status',
    value: (o) => o.status,
    cell: (context, o) => Align(
      alignment: AlignmentDirectional.centerStart,
      child: MinimalStatusBadge(
        o.status,
        tone: switch (o.status) {
          'Paid' => MinimalTone.success,
          'Pending' => MinimalTone.warning,
          _ => MinimalTone.neutral,
        },
      ),
    ),
  ),
  MinimalDataColumn<_Order>(
    'Total',
    value: (o) => _money(o.cents),
    sortKey: (o) => o.cents,
    numeric: true,
  ),
];

Widget kitDataTableDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Data table',
  sections: [
    kitSection(
      'Orders',
      children: [
        const _Orders(),
        kitNote(
          'A press on a header sorts it; Space or a press selects a row, '
          'Shift a run, ⌘ A the page.',
        ),
      ],
    ),
    kitSection(
      'Filtered to nothing',
      children: [
        // The same orders filtered to nothing: the columns keep the widths
        // they were measured at over every row, so nothing moves.
        MinimalDataTable<_Order>(
          rows: _orders,
          columns: _columns(),
          rowKey: (o) => o.id,
          query: 'Oslo',
        ),
        kitNote(
          'Filtered by “Oslo”, which no order matches: the columns keep '
          'their places, measured over every row.',
        ),
      ],
    ),
  ],
);

class _Orders extends StatefulWidget {
  const _Orders();

  @override
  State<_Orders> createState() => _OrdersState();
}

class _OrdersState extends State<_Orders> {
  String _query = '';
  int _chosen = 0;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      MinimalSearchField(
        hint: 'Filter orders',
        clearable: true,
        onChanged: (q) => setState(() => _query = q),
      ),
      const MinimalGap(MinimalSpacing.s8),
      MinimalDataTable<_Order>(
        rows: _orders,
        columns: _columns(),
        rowKey: (o) => o.id,
        pageSize: 5,
        query: _query,
        onSelectionChanged: (rows) => setState(() => _chosen = rows.length),
        onRowActivated: (o) => showMinimalSnackBar(context, o.id),
      ),
      if (_chosen > 0) ...[
        const MinimalGap(MinimalSpacing.s8),
        Text(
          '$_chosen selected',
          style: context.minimalTheme.caption.c(
            context.minimalTheme.mutedForeground,
          ),
        ),
      ],
    ],
  );
}

// --- catalog specimens -------------------------------------------------------

/// Five orders of eight, sorted by nothing, a pager under them.
Widget kitSpecimenDataTable() => Padding(
  padding: const EdgeInsets.all(MinimalSpacing.s16),
  child: MinimalDataTable<_Order>(
    rows: _orders,
    columns: _columns(),
    rowKey: (o) => o.id,
    pageSize: 5,
  ),
);
