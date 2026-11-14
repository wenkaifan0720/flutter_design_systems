/// The small marks the look is made of. The LED is where the pigment lives: a small lit lamp on what's live.
library;

import 'package:flutter/material.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

import '../kit.dart';

Widget kitOrnamentsDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Lamps and marks',
  sections: [
    kitSection('An LED', children: [kitSpecimenLed()]),
    kitSection('Live words', children: [kitSpecimenLive()]),
    kitSection('A shape mark', children: [kitSpecimenShapeMark()]),
    kitSection('A monogram', children: [kitSpecimenMonogram()]),
    kitSection('An icon in a well', children: [kitSpecimenIconWell()]),
    kitSection('The brand mark', children: [kitSpecimenBrandMark()]),
  ],
);

Widget kitSpecimenLed() => const NeumorphicLed();

Widget kitSpecimenLive() =>
    const NeumorphicLiveText('On, 30%', icon: NeumorphicGlyphs.flame);

Widget kitSpecimenShapeMark() => const Wrap(
  spacing: 12,
  children: [
    NeumorphicShapeMark(NeumorphicMarkShape.solid),
    NeumorphicShapeMark(NeumorphicMarkShape.ring),
    NeumorphicShapeMark(NeumorphicMarkShape.half),
  ],
);

Widget kitSpecimenMonogram() => const Wrap(
  spacing: 12,
  children: [
    NeumorphicMonogram('AB'),
    NeumorphicMonogram('CD', led: true),
    NeumorphicMonogram('EF', size: 72, led: true),
  ],
);

Widget kitSpecimenIconWell() => const Wrap(
  spacing: 12,
  children: [
    NeumorphicIconWell(NeumorphicGlyphs.lock),
    NeumorphicIconWell(NeumorphicGlyphs.lock, live: true),
    NeumorphicIconWell(NeumorphicGlyphs.lock, square: true),
  ],
);

Widget kitSpecimenBrandMark() => const NeumorphicBrandMark();
