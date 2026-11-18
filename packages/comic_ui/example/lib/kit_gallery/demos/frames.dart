/// The comic page's structure: inked panels with gutters in tiers, the narrator's caption, and the lettered heads.
library;

import 'package:material_ui/material_ui.dart';
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

Widget kitSpecimenPanel() => Builder(
  builder: (context) => ComicPanel(
    caption: kitSay(context, 'A caption'),
    child: ComicColumn(
      children: [
        ComicPanelHead(kitSay(context, 'A panel')),
        ComicKvRow(
          kitSay(context, 'A label'),
          kitSay(context, 'A value'),
          isFirst: true,
        ),
        ComicKvRow(kitSay(context, 'Another'), '12'),
      ],
    ),
  ),
);

Widget kitSpecimenTier() => Builder(
  builder: (context) => ComicColumn(
    gap: 12,
    children: [
      ComicTier(
        spans: [8, 4],
        children: [
          ComicPanel(
            caption: kitSay(context, 'Spans 8 and 4'),
            child: Text(
              kitSay(context, 'Two thirds on a desktop, half on a phone'),
            ),
          ),
          ComicPanel(
            child: Text(
              kitSay(context, 'One third on a desktop, half on a phone'),
            ),
          ),
        ],
      ),
      ComicTier(
        phone: ComicTierLayout.strip,
        children: [
          ComicPanel(child: Text(kitSay(context, 'One'))),
          ComicPanel(child: Text(kitSay(context, 'Two'))),
          ComicPanel(child: Text(kitSay(context, 'Three'))),
        ],
      ),
      ComicTier(
        phone: ComicTierLayout.stack,
        children: [
          ComicPanel(child: Text(kitSay(context, 'One'))),
          ComicPanel(child: Text(kitSay(context, 'Two'))),
          ComicPanel(child: Text(kitSay(context, 'Three'))),
          ComicPanel(child: Text(kitSay(context, 'Four'))),
          ComicPanel(child: Text(kitSay(context, 'And five'))),
        ],
      ),
    ],
  ),
);

Widget kitSpecimenPanelStack() => Builder(
  builder: (context) => ComicTier(
    spans: [6, 6],
    children: [
      ComicPanel(
        child: Text(kitSay(context, 'A panel beside a stack, as tall as both')),
      ),
      ComicPanelStack(
        children: [
          ComicPanel(child: Text(kitSay(context, 'Upper'))),
          ComicPanel(child: Text(kitSay(context, 'Lower'))),
        ],
      ),
    ],
  ),
);

Widget kitSpecimenCaption() => Builder(
  builder: (context) => ComicColumn(
    gap: 8,
    children: [
      ComicCaption(kitSay(context, 'Meanwhile, by the lake…')),
      ComicCaption(
        kitSay(context, 'A caption in the shade'),
        tone: ComicSpeaker.group,
      ),
      ComicCaption(kitSay(context, 'For you'), tone: ComicSpeaker.currentUser),
      ComicCaption(
        kitSay(context, 'Free in the page, under a line of its own'),
        free: true,
      ),
    ],
  ),
);

Widget kitSpecimenWell() => Builder(
  builder: (context) => ComicGridOf(
    columns: 2,
    children: [
      ComicWell(child: Text(kitSay(context, 'A quiet well'))),
      ComicWell(
        lamp: true,
        child: Text(kitSay(context, 'The one that matters')),
      ),
    ],
  ),
);

Widget kitSpecimenSectionHead() => Builder(
  builder: (context) => ComicSectionHeader(
    kitSay(context, 'A section'),
    note: kitSay(context, 'its note'),
  ),
);

Widget kitSpecimenPanelHead() => Builder(
  builder: (context) => ComicPanelHead(
    kitSay(context, 'A panel head'),
    sub: kitSay(context, 'A line under it'),
    more: kitSay(context, 'See all'),
    onMore: () => kitFeedback(context, 'Everything under this head.'),
  ),
);

Widget kitSpecimenLetters() => Builder(
  builder: (context) =>
      ComicLetters(kitSay(context, 'Any words in the lettering')),
);

Widget kitSpecimenLabel() => Builder(
  builder: (context) => ComicColumn(
    gap: 6,
    // Its own words, so the section's head above it isn't printed twice.
    children: [
      ComicLabel(kitSay(context, 'Delivery')),
      ComicLabel(kitSay(context, 'Optional'), quiet: true),
    ],
  ),
);

Widget kitSpecimenTag() => Builder(
  builder: (context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      ComicTag(kitSay(context, 'New'), tone: ComicSpeaker.narrator),
      ComicTag(kitSay(context, 'Plain')),
      ComicTag(kitSay(context, 'Yours'), tone: ComicSpeaker.currentUser),
      ComicTag(kitSay(context, 'Shade'), tone: ComicSpeaker.group),
    ],
  ),
);

// At the size a score stands alone; 13 is the size inline in a row's subline.
Widget kitSpecimenStars() => const ComicStars(4, size: 20);

Widget kitSpecimenMore() => Builder(
  builder: (context) => ComicMoreLink(
    kitSay(context, 'See all of it'),
    onPressed: () => kitFeedback(context, kitSay(context, 'The whole list.')),
  ),
);

Widget kitSpecimenIndicia() => Builder(
  builder: (context) => ComicIndicia(
    kitSay(
      context,
      'Every issue a neutral sample; nothing here is anyone real.',
    ),
    lead: kitSay(context, 'No. 27, this month.'),
  ),
);

Widget kitSpecimenRating() => kitState(
  3,
  (context, value, change) =>
      ComicRating(label: 'Rate this issue', value: value, onChanged: change),
);
