/// Minimal's data table, full bleed as a page stands it: the bakery's
/// orders sorted and selected live as a sliver whose header pins (a faded
/// picked-up row, status badges in every tone), a wide habit ledger that
/// scrolls sideways, a fixed-height table whose header stays while its
/// rows scroll, and the empty table.
library;

import 'package:flutter/material.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:minimal_ui/minimal_host.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../kit.dart';

Widget kitTableDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Table',
  padding: EdgeInsets.zero,
  scroll: false,
  // On an example page the slivers shrink-wrap and the page scrolls them,
  // so the phone grows with every table instead of cutting the last.
  grow: true,
  body: CustomScrollView(
    shrinkWrap: kitEmbedded,
    physics: kitEmbedded ? const NeverScrollableScrollPhysics() : null,
    slivers: [
      const _Band(
        'Sortable · pinned header',
        note:
            'Tap #, Qty or Due to sort; tap a row to select it. The '
            'picked-up order stays, faded. As a sliver in a page\'s scroll '
            'view, the header pins while the orders scroll under it.',
      ),
      const _Orders(),
      const _Band(
        'Tones & cells',
        note: 'Badges in every tone, a late time in the warning ink, a flag.',
      ),
      const SliverToBoxAdapter(
        child: MinimalTable(
          columns: [
            MinimalColumn('Status', width: 96),
            MinimalColumn('Meaning'),
            MinimalColumn('Due', width: 50, numeric: true),
          ],
          rows: [
            MinimalTableRow([
              MinimalCell.badge('Queued'),
              MinimalCell('Waiting for the oven'),
              MinimalCell('11:00'),
            ]),
            MinimalTableRow([
              MinimalCell.badge('Baking', tone: MinimalTone.primary),
              // Not "In progress": that is a task's state, in its own tone.
              MinimalCell('In the oven'),
              MinimalCell('09:45'),
            ]),
            MinimalTableRow([
              MinimalCell.badge('Ready', tone: MinimalTone.success),
              MinimalCell('On the shelf'),
              MinimalCell('10:15'),
            ]),
            MinimalTableRow([
              MinimalCell.badge('Late', tone: MinimalTone.warning),
              MinimalCell('Past its slot'),
              MinimalCell('09:30', tone: MinimalTone.warning),
            ]),
            MinimalTableRow([
              // A refund is settled, so it stays neutral (as in the data
              // table); the danger tone is for an order that failed.
              MinimalCell.badge('Failed', tone: MinimalTone.destructive),
              MinimalCell('The payment did not go through'),
              MinimalCell('—'),
            ]),
            MinimalTableRow([
              MinimalCell.widget(_Flag()),
              MinimalCell('Flagged by the kitchen'),
              MinimalCell('12:00'),
            ]),
          ],
        ),
      ),
      const _Band(
        'Wide · scrolls sideways',
        note: 'A wide table scrolls sideways as one piece.',
      ),
      SliverToBoxAdapter(
        child: MinimalTable(
          minWidth: 560,
          columns: const [
            MinimalColumn('Habit', width: 132),
            MinimalColumn('Area', width: 80),
            MinimalColumn('Streak', width: 56, numeric: true),
            MinimalColumn('Best', width: 44, numeric: true),
            MinimalColumn('Kept', width: 56, numeric: true),
            MinimalColumn('Rate', width: 48, numeric: true),
            MinimalColumn('Started', width: 80, mono: true),
          ],
          rows: [
            for (final h in _habits)
              MinimalTableRow([
                MinimalCell(h.$1, strong: true),
                MinimalCell(h.$2),
                MinimalCell('${h.$3}d'),
                MinimalCell('${h.$4}d'),
                MinimalCell('${h.$5}/28'),
                MinimalCell('${(h.$5 * 100 / 28).round()}%'),
                MinimalCell(h.$6),
              ], faded: h.$1 == 'Water the plants'),
          ],
        ),
      ),
      const _Band(
        'Fixed height · rows scroll inside',
        note:
            'In a short space the table scrolls its own rows under the '
            'header; half a row shows there is more.',
      ),
      SliverToBoxAdapter(
        child: SizedBox(
          height: 210,
          child: MinimalTable(
            columns: const [
              MinimalColumn('Day', width: 84, mono: true),
              MinimalColumn('Habit'),
              MinimalColumn('At', width: 50, numeric: true),
            ],
            rows: [
              for (final (i, h) in _habits.indexed)
                for (final day in const ['28 Aug', '27 Aug'])
                  MinimalTableRow([
                    MinimalCell(day),
                    MinimalCell(h.$1),
                    MinimalCell(
                      '0${6 + i % 3}:${(i * 7 % 60).toString().padLeft(2, '0')}',
                    ),
                  ]),
            ],
          ),
        ),
      ),
      const _Band('Empty', note: 'No rows: the header and a quiet line.'),
      const SliverToBoxAdapter(
        child: MinimalTable(
          columns: [
            MinimalColumn('#', width: 40, mono: true),
            MinimalColumn('Customer'),
            MinimalColumn('Qty', width: 38, numeric: true),
          ],
          rows: [],
          emptyLabel: 'No orders yet today',
        ),
      ),
      const SliverSafeArea(
        top: false,
        sliver: SliverToBoxAdapter(child: MinimalGap(MinimalSpacing.s16)),
      ),
    ],
  ),
);

/// The Ritual habits: name, area, streak, best, days kept in August,
/// started.
const List<(String, String, int, int, int, String)> _habits = [
  ('Meditate', 'Morning', 4, 19, 22, '2026-03-14'),
  ('Morning run', 'Morning', 12, 21, 23, '2026-06-02'),
  ('Drink water', 'All day', 10, 30, 26, '2026-01-05'),
  ('Journal', 'Evening', 3, 14, 17, '2026-04-20'),
  ('Read 20 pages', 'Evening', 6, 25, 21, '2026-02-11'),
  ('Water the plants', 'Weekly', 2, 8, 8, '2026-05-30'),
];

/// A section label and its note, held to the page's gutter above a
/// full-bleed table: a sliver of the page.
class _Band extends StatelessWidget {
  const _Band(this.label, {required this.note});

  final String label;
  final String note;

  @override
  Widget build(BuildContext context) => SliverPadding(
    padding: const EdgeInsets.fromLTRB(
      MinimalChromeMetrics.gutter,
      MinimalSpacing.s24,
      MinimalChromeMetrics.gutter,
      MinimalSpacing.s12,
    ),
    sliver: SliverToBoxAdapter(
      child: kitSection(label, children: [kitNote(note)]),
    ),
  );
}

class _Flag extends StatelessWidget {
  const _Flag();

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        MinimalIcon(
          LucideIcons.flag,
          size: MinimalIconSize.i14,
          color: t.destructive,
        ),
        const MinimalGap(MinimalSpacing.s4),
        Flexible(
          child: Text(
            'Urgent',
            style: t.caption.medium.c(t.destructiveInk),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

typedef _Order = ({
  int id,
  String customer,
  int qty,
  String due,
  String status,
  MinimalTone tone,
});

const List<_Order> _orders = [
  (
    id: 1047,
    customer: 'Hanna Berg',
    qty: 3,
    due: '09:30',
    status: 'Late',
    tone: MinimalTone.warning,
  ),
  (
    id: 1046,
    customer: 'Oskar Lind',
    qty: 1,
    due: '09:45',
    status: 'Baking',
    tone: MinimalTone.primary,
  ),
  (
    id: 1045,
    customer: 'Café Morgen',
    qty: 24,
    due: '10:00',
    status: 'Baking',
    tone: MinimalTone.primary,
  ),
  (
    id: 1044,
    customer: 'Ines Duarte',
    qty: 2,
    due: '10:15',
    status: 'Ready',
    tone: MinimalTone.success,
  ),
  (
    id: 1043,
    customer: 'Tom Alves',
    qty: 6,
    due: '10:30',
    status: 'Ready',
    tone: MinimalTone.success,
  ),
  (
    id: 1042,
    customer: 'Studio North',
    qty: 12,
    due: '11:00',
    status: 'Queued',
    tone: MinimalTone.neutral,
  ),
  (
    id: 1041,
    customer: 'Mara Quintero',
    qty: 2,
    due: '11:15',
    status: 'Queued',
    tone: MinimalTone.neutral,
  ),
  (
    id: 1039,
    customer: 'Jonas Weber',
    qty: 1,
    due: '08:45',
    status: 'Picked up',
    tone: MinimalTone.neutral,
  ),
];

/// The live orders table, as a sliver: the page sorts, the table reports.
class _Orders extends StatefulWidget {
  const _Orders();

  @override
  State<_Orders> createState() => _OrdersState();
}

class _OrdersState extends State<_Orders> {
  // Newest first, and the # header says so.
  int? _sort = 0;
  bool _ascending = false;
  int? _selected = 1045;

  List<_Order> get _rows {
    final rows = [..._orders];
    final sort = _sort;
    if (sort == null) return rows;
    int compare(_Order a, _Order b) => switch (sort) {
      0 => a.id.compareTo(b.id),
      2 => a.qty.compareTo(b.qty),
      _ => a.due.compareTo(b.due),
    };
    rows.sort((a, b) => _ascending ? compare(a, b) : compare(b, a));
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    final rows = _rows;
    return MinimalTable.sliver(
      columns: const [
        MinimalColumn('#', width: 40, mono: true, sortable: true),
        MinimalColumn('Customer'),
        MinimalColumn('Qty', width: 38, numeric: true, sortable: true),
        MinimalColumn('Due', width: 56, numeric: true, sortable: true),
        MinimalColumn('Status', width: 84, alignEnd: true),
      ],
      sortColumn: _sort,
      sortAscending: _ascending,
      onSort: (column, ascending) => setState(() {
        _sort = column;
        _ascending = ascending;
      }),
      onRowPressed: (i) => setState(() => _selected = rows[i].id),
      rows: [
        for (final o in rows)
          MinimalTableRow(
            [
              MinimalCell('${o.id}'),
              MinimalCell(o.customer, strong: true),
              MinimalCell('${o.qty}'),
              // A late order's due time takes the warning ink, as on the
              // Orders screen.
              MinimalCell(
                o.due,
                tone: o.tone == MinimalTone.warning
                    ? MinimalTone.warning
                    : null,
              ),
              MinimalCell.badge(o.status, tone: o.tone),
            ],
            faded: o.status == 'Picked up',
            selected: o.id == _selected,
            semanticLabel: 'Order ${o.id}, ${o.customer}, ${o.status}',
          ),
      ],
    );
  }
}

// --- catalog specimens -------------------------------------------------------
//
// One configuration each, for the lab's Components pages (metadata.yaml
// `specimens`). The stage (kitSpecimenStage) styles and places them; a
// builder never names a style. The table runs edge to edge, as on its
// `padding: EdgeInsets.zero` page.

/// The morning's orders, sorted by number: mono figures, dot badges, one
/// row selected and a collected one faded.
Widget kitSpecimenTableOrders() => _Body(
  bleed: true,
  child: MinimalTable(
    columns: const [
      MinimalColumn('#', width: 40, mono: true, sortable: true),
      MinimalColumn('Customer'),
      MinimalColumn('Qty', width: 38, numeric: true, sortable: true),
      MinimalColumn('Due', width: 56, numeric: true, sortable: true),
      MinimalColumn('Status', width: 84, alignEnd: true),
    ],
    sortColumn: 0,
    sortAscending: false,
    onSort: (_, _) {},
    onRowPressed: (_) {},
    rows: [
      for (final o in _orders.take(6))
        MinimalTableRow(
          [
            MinimalCell('${o.id}'),
            MinimalCell(o.customer, strong: true),
            MinimalCell('${o.qty}'),
            MinimalCell(
              o.due,
              tone: o.tone == MinimalTone.warning ? MinimalTone.warning : null,
            ),
            MinimalCell.badge(o.status, tone: o.tone),
          ],
          faded: o.status == 'Picked up',
          selected: o.id == 1045,
          semanticLabel: 'Order ${o.id}, ${o.customer}, ${o.status}',
        ),
    ],
  ),
);

/// A table wider than the phone: it scrolls sideways as one piece.
Widget kitSpecimenTableWide() => _Body(
  bleed: true,
  child: MinimalTable(
    minWidth: 560,
    columns: const [
      MinimalColumn('Habit', width: 132),
      MinimalColumn('Area', width: 80),
      MinimalColumn('Streak', width: 56, numeric: true),
      MinimalColumn('Best', width: 44, numeric: true),
      MinimalColumn('Kept', width: 56, numeric: true),
      MinimalColumn('Rate', width: 48, numeric: true),
      MinimalColumn('Started', width: 80, mono: true),
    ],
    rows: [
      for (final h in _habits.take(4))
        MinimalTableRow([
          MinimalCell(h.$1, strong: true),
          MinimalCell(h.$2),
          MinimalCell('${h.$3}d'),
          MinimalCell('${h.$4}d'),
          MinimalCell('${h.$5}/28'),
          MinimalCell('${(h.$5 * 100 / 28).round()}%'),
          MinimalCell(h.$6),
        ]),
    ],
  ),
);

/// Lays a specimen out as a scrolling page body does: its own height,
/// however tall the stage — and with [bleed] edge to edge past the stage's
/// gutter, as on a `MinimalScaffold(padding: EdgeInsets.zero)` page.
class _Body extends StatelessWidget {
  const _Body({required this.child, this.bleed = false});

  final Widget child;
  final bool bleed;

  @override
  Widget build(BuildContext context) => UnconstrainedBox(
    constrainedAxis: Axis.horizontal,
    child: !bleed
        ? child
        : LayoutBuilder(
            builder: (context, c) => FractionallySizedBox(
              widthFactor:
                  (c.maxWidth + 2 * MinimalChromeMetrics.gutter) / c.maxWidth,
              child: child,
            ),
          ),
  );
}
