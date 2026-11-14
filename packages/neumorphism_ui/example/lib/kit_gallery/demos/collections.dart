/// Tables, trees and lists that move.
library;

import 'package:flutter/widgets.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

import '../kit.dart';

Widget kitCollectionsDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Tables, trees and lists that move',
  sections: kitCollectionsSections(),
);

List<Widget> kitCollectionsSections() => [
  kitSection('Sort, select and page', children: [kitSpecimenDataTable()]),
  kitSection('A tree of rooms', children: [kitSpecimenTreeView()]),
  kitSection('Put them in order', children: [kitSpecimenReorderableListView()]),
  kitSection(
    'Slide a row for its actions',
    children: [kitSpecimenSwipeActions()],
  ),
  kitSection('Two panes that share the room', children: [kitLiveResizable()]),
  kitSection('A region with its own bar', children: [kitLiveScrollArea()]),
];

class _Room {
  const _Room(this.name, this.floor, this.heat);
  final String name;
  final String floor;
  final int heat;
}

const _rooms = [
  _Room('Attic', 'Top', 17),
  _Room('Bedroom', 'Upstairs', 19),
  _Room('Cellar', 'Below', 14),
  _Room('Hall', 'Ground', 18),
  _Room('Kitchen', 'Ground', 22),
  _Room('Landing', 'Upstairs', 18),
  _Room('Porch', 'Ground', 12),
  _Room('Study', 'Upstairs', 21),
];

Widget kitSpecimenDataTable() => kitHeld<DesignTableController<_Room>>(
  () => DesignTableController<_Room>(
    rows: _rooms,
    pageSize: 5,
    columns: [
      DesignTableColumn<_Room>(
        id: 'room',
        label: 'Room',
        sortKey: (r) => r.name,
      ),
      DesignTableColumn<_Room>(
        id: 'floor',
        label: 'Floor',
        sortKey: (r) => r.floor,
      ),
      DesignTableColumn<_Room>(
        id: 'heat',
        label: 'Heat',
        numeric: true,
        sortKey: (r) => r.heat,
      ),
    ],
    // Sorted by room from the first frame, so a header carries its sort mark: unsorted, a table titled for sorting showed
    // no sign it sorts (fresh-eyes round 12).
  )..sortBy('room'),
  (context, rooms) => NeumorphicDataTable<_Room>(
    label: 'Rooms',
    controller: rooms,
    cell: (r, column) => switch (column.id) {
      'room' => r.name,
      'floor' => r.floor,
      _ => '${r.heat}°',
    },
  ),
);

Widget kitSpecimenTreeView() => kitHeld<DesignTreeController<String>>(
  () => DesignTreeController<String>(
    roots: const ['Upstairs', 'Ground'],
    expanded: const ['Upstairs'],
    childrenOf: (n) => switch (n) {
      'Upstairs' => const ['Bedroom', 'Study', 'Landing'],
      'Ground' => const ['Kitchen', 'Hall'],
      _ => const <String>[],
    },
  ),
  (context, places) => NeumorphicTreeView<String>(
    label: 'Rooms',
    controller: places,
    labelOf: (n) => n,
    iconOf: (n) => n == 'Upstairs' || n == 'Ground'
        ? NeumorphicGlyphs.folder
        : NeumorphicGlyphs.lamp,
  ),
);

Widget kitSpecimenReorderableListView() => kitValue<List<String>>(
  const ['Hall', 'Kitchen', 'Study', 'Bedroom'],
  // A list's rows stand in their card, as every list's do: on the bare wall its rules read as ruled paper.
  (context, order, change) => NeumorphicSlab(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    child: NeumorphicReorderableListView<String>(
      items: order,
      labelOf: (s) => s,
      onReorder: (from, to) {
        final next = [...order];
        next.insert(to, next.removeAt(from));
        change(next);
      },
      itemBuilder: (context, s) => Text(s),
    ),
  ),
);

// Two rows: the first at rest, so the row reads as a row, and the second slid open. Open, a row slides the width of
// its actions aside; the state at its end is what stays in view beside them. Alone and open, the row had no name and
// no body left in view. They stand on the wall: a sliding row covers its actions in the wall's colour.
// Two rows of one card: bare on the wall, the open row was a lone status word beside its keys, its words slid out of
// sight with nothing to show they were a row. Its line runs long enough that its end stays in view as it slides.
// The rows a breath inside the card: a row is square, so at its edge it cut the card's round corners off.
Widget kitSpecimenSwipeActions() => NeumorphicSlab(
  padding: const EdgeInsets.all(8),
  child: NeumorphicColumn(
    gap: 0,
    children: [
      NeumorphicSwipeActions(
        startActions: [DesignSwipeAction(label: 'Pin', onPressed: () {})],
        endActions: [
          DesignSwipeAction(label: 'Archive', onPressed: () {}),
          DesignSwipeAction(
            label: 'Delete',
            destructive: true,
            onPressed: () {},
          ),
        ],
        child: const NeumorphicListTile(
          title: 'Bedroom',
          subtitle: 'Two lamps',
          trailing: NeumorphicStatus('Lit'),
          isFirst: true,
        ),
      ),
      NeumorphicSwipeActions(
        initiallyOpen: true,
        startActions: [DesignSwipeAction(label: 'Pin', onPressed: () {})],
        endActions: [
          DesignSwipeAction(label: 'Archive', onPressed: () {}),
          DesignSwipeAction(
            label: 'Delete',
            destructive: true,
            onPressed: () {},
          ),
        ],
        child: const NeumorphicListTile(
          title: 'Kitchen',
          subtitle: 'One lamp over the worktop, on until eleven',
          trailing: NeumorphicStatus('Lit'),
        ),
      ),
    ],
  ),
);

// The panes are the two halves of one card, parted by its groove: bare on the wall they were two words and a line.
// As tall as its words need at the reader's text size: at twice the size a fixed 180 cut "bedroom" in half.
Widget kitLiveResizable() => Builder(
  builder: (context) => NeumorphicSlab(
    padding: EdgeInsets.zero,
    child: SizedBox(
      height: MediaQuery.textScalerOf(context)
          .clamp(maxScaleFactor: 2)
          .scale(180),
      child: NeumorphicResizable(
        minFirst: 96,
        minSecond: 96,
        first: const Padding(padding: EdgeInsets.all(14), child: Text('Rooms')),
        second: const Padding(
          padding: EdgeInsets.all(14),
          child: Text('Two lamps on in the bedroom'),
        ),
      ),
    ),
  ),
);

Widget kitLiveScrollArea() => kitHeld<ScrollController>(
  ScrollController.new,
  // The region is a card of its own width with its bar at its edge: on the bare wall the bar stood far from its words.
  // 360, so on a phone it spans the column as the cards around it do (at 320 it stopped 30 short).
  (context, scroll) => Align(
    alignment: AlignmentDirectional.centerStart,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 360),
      child: NeumorphicSlab(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        child: SizedBox(
          height: 160,
          child: NeumorphicScrollArea(
            controller: scroll,
            label: 'Rooms',
            alwaysShown: true,
            child: ListView(
              controller: scroll,
              children: [
                for (final r in _rooms)
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Text(r.name),
                  ),
              ],
            ),
          ),
        ),
      ),
    ),
  ),
);
