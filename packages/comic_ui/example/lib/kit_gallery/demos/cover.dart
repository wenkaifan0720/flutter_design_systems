/// A page's opening panel. The cover is the look's whole home, once; a splash opens any other page. Both have a band of about 130 on a phone so the work shows first.
library;

import 'package:flutter/material.dart';
import 'package:comic_ui/comic_ui.dart';

import '../kit.dart';
// The demo art is the example's; a test or page that draws it reads it from there.
// ignore: avoid_relative_lib_imports
import '../../demo_art.dart';

Widget kitCoverDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'The cover and the splash',
  sections: [
    kitSection('The cover', children: [kitSpecimenCover()]),
    kitSection('A splash', children: [kitSpecimenSplash()]),
    kitSection('Nothing here yet', children: [kitSpecimenEmpty()]),
  ],
);

Widget kitSpecimenCover() => const ComicCover(
  masthead: 'Huzzah!',
  subtitle: 'The first',
  emphasis: 'issue!',
  issue: ComicCoverBox('No. 27', 'so far'),
  price: ComicCoverBox('12', 'to read'),
  date: ComicCoverBox('Wed 11 Nov', 'mild, 9°'),
  burst: ComicCoverBurst('23', over: 'Only', under: 'to go!'),
  say: 'A line from the cast, in a balloon.',
  sayer: 2,
  cast: [
    ComicCast('Sam', portrait: ComicPortrait(ComicBust.bob)),
    ComicCast(
      'You',
      portrait: ComicPortrait(ComicBust.puff),
      isCurrentUser: true,
    ),
    ComicCast('Alex', portrait: ComicPortrait(ComicBust.spikes)),
    ComicCast('Robin', portrait: ComicPortrait(ComicBust.topknot)),
  ],
);

Widget kitSpecimenSplash() => const ComicSplash(
  title: 'The long\nweekend',
  caption: 'Meanwhile, by the lake…',
  note: 'Fri 4 – Sun 6 Dec',
  art: ComicArtBand(
    ground: 2,
    leading: ComicMark(ComicMarks.cabin),
    markSize: 180,
  ),
  burst: ComicCoverBurst('23', over: 'In', under: 'days!'),
  facts: [('162', 'Kilometres'), ('Six', 'Walkers'), ('Easy', 'Grade')],
);

Widget kitSpecimenEmpty() => const ComicEmptyState(
  title: 'Nothing here yet',
  body: 'The first one will show up here.',
);
