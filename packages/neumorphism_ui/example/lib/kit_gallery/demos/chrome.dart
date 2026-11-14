/// The screen and its bars, the rail, the picture part and the states a page can be in.
library;

import 'package:flutter/material.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

import '../kit.dart';

Widget kitChromeDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Screen, rail and pictures',
  sections: [
    kitSection('The drawer', children: [kitSpecimenNavigationDrawer()]),
    kitSection('The top bar', children: [kitSpecimenTopBar()]),
    kitSection('The tab bar', children: [kitSpecimenTabBar()]),
    kitSection(
      'A rail of destinations',
      children: [kitSpecimenNavigationRail()],
    ),
    kitSection('A set in the rail', children: [kitSpecimenRailSet()]),
    kitSection('A link in the rail', children: [kitSpecimenRailLink()]),
    kitSection('A picture', children: [kitSpecimenPhoto()]),
    kitSection('A card with a picture', children: [kitSpecimenPictureCard()]),
    kitSection('A field a stub draws', children: [kitSpecimenInput()]),
    kitSection('Loading', children: [kitSpecimenLoadingState()]),
    kitSection('An error', children: [kitSpecimenErrorState()]),
  ],
);

Widget kitSpecimenTopBar() => const NeumorphicAppBar(title: 'A page');

Widget kitSpecimenTabBar() =>
    const NeumorphicNavigationBar(items: kitTabs, selectedIndex: 0);

Widget kitSpecimenRailSet() => const NeumorphicRailSet(
  label: 'A set',
  gap: 4,
  children: [
    NeumorphicRailLink(
      label: 'A place',
      figure: '21.0',
      live: true,
      selected: true,
    ),
    NeumorphicRailLink(label: 'Another place', figure: '19.4'),
  ],
);

Widget kitSpecimenRailLink() =>
    const NeumorphicRailLink(label: 'A place', figure: '21.0', live: true);

Widget kitSpecimenPhoto() =>
    const NeumorphicMedia(slotId: 'item-1', aspect: 4 / 3, label: 'A piece');

Widget kitSpecimenPictureCard() => const NeumorphicPictureCard(
  glyph: NeumorphicGlyphs.lamp,
  title: 'A piece',
  subtitle: 'A short line',
  figure: '48',
);

Widget kitSpecimenInput() => NeumorphicInput(hint: 'A name', onChanged: (_) {});

Widget kitSpecimenLoadingState() => const NeumorphicLoadingState();

Widget kitSpecimenErrorState() => NeumorphicErrorState(
  title: 'Could not load',
  message: 'Check your connection.',
  onRetry: () {},
);

Widget kitSpecimenScreen() => const NeumorphicScaffold(
  topBar: NeumorphicAppBar(title: 'A page'),
  body: NeumorphicSections(
    children: [
      NeumorphicCard(
        title: 'A card',
        children: [NeumorphicKvRow('A label', 'A value', isFirst: true)],
      ),
    ],
  ),
);

Widget kitSpecimenNavigationDrawer() {
  var selected = 0;
  return StatefulBuilder(
    builder: (context, setState) => NeumorphicNavigationDrawer(
      items: kitTabs,
      selectedIndex: selected,
      header: const NeumorphicBrandRow('A place'),
      footer: const Text('Your workspace'),
      onDestinationSelected: (v) => setState(() => selected = v),
    ),
  );
}

Widget kitSpecimenNavigationRail() => SizedBox(
  height: 320,
  child: Align(
    alignment: AlignmentDirectional.centerStart,
    child: NeumorphicNavigationRail(
      items: kitTabs,
      onDestinationSelected: (_) {},
    ),
  ),
);
