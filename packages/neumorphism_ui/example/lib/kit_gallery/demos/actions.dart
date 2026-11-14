/// Groups of buttons, toggles and keys.
library;

import 'package:flutter/widgets.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

import '../kit.dart';

Widget kitActionsDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Groups of buttons, toggles and keys',
  sections: kitActionsSections(),
);

List<Widget> kitActionsSections() => [
  kitSection('Buttons that act together', children: [kitSpecimenButtonGroup()]),
  kitSection('Choices that stay pressed', children: [kitSpecimenToggleGroup()]),
  kitSection(
    'One action and its alternatives',
    children: [kitSpecimenSplitButton()],
  ),
  kitSection('Keys to press', children: [kitSpecimenKbd()]),
];

Widget kitSpecimenButtonGroup() => NeumorphicButtonGroup(
  label: 'Week',
  items: [
    NeumorphicButtonGroupItem('Previous', onPressed: () {}),
    NeumorphicButtonGroupItem('Today', onPressed: () {}),
    NeumorphicButtonGroupItem('Next', onPressed: () {}),
  ],
);

Widget kitSpecimenToggleGroup() => kitValue<Set<String>>(
  const {'bed'},
  (context, on, change) => NeumorphicToggleGroup<String>(
    label: 'Rooms that dim at dusk',
    selected: on,
    onChanged: change,
    items: const [
      NeumorphicButtonSegment('bed', 'Bedroom'),
      NeumorphicButtonSegment('kitchen', 'Kitchen'),
      NeumorphicButtonSegment('study', 'Study'),
    ],
  ),
);

Widget kitSpecimenSplitButton() => NeumorphicSplitButton(
  'Start now',
  onPressed: () {},
  actions: [
    NeumorphicSplitAction('Start at dusk', onPressed: () {}),
    NeumorphicSplitAction('Start tomorrow', onPressed: () {}),
  ],
);

Widget kitSpecimenKbd() => const NeumorphicKbd(['Ctrl', 'K']);
