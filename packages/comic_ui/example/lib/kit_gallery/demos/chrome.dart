/// The screen and its bars, the picture and the states a page can be in.
library;

import 'package:material_ui/material_ui.dart';
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

Widget kitSpecimenTopBar() => Builder(
  builder: (context) => ComicAppBar(title: kitSay(context, 'A page')),
);

Widget kitSpecimenTabBar() => kitState(
  0,
  (context, value, change) => ComicNavigationBar(
    destinations: kitTabs(context),
    selectedIndex: value,
    onDestinationSelected: change,
  ),
);

Widget kitSpecimenLogo() =>
    Builder(builder: (context) => ComicLogo(kitSay(context, 'Huzzah!')));

Widget kitSpecimenGroupChip() => Builder(
  builder: (context) => ComicGroupChip(
    kitSay(context, 'Our six'),
    people: const [
      ComicPerson(initials: 'AB', size: 26),
      ComicPerson(initials: 'CD', size: 26, fillIndex: 1),
    ],
    onPressed: () =>
        kitFeedback(context, kitSay(context, 'Our six, all of them.')),
  ),
);

Widget kitSpecimenPhoto() =>
    const ComicMedia(slotId: 'kit-picture', aspect: 16 / 9, label: 'A picture');

Widget kitSpecimenPictureCard() => Builder(
  builder: (context) => ComicRow(
    spans: [6, 6],
    children: [
      ComicPictureCard(
        slotId: 'kit-picture',
        image: ComicArtBand(leading: ComicMark(ComicMarks.mug)),
        title: kitSay(context, 'A piece'),
        subtitle: kitSay(context, 'A kind'),
        figure: '42',
      ),
      ComicPictureCard(
        slotId: 'kit-picture-2',
        image: ComicArtBand(ground: 4, leading: ComicMark(ComicMarks.peak)),
        title: kitSay(context, 'Another'),
        subtitle: kitSay(context, 'A kind'),
        figure: '38',
      ),
    ],
  ),
);

Widget kitSpecimenLoadingState() =>
    const SizedBox(height: 140, child: ComicLoadingState());

Widget kitSpecimenErrorState() => Builder(
  builder: (context) => Builder(
    builder: (context) => ComicErrorState(
      title: kitSay(context, 'That did not load'),
      message: kitSay(context, 'Check the line and try again.'),
      onRetry: () => kitFeedback(context, kitSay(context, 'Trying again.')),
    ),
  ),
);

Widget kitSpecimenButton() => Builder(
  builder: (context) => ComicButton(
    'A plain button',
    onPressed: () => kitFeedback(context, 'Button pressed.'),
  ),
);

Widget kitSpecimenInput() => Builder(
  builder: (context) => ComicInput(hint: kitSay(context, 'A plain input')),
);

Widget kitSpecimenScreen() => Builder(
  builder: (context) => ComicScaffold(
    topBar: ComicAppBar(title: 'A page'),
    body: ComicSections(
      children: [
        ComicPanel(
          caption: kitSay(context, 'A panel'),
          child: ComicKvRow(
            kitSay(context, 'A label'),
            kitSay(context, 'A value'),
            isFirst: true,
          ),
        ),
      ],
    ),
  ),
);
