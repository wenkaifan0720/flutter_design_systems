/// What the people say and what the page shouts: the shapes that carry words. A balloon sizes to any words with its tail fused on; a burst fits any number.
library;

import 'package:flutter/material.dart';
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

Widget kitSpecimenBalloon() => const ComicColumn(
  gap: 10,
  children: [
    ComicBalloon('Short.', by: 'Someone · 21:16'),
    ComicBalloon(
      'A longer sentence with a tail that stays on however it wraps, at any width at all.',
      tail: ComicTail.bottomEnd,
    ),
    ComicBalloon('From the side.', tail: ComicTail.side),
  ],
);

Widget kitSpecimenThought() => const ComicThought('Still thinking it over');

Widget kitSpecimenBurst() =>
    const ComicBurst(number: '23', over: 'In', under: 'days!');

Widget kitSpecimenPop() => const Wrap(
  spacing: 8,
  children: [
    ComicPop('5'),
    ComicPop('12', isCurrentUser: true),
    ComicPop('4.7', width: 96, height: 80, size: 34, plate: true),
  ],
);

Widget kitSpecimenStamp() => const Wrap(
  spacing: 18,
  children: [ComicStamp('Paid'), ComicStamp('Leads', tight: true)],
);
