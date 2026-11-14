/// The comic page's structure: inked panels with gutters in tiers, the narrator's caption, and the lettered heads.
library;

import 'package:flutter/material.dart';
import 'package:comic_ui/comic_ui.dart';

import '../kit.dart';

Widget kitFramesDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Panels, tiers and captions',
  sections: [
    kitSection('A panel', children: [kitSpecimenPanel()]),
    kitSection('Tiers of panels', children: [kitSpecimenTier()]),
    kitSection('Panels in a column', children: [kitSpecimenPanelStack()]),
    kitSection('A narration caption', children: [kitSpecimenCaption()]),
    kitSection('A well', children: [kitSpecimenWell()]),
    kitSection('A section head', children: [kitSpecimenSectionHead()]),
    kitSection('A panel head', children: [kitSpecimenPanelHead()]),
    kitSection('A line in the lettering', children: [kitSpecimenLetters()]),
    kitSection('A label', children: [kitSpecimenLabel()]),
    kitSection('A tag', children: [kitSpecimenTag()]),
    kitSection('A score in stars', children: [kitSpecimenStars()]),
    kitSection('A way on', children: [kitSpecimenMore()]),
    kitSection('The indicia', children: [kitSpecimenIndicia()]),
  ],
);

Widget kitSpecimenPanel() => const ComicPanel(
  caption: 'A caption',
  child: ComicColumn(
    children: [
      ComicPanelHead('A panel'),
      ComicKvRow('A label', 'A value', isFirst: true),
      ComicKvRow('Another', '12'),
    ],
  ),
);

Widget kitSpecimenTier() => const ComicColumn(
  gap: 12,
  children: [
    ComicTier(
      spans: [8, 4],
      children: [
        ComicPanel(
          caption: 'Spans 8 and 4',
          child: Text('Two thirds on a desktop, half on a phone'),
        ),
        ComicPanel(child: Text('One third on a desktop, half on a phone')),
      ],
    ),
    ComicTier(
      phone: ComicTierLayout.strip,
      children: [
        ComicPanel(child: Text('One')),
        ComicPanel(child: Text('Two')),
        ComicPanel(child: Text('Three')),
      ],
    ),
    ComicTier(
      phone: ComicTierLayout.stack,
      children: [
        ComicPanel(child: Text('One')),
        ComicPanel(child: Text('Two')),
        ComicPanel(child: Text('Three')),
        ComicPanel(child: Text('Four')),
        ComicPanel(child: Text('And five')),
      ],
    ),
  ],
);

Widget kitSpecimenPanelStack() => const ComicTier(
  spans: [6, 6],
  children: [
    ComicPanel(child: Text('A panel beside a stack, as tall as both')),
    ComicPanelStack(
      children: [
        ComicPanel(child: Text('Upper')),
        ComicPanel(child: Text('Lower')),
      ],
    ),
  ],
);

Widget kitSpecimenCaption() => const ComicColumn(
  gap: 8,
  children: [
    ComicCaption('Meanwhile, by the lake…'),
    ComicCaption('A caption in the shade', tone: ComicSpeaker.group),
    ComicCaption('For you', tone: ComicSpeaker.currentUser),
    ComicCaption('Free in the page, under a line of its own', free: true),
  ],
);

Widget kitSpecimenWell() => const ComicGridOf(
  columns: 2,
  children: [
    ComicWell(child: Text('A quiet well')),
    ComicWell(lamp: true, child: Text('The one that matters')),
  ],
);

Widget kitSpecimenSectionHead() =>
    const ComicSectionHeader('A section', note: 'its note');

Widget kitSpecimenPanelHead() => Builder(
  builder: (context) => ComicPanelHead(
    'A panel head',
    sub: 'A line under it',
    more: 'See all',
    onMore: () => kitFeedback(context, 'Everything under this head.'),
  ),
);

Widget kitSpecimenLetters() => const ComicLetters('Any words in the lettering');

Widget kitSpecimenLabel() => const ComicColumn(
  gap: 6,
  // Its own words, so the section's head above it isn't printed twice.
  children: [ComicLabel('Delivery'), ComicLabel('Optional', quiet: true)],
);

Widget kitSpecimenTag() => const Wrap(
  spacing: 8,
  runSpacing: 8,
  children: [
    ComicTag('New', tone: ComicSpeaker.narrator),
    ComicTag('Plain'),
    ComicTag('Yours', tone: ComicSpeaker.currentUser),
    ComicTag('Shade', tone: ComicSpeaker.group),
  ],
);

// At the size a score stands alone; 13 is the size inline in a row's subline.
Widget kitSpecimenStars() => const ComicStars(4, size: 20);

Widget kitSpecimenMore() => Builder(
  builder: (context) => ComicMoreLink(
    'See all of it',
    onPressed: () => kitFeedback(context, 'The whole list.'),
  ),
);

Widget kitSpecimenIndicia() => const ComicIndicia(
  'Every issue a neutral sample; nothing here is anyone real.',
  lead: 'No. 27, this month.',
);

Widget kitSpecimenRating() => kitState(
  3,
  (context, value, change) =>
      ComicRating(label: 'Rate this issue', value: value, onChanged: change),
);
