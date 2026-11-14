/// What an active window opens on: an object or a big figure, with what it means.
library;

import 'package:flutter/material.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';

import '../kit.dart';

Widget kitObjectsDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Objects and heroes',
  sections: [
    kitSection('A day tile', children: [kitSpecimenDayTile()]),
    kitSection('A big figure', children: [kitSpecimenBigFigure()]),
    kitSection('A hero', children: [kitSpecimenHero()]),
    kitSection('A figure hero', children: [kitSpecimenFigureHero()]),
    kitSection('A reading head', children: [kitSpecimenReadingHead()]),
    kitSection('Nothing here yet', children: [kitSpecimenEmpty()]),
  ],
);

Widget kitSpecimenDayTile() => const RetroDesktopDayTile(
  month: 'MAR',
  year: '2026',
  day: '14',
  weekday: 'Saturday',
);

Widget kitSpecimenBigFigure() => const RetroDesktopBigFigure('8', unit: '°');

Widget kitSpecimenHero() => const RetroDesktopHeroHeader(
  object: RetroDesktopDayTile(
    month: 'MAR',
    year: '2026',
    day: '14',
    weekday: 'Saturday',
  ),
  eyebrow: 'Good morning',
  title: '3 left today',
  progress: .4,
  progressLabel: '2 of 5 done',
  flag: '1 overdue',
  flagNote: 'since Thursday',
  stats: [
    ('Open', '18', null),
    ('This week', '4', null),
    ('Next up', '14:00', null),
  ],
);

Widget kitSpecimenFigureHero() => const RetroDesktopFigureHero(
  value: '8',
  unit: '°',
  title: 'Showers',
  note: 'Clearing by 14:00',
  reads: [('High', '11°', null), ('Low', '4°', null), ('Rain', '6.4', 'mm')],
  summary: 'Showers ease by midday, dry until evening, then rain again.',
);

Widget kitSpecimenReadingHead() => const RetroDesktopReadingHead(
  value: '28',
  title: 'Good',
  note: 'Nothing to mention today.',
);

Widget kitSpecimenEmpty() => const RetroDesktopEmpty(
  title: 'Nothing here yet',
  body: 'It will show up here when the first one comes in.',
);
