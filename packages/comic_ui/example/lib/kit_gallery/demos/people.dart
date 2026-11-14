/// People in the look: initials, a picture or a drawn bust. The cast is fiction: a bust is a shape selected by enum or seed, nobody's likeness.
library;

import 'package:flutter/material.dart';
import 'package:comic_ui/comic_ui.dart';

import '../kit.dart';
// The demo art is the example's; a test or page that draws it reads it from there.
// ignore: avoid_relative_lib_imports
import '../../demo_art.dart';

Widget kitPeopleDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'The cast',
  sections: [
    kitSection('A person', children: [kitSpecimenPerson()]),
    kitSection('A few people', children: [kitSpecimenPeople()]),
    kitSection('A lineup', children: [kitSpecimenLineup()]),
  ],
);

Widget kitSpecimenPerson() => const Wrap(
  spacing: 8,
  crossAxisAlignment: WrapCrossAlignment.end,
  children: [
    ComicPerson(initials: 'AC'),
    ComicPerson(initials: 'BD', fillIndex: 1, size: 48),
    ComicPerson(
      portrait: ComicPortrait(ComicBust.quiff, cropped: true),
      size: 48,
    ),
    ComicPerson(
      portrait: ComicPortrait(ComicBust.beanie, cropped: true),
      size: 48,
      isCurrentUser: true,
    ),
    ComicPerson(
      portrait: ComicPortrait(ComicBust.puff, cropped: true),
      size: 48,
      out: true,
    ),
  ],
);

Widget kitSpecimenPeople() => const ComicPeople([
  ComicPerson(initials: 'AB', size: 28),
  ComicPerson(initials: 'CD', size: 28, fillIndex: 1),
  ComicPerson(initials: 'EF', size: 28, fillIndex: 2),
  ComicPerson(initials: 'GH', size: 28),
  ComicPerson(initials: 'IJ', size: 28),
  ComicPerson(initials: 'KL', size: 28),
]);

Widget kitSpecimenLineup() => const ComicLineup([
  ComicCast('Sam', portrait: ComicPortrait(ComicBust.bob)),
  ComicCast(
    'You',
    portrait: ComicPortrait(ComicBust.puff),
    isCurrentUser: true,
  ),
  ComicCast('Alex', portrait: ComicPortrait(ComicBust.spikes)),
  ComicCast('Robin', portrait: ComicPortrait(ComicBust.topknot)),
]);
