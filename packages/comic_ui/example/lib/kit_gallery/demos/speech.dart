/// What the people say and what the page shouts: the shapes that carry words. A balloon sizes to any words with its tail fused on; a burst fits any number.
library;

import 'package:material_ui/material_ui.dart';
import 'package:comic_ui/comic_ui.dart';

import '../kit.dart';

Widget kitSpeechDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Balloons, bursts and stamps',
  sections: [
    kitSection('A speech balloon', children: [kitSpecimenBalloon()]),
    kitSection('A thought', children: [kitSpecimenThought()]),
    kitSection('A burst', children: [kitSpecimenBurst()]),
    kitSection('A small pop', children: [kitSpecimenPop()]),
    kitSection('A stamp', children: [kitSpecimenStamp()]),
  ],
);

Widget kitSpecimenBalloon() => Builder(
  builder: (context) => ComicColumn(
    gap: 10,
    children: [
      ComicBalloon(
        kitSay(context, 'Short.'),
        by: kitSay(context, 'Someone · 21:16'),
      ),
      ComicBalloon(
        kitSay(
          context,
          'A longer sentence with a tail that stays on however it wraps, at any width at all.',
        ),
        tail: ComicTail.bottomEnd,
      ),
      ComicBalloon(kitSay(context, 'From the side.'), tail: ComicTail.side),
    ],
  ),
);

Widget kitSpecimenThought() => Builder(
  builder: (context) => ComicThought(kitSay(context, 'Still thinking it over')),
);

Widget kitSpecimenBurst() => Builder(
  builder: (context) => ComicBurst(
    number: '23',
    over: kitSay(context, 'In'),
    under: kitSay(context, 'days!'),
  ),
);

Widget kitSpecimenPop() => const Wrap(
  spacing: 8,
  children: [
    ComicPop('5'),
    ComicPop('12', isCurrentUser: true),
    ComicPop('4.7', width: 96, height: 80, size: 34, plate: true),
  ],
);

Widget kitSpecimenStamp() => Builder(
  builder: (context) => Wrap(
    spacing: 18,
    children: [
      ComicStamp(kitSay(context, 'Paid')),
      ComicStamp(kitSay(context, 'Leads'), tight: true),
    ],
  ),
);
