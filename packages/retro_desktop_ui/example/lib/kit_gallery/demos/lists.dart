/// A window full of things: a list view with its scroll bar, a table, folders and files, a tree with its shares, a checklist, a document.
library;

import 'package:flutter/material.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../kit.dart';
// The demo art is the example's; a test or page that draws it reads it from there.
// ignore: avoid_relative_lib_imports
import '../../demo_art.dart';

Widget kitListsDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Lists, tables and folders',
  sections: [
    kitSection('A list view', children: [kitSpecimenListView()]),
    kitSection('A table', children: [kitSpecimenTable()]),
    kitSection('Folders', children: [kitSpecimenFolderGrid()]),
    kitSection('Files', children: [kitSpecimenFileGrid()]),
    kitSection('A tree of shares', children: [kitSpecimenTreeBars()]),
    kitSection('A checklist', children: [kitSpecimenChecklist()]),
    kitSection('A document', children: [kitSpecimenDocument()]),
  ],
);

// A list you choose from: the chosen row lit across every column, the arrows moving it.
Widget kitSpecimenListView() => kitValue<int>(
  1,
  (value, change) => RetroDesktopListTable(
    label: 'Documents',
    total: 40,
    selected: value,
    onSelected: change,
    columns: const [
      RetroDesktopListTableColumn('Name'),
      RetroDesktopListTableColumn('Edited', width: 96, sorted: true),
    ],
    rows: const [
      RetroDesktopListTableRow(
        title: 'The one from this morning',
        note: 'First folder',
        cells: [('09:14', 'today')],
      ),
      RetroDesktopListTableRow(
        title: 'Something from yesterday',
        note: 'Second folder',
        cells: [('18:05', 'yesterday')],
      ),
      RetroDesktopListTableRow(
        title: 'One from earlier this week',
        note: 'Third folder',
        cells: [('16:30', 'Thursday')],
      ),
    ],
  ),
);

Widget kitSpecimenTable() => const RetroDesktopTable(
  columns: [
    RetroDesktopTableColumn('What', flex: 2),
    RetroDesktopTableColumn('When', figures: true),
    RetroDesktopTableColumn('How much', figures: true, sorted: true, end: true),
  ],
  rows: [
    ['The largest entry', '03 Mar', '198'],
    ['The next one', '09 Mar', '168'],
    ['A middling entry', '11 Mar', '128'],
  ],
  total: ['Total', '', '494'],
);

Widget kitSpecimenFolderGrid() => kitValue(
  0,
  (value, change) => RetroDesktopFolderGrid(
    items: [
      for (final (index, entry) in const [
        ('First kind', LucideIcons.star, '6 things'),
        ('Second kind', LucideIcons.bookOpen, '4 things'),
        ('Third kind', LucideIcons.house, '2 things'),
      ].indexed)
        RetroDesktopFolder(
          entry.$1,
          icon: entry.$2,
          note: entry.$3,
          selected: value == index,
          onPressed: () => change(index),
          art: RetroDesktopFolderArt(selected: value == index, icon: entry.$2),
        ),
    ],
  ),
);

Widget kitSpecimenFileGrid() => kitValue(
  1,
  (value, change) => RetroDesktopFileGrid(
    items: [
      for (final (index, entry) in const [
        ('first-sheet.pdf', 'PDF', '2 pages', RetroDesktopFileArt.text),
        ('the-numbers.csv', 'CSV', '18 rows', RetroDesktopFileArt.table),
        ('a-drawing.svg', 'SVG', '1 sheet', RetroDesktopFileArt.plan),
      ].indexed)
        RetroDesktopFile(
          entry.$1,
          kind: entry.$2,
          note: entry.$3,
          selected: value == index,
          onPressed: () => change(index),
          art: RetroDesktopFilePageArt(
            kind: entry.$4,
            selected: value == index,
          ),
        ),
    ],
  ),
);

Widget kitSpecimenTreeBars() => const RetroDesktopTreeBars(
  rows: [
    RetroDesktopTreeRow('First part', '310', share: .48, open: true),
    RetroDesktopTreeRow('A piece of it', '190', share: .3, level: 1),
    RetroDesktopTreeRow('Another piece', '120', share: .18, level: 1),
    RetroDesktopTreeRow('Second part', '220', share: .34, open: false),
    // The parts add up to the total.
    RetroDesktopTreeRow('Third part', '110', share: .17, open: false),
  ],
  totalName: 'Total',
  total: '640',
);

Widget kitSpecimenChecklist() => kitValue(
  <bool>[true, false, false],
  (values, change) => RetroDesktopChecklist(
    title: 'Checklist',
    items: [
      RetroDesktopCheckItem(
        'The first step, done some time ago',
        value: values[0],
        onChanged: (next) => change([...values]..[0] = next),
      ),
      RetroDesktopCheckItem(
        'The step to take next',
        value: values[1],
        isCurrent: true,
        chips: const ['today 14:00'],
        selectedChip: 'today 14:00',
        onChanged: (next) => change([...values]..[1] = next),
      ),
      RetroDesktopCheckItem(
        'The last step',
        value: values[2],
        chips: const ['Fri 13 Mar'],
        onChanged: (next) => change([...values]..[2] = next),
      ),
    ],
  ),
);

Widget kitSpecimenDocument() => const RetroDesktopDocument(
  path: ['Everything', 'First folder'],
  title: 'A plan worth keeping',
  meta: [('Made', 'Sun 1 March'), ('Edited', 'today 09:14')],
  tags: ['first', 'second'],
  addTag: 'Tag',
  paragraphs: [
    'This is the paragraph that says what the thing is and who it is for.',
  ],
);
