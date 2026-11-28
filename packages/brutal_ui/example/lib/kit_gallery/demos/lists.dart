import 'package:material_ui/material_ui.dart';
import 'package:brutal_ui/brutal_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../kit.dart';

/// Rows on shared rules: a table you can see, its rows turning over to ink
/// when pressed; tables plain and sortable, terms, and the collections that
/// move: reordered, swiped, refreshed, scrolled, split and folded.
Widget kitListsDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Lists and tables',
  sections: [
    KitSection(
      title: 'A group',
      note: 'One frame, full-width rules between rows. Flat: rows do not lift.',
      children: [
        BrutalListGroup(
          header: 'Account',
          children: [
            BrutalListTile(
              title: 'Name',
              trailingText: 'Ada Park',
              onTap: () {},
            ),
            BrutalListTile(
              title: 'Email',
              trailingText: 'ada@example.com',
              onTap: () {},
            ),
            BrutalListTile(title: 'Member since', trailingText: 'March 2024'),
          ],
        ),
      ],
    ),
    KitSection(
      title: 'With glyphs and lines',
      children: [
        BrutalListGroup(
          footer: 'Reminders go out a day before, at 10:00.',
          children: [
            BrutalListTile(
              leading: const Icon(LucideIcons.bell),
              title: 'Reminders',
              subtitle: 'A day before each event',
              trailing: BrutalSwitch(value: true, onChanged: (_) {}),
            ),
            BrutalListTile(
              leading: const Icon(LucideIcons.mail),
              title: 'Weekly listings',
              subtitle: 'Mondays',
              trailing: BrutalSwitch(value: false, onChanged: (_) {}),
            ),
            BrutalListTile(
              leading: const Icon(LucideIcons.creditCard),
              title: 'Payment',
              subtitle: 'Card ending 4417',
              onTap: () {},
            ),
          ],
        ),
      ],
    ),
    KitSection(
      title: 'Chosen, destructive, off',
      children: [
        BrutalListGroup(
          children: [
            BrutalListTile(title: 'Harbour', selected: true, onTap: () {}),
            BrutalListTile(title: 'Old town', onTap: () {}),
            BrutalListTile(
              title: 'Sign out',
              isDestructiveAction: true,
              onTap: () {},
            ),
            const BrutalListTile(title: 'Delete account', enabled: false),
          ],
        ),
      ],
    ),
    const _Tables(),
    const _Collections(),
  ],
);

class _Night {
  const _Night(this.title, this.venue, this.day, this.sold, this.price);
  final String title;
  final String venue;
  final int day;
  final int sold;
  final double price;
}

const _nights = [
  _Night('Low Tide', 'The Shed', 14, 212, 18),
  _Night('Paper Walls', 'Dock 4', 15, 340, 24),
  _Night('Night Garden', 'Glasshouse', 15, 96, 12),
  _Night('Static Choir', 'The Shed', 16, 180, 20),
  _Night('Slow Motion', 'Cellar', 17, 64, 10),
  _Night('Field Notes', 'Dock 4', 18, 275, 22),
  _Night('Brass Hour', 'Glasshouse', 19, 150, 16),
];

class _Tables extends StatefulWidget {
  const _Tables();

  @override
  State<_Tables> createState() => _TablesState();
}

class _TablesState extends State<_Tables> {
  late final _table = BrutalTableController<_Night>(
    rows: _nights,
    rowKey: (n) => n.title,
    pageSize: 4,
    columns: [
      BrutalDataColumn(
        id: 'title',
        label: 'Night',
        sortKey: (n) => n.title,
        flex: 3,
      ),
      BrutalDataColumn(id: 'venue', label: 'Venue', flex: 2),
      BrutalDataColumn(
        id: 'sold',
        label: 'Sold',
        sortKey: (n) => n.sold,
        numeric: true,
        flex: 2,
      ),
    ],
  );

  @override
  void dispose() {
    _table.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      KitSection(
        title: 'Table',
        note:
            'A full grid of rules, its header in ink; numbers set to the '
            'end in even figures.',
        children: [
          BrutalTable(
            columns: const [
              BrutalTableColumn('Night', flex: 3),
              BrutalTableColumn('Doors'),
              BrutalTableColumn('Price', numeric: true),
            ],
            rows: [
              for (final n in _nights.take(4))
                [n.title, '19:30', '£${n.price.toStringAsFixed(2)}'],
            ],
          ),
        ],
      ),
      const SizedBox(height: BrutalSpacing.extraLarge),
      KitSection(
        title: 'Data table',
        note:
            'Press a heading to sort; press rows (Space, Shift to extend) to '
            'pick them, lime once picked; pages under it.',
        children: [
          BrutalDataTable<_Night>(
            controller: _table,
            cell: (n, column) => switch (column) {
              'title' => n.title,
              'venue' => n.venue,
              _ => '${n.sold}',
            },
          ),
        ],
      ),
      const SizedBox(height: BrutalSpacing.extraLarge),
      const KitSection(
        title: 'Description list',
        note: 'Terms beside their details from 400 wide, over them below.',
        children: [
          BrutalDescriptionList(
            entries: [
              BrutalDescription('Doors', '19:30, last entry 22:00'),
              BrutalDescription('Venue', 'The Shed, 12 Quay Street'),
              BrutalDescription('Ages', '18 and over, ID at the door'),
              BrutalDescription('Refunds', 'Up to a day before'),
            ],
          ),
        ],
      ),
    ],
  );
}

class _Place {
  const _Place(this.name, [this.children = const []]);
  final String name;
  final List<_Place> children;
}

const _venues = [
  _Place('North quay', [
    _Place('The Shed', [_Place('Main room'), _Place('Yard')]),
    _Place('Dock 4'),
  ]),
  _Place('Old town', [_Place('Cellar'), _Place('Glasshouse')]),
];

class _Collections extends StatefulWidget {
  const _Collections();

  @override
  State<_Collections> createState() => _CollectionsState();
}

class _CollectionsState extends State<_Collections> {
  final _acts = ['Doors', 'Support: Paper Walls', 'Low Tide', 'Encore'];
  final _scroll = ScrollController();
  late final _tree = BrutalTreeController<_Place>(
    roots: _venues,
    childrenOf: (p) => p.children,
    expanded: [_venues.first],
  );
  int _refreshed = 0;

  @override
  void dispose() {
    _scroll.dispose();
    _tree.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.brutalTheme.textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: BrutalSpacing.extraLarge),
        KitSection(
          title: 'Reorderable',
          note:
              'Drag a row by its grip (or long-press it); on the grip, Alt '
              'with Up or Down moves it.',
          children: [
            BrutalReorderableList<String>(
              items: _acts,
              labelOf: (a) => a,
              onReorder: (from, to) =>
                  setState(() => _acts.insert(to, _acts.removeAt(from))),
              itemBuilder: (context, a) => Text(a),
            ),
          ],
        ),
        const SizedBox(height: BrutalSpacing.extraLarge),
        KitSection(
          title: 'Swipe actions',
          note:
              'Swipe a row toward the start for its actions; a long swipe '
              'runs the first.',
          children: [
            BrutalListGroup(
              children: [
                for (final n in _nights.take(3))
                  BrutalSwipeRow(
                    startActions: [
                      BrutalSwipeAction(
                        label: 'Save',
                        icon: LucideIcons.heart,
                        onPressed: () {},
                      ),
                    ],
                    endActions: [
                      BrutalSwipeAction(
                        label: 'Share',
                        icon: LucideIcons.share2,
                        onPressed: () {},
                      ),
                      BrutalSwipeAction(
                        label: 'Hide',
                        icon: LucideIcons.eyeOff,
                        isDestructiveAction: true,
                        onPressed: () {},
                      ),
                    ],
                    child: BrutalListTile(title: n.title, subtitle: n.venue),
                  ),
              ],
            ),
          ],
        ),
        const SizedBox(height: BrutalSpacing.extraLarge),
        KitSection(
          title: 'Pull to refresh and scroll area',
          note:
              'Pull the list down past the mark; the square thumb shows '
              'while it scrolls or under the pointer.',
          children: [
            SizedBox(
              height: 240,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: context.brutalTheme.colors.ink,
                    width: BrutalMetrics.borderWidth,
                  ),
                ),
                child: BrutalPullToRefresh(
                  onRefresh: () async {
                    await Future<void>.delayed(const Duration(seconds: 1));
                    if (mounted) setState(() => _refreshed++);
                  },
                  child: BrutalScrollArea(
                    controller: _scroll,
                    semanticLabel: 'Listings',
                    child: ListView(
                      controller: _scroll,
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(BrutalSpacing.regular),
                          child: Text(
                            'Refreshed $_refreshed times',
                            style: t.secondary,
                          ),
                        ),
                        for (final n in [..._nights, ..._nights])
                          BrutalListTile(title: n.title, trailingText: n.venue),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: BrutalSpacing.extraLarge),
        KitSection(
          title: 'Split view',
          note:
              'Drag the rule (or focus it and use the arrows) to share the '
              'room.',
          children: [
            SizedBox(
              height: 200,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: context.brutalTheme.colors.ink,
                    width: BrutalMetrics.borderWidth,
                  ),
                ),
                child: BrutalSplitView(
                  initialFraction: 0.4,
                  minFirst: 96,
                  minSecond: 96,
                  first: Padding(
                    padding: const EdgeInsets.all(BrutalSpacing.regular),
                    child: Text('Nights', style: t.title),
                  ),
                  second: Padding(
                    padding: const EdgeInsets.all(BrutalSpacing.regular),
                    child: Text('Low Tide at The Shed', style: t.body),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: BrutalSpacing.extraLarge),
        KitSection(
          title: 'Tree',
          note:
              'Right opens, Left closes, Up and Down move; the chosen row '
              'is ink.',
          children: [
            BrutalTree<_Place>(
              controller: _tree,
              labelOf: (p) => p.name,
              iconOf: (p) =>
                  p.children.isEmpty ? LucideIcons.mapPin : LucideIcons.folder,
              semanticLabel: 'Venues',
            ),
          ],
        ),
      ],
    );
  }
}

Widget kitSpecimenSectionHeader() => Builder(
  builder: (context) => BrutalSectionHeader(
    'This week',
    trailing: BrutalLink(
      'See all',
      onPressed: () => kitFeedback(context, 'Every night opens here.'),
    ),
  ),
);

Widget kitSpecimenListTile() => Builder(
  builder: (context) => BrutalListTile(
    leading: const Icon(LucideIcons.ticket),
    title: 'Low Tide',
    subtitle: 'The Shed, Friday 14',
    trailingText: '£18',
    showChevron: true,
    onTap: () => kitFeedback(context, 'The night opens here.'),
  ),
);

Widget kitSpecimenListGroup() => Builder(
  builder: (context) => BrutalListGroup(
    header: 'Account',
    footer: 'Your tickets go to this address.',
    children: [
      BrutalListTile(
        title: 'Name',
        trailingText: 'Ada Park',
        onTap: () => kitFeedback(context, 'Your name opens here.'),
      ),
      BrutalListTile(
        title: 'Email',
        trailingText: 'ada@example.com',
        onTap: () => kitFeedback(context, 'Your email opens here.'),
      ),
    ],
  ),
);

Widget kitSpecimenRule() => const Column(
  crossAxisAlignment: CrossAxisAlignment.stretch,
  children: [
    Text('Doors at seven'),
    SizedBox(height: BrutalSpacing.regular),
    BrutalRule(),
    SizedBox(height: BrutalSpacing.regular),
    Text('Last entry at ten'),
  ],
);

Widget kitSpecimenDataTable() => kitOwned(
  create: () => BrutalTableController<_Night>(
    rows: _nights,
    rowKey: (n) => n.title,
    pageSize: 4,
    columns: [
      BrutalDataColumn(
        id: 'title',
        label: 'Night',
        sortKey: (n) => n.title,
        flex: 3,
      ),
      BrutalDataColumn(
        id: 'sold',
        label: 'Sold',
        sortKey: (n) => n.sold,
        numeric: true,
        flex: 2,
      ),
    ],
  ),
  dispose: (table) => table.dispose(),
  builder: (context, table) => BrutalDataTable<_Night>(
    controller: table,
    cell: (n, column) => column == 'title' ? n.title : '${n.sold}',
  ),
);

Widget kitSpecimenCarousel() => BrutalCarousel(
  itemCount: 3,
  semanticLabel: 'This week',
  itemBuilder: (context, i) => ColoredBox(
    color: [
      context.brutalTheme.colors.signal,
      context.brutalTheme.colors.lead,
      context.brutalTheme.colors.pink,
    ][i],
    child: Center(
      child: Text(
        ['Low Tide', 'Paper Walls', 'Night Garden'][i],
        style: context.brutalTheme.textTheme.headline.copyWith(
          color: context.brutalTheme.colors.onBlock,
        ),
      ),
    ),
  ),
);

Widget kitSpecimenReorderableList() => kitState(
  const ['Doors', 'Support: Paper Walls', 'Low Tide'],
  (context, acts, change) => BrutalReorderableList<String>(
    items: acts,
    labelOf: (a) => a,
    onReorder: (from, to) {
      final next = [...acts];
      next.insert(to, next.removeAt(from));
      change(next);
    },
    itemBuilder: (context, a) => Text(a),
  ),
);

Widget kitSpecimenSwipeRow() => Builder(
  builder: (context) => BrutalSwipeRow(
    endActions: [
      BrutalSwipeAction(
        label: 'Archive',
        icon: LucideIcons.archive,
        onPressed: () => kitFeedback(context, 'Archived.'),
      ),
      BrutalSwipeAction(
        label: 'Delete',
        icon: LucideIcons.trash2,
        isDestructiveAction: true,
        onPressed: () => kitFeedback(context, 'Deleted.'),
      ),
    ],
    child: const BrutalListTile(
      title: 'Low Tide',
      subtitle: 'Swipe toward the start',
    ),
  ),
);

Widget kitSpecimenTree() => kitOwned(
  create: () => BrutalTreeController<_Place>(
    roots: _venues,
    childrenOf: (p) => p.children,
    expanded: [_venues.first],
  ),
  dispose: (tree) => tree.dispose(),
  builder: (context, tree) =>
      BrutalTree<_Place>(controller: tree, labelOf: (p) => p.name),
);
