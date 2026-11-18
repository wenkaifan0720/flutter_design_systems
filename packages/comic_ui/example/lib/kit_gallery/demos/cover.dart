/// A page's opening panel. The cover is the look's whole home, once; a splash opens any other page. Both have a band of about 130 on a phone so the work shows first.
library;

import 'package:material_ui/material_ui.dart';
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

Widget kitSpecimenCover() => Builder(
  builder: (context) => ComicCover(
    masthead: kitSay(context, 'Huzzah!'),
    subtitle: kitSay(context, 'The first'),
    emphasis: kitSay(context, 'issue!'),
    issue: ComicCoverBox(kitSay(context, 'No. 27'), kitSay(context, 'so far')),
    price: ComicCoverBox('12', kitSay(context, 'to read')),
    date: ComicCoverBox(
      kitSay(context, 'Wed 11 Nov'),
      kitSay(context, 'mild, 9°'),
    ),
    burst: ComicCoverBurst(
      '23',
      over: kitSay(context, 'Only'),
      under: kitSay(context, 'to go!'),
    ),
    say: kitSay(context, 'A line from the cast, in a balloon.'),
    sayer: 2,
    cast: [
      ComicCast(kitSay(context, 'Sam'), portrait: ComicPortrait(ComicBust.bob)),
      ComicCast(
        kitSay(context, 'You'),
        portrait: ComicPortrait(ComicBust.puff),
        isCurrentUser: true,
      ),
      ComicCast(
        kitSay(context, 'Alex'),
        portrait: ComicPortrait(ComicBust.spikes),
      ),
      ComicCast(
        kitSay(context, 'Robin'),
        portrait: ComicPortrait(ComicBust.topknot),
      ),
    ],
  ),
);

Widget kitSpecimenSplash() => Builder(
  builder: (context) => ComicSplash(
    title: kitSay(context, 'The long\nweekend'),
    caption: kitSay(context, 'Meanwhile, by the lake…'),
    note: kitSay(context, 'Fri 4 – Sun 6 Dec'),
    // At a desk the title runs twice the phone's size across the panel's foot and the burst takes its top end: the
    // cabin stands smaller, up and toward the start, between the note and the title. Centred, the title covered it.
    art: ComicTheme.of(context).desk
        ? ComicArtBand(
            ground: 2,
            leading: ComicMark(ComicMarks.cabin),
            markSize: 120,
            markInset: const EdgeInsetsDirectional.only(end: 200, bottom: 130),
          )
        : ComicArtBand(
            ground: 2,
            leading: ComicMark(ComicMarks.cabin),
            markSize: 180,
          ),
    burst: ComicCoverBurst(
      '23',
      over: kitSay(context, 'In'),
      under: kitSay(context, 'days!'),
    ),
    facts: [
      ('162', kitSay(context, 'Kilometres')),
      (kitSay(context, 'Six'), kitSay(context, 'Walkers')),
      (kitSay(context, 'Easy'), kitSay(context, 'Grade')),
    ],
  ),
);

Widget kitSpecimenEmpty() => Builder(
  builder: (context) => ComicEmptyState(
    title: kitSay(context, 'Nothing here yet'),
    body: kitSay(context, 'The first one will show up here.'),
  ),
);
