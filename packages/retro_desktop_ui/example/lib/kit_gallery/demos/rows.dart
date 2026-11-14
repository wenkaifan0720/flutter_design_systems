/// What a window lists: rows that press whole, facts on leaders and figures across.
library;

import 'package:flutter/material.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../kit.dart';

Widget kitRowsDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Rows, facts and figures',
  sections: [
    kitSection('A list of rows', children: [kitSpecimenList()]),
    kitSection('An action row', children: [kitSpecimenActionRow()]),
    kitSection('A task', children: [kitSpecimenTaskRow()]),
    kitSection('Facts', children: [kitSpecimenFacts()]),
    kitSection('Stats', children: [kitSpecimenStats()]),
    kitSection('Readings', children: [kitSpecimenReadings()]),
    kitSection('Measures', children: [kitSpecimenMeasures()]),
  ],
);

Widget kitSpecimenList() => RetroDesktopWell(
  child: RetroDesktopList(
    share: true,
    children: const [
      RetroDesktopListTile(
        title: 'A row',
        subtitle: 'A line under it',
        trailing: _Count('8'),
      ),
      RetroDesktopListTile(
        title: 'Another row',
        subtitle: 'A line under it',
        trailing: _Count('10'),
        selected: true,
      ),
    ],
  ),
);

/// A row's count at its end: the trailing size, the meta grey, under the
/// title's weight. Built in the row, so a chosen row's palette reaches it.
class _Count extends StatelessWidget {
  const _Count(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    final t = RetroDesktopTheme.of(context);
    return Text(
      text,
      style: t.type.meta.copyWith(color: t.colors.textSecondary),
      maxLines: 1,
      softWrap: false,
    );
  }
}

Widget kitSpecimenActionRow() => kitAction(
  'Reminder sent',
  (press) => RetroDesktopWell(
    child: RetroDesktopListTile(
      title: 'A signature from the second',
      subtitle: 'Asked on Tuesday',
      leading: const RetroDesktopMonogram('CD'),
      action: RetroDesktopButton(
        'Remind',
        size: RetroDesktopButtonSize.small,
        onPressed: press,
      ),
    ),
  ),
);

Widget kitSpecimenTaskRow() => kitValue(
  <bool>[false, false, true],
  (values, change) => RetroDesktopWell(
    child: RetroDesktopList(
      share: true,
      children: [
        RetroDesktopTaskRow(
          title: 'The first thing',
          subtitle: 'Today',
          overdue: '1 day late',
          priority: 1,
          value: values[0],
          onChanged: (next) => change([...values]..[0] = next),
        ),
        RetroDesktopTaskRow(
          title: 'The next thing',
          subtitle: 'Second folder',
          time: '14:00',
          bell: true,
          priority: 2,
          selected: true,
          value: values[1],
          onChanged: (next) => change([...values]..[1] = next),
        ),
        RetroDesktopTaskRow(
          title: 'Done this morning',
          subtitle: 'Done 09:05',
          priority: 3,
          value: values[2],
          onChanged: (next) => change([...values]..[2] = next),
        ),
      ],
    ),
  ),
);

Widget kitSpecimenFacts() => const RetroDesktopColumn(
  gap: 12,
  children: [
    RetroDesktopDescriptionList([
      RetroDesktopFact('Folder', 'First folder'),
      RetroDesktopFact('Edited', 'Today 09:14', figures: true),
    ]),
    RetroDesktopDescriptionList([
      RetroDesktopFact('Wind', '24 km/h', icon: LucideIcons.wind),
      RetroDesktopFact('Humidity', '81%', icon: LucideIcons.droplets),
    ], leaders: true),
  ],
);

Widget kitSpecimenStats() => const RetroDesktopStats([
  ('Open', '18', null),
  ('Rain today', '6.4', 'mm'),
  ('Next up', '14:00', null),
]);

Widget kitSpecimenReadings() => const RetroDesktopReadings([
  ('High', '11°', null),
  ('Low', '4°', null),
  ('Rain', '6.4', 'mm'),
]);

Widget kitSpecimenMeasures() => const RetroDesktopMeasures([
  ('PM2.5', '6', 'µg/m³'),
  ('NO₂', '17', 'µg/m³'),
  ('O₃', '52', 'µg/m³'),
]);
