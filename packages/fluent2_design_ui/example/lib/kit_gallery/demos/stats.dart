/// Stat tiles on a team dashboard (a figure with its change, a unit, a
/// trend, the lead figure large, one that opens), the metadata line of a
/// file row, the counter that counts its way to a new total, the icon
/// tile in the brand, neutral and Fluent's named hues, and the date block.
library;

import 'package:flutter/material.dart';
import 'package:fluent2_design_ui/fluent2_design_ui.dart';

import '../kit.dart';

Widget kitStatsDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Stats & tiles',
  sections: [
    kitSection('Stat tiles', children: [kitSpecimenStatTiles()]),
    kitSection('Lead figure', children: [kitSpecimenStatLead()]),
    kitSection('Metadata lines', children: [kitSpecimenMetaLines()]),
    kitSection('Counter', children: [kitSpecimenCounter(), const _Counting()]),
    kitSection('Icon tiles', children: [kitSpecimenIconTiles()]),
    kitSection('Every named hue', children: [kitSpecimenIconTileHues()]),
    kitSection('Date blocks', children: [kitSpecimenDateBlocks()]),
  ],
);

/// Two tiles side by side, one with a trend.
Widget kitSpecimenStatTiles() => Row(
  crossAxisAlignment: CrossAxisAlignment.start,
  spacing: Fluent2Spacing.m,
  children: const [
    Expanded(
      child: Fluent2Stat(
        label: 'Files shared',
        value: '1,284',
        delta: Fluent2StatDelta('+12%'),
        caption: 'vs last week',
        trend: [820, 940, 910, 1080, 1010, 1190, 1284],
      ),
    ),
    Expanded(
      child: Fluent2Stat(
        label: 'Meeting hours',
        value: '18.5',
        unit: 'h',
        delta: Fluent2StatDelta('-3 h', up: false, good: true),
        caption: 'vs last week',
        icon: Fluent2Icons.calendarLtr,
      ),
    ),
  ],
);

/// The one lead figure of a view, large, with a unit, a glyph and an
/// unwelcome change; it opens what it counts.
Widget kitSpecimenStatLead() => Fluent2Stat(
  label: 'Storage used',
  value: '9.4',
  unit: 'GB',
  caption: 'of 10 GB on the Team plan',
  icon: Fluent2Icons.cloud,
  size: Fluent2StatSize.large,
  delta: const Fluent2StatDelta('+0.6 GB this week', good: false),
  onPressed: () {},
);

/// A total where it lands, at the title1 step.
Widget kitSpecimenCounter() => const Fluent2Counter(value: 1284);

/// A file row's facts and a message's.
Widget kitSpecimenMetaLines() => const Column(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.start,
  spacing: Fluent2Spacing.s,
  children: [
    Fluent2MetaLine(
      items: [
        Fluent2MetaItem('Kai Tanaka', icon: Fluent2Icons.person),
        Fluent2MetaItem('Edited 2h ago', keepOnPhone: true),
        Fluent2MetaItem(
          '4 comments',
          icon: Fluent2Icons.comment,
          keepOnPhone: true,
        ),
      ],
    ),
    Fluent2MetaLine(
      separator: Fluent2MetaSeparator.bullet,
      items: [
        Fluent2MetaItem('Design channel'),
        Fluent2MetaItem('Launch plan.docx and 2 more files'),
        Fluent2MetaItem('Yesterday', keepOnPhone: true),
      ],
    ),
  ],
);

/// Kinds of thing at the start of rows: a folder, a meeting, a plan, a
/// channel, the sizes.
Widget kitSpecimenIconTiles() => kitRow(const [
  Fluent2IconTile(
    Fluent2Icons.folder,
    hue: Fluent2Hue.cornflower,
    label: 'Folder',
  ),
  Fluent2IconTile(
    Fluent2Icons.calendarLtr,
    hue: Fluent2Hue.pumpkin,
    label: 'Meeting',
  ),
  Fluent2IconTile(
    Fluent2Icons.taskListLtr,
    hue: Fluent2Hue.forest,
    label: 'Plan',
  ),
  Fluent2IconTile(Fluent2Icons.channel, label: 'Channel'),
  Fluent2IconTile(
    Fluent2Icons.document,
    hue: Fluent2Hue.neutral,
    label: 'File',
  ),
  Fluent2IconTile(
    Fluent2Icons.mail,
    hue: Fluent2Hue.lavender,
    size: 24,
    label: 'Mail',
  ),
  Fluent2IconTile(
    Fluent2Icons.people,
    hue: Fluent2Hue.magenta,
    size: 48,
    label: 'Team',
  ),
]);

/// Every hue a tile wears: the brand, neutral and Fluent's thirty.
Widget kitSpecimenIconTileHues() => kitRow([
  for (final hue in Fluent2Hue.values)
    Fluent2IconTile(Fluent2Icons.folder, hue: hue, size: 32),
]);

/// The week's meetings: today emphasised, a compact one.
Widget kitSpecimenDateBlocks() => kitRow([
  Fluent2DateBlock(date: DateTime(2026, 11, 2)),
  Fluent2DateBlock(date: DateTime(2026, 11, 3), emphasis: true),
  Fluent2DateBlock(date: DateTime(2026, 11, 5)),
  Fluent2DateBlock(date: DateTime(2026, 11, 12), compact: true),
]);

class _Counting extends StatefulWidget {
  const _Counting();

  @override
  State<_Counting> createState() => _CountingState();
}

class _CountingState extends State<_Counting> {
  double _total = 1284;

  @override
  Widget build(BuildContext context) => Row(
    spacing: Fluent2Spacing.m,
    children: [
      Expanded(child: Fluent2Counter(value: _total, from: 0)),
      Fluent2Button(
        'Share 25 more',
        onPressed: () => setState(() => _total += 25),
      ),
    ],
  );
}
