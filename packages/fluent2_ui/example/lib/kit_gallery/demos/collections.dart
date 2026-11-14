/// Collections past the list and the table: a sortable table with rows to
/// check, a scroll area with its bar, two panes split by a
/// handle, a carousel of highlights, a list to reorder, a list to pull down
/// and a file's history.
library;

import 'package:flutter/material.dart';
import 'package:fluent2_ui/fluent2_ui.dart';

import '../kit.dart';

Widget kitCollectionsDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Tables, panes, carousels & history',
  sections: [
    kitSection('Data table', children: [kitSpecimenDataTable()]),
    kitSection('Scroll area', children: [kitLiveScrollArea()]),
    kitSection('Resizable panes', children: [kitLiveResizable()]),
    kitSection('Carousel', children: [kitSpecimenCarouselView()]),
    kitSection('Reorder', children: [kitSpecimenReorderableListView()]),
    kitSection('Pull to refresh', children: [kitLiveRefreshIndicator()]),
    kitSection('Timeline', children: [kitSpecimenTimeline()]),
  ],
);

class _File {
  const _File(this.name, this.owner, this.pages);
  final String name;
  final String owner;
  final int pages;
}

final _files = DesignTableController<_File>(
  rows: const [
    _File('Budget', 'Ana Ruiz', 12),
    _File('Roadmap', 'Kai Ito', 8),
    _File('Handbook', 'Sam Lee', 40),
    _File('Launch plan', 'Ana Ruiz', 21),
  ],
  columns: [
    DesignTableColumn<_File>(id: 'name', label: 'Name', sortKey: (f) => f.name),
    DesignTableColumn<_File>(
      id: 'owner',
      label: 'Owner',
      sortKey: (f) => f.owner,
    ),
    DesignTableColumn<_File>(
      id: 'pages',
      label: 'Pages',
      numeric: true,
      sortKey: (f) => f.pages,
    ),
  ],
);

Widget kitSpecimenDataTable() => Fluent2DataGrid<_File>(
  label: 'Files',
  controller: _files,
  selectable: true,
  cell: (row, column) => switch (column.id) {
    'name' => row.name,
    'owner' => row.owner,
    _ => '${row.pages}',
  },
);

final _scroll = ScrollController();

Widget kitLiveScrollArea() => SizedBox(
  height: 180,
  child: Fluent2ScrollArea(
    controller: _scroll,
    semanticLabel: 'Recent files',
    thumbVisibility: true,
    child: ListView(
      controller: _scroll,
      children: [
        for (final (name, edited) in const [
          ('Budget', 'Edited today'),
          ('Roadmap', 'Edited yesterday'),
          ('Handbook', 'Edited Monday'),
          ('Launch plan', 'Edited last week'),
          ('Hiring', 'Edited last week'),
          ('Retro notes', 'Edited in May'),
        ])
          Fluent2ListItem(
            leading: const Icon(Fluent2Icons.document),
            title: name,
            subtitle: edited,
            onTap: () {},
          ),
      ],
    ),
  ),
);

Widget _pane(String title, String body) => Builder(
  builder: (context) {
    final t = context.fluent2Theme;
    return Padding(
      padding: const EdgeInsets.all(Fluent2Spacing.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: Fluent2Spacing.xs,
        children: [
          Text(title, style: t.body1Strong.c(t.textPrimary)),
          Text(body, style: t.caption1.c(t.textSecondary)),
        ],
      ),
    );
  },
);

// The panes' height grows with the reader's text size, so larger words
// never run out of the panes.
Widget kitLiveResizable() => Builder(
  builder: (context) => SizedBox(
    height: MediaQuery.textScalerOf(context).scale(180),
    child: Fluent2Resizable(
      initialFraction: .4,
      first: _pane('Files', 'Budget, Roadmap, Notes'),
      second: _pane('Budget', 'Edited today by Ana Ruiz'),
    ),
  ),
);

// A highlight: its glyph, its title and a line on what it does, at the
// slide's reading start.
Widget _slide(
  IconData icon,
  String title,
  String line,
  Color fill,
  Color ink,
) => DecoratedBox(
  decoration: BoxDecoration(color: fill),
  child: Builder(
    builder: (context) {
      final t = context.fluent2Theme;
      return Padding(
        padding: const EdgeInsets.all(Fluent2Spacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: Fluent2Spacing.s,
          children: [
            Icon(icon, size: 28, color: ink),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: t.subtitle1.c(ink),
            ),
            Flexible(
              child: Text(
                line,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: t.body1.c(t.textSecondary),
              ),
            ),
          ],
        ),
      );
    },
  ),
);

Widget kitSpecimenCarouselView() => Builder(
  builder: (context) {
    final c = context.fluent2Theme.colors;
    // Taller with the reader's text size, so a slide's words still fit.
    final grow = MediaQuery.textScalerOf(context).scale(16) / 16;
    return Fluent2CarouselView(
      label: 'Highlights',
      aspect: 16 / (7 * grow),
      children: [
        _slide(
          Fluent2Icons.folder,
          'New in Files',
          'Folders now show who edited what, and when.',
          c.brandBackground2,
          c.brandForeground2,
        ),
        _slide(
          Fluent2Icons.link,
          'Share with a link',
          'Anyone in Northwind can open it; you choose who can edit.',
          c.neutralBackground3,
          c.neutralForeground1,
        ),
        _slide(
          Fluent2Icons.cloudArrowUp,
          'Work offline',
          'Changes you make on the road upload when you are back online.',
          c.brandBackground2,
          c.brandForeground2,
        ),
      ],
    );
  },
);

Widget kitSpecimenReorderableListView() {
  var order = ['Budget', 'Roadmap', 'Handbook', 'Launch plan'];
  return StatefulBuilder(
    builder: (context, set) => Fluent2ReorderableListView<String>(
      shrinkWrap: true,
      items: order,
      labelOf: (item) => item,
      onReorder: (from, to) => set(() {
        order = [...order];
        final moved = order.removeAt(from);
        order.insert(to > from ? to - 1 : to, moved);
      }),
      itemBuilder: (context, item) => Fluent2ListItem(title: item),
    ),
  );
}

Widget kitLiveRefreshIndicator() => SizedBox(
  height: 160,
  child: Fluent2RefreshIndicator(
    onRefresh: () => Future<void>.delayed(const Duration(seconds: 1)),
    child: ListView(
      children: const [
        Fluent2ListItem(title: 'Budget', subtitle: 'Pull down to refresh'),
        Fluent2ListItem(title: 'Roadmap'),
        Fluent2ListItem(title: 'Handbook'),
      ],
    ),
  ),
);

Widget kitSpecimenTimeline() => const Fluent2Timeline(
  entries: [
    Fluent2TimelineEntry(
      title: 'Ana Ruiz created Budget',
      time: 'Monday, 9:12 AM',
      icon: Fluent2Icons.document,
    ),
    Fluent2TimelineEntry(
      title: 'Kai Ito commented',
      time: 'Tuesday, 2:30 PM',
      body: 'Can we split travel from events?',
      icon: Fluent2Icons.chat,
    ),
    Fluent2TimelineEntry(
      title: 'Approved',
      time: 'Today, 10:05 AM',
      icon: Fluent2Icons.checkmark,
      tone: Fluent2Tone.success,
    ),
  ],
);
