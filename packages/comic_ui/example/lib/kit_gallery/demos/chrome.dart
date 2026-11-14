/// The screen and its bars, the picture and the states a page can be in.
library;

import 'package:flutter/material.dart';
import 'package:comic_ui/comic_ui.dart';

import '../kit.dart';
// The demo art is the example's; a test or page that draws it reads it from there.
// ignore: avoid_relative_lib_imports
import '../../demo_art.dart';

Widget kitChromeDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Screen, bars and pictures',
  sections: [
    kitSection('The top bar', children: [kitSpecimenTopBar()]),
    kitSection('The tab bar', children: [kitSpecimenTabBar()]),
    kitSection('The name', children: [kitSpecimenLogo()]),
    kitSection('A group', children: [kitSpecimenGroupChip()]),
    kitSection('A picture, in its fallback', children: [kitSpecimenPhoto()]),
    kitSection('A picture card', children: [kitSpecimenPictureCard()]),
    kitSection('Loading', children: [kitSpecimenLoadingState()]),
    kitSection('An error', children: [kitSpecimenErrorState()]),
    kitSection('The plain button', children: [kitSpecimenButton()]),
    kitSection('The plain input', children: [kitSpecimenInput()]),
  ],
);

Widget kitSpecimenTopBar() => const ComicAppBar(title: 'A page');

Widget kitSpecimenTabBar() => kitState(
  0,
  (context, value, change) => ComicNavigationBar(
    destinations: kitTabs,
    selectedIndex: value,
    onDestinationSelected: change,
  ),
);

Widget kitSpecimenLogo() => const ComicLogo('Huzzah!');

Widget kitSpecimenGroupChip() => Builder(
  builder: (context) => ComicGroupChip(
    'Our six',
    people: const [
      ComicPerson(initials: 'AB', size: 26),
      ComicPerson(initials: 'CD', size: 26, fillIndex: 1),
    ],
    onPressed: () => kitFeedback(context, 'Our six, all of them.'),
  ),
);

Widget kitSpecimenPhoto() =>
    const ComicMedia(slotId: 'kit-picture', aspect: 16 / 9, label: 'A picture');

Widget kitSpecimenPictureCard() => const ComicRow(
  spans: [6, 6],
  children: [
    ComicPictureCard(
      slotId: 'kit-picture',
      image: ComicArtBand(leading: ComicMark(ComicMarks.mug)),
      title: 'A piece',
      subtitle: 'A kind',
      figure: '42',
    ),
    ComicPictureCard(
      slotId: 'kit-picture-2',
      image: ComicArtBand(ground: 4, leading: ComicMark(ComicMarks.peak)),
      title: 'Another',
      subtitle: 'A kind',
      figure: '38',
    ),
  ],
);

Widget kitSpecimenLoadingState() =>
    const SizedBox(height: 140, child: ComicLoadingState());

Widget kitSpecimenErrorState() => Builder(
  builder: (context) => ComicErrorState(
    title: 'That did not load',
    message: 'Check the line and try again.',
    onRetry: () => kitFeedback(context, 'Trying again.'),
  ),
);

Widget kitSpecimenButton() => Builder(
  builder: (context) => ComicButton(
    'A plain button',
    onPressed: () => kitFeedback(context, 'Button pressed.'),
  ),
);

Widget kitSpecimenInput() => const ComicInput(hint: 'A plain input');

Widget kitSpecimenScreen() => const ComicScaffold(
  topBar: ComicAppBar(title: 'A page'),
  body: ComicSections(
    children: [
      ComicPanel(
        caption: 'A panel',
        child: ComicKvRow('A label', 'A value', isFirst: true),
      ),
    ],
  ),
);
