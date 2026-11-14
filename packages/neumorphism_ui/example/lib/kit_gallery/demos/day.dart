/// Time as things to touch: a day as a pressed tray of raised tiles, a month in a well, a bank of round push buttons.
library;

import 'package:flutter/material.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

import '../kit.dart';

Widget kitDayDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'The day, the month, the bank',
  sections: [
    kitSection('A day in a tray', children: [kitSpecimenDayTray()]),
    kitSection('A month', children: [kitSpecimenMonth()]),
    kitSection('A bank of push buttons', children: [kitSpecimenPushBank()]),
    kitSection('A note', children: [kitSpecimenNote()]),
  ],
);

Widget kitSpecimenDayTray() => const NeumorphicDayTray(
  from: 9,
  to: 14,
  now: '12:45',
  free: [NeumorphicTrayFree('13:15', '14:00', 'Free, 45 min')],
  events: [
    NeumorphicTrayEvent(
      start: '09:00',
      end: '09:30',
      title: 'A short check-in',
      subtitle: '09:00, by video',
      mark: NeumorphicMarkShape.solid,
      isPast: true,
    ),
    NeumorphicTrayEvent(
      start: '10:00',
      end: '11:30',
      title: 'A site visit',
      subtitle: '10:00 to 11:30',
      detail: 'At the north entrance',
      mark: NeumorphicMarkShape.solid,
      isPast: true,
    ),
    NeumorphicTrayEvent(
      start: '12:30',
      end: '13:15',
      title: 'A review',
      subtitle: '12:30 to 13:15',
      mark: NeumorphicMarkShape.half,
      isCurrent: true,
    ),
  ],
);

Widget kitSpecimenMonth() => const NeumorphicMonth(
  year: 2026,
  month: 11,
  today: 11,
  marked: {2, 3, 4, 9, 12, 16, 19, 23, 25},
);

Widget kitSpecimenPushBank() => NeumorphicPushGroup(
  items: [
    NeumorphicPush(
      icon: NeumorphicGlyphs.sunrise,
      label: 'Open',
      note: 'Ran 06:45',
      onPressed: () {},
    ),
    NeumorphicPush(
      icon: NeumorphicGlyphs.logOut,
      label: 'Away',
      note: 'Off 16:05',
      onPressed: () {},
    ),
    NeumorphicPush(
      icon: NeumorphicGlyphs.users,
      label: 'Busy',
      note: 'Since 19:45',
      selected: true,
      onPressed: () {},
    ),
    NeumorphicPush(
      icon: NeumorphicGlyphs.moonStar,
      label: 'Closed',
      note: 'At 22:30',
      onPressed: () {},
    ),
  ],
);

Widget kitSpecimenNote() => const NeumorphicNote(
  icon: NeumorphicGlyphs.zap,
  overline: 'Next, in 55 min',
  title: 'A short note about the page.',
  subtitle: 'A line under it',
);
