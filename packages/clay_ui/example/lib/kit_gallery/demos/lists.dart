/// Clay's slabs of rows, rows, cards and badges, tables of data, reordering
/// and swiping, trees, scroll areas, split panes and the carousel.
library;

import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:clay_ui/clay_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../kit.dart';

/// The lists page.
Widget kitListsDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Lists',
  sections: const [
    KitSection(
      title: 'A slab of rows',
      note:
          'Rows on one raised slab; a press opens a soft well under the '
          'row; the chosen row warms toward the accent.',
      children: [_Rows()],
    ),
    KitSection(title: 'Cards and badges', children: [_Cards()]),
    KitSection(
      title: 'A table of data',
      note:
          'Sort by a head, pick rows by their cups; it scrolls sideways '
          'when the screen is narrow.',
      children: [_DataTable()],
    ),
    KitSection(
      title: 'Reordering and swiping',
      note:
          'Drag a row by its grip, or move it with the keys; swipe a row to '
          'show what it can do.',
      children: [_Reorder()],
    ),
    KitSection(
      title: 'A tree',
      note: 'Branches open under a chevron; arrows walk it.',
      children: [_Tree()],
    ),
    KitSection(
      title: 'Scrolling, splitting and pulling',
      note:
          'A groove of a scrollbar; two panes and a grip between them; pull '
          'down to sync.',
      children: [_Panes()],
    ),
    KitSection(
      title: 'A carousel',
      note: 'Slabs that slide past one by one, dots under them.',
      children: [_Carousel()],
    ),
  ],
);

class _Rows extends StatefulWidget {
  const _Rows();

  @override
  State<_Rows> createState() => _RowsState();
}

class _RowsState extends State<_Rows> {
  int _chosen = 0;
  bool _reminders = true;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      ClayGroup(
        header: 'Morning',
        headerTrailing: ClayButton.text('Edit', onPressed: () {}),
        footer: 'Tap a habit to see its streak.',
        children: [
          for (final (i, h) in const [
            (
              'Drink water',
              '5 of 8 glasses',
              ClayTint.sky,
              LucideIcons.droplets,
            ),
            (
              'Morning walk',
              '20 minutes',
              ClayTint.mint,
              LucideIcons.footprints,
            ),
            (
              'Stretch',
              '10 minutes',
              ClayTint.peach,
              LucideIcons.personStanding,
            ),
          ].indexed)
            ClayListTile(
              leading: ClayIconTile(tint: h.$3, child: Icon(h.$4)),
              title: h.$1,
              subtitle: h.$2,
              selected: i == _chosen,
              onTap: () => setState(() => _chosen = i),
            ),
        ],
      ),
      const SizedBox(height: ClaySpacing.large),
      ClayGroup(
        children: [
          ClayListTile(
            title: 'Reminders',
            trailing: ClaySwitch(
              value: _reminders,
              onChanged: (v) => setState(() => _reminders = v),
              semanticLabel: 'Reminders',
            ),
          ),
          ClayListTile(
            title: 'Week starts on',
            trailingText: 'Monday',
            onTap: () {},
          ),
          const ClayListTile(title: 'Version', trailingText: '2.4.0'),
          ClayListTile(
            title: 'Delete all data',
            isDestructiveAction: true,
            onTap: () {},
          ),
          const ClayListTile(
            title: 'Sync (off)',
            enabled: false,
            trailingText: 'Off',
          ),
        ],
      ),
      const SizedBox(height: ClaySpacing.regular),
      const ClaySectionHeader('A header alone'),
      const ClayGroove(indent: 20),
    ],
  );
}

class _Cards extends StatelessWidget {
  const _Cards();

  @override
  Widget build(BuildContext context) {
    final theme = ClayTheme.of(context);
    final c = theme.colors;
    final butter = c.tint(ClayTint.butter);
    final read = ClayCard(
      onTap: () {},
      semanticLabel: 'Read 20 pages',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ClayIconTile(
            tint: ClayTint.lilac,
            child: Icon(LucideIcons.bookOpen),
          ),
          const SizedBox(height: ClaySpacing.medium),
          Text('Read 20 pages', style: theme.textTheme.title),
          Text('12-day streak', style: theme.textTheme.secondary),
        ],
      ),
    );
    final best = ClayCard(
      color: butter,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Best streak',
            style: theme.textTheme.secondary.copyWith(color: c.onColor(butter)),
          ),
          Text(
            '31 days',
            style: theme.textTheme.headline.copyWith(color: c.onColor(butter)),
          ),
        ],
      ),
    );
    return LayoutBuilder(
      // Two cards share the row's width, each half of it, as one grid; on a
      // phone one stands over the other at full width.
      builder: (context, box) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (box.maxWidth >= 480)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: read),
                  const SizedBox(width: ClaySpacing.regular),
                  Expanded(child: best),
                ],
              ),
            )
          else ...[
            read,
            const SizedBox(height: ClaySpacing.regular),
            best,
          ],
          const SizedBox(height: ClaySpacing.regular),
          KitRow(
            children: [
              for (final t in ClayTint.values)
                ClayIconTile(tint: t, child: const Icon(LucideIcons.leaf)),
            ],
          ),
        ],
      ),
    );
  }
}

class _Habit {
  const _Habit(this.name, this.kept, this.streak);
  final String name;
  final int kept;
  final int streak;
}

class _DataTable extends StatefulWidget {
  const _DataTable();

  @override
  State<_DataTable> createState() => _DataTableState();
}

class _DataTableState extends State<_DataTable> {
  final _table = ClayTableController<_Habit>(
    rows: const [
      _Habit('Drink water', 6, 12),
      _Habit('Morning walk', 5, 9),
      _Habit('Read', 4, 4),
      _Habit('Stretch', 7, 21),
    ],
    rowKey: (h) => h.name,
    columns: [
      ClayDataColumn(id: 'name', label: 'Habit', sortKey: (h) => h.name),
      ClayDataColumn(
        id: 'kept',
        label: 'This week',
        sortKey: (h) => h.kept,
        numeric: true,
      ),
      ClayDataColumn(
        id: 'streak',
        label: 'Streak',
        sortKey: (h) => h.streak,
        numeric: true,
      ),
    ],
  );

  @override
  void dispose() {
    _table.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ClayDataTable<_Habit>(
    controller: _table,
    selectable: true,
    cell: (h, column) => switch (column) {
      'name' => h.name,
      'kept' => '${h.kept} of 7',
      _ => '${h.streak}',
    },
  );
}

class _Reorder extends StatefulWidget {
  const _Reorder();

  @override
  State<_Reorder> createState() => _ReorderState();
}

class _ReorderState extends State<_Reorder> {
  final _habits = ['Drink water', 'Morning walk', 'Read', 'Stretch'];

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      ClayReorderableList<String>(
        items: _habits,
        labelOf: (s) => s,
        onReorder: (from, to) =>
            setState(() => _habits.insert(to, _habits.removeAt(from))),
        itemBuilder: (context, s) => Text(s),
      ),
      const SizedBox(height: ClaySpacing.regular),
      ClayGroup(
        children: [
          ClaySwipeRow(
            startActions: [
              ClaySwipeAction(
                label: 'Done',
                icon: LucideIcons.check,
                onPressed: () => showClayToast(context, 'Marked done'),
              ),
            ],
            endActions: [
              ClaySwipeAction(
                label: 'Pause',
                icon: LucideIcons.pause,
                onPressed: () => showClayToast(context, 'Paused'),
              ),
              ClaySwipeAction(
                label: 'Delete',
                icon: LucideIcons.trash2,
                isDestructiveAction: true,
                onPressed: () => showClayToast(context, 'Deleted'),
              ),
            ],
            child: const ClayListTile(
              title: 'Drink water',
              subtitle: 'Swipe either way',
            ),
          ),
        ],
      ),
    ],
  );
}

class _Area {
  const _Area(this.name, [this.children = const []]);
  final String name;
  final List<_Area> children;
}

class _Tree extends StatefulWidget {
  const _Tree();

  @override
  State<_Tree> createState() => _TreeState();
}

class _TreeState extends State<_Tree> {
  static const _roots = [
    _Area('Health', [_Area('Drink water'), _Area('Morning walk')]),
    _Area('Mind', [_Area('Read'), _Area('Breathe')]),
    _Area('Home', [_Area('Water the plants')]),
  ];

  final _tree = ClayTreeController<_Area>(
    roots: _roots,
    childrenOf: (a) => a.children,
    expanded: [_roots.first],
  );

  @override
  void dispose() {
    _tree.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ClayCard(
    child: ClayTree<_Area>(controller: _tree, labelOf: (a) => a.name),
  );
}

class _Panes extends StatefulWidget {
  const _Panes();

  @override
  State<_Panes> createState() => _PanesState();
}

class _PanesState extends State<_Panes> {
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ClayTheme.of(context);
    // The panes hold words: they grow with the reader's text size.
    final scale = MediaQuery.textScalerOf(context);
    final days = ClayGroup(
      children: [
        SizedBox(
          height: scale.scale(220),
          child: ClayScrollArea(
            controller: _scroll,
            child: ListView(
              controller: _scroll,
              children: [
                for (var i = 1; i <= 14; i++)
                  ClayListTile(
                    title: 'Day $i',
                    trailingText: '${4 + i % 4} of 8',
                  ),
              ],
            ),
          ),
        ),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: scale.scale(220),
          child: ClaySplitView(
            semanticLabel: 'Habits and the chosen one',
            first: days,
            second: ClayCard(
              // A narrow pane at a large text size scrolls its words.
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Drink water',
                      style: theme.textTheme.title.copyWith(
                        color: theme.colors.ink,
                      ),
                    ),
                    Text('12 days running', style: theme.textTheme.secondary),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: ClaySpacing.regular),
        SizedBox(
          height: scale.scale(200),
          child: ClayPullToRefresh(
            onRefresh: () => Future<void>.delayed(const Duration(seconds: 1)),
            child: ListView(
              // Room round the slab for its shadow inside the list's edge.
              padding: const EdgeInsets.fromLTRB(
                ClaySpacing.large,
                ClaySpacing.small,
                ClaySpacing.large,
                ClaySpacing.large,
              ),
              children: const [
                ClayGroup(
                  header: 'Pull down to sync',
                  children: [
                    ClayListTile(title: 'Drink water', trailingText: '6 of 8'),
                    ClayListTile(title: 'Read', trailingText: '20 min'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Carousel extends StatelessWidget {
  const _Carousel();

  static const _tips = [
    (ClayTint.peach, 'Start small', 'One glass is a habit; eight is a goal.'),
    (ClayTint.mint, 'Stack it', 'Read after the kettle, every time.'),
    (
      ClayTint.sky,
      'Forgive a day',
      'A miss pauses a streak; it does not end it.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = ClayTheme.of(context);
    // A slide holds words: at a larger text size it stands taller, as its
    // lines both grow and wrap.
    final scale = MediaQuery.textScalerOf(context).scale(1);
    return ClayCarousel(
      semanticLabel: 'Tips',
      aspectRatio: 16 / 9 / math.pow(scale, 1.5),
      itemCount: _tips.length,
      itemBuilder: (context, i) {
        final (tint, title, body) = _tips[i];
        // A slide is a tinted panel lying in the carousel's well, casting
        // nothing: no shadow fits whole inside a frame it fills.
        return ClaySurface(
          face: ClayFace.flat(
            theme.colors,
            radius: ClayRadius.large - 4,
          ).copyWith(color: theme.colors.tint(tint), shadowOpacity: 0),
          child: Padding(
            padding: const EdgeInsets.all(ClaySpacing.large),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.headline.copyWith(
                    color: theme.colors.ink,
                  ),
                ),
                Text(
                  body,
                  style: theme.textTheme.body.copyWith(color: theme.colors.ink),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
