/// The look's moment: a whole place cast in the wall, its floors and bays. A bay's window draws its state with no words in it; the words stand on the wall under it. One a screen, and the look's home.
library;

import 'package:flutter/material.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

import '../kit.dart';
// The demo art is the example's; a test or page that draws it reads it from there.
// ignore: avoid_relative_lib_imports
import '../../demo_art.dart';

Widget kitReliefDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'The relief',
  sections: [
    kitSection('A place in relief', children: [kitSpecimenRelief()]),
  ],
);

Widget kitSpecimenRelief() => const NeumorphicRelief(
  headerArt: NeumorphicGableArt(),
  title: '12',
  subtitle: 'North Street',
  count: '*4 of 6* on',
  courses: [
    NeumorphicCourse('Upper', [
      NeumorphicBay(name: 'Studio', figure: '18', note: 'Free'),
      NeumorphicBay(
        name: 'Meeting room',
        figure: '31',
        note: 'On, 80%',
        lit: .8,
        flag: NeumorphicGlyphs.bell,
      ),
      NeumorphicBay(name: 'Office', figure: '7', note: 'Free'),
    ]),
    NeumorphicCourse('Lower', [
      NeumorphicBay(name: 'Hall', figure: '15', note: 'On, 40%', lit: .4),
      NeumorphicBay(name: 'Main room', figure: '42', note: 'On, 40%', lit: .4),
      NeumorphicBay(name: 'Front desk', figure: '6', note: 'On, 20%', lit: .2),
    ]),
  ],
  ground: [NeumorphicGroundNote('Outside 7°', icon: NeumorphicGlyphs.trees)],
);
