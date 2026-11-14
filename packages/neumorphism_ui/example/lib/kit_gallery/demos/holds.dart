/// Grouping rows and revealing detail.
library;

import 'package:flutter/widgets.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

import '../kit.dart';

Widget kitHoldsDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Groups and records',
  sections: [
    kitSection('A divider', children: [kitSpecimenDivider()]),
    kitSection('Grouped rows', children: [kitSpecimenGroupedList()]),
    kitSection('More in place', children: [kitSpecimenDisclosure()]),
    kitSection('Records', children: [kitSpecimenTable()]),
  ],
);
Widget kitSpecimenGroupedList() => NeumorphicListSection(
  label: 'Account',
  footer: 'Only you see these details.',
  children: [
    NeumorphicListTile(
      title: 'Profile',
      subtitle: 'Name and photo',
      isFirst: true,
      onPressed: () {},
    ),
    NeumorphicListTile(
      title: 'Notifications',
      subtitle: 'Choose what reaches you',
      onPressed: () {},
    ),
  ],
);
Widget kitSpecimenDisclosure() => const NeumorphicColumn(
  children: [
    NeumorphicDisclosure(
      title: 'What is included?',
      initiallyExpanded: true,
      isFirst: true,
      child: Text('Every space has room for your people and projects.'),
    ),
    NeumorphicDisclosure(
      title: 'Can I change it later?',
      child: Text('You can update these choices at any time.'),
    ),
  ],
);
Widget kitSpecimenTable() => NeumorphicTable(
  label: 'Purchases',
  columns: const [
    NeumorphicTableColumn('Item', flex: 2),
    NeumorphicTableColumn('Quantity', numeric: true),
    NeumorphicTableColumn('Total', numeric: true),
  ],
  rows: [
    NeumorphicTableRow(
      ['Table lamp', '2', '96.00'],
      selected: true,
      onPressed: () {},
    ),
    NeumorphicTableRow(['Linen shade', '1', '32.00'], onPressed: () {}),
  ],
);

Widget kitSpecimenDivider() => const NeumorphicDivider(space: 24);
