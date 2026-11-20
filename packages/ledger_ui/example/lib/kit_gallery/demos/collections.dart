/// Ledger's collections, each live: a table of October's entries sorted by
/// its headings, the accounts put in order by their grips, a month's
/// highlights turned one at a time, the terms of a transfer in a scrolling
/// region, and a bank feed fetched again by a pull.
library;

import 'package:material_ui/material_ui.dart';
import 'package:ledger_ui/ledger_ui.dart';

import '../kit.dart';

Widget kitCollectionsDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Collections',
  sections: const [_Table(), _Order(), _Highlights(), _Terms(), _Feed()],
);

/// October's entries, sorted by a heading's press, chosen by a row's.
class _Table extends StatefulWidget {
  const _Table();

  @override
  State<_Table> createState() => _TableState();
}

class _TableState extends State<_Table> {
  late final _rows = [for (final d in kitDays) ...d.rows].take(8).toList();
  late final _table = DesignTableController<KitTx>(
    rows: _rows,
    rowKey: (tx) => tx.id,
    columns: [
      DesignTableColumn(id: 'title', label: 'Entry', sortKey: (tx) => tx.title),
      DesignTableColumn(
        id: 'account',
        label: 'Account',
        sortKey: (tx) => tx.account,
      ),
      DesignTableColumn(
        id: 'amount',
        label: 'Amount',
        numeric: true,
        sortKey: (tx) => tx.amount,
      ),
    ],
  );

  @override
  void dispose() {
    _table.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => kitSection(
    'A table',
    children: [
      LedgerDataTable<KitTx>(
        controller: _table,
        cellText: (tx, column) => switch (column.id) {
          'title' => tx.title,
          'account' => tx.account,
          _ => LedgerFormat.money(tx.amount),
        },
      ),
    ],
  );
}

/// The accounts, put in order by their grips.
class _Order extends StatefulWidget {
  const _Order();

  @override
  State<_Order> createState() => _OrderState();
}

class _OrderState extends State<_Order> {
  final _names = ['Everyday', 'Savings', 'Wren Card', 'Brokerage'];

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    return kitSection(
      'Put in order',
      children: [
        LedgerReorderableList<String>(
          items: _names,
          labelOf: (n) => n,
          onReorder: (from, to) =>
              setState(() => _names.insert(to, _names.removeAt(from))),
          itemBuilder: (context, n) =>
              Text(n, style: t.body.colored(t.textPrimary)),
        ),
      ],
    );
  }
}

/// October's highlights, one at a time.
class _Highlights extends StatelessWidget {
  const _Highlights();

  static const _slides = [
    ('Spent', '\$2,184.60', 'down 12% on September'),
    ('Saved', '\$640.00', 'the most this year'),
    ('Biggest', '\$1,150.00', 'rent, on Oct 1'),
  ];

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    return kitSection(
      'One at a time',
      children: [
        LedgerCarousel(
          semanticLabel: 'October highlights',
          height: 152,
          itemCount: _slides.length,
          itemBuilder: (context, i) => ColoredBox(
            color: t.surfaceAlt,
            child: Padding(
              padding: const EdgeInsets.all(LedgerSpacing.s16),
              // A slide is a card of one size: past the room its height grows
              // to at large text, its words shrink to fit it.
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerStart,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  spacing: LedgerSpacing.s4,
                  children: [
                    Text(
                      _slides[i].$1.toUpperCase(),
                      style: t.tag.colored(t.textSecondary),
                    ),
                    Text(_slides[i].$2, style: t.figure.colored(t.textPrimary)),
                    Text(
                      _slides[i].$3,
                      style: t.bodySmall.colored(t.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// The terms of a transfer, scrolling in their own region.
class _Terms extends StatefulWidget {
  const _Terms();

  @override
  State<_Terms> createState() => _TermsState();
}

class _TermsState extends State<_Terms> {
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    return kitSection(
      'A scrolling region',
      children: [
        SizedBox(
          height: 160,
          child: LedgerScrollArea(
            controller: _scroll,
            semanticLabel: 'Transfer terms',
            child: SingleChildScrollView(
              controller: _scroll,
              padding: const EdgeInsetsDirectional.only(end: LedgerSpacing.s16),
              child: Text(
                [
                  for (var i = 1; i <= 6; i++)
                    '$i. A transfer between your own accounts arrives the '
                        'same day when sent before 5 pm, else the next '
                        'working day. Transfers to others may take up to '
                        'three working days.',
                ].join('\n\n'),
                style: t.bodySmall.colored(t.textSecondary),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// A bank feed fetched again by a pull from its top.
class _Feed extends StatefulWidget {
  const _Feed();

  @override
  State<_Feed> createState() => _FeedState();
}

class _FeedState extends State<_Feed> {
  int _fetched = 0;

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    return kitSection(
      'Pull to fetch',
      children: [
        SizedBox(
          height: 200,
          child: LedgerPullToRefresh(
            onRefresh: () async {
              await Future<void>.delayed(const Duration(milliseconds: 600));
              if (mounted) setState(() => _fetched++);
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                for (final tx in kitDays.first.rows.take(4))
                  LedgerRow(
                    title: tx.title,
                    subtitle: tx.subtitle,
                    value: LedgerAmount(tx.amount),
                  ),
                Padding(
                  padding: const EdgeInsets.all(LedgerSpacing.s12),
                  child: Text(
                    _fetched == 0
                        ? 'Pull down to fetch the feed again.'
                        : 'Fetched $_fetched times.',
                    style: t.bodySmall.colored(t.textSecondary),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
