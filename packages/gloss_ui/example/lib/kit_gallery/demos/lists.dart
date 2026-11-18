/// Gloss's wells, rows and cards.
library;

import 'package:material_ui/material_ui.dart';
import 'package:gloss_ui/gloss_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../kit.dart';

/// The lists page.
Widget kitListsDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Wells and cards',
  sections: const [
    KitSection(title: 'A well of rows', children: [_Rows()]),
    KitSection(title: 'Cards', children: [_Cards()]),
    KitSection(title: 'Collections', children: [_Collections()]),
  ],
);

class _Rows extends StatefulWidget {
  const _Rows();

  @override
  State<_Rows> createState() => _RowsState();
}

class _RowsState extends State<_Rows> {
  bool _reminders = true;
  int _chosen = 1;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      GlossWell(
        header: 'Notifications',
        footer: 'Reminders arrive an hour before you start\u00A0cooking.',
        children: [
          GlossListTile(
            leading: const Icon(LucideIcons.bell),
            title: 'Cooking reminders',
            trailing: GlossSwitch(
              value: _reminders,
              onChanged: (v) => setState(() => _reminders = v),
            ),
          ),
          GlossListTile(
            leading: const Icon(LucideIcons.calendarDays),
            title: 'Plan the week on',
            trailingText: 'Sunday',
            onTap: () {},
          ),
          GlossListTile(
            leading: const Icon(LucideIcons.shoppingBasket),
            title: 'Shopping day',
            subtitle: 'Your list is ready the evening before',
            onTap: () {},
          ),
        ],
      ),
      const SizedBox(height: GlossSpacing.large),
      GlossWell(
        header: 'Chosen row',
        children: [
          for (final (i, name) in ['Monday', 'Tuesday', 'Wednesday'].indexed)
            GlossListTile(
              title: name,
              selected: i == _chosen,
              onTap: () => setState(() => _chosen = i),
            ),
        ],
      ),
      const SizedBox(height: GlossSpacing.large),
      GlossWell(
        children: [
          GlossListTile(
            title: 'Delete account',
            destructive: true,
            onTap: () {},
          ),
          const GlossListTile(
            title: 'Shared pantry',
            enabled: false,
            trailingText: 'Not set up',
          ),
        ],
      ),
    ],
  );
}

class _Cards extends StatelessWidget {
  const _Cards();

  @override
  Widget build(BuildContext context) {
    final t = GlossTheme.of(context).textTheme;
    return KitRow(
      children: [
        SizedBox(
          width: 220,
          child: GlossCard(
            onTap: () {},
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Miso aubergine', style: t.title),
                const SizedBox(height: GlossSpacing.tight),
                Text('35 min · Serves 2', style: t.secondary),
              ],
            ),
          ),
        ),
        SizedBox(
          width: 220,
          child: GlossCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Shows only', style: t.title),
                const SizedBox(height: GlossSpacing.tight),
                Text('No press', style: t.secondary),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Dish {
  const _Dish(this.name, this.course, this.minutes);
  final String name;
  final String course;
  final int minutes;
}

class _Shelf {
  const _Shelf(this.name, [this.children = const []]);
  final String name;
  final List<_Shelf> children;
}

class _Collections extends StatefulWidget {
  const _Collections();

  @override
  State<_Collections> createState() => _CollectionsState();
}

class _CollectionsState extends State<_Collections> {
  static const _roots = [
    _Shelf('Pantry', [_Shelf('Grains'), _Shelf('Spices'), _Shelf('Tins')]),
    _Shelf('Fridge', [_Shelf('Dairy'), _Shelf('Greens')]),
    _Shelf('Freezer'),
  ];

  final _table = GlossTableController<_Dish>(
    rows: const [
      _Dish('Lemon risotto', 'Main', 35),
      _Dish('Green curry', 'Main', 25),
      _Dish('Miso aubergine', 'Side', 30),
      _Dish('Pea soup', 'Soup', 20),
      _Dish('Plum crumble', 'Pudding', 45),
      _Dish('Dal', 'Main', 40),
    ],
    rowKey: (d) => d.name,
    pageSize: 4,
    columns: [
      GlossDataColumn(
        id: 'name',
        label: 'Dish',
        sortKey: (d) => d.name,
        flex: 4,
      ),
      // Room for each heading (and the sorted one's arrow) on a phone.
      GlossDataColumn(
        id: 'course',
        label: 'Course',
        sortKey: (d) => d.course,
        flex: 2,
      ),
      GlossDataColumn(
        id: 'minutes',
        label: 'Minutes',
        sortKey: (d) => d.minutes,
        numeric: true,
        flex: 2,
      ),
    ],
  );
  final _tree = GlossTreeController<_Shelf>(
    roots: _roots,
    childrenOf: (s) => s.children,
    expanded: [_roots.first],
  );
  final _scroll = ScrollController();
  final _steps = ['Toast the rice', 'Add the stock', 'Stir in the lemon'];

  @override
  void dispose() {
    _table.dispose();
    _tree.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = GlossTheme.of(context).textTheme;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 560),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GlossDataTable<_Dish>(
            controller: _table,
            cell: (d, column) => switch (column) {
              'name' => d.name,
              'course' => d.course,
              _ => '${d.minutes}',
            },
          ),
          const SizedBox(height: GlossSpacing.large),
          GlossReorderableList<String>(
            items: _steps,
            labelOf: (s) => s,
            onReorder: (from, to) =>
                setState(() => _steps.insert(to, _steps.removeAt(from))),
            itemBuilder: (context, s) => Text(s),
          ),
          const SizedBox(height: GlossSpacing.large),
          GlossWell(
            children: [
              GlossSwipeRow(
                startActions: [
                  GlossSwipeAction(
                    label: 'Plan',
                    icon: LucideIcons.calendarPlus,
                    onPressed: () {},
                  ),
                ],
                endActions: [
                  GlossSwipeAction(
                    label: 'Delete',
                    icon: LucideIcons.trash2,
                    isDestructiveAction: true,
                    onPressed: () {},
                  ),
                ],
                child: const GlossListTile(
                  title: 'Lemon risotto',
                  subtitle: 'Swipe either way',
                ),
              ),
            ],
          ),
          const SizedBox(height: GlossSpacing.large),
          // The two panes sit in a well: what scrolls is cut at its rim. The
          // notes stand in rows as tall as the tree's, and the well is five
          // rows tall, so at rest no row is cut and the panes' rows line up.
          SizedBox(
            height: 5 * (context.glossTheme.controlHeight - 4),
            child: GlossSurface(
              face: GlossFace.well(
                context.glossTheme.colors,
                radius: GlossMetrics.wellRadius,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(
                  GlossMetrics.wellRadius - 2,
                ),
                child: GlossSplitView(
                  minFirst: 140,
                  minSecond: 160,
                  initialFraction: 0.4,
                  // The tree is as tall as its open rows; its pane scrolls it.
                  first: SingleChildScrollView(
                    child: GlossTree<_Shelf>(
                      controller: _tree,
                      labelOf: (s) => s.name,
                      iconOf: (s) => s.children.isEmpty
                          ? LucideIcons.package
                          : LucideIcons.folder,
                    ),
                  ),
                  second: GlossScrollArea(
                    controller: _scroll,
                    child: ListView(
                      controller: _scroll,
                      padding: const EdgeInsets.symmetric(
                        horizontal: GlossSpacing.regular,
                      ),
                      itemExtent: context.glossTheme.controlHeight - 4,
                      children: [
                        for (var i = 1; i <= 14; i++)
                          Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: Text('Shelf note $i', style: t.body),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: GlossSpacing.large),
          GlossCarousel(
            itemCount: 3,
            semanticLabel: 'Photos',
            itemBuilder: (context, i) =>
                Center(child: Text(['The pan', 'The plate', 'The table'][i])),
          ),
          const SizedBox(height: GlossSpacing.large),
          SizedBox(
            height: 200,
            child: GlossPullToRefresh(
              onRefresh: () =>
                  Future<void>.delayed(const Duration(milliseconds: 800)),
              child: ListView(
                children: const [
                  GlossWell(
                    children: [
                      GlossListTile(title: 'Pull down to sync'),
                      GlossListTile(title: 'Lemon risotto'),
                      GlossListTile(title: 'Green curry'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
