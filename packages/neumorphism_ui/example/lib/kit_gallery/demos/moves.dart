/// Places within a page and progress through a sequence.
library;

import 'package:flutter/widgets.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

import '../kit.dart';

Widget kitMovesDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Views and sequences',
  sections: [
    kitSection('View tabs', children: [kitSpecimenViewTabs()]),
    kitSection('Pages', children: [kitSpecimenPageDots()]),
    kitSection('Steps', children: [kitSpecimenStepProgress()]),
    kitSection('Pages of a list', children: [kitSpecimenPagination()]),
    kitSection('Where this is', children: [kitSpecimenBreadcrumbs()]),
    kitSection('A strip of cards', children: [kitSpecimenCarousel()]),
  ],
);
Widget kitSpecimenViewTabs() {
  var selected = 0;
  return StatefulBuilder(
    builder: (context, setState) => NeumorphicTabBar(
      tabs: const ['Overview', 'Activity', 'Details'],
      selectedIndex: selected,
      onChanged: (v) => setState(() => selected = v),
    ),
  );
}

Widget kitSpecimenPageDots() {
  var selected = 1;
  return StatefulBuilder(
    builder: (context, setState) => NeumorphicPageDots(
      count: 4,
      selectedIndex: selected,
      label: 'Introduction',
      onChanged: (v) => setState(() => selected = v),
    ),
  );
}

Widget kitSpecimenStepProgress() => const NeumorphicStepProgress(
  count: 4,
  currentStep: 1,
  name: 'Choose a space',
  phase: 'Personalize your place',
);

Widget kitSpecimenPagination() {
  var page = 4;
  return StatefulBuilder(
    builder: (context, setState) => NeumorphicPagination(
      count: 12,
      page: page,
      onChanged: (v) => setState(() => page = v),
    ),
  );
}

Widget kitSpecimenBreadcrumbs() => NeumorphicBreadcrumb(
  crumbs: [
    NeumorphicCrumb('Home', onPressed: () {}),
    NeumorphicCrumb('Rooms', onPressed: () {}),
    const NeumorphicCrumb('Kitchen'),
  ],
);

Widget kitSpecimenCarousel() => NeumorphicCarouselView(
  label: 'Rooms',
  height: 150,
  // The middle room first: a neighbour shows on each side and both steps are live.
  initialPage: 1,
  children: [
    kitSlide('Kitchen', '21.5° · lights on'),
    kitSlide('Hall', '19.0° · quiet'),
    kitSlide('Study', '20.5° · fan low'),
  ],
);

/// A carousel's slide: a card of the one plaster, a title and a line. Tinted each with its own hue, the slides read as
/// slabs of other materials laid on the wall (muddy by night).
Widget kitSlide(String title, String line) =>
    NeumorphicCard(title: title, children: [Text(line)]);
