/// The cast objects: a fluted dial to set one value, a span dial for what's on now, gauges and knobs. They stay round and take no card. On a phone the big ones go compact, so a page's job stands on the first screen.
library;

import 'package:flutter/material.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

import '../kit.dart';

Widget kitDialDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Fluted dials and knobs',
  sections: [
    kitSection('A fluted dial, whole', children: [kitSpecimenDial()]),
    kitSection('A fluted dial, compact', children: [kitSpecimenDialCompact()]),
    kitSection('A span dial', children: [kitSpecimenSpanDial()]),
    kitSection('A small dial', children: [kitSpecimenMiniDial()]),
    kitSection('A gauge', children: [kitSpecimenGauge()]),
    kitSection('A knob', children: [kitSpecimenKnob()]),
    kitSection('A knob with its figure', children: [kitSpecimenKnobRow()]),
    kitSection('An object beside its words', children: [kitSpecimenHeroBand()]),
  ],
);

Widget kitSpecimenDial() => NeumorphicDial(
  value: 72,
  min: 40,
  max: 90,
  now: 68,
  major: 10,
  step: 1.25,
  label: 'Rising to',
  labelIcon: NeumorphicGlyphs.trendingUp,
  figure: '72',
  sub: 'Now 68',
  caption: '72 by about 20:25',
  captionDetail: 'Set at 19:45',
  onDecrease: () {},
  onIncrease: () {},
);

Widget kitSpecimenDialCompact() => NeumorphicDial(
  compact: true,
  value: 72,
  min: 40,
  max: 90,
  now: 68,
  label: 'Rising to',
  figure: '72',
  sub: 'Now 68',
  caption: '72 by about 20:25',
  onDecrease: () {},
  onIncrease: () {},
);

Widget kitSpecimenSpanDial() => const NeumorphicSpanDial(
  start: '12:30',
  end: '13:15',
  elapsed: 35,
  total: 45,
  tag: 'Now, 13:05',
  figure: '10',
  unit: 'min left',
  title: 'A thing that is on now',
  note: 'A place',
  noteMark: NeumorphicShapeMark(NeumorphicMarkShape.half),
);

Widget kitSpecimenMiniDial() => const NeumorphicMiniDial(
  value: 72,
  min: 40,
  max: 90,
  now: 68,
  figure: '72',
  live: true,
);

Widget kitSpecimenGauge() => const NeumorphicGauge(
  value: 72,
  figure: '72',
  name: 'A zone',
  note: 'Rising to 75',
  noteIcon: NeumorphicGlyphs.trendingUp,
  live: true,
);

Widget kitSpecimenKnob() => const NeumorphicKnob(value: .38);

Widget kitSpecimenKnobRow() =>
    const NeumorphicKnobRow(value: .38, label: 'Level', figure: '38%');

Widget kitSpecimenHeroBand() => const NeumorphicHeroBand(
  object: NeumorphicMiniDial(value: 40, figure: '40'),
  overline: 'Now',
  title: 'A title',
  body: 'A line about it',
);
