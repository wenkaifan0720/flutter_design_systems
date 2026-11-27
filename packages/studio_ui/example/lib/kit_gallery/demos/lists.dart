import 'package:material_ui/material_ui.dart';
import 'package:studio_ui/studio_ui.dart';

import '../kit.dart';

/// Section headers, rows on glass, panels and displays.
Widget kitListsDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Lists and panes',
  sections: [
    KitSection(
      title: 'Rows on glass',
      note: 'A press sinks a slot into the glass; the open row keeps it, its lamp lit.',
      children: [
        StudioListGroup(
          children: [
            StudioListTile(
              leading: const Icon(LucideIcons.headphones),
              title: 'The bookbinder who keeps every offcut',
              subtitle: 'Low Ceiling · Today · 37 min left',
              selected: true,
              onTap: () {},
            ),
            StudioListTile(
              leading: const Icon(LucideIcons.headphones),
              title: 'A harbour before the boats go out',
              subtitle: 'Field Notes · Yesterday · 23 min',
              onTap: () {},
            ),
            StudioListTile(
              title: 'Audio quality',
              trailingText: 'High',
              onTap: () {},
            ),
            const StudioListTile(title: 'Version', trailingText: '0.1.0'),
          ],
        ),
      ],
    ),
    KitSection(
      title: 'Panels and displays',
      note: 'Chrome is metal; what people read sits on glass.',
      children: [
        StudioPanel(
          child: Row(
            children: [
              const Expanded(child: Text('A panel of brushed metal')),
              StudioButton('Key', onPressed: () {}),
            ],
          ),
        ),
        const StudioDisplay(
          padding: EdgeInsets.all(StudioSpacing.regular),
          child: Text(
            'A display: a pane of glass set into the metal, where the reading happens.',
          ),
        ),
        const StudioDisplay(
          readout: true,
          padding: EdgeInsets.all(StudioSpacing.regular),
          child: Text('A readout pane: lit by day, dark by night.'),
        ),
      ],
    ),
    const KitSection(
      title: 'Data table',
      note: 'Sort by a column head; choose rows with their lamps.',
      children: [_DataTableDemo()],
    ),
    const KitSection(
      title: 'Scroll area and split view',
      note: 'A slot scrollbar beside the glass; a grip between two panes.',
      children: [
        _ScrollDemo(),
        SizedBox(
          height: 180,
          child: StudioSplitView(
            minFirst: 120,
            minSecond: 120,
            first: SizedBox.expand(
              child: StudioDisplay(child: Center(child: Text('Episodes'))),
            ),
            second: SizedBox.expand(
              child: StudioDisplay(child: Center(child: Text('Notes'))),
            ),
          ),
        ),
      ],
    ),
    KitSection(
      title: 'Carousel',
      note: 'Pages under glass, a lamp for each.',
      children: [
        StudioCarousel(
          itemCount: 3,
          semanticLabel: 'Featured shows',
          itemBuilder: (context, i) => Center(
            child: Text(const ['Night Desk', 'Field Notes', 'Long Table'][i]),
          ),
        ),
      ],
    ),
    KitSection(
      title: 'Reorder, swipe and refresh',
      note: 'A grip to drag by; actions under a row; lamps chasing as it refreshes.',
      children: [
        const _ReorderDemo(),
        Builder(
          builder: (context) => StudioDisplay(
            padding: const EdgeInsets.all(StudioMetrics.recessInset),
            child: StudioSwipeRow(
              startActions: [
                StudioSwipeAction(
                  label: 'Played',
                  icon: const Icon(LucideIcons.check),
                  onPressed: () => kitFeedback(context, 'Marked played'),
                ),
              ],
              endActions: [
                StudioSwipeAction(
                  label: 'Delete',
                  icon: const Icon(LucideIcons.trash2),
                  destructive: true,
                  onPressed: () => kitFeedback(context, 'Deleted'),
                ),
              ],
              child: const StudioListTile(
                title: 'Episode 11',
                subtitle: 'Swipe either way',
              ),
            ),
          ),
        ),
        StudioDisplay(
          padding: const EdgeInsets.all(StudioMetrics.recessInset),
          child: SizedBox(
            height: 180,
            child: StudioPullToRefresh(
              onRefresh: () => Future<void>.delayed(const Duration(seconds: 1)),
              child: ListView(
                children: const [
                  StudioListTile(title: 'Draft 3'),
                  StudioListTile(title: 'Draft 2'),
                  StudioListTile(title: 'Draft 1'),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
    const KitSection(
      title: 'Tree',
      note: 'Folders that open by a wedge or the arrows.',
      children: [
        StudioDisplay(
          padding: EdgeInsets.all(StudioMetrics.recessInset),
          child: _TreeDemo(),
        ),
      ],
    ),
  ],
);

class _Episode {
  const _Episode(this.title, this.length, this.plays);
  final String title;
  final String length;
  final int plays;
}

class _DataTableDemo extends StatefulWidget {
  const _DataTableDemo();

  @override
  State<_DataTableDemo> createState() => _DataTableDemoState();
}

class _DataTableDemoState extends State<_DataTableDemo> {
  final _table = StudioTableController<_Episode>(
    rows: const [
      _Episode('Pilot', '38:02', 1204),
      _Episode('The long table', '51:40', 864),
      _Episode('Field notes from the coast', '44:15', 702),
    ],
    rowKey: (e) => e.title,
    columns: [
      StudioDataColumn(
        id: 'title',
        label: 'Episode',
        sortKey: (e) => e.title,
        flex: 2,
      ),
      StudioDataColumn(
        id: 'length',
        label: 'Length',
        sortKey: (e) => e.length,
        numeric: true,
      ),
      StudioDataColumn(
        id: 'plays',
        label: 'Plays',
        sortKey: (e) => e.plays,
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
  Widget build(BuildContext context) => StudioDataTable<_Episode>(
    controller: _table,
    cell: (e, column) => switch (column) {
      'title' => e.title,
      'length' => e.length,
      _ => '${e.plays}',
    },
  );
}

class _ScrollDemo extends StatefulWidget {
  const _ScrollDemo();

  @override
  State<_ScrollDemo> createState() => _ScrollDemoState();
}

class _ScrollDemoState extends State<_ScrollDemo> {
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => StudioDisplay(
    padding: const EdgeInsets.all(StudioMetrics.recessInset),
    child: SizedBox(
      height: 180,
      child: StudioScrollArea(
        controller: _scroll,
        child: ListView(
          controller: _scroll,
          children: [
            for (var i = 12; i >= 1; i--) StudioListTile(title: 'Take $i'),
          ],
        ),
      ),
    ),
  );
}

class _ReorderDemo extends StatefulWidget {
  const _ReorderDemo();

  @override
  State<_ReorderDemo> createState() => _ReorderDemoState();
}

class _ReorderDemoState extends State<_ReorderDemo> {
  final _queue = ['Night Desk 12', 'Field Notes 4', 'Long Table 9'];

  @override
  Widget build(BuildContext context) => StudioReorderableList<String>(
    items: _queue,
    labelOf: (a) => a,
    onReorder: (from, to) =>
        setState(() => _queue.insert(to, _queue.removeAt(from))),
    itemBuilder: (context, a) => Text(a),
  );
}

class _Folder {
  const _Folder(this.name, [this.children = const []]);
  final String name;
  final List<_Folder> children;
}

class _TreeDemo extends StatefulWidget {
  const _TreeDemo();

  @override
  State<_TreeDemo> createState() => _TreeDemoState();
}

class _TreeDemoState extends State<_TreeDemo> {
  static const _roots = [
    _Folder('Season 2', [
      _Folder('Raw takes', [_Folder('Take 1'), _Folder('Take 2')]),
      _Folder('Mixes'),
    ]),
    _Folder('Season 1', [_Folder('Archive')]),
  ];

  final _tree = StudioTreeController<_Folder>(
    roots: _roots,
    childrenOf: (f) => f.children,
    expanded: [_roots.first],
  );

  @override
  void dispose() {
    _tree.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      StudioTree<_Folder>(controller: _tree, labelOf: (f) => f.name);
}
